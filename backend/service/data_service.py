# 数据处理业务
from calendar import monthrange
from datetime import datetime, timedelta

from repository.physio_repo import (
    insert_physio_data,
    get_physio_data_by_user,
    insert_sleep_record,
    get_sleep_record_by_user,
    insert_sport_record,
    get_sport_record_by_user,
    get_sport_records_by_user_in_range,
)
from repository.iot_repo import get_averaged_metrics_in_time_range
from repository.user_repo import get_user_by_id
from utils.sport_calculator import calculate_calorie
from utils.ai_util import generate_sport_suggestion_ai


def _parse_date_only(raw_date: str | None):
    if not raw_date:
        return datetime.now().date()
    return datetime.strptime(raw_date, "%Y-%m-%d").date()


def _parse_datetime(raw_time: str | None):
    if not raw_time:
        return None
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M"):
        try:
            return datetime.strptime(raw_time, fmt)
        except Exception:
            continue
    return None


def _weekday_cn(date_value):
    labels = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    return labels[date_value.weekday()]


def get_sport_summary_service(
    user_id: int,
    granularity: str,
    date: str | None = None,
    year: int | None = None,
    month: int | None = None,
):
    granularity = (granularity or "week").lower()

    if granularity == "day":
        day = _parse_date_only(date)
        start_dt = datetime(day.year, day.month, day.day)
        end_dt = start_dt + timedelta(days=1)
        records = get_sport_records_by_user_in_range(
            user_id,
            start_dt.strftime("%Y-%m-%d %H:%M:%S"),
            end_dt.strftime("%Y-%m-%d %H:%M:%S"),
        )

        points = []
        total_calorie = 0.0
        for record in records:
            start_time = _parse_datetime(record.get("sport_start"))
            calorie = float(record.get("calorie") or 0)
            total_calorie += calorie
            points.append(
                {
                    "time": record.get("sport_start"),
                    "timestamp_ms": (
                        int(start_time.timestamp() * 1000) if start_time else None
                    ),
                    "calorie": round(calorie, 1),
                    "sport_type": record.get("sport_type"),
                }
            )

        return {
            "status": "success",
            "data": {
                "granularity": "day",
                "date": day.strftime("%Y-%m-%d"),
                "date_label": f"{day.strftime('%Y-%m-%d')} {_weekday_cn(day)}",
                "summary": {
                    "workout_count": len(records),
                    "total_calorie": round(total_calorie, 1),
                },
                "chart": {
                    "mode": "time",
                    "points": points,
                },
            },
        }

    if granularity == "month":
        month_year = year or datetime.now().year
        month_value = month or datetime.now().month
        days_in_month = monthrange(month_year, month_value)[1]
        month_start = datetime(month_year, month_value, 1)
        if month_value == 12:
            next_month_start = datetime(month_year + 1, 1, 1)
        else:
            next_month_start = datetime(month_year, month_value + 1, 1)

        records = get_sport_records_by_user_in_range(
            user_id,
            month_start.strftime("%Y-%m-%d %H:%M:%S"),
            next_month_start.strftime("%Y-%m-%d %H:%M:%S"),
        )

        day_map = {
            day: {"workout_count": 0, "total_calorie": 0.0}
            for day in range(1, days_in_month + 1)
        }
        month_total_count = 0
        month_total_calorie = 0.0
        month_max_calorie = 0.0

        for record in records:
            start_time = _parse_datetime(record.get("sport_start"))
            if not start_time:
                continue
            day = start_time.day
            calorie = float(record.get("calorie") or 0)
            day_info = day_map[day]
            day_info["workout_count"] += 1
            day_info["total_calorie"] += calorie
            month_total_count += 1
            month_total_calorie += calorie

        days = []
        for day in range(1, days_in_month + 1):
            calorie = day_map[day]["total_calorie"]
            workout_count = day_map[day]["workout_count"]
            month_max_calorie = max(month_max_calorie, calorie)
            days.append(
                {
                    "date": f"{month_year:04d}-{month_value:02d}-{day:02d}",
                    "day": day,
                    "workout_count": workout_count,
                    "total_calorie": round(calorie, 1),
                    "has_workout": workout_count > 0,
                }
            )

        return {
            "status": "success",
            "data": {
                "granularity": "month",
                "year": month_year,
                "month": month_value,
                "days_in_month": days_in_month,
                "summary": {
                    "month_total_calorie": round(month_total_calorie, 1),
                    "month_total_count": month_total_count,
                    "month_max_calorie": round(month_max_calorie, 1),
                },
                "calendar": {
                    "days": days,
                },
            },
        }

    # 默认周视图：从周一到周日
    base_day = _parse_date_only(date)
    week_start = base_day - timedelta(days=base_day.weekday())
    week_end = week_start + timedelta(days=7)
    records = get_sport_records_by_user_in_range(
        user_id,
        datetime(week_start.year, week_start.month, week_start.day).strftime(
            "%Y-%m-%d %H:%M:%S"
        ),
        datetime(week_end.year, week_end.month, week_end.day).strftime(
            "%Y-%m-%d %H:%M:%S"
        ),
    )

    day_map = {i: {"workout_count": 0, "total_calorie": 0.0} for i in range(7)}
    total_calorie = 0.0
    total_count = 0

    for record in records:
        start_time = _parse_datetime(record.get("sport_start"))
        if not start_time:
            continue
        day_index = (start_time.date() - week_start).days
        if 0 <= day_index <= 6:
            calorie = float(record.get("calorie") or 0)
            day_info = day_map[day_index]
            day_info["workout_count"] += 1
            day_info["total_calorie"] += calorie
            total_count += 1
            total_calorie += calorie

    days = []
    for index in range(7):
        day_date = week_start + timedelta(days=index)
        weekday_label = _weekday_cn(day_date)
        days.append(
            {
                "date": day_date.strftime("%Y-%m-%d"),
                "weekday": weekday_label,
                "workout_count": day_map[index]["workout_count"],
                "calorie": round(day_map[index]["total_calorie"], 1),
            }
        )

    return {
        "status": "success",
        "data": {
            "granularity": "week",
            "week_start": week_start.strftime("%Y-%m-%d"),
            "week_end": (week_end - timedelta(days=1)).strftime("%Y-%m-%d"),
            "summary": {
                "week_total_calorie": round(total_calorie, 1),
                "week_total_count": total_count,
            },
            "chart": {
                "mode": "weekday",
                "days": days,
            },
        },
    }


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

    iot_metrics = get_averaged_metrics_in_time_range(
        start_ms, end_ms, min_data_points=3
    )
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

    iot_metrics = get_averaged_metrics_in_time_range(
        start_ms, end_ms, min_data_points=3
    )
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
