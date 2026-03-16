# 运动计算工具模块
from datetime import datetime


# MET值（代谢当量）表
MET_VALUES = {
    "步行": 3.5,  # 慢走
    "快走": 4.5,
    "跑步": 8.0,  # 慢跑
    "快跑": 12.0,
    "骑行": 6.0,  # 普通骑行
    "游泳": 7.0,
    "瑜伽": 2.5,
    "健身": 5.0,
}


def get_met_value(sport_type: str) -> float:
    """
    根据运动类型获取MET值
    """
    return MET_VALUES.get(sport_type, 5.0)  # 默认5.0


def calculate_calorie(
    sport_type: str, sport_start: str, sport_end: str, weight: float
) -> tuple:
    """
    计算运动消耗的卡路里和运动时长

    公式：卡路里消耗(kcal) = MET值 × 体重(kg) × 时间(h)

    返回：(运动时长分钟, 消耗卡路里)
    """
    try:
        # 计算运动时长
        start_time = datetime.strptime(sport_start, "%Y-%m-%d %H:%M:%S")
        end_time = datetime.strptime(sport_end, "%Y-%m-%d %H:%M:%S")
        duration_minutes = int((end_time - start_time).total_seconds() / 60)

        if duration_minutes <= 0:
            return 0, 0.0

        # 计算卡路里
        met = get_met_value(sport_type)
        duration_hours = duration_minutes / 60
        calorie = met * weight * duration_hours

        return duration_minutes, round(calorie, 1)
    except Exception as e:
        print(f"计算卡路里出错: {e}")
        return 0, 0.0
