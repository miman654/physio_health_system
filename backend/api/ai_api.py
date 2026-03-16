# AI营养/体检分析接口
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from service.ai_service import ai_physio_analysis_service, ai_sport_nutrition_service

router = APIRouter()


# ==================== AI健康分析接口 ====================
# 查询用户AI生理数据分析
@router.get("/physio/analysis")
async def ai_physio_analysis(user_id: int):
    result = ai_physio_analysis_service(user_id=user_id)
    # 检查返回状态
    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result.get("msg", "分析失败"))

    # 确保 data 存在
    if "data" not in result:
        return {"code": 200, "msg": "分析成功", "data": None}
    return {"code": 200, "msg": "分析成功", "data": result["data"]}


# ==================== AI运动营养建议接口 ====================
# 运动营养建议请求模型
class SportNutritionRequest(BaseModel):
    user_id: int
    sport_type: str  # 步行/跑步/骑行
    sport_duration: int  # 运动时长（分钟）
    sport_time: str  # 运动时间（ISO格式字符串，如2023-10-01T12:00:00）


# 获取运动营养建议
# 获取运动营养建议
@router.post("/sport/nutrition")
async def ai_sport_nutrition(request: SportNutritionRequest):
    result = ai_sport_nutrition_service(
        user_id=request.user_id,
        sport_type=request.sport_type,
        sport_duration=request.sport_duration,
        sport_time=request.sport_time,
    )
    # 检查返回状态
    if result["status"] == "error":
        raise HTTPException(status_code=400, detail=result.get("msg", "建议生成失败"))

    # 确保 data 存在
    if "data" not in result:
        return {"code": 200, "msg": "建议生成成功", "data": None}
    return {"code": 200, "msg": "建议生成成功", "data": result["data"]}
