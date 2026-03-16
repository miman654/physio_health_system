# AI建议工具
"""AI工具类：可后续扩展AI模型调用、数据统计等"""
import pandas as pd

# AI工具模块
import requests
from config.settings import DEEPSEEK_API_KEY, DEEPSEEK_URL


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


def call_deepseek_api(prompt: str) -> str:
    """
    调用DeepSeek API的统一方法
    """
    headers = {
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        "Content-Type": "application/json",
    }

    data = {
        "model": "deepseek-chat",
        "messages": [
            {
                "role": "system",
                "content": "你是一位专业的健康顾问。请用2-3句话给出具体可执行的建议，每句都要包含量化指标（如具体数值、时间、食物名称）。不要解释原因，不要使用markdown格式。",
            },
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.4,
        "max_tokens": 200,
        "top_p": 0.9,
    }

    try:
        response = requests.post(DEEPSEEK_URL, headers=headers, json=data, timeout=30)
        response.encoding = "utf-8"

        if response.status_code == 200:
            result = response.json()
            return result["choices"][0]["message"]["content"].strip()
        else:
            return f"AI调用失败: {response.status_code}"
    except Exception as e:
        return f"AI调用错误: {str(e)}"


def generate_sport_suggestion_ai(
    sport_type: str,
    sport_duration: int,
    sport_time: str,
    age: int,
    gender: str,
    weight: float,
    calorie: float,
) -> str:
    """
    使用AI生成运动建议
    """
    prompt = f"""
【用户个人信息】
年龄：{age}岁
性别：{gender}
体重：{weight}kg

【本次运动信息】
运动类型：{sport_type}
运动时长：{sport_duration}分钟
运动时间：{sport_time}
预估消耗：约{int(calorie)}千卡

请根据以上用户的完整信息，给出针对本次运动的3条具体建议：
1. 运动强度是否合适，如何调整
2. 运动中需要注意什么
3. 运动后如何恢复

要求：
- 考虑用户的体重、年龄和运动强度
- 给出具体的数值建议
- 如果是首次运动，要给出特别提醒
"""
    return call_deepseek_api(prompt)
