# 数据处理业务
from repository.physio_repo import (
    insert_physio_data,
    get_physio_data_by_user,
    insert_sleep_record,
    get_sleep_record_by_user,
    insert_sport_record,
    get_sport_record_by_user,
    get_sport_calendar_by_user,
)
from repository.iot_repo import get_averaged_metrics_in_time_range
from repository.user_repo import get_user_by_id
from utils.sport_calculator import calculate_calorie
from utils.ai_util import generate_sport_suggestion_ai
from calendar import monthrange


# 上传生理数据（新版本）
def upload_physio_data_service(
    user_id: int,
    timestamp: str = None,
    scene: int = 0,
):
    from datetime import datetime
    import random

    # 1. 获取用户个人信息（用于AI建议）
    user_info = get_user_by_id(user_id)
    if not user_info:
        return {"status": "error", "msg": "用户不存在"}

    age = user_info.get("age", 30)
    gender = user_info.get("gender", "未知")
    weight = user_info.get("weight", 60)

    # 2. 设置默认生理数据（根据不同场景）
    if scene == 0:  # 静息
        heart_rate = 72
        spo2 = 98
        temp = 36.5
    elif scene == 1:  # 运动
        heart_rate = 125
        spo2 = 95
        temp = 37.2
    else:  # 睡眠
        heart_rate = 58
        spo2 = 97
        temp = 36.0

    # 3. 如果没有传入时间戳，使用当前时间
    if timestamp is None:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 4. 调用AI生成建议
    from utils.ai_util import call_deepseek_api

    scene_names = {0: "静息", 1: "运动", 2: "睡眠"}
    scene_name = scene_names.get(scene, "未知")

    prompt = f"""
【用户个人信息】
年龄：{age}岁
性别：{gender}
体重：{weight}kg

【当前生理数据】
场景：{scene_name}
心率：{heart_rate}次/分钟
血氧：{spo2}%
体温：{temp}℃

请根据以上用户的完整信息，分析当前生理数据是否正常，并给出3条具体建议：
1. 心率是否正常，如何调整
2. 血氧水平评价
3. 体温是否正常，注意事项

要求：
- 考虑用户的年龄、性别
- 给出具体的数值建议
- 如果是异常值，要给出特别提醒
"""

    suggestion = call_deepseek_api(prompt)
    if "AI调用" in suggestion:
        suggestion = f"当前{scene_name}状态下，心率{heart_rate}次/分钟，血氧{spo2}%，体温{temp}℃，各项指标正常。建议保持良好生活习惯。"

    # 5. 插入数据库
    insert_result = insert_physio_data(
        user_id=user_id,
        heart_rate=heart_rate,
        spo2=spo2,
        temp=temp,
        scene=scene,
        timestamp=timestamp,
        suggestion=suggestion,
    )

    # 6. 返回完整的生理数据
    if insert_result["status"] == "success":
        return {
            "status": "success",
            "msg": insert_result["msg"],
            "user_id": user_id,
            "heart_rate": heart_rate,
            "spo2": spo2,
            "temp": temp,
            "scene": scene,
            "timestamp": timestamp,
            "suggestion": suggestion,
        }
    else:
        return insert_result


# 查询生理数据（修改）
def get_physio_data_service(user_id: int, limit: int = 10):
    data = get_physio_data_by_user(user_id, limit)
    return {"status": "success", "data": data}


