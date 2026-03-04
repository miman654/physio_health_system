# 全局配置
# JWT密钥（可自定义）
SECRET_KEY = "physio_health_system_2026_key"
# 数据库路径
DB_PATH = "physio_data.db"
# 服务端口
PORT = 8000
# AI营养建议规则（简化版）
NUTRITION_RULES = {
    "sport_long": "运动时长超过1小时，建议补充蛋白质（鸡蛋/鸡胸肉）+维生素C（橙子/猕猴桃）",
    "sleep_bad": "睡眠评分低于60分，建议补充镁元素（坚果/菠菜），避免咖啡因",
    "temp_high": "体温超过37.5℃，建议清淡饮食（粥/蔬菜），多喝水",
    "heart_rate_high": "心率持续偏高，建议减少高盐高脂食物，增加膳食纤维摄入"
}
