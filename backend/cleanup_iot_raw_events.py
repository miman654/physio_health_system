"""Remove iot_raw_events rows older than 24 hours.

Run this script directly from the repository root or the backend directory.
It deletes by server_received_at so the retention window follows ingest time.
"""

from __future__ import annotations

import sqlite3
import time
from pathlib import Path

from config.settings import DB_PATH

RETENTION_HOURS = 24


def cleanup_iot_raw_events(retention_hours: int = RETENTION_HOURS) -> int:
    cutoff_ms = int(time.time() * 1000) - retention_hours * 60 * 60 * 1000
    db_path = Path(DB_PATH)

    if not db_path.exists():
        raise FileNotFoundError(f"Database file not found: {db_path}")

    conn = sqlite3.connect(db_path)
    try:
        cursor = conn.cursor()
        cursor.execute("PRAGMA foreign_keys = ON")
        cursor.execute(
            "DELETE FROM iot_raw_events WHERE server_received_at < ?",
            (cutoff_ms,),
        )
        deleted_rows = cursor.rowcount
        conn.commit()
        return deleted_rows
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def main() -> None:
    deleted_rows = cleanup_iot_raw_events()
    print(
        f"Deleted {deleted_rows} rows from iot_raw_events older than {RETENTION_HOURS} hours."
    )


if __name__ == "__main__":
    main()
