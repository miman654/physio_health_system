# MQTT 订阅服务
import json
import logging
import threading

from paho.mqtt.client import Client

from config.settings import (
    MQTT_CLIENT_ID,
    MQTT_HOST,
    MQTT_KEEPALIVE,
    MQTT_PORT,
    MQTT_TOPIC,
)
from repository.iot_repo import get_latest_device_event, save_iot_event
from service.realtime_broker import broadcast_device_update

logger = logging.getLogger(__name__)

_mqtt_client: Client | None = None
_mqtt_lock = threading.Lock()


def _on_connect(client, userdata, flags, reason_code, properties=None):
    if reason_code == 0:
        logger.info("MQTT connected, subscribing to %s", MQTT_TOPIC)
        client.subscribe(MQTT_TOPIC)
    else:
        logger.error("MQTT connect failed: %s", reason_code)


def _on_message(client, userdata, msg):
    raw_payload = msg.payload.decode("utf-8", errors="replace")
    try:
        payload = json.loads(raw_payload)
        save_result = save_iot_event(
            topic=msg.topic, raw_payload=raw_payload, payload=payload, parse_ok=True
        )
        device_id = payload.get("device_id") or "unknown"
        if device_id != "unknown":
            latest = get_latest_device_event(device_id)
            if latest:
                broadcast_device_update(device_id, _build_ws_snapshot(latest))
    except Exception as exc:
        logger.exception("MQTT message ingest failed")
        save_iot_event(
            topic=msg.topic,
            raw_payload=raw_payload,
            payload=None,
            parse_ok=False,
            ingest_error=str(exc),
        )


def _build_ws_snapshot(latest_record: dict):
    if not latest_record:
        status = "后端无实时数据"
        return {
            "device_id": "unknown",
            "heart_rate": None,
            "spo2": None,
            "temp": None,
            "scene": 0,
            "timestamp": "",
            "timestamp_ms": None,
            "reason": "backend_empty",
            "contact": None,
            "signal": None,
            "seq": None,
            "valid_heart_rate": 0,
            "valid_spo2": 0,
            "valid_temp": 0,
            "status": status,
            "status_text": status,
            "hint_text": "等待硬件开始上报实时数据",
        }

    timestamp_ms = latest_record.get("display_time_ms")
    timestamp_text = _format_timestamp_ms(timestamp_ms)
    contact = latest_record.get("contact")
    signal = latest_record.get("signal")
    if contact == 0:
        status = "离线"
    elif signal is not None and float(signal) < 0.2:
        status = "信号差"
    else:
        status = "正常"
    return {
        "device_id": latest_record.get("device_id"),
        "heart_rate": latest_record.get("heart_rate"),
        "spo2": latest_record.get("spo2"),
        "temp": latest_record.get("temp"),
        "scene": 0,
        "timestamp": timestamp_text,
        "timestamp_ms": timestamp_ms,
        "reason": latest_record.get("reason"),
        "contact": contact,
        "signal": signal,
        "seq": latest_record.get("last_seq"),
        "valid_heart_rate": latest_record.get("valid_heart_rate"),
        "valid_spo2": latest_record.get("valid_spo2"),
        "valid_temp": latest_record.get("valid_temp"),
        "status": status,
        "status_text": status,
        "hint_text": (
            "请将手指稳定放到红光上并保持一段时间"
            if status == "采集中"
            else ("请重新调整手指位置" if status == "信号差" else "数据正常")
        ),
    }


build_ws_snapshot = _build_ws_snapshot


def _format_timestamp_ms(timestamp_ms):
    if not timestamp_ms:
        return ""
    from datetime import datetime

    dt = datetime.fromtimestamp(timestamp_ms / 1000)
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def start_iot_mqtt_ingest():
    global _mqtt_client
    with _mqtt_lock:
        if _mqtt_client is not None:
            return

        client = Client(client_id=MQTT_CLIENT_ID)
        client.on_connect = _on_connect
        client.on_message = _on_message
        client.reconnect_delay_set(min_delay=1, max_delay=30)
        client.connect_async(MQTT_HOST, MQTT_PORT, MQTT_KEEPALIVE)
        client.loop_start()
        _mqtt_client = client
        logger.info(
            "MQTT ingest service started: %s:%s topic=%s",
            MQTT_HOST,
            MQTT_PORT,
            MQTT_TOPIC,
        )


def stop_iot_mqtt_ingest():
    global _mqtt_client
    with _mqtt_lock:
        if _mqtt_client is None:
            return

        try:
            _mqtt_client.loop_stop()
            _mqtt_client.disconnect()
        finally:
            _mqtt_client = None
            logger.info("MQTT ingest service stopped")
