# 数据库初始化

import sqlite3
import datetime
import hashlib
from pathlib import Path

from config.settings import DB_PATH


def init_db():
    # 连接数据库（不存在则创建），并确保目录存在
    db_path = Path(DB_PATH)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # 1. 创建或更新用户表
    cursor.execute(
        """
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        age INTEGER,
        gender TEXT, 
        weight REAL,
        height REAL,
        is_active INTEGER DEFAULT 1,  
        create_time TEXT NOT NULL
    )
    """
    )

    # 2. 生理数据表（含场景字段）
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS physio_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            heart_rate INTEGER,
            spo2 INTEGER,
            temp REAL,
            scene INTEGER NOT NULL DEFAULT 0,
            timestamp TEXT NOT NULL,
            suggestion TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
    )
    """
    )  # 0=静息 1=运动 2=睡眠

    # 3. 睡眠记录表
    cursor.execute(
        """
    CREATE TABLE IF NOT EXISTS sleep_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        sleep_start TEXT NOT NULL,
        sleep_end TEXT NOT NULL,
        sleep_score INTEGER NOT NULL,
        deep_sleep_duration INTEGER,
        avg_heart_rate INTEGER,
        avg_spo2 INTEGER,
        avg_temp REAL,
        suggestion TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    """
    )

    # 4. 直接创建新的 sport_record 表（已删除旧表处理逻辑）
    cursor.execute(
        """
    CREATE TABLE IF NOT EXISTS sport_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        sport_type TEXT NOT NULL, 
        sport_start TEXT NOT NULL,
        sport_end TEXT NOT NULL,
        avg_heart_rate INTEGER,
        avg_spo2 INTEGER,
        avg_temp REAL,
        calorie REAL,
        suggestion TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    """
    )
    print("sport_record 表创建成功")

    conn.commit()
    conn.close()


if __name__ == "__main__":
    init_db()
