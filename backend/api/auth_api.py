# 登录鉴权接口

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from service.auth_service import login_service

router = APIRouter()

# 登录请求模型
class LoginRequest(BaseModel):
    username: str
    password: str

@router.post("/login")
async def login(request: LoginRequest):
    result = login_service(request.username, request.password)
    if result["status"] == "error":
        raise HTTPException(status_code=401, detail=result["msg"])
    return {
        "code": 200,
        "msg": "登录成功",
        "data": result["data"]
    }