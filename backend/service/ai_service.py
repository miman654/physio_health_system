# AI分析业务
import datetime
from repository.physio_repo import (
    get_physio_data_by_user,
    get_physio_data_by_user_in_range,
    get_sleep_record_by_user,
    get_sport_record_by_user,
)
from repository.user_repo import get_user_by_id
from utils.ai_util import call_deepseek_api, generate_sport_suggestion_ai


# 辅助方法：计算运动时长（分钟）- 移到文件顶部
def _get_duration_minutes(start_time, end_time):
    try:
        start = datetime.datetime.strptime(start_time, "%Y-%m-%d %H:%M:%S")
        end = datetime.datetime.strptime(end_time, "%Y-%m-%d %H:%M:%S")
        duration = (end - start).total_seconds() / 60
        return int(duration)
    except:
        return 30  # 默认30分钟


def _build_physio_snapshot_text(records):
    if not records:
        return "【最近生理数据】暂无生理数据"

    latest = records[0]
    values = []
    heart_rates = []
    spo2_values = []
    temps = []
    for item in records:
        if item.get("heart_rate") is not None:
            heart_rates.append(item["heart_rate"])
        if item.get("spo2") is not None:
            spo2_values.append(item["spo2"])
        if item.get("temp") is not None:
            temps.append(item["temp"])

    scene = "运动中" if latest.get("scene") == 0 else "静息"
    values.append(
        f"【最近生理数据】共{len(records)}条，最近一次：心率{latest.get('heart_rate')}bpm，血氧{latest.get('spo2')}%，体温{latest.get('temp')}℃，状态：{scene}"
    )
    if heart_rates:
        avg_hr = round(sum(heart_rates) / len(heart_rates), 1)
        values.append(f"【统计概览】平均心率{avg_hr}bpm")
    if spo2_values:
        avg_spo2 = round(sum(spo2_values) / len(spo2_values), 1)
        values.append(f"【统计概览】平均血氧{avg_spo2}%")
    if temps:
        avg_temp = round(sum(temps) / len(temps), 1)
        values.append(f"【统计概览】平均体温{avg_temp}℃")
    values.append(f"【最近记录时间】{latest.get('timestamp')}")
    return "\n".join(values)


def _build_ai_suggestions(prompt, fallback_suggestions, fallback_prefix=""):
    suggestion = call_deepseek_api(prompt)
    if suggestion and "AI调用失败" not in suggestion and "AI调用错误" not in suggestion:
        suggestions = [s.strip() for s in suggestion.split("\n") if s.strip()]
        while len(suggestions) < 3:
            suggestions.append(
                fallback_suggestions[len(suggestions) % len(fallback_suggestions)]
            )
    else:
        suggestions = fallback_suggestions

    if fallback_prefix:
        suggestions = [f"{fallback_prefix}{item}" for item in suggestions[:3]]
    return suggestions[:3]


