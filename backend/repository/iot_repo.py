# 物联网数据落库
import json
import time

from .db import get_db_connection


def _to_int_flag(value):
    if value is None:
        return None
    return 1 if bool(value) else 0


def _extract_record_fields(payload: dict):
    valid = payload.get("valid") or {}
    quality = payload.get("quality") or {}
    return {
        "device_id": payload.get("device_id") or "unknown",
        "seq": payload.get("seq"),
        "ts_device_ms": payload.get("ts") or 0,
        "valid_temp": _to_int_flag(valid.get("temp")),
        "valid_heart_rate": _to_int_flag(valid.get("heart_rate")),
        "valid_spo2": _to_int_flag(valid.get("spo2")),
        "reason": valid.get("reason"),
        "contact": _to_int_flag(quality.get("contact")),
        "signal": quality.get("signal"),
        "temp": payload.get("temp"),
        "heart_rate": payload.get("heart_rate"),
        "spo2": payload.get("spo2"),
    }


def save_iot_event(
    topic: str,
    raw_payload: str,
    payload: dict | None = None,
    parse_ok: bool = True,
    ingest_error: str | None = None,
):
    server_received_at = int(time.time() * 1000)
    parsed_payload = payload or {}
    fields = (
        _extract_record_fields(parsed_payload)
        if parse_ok and isinstance(parsed_payload, dict)
        else {
            "device_id": "unknown",
            "seq": None,
            "ts_device_ms": 0,
            "valid_temp": None,
            "valid_heart_rate": None,
            "valid_spo2": None,
            "reason": None,
            "contact": None,
            "signal": None,
            "temp": None,
            "heart_rate": None,
            "spo2": None,
        }
    )

    # 判断是否为高质量数据
    hr = fields.get("heart_rate")
    spo2 = fields.get("spo2")
    is_high_quality = (
        fields.get("contact") == 1
        and fields.get("signal") is not None
        and fields.get("signal") >= 0.75
        and hr is not None
        and 50 <= hr <= 120
        and spo2 is not None
        and 94.0 <= spo2 <= 100.0
    )

    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        display_time_ms = server_received_at

        raw_event_id = None
        if is_high_quality:
            cursor.execute(
                """
                INSERT INTO iot_raw_events (
                    device_id, topic, seq, ts_device_ms, server_received_at, payload_json,
                    parse_ok, valid_temp, valid_heart_rate, valid_spo2, reason, contact, signal, ingest_error
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    fields["device_id"],
                    topic,
                    fields["seq"],
                    fields["ts_device_ms"],
                    server_received_at,
                    raw_payload,
                    1 if parse_ok else 0,
                    fields["valid_temp"],
                    fields["valid_heart_rate"],
                    fields["valid_spo2"],
                    fields["reason"],
                    fields["contact"],
                    fields["signal"],
                    ingest_error,
                ),
            )
            raw_event_id = cursor.lastrowid

        if parse_ok and fields["device_id"] != "unknown":
            _upsert_latest(
                cursor=cursor,
                device_id=fields["device_id"],
                raw_event_id=raw_event_id,  # 可能为 None
                seq=fields["seq"],
                ts_device_ms=fields["ts_device_ms"],
                server_received_at=server_received_at,
                display_time_ms=display_time_ms,
                payload_json=raw_payload,
                temp=fields["temp"],
                heart_rate=fields["heart_rate"],
                spo2=fields["spo2"],
                valid_temp=fields["valid_temp"],
                valid_heart_rate=fields["valid_heart_rate"],
                valid_spo2=fields["valid_spo2"],
                reason=fields["reason"],
                contact=fields["contact"],
                signal=fields["signal"],
            )

        conn.commit()
        return {
            "status": "success",
            "raw_event_id": raw_event_id,
            "server_received_at": server_received_at,
            "is_high_quality": is_high_quality,
        }
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def _pick_metric(incoming_value, incoming_valid, current_value):
    # incoming_valid == 1 才允许覆盖；否则保留旧值
    if incoming_valid == 1 and incoming_value is not None:
        return incoming_value
    return current_value


def _upsert_latest(
    cursor,
    device_id: str,
    raw_event_id: int,
    seq,
    ts_device_ms,
    server_received_at: int,
    display_time_ms: int,
    payload_json: str,
    temp,
    heart_rate,
    spo2,
    valid_temp,
    valid_heart_rate,
    valid_spo2,
    reason,
    contact,
    signal,
):
    cursor.execute(
        """
        SELECT
            last_raw_event_id, last_seq, last_ts_device_ms, last_server_received_at, payload_json,
            display_time_ms, temp, heart_rate, spo2, valid_temp, valid_heart_rate, valid_spo2,
            reason, contact, signal, updated_at
        FROM iot_device_latest
        WHERE device_id = ?
        """,
        (device_id,),
    )
    row = cursor.fetchone()

    if row is None:
        # 首条直接写入
        cursor.execute(
            """
            INSERT INTO iot_device_latest (
                device_id, last_raw_event_id, last_seq, last_ts_device_ms, last_server_received_at,
                display_time_ms, payload_json, temp, heart_rate, spo2, valid_temp, valid_heart_rate, valid_spo2,
                reason, contact, signal, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                device_id,
                raw_event_id,
                seq,
                ts_device_ms,
                server_received_at,
                display_time_ms,
                payload_json,
                temp,
                heart_rate,
                spo2,
                valid_temp,
                valid_heart_rate,
                valid_spo2,
                reason,
                contact,
                signal,
                server_received_at,
            ),
        )
        return

    current = dict(row)

    current_seq = current.get("last_seq")
    is_out_of_order = current_seq is not None and seq is not None and seq <= current_seq

    # 先做条件覆盖：心率/血氧按 valid 开关决定是否保留旧值
    merged_heart_rate = _pick_metric(
        incoming_value=heart_rate,
        incoming_valid=valid_heart_rate,
        current_value=current.get("heart_rate"),
    )
    merged_spo2 = _pick_metric(
        incoming_value=spo2,
        incoming_valid=valid_spo2,
        current_value=current.get("spo2"),
    )

    if is_out_of_order:
        # 乱序包：不推进主序列，不替换 payload/seq/raw_id；但状态文案 reason 仍更新
        cursor.execute(
            """
            UPDATE iot_device_latest
            SET
                display_time_ms = ?,
                heart_rate = ?,
                spo2 = ?,
                valid_heart_rate = ?,
                valid_spo2 = ?,
                reason = ?,
                contact = ?,
                signal = ?,
                updated_at = ?
            WHERE device_id = ?
            """,
            (
                display_time_ms,
                merged_heart_rate,
                merged_spo2,
                valid_heart_rate,
                valid_spo2,
                reason,
                contact,
                signal,
                server_received_at,
                device_id,
            ),
        )
        return

    # 正常新包：推进 latest 主字段，同时应用条件覆盖规则
    cursor.execute(
        """
        UPDATE iot_device_latest
        SET
            last_raw_event_id = ?,
            last_seq = ?,
            last_ts_device_ms = ?,
            last_server_received_at = ?,
            display_time_ms = ?,
            payload_json = ?,
            temp = ?,
            heart_rate = ?,
            spo2 = ?,
            valid_temp = ?,
            valid_heart_rate = ?,
            valid_spo2 = ?,
            reason = ?,
            contact = ?,
            signal = ?,
            updated_at = ?
        WHERE device_id = ?
        """,
        (
            raw_event_id,
            seq,
            ts_device_ms,
            server_received_at,
            display_time_ms,
            payload_json,
            temp,
            merged_heart_rate,
            merged_spo2,
            valid_temp,
            valid_heart_rate,
            valid_spo2,
            reason,
            contact,
            signal,
            server_received_at,
            device_id,
        ),
    )


