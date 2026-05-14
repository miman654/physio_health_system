# AI分析业务
import datetime
from repository.physio_repo import (
    get_physio_data_by_user,
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


# AI生理数据分析 - 结合用户身体情况
def ai_physio_analysis_service(user_id: int):
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

    # 添加用户基本信息
    prompt_parts.append(
        f"【用户基本信息】年龄：{user_info['age']}岁，性别：{'男' if user_info['gender'] == '男' else '女'}，体重：{user_info['weight']}kg，身高：{user_info['height']}cm"
    )
    if bmi:
        prompt_parts.append(f"BMI指数：{bmi}")

    # 添加生理数据
    if physio_data:
        latest_physio = physio_data[0]
        heart_rate = latest_physio["heart_rate"]
        spo2 = latest_physio["spo2"]
        temp = latest_physio["temp"]
        scene = "运动中" if latest_physio["scene"] == 0 else "静息"

        response_data["latest_physio"] = {
            "heart_rate": heart_rate,
            "spo2": spo2,
            "temp": temp,
            "scene": latest_physio["scene"],
            "timestamp": latest_physio["timestamp"],
        }

        prompt_parts.append(
            f"【最新生理数据】心率：{heart_rate}bpm，血氧：{spo2}%，体温：{temp}℃，状态：{scene}"
        )

        # 根据心率生成针对性提示
        if scene == "运动中" and heart_rate > 140:
            prompt_parts.append("【重点关注】心率偏高，需要关注运动强度")
        elif scene == "运动中" and heart_rate > 120:
            prompt_parts.append("【重点关注】心率略高，建议适当调整运动强度")
        elif heart_rate > 100:
            prompt_parts.append("【重点关注】静息心率偏高，需要关注放松和作息")
        else:
            prompt_parts.append("【重点关注】心率正常，继续保持")
    else:
        prompt_parts.append("【最新生理数据】暂无生理数据")

    # 添加睡眠数据
    if sleep_data:
        latest_sleep = sleep_data[0]
        sleep_score = latest_sleep["sleep_score"]
        deep_sleep = latest_sleep["deep_sleep_duration"]
        light_sleep = latest_sleep.get("light_sleep_duration")
        awake_count = latest_sleep.get("awake_count")

        response_data["latest_sleep"] = {
            "sleep_score": sleep_score,
            "deep_sleep_duration": deep_sleep,
            "light_sleep_duration": light_sleep,
            "awake_count": awake_count,
            "sleep_start": latest_sleep["sleep_start"],
        }

        sleep_metrics_text = [
            f"睡眠评分：{sleep_score}分",
            f"深睡时长：{deep_sleep}分钟",
        ]
        if light_sleep is not None:
            sleep_metrics_text.append(f"浅睡时长：{light_sleep}分钟")
        if awake_count is not None:
            sleep_metrics_text.append(f"清醒次数：{awake_count}次")
        sleep_metrics_text.append(f"入睡时间：{latest_sleep['sleep_start']}")

        prompt_parts.append("【最新睡眠数据】" + "，".join(sleep_metrics_text))

        if sleep_score >= 90:
            prompt_parts.append("【睡眠评价】睡眠质量优秀，继续保持")
        elif sleep_score >= 70:
            prompt_parts.append("【睡眠评价】睡眠质量良好，还有提升空间")
        elif sleep_score >= 60:
            prompt_parts.append("【睡眠评价】睡眠质量一般，需要改善")
        else:
            prompt_parts.append("【睡眠评价】睡眠质量差，需要重点关注")
    else:
        prompt_parts.append("【最新睡眠数据】暂无睡眠数据")

    # 构建完整的提示词
    prompt = "\n".join(prompt_parts)
    prompt += "\n\n请根据以上用户信息，给出3条具体的健康建议，每句都要包含量化指标。建议格式：1. 运动方面建议 2. 饮食方面建议 3. 作息方面建议"

    # 调用AI接口
    suggestion = call_deepseek_api(prompt)

    # 处理AI返回的建议
    if suggestion and "AI调用失败" not in suggestion and "AI调用错误" not in suggestion:
        # 按行分割建议，去除空行
        suggestions = [s.strip() for s in suggestion.split("\n") if s.strip()]
        # 如果建议不足3条，补充默认建议
        while len(suggestions) < 3:
            suggestions.append(
                "建议保持规律作息，每天保证7-8小时睡眠，多摄入蔬菜水果。"
            )
    else:
        suggestions = [
            "根据您的年龄和身体状况，建议每周进行3-5次中等强度运动，每次30-45分钟。",
            "每日饮水量建议达到2000ml，可适当饮用绿茶，有助于新陈代谢。",
            "建议23点前入睡，保证7-8小时睡眠，睡前1小时避免使用电子设备。",
        ]

    response_data["suggestions"] = suggestions[:3]  # 只保留3条建议

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
