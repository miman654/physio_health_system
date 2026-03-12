# AI分析业务
import datetime
from config.settings import NUTRITION_RULES
from repository.physio_repo import get_physio_data_by_user, get_sleep_record_by_user

# AI生理数据分析（生成健康建议）
def ai_physio_analysis_service(user_id: int):
    # 获取最新生理数据
    physio_data = get_physio_data_by_user(user_id, limit=1)
    sleep_data = get_sleep_record_by_user(user_id, limit=1)
    
    suggestions = []
    if physio_data:
        latest_physio = physio_data[0]
        # 体温异常建议
        if latest_physio["temp"] > 37.5:
            suggestions.append(NUTRITION_RULES["temp_high"])
        # 心率异常建议
        if latest_physio["scene"] == 0 and latest_physio["heart_rate"] > 90:
            suggestions.append(NUTRITION_RULES["heart_rate_high"])
    
    if sleep_data:
        latest_sleep = sleep_data[0]
        # 睡眠评分低建议
        if latest_sleep["sleep_score"] < 60:
            suggestions.append(NUTRITION_RULES["sleep_bad"])
    
    # 无异常则返回通用建议
    if not suggestions:
        suggestions.append("你的生理数据整体正常，建议保持规律作息、均衡饮食、适量运动！")
    
    return {
        "status": "success",
        "data": {
            "analysis_time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "suggestions": suggestions
        }
    }

# AI运动营养建议
def ai_sport_nutrition_service(sport_type: str, sport_duration: int):
    # sport_duration：运动时长（分钟）
    suggestions = []
    if sport_duration > 60:
        suggestions.append(NUTRITION_RULES["sport_long"])
    # 按运动类型补充建议
    if sport_type == "跑步":
        suggestions.append("跑步后建议补充电解质水，避免脱水")
    elif sport_type == "骑行":
        suggestions.append("骑行后建议拉伸腿部肌肉，补充碳水化合物（香蕉/全麦面包）")
    elif sport_type == "步行":
        suggestions.append("步行属于低强度运动，建议补充水分即可，无需额外加餐")
    
    return {
        "status": "success",
        "data": {
            "sport_type": sport_type,
            "sport_duration": sport_duration,
            "nutrition_suggestions": suggestions
        }
    }