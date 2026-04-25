import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../api/api_service.dart';
import '../controller/auth_controller.dart';
import '../component/bottom_tab_bar.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isSleeping = false;
  bool _submitting = false;
  DateTime? _sleepStartAt;

  // 睡眠记录
  List<Map<String, dynamic>> sleepRecords = [];
  bool loading = false;

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
    fetchSleepRecords();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    setState(() {
      _isSleeping = true;
      _sleepStartAt = DateTime.now();
    });
  }

  Future<void> _endSleep() async {
    final startedAt = _sleepStartAt;
    if (startedAt == null) {
      setState(() {
        _isSleeping = false;
      });
      return;
    }

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed.inSeconds < 180) {
      final shouldEnd = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: const Color(0xFF2C2344),
          title: const Text(
            '睡眠时间不足',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: Text(
            '睡眠不足3分钟，记录不会保存。\n是否仍要结束睡眠？',
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

      setState(() {
        _isSleeping = false;
        _sleepStartAt = null;
      });
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
      setState(() {
        _isSleeping = false;
        _sleepStartAt = null;
      });
      fetchSleepRecords();
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
        Text(
          _isSleeping ? '睡眠中' : '睡眠记录',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepFlowCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _isSleeping ? _buildSleepingState() : _buildStartState(),
      ),
    );
  }

  Widget _buildStartState() {
    return Column(
      key: const ValueKey('sleep-start'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
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
            size: 64,
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
        Text(
          '开始时间  ${_formatClock(_sleepStartAt)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  final value = _pulseAnimation.value;
                  return Container(
                    width: 170 + (20 * value),
                    height: 170 + (20 * value),
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
                    offset: Offset(0, -8 * value),
                    child: Container(
                      width: 126,
                      height: 126,
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
                        size: 72,
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
                    width: 220,
                    height: 220,
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
              _buildPhysioChip(
                  '心率', '$avgHeartRate', Icons.favorite, Colors.red),
              const SizedBox(width: 8),
              _buildPhysioChip('血氧', '$avgSpo2%', Icons.bloodtype, Colors.blue),
              const SizedBox(width: 8),
              _buildPhysioChip(
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

  Widget _buildPhysioChip(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2344),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildSleepFlowCard(),
              buildSleepRecords(),
              const SizedBox(height: 24),
            ],
          ),
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
