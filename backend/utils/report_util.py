# 报告生成工具
"""报告生成工具：可后续扩展PDF/Excel导出"""
import datetime

# 生成用户健康周报（文本版）
def generate_health_weekly_report(user_id: int, physio_data: list, sleep_data: list, sport_data: list):
    report_time = datetime.datetime.now().strftime("%Y年%m月%d日")
    report = f"""
    # 生理健康周报（{report_time}）
    用户ID：{user_id}

    ## 生理数据概况
    本周采集数据条数：{len(physio_data)}
    平均心率：{sum([d['heart_rate'] for d in physio_data])/len(physio_data) if physio_data else 0:.1f} 次/分钟
    平均血氧：{sum([d['spo2'] for d in physio_data])/len(physio_data) if physio_data else 0:.1f} %
    平均体温：{sum([d['temp'] for d in physio_data])/len(physio_data) if physio_data else 0:.1f} ℃

    ## 睡眠概况
    本周睡眠记录数：{len(sleep_data)}
    平均睡眠评分：{sum([d['sleep_score'] for d in sleep_data])/len(sleep_data) if sleep_data else 0:.1f} 分

    ## 运动概况
    本周运动记录数：{len(sport_data)}
    总消耗卡路里：{sum([d['calorie'] for d in sport_data]) if sport_data else 0:.1f} 大卡

    ## 健康建议
    1. 保持规律作息，每天保证7-8小时睡眠
    2. 每周运动3-5次，每次30分钟以上
    3. 饮食均衡，多摄入蔬菜水果，减少高油高盐食物
    """
    return report.strip()