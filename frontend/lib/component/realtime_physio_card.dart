import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/color.dart';

class RealtimePhysioCard extends StatefulWidget {
  final Map<String, dynamic>? latest;
  final String title;
  final String subtitle;

  const RealtimePhysioCard({
    super.key,
    required this.latest,
    this.title = '当前生理指标总览',
    this.subtitle = '实时来自硬件端的最新有效数据',
  });

  @override
  State<RealtimePhysioCard> createState() => _RealtimePhysioCardState();
}

class _RealtimePhysioCardState extends State<RealtimePhysioCard> {
  late DateTime _now;
  Timer? _timer;
  static final Map<String, DateTime> _contactResumedAtByDevice = {};

  static const Duration _collectingWindow = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _syncContactTiming(null, widget.latest);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void didUpdateWidget(covariant RealtimePhysioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncContactTiming(oldWidget.latest, widget.latest);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusText;
    final statusColor = _statusColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                label: '温度',
                value: _displayTemp,
                unit: '℃',
                color: Colors.orange,
                icon: Icons.thermostat,
              ),
              _buildMetricCard(
                label: '心率',
                value: _displayHeartRate,
                unit: 'bpm',
                color: Colors.red,
                icon: Icons.favorite,
              ),
              _buildMetricCard(
                label: '血氧',
                value: _displaySpo2,
                unit: '%',
                color: Colors.blue,
                icon: Icons.bloodtype,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _timestampText,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _hintText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '$value $unit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String get _displayHeartRate {
    if (_isHardOffline || _collecting || _isNoContact) return '--';
    final value = widget.latest?['heart_rate'];
    return _formatNumber(value, decimals: 0);
  }

  String get _displaySpo2 {
    if (_isHardOffline || _collecting || _isNoContact) return '--';
    final value = widget.latest?['spo2'];
    return _formatNumber(value, decimals: 1);
  }

  String get _displayTemp {
    if (_isHardOffline) return '--';
    final value = widget.latest?['temp'];
    return _formatNumber(value, decimals: 1);
  }

  String get _statusText {
    if (_isHardOffline || _isNoContact) return '离线';
    if (_collecting) return '采集中';
    if (_isSignalGood) return '正常';
    return _hasRealtimeData ? '信号差' : '离线';
  }

  Color get _statusColor {
    switch (_statusText) {
      case '离线':
        return Colors.grey;
      case '采集中':
        return Colors.orange;
      case '信号差':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String get _hintText {
    if (_isHardOffline) {
      return '暂无实时数据，请检查后端或硬件连接';
    }
    if (_isNoContact) {
      return '手指未放到 MAX30102，心率和血氧暂不显示';
    }
    if (_statusText == '采集中') {
      return '请保持手指稳定，等待采集完成';
    }
    if (_statusText == '信号差') {
      return '信号较弱，请重新调整手指位置';
    }
    return '数据稳定，可继续观察实时变化';
  }

  String get _timestampText {
    String pad(int value) => value.toString().padLeft(2, '0');
    return "${_now.year}-${pad(_now.month)}-${pad(_now.day)} ${pad(_now.hour)}:${pad(_now.minute)}:${pad(_now.second)}";
  }

  bool get _hasRealtimeData => widget.latest != null;

  bool get _isHardOffline => widget.latest == null;

  bool get _isNoContact {
    final reason = _reasonText;
    return reason == 'no_contact' || widget.latest?['contact'] == 0;
  }

  bool get _collecting {
    if (_isHardOffline || _isNoContact) return false;
    final startAt = _contactResumedAt;
    if (startAt == null) return false;
    return DateTime.now().difference(startAt) < _collectingWindow;
  }

  bool get _isSignalGood {
    final latest = widget.latest;
    if (latest == null || _isNoContact || _collecting) return false;

    final contact = latest['contact'];
    final signal = _asDouble(latest['signal']);
    final heartRate = _asDouble(latest['heart_rate']);
    final spo2 = _asDouble(latest['spo2']);
    final validHeartRate = latest['valid_heart_rate'];
    final validSpo2 = latest['valid_spo2'];

    return contact == 1 &&
        signal != null &&
        signal >= 0.75 &&
        (validHeartRate == 1 || validHeartRate == true) &&
        (validSpo2 == 1 || validSpo2 == true) &&
        heartRate != null &&
        heartRate >= 50 &&
        heartRate <= 120 &&
        spo2 != null &&
        spo2 >= 80 &&
        spo2 <= 100;
  }

  String get _reasonText {
    final raw = widget.latest?['reason'] ?? widget.latest?['status_text'];
    return raw?.toString() ?? '';
  }

  void _syncContactTiming(
      Map<String, dynamic>? oldLatest, Map<String, dynamic>? latest) {
    final deviceId = _deviceKey(latest ?? oldLatest);
    final newReason = _reasonFromSnapshot(latest);

    if (deviceId.isEmpty) {
      return;
    }

    if (latest == null) {
      return;
    }

    if (newReason == 'no_contact') {
      _contactResumedAtByDevice.remove(deviceId);
      return;
    }

    _contactResumedAtByDevice.putIfAbsent(deviceId, DateTime.now);

    if (_reasonFromSnapshot(oldLatest) == 'no_contact') {
      _contactResumedAtByDevice[deviceId] = DateTime.now();
    }
  }

  DateTime? get _contactResumedAt =>
      _contactResumedAtByDevice[_deviceKey(widget.latest)];

  String _deviceKey(Map<String, dynamic>? snapshot) {
    final deviceId = snapshot?['device_id']?.toString().trim();
    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }
    return '__default_device__';
  }

  String _reasonFromSnapshot(Map<String, dynamic>? snapshot) {
    final raw = snapshot?['reason'] ?? snapshot?['status_text'];
    return raw?.toString() ?? '';
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatNumber(dynamic value, {required int decimals}) {
    if (value == null) return '--';
    if (value is num) {
      final number = value.toDouble();
      return decimals == 0
          ? number.toInt().toString()
          : number.toStringAsFixed(decimals);
    }
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return decimals == 0
        ? parsed.toInt().toString()
        : parsed.toStringAsFixed(decimals);
  }
}