def _with_display_time(record: dict):
    return record


def _enrich_raw_record(record: dict):
    payload_json = record.get("payload_json")
    try:
        payload = json.loads(payload_json) if payload_json else {}
    except Exception:
        payload = {}

    record["temp"] = payload.get("temp")
    record["heart_rate"] = payload.get("heart_rate")
    record["spo2"] = payload.get("spo2")
    record["device_time_ms"] = record.get("ts_device_ms")
    return record


def get_latest_device_event(device_id: str | None = None):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        if device_id:
            cursor.execute(
                "SELECT * FROM iot_device_latest WHERE device_id = ?", (device_id,)
            )
            row = cursor.fetchone()
            if not row:
                return None
            return _with_display_time(dict(row))

        cursor.execute("SELECT * FROM iot_device_latest ORDER BY updated_at DESC")
        return [_with_display_time(dict(item)) for item in cursor.fetchall()]
    finally:
        conn.close()


def get_recent_iot_raw_events(device_id: str | None = None, limit: int = 20):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        if device_id:
            cursor.execute(
                "SELECT * FROM iot_raw_events WHERE device_id = ? ORDER BY server_received_at DESC LIMIT ?",
                (device_id, limit),
            )
        else:
            cursor.execute(
                "SELECT * FROM iot_raw_events ORDER BY server_received_at DESC LIMIT ?",
                (limit,),
            )

        rows = [dict(item) for item in cursor.fetchall()]
        for row in rows:
            row["display_time_ms"] = row.get("server_received_at")
            _enrich_raw_record(row)
        return rows
    finally:
        conn.close()


def get_device_history_events(device_id: str, seconds: int = 600):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cutoff_ms = int(time.time() * 1000) - seconds * 1000
        cursor.execute(
            """
            SELECT *
            FROM iot_raw_events
            WHERE device_id = ? AND server_received_at >= ?
            ORDER BY server_received_at ASC, id ASC
            """,
            (device_id, cutoff_ms),
        )
        rows = [dict(item) for item in cursor.fetchall()]
        for row in rows:
            row["display_time_ms"] = row.get("server_received_at")
            _enrich_raw_record(row)
        return rows
    finally:
        conn.close()


def get_averaged_metrics_in_time_range(start_time_ms: int, end_time_ms: int, min_data_points: int = 3):
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT payload_json
            FROM iot_raw_events
            WHERE server_received_at >= ? AND server_received_at <= ?
            ORDER BY server_received_at ASC
            """,
            (start_time_ms, end_time_ms),
        )
        rows = cursor.fetchall()

        heart_rates = []
        spo2_values = []
        temps = []

        for row in rows:
            try:
                payload = json.loads(row[0]) if row[0] else {}
                hr = payload.get("heart_rate")
                spo2 = payload.get("spo2")
                temp = payload.get("temp")

                if hr is not None and isinstance(hr, (int, float)):
                    heart_rates.append(float(hr))
                if spo2 is not None and isinstance(spo2, (int, float)):
                    spo2_values.append(float(spo2))
                if temp is not None and isinstance(temp, (int, float)):
                    temps.append(float(temp))
            except (json.JSONDecodeError, TypeError):
                continue

        result = {
            "heart_rate": None,
            "spo2": None,
            "temp": None,
            "data_points": len(heart_rates),
        }

        if len(heart_rates) >= min_data_points:
            result["heart_rate"] = round(sum(heart_rates) / len(heart_rates))
        if len(spo2_values) >= min_data_points:
            result["spo2"] = round(sum(spo2_values) / len(spo2_values))
        if len(temps) >= min_data_points:
            result["temp"] = round(sum(temps) / len(temps), 1)

        return result
    finally:
        conn.close()
