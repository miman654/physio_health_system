# 后端入口文件
import asyncio
import os
import sys

from fastapi import FastAPI, Depends, HTTPException, WebSocket, WebSocketDisconnect

# FastAPI：主框架类
# Depends：依赖注入（用于获取数据库连接等）
# HTTPException：返回HTTP错误
# WebSocket：实时通信支持
# WebSocketDisconnect：处理断开连接
from fastapi.middleware.cors import (
    CORSMiddleware,
)  # 跨域中间件，解决Flutter请求被浏览器拦截的问题
import uvicorn  # ASGI服务器，用于运行FastAPI应用

# 确保项目根目录在 sys.path 首位（避免误用 venv 目录中同名模块）
sys.path.insert(0, os.path.dirname(__file__))

from api import auth_api, data_api, ai_api, device_api
from config.settings import PORT
from db_init import init_db
from service.iot_service import (
    build_ws_snapshot,
    start_iot_mqtt_ingest,
    stop_iot_mqtt_ingest,
)
from service.realtime_broker import (
    register_device_socket,
    set_app_loop,
    shutdown_realtime_broker,
    unregister_device_socket,
)
from repository.iot_repo import get_latest_device_event

# 在文件开头添加
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# 初始化APP
app = FastAPI(title="生理健康管理系统后端", version="1.0")


# 在路由注册后添加
@app.middleware("http")
async def log_requests(request, call_next):
    logger.info(f"Request: {request.method} {request.url}")
    response = await call_next(request)
    logger.info(f"Response: {response.status_code}")
    return response


# 启动时初始化数据库（如果还没创建表则会自动创建）
@app.on_event("startup")
async def startup_event():
    set_app_loop(asyncio.get_running_loop())
    init_db()
    start_iot_mqtt_ingest()


@app.on_event("shutdown")
async def shutdown_event():
    shutdown_realtime_broker()
    stop_iot_mqtt_ingest()


# 根据你的代码生成OpenAPI规范（JSON格式）
# 提供Swagger UI（漂亮页面）

# 跨域配置（解决Flutter跨域问题）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 开发期允许所有来源
    allow_credentials=True,  # 允许携带cookie
    allow_methods=["*"],  # 允许所有HTTP方法（GET、POST等）
    allow_headers=["*"],  # 允许所有HTTP头（Content-Type等）
)

# 注册路由 把不同模块的路由注册到主应用
# tags参数： 在API文档中分组显示
app.include_router(auth_api.router, prefix="/auth", tags=["用户鉴权"])
app.include_router(data_api.router, prefix="/data", tags=["生理数据"])
app.include_router(ai_api.router, prefix="/ai", tags=["AI服务"])
app.include_router(device_api.router, tags=["设备接入"])


# WebSocket实时推送（MQTT 入库后 -> 前端订阅）
@app.websocket("/ws/device/{device_id}")
async def websocket_device_latest(websocket: WebSocket, device_id: str):
    await websocket.accept()
    await register_device_socket(device_id, websocket)

    try:
        latest = get_latest_device_event(device_id=device_id)
        if latest:
            await websocket.send_json(
                {"type": "device_latest", "data": build_ws_snapshot(latest)}
            )

        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        await unregister_device_socket(device_id, websocket)


# 启动服务
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=PORT)