# 上传睡眠记录（新版本）
def upload_sleep_record_service(
    user_id: int,
    sleep_start: str,
    sleep_end: str,
):
    from datetime import datetime, timedelta

    # 1. 获取用户个人信息（用于AI建议）
    user_info = get_user_by_id(user_id)
    if not user_info:
        return {"status": "error", "msg": "用户不存在"}

    age = user_info.get("age", 30)
    gender = user_info.get("gender", "未知")
    weight = user_info.get("weight", 60)

    # 2. 计算睡眠总时长（分钟）
    try:
        start_time = datetime.strptime(sleep_start, "%Y-%m-%d %H:%M:%S")
        end_time = datetime.strptime(sleep_end, "%Y-%m-%d %H:%M:%S")

        # 如果结束时间小于开始时间，说明跨天了
        if end_time < start_time:
            end_time = end_time + timedelta(days=1)

        total_minutes = int((end_time - start_time).total_seconds() / 60)

        if total_minutes < 3:
            return {"status": "error", "msg": "睡眠时长不足3分钟，记录不会保存"}

        # 转换为小时
        total_hours = round(total_minutes / 60, 1)

    except Exception as e:
        return {"status": "error", "msg": f"时间解析错误: {str(e)}"}

    # 3. 根据总时长计算睡眠评分（简单逻辑）
    if total_hours >= 8:
        sleep_score = 90
    elif total_hours >= 7:
        sleep_score = 80
    elif total_hours >= 6:
        sleep_score = 70
    elif total_hours >= 5:
        sleep_score = 60
    else:
        sleep_score = 50

    # 4. 计算深度睡眠时间（默认占总睡眠的25%左右）
    deep_sleep_duration = int(total_minutes * 0.25)

    # 5. 从IoT设备获取真实生理数据
    start_dt = datetime.strptime(sleep_start, "%Y-%m-%d %H:%M:%S")
    end_dt = datetime.strptime(sleep_end, "%Y-%m-%d %H:%M:%S")
    start_ms = int(start_dt.timestamp() * 1000)
    end_ms = int(end_dt.timestamp() * 1000)

    iot_metrics = get_averaged_metrics_in_time_range(start_ms, end_ms, min_data_points=3)
    avg_heart_rate = iot_metrics.get("heart_rate")
    avg_spo2 = iot_metrics.get("spo2")
    avg_temp = iot_metrics.get("temp")

    # 6. 调用AI生成睡眠建议
    from utils.ai_util import call_deepseek_api

    prompt = f"""
【用户个人信息】
年龄：{age}岁
性别：{gender}
体重：{weight}kg

【本次睡眠信息】
入睡时间：{sleep_start}
起床时间：{sleep_end}
睡眠总时长：{total_hours}小时
睡眠评分：{sleep_score}分
深睡时长：约{deep_sleep_duration}分钟

请根据以上用户的完整信息，给出针对本次睡眠的3条具体建议：
1. 睡眠质量评价
2. 如何改善睡眠质量
3. 第二天起床后的注意事项

要求：
- 考虑用户的年龄、性别
- 给出具体的数值建议（如几点前睡觉、睡多久等）
- 如果是睡眠不足，要给出特别提醒
"""

    suggestion = call_deepseek_api(prompt)
    if "AI调用" in suggestion:
        suggestion = f"睡眠时长{total_hours}小时，评分{sleep_score}分。建议保持规律作息，每天同一时间入睡。"

    # 7. 插入数据库
    insert_result = insert_sleep_record(
        user_id,
        sleep_start,
        sleep_end,
        sleep_score,
        deep_sleep_duration,
        avg_heart_rate,  # 新增
        avg_spo2,  # 新增
        avg_temp,  # 新增
        suggestion,  # 新增
    )

    # 8. 返回完整的睡眠数据
    if insert_result["status"] == "success":
        return {
            "status": "success",
            "msg": insert_result["msg"],
            "sleep_duration": total_minutes,  # 分钟
            "sleep_duration_hours": total_hours,  # 小时
            "deep_sleep_duration": deep_sleep_duration,
            "sleep_score": sleep_score,
            "avg_heart_rate": avg_heart_rate,
            "avg_spo2": avg_spo2,
            "avg_temp": avg_temp,
            "suggestion": suggestion,
        }
    else:
        return insert_result


# 查询睡眠记录
def get_sleep_record_service(user_id: int, limit: int = 7):
    data = get_sleep_record_by_user(user_id, limit)
    return {"status": "success", "data": data}


