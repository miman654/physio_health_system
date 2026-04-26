# 数据库初始化

import sqlite3
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

    # 2.1 物联网原始事件表（全量历史）
    cursor.execute(
        """
    CREATE TABLE IF NOT EXISTS iot_raw_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        topic TEXT NOT NULL,
        seq INTEGER,
        ts_device_ms INTEGER,
        server_received_at INTEGER NOT NULL,
        payload_json TEXT NOT NULL,
        parse_ok INTEGER NOT NULL DEFAULT 1,
        valid_temp INTEGER,
        valid_heart_rate INTEGER,
        valid_spo2 INTEGER,
        reason TEXT,
        contact INTEGER,
        signal REAL,
        ingest_error TEXT
    )
    """
    )

    cursor.execute(
        "CREATE INDEX IF NOT EXISTS idx_raw_device_time ON iot_raw_events (device_id, server_received_at)"
    )
    cursor.execute(
        "CREATE INDEX IF NOT EXISTS idx_raw_device_seq ON iot_raw_events (device_id, seq)"
    )
    cursor.execute(
        "CREATE INDEX IF NOT EXISTS idx_raw_topic_time ON iot_raw_events (topic, server_received_at)"
    )

    # 2.2 设备最新态表（每个 device_id 只保留一行）
    cursor.execute(
        """
    CREATE TABLE IF NOT EXISTS iot_device_latest (
        device_id TEXT PRIMARY KEY,
        last_raw_event_id INTEGER,
        last_seq INTEGER,
        last_ts_device_ms INTEGER,
        last_server_received_at INTEGER NOT NULL,
        display_time_ms INTEGER NOT NULL,
        payload_json TEXT NOT NULL,
        temp REAL,
        heart_rate INTEGER,
        spo2 REAL,
        valid_temp INTEGER,
        valid_heart_rate INTEGER,
        valid_spo2 INTEGER,
        reason TEXT,
        contact INTEGER,
        signal REAL,
        updated_at INTEGER NOT NULL
    )
    """
    )

    cursor.execute("PRAGMA table_info(iot_device_latest)")
    latest_columns = {row[1] for row in cursor.fetchall()}
    if "display_time_ms" not in latest_columns:
        cursor.execute(
            "ALTER TABLE iot_device_latest ADD COLUMN display_time_ms INTEGER NOT NULL DEFAULT 0"
        )
        cursor.execute(
            "UPDATE iot_device_latest SET display_time_ms = CASE WHEN last_ts_device_ms IS NOT NULL AND last_ts_device_ms > 0 THEN last_ts_device_ms ELSE last_server_received_at END"
        )

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
    print("iot_raw_events / iot_device_latest / sport_record 表创建成功")

    conn.commit()
    conn.close()


if __name__ == "__main__":
    init_db()
