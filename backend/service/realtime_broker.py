# 实时推送中枢
import asyncio
import logging
import threading
import time
from collections import defaultdict
from datetime import datetime

from fastapi import WebSocket

logger = logging.getLogger(__name__)

_app_loop: asyncio.AbstractEventLoop | None = None
_device_connections: dict[str, set[WebSocket]] = defaultdict(set)
_pending_updates: dict[str, dict] = {}
_device_contact_since_ms: dict[str, int] = {}
_state_lock = threading.Lock()
_flush_task: asyncio.Task | None = None
_flush_interval_seconds = 0.25
_collecting_window_ms = 30_000


def set_app_loop(loop: asyncio.AbstractEventLoop):
    global _app_loop, _flush_task
    _app_loop = loop
    if _flush_task is None:
        _flush_task = loop.create_task(_flush_loop())


async def register_device_socket(device_id: str, websocket: WebSocket):
    with _state_lock:
        _device_connections[device_id].add(websocket)


async def unregister_device_socket(device_id: str, websocket: WebSocket):
    with _state_lock:
        sockets = _device_connections.get(device_id)
        if not sockets:
            return
        sockets.discard(websocket)
        if not sockets:
            _device_connections.pop(device_id, None)


def queue_device_update(device_id: str, payload: dict):
    decorated = _decorate_snapshot(device_id, payload)
    with _state_lock:
        _pending_updates[device_id] = decorated


async def _flush_loop():
    while True:
        await asyncio.sleep(_flush_interval_seconds)
        with _state_lock:
            pending = dict(_pending_updates)
            _pending_updates.clear()

        if not pending:
            continue

        for device_id, payload in pending.items():
            await _push_to_device_sockets(device_id, payload)


async def _push_to_device_sockets(device_id: str, payload: dict):
    with _state_lock:
        sockets = list(_device_connections.get(device_id, set()))

    if not sockets:
        return

    disconnected: list[WebSocket] = []
    for websocket in sockets:
        try:
            await websocket.send_json(payload)
        except Exception:
            disconnected.append(websocket)

    if disconnected:
        with _state_lock:
            for websocket in disconnected:
                _device_connections.get(device_id, set()).discard(websocket)


def _decorate_snapshot(device_id: str, payload: dict):
    snapshot = dict(payload)
    contact = snapshot.get("contact")
    signal = snapshot.get("signal")
    now_ms = int(time.time() * 1000)
    valid_heart_rate = snapshot.get("valid_heart_rate")
    valid_spo2 = snapshot.get("valid_spo2")
    has_detectable_vitals = (
        valid_heart_rate == 1
        and valid_spo2 == 1
        and snapshot.get("heart_rate") is not None
        and snapshot.get("spo2") is not None
    )

    if contact == 1:
        with _state_lock:
            contact_since_ms = _device_contact_since_ms.get(device_id)
            if contact_since_ms is None:
                _device_contact_since_ms[device_id] = now_ms
                contact_since_ms = now_ms
    else:
        with _state_lock:
            _device_contact_since_ms.pop(device_id, None)
        contact_since_ms = None

    if contact == 0:
        status = "离线"
    elif (
        contact_since_ms is not None
        and now_ms - contact_since_ms < _collecting_window_ms
    ):
        status = "采集中"
    elif not has_detectable_vitals:
        status = "信号差"
    elif signal is not None and float(signal) < 0.2:
        status = "信号差"
    else:
        status = "正常"

    snapshot["status"] = status
    snapshot["status_text"] = status
    snapshot["status_color"] = _status_color(status)
    snapshot["hint_text"] = _status_hint(status)
    snapshot["timestamp"] = _format_timestamp_text(
        snapshot.get("timestamp_ms")
    ) or snapshot.get("timestamp", "")

    if status == "离线":
        snapshot["heart_rate"] = None
        snapshot["spo2"] = None
        snapshot["temp"] = None
        snapshot["valid_heart_rate"] = 0
        snapshot["valid_spo2"] = 0
        snapshot["valid_temp"] = 0
    elif status == "采集中":
        snapshot["hint_text"] = "请保持30s手指放在红光上面"

    return snapshot


def _status_color(status: str):
    return {
        "离线": "#9CA3AF",
        "采集中": "#F59E0B",
        "正常": "#22C55E",
        "信号差": "#EF4444",
    }.get(status, "#3B82F6")


def _status_hint(status: str):
    return {
        "离线": "请将手指放到 MAX30102 红光上方",
        "采集中": "请保持30s手指放在红光上面",
        "正常": "数据稳定，可持续采集",
        "信号差": "请重新调整手指位置，保持稳定",
    }.get(status, "")


def _format_timestamp_text(timestamp_ms):
    if not timestamp_ms:
        return ""
    dt = datetime.fromtimestamp(int(timestamp_ms) / 1000)
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def broadcast_device_update(device_id: str, payload: dict):
    if _app_loop is None:
        logger.debug("Realtime broker loop not ready; skip push for %s", device_id)
        return

    queue_device_update(device_id, payload)


def shutdown_realtime_broker():
    global _flush_task
    if _flush_task is not None:
        _flush_task.cancel()
        _flush_task = None
