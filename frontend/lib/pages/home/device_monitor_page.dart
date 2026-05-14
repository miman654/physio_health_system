import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_service.dart';
import '../../component/realtime_physio_card.dart';
import '../../controller/data_controller.dart';
import '../../model/device_telemetry.dart';

enum _TrendMetric { heartRate, spo2, temp }

enum _DebounceBucket { oneSecond, twoSeconds, fiveSeconds }

class _TrendPoint {
  final int timestampMs;
  final double value;

  const _TrendPoint({required this.timestampMs, required this.value});
}

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
  _TrendMetric _selectedTrendMetric = _TrendMetric.heartRate;
  _DebounceBucket _selectedDebounceBucket = _DebounceBucket.twoSeconds;

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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                      const SizedBox(height: 8),
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
                            const SizedBox(height: 6),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth <= 412;

              if (isCompact) {
                final deviceFieldWidth = _compactDeviceFieldWidth(context);
                final spacing = 12.0;
                final windowWidth =
                    (constraints.maxWidth - deviceFieldWidth - spacing)
                        .clamp(0.0, constraints.maxWidth);

                return Row(
                  children: [
                    SizedBox(
                      width: deviceFieldWidth,
                      child: TextField(
                        controller: _deviceIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('设备 ID，例如 hi3861-01'),
                        onSubmitted: (_) => _loadData(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: windowWidth,
                      child: InkWell(
                        onTap: _showHistoryWindowPicker,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _historyWindowLabel,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const Icon(Icons.expand_more,
                                  color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
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
                          border:
                              Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _historyWindowLabel,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const Icon(Icons.expand_more,
                                color: Colors.white54),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  double _compactDeviceFieldWidth(BuildContext context) {
    final painter = TextPainter(
      text: const TextSpan(
        text: 'hi3861-01',
        style: TextStyle(fontSize: 16),
      ),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    const horizontalPadding = 14.0 * 2;
    const borderWidth = 2.0;
    const caretAndBuffer = 18.0;

    return painter.width + horizontalPadding + borderWidth + caretAndBuffer;
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
    final metric = _selectedTrendMetric;
    final points = _trendPoints(metric);
    final average = _averageValue(points);
    final metricLabel = _trendMetricLabel(metric);
    final metricUnit = _trendMetricUnit(metric);
    final metricColor = _trendMetricColor(metric);
    final valueText =
        average == null ? '--' : _formatTrendValue(average, metric);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xff111a2e),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xffa78bfa)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '平均$metricLabel $valueText $metricUnit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 224, // Reduced by 20% from 280
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: points.isEmpty
                ? Center(
                    child: Text(
                      '暂无历史数据',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  )
                : LineChart(
                    _buildTrendChartData(
                      points,
                      metricColor,
                      metric,
                      _historyWindowSeconds,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          _buildTrendMetricSelector(),
          const SizedBox(height: 10),
          _buildDebounceSelector(),
        ],
      ),
    );
  }

  List<_TrendPoint> _trendPoints(_TrendMetric metric) {
    final sortedHistory = _history.toList()
      ..sort((left, right) {
        final timestampCompare = left.timestamp.compareTo(right.timestamp);
        if (timestampCompare != 0) return timestampCompare;

        final receivedAtCompare =
            (left.serverReceivedAt ?? 0).compareTo(right.serverReceivedAt ?? 0);
        if (receivedAtCompare != 0) return receivedAtCompare;

        return (left.seq ?? 0).compareTo(right.seq ?? 0);
      });

    final rawPoints = sortedHistory
        .map((point) {
          final value = _trendMetricValue(point, metric);
          if (value == null) return null;
          return _TrendPoint(timestampMs: point.timestamp, value: value);
        })
        .whereType<_TrendPoint>()
        .toList();

    return _debouncePointsByBucket(
      rawPoints,
      _debounceBucketSeconds(_selectedDebounceBucket),
    );
  }

  List<_TrendPoint> _debouncePointsByBucket(
    List<_TrendPoint> points,
    int bucketSeconds,
  ) {
    if (points.isEmpty) return points;
    final bucketMs = bucketSeconds * 1000;

    final Map<int, List<_TrendPoint>> grouped = {};
    for (final point in points) {
      final bucketKey = point.timestampMs ~/ bucketMs;
      grouped.putIfAbsent(bucketKey, () => <_TrendPoint>[]).add(point);
    }

    final result = <_TrendPoint>[];
    for (final bucketPoints in grouped.values) {
      result.add(_medianRepresentativePoint(bucketPoints));
    }

    result.sort((left, right) => left.timestampMs.compareTo(right.timestampMs));
    return result;
  }

  _TrendPoint _medianRepresentativePoint(List<_TrendPoint> points) {
    if (points.length == 1) return points.first;

    final values = points.map((point) => point.value).toList()..sort();
    final mid = values.length ~/ 2;
    final medianValue =
        values.length.isOdd ? values[mid] : (values[mid - 1] + values[mid]) / 2;

    _TrendPoint best = points.first;
    double bestDistance = (best.value - medianValue).abs();

    for (final point in points.skip(1)) {
      final distance = (point.value - medianValue).abs();
      if (distance < bestDistance) {
        best = point;
        bestDistance = distance;
      } else if (distance == bestDistance &&
          point.timestampMs > best.timestampMs) {
        best = point;
      }
    }

    return best;
  }

  int _debounceBucketSeconds(_DebounceBucket bucket) {
    switch (bucket) {
      case _DebounceBucket.oneSecond:
        return 1;
      case _DebounceBucket.twoSeconds:
        return 2;
      case _DebounceBucket.fiveSeconds:
        return 5;
    }
  }

  String _debounceBucketLabel(_DebounceBucket bucket) {
    switch (bucket) {
      case _DebounceBucket.oneSecond:
        return '1秒';
      case _DebounceBucket.twoSeconds:
        return '2秒';
      case _DebounceBucket.fiveSeconds:
        return '5秒';
    }
  }

  double? _trendMetricValue(DeviceHistoryPoint point, _TrendMetric metric) {
    switch (metric) {
      case _TrendMetric.heartRate:
        if (point.validHeartRate != 1 || point.heartRate == null) return null;
        return point.heartRate!.toDouble();
      case _TrendMetric.spo2:
        if (point.validSpo2 != 1 || point.spo2 == null) return null;
        return point.spo2;
      case _TrendMetric.temp:
        if (point.validTemp != 1 || point.temp == null) return null;
        return point.temp;
    }
  }

  double? _averageValue(List<_TrendPoint> points) {
    if (points.isEmpty) return null;
    final sum = points.fold<double>(0, (acc, point) => acc + point.value);
    return sum / points.length;
  }

  String _trendMetricLabel(_TrendMetric metric) {
    switch (metric) {
      case _TrendMetric.heartRate:
        return '心率';
      case _TrendMetric.spo2:
        return '血氧';
      case _TrendMetric.temp:
        return '温度';
    }
  }

  String _trendMetricUnit(_TrendMetric metric) {
    switch (metric) {
      case _TrendMetric.heartRate:
        return '次/分钟';
      case _TrendMetric.spo2:
        return '%';
      case _TrendMetric.temp:
        return '℃';
    }
  }

  Color _trendMetricColor(_TrendMetric metric) {
    switch (metric) {
      case _TrendMetric.heartRate:
        return const Color(0xfff65a6b);
      case _TrendMetric.spo2:
        return const Color(0xff4ea1ff);
      case _TrendMetric.temp:
        return const Color(0xffff9f43);
    }
  }

  String _formatTrendValue(double value, _TrendMetric metric) {
    switch (metric) {
      case _TrendMetric.heartRate:
        return value.toStringAsFixed(0);
      case _TrendMetric.spo2:
      case _TrendMetric.temp:
        return value.toStringAsFixed(1);
    }
  }

  LineChartData _buildTrendChartData(
    List<_TrendPoint> points,
    Color color,
    _TrendMetric metric,
    int selectedWindowSeconds,
  ) {
    final currentTimestampMs = DateTime.now().millisecondsSinceEpoch;

    final rightTimestamp = currentTimestampMs;

    final leftTimestamp = rightTimestamp - selectedWindowSeconds * 1000;

    final filteredPoints = points
        .where((point) =>
            point.timestampMs >= leftTimestamp &&
            point.timestampMs <= rightTimestamp)
        .toList();

    filteredPoints
        .sort((left, right) => left.timestampMs.compareTo(right.timestampMs));

    if (filteredPoints.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
      );
    }

    final values = filteredPoints.map((point) => point.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = (maxValue - minValue).abs();
    final pad = span < 1 ? 1.0 : span * 0.25;
    final minY = minValue - pad;
    final maxY = maxValue + pad;
    final xStep = _trendXAxisIntervalSeconds(selectedWindowSeconds).toDouble();
    final yStep = _axisStep(minY, maxY, metric);

    return LineChartData(
      minX: 0,
      maxX: selectedWindowSeconds.toDouble(),
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yStep,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Colors.white.withOpacity(0.08),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots
              .map(
                (spot) => LineTooltipItem(
                  '${_formatTrendValue(spot.y, metric)} ${_trendMetricUnit(metric)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              .toList(),
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 46,
            interval: yStep,
            getTitlesWidget: (value, meta) {
              if (value < minY || value > maxY) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  _formatTrendAxisValue(value, metric),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: xStep,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value > selectedWindowSeconds) {
                return const SizedBox.shrink();
              }
              final displayTimestampMs = leftTimestamp + (value * 1000).round();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTrendTime(displayTimestampMs),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: _buildTrendLineBars(filteredPoints, leftTimestamp, color),
    );
  }

  List<LineChartBarData> _buildTrendLineBars(
    List<_TrendPoint> points,
    int leftTimestampMs,
    Color color,
  ) {
    if (points.length < 2) {
      return [
        LineChartBarData(
          spots: [
            for (final point in points)
              FlSpot(
                  (point.timestampMs - leftTimestampMs) / 1000.0, point.value),
          ],
          isCurved: false,
          barWidth: 1.5,
          color: color,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ];
    }

    final bars = <LineChartBarData>[];
    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      bars.add(
        LineChartBarData(
          spots: [
            FlSpot((current.timestampMs - leftTimestampMs) / 1000.0,
                current.value),
            FlSpot((next.timestampMs - leftTimestampMs) / 1000.0, next.value),
          ],
          isCurved: false,
          barWidth: 1.5,
          color: color,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return bars;
  }

  double _axisStep(double minY, double maxY, _TrendMetric metric) {
    final span = (maxY - minY).abs();
    if (span <= 0) return 1;

    switch (metric) {
      case _TrendMetric.heartRate:
        // Heart rate: use larger steps for better readability
        if (span >= 40) return 10;
        if (span >= 20) return 5;
        return 5;
      case _TrendMetric.spo2:
        // SpO2: typically small range, use 1 unit steps
        return 1;
      case _TrendMetric.temp:
        // Temperature: use 0.5 or 1 unit steps
        if (span >= 2) return 1;
        return 0.5;
    }
  }

  int _trendXAxisIntervalSeconds(int selectedWindowSeconds) {
    if (selectedWindowSeconds <= 5 * 60) return 60;
    if (selectedWindowSeconds <= 30 * 60) return 5 * 60;
    if (selectedWindowSeconds <= 2 * 3600) return 15 * 60;
    if (selectedWindowSeconds <= 6 * 3600) return 30 * 60;
    if (selectedWindowSeconds <= 12 * 3600) return 60 * 60;
    return 2 * 3600;
  }

  String _formatTrendAxisValue(double value, _TrendMetric metric) {
    switch (metric) {
      case _TrendMetric.heartRate:
        return value.toStringAsFixed(0);
      case _TrendMetric.spo2:
      case _TrendMetric.temp:
        return value.toStringAsFixed(1);
    }
  }

  String _formatTrendTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${pad(date.hour)}:${pad(date.minute)}';
  }

  Widget _buildTrendMetricSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: _TrendMetric.values.map((metric) {
          final selected = metric == _selectedTrendMetric;
          final color = _trendMetricColor(metric);
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTrendMetric = metric;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _trendMetricLabel(metric),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDebounceSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: _DebounceBucket.values.map((bucket) {
          final selected = bucket == _selectedDebounceBucket;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDebounceBucket = bucket;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      selected ? const Color(0xff2d7ff9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _debounceBucketLabel(bucket),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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

  String _windowLabel(int seconds) {
    if (seconds < 3600) {
      final minutes = (seconds / 60).round();
      return '$minutes 分钟';
    }
    final hours = (seconds / 3600).round();
    return '$hours 小时';
  }

  String get _historyWindowLabel => _windowLabel(_historyWindowSeconds);

  void _showHistoryWindowPicker() {
    Get.dialog(
      Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Dialog(
            backgroundColor: const Color(0xff1e2a47),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        60,
                        120,
                        300,
                        600,
                        900,
                        1800,
                        3600,
                        7200,
                        14400,
                        21600,
                        43200,
                        86400,
                      ].map((seconds) => _historyWindowTile(seconds)).toList(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        '取消',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _historyWindowTile(int seconds) {
    final label = _windowLabel(seconds);
    final selected = _historyWindowSeconds == seconds;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xff2d7ff9) : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xff2d7ff9))
          : null,
      onTap: () {
        Get.back();
        setState(() {
          _historyWindowSeconds = seconds;
        });
        _loadData();
      },
    );
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${pad(date.hour)}:${pad(date.minute)}:${pad(date.second)}';
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
