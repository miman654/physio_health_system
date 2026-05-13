import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../component/bottom_tab_bar.dart';
import '../component/realtime_physio_card.dart';
import '../controller/auth_controller.dart';
import '../controller/data_controller.dart';
import '../utils/color.dart';

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
      body: RefreshIndicator(
        onRefresh: () => dataCtrl.refreshAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                    ? Map<String, dynamic>.from(dataCtrl.realtimePhysioSnapshot)
                    : null;
                return RealtimePhysioCard(
                  latest: latest,
                  title: '当前生理指标总览',
                  subtitle: '实时来自后端的最新有效数据',
                );
              }),
              Obx(() {
                if (dataCtrl.realtimePhysioSnapshot.isEmpty) {
                  return const SizedBox.shrink();
                }
                final latest = dataCtrl.realtimePhysioSnapshot;
                final contact = latest['contact'];
                final signal = latest['signal'];
                final unstable =
                    contact == 0 || (signal is num && signal.toDouble() < 0.2);
                if (!unstable) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primaryDark),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '请将手指稳定放到 MAX30102 红光下面，并保持一段时间，才能测出更稳定的数据。',
                          style:
                              TextStyle(color: AppColors.textBody, height: 1.4),
                        ),
                      ),
                    ],
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomTabBar(currentIndex: 0),
    );
  }
}
