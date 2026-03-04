# 数据库初始化

import sqlite3
import datetime

def init_db():
    # 连接数据库（不存在则创建）
    conn = sqlite3.connect("physio_data.db")
    cursor = conn.cursor()

    # 1. 用户表
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        age INTEGER,
        weight REAL,
        create_time TEXT NOT NULL
    )
    ''')

    # 2. 生理数据表（含场景字段）
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS physio_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        heart_rate INTEGER NOT NULL,
        spo2 INTEGER NOT NULL,
        temp REAL NOT NULL,
        scene INTEGER NOT NULL DEFAULT 0,  
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''') # 0=静息 1=运动 2=睡眠

    # 3. 睡眠记录表
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS sleep_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        sleep_start TEXT NOT NULL,
        sleep_end TEXT NOT NULL,
        sleep_score INTEGER NOT NULL,
        deep_sleep_duration INTEGER,
        light_sleep_duration INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''')

    # 4. 运动记录表
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS sport_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        sport_type TEXT NOT NULL, 
        sport_start TEXT NOT NULL,
        sport_end TEXT NOT NULL,
        avg_heart_rate INTEGER,
        calorie REAL,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''') #sport_type TEXT NOT NULL,   步行/跑步/骑行

    # 插入测试用户（test/123456）
    try:
        cursor.execute('''
        INSERT INTO users (username, password, age, weight, create_time) 
        VALUES (?, ?, ?, ?, ?)
        ''', ("test", "123456", 25, 60.0, datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
        print("测试用户创建成功：test/123456")
    except sqlite3.IntegrityError:
        print("测试用户已存在")

    conn.commit()
    conn.close()

if __name__ == "__main__":
    init_db()