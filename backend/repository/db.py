# 数据库连接
import sqlite3
from config.settings import DB_PATH

# 获取数据库连接（复用连接，避免重复创建）
def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    # 启用字典游标，查询结果返回字典格式（更易使用）
    conn.row_factory = sqlite3.Row
    return conn