# # 删除physio_data表
# import sqlite3
# from pathlib import Path
# from config.settings import DB_PATH


# def drop_sleep_table():
#     """
#     删除physio_data表
#     """
#     # 连接数据库
#     db_path = Path(DB_PATH)
#     if not db_path.exists():
#         print(f"数据库文件不存在: {db_path}")
#         return

#     conn = sqlite3.connect(db_path)
#     cursor = conn.cursor()

#     try:
#         # 检查表是否存在
#         cursor.execute(
#             "SELECT name FROM sqlite_master WHERE type='table' AND name='physio_data'"
#         )
#         table_exists = cursor.fetchone()

#         if table_exists:
#             # 删除表
#             cursor.execute("DROP TABLE physio_data")
#             print("✅ physio_data 表已成功删除")
#         else:
#             print("ℹ️ physio_data 表不存在，无需删除")

#         # 提交更改
#         conn.commit()

#     except Exception as e:
#         print(f"❌ 删除表时出错: {e}")

#     finally:
#         conn.close()


# if __name__ == "__main__":
#     print("开始删除 physio_data 表...")
#     drop_sleep_table()
#     print("操作完成")


# 添加 is_active 字段到 users 表
import sqlite3
from pathlib import Path
from config.settings import DB_PATH


def add_is_active_field():
    db_path = Path(DB_PATH)
    if not db_path.exists():
        print(f"数据库文件不存在: {db_path}")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # 检查字段是否已存在
        cursor.execute("PRAGMA table_info(users)")
        columns = cursor.fetchall()
        column_names = [col[1] for col in columns]

        if "is_active" not in column_names:
            cursor.execute("ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1")
            print("✅ 成功添加 is_active 字段到 users 表")
        else:
            print("ℹ️ is_active 字段已存在")

        conn.commit()
    except Exception as e:
        print(f"❌ 添加字段失败: {e}")
    finally:
        conn.close()


if __name__ == "__main__":
    add_is_active_field()