# AI生理数据分析 - 结合用户身体情况
def ai_physio_analysis_service(
    user_id: int, analysis_type: str = "overview", recent_hours: int = 2
):
    # 获取用户信息
    user_info = get_user_by_id(user_id)
    if not user_info:
        return {"status": "error", "msg": "用户不存在"}

    # 计算BMI
    height_m = user_info["height"] / 100 if user_info["height"] else None
    bmi = (
        round(user_info["weight"] / (height_m**2), 1)
        if user_info["weight"] and height_m
        else None
    )

    # 获取最新生理数据和睡眠数据
    if analysis_type == "recent":
        end_time = datetime.datetime.now()
        start_time = end_time - datetime.timedelta(hours=recent_hours)
        physio_data = get_physio_data_by_user_in_range(
            user_id,
            start_time.strftime("%Y-%m-%d %H:%M:%S"),
            end_time.strftime("%Y-%m-%d %H:%M:%S"),
            limit=50,
        )
    else:
        physio_data = get_physio_data_by_user(user_id, limit=1)
    sleep_data = get_sleep_record_by_user(user_id, limit=1)

    # 准备返回的数据结构
    response_data = {
        "analysis_time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "user_info": {
            "age": user_info["age"],
            "gender": user_info["gender"],
            "weight": user_info["weight"],
            "height": user_info["height"],
            "bmi": bmi,
        },
        "latest_physio": None,
        "latest_sleep": None,
        "suggestions": [],
    }

    # 构建AI提示词
    prompt_parts = []
    prompt_parts.append(
        f"【用户基本信息】年龄：{user_info['age']}岁，性别：{'男' if user_info['gender'] == '男' else '女'}，体重：{user_info['weight']}kg，身高：{user_info['height']}cm"
    )
    if bmi:
        prompt_parts.append(f"BMI指数：{bmi}")

    if physio_data:
        latest_physio = physio_data[0]
        response_data["latest_physio"] = {
            "heart_rate": latest_physio["heart_rate"],
            "spo2": latest_physio["spo2"],
            "temp": latest_physio["temp"],
            "scene": latest_physio["scene"],
            "timestamp": latest_physio["timestamp"],
        }
        prompt_parts.append(_build_physio_snapshot_text(physio_data))

        if analysis_type == "recent":
            prompt_parts.append(
                "【分析目标】只看最近两小时，输出3条超简短提醒，每条尽量不超过15个字，重点放在当前状态和马上要做什么。"
            )
        else:
            prompt_parts.append(
                "【分析目标】结合整体健康情况，输出3条较完整建议，每条包含原因、做法和量化指标。"
            )
    else:
        prompt_parts.append("【最近生理数据】暂无生理数据")

    if sleep_data:
        latest_sleep = sleep_data[0]
        response_data["latest_sleep"] = {
            "sleep_score": latest_sleep["sleep_score"],
            "deep_sleep_duration": latest_sleep["deep_sleep_duration"],
            "light_sleep_duration": latest_sleep.get("light_sleep_duration"),
            "awake_count": latest_sleep.get("awake_count"),
            "sleep_start": latest_sleep["sleep_start"],
        }

        if analysis_type != "recent":
            sleep_score = latest_sleep["sleep_score"]
            deep_sleep = latest_sleep["deep_sleep_duration"]
            light_sleep = latest_sleep.get("light_sleep_duration")
            awake_count = latest_sleep.get("awake_count")
            sleep_text = (
                f"【最新睡眠数据】睡眠评分：{sleep_score}分，深睡时长：{deep_sleep}分钟"
            )
            if light_sleep is not None:
                sleep_text += f"，浅睡时长：{light_sleep}分钟"
            if awake_count is not None:
                sleep_text += f"，清醒次数：{awake_count}次"
            sleep_text += f"，入睡时间：{latest_sleep['sleep_start']}"
            prompt_parts.append(sleep_text)

    if analysis_type == "recent":
        fallback_suggestions = [
            "总提示：指尖盖住传感器，别漏光。",
            "要点1：手指保持静止，别晃动。",
            "要点2：环境光柔和，避开强光。",
        ]
    else:
        fallback_suggestions = [
            "建议每周进行3-5次中等强度运动，每次30-45分钟。",
            "建议每日饮水2000ml左右，饮食增加蔬菜和优质蛋白。",
            "建议23点前入睡，保证7-8小时睡眠。",
        ]

    prompt = "\n".join(prompt_parts)
    if analysis_type == "recent":
        prompt += (
            "\n\n请只输出3条，每条单独一行："
            "第1条写1句总提示，第2条和第3条写2条最重要的要点。"
            "不要加额外解释，不要多于3条。"
        )
    else:
        prompt += "\n\n请根据以上用户信息，给出3条具体的健康建议，每句都要包含量化指标。建议格式：1. 运动方面建议 2. 饮食方面建议 3. 作息方面建议"

    suggestions = _build_ai_suggestions(prompt, fallback_suggestions)
    response_data["suggestions"] = suggestions[:3]

    return {"status": "success", "data": response_data}


