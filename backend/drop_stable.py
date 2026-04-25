"""Clear application data from the local SQLite database.

Run this file directly when you want to wipe table rows but keep the schema.
"""

import sqlite3
from pathlib import Path

from config.settings import DB_PATH


TABLES_TO_CLEAR = (
    "iot_raw_events",
    "iot_device_latest",
    "physio_data",
    "sleep_record",
    "sport_record",
    "users",
)


def clear_database() -> None:
    db_path = Path(DB_PATH)
    if not db_path.exists():
        raise FileNotFoundError(f"Database not found: {db_path}")

    conn = sqlite3.connect(db_path)
    try:
        conn.execute("PRAGMA foreign_keys = OFF")
        cursor = conn.cursor()

        for table_name in TABLES_TO_CLEAR:
            cursor.execute(f"DELETE FROM {table_name}")

        cursor.execute("DELETE FROM sqlite_sequence")
        conn.commit()
        print("Database tables cleared successfully.")
        print("Cleared tables:", ", ".join(TABLES_TO_CLEAR))
    finally:
        conn.close()


if __name__ == "__main__":
    clear_database()
