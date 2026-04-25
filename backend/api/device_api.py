# 设备当前态/历史曲线接口
from fastapi import APIRouter, HTTPException, Query

from repository.iot_repo import get_device_history_events, get_latest_device_event

router = APIRouter()


def _format_latest(record: dict):
    return {
        "device_id": record.get("device_id"),
        "seq": record.get("last_seq"),
        "timestamp": record.get("display_time_ms"),
        "server_received_at": record.get("last_server_received_at"),
        "last_ts_device_ms": record.get("last_ts_device_ms"),
        "temp": record.get("temp"),
        "heart_rate": record.get("heart_rate"),
        "spo2": record.get("spo2"),
        "valid_temp": record.get("valid_temp"),
        "valid_heart_rate": record.get("valid_heart_rate"),
        "valid_spo2": record.get("valid_spo2"),
        "reason": record.get("reason"),
        "contact": record.get("contact"),
        "signal": record.get("signal"),
        "updated_at": record.get("updated_at"),
    }


def _format_history_point(record: dict):
    return {
        "timestamp": record.get("display_time_ms"),
        "server_received_at": record.get("server_received_at"),
        "device_time_ms": record.get("ts_device_ms"),
        "seq": record.get("seq"),
        "temp": record.get("temp"),
        "heart_rate": record.get("heart_rate"),
        "spo2": record.get("spo2"),
        "valid_temp": record.get("valid_temp"),
        "valid_heart_rate": record.get("valid_heart_rate"),
        "valid_spo2": record.get("valid_spo2"),
        "reason": record.get("reason"),
        "contact": record.get("contact"),
        "signal": record.get("signal"),
    }


@router.get("/api/device/{device_id}/latest")
async def get_device_latest(device_id: str):
    result = get_latest_device_event(device_id=device_id)
    if result is None:
        raise HTTPException(status_code=404, detail="设备不存在或暂无数据")
    return {"code": 200, "msg": "查询成功", "data": _format_latest(result)}


@router.get("/api/device/{device_id}/history")
async def get_device_history(
    device_id: str, seconds: int = Query(default=600, ge=30, le=1800)
):
    result = get_device_history_events(device_id=device_id, seconds=seconds)
    return {
        "code": 200,
        "msg": "查询成功",
        "data": {
            "device_id": device_id,
            "seconds": seconds,
            "points": [_format_history_point(item) for item in result],
        },
    }
