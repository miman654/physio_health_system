 # 数据上传/查询接口
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from service.data_service import (
    upload_physio_data_service, get_physio_data_service,
    upload_sleep_record_service, get_sleep_record_service,
    upload_sport_record_service, get_sport_record_service,
    generate_mock_physio_data
)

router = APIRouter()

# ==================== 生理数据接口 ====================
# 生理数据上传请求模型
class PhysioDataRequest(BaseModel):
    user_id: int
    heart_rate: int
    spo2: int
    temp: float
    scene: int = 0  # 0=静息 1=运动 2=睡眠

# 上传生理数据
@router.post("/upload/physio")
async def upload_physio_data(request: PhysioDataRequest):
    result = upload_physio_data_service(
        user_id=request.user_id,
        heart_rate=request.heart_rate,
        spo2=request.spo2,
        temp=request.temp,
        scene=request.scene
    )
    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result["msg"])
    return {"code": 200, "msg": result["msg"], "data": None}

# 查询生理数据
@router.get("/query/physio")
async def query_physio_data(
    user_id: int,
    limit: int = Query(default=10, ge=1, le=100)  # 限制查询条数1-100
):
    result = get_physio_data_service(user_id=user_id, limit=limit)
    return {"code": 200, "msg": "查询成功", "data": result["data"]}

# 生成模拟生理数据（替代硬件，前端可直接调用）
@router.get("/mock/physio")
async def mock_physio_data(
    user_id: int,
    scene: int = Query(default=0, ge=0, le=2)  # 0=静息 1=运动 2=睡眠
):
    result = generate_mock_physio_data(user_id=user_id, scene=scene)
    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result["msg"])
    return {"code": 200, "msg": f"模拟{['静息','运动','睡眠'][scene]}生理数据生成成功", "data": None}

# ==================== 睡眠记录接口 ====================
# 睡眠记录上传请求模型
class SleepRecordRequest(BaseModel):
    user_id: int
    sleep_start: str  # 格式：2026-03-04 23:00:00
    sleep_end: str    # 格式：2026-03-05 07:00:00
    sleep_score: int  # 0-100分
    deep_sleep_duration: int  # 深睡时长（分钟）
    light_sleep_duration: int # 浅睡时长（分钟）

# 上传睡眠记录
@router.post("/upload/sleep")
async def upload_sleep_record(request: SleepRecordRequest):
    result = upload_sleep_record_service(
        user_id=request.user_id,
        sleep_start=request.sleep_start,
        sleep_end=request.sleep_end,
        sleep_score=request.sleep_score,
        deep_sleep=request.deep_sleep_duration,
        light_sleep=request.light_sleep_duration
    )
    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result["msg"])
    return {"code": 200, "msg": result["msg"], "data": None}

# 查询睡眠记录
@router.get("/query/sleep")
async def query_sleep_record(
    user_id: int,
    limit: int = Query(default=7, ge=1, le=30)  # 默认查近7天
):
    result = get_sleep_record_service(user_id=user_id, limit=limit)
    return {"code": 200, "msg": "查询成功", "data": result["data"]}

# ==================== 运动记录接口 ====================
# 运动记录上传请求模型
class SportRecordRequest(BaseModel):
    user_id: int
    sport_type: str  # 步行/跑步/骑行
    sport_start: str # 格式：2026-03-04 18:00:00
    sport_end: str   # 格式：2026-03-04 19:00:00
    avg_heart_rate: int  # 平均心率
    calorie: float       # 消耗卡路里

# 上传运动记录
@router.post("/upload/sport")
async def upload_sport_record(request: SportRecordRequest):
    result = upload_sport_record_service(
        user_id=request.user_id,
        sport_type=request.sport_type,
        sport_start=request.sport_start,
        sport_end=request.sport_end,
        avg_heart_rate=request.avg_heart_rate,
        calorie=request.calorie
    )
    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result["msg"])
    return {"code": 200, "msg": result["msg"], "data": None}

# 查询运动记录
@router.get("/query/sport")
async def query_sport_record(
    user_id: int,
    limit: int = Query(default=7, ge=1, le=30)  # 默认查近7天
):
    result = get_sport_record_service(user_id=user_id, limit=limit)
    return {"code": 200, "msg": "查询成功", "data": result["data"]}