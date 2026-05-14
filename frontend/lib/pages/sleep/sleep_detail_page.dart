import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SleepDetailPage extends StatelessWidget {
  const SleepDetailPage({super.key, required this.record});

  final Map<String, dynamic> record;

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _toText(dynamic value, {String fallback = '--'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
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

  String _formatDateTime(String? raw) {
    final dt = _parseDateTime(raw);
    if (dt == null) return raw ?? '--';
    return DateFormat('MM-dd HH:mm').format(dt);
  }

  String _qualityText(int score) {
    if (score >= 80) return '良好';
    if (score >= 60) return '一般';
    return '较差';
  }

  Widget _buildPhysioChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _toInt(record['sleep_score']);
    final deepSleep = _toInt(record['deep_sleep_duration']);
    final lightSleep = math.max(deepSleep * 2, 0);
    final remSleep = math.max((deepSleep * 0.5).round(), 0);
    final totalSleep = deepSleep + lightSleep + remSleep;

    final deepPercent = totalSleep > 0 ? (deepSleep / totalSleep) * 100 : 0.0;
    final lightPercent = totalSleep > 0 ? (lightSleep / totalSleep) * 100 : 0.0;
    final remPercent = totalSleep > 0 ? (remSleep / totalSleep) * 100 : 0.0;

    final avgHeartRate = _toText(record['avg_heart_rate']);
    final avgSpo2 = _toText(record['avg_spo2']);
    final avgTemp = _toText(record['avg_temp']);
    final suggestion = _toText(record['suggestion'], fallback: '暂无建议');

    return Scaffold(
      backgroundColor: const Color(0xFF2C2344),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '睡眠详情',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2344),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$score 分',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
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
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (score ~/ 20)
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFFFE23A),
                          size: 22,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatDateTime(record['sleep_start']?.toString())} - ${_formatDateTime(record['sleep_end']?.toString())}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '睡眠质量${_qualityText(score)}。然而，睡眠期间醒了 2 次，略高于正常范围，存在易醒问题。',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stageRow('深睡', deepSleep, Colors.purple),
                          const SizedBox(height: 10),
                          _stageRow('浅睡', lightSleep, Colors.blue),
                          const SizedBox(height: 10),
                          _stageRow('快速眼动', remSleep, Colors.green),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: PieChart(
                        PieChartData(
                          sections: totalSleep > 0
                              ? [
                                  PieChartSectionData(
                                    value: deepPercent,
                                    color: Colors.purple,
                                    radius: 35,
                                    title: '',
                                  ),
                                  PieChartSectionData(
                                    value: lightPercent,
                                    color: Colors.blue,
                                    radius: 35,
                                    title: '',
                                  ),
                                  PieChartSectionData(
                                    value: remPercent,
                                    color: Colors.green,
                                    radius: 35,
                                    title: '',
                                  ),
                                ]
                              : [
                                  PieChartSectionData(
                                    value: 100,
                                    color: Colors.white24,
                                    radius: 35,
                                    title: '',
                                  ),
                                ],
                          centerSpaceRadius: 24,
                          sectionsSpace: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _issueRow('清醒次数 2 次', '参考值: 0-1次'),
                const SizedBox(height: 10),
                _issueRow('浅睡比例 67%', '参考值: <55%'),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPhysioChip(
                        '心率', avgHeartRate, Icons.favorite, Colors.red),
                    _buildPhysioChip(
                        '血氧', '$avgSpo2%', Icons.bloodtype, Colors.blue),
                    _buildPhysioChip(
                        '体温', '$avgTemp°C', Icons.thermostat, Colors.orange),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb,
                          color: Color(0xFFFFE23A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stageRow(String label, int minutes, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ${minutes}分钟',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _issueRow(String title, String reference) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Text(
              '偏高',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          reference,
          style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12),
        ),
      ],
    );
  }
}
