import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../api/api_service.dart';
import '../../controller/auth_controller.dart';
import '../../controller/sleep_controller.dart';
import '../../component/bottom_tab_bar.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();
  final SleepController _sleepController = Get.find<SleepController>();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _submitting = false;

  // 睡眠记录
  List<Map<String, dynamic>> sleepRecords = [];
  bool loading = false;

  // 睡眠记录弹窗
  bool _showSleepPopup = false;
  Map<String, dynamic>? _latestSleepRecord;
  late final AnimationController _popupController;
  late final Animation<double> _popupScaleAnimation;
  late final Animation<double> _popupOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // 初始化弹窗动画控制器
    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _popupScaleAnimation = CurvedAnimation(
      parent: _popupController,
      curve: Curves.elasticOut,
    );
    _popupOpacityAnimation = CurvedAnimation(
      parent: _popupController,
      curve: Curves.easeOut,
    );

    fetchSleepRecords();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  Future<void> fetchSleepRecords() async {
    setState(() {
      loading = true;
    });
    final resp = await _apiService.querySleepRecord(
      _authController.userId.value,
      limit: 7,
    );
    if (!mounted) return;
    setState(() {
      loading = false;
      if (resp["code"] == 200) {
        List<Map<String, dynamic>> records =
            List<Map<String, dynamic>>.from(resp["data"] ?? []);
        sleepRecords = records;
      } else {
        Get.snackbar('查询失败', resp["msg"] ?? "未知错误");
      }
    });
  }

  void _startSleep() {
    _sleepController.startSleep();
  }

  Future<void> _endSleep() async {
    final startedAt = _sleepController.getSleepStartAt();
    if (startedAt == null) {
      _sleepController.endSleep();
      return;
    }

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed.inSeconds < 5) {
      final shouldEnd = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: const Color(0xFF2C2344),
          title: const Text(
            '睡眠时间不足',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: Text(
            '睡眠不足5秒，记录不会保存。\n是否仍要结束睡眠？',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child:
                  const Text('继续睡眠', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFE23A),
                foregroundColor: Colors.black,
              ),
              child: const Text('结束并放弃记录'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (!mounted) return;
      if (shouldEnd != true) {
        return;
      }

      _sleepController.endSleep();
      return;
    }

    setState(() {
      _submitting = true;
    });

    final endedAt = DateTime.now();
    final resp = await _apiService.uploadSleepRecord({
      'user_id': _authController.userId.value,
      'sleep_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(startedAt),
      'sleep_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(endedAt),
    });

    if (!mounted) return;

    setState(() {
      _submitting = false;
    });

    if (resp["code"] == 200) {
      Get.snackbar('上传成功', '睡眠记录已上传');
      _sleepController.endSleep();

      // 上传成功后立即查询睡眠记录
      await fetchSleepRecords();

      // 显示睡眠记录弹窗
      if (sleepRecords.isNotEmpty) {
        setState(() {
          _latestSleepRecord = sleepRecords.first;
          _showSleepPopup = true;
        });
        _popupController.forward();

        // 3秒后关闭弹窗并动画归入列表
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          _popupController.reverse();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            setState(() {
              _showSleepPopup = false;
              _latestSleepRecord = null;
            });
          });
        });
      }
    } else {
      Get.snackbar('上传失败', resp["msg"] ?? "未知错误");
    }
  }

  String _formatClock(DateTime? time) {
    if (time == null) return '--';
    return DateFormat('HH:mm').format(time);
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _sleepController.isSleeping.value ? '睡眠中' : '睡眠记录',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_sleepController.isSleeping.value) ...[
              const SizedBox(width: 12),
              Text(
                '开始时间  ${_formatClock(_sleepController.getSleepStartAt())}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSleepFlowCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Obx(() => AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _sleepController.isSleeping.value
                ? _buildSleepingState()
                : _buildStartState(),
          )),
    );
  }

  Widget _buildStartState() {
    return Column(
      key: const ValueKey('sleep-start'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 216,
          height: 216,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.nightlight_round,
            size: 115,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startSleep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFE23A),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '开始睡眠',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepingState() {
    return Column(
      key: const ValueKey('sleeping'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 380, // 给脉冲和轨道动画留出足够的空间
          child: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    final value = _pulseAnimation.value;
                    return Container(
                      width: 306 + (36 * value),
                      height: 306 + (36 * value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6B5BBE).withValues(alpha: 0.18),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    final value = _pulseAnimation.value;
                    return Transform.translate(
                      offset: Offset(0, -14 * value),
                      child: Container(
                        width: 227,
                        height: 227,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade300,
                              Colors.purple.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.nightlight_round,
                          size: 130,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    final value = _pulseAnimation.value;
                    return Container(
                      width: 396,
                      height: 396,
                      alignment: Alignment.center,
                      child: CustomPaint(
                        painter: _SleepingOrbitPainter(progress: value),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '睡眠中，请保持安静',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _endSleep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text(
                    '结束睡眠',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }

  Widget buildSleepRecords() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  const Text('最近睡眠记录',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (sleepRecords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.night_shelter,
                          size: 48, color: Colors.white24),
                      SizedBox(height: 8),
                      Text('暂无睡眠记录', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sleepRecords.length,
                  itemBuilder: (context, index) {
                    return buildSleepRecordItem(sleepRecords[index]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw);
      return DateFormat('MM-dd HH:mm').format(dt);
    } catch (_) {
      try {
        final dt = DateFormat('yyyy-MM-dd HH:mm').parse(raw);
        return DateFormat('MM-dd HH:mm').format(dt);
      } catch (_) {
        return raw;
      }
    }
  }

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd HH:mm').parse(raw);
      } catch (_) {
        return null;
      }
    }
  }

  String _formatCompactDuration(Duration? duration) {
    if (duration == null || duration.inSeconds <= 0) return '--';

    final roundedMinutes = (duration.inSeconds + 30) ~/ 60;
    if (roundedMinutes <= 0) return '--';

    final hours = roundedMinutes ~/ 60;
    final minutes = roundedMinutes % 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h${minutes}min' : '${hours}h';
    }
    return '${minutes}min';
  }

  String _getScoreQuality(int score) {
    if (score >= 85) return '优秀';
    if (score >= 70) return '良好';
    if (score >= 60) return '一般';
    return '较差';
  }

  Widget buildSleepRecordItem(Map<String, dynamic> record) {
    final sleepStartRaw = record['sleep_start']?.toString();
    final sleepEndRaw = record['sleep_end']?.toString();
    final start = _formatDateTime(record['sleep_start']?.toString());
    final score = record['sleep_score'] ?? 0;
    final deepSleep = record['deep_sleep_duration'] ?? 0;
    final avgHeartRate = record['avg_heart_rate'] ?? '--';
    final avgSpo2 = record['avg_spo2'] ?? '--';
    final avgTemp = record['avg_temp'] ?? '--';
    final suggestion = record['suggestion'] ?? '';

    // 根据后端返回的开始/结束时间计算时长
    final startTime = _parseDateTime(sleepStartRaw);
    final endTime = _parseDateTime(sleepEndRaw);
    Duration? duration;
    if (startTime != null && endTime != null) {
      duration = endTime.difference(startTime);
      if (duration.inSeconds < 0) {
        duration = duration + const Duration(days: 1);
      }
    }
    final durationText = _formatCompactDuration(duration);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间和评分
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$start   $durationText',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: score >= 80 ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score分 ${_getScoreQuality(score)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 深睡
          Row(
            children: [
              Icon(Icons.night_shelter, size: 14, color: Colors.blue.shade300),
              const SizedBox(width: 4),
              Text(
                '深睡: $deepSleep分钟',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 生理指标
          Row(
            children: [
              _buildSleepPhysioChip(
                  '心率', '$avgHeartRate', Icons.favorite, Colors.red),
              const SizedBox(width: 8),
              _buildSleepPhysioChip(
                  '血氧', '$avgSpo2%', Icons.bloodtype, Colors.blue),
              const SizedBox(width: 8),
              _buildSleepPhysioChip(
                  '体温', '$avgTemp°C', Icons.thermostat, Colors.orange),
            ],
          ),
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.yellow, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSleepPhysioChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '$label $value',
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepPopup() {
    if (_latestSleepRecord == null) return Container();

    final record = _latestSleepRecord!;
    final score = record['sleep_score'] ?? 0;
    final deepSleep = record['deep_sleep_duration'] ?? 0;
    final avgHeartRate = record['avg_heart_rate'] ?? '--';
    final avgSpo2 = record['avg_spo2'] ?? '--';
    final avgTemp = record['avg_temp'] ?? '--';
    final suggestion = record['suggestion'] ?? '';

    // Calculate sleep stages (mock data for now)
    final totalSleepMinutes = deepSleep + (deepSleep * 2); // Mock: deep + light
    final deepSleepPercent =
        totalSleepMinutes > 0 ? (deepSleep / totalSleepMinutes) * 100 : 0;
    final lightSleepPercent = 100 - deepSleepPercent;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        children: [
          // Background blur
          GestureDetector(
            onTap: () {
              _popupController.reverse();
              Future.delayed(const Duration(milliseconds: 500), () {
                if (!mounted) return;
                setState(() {
                  _showSleepPopup = false;
                  _latestSleepRecord = null;
                });
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Popup content
          Center(
            child: AnimatedBuilder(
              animation: _popupController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _popupScaleAnimation.value,
                  child: Opacity(
                    opacity: _popupOpacityAnimation.value,
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2344),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Score and rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$score 分',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '超过 ${(score * 1.2).toInt()}% 的用户',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              // Star rating
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < (score ~/ 20)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: const Color(0xFFFFE23A),
                                    size: 20,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Sleep quality text
                          Text(
                            '睡眠质量${score >= 80 ? '良好' : score >= 60 ? '一般' : '较差'}。然而，睡眠期间醒了 2 次，略高于正常范围，存在易醒问题。',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Sleep stages
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Left side: stage details
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.purple,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '深睡 ${deepSleep}分钟',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '浅睡 ${(deepSleep * 2)}分钟',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '快速眼动 ${(deepSleep * 0.5).toInt()}分钟',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Right side: circular chart
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: deepSleepPercent.toDouble(),
                                        color: Colors.purple,
                                        radius: 30,
                                        title: '',
                                      ),
                                      PieChartSectionData(
                                        value: lightSleepPercent.toDouble(),
                                        color: Colors.blue,
                                        radius: 30,
                                        title: '',
                                      ),
                                    ],
                                    centerSpaceRadius: 20,
                                    sectionsSpace: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Sleep issues
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '清醒次数 2 次',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '偏高',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '参考值: 0-1次',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '浅睡比例 67%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '偏高',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '参考值: <55%',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Physiological indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSleepPhysioChip('心率', '$avgHeartRate',
                                  Icons.favorite, Colors.red),
                              const SizedBox(width: 8),
                              _buildSleepPhysioChip('血氧', '$avgSpo2%',
                                  Icons.bloodtype, Colors.blue),
                              const SizedBox(width: 8),
                              _buildSleepPhysioChip('体温', '$avgTemp°C',
                                  Icons.thermostat, Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2344),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSleepFlowCard(),
                  buildSleepRecords(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Sleep record popup
            if (_showSleepPopup) _buildSleepPopup(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomTabBar(currentIndex: 2),
    );
  }
}

class _SleepingOrbitPainter extends CustomPainter {
  _SleepingOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.16);

    for (var i = 0; i < 3; i++) {
      final radius = 48 + i * 18 + progress * 6;
      canvas.drawCircle(center, radius, ringPaint);
    }

    final dotPaint = Paint()..color = const Color(0xFFFFE23A);
    for (var i = 0; i < 5; i++) {
      final angle = (progress * 2 * 3.141592653589793) + (i * 1.2);
      final orbit = 70 + i * 5;
      final point = Offset(
        center.dx + orbit * 0.62 * math.cos(angle),
        center.dy + orbit * 0.42 * math.sin(angle),
      );
      canvas.drawCircle(point, 3.2 - (i * 0.2), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SleepingOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