# 上传运动记录（新版本）
def upload_sport_record_service(
    user_id: int,
    sport_type: str,
    sport_start: str,
    sport_end: str,
):
    # 1. 获取用户个人信息
    user_info = get_user_by_id(user_id)
    if not user_info:
        return {"status": "error", "msg": "用户不存在"}

    weight = user_info.get("weight")
    if not weight:
        return {"status": "error", "msg": "用户体重信息缺失，无法计算卡路里"}

    age = user_info.get("age", 30)
    gender = user_info.get("gender", "未知")

    # 2. 计算运动时长和卡路里
    duration_minutes, calorie = calculate_calorie(
        sport_type, sport_start, sport_end, weight
    )

    if duration_minutes <= 0:
        return {
            "status": "error",
            "msg": "运动时长无效，请先点击开始并在结束前保持至少几秒",
        }

    # 3. 从IoT设备获取真实生理数据
    from datetime import datetime
    start_dt = datetime.strptime(sport_start, "%Y-%m-%d %H:%M:%S")
    end_dt = datetime.strptime(sport_end, "%Y-%m-%d %H:%M:%S")
    start_ms = int(start_dt.timestamp() * 1000)
    end_ms = int(end_dt.timestamp() * 1000)

    iot_metrics = get_averaged_metrics_in_time_range(start_ms, end_ms, min_data_points=3)
    avg_heart_rate = iot_metrics.get("heart_rate")
    avg_spo2 = iot_metrics.get("spo2")
    avg_temp = iot_metrics.get("temp")

    # 4. 调用AI生成运动建议
    suggestion = generate_sport_suggestion_ai(
        sport_type=sport_type,
        sport_duration=duration_minutes,
        sport_time=sport_start,
        age=age,
        gender=gender,
        weight=weight,
        calorie=calorie,
    )

    # 5. 插入数据库
    insert_result = insert_sport_record(
        user_id,
        sport_type,
        sport_start,
        sport_end,
        avg_heart_rate,
        avg_spo2,
        avg_temp,
        calorie,
        suggestion,
    )

    # 6. 返回完整的运动数据（不仅仅是插入结果）
    if insert_result["status"] == "success":
        return {
            "status": "success",
            "msg": insert_result["msg"],
            "avg_heart_rate": avg_heart_rate,
            "avg_spo2": avg_spo2,
            "avg_temp": avg_temp,
            "calorie": calorie,
            "suggestion": suggestion,
        }
    else:
        return insert_result


# 查询运动记录
def get_sport_record_service(user_id: int, limit: int = 7):
    data = get_sport_record_by_user(user_id, limit)
    return {"status": "success", "data": data}


def get_sport_week_service(user_id: int):
    from repository.physio_repo import get_sport_record_by_user
    records = get_sport_record_by_user(user_id, limit=100)

    from datetime import datetime, timedelta
    today = datetime.now()
    week_start = today - timedelta(days=today.weekday() - 1)
    week_start = datetime(week_start.year, week_start.month, week_start.day)

    daily_calories = {i: 0.0 for i in range(7)}

    for record in records:
        sport_start_str = record.get("sport_start")
        if not sport_start_str:
            continue
        try:
            sport_start = datetime.strptime(sport_start_str, "%Y-%m-%d %H:%M:%S")
            if sport_start >= week_start and sport_start < week_start + timedelta(days=7):
                day_index = sport_start.weekday() - 1
                if day_index < 0:
                    day_index = 6
                calorie = record.get("calorie") or 0
                daily_calories[day_index] += float(calorie)
        except (ValueError, TypeError):
            continue

    weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    data = [
        {"weekday": weekdays[i], "calorie": round(daily_calories[i], 1)}
        for i in range(7)
    ]

    return {"status": "success", "data": data}


def get_sport_calendar_service(user_id: int, year: int, month: int):
    raw_days = get_sport_calendar_by_user(user_id, year, month)
    days_in_month = monthrange(year, month)[1]

    day_map = {}
    for item in raw_days:
        sport_date = item.get("sport_date")
        if not sport_date:
            continue
        day_map[int(sport_date[-2:])] = item

    days = []
    month_total_calorie = 0.0
    month_total_count = 0
    month_max_calorie = 0.0

    for day in range(1, days_in_month + 1):
        item = day_map.get(day)
        calorie = float(item.get("total_calorie", 0)) if item else 0.0
        workout_count = int(item.get("workout_count", 0)) if item else 0
        month_total_calorie += calorie
        month_total_count += workout_count
        month_max_calorie = max(month_max_calorie, calorie)
        days.append(
            {
                "date": f"{year:04d}-{month:02d}-{day:02d}",
                "day": day,
                "workout_count": workout_count,
                "total_calorie": round(calorie, 1),
                "has_workout": workout_count > 0,
            }
        )

    return {
        "status": "success",
        "data": {
            "year": year,
            "month": month,
            "days_in_month": days_in_month,
            "month_total_calorie": round(month_total_calorie, 1),
            "month_total_count": month_total_count,
            "month_max_calorie": round(month_max_calorie, 1),
            "days": days,
        },
    }
