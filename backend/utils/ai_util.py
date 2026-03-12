# AI建议工具
"""AI工具类：可后续扩展AI模型调用、数据统计等"""
import pandas as pd

# 计算生理数据平均值（用于趋势分析）
def calc_physio_average(data_list: list, field: str) -> float:
    """
    :param data_list: 生理数据列表（从数据库查询的字典列表）
    :param field: 要计算的字段（heart_rate/spo2/temp）
    :return: 平均值
    """
    if not data_list:
        return 0.0
    df = pd.DataFrame(data_list)
    return round(df[field].mean(), 1)

# 睡眠质量评级（优秀/良好/一般/差）
def sleep_quality_rating(score: int) -> str:
    if score >= 90:
        return "优秀"
    elif score >= 70:
        return "良好"
    elif score >= 60:
        return "一般"
    else:
        return "差"