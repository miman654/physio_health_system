# AI分析业务
import datetime
from repository.physio_repo import (
    get_physio_data_by_user,
    get_sleep_record_by_user,
    get_sport_record_by_user,
)
from repository.user_repo import get_user_by_id
from utils.ai_util import call_deepseek_api


# AI生理数据分析 - 结合用户身体情况
def ai_physio_analysis_service(user_id: int):
    # ... 前面的代码保持不变 ...
    # 只是把 call_deepseek_api 改为从 utils.ai_tool 导入
    suggestion = call_deepseek_api(prompt)
    # ... 后面的代码保持不变 ...


# AI运动营养建议 - 结合用户身体情况
def ai_sport_nutrition_service(
    user_id: int, sport_type: str, sport_duration: int, sport_time: str
):
    # ... 前面的代码保持不变 ...
    # 只是把 call_deepseek_api 改为从 utils.ai_tool 导入
    suggestion = call_deepseek_api(prompt)
    # ... 后面的代码保持不变 ...
