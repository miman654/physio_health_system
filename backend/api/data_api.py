# 数据上传/查询接口
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from service.data_service import (
    upload_physio_data_service,
    get_physio_data_service,
    upload_sleep_record_service,
    get_sleep_record_service,
    upload_sport_record_service,
    get_sport_record_service,
    generate_mock_physio_data,
)

router = APIRouter()


# ==================== 生理数据接口 ====================
# 生理数据上传请求模型（修改）
class PhysioDataRequest(BaseModel):
    user_id: int
    timestamp: str = None  # 可选，不传则使用当前时间
    scene: int = 0  # 0=静息 1=运动 2=睡眠
    # 去掉 heart_rate, spo2, temp


# 上传生理数据（修改）
@router.post("/upload/physio")
async def upload_physio_data(request: PhysioDataRequest):
    result = upload_physio_data_service(
        user_id=request.user_id,
        timestamp=request.timestamp,
        scene=request.scene,
    )
    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result["msg"])

    return {
        "code": 200,
        "msg": result["msg"],
        "data": {
            "user_id": result.get("user_id"),
            "heart_rate": result.get("heart_rate"),
            "spo2": result.get("spo2"),
            "temp": result.get("temp"),
            "scene": result.get("scene"),
            "timestamp": result.get("timestamp"),
            "suggestion": result.get("suggestion"),
        },
    }


# 查询生理数据（修改返回格式）
@router.get("/query/physio")
async def query_physio_data(user_id: int, limit: int = Query(default=10, ge=1, le=100)):
    result = get_physio_data_service(user_id=user_id, limit=limit)
    return {
        "code": 200,
        "msg": "查询成功",
        "data": result["data"],  # 现在包含 suggestion 字段
    }


# 生成模拟生理数据（替代硬件，前端可直接调用）
@router.get("/mock/physio")
async def mock_physio_data(
    user_id: int, scene: int = Query(default=0, ge=0, le=2)  # 0=静息 1=运动 2=睡眠
):
    result = generate_mock_physio_data(user_id=user_id, scene=scene)
    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result["msg"])
    return {
        "code": 200,
        "msg": f"模拟{['静息','运动','睡眠'][scene]}生理数据生成成功",
        "data": None,
    }


# ==================== 睡眠记录接口 ====================
# 睡眠记录上传请求模型
class SleepRecordRequest(BaseModel):
    user_id: int
    sleep_start: str  # 格式：2026-03-04 23:00:00
    sleep_end: str  # 格式：2026-03-05 07:00:00


# 上传睡眠记录
@router.post("/upload/sleep")
async def upload_sleep_record(request: SleepRecordRequest):
    result = upload_sleep_record_service(
        user_id=request.user_id,
        sleep_start=request.sleep_start,
        sleep_end=request.sleep_end,
    )

    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result["msg"])

    # 返回数据包含所有字段
    return {
        "code": 200,
        "msg": result["msg"],
        "data": {
            "user_id": request.user_id,
            "sleep_start": request.sleep_start,
            "sleep_end": request.sleep_end,
            "sleep_duration": result.get("sleep_duration", 480),  # 分钟
            "sleep_duration_hours": result.get("sleep_duration_hours", 8.0),  # 小时
            "deep_sleep_duration": result.get("deep_sleep_duration", 120),
            "sleep_score": result.get("sleep_score", 80),
            "avg_heart_rate": result.get("avg_heart_rate", 58),
            "avg_spo2": result.get("avg_spo2", 97),
            "avg_temp": result.get("avg_temp", 36.2),
            "suggestion": result.get("suggestion", "睡眠质量良好，继续保持规律作息。"),
        },
    }


# 查询睡眠记录
@router.get("/query/sleep")
async def query_sleep_record(
    user_id: int, limit: int = Query(default=7, ge=1, le=30)  # 默认查近7天
):
    result = get_sleep_record_service(user_id=user_id, limit=limit)
    return {"code": 200, "msg": "查询成功", "data": result["data"]}


# ==================== 运动记录接口 ====================
# 运动记录上传请求模型（修改）# 运动记录上传请求模型（修改）
class SportRecordRequest(BaseModel):
    user_id: int
    sport_type: str  # 步行/跑步/骑行
    sport_start: str  # 格式：2026-03-04 18:00:00
    sport_end: str  # 格式：2026-03-04 19:00:00
    # 去掉 avg_heart_rate, avg_spo2, avg_temp, calorie


# 上传运动记录（修改）
@router.post("/upload/sport")
async def upload_sport_record(request: SportRecordRequest):

    result = upload_sport_record_service(
        user_id=request.user_id,
        sport_type=request.sport_type,
        sport_start=request.sport_start,
        sport_end=request.sport_end,
    )

    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result["msg"])

    # 返回数据包含所有字段
    return {
        "code": 200,
        "msg": result["msg"],
        "data": {
            "user_id": request.user_id,
            "sport_type": request.sport_type,
            "sport_start": request.sport_start,
            "sport_end": request.sport_end,
            "avg_heart_rate": result.get("avg_heart_rate", 120),  # 使用字典的get方法
            "avg_spo2": result.get("avg_spo2", 95),
            "avg_temp": result.get("avg_temp", 37.0),
            "calorie": result.get("calorie", 300.0),
            "suggestion": result.get("suggestion", "运动表现良好，继续保持！"),
        },
    }


# 查询运动记录（修改返回格式）
@router.get("/query/sport")
async def query_sport_record(
    user_id: int, limit: int = Query(default=7, ge=1, le=30)  # 默认查近7天
):
    result = get_sport_record_service(user_id=user_id, limit=limit)
    return {
        "code": 200,
        "msg": "查询成功",
        "data": result["data"],  # 现在包含所有新字段
    }