# AI运动营养建议 - 结合用户身体情况
def ai_sport_nutrition_service(
    user_id: int, sport_type: str, sport_duration: int, sport_time: str
):
    # 获取用户信息
    user_info = get_user_by_id(user_id)
    if not user_info:
        return {"status": "error", "msg": "用户不存在"}

    # 获取最新的运动记录作为参考
    sport_records = get_sport_record_by_user(user_id, limit=3)

    # 计算预估消耗卡路里（简化计算）
    # 跑步：体重(kg) * 时长(小时) * 8 MET
    # 步行：体重(kg) * 时长(小时) * 3.5 MET
    # 骑行：体重(kg) * 时长(小时) * 6 MET
    met_value = {"跑步": 8, "步行": 3.5, "骑行": 6}.get(sport_type, 5)

    hours = sport_duration / 60
    estimated_calorie = (
        int(user_info["weight"] * hours * met_value) if user_info["weight"] else 0
    )

    # 准备返回的数据结构
    response_data = {
        "sport_type": sport_type,
        "sport_duration": sport_duration,
        "estimated_calorie": estimated_calorie,
        "user_weight": user_info["weight"],
        "nutrition_suggestions": [],
    }

    # 构建运动历史信息
    history_info = ""
    if sport_records:
        history_info = "【近期运动记录】\n"
        for i, record in enumerate(sport_records[:2], 1):
            # 修正：移除 self. 直接调用函数
            duration = _get_duration_minutes(record["sport_start"], record["sport_end"])
            history_info += f"{i}. {record['sport_type']}，时长：{duration}分钟\n"

    # 构建提示词
    prompt = f"""
【用户基本信息】
年龄：{user_info['age']}岁
性别：{'男' if user_info['gender'] == '男' else '女'}
体重：{user_info['weight']}kg
身高：{user_info['height']}cm

【本次运动信息】
运动类型：{sport_type}
运动时长：{sport_duration}分钟
运动时间：{sport_time}
预估消耗：约{estimated_calorie}千卡

{history_info}
请根据以上用户信息，给出针对本次运动的3条具体营养建议：
1. 运动前应该补充什么食物和水分
2. 运动中如何补充水分和能量
3. 运动后如何补充营养帮助恢复

要求：
- 每句都要包含量化指标（如具体食物名称、数量、时间）
- 考虑用户的体重、年龄因素
- 如果运动时长超过60分钟，要特别关注运动中补充
- 如果是首次运动或近期运动较少，要给出特别提醒
"""

    # 调用AI接口
    suggestion = call_deepseek_api(prompt)

    # 处理AI返回的建议
    if suggestion and "AI调用失败" not in suggestion and "AI调用错误" not in suggestion:
        # 按行分割建议，去除空行
        suggestions = [s.strip() for s in suggestion.split("\n") if s.strip()]
        # 如果建议不足3条，补充默认建议
        while len(suggestions) < 3:
            suggestions.append(
                f"运动后可补充20g蛋白质和50g碳水化合物，如2个水煮蛋+1个馒头。"
            )
    else:
        # 默认建议（根据运动类型和时长）
        if sport_duration > 60:
            suggestions = [
                f"运动前1-2小时可食用1-2根香蕉+2片全麦面包，补充约300-400千卡能量。",
                f"运动中每15-20分钟补充100-150ml运动饮料，总量约{int(sport_duration/15)*150}ml。",
                f"运动后30分钟内补充20-30g蛋白质（如2个水煮蛋+1杯牛奶）和50-75g碳水化合物。",
            ]
        else:
            suggestions = [
                f"运动前1小时可食用1根香蕉或1个苹果，补充约100千卡能量。",
                f"运动前中后共补充500-800ml水分，可分次饮用。",
                f"运动后30分钟内补充15-20g蛋白质（如1杯牛奶+1个鸡蛋）和适量主食。",
            ]

    response_data["nutrition_suggestions"] = suggestions[:3]  # 只保留3条建议

    return {"status": "success", "data": response_data}
