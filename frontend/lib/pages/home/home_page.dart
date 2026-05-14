import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../component/bottom_tab_bar.dart';
import '../../component/realtime_physio_card.dart';
import '../../controller/auth_controller.dart';
import '../../controller/data_controller.dart';
import '../../utils/color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController authCtrl = Get.find<AuthController>();
  final DataController dataCtrl = Get.find<DataController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await dataCtrl.refreshAllData();
        await dataCtrl.syncRealtimePhysioSnapshot();
      } catch (e) {
        debugPrint('首页刷新失败: $e');
      }
    });
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    if (timestamp.length >= 16) {
      return timestamp.substring(0, 16);
    }
    return timestamp;
  }

  String _getSceneName(int scene) {
    switch (scene) {
      case 0:
        return '静息';
      case 1:
        return '运动';
      case 2:
        return '睡眠';
      default:
        return '未知';
    }
  }

  Widget _buildEmptyTip(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.inbox, size: 48, color: AppColors.textTip),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(color: AppColors.textBody, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => dataCtrl.refreshAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '你好，${authCtrl.username.value}！',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textTitle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => Get.toNamed('/device-monitor'),
                          icon: const Icon(Icons.monitor_heart, size: 18),
                          label: const Text('设备监控'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            side: const BorderSide(
                                color: AppColors.primaryDark, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final latest = dataCtrl.realtimePhysioSnapshot.isNotEmpty
                        ? Map<String, dynamic>.from(
                            dataCtrl.realtimePhysioSnapshot)
                        : null;
                    return RealtimePhysioCard(
                      latest: latest,
                      title: '当前生理指标总览',
                      subtitle: '实时来自后端的最新有效数据',
                    );
                  }),
                  // 离线时在首页实时卡片下面、AI建议上面显示提示卡片
                  Obx(() {
                    final latest = dataCtrl.realtimePhysioSnapshot.isNotEmpty
                        ? Map<String, dynamic>.from(
                            dataCtrl.realtimePhysioSnapshot)
                        : null;
                    final isOffline = latest == null || latest['contact'] == 0;
                    if (!isOffline) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.fingerprint,
                                color: AppColors.primaryDark, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    '指尖放置小贴士',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '• 指尖盖住LED红光与接收区，别漏光。\n• 轻贴皮肤，别太紧。手指保持静止。',
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Obx(() {
                    if (dataCtrl.aiPhysioSuggestions.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: AppColors.primaryDark),
                              SizedBox(width: 8),
                              Text(
                                'AI健康建议',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textTitle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...dataCtrl.aiPhysioSuggestions
                              .map((suggestion) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ',
                                            style: TextStyle(
                                                color: AppColors.primaryDark,
                                                fontSize: 14)),
                                        Expanded(
                                          child: Text(
                                            suggestion,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: AppColors.textBody,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          const SizedBox(height: 8),
                          Text(
                            '分析时间: ${_formatTimestamp(dataCtrl.aiPhysioAnalysis["analysis_time"])}',
                            style: const TextStyle(
                                color: AppColors.textTip, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Obx(() {
            if (!dataCtrl.isLoading.value) {
              return const SizedBox.shrink();
            }

            return Positioned(
              top: 12,
              right: 12,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.28,
                  child: Container(
                    width: 22,
                    height: 22,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: const BottomTabBar(currentIndex: 0),
    );
  }
}
