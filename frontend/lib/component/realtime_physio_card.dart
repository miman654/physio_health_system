import 'dart:async';

import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
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
    if (_isOffline || _isInvalid('valid_heart_rate')) return '--';
    final value = widget.latest?['heart_rate'];
    return _formatNumber(value, decimals: 0);
  }

  String get _displaySpo2 {
    if (_isOffline || _isInvalid('valid_spo2')) return '--';
    final value = widget.latest?['spo2'];
    return _formatNumber(value, decimals: 1);
  }

  String get _displayTemp {
    if (_isOffline || _isInvalid('valid_temp')) return '--';
    final value = widget.latest?['temp'];
    return _formatNumber(value, decimals: 1);
  }

  String get _statusText {
    final raw = _rawStatusText;
    if (raw != null && raw.isNotEmpty) {
      return raw;
    }
    if (_isOffline) return '离线';
    if (_collecting) return '采集中';
    if (_isSignalBad) return '信号差';
    return '正常';
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
    final raw = widget.latest?['hint_text']?.toString();
    if (raw != null && raw.isNotEmpty) {
      return raw;
    }
    if (_statusText == '离线') {
      return '请将手指放到 MAX30102 红光上面';
    }
    if (_statusText == '采集中') {
      return '请保持30s手指放在红光上面';
    }
    if (_statusText == '信号差') {
      return '请重新调整手指位置并保持稳定';
    }
    return '数据稳定，可继续观察实时变化';
  }

  String get _timestampText {
    String pad(int value) => value.toString().padLeft(2, '0');
    return "${_now.year}-${pad(_now.month)}-${pad(_now.day)} ${pad(_now.hour)}:${pad(_now.minute)}:${pad(_now.second)}";
  }

  bool get _isOffline =>
      (widget.latest?['contact'] == 0) || widget.latest == null;

  String? get _rawStatusText => widget.latest?['status_text']?.toString();

  bool get _collecting {
    if (_isOffline) return false;
    final raw = _rawStatusText;
    if (raw != null && raw.isNotEmpty) {
      return raw == '采集中';
    }
    return widget.latest?['contact'] == 1 && !_isSignalBad;
  }

  bool get _isSignalBad {
    final signal = widget.latest?['signal'];
    if (signal is num) {
      return signal.toDouble() < 0.2;
    }
    return false;
  }

  bool _isInvalid(String key) {
    final flag = widget.latest?[key];
    return flag == 0 || flag == false;
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
