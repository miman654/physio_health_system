# 生理数据操作
import datetime
from .db import get_db_connection

# 插入生理数据
def insert_physio_data(user_id: int, heart_rate: int, spo2: int, temp: float, scene: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cursor.execute(
        """INSERT INTO physio_data 
        (user_id, heart_rate, spo2, temp, scene, timestamp) 
        VALUES (?, ?, ?, ?, ?, ?)""",
        (user_id, heart_rate, spo2, temp, scene, timestamp)
    )
    conn.commit()
    conn.close()
    return {"status": "success", "msg": "数据插入成功"}

# 查询用户生理数据（按时间倒序）
def get_physio_data_by_user(user_id: int, limit: int = 10):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """SELECT id, heart_rate, spo2, temp, scene, timestamp 
        FROM physio_data WHERE user_id=? ORDER BY timestamp DESC LIMIT ?""",
        (user_id, limit)
    )
    data = cursor.fetchall()
    conn.close()
    # 转换为列表字典
    return [dict(item) for item in data]

# 插入睡眠记录
def insert_sleep_record(user_id: int, sleep_start: str, sleep_end: str, sleep_score: int, deep_sleep: int, light_sleep: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """INSERT INTO sleep_record 
        (user_id, sleep_start, sleep_end, sleep_score, deep_sleep_duration, light_sleep_duration) 
        VALUES (?, ?, ?, ?, ?, ?)""",
        (user_id, sleep_start, sleep_end, sleep_score, deep_sleep, light_sleep)
    )
    conn.commit()
    conn.close()
    return {"status": "success", "msg": "睡眠记录插入成功"}

# 查询用户睡眠记录
def get_sleep_record_by_user(user_id: int, limit: int = 7):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """SELECT id, sleep_start, sleep_end, sleep_score, deep_sleep_duration, light_sleep_duration 
        FROM sleep_record WHERE user_id=? ORDER BY sleep_start DESC LIMIT ?""",
        (user_id, limit)
    )
    data = cursor.fetchall()
    conn.close()
    return [dict(item) for item in data]

# 插入运动记录
def insert_sport_record(user_id: int, sport_type: str, sport_start: str, sport_end: str, avg_heart_rate: int, calorie: float):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """INSERT INTO sport_record 
        (user_id, sport_type, sport_start, sport_end, avg_heart_rate, calorie) 
        VALUES (?, ?, ?, ?, ?, ?)""",
        (user_id, sport_type, sport_start, sport_end, avg_heart_rate, calorie)
    )
    conn.commit()
    conn.close()
    return {"status": "success", "msg": "运动记录插入成功"}

# 查询用户运动记录
def get_sport_record_by_user(user_id: int, limit: int = 7):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """SELECT id, sport_type, sport_start, sport_end, avg_heart_rate, calorie 
        FROM sport_record WHERE user_id=? ORDER BY sport_start DESC LIMIT ?""",
        (user_id, limit)
    )
    data = cursor.fetchall()
    conn.close()
    return [dict(item) for item in data]