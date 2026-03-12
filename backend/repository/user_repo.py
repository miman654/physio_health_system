# 用户数据操作
from .db import get_db_connection

# 根据用户名和密码查询用户
def get_user_by_username_and_pwd(username: str, password: str):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, username, age, weight FROM users WHERE username=? AND password=?",
        (username, password)
    )
    user = cursor.fetchone()
    conn.close()
    # 转换为字典（方便后续处理）
    return dict(user) if user else None

# 根据用户ID查询用户信息
def get_user_by_id(user_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, username, age, weight FROM users WHERE id=?",
        (user_id,)
    )
    user = cursor.fetchone()
    conn.close()
    return dict(user) if user else None