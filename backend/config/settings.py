from pathlib import Path

# 全局配置
# 项目根目录（避免因工作目录不同导致找不到数据库）
BASE_DIR = Path(__file__).resolve().parent.parent

# JWT密钥（可自定义）
SECRET_KEY = "physio_health_system_2026_key"
# 数据库路径（使用绝对路径避免因工作目录不同导致找不到数据库）
DB_PATH = str(BASE_DIR / "physio_data.db")
# 服务端口
PORT = 8008

DEEPSEEK_API_KEY = "sk-4fe5f96a7f6b4cf6b1206ac56436459d"
DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions"
