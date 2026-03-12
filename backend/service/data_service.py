# 数据处理业务
from repository.physio_repo import (
    insert_physio_data, get_physio_data_by_user,
    insert_sleep_record, get_sleep_record_by_user,
    insert_sport_record, get_sport_record_by_user
)

# 上传生理数据
def upload_physio_data_service(user_id: int, heart_rate: int, spo2: int, temp: float, scene: int):
    # 简单数据校验
    if heart_rate < 30 or heart_rate > 200:
        return {"status": "error", "msg": "心率值异常（范围30-200）"}
    if spo2 < 80 or spo2 > 100:
        return {"status": "error", "msg": "血氧值异常（范围80-100）"}
    if temp < 35 or temp > 42:
        return {"status": "error", "msg": "体温值异常（范围35-42）"}
    # 插入数据库
    return insert_physio_data(user_id, heart_rate, spo2, temp, scene)

# 查询生理数据
def get_physio_data_service(user_id: int, limit: int = 10):
    data = get_physio_data_by_user(user_id, limit)
    return {"status": "success", "data": data}

# 上传睡眠记录
def upload_sleep_record_service(user_id: int, sleep_start: str, sleep_end: str, sleep_score: int, deep_sleep: int, light_sleep: int):
    if sleep_score < 0 or sleep_score > 100:
        return {"status": "error", "msg": "睡眠评分异常（范围0-100）"}
    return insert_sleep_record(user_id, sleep_start, sleep_end, sleep_score, deep_sleep, light_sleep)

# 查询睡眠记录
def get_sleep_record_service(user_id: int, limit: int = 7):
    data = get_sleep_record_by_user(user_id, limit)
    return {"status": "success", "data": data}

# 上传运动记录
def upload_sport_record_service(user_id: int, sport_type: str, sport_start: str, sport_end: str, avg_heart_rate: int, calorie: float):
    if avg_heart_rate < 60 or avg_heart_rate > 180:
        return {"status": "error", "msg": "运动平均心率异常（范围60-180）"}
    return insert_sport_record(user_id, sport_type, sport_start, sport_end, avg_heart_rate, calorie)

# 查询运动记录
def get_sport_record_service(user_id: int, limit: int = 7):
    data = get_sport_record_by_user(user_id, limit)
    return {"status": "success", "data": data}

# 生成模拟生理数据（硬件替代）
def generate_mock_physio_data(user_id: int, scene: int = 0):
    import random
    # 模拟不同场景的生理数据
    if scene == 0:  # 静息
        heart_rate = random.randint(60, 80)
        spo2 = random.randint(95, 99)
        temp = round(random.uniform(36.0, 36.8), 1)
    elif scene == 1:  # 运动
        heart_rate = random.randint(100, 150)
        spo2 = random.randint(90, 95)
        temp = round(random.uniform(36.8, 37.5), 1)
    else:  # 睡眠
        heart_rate = random.randint(50, 70)
        spo2 = random.randint(96, 100)
        temp = round(random.uniform(35.8, 36.5), 1)
    # 插入模拟数据
    return insert_physio_data(user_id, heart_rate, spo2, temp, scene)