# 用户数据操作
from .db import get_db_connection


# 根据用户名和密码查询用户（只查询活跃用户）
def get_user_by_username_and_pwd(username: str, password: str):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, username, age, weight, height, gender FROM users WHERE username=? AND password=? AND is_active=1",
        (username, password),
    )
    user = cursor.fetchone()
    conn.close()
    return dict(user) if user else None


# 根据用户ID查询用户信息（默认只查询活跃用户）
def get_user_by_id(user_id: int, include_inactive: bool = False):
    conn = get_db_connection()
    cursor = conn.cursor()

    if include_inactive:
        cursor.execute(
            "SELECT id, username, age, weight, height, gender, is_active FROM users WHERE id=?",
            (user_id,),
        )
    else:
        cursor.execute(
            "SELECT id, username, age, weight, height, gender FROM users WHERE id=? AND is_active=1",
            (user_id,),
        )

    user = cursor.fetchone()
    conn.close()
    return dict(user) if user else None


# 创建新用户
def create_user(
    username: str,
    password: str,
    age: int = None,
    weight: float = None,
    height: float = None,
    gender: str = None,
):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO users (username, password, age, weight, height, gender, create_time)
        VALUES (?, ?, ?, ?, ?, ?, datetime('now', 'localtime'))
        """,
        (username, password, age, weight, height, gender),
    )
    user_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return user_id


# 更新用户基础资料
def update_user_profile(
    user_id: int,
    age: int | None = None,
    weight: float | None = None,
    height: float | None = None,
):
    conn = get_db_connection()
    cursor = conn.cursor()

    fields = []
    values = []

    if age is not None:
        fields.append("age = ?")
        values.append(age)
    if weight is not None:
        fields.append("weight = ?")
        values.append(weight)
    if height is not None:
        fields.append("height = ?")
        values.append(height)

    if not fields:
        conn.close()
        return get_user_by_id(user_id, include_inactive=False)

    values.append(user_id)
    cursor.execute(
        f"UPDATE users SET {', '.join(fields)} WHERE id = ? AND is_active = 1",
        values,
    )
    conn.commit()
    conn.close()
    return get_user_by_id(user_id, include_inactive=False)


# 检查用户名是否存在
def check_username_exists(username: str):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM users WHERE username=?", (username,))
    user = cursor.fetchone()
    conn.close()
    return user is not None


# 删除用户（硬删除）
def delete_user(user_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 开启事务
        cursor.execute("BEGIN TRANSACTION")

        # 删除相关数据（根据外键约束顺序）
        cursor.execute("DELETE FROM sport_record WHERE user_id=?", (user_id,))
        cursor.execute("DELETE FROM sleep_record WHERE user_id=?", (user_id,))
        cursor.execute("DELETE FROM physio_data WHERE user_id=?", (user_id,))
        cursor.execute("DELETE FROM users WHERE id=?", (user_id,))

        conn.commit()
        return True
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


# 软删除用户
def soft_delete_user(user_id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET is_active = 0 WHERE id = ?", (user_id,))
    conn.commit()
    conn.close()
    return True
