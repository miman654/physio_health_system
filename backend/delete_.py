"""Delete the first 5000 rows of the iot_raw_events table in the local SQLite database.
Run this file directly to execute the deletion (the table structure and other table data remain unchanged).
"""

import sqlite3
from pathlib import Path

# 数据库路径（与原代码保持一致，从配置文件导入）
from config.settings import DB_PATH


def delete_top_5000_iot_raw_events() -> None:
    """Delete the first 5000 rows of the iot_raw_events table"""
    # 校验数据库文件是否存在
    db_path = Path(DB_PATH)
    if not db_path.exists():
        raise FileNotFoundError(f"Database file not found: {db_path}")

    # 建立数据库连接并执行删除操作
    conn = None
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # 关闭外键约束（避免删除时受外键关联影响）
        cursor.execute("PRAGMA foreign_keys = OFF")

        # 核心逻辑：删除iot_raw_events表的前5000条数据
        # 利用ROWID筛选前5000行（若表有自定义主键，可替换为主键字段，如id）
        delete_sql = """
            DELETE FROM iot_raw_events
            WHERE ROWID IN (SELECT ROWID FROM iot_raw_events LIMIT 66)
        """
        cursor.execute(delete_sql)

        # 获取实际删除的行数（若表中数据不足5000，会显示实际数量）
        deleted_rows = cursor.rowcount

        # 提交事务
        conn.commit()

        # 打印执行结果
        print(f"Operation completed successfully!")
        print(
            f"Deleted {deleted_rows} rows from the 'iot_raw_events' table (max 5000)."
        )

    except Exception as e:
        # 出错时回滚事务
        if conn:
            conn.rollback()
        print(f"Error occurred during deletion: {str(e)}")
    finally:
        # 确保数据库连接关闭
        if conn:
            conn.close()


if __name__ == "__main__":
    # 执行主函数
    delete_top_5000_iot_raw_events()
