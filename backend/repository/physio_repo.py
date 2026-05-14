# 生理数据操作
import datetime
from .db import get_db_connection


# 插入生理数据（修改后）
def insert_physio_data(
    user_id: int,
    heart_rate: int = None,
    spo2: int = None,
    temp: float = None,
    scene: int = 0,
    timestamp: str = None,
    suggestion: str = None,
):
    conn = get_db_connection()
    cursor = conn.cursor()
    if timestamp is None:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    cursor.execute(
        """INSERT INTO physio_data 
        (user_id, heart_rate, spo2, temp, scene, timestamp, suggestion) 
        VALUES (?, ?, ?, ?, ?, ?, ?)""",
        (user_id, heart_rate, spo2, temp, scene, timestamp, suggestion),
    )
    conn.commit()
    conn.close()
    return {"status": "success", "msg": "数据插入成功"}


# 查询用户生理数据（按时间倒序）
def get_physio_data_by_user(user_id: int, limit: int = 10):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """SELECT id, user_id, heart_rate, spo2, temp, scene, timestamp, suggestion 
        FROM physio_data WHERE user_id=? ORDER BY timestamp DESC LIMIT ?""",
        (user_id, limit),
    )
    data = cursor.fetchall()
    conn.close()
    # 转换为列表字典
    return [dict(item) for item in data]


# 插入睡眠记录（修改后）
def insert_sleep_record(
    user_id: int,
    sleep_start: str,
    sleep_end: str,
    sleep_score: int,
    deep_sleep_duration: int,
    avg_heart_rate: int,
    avg_spo2: int,
    avg_temp: float,
    suggestion: str,
):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """INSERT INTO sleep_record 
        (user_id, sleep_start, sleep_end, sleep_score, deep_sleep_duration, avg_heart_rate, avg_spo2, avg_temp, suggestion) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user_id,
            sleep_start,
            sleep_end,
            sleep_score,
            deep_sleep_duration,
            avg_heart_rate,
            avg_spo2,
            avg_temp,
            suggestion,
        ),
    )
    conn.commit()
    conn.close()
    return {"status": "success", "msg": "睡眠记录插入成功"}


# 查询用户睡眠记录（修改后）
def get_sleep_record_by_user(user_id: int, limit: int = 7):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """SELECT id, user_id, sleep_start, sleep_end, sleep_score, deep_sleep_duration, avg_heart_rate, avg_spo2, avg_temp, suggestion 
        FROM sleep_record WHERE user_id=? ORDER BY sleep_start DESC LIMIT ?""",
        (user_id, limit),
    )
    data = cursor.fetchall()
    conn.close()
    return [dict(item) for item in data]


# 插入运动记录（修改）
def insert_sport_record(
    user_id: int,
    sport_type: str,
    sport_start: str,
    sport_end: str,
    avg_heart_rate: int,
    avg_spo2: int,
    avg_temp: float,
    calorie: float,
    suggestion: str,
):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """INSERT INTO sport_record 
        (user_id, sport_type, sport_start, sport_end, avg_heart_rate, avg_spo2, avg_temp, calorie, suggestion) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            user_id,
            sport_type,
            sport_start,
            sport_end,
            avg_heart_rate,
            avg_spo2,
            avg_temp,
            calorie,
            suggestion,
        ),
    )
    conn.commit()
    conn.close()
    return {"status": "success", "msg": "运动记录插入成功"}


# 查询用户运动记录（修改）
def get_sport_record_by_user(user_id: int, limit: int = 7):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """SELECT id, sport_type, sport_start, sport_end, avg_heart_rate, avg_spo2, avg_temp, calorie, suggestion 
        FROM sport_record WHERE user_id=? ORDER BY sport_start DESC LIMIT ?""",
        (user_id, limit),
    )
    data = cursor.fetchall()
    conn.close()
    return [dict(item) for item in data]


def get_sport_records_by_user_in_range(user_id: int, start_time: str, end_time: str):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """SELECT id, sport_type, sport_start, sport_end, avg_heart_rate, avg_spo2, avg_temp, calorie, suggestion 
        FROM sport_record 
        WHERE user_id = ? AND sport_start >= ? AND sport_start < ?
        ORDER BY sport_start ASC""",
        (user_id, start_time, end_time),
    )
    data = cursor.fetchall()
    conn.close()
    return [dict(item) for item in data]


def get_sport_calendar_by_user(user_id: int, year: int, month: int):
    conn = get_db_connection()
    cursor = conn.cursor()

    month_start = f"{year:04d}-{month:02d}-01"
    if month == 12:
        next_month_start = f"{year + 1:04d}-01-01"
    else:
        next_month_start = f"{year:04d}-{month + 1:02d}-01"

    cursor.execute(
        """SELECT
            substr(sport_start, 1, 10) AS sport_date,
            COUNT(*) AS workout_count,
            COALESCE(SUM(calorie), 0) AS total_calorie,
            MIN(sport_start) AS first_start,
            MAX(sport_end) AS last_end
        FROM sport_record
        WHERE user_id = ?
          AND sport_start >= ?
          AND sport_start < ?
        GROUP BY substr(sport_start, 1, 10)
        ORDER BY sport_date""",
        (user_id, month_start, next_month_start),
    )

    data = cursor.fetchall()
    conn.close()
    return [dict(item) for item in data]
