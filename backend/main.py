# 后端入口文件
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

from api import auth_api, data_api, ai_api
from config.settings import PORT
from db_init import init_db

# 初始化APP
app = FastAPI(title="生理健康管理系统后端", version="1.0")


# 启动时初始化数据库（如果还没创建表则会自动创建）
@app.on_event("startup")
async def startup_event():
    init_db()


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

# WebSocket实时推送（硬件→后端→APP）
active_connections: list[WebSocket] = []  # 存储所有活跃的WebSocket连接


# WebSocket端点定义，路径参数user_id用于区分不同用户的连接
@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):
    # 接受WebSocket连接请求，并将连接添加到活跃连接列表中
    await websocket.accept()
    active_connections.append(websocket)
    try:
        # 持续监听WebSocket连接，接收硬件数据并推送给所有连接的客户端（Flutter）
        while True:
            # 接收硬件数据（开发期用测试数据模拟）
            data = await websocket.receive_json()
            # 推送给所有连接的客户端（Flutter）
            for connection in active_connections:
                await connection.send_json(data)
    except WebSocketDisconnect:
        active_connections.remove(websocket)


# 启动服务
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=PORT)
