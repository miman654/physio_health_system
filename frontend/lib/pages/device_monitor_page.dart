import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/api_service.dart';
import '../component/realtime_physio_card.dart';
import '../controller/data_controller.dart';
import '../model/device_telemetry.dart';

class DeviceMonitorPage extends StatefulWidget {
  const DeviceMonitorPage({super.key});

  @override
  State<DeviceMonitorPage> createState() => _DeviceMonitorPageState();
}

class _DeviceMonitorPageState extends State<DeviceMonitorPage> {
  final ApiService _apiService = ApiService();
  final DataController dataCtrl = Get.find<DataController>();
  final TextEditingController _deviceIdController =
      TextEditingController(text: 'hi3861-01');

  bool _loading = false;
  String? _errorMessage;
  int _historyWindowSeconds = 600;
  DeviceLatestSnapshot? _latest;
  List<DeviceHistoryPoint> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    dataCtrl.startRealtimePhysioStream(
        deviceId: _deviceIdController.text.trim());
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) {
      setState(() {
        _errorMessage = '请输入设备 ID';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getDeviceLatest(deviceId),
        _apiService.getDeviceHistory(
          deviceId,
          seconds: _historyWindowSeconds,
        ),
      ]);

      final latestResp = results[0];
      final historyResp = results[1];

      if (latestResp['code'] == 200 && latestResp['data'] is Map) {
        _latest = DeviceLatestSnapshot.fromJson(
          Map<String, dynamic>.from(latestResp['data'] as Map),
        );
      } else {
        _latest = null;
      }

      if (historyResp['code'] == 200 && historyResp['data'] is Map) {
        final points = (historyResp['data']['points'] as List? ?? [])
            .whereType<Map>()
            .map((item) =>
                DeviceHistoryPoint.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _history = points;
      } else {
        _history = [];
      }

      if (latestResp['code'] != 200 && historyResp['code'] != 200) {
        _errorMessage = latestResp['msg']?.toString() ?? '获取设备数据失败';
      }

      await dataCtrl.startRealtimePhysioStream(
        deviceId: _deviceIdController.text.trim(),
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0b1220),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff0b1220), Color(0xff13233d)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '设备监控',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _loading ? null : _loadData,
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildInputPanel(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _buildErrorBanner(_errorMessage!),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _loading && _latest == null
                      ? const _LoadingCard()
                      : Column(
                          children: [
                            _buildLatestPanel(),
                            const SizedBox(height: 18),
                            _buildTrendPanel(),
                            const SizedBox(height: 18),
                            _buildHistoryList(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设备与时间窗口',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _deviceIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('设备 ID，例如 hi3861-01'),
                  onSubmitted: (_) => _loadData(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _showHistoryWindowPicker,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _historyWindowLabel,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const Icon(Icons.expand_more, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _loadData,
              icon: const Icon(Icons.play_arrow),
              label: Text(_loading ? '刷新中...' : '刷新数据'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2d7ff9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestPanel() {
    return Obx(() {
      final activeDeviceId = _deviceIdController.text.trim();
      final realtimeLatest = dataCtrl.physioDataList.isNotEmpty
          ? Map<String, dynamic>.from(dataCtrl.physioDataList.first as Map)
          : null;
      final realtimeMatchesDevice =
          realtimeLatest?['device_id']?.toString() == activeDeviceId;
      final fallbackLatest = _latest?.toMap();
      final latest = realtimeMatchesDevice ? realtimeLatest : fallbackLatest;

      return RealtimePhysioCard(
        latest: latest,
        title: '当前态',
        subtitle: '实时来自硬件端的最新有效数据',
      );
    });
  }

  Widget _buildTrendPanel() {
    final hasData = _history.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff111a2e),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Color(0xffa78bfa)),
              SizedBox(width: 8),
              Text(
                '最近趋势',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasData)
            const Text(
              '暂无历史数据',
              style: TextStyle(color: Colors.white70),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 3
                    : constraints.maxWidth >= 700
                        ? 2
                        : 1;
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _SparklineCard(
                        title: '心率',
                        color: Colors.redAccent,
                        values: _history
                            .where((e) =>
                                e.validHeartRate == 1 && e.heartRate != null)
                            .map((e) => e.heartRate!.toDouble())
                            .toList(),
                        suffix: 'bpm',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _SparklineCard(
                        title: '血氧',
                        color: Colors.lightBlueAccent,
                        values: _history
                            .where((e) => e.validSpo2 == 1 && e.spo2 != null)
                            .map((e) => e.spo2!)
                            .toList(),
                        suffix: '%',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _SparklineCard(
                        title: '体温',
                        color: Colors.orangeAccent,
                        values: _history
                            .where((e) => e.validTemp == 1 && e.temp != null)
                            .map((e) => e.temp!)
                            .toList(),
                        suffix: '℃',
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff111a2e),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xff76f2c5)),
              SizedBox(width: 8),
              Text(
                '历史点',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            const Text(
              '暂无历史点',
              style: TextStyle(color: Colors.white70),
            )
          else
            ..._history.reversed.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatTimestamp(point.timestamp),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${point.seq ?? '--'}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          const Spacer(),
                          _statusBadge(point.reason ?? 'ok'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _miniMetric(
                              '心率', point.heartRate?.toString() ?? '--'),
                          _miniMetric(
                              '血氧', point.spo2?.toStringAsFixed(1) ?? '--'),
                          _miniMetric(
                              '体温', point.temp?.toStringAsFixed(1) ?? '--'),
                          _miniMetric(
                              '信号', point.signal?.toStringAsFixed(2) ?? '--'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xff2d7ff9)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _miniMetric(String label, String value) {
    return Text(
      '$label: $value',
      style: const TextStyle(color: Colors.white70),
    );
  }

  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xff2d7ff9).withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.isEmpty ? 'ok' : text,
        style: const TextStyle(color: Color(0xff9fd0ff), fontSize: 12),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _historyWindowChip(int seconds) {
    final label = _windowLabel(seconds);
    final selected = _historyWindowSeconds == seconds;
    return ActionChip(
      label: Text(label),
      backgroundColor:
          selected ? const Color(0xff2d7ff9) : Colors.white.withOpacity(0.06),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white,
      ),
      onPressed: () {
        Get.back();
        setState(() {
          _historyWindowSeconds = seconds;
        });
        _loadData();
      },
    );
  }

  String _windowLabel(int seconds) {
    if (seconds < 60) {
      return '$seconds 秒';
    }
    final minutes = (seconds / 60).round();
    return '$minutes 分钟';
  }

  String get _historyWindowLabel => _windowLabel(_historyWindowSeconds);

  void _showHistoryWindowPicker() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xff111a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择历史窗口',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _historyWindowChip(30),
                _historyWindowChip(60),
                _historyWindowChip(120),
                _historyWindowChip(300),
                _historyWindowChip(600),
                _historyWindowChip(1800),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${pad(date.month)}-${pad(date.day)} ${pad(date.hour)}:${pad(date.minute)}:${pad(date.second)}';
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xff111a2e),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xff2d7ff9)),
      ),
    );
  }
}

class _SparklineCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<double> values;
  final String suffix;

  const _SparklineCard({
    required this.title,
    required this.color,
    required this.values,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final latest = values.isEmpty ? '--' : _formatValue(values.last);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                latest == '--' ? '--' : '$latest $suffix',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: values.length < 2
                ? Center(
                    child: Text(
                      '暂无有效数据',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _SparklinePainter(color: color, values: values),
                    child: Container(),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  final List<double> values;

  _SparklinePainter({required this.color, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.length < 2) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span =
        (maxValue - minValue).abs() < 0.0001 ? 1.0 : maxValue - minValue;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final normalized = (values[i] - minValue) / span;
      final y = size.height - normalized * (size.height - 12) - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    for (int i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final normalized = (values[i] - minValue) / span;
      final y = size.height - normalized * (size.height - 12) - 6;
      canvas.drawCircle(Offset(x, y), 2.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
