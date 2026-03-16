# 登录业务
from utils.jwt_util import generate_token
from repository.user_repo import get_user_by_username_and_pwd


def login_service(username: str, password: str):
    user = get_user_by_username_and_pwd(username, password)
    if not user:
        return {"status": "error", "msg": "用户名或密码错误"}

    # 生成JWT token
    token = generate_token(user["id"], user["username"])
    return {
        "status": "success",
        "data": {"user_id": user["id"], "username": user["username"], "token": token},
    }
