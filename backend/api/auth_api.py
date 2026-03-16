from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from fastapi.security import HTTPBearer
import sqlite3
import datetime
import hashlib

# 注意：这里导入的函数名是 generate_token（和 jwt_util.py 保持一致）
from service.auth_service import login_service
from utils.jwt_util import generate_token, verify_token

security = HTTPBearer()


# JWT依赖函数
def get_current_user(credentials=Depends(security)):
    token = credentials.credentials
    result = verify_token(token)
    if result["status"] != "success":
        raise HTTPException(status_code=401, detail="无效的token")
    return result["data"]


# 创建路由实例，会被 main.py 挂载到 /auth 前缀下
router = APIRouter()


# ==================== 请求模型定义 ====================
# 登录请求模型（校验前端传入的参数）
class LoginRequest(BaseModel):
    username: str
    password: str


# 注册请求模型（age/weight/height 可选，允许为空）
# 注册请求模型（age/weight/height/gender 可选，允许为空）
class RegisterRequest(BaseModel):
    username: str
    password: str
    age: int | None = None
    weight: float | None = None
    height: float | None = None
    gender: str | None = None  # 新增性别字段


# ==================== 核心接口 ====================
# 注册接口 - POST /auth/register
@router.post("/register")
async def user_register(request: RegisterRequest):
    from repository.user_repo import check_username_exists, create_user

    # 1. 检查用户名是否已存在
    if check_username_exists(request.username):
        raise HTTPException(status_code=400, detail="用户名已存在")

    # 2. 对密码进行哈希处理
    hashed_password = hashlib.sha256(request.password.encode()).hexdigest()

    # 3. 创建新用户
    try:
        user_id = create_user(
            username=request.username,
            password=hashed_password,
            age=request.age,
            weight=request.weight,
            height=request.height,
            gender=request.gender,  # 传入性别字段
        )
        return {"code": 200, "msg": "用户注册成功", "data": {"user_id": user_id}}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"注册失败: {str(e)}")


# 登录接口 - POST /auth/login
@router.post("/login")
async def user_login(request: LoginRequest):
    # 对密码进行哈希处理
    hashed_password = hashlib.sha256(request.password.encode()).hexdigest()

    # 调用service层
    result = login_service(request.username, hashed_password)

    if result["status"] == "error":
        raise HTTPException(status_code=401, detail=result["msg"])

    return {"code": 200, "msg": "登录成功", "data": result["data"]}


# 退出登录接口 - POST /auth/logout
@router.post("/logout")
async def user_logout(
    current_user: dict = Depends(get_current_user), credentials=Depends(security)
):
    from utils.token_blacklist import blacklist
    from utils.jwt_util import verify_token

    token = credentials.credentials
    # 验证token获取过期时间
    result = verify_token(token)
    if result["status"] == "success":
        # 解码获取过期时间
        import jwt
        from config.settings import SECRET_KEY

        payload = jwt.decode(
            token, SECRET_KEY, algorithms=["HS256"], options={"verify_exp": False}
        )
        expire_time = payload["exp"]
        # 加入黑名单
        blacklist.add(token, expire_time)

    return {"code": 200, "msg": "退出登录成功", "data": None}


# 注销账号接口 - DELETE /auth/account
@router.delete("/account")
async def delete_account(
    current_user: dict = Depends(get_current_user), credentials=Depends(security)
):
    from repository.user_repo import soft_delete_user
    from utils.token_blacklist import blacklist
    import jwt
    from config.settings import SECRET_KEY

    user_id = current_user["user_id"]
    token = credentials.credentials

    try:
        # 1. 软删除用户（设置 is_active = 0）
        soft_delete_user(user_id)

        # 2. 将当前token加入黑名单（立即失效）
        payload = jwt.decode(
            token, SECRET_KEY, algorithms=["HS256"], options={"verify_exp": False}
        )
        expire_time = payload["exp"]
        blacklist.add(token, expire_time)

        return {"code": 200, "msg": "账号注销成功", "data": None}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"注销失败: {str(e)}")


# 获取用户信息接口
@router.get("/userinfo")
async def get_user_info(current_user: dict = Depends(get_current_user)):
    from repository.user_repo import get_user_by_id

    user_id = current_user["user_id"]
    user = get_user_by_id(user_id, include_inactive=False)  # 只查活跃用户

    if not user:
        raise HTTPException(status_code=404, detail="用户不存在或账号已注销")

    return {
        "code": 200,
        "msg": "获取成功",
        "data": {
            "username": user["username"],
            "age": user["age"],
            "gender": user["gender"],
            "weight": user["weight"],
            "height": user["height"],
        },
    }
