# JWT工具
import jwt
from datetime import datetime, timedelta
from config.settings import SECRET_KEY


# 生成token
def generate_token(user_id: int, username: str):
    payload = {
        "user_id": user_id,
        "username": username,
        "exp": datetime.utcnow() + timedelta(hours=240),  # 240小时过期
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
    return token


# 验证token
def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return {"status": "success", "data": payload}
    except jwt.ExpiredSignatureError:
        return {"status": "error", "msg": "token已过期"}
    except jwt.InvalidTokenError:
        return {"status": "error", "msg": "token无效"}
