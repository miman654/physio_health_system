from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
import sqlite3
import datetime
import hashlib
# 注意：这里导入的函数名是 generate_token（和 jwt_util.py 保持一致）
from utils.jwt_util import generate_token

# 创建路由实例，会被 main.py 挂载到 /auth 前缀下
router = APIRouter()

# ==================== 请求模型定义 ====================
# 登录请求模型（校验前端传入的参数）
class LoginRequest(BaseModel):
    username: str
    password: str

# 注册请求模型（age/weight 可选，允许为空）
class RegisterRequest(BaseModel):
    username: str
    password: str
    age: int | None = None
    weight: float | None = None

# ==================== 核心接口 ====================
# 登录接口 - POST /auth/login
@router.post("/login")
async def user_login(request: LoginRequest):
    # 1. 连接数据库
    conn = sqlite3.connect("physio_data.db")
    cursor = conn.cursor()

    try:
        # 2. 对密码进行哈希处理
        hashed_password = hashlib.sha256(request.password.encode()).hexdigest()

        # 3. 查询用户是否存在，密码是否匹配
        cursor.execute('''
            SELECT id FROM users WHERE username = ? AND password = ?
        ''', (request.username, hashed_password))
        user = cursor.fetchone()

        if not user:
            # 用户名或密码错误，返回401
            raise HTTPException(status_code=401, detail="用户名或密码错误")

        # 4. 生成JWT token（user_id是查询结果的第一个字段）
        user_id = user[0]
        token = generate_token(user_id=user_id, username=request.username)

        # 5. 返回成功结果
        return {
            "code": 200,
            "msg": "登录成功",
            "data": {
                "user_id": user_id,
                "username": request.username,
                "token": token
            }
        }
    finally:
        # 无论是否报错，都关闭数据库连接
        conn.close()

# 注册接口 - POST /auth/register
@router.post("/register")
async def user_register(request: RegisterRequest):
    # 1. 连接数据库
    conn = sqlite3.connect("physio_data.db")
    cursor = conn.cursor()

    try:
        # 2. 对密码进行哈希处理
        hashed_password = hashlib.sha256(request.password.encode()).hexdigest()

        # 3. 插入新用户（用户名唯一，重复会抛 IntegrityError）
        create_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cursor.execute('''
            INSERT INTO users (username, password, age, weight, create_time)
            VALUES (?, ?, ?, ?, ?)
        ''', (
            request.username,
            hashed_password,
            request.age,
            request.weight,
            create_time
        ))
        conn.commit()

        # 4. 返回成功结果
        return {
            "code": 200,
            "msg": "用户注册成功",
            "data": None
        }
    except sqlite3.IntegrityError:
        # 用户名重复，返回400
        raise HTTPException(status_code=400, detail="用户名已存在")
    finally:
        # 关闭数据库连接
        conn.close()

