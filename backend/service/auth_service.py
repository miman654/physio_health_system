# 登录业务

import sqlite3
from utils.jwt_util import generate_token
from config.settings import DB_PATH

def login_service(username: str, password: str):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT id, username FROM users WHERE username=? AND password=?", (username, password))
    user = cursor.fetchone()
    conn.close()
    if not user:
        return {"status": "error", "msg": "用户名或密码错误"}
    # 生成JWT token
    token = generate_token(user[0], user[1])
    return {
        "status": "success",
        "data": {
            "user_id": user[0],
            "username": user[1],
            "token": token
        }
    }