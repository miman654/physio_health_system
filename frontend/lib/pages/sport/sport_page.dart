import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../api/api_service.dart';
import '../../component/bottom_tab_bar.dart';
import '../../controller/auth_controller.dart';
import '../../controller/data_controller.dart';
import '../../utils/color.dart';

class SportPage extends StatefulWidget {
  const SportPage({super.key});

  @override
  State<SportPage> createState() => _SportPageState();
}

class _SportPageState extends State<SportPage> {
  final AuthController _authController = Get.find<AuthController>();
  final DataController _dataController = Get.find<DataController>();
  final ApiService _apiService = ApiService();

  final List<String> _sportTypes = <String>[
    '步行',
    '快走',
    '跑步',
    '快跑',
    '骑行',
    '游泳',
    '瑜伽',
    '健身',
  ];

  final Map<String, String> _sportAdvice = const {
    '步行': '建议快走20分钟，专注呼吸节奏。',
    '快走': '保持中等配速，组间放松20秒。',
    '跑步': '建议2公里热身，再逐步提速。',
    '快跑': '每组90秒，组间慢走恢复。',
    '骑行': '控制踏频，保持心率稳定。',
    '游泳': '建议分组游进，每组后放松。',
    '瑜伽': '专注核心与拉伸，避免憋气。',
    '健身': '动作标准优先，重量循序渐进。',
  };

  String _sportType = '跑步';
  bool _loading = false;
  bool _isWorkoutRunning = false;
  DateTime? _workoutStart;
  _ChartAxisMode _chartAxisMode = _ChartAxisMode.weekday;
  Map<String, dynamic> _sportSummaryData = {};
  double? _hoverChartDx;

  @override
  void initState() {
    super.initState();
    _fetchSportRecords();
    _fetchChartSummary();
  }

  Future<void> _fetchChartSummary() async {
    final granularity =
        _chartAxisMode == _ChartAxisMode.weekday ? 'week' : 'day';
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await _dataController.querySportSummary(
      granularity: granularity,
      date: today,
    );
    if (!mounted) return;
    if (result != null && result['code'] == 200 && result['data'] is Map) {
      setState(() {
        _sportSummaryData = Map<String, dynamic>.from(result['data'] as Map);
      });
    }
  }

  Future<void> _fetchSportRecords() async {
    setState(() {
      _loading = true;
    });
    await _dataController.querySportRecord(limit: 10);
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    await _fetchChartSummary();
  }

  Future<void> _toggleWorkout() async {
    if (_isWorkoutRunning) {
      await _endWorkout();
    } else {
      _startWorkout();
    }
  }

  void _startWorkout() {
    setState(() {
      _workoutStart = DateTime.now();
      _isWorkoutRunning = true;
    });
    Get.snackbar(
      '运动开始',
      '已开始$_sportType，请完成后点击结束',
      backgroundColor: Colors.green.withValues(alpha: 0.75),
      colorText: Colors.black,
    );
  }

  Future<void> _endWorkout() async {
    final startedAt = _workoutStart;
    if (startedAt == null) {
      setState(() {
        _isWorkoutRunning = false;
      });
      return;
    }

    final endedAt = DateTime.now();
    setState(() {
      _loading = true;
    });

    final result = await _dataController.uploadSportRecord({
      'user_id': _authController.userId.value,
      'sport_type': _sportType,
      'sport_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(startedAt),
      'sport_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(endedAt),
    });

    if (!mounted) return;

    final dynamic calorieRaw = result?['data']?['calorie'];
    final burned = _asDouble(calorieRaw);

    setState(() {
      _loading = false;
      _isWorkoutRunning = false;
      _workoutStart = null;
    });

    if (burned != null) {
      _showCalorieDialog(burned);
      await _fetchSportRecords();
    }
  }

  void _showCalorieDialog(double calories) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          '本次运动完成',
          style: TextStyle(color: AppColors.textTitle),
        ),
        content: Text(
          '本次燃烧 ${calories.toStringAsFixed(1)} 千卡',
          style: const TextStyle(color: AppColors.textBody, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              '知道了',
              style: TextStyle(color: AppColors.primaryDark),
            ),
          )
        ],
      ),
    );
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final formats = <String>['yyyy-MM-dd HH:mm:ss', 'yyyy-MM-dd HH:mm'];
    for (final format in formats) {
      try {
        return DateFormat(format).parse(raw);
      } catch (_) {}
    }
    return null;
  }

  void _toggleChartAxisMode() {
    setState(() {
      _chartAxisMode = _chartAxisMode == _ChartAxisMode.weekday
          ? _ChartAxisMode.time
          : _ChartAxisMode.weekday;
    });
    _fetchChartSummary();
  }

  List<_CaloriePoint> _buildChartPoints() {
    final points = <_CaloriePoint>[];
    final chart = Map<String, dynamic>.from(
      _sportSummaryData['chart'] as Map? ?? const {},
    );
    final rawPoints = List<Map<String, dynamic>>.from(
      chart['points'] ?? const [],
    );

    for (final item in rawPoints) {
      final time = _parseTime(item['time']?.toString()) ?? DateTime.now();
      final calories = _asDouble(item['calorie']) ?? 0;
      points.add(
        _CaloriePoint(
          time: time,
          calories: calories,
          isToday: _isSameDay(time, DateTime.now()),
        ),
      );
    }

    return points;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    if (duration.inSeconds <= 0) return '--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes <= 0) {
      return '${duration.inSeconds}秒';
    }
    if (seconds == 0) {
      return '$minutes分钟';
    }
    return '$minutes分$seconds秒';
  }

  String _formatCompactDuration(Duration? duration) {
    if (duration == null) return '--';
    if (duration.inSeconds <= 0) return '--';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return minutes > 0 ? '${hours}h${minutes}min' : '${hours}h';
    }
    if (minutes > 0) {
      return seconds > 0 ? '${minutes}min${seconds}s' : '${minutes}min';
    }
    return '${seconds}s';
  }

  String _weekdayLabel(DateTime date) {
    const labels = <int, String>{
      DateTime.monday: '星期一',
      DateTime.tuesday: '星期二',
      DateTime.wednesday: '星期三',
      DateTime.thursday: '星期四',
      DateTime.friday: '星期五',
      DateTime.saturday: '星期六',
      DateTime.sunday: '星期日',
    };
    return labels[date.weekday] ?? '星期?';
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  List<_SportDayGroup> _buildSportHistoryGroups() {
    final raw = _dataController.sportDataList.cast<dynamic>().toList();
    final records = raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    records.sort((a, b) {
      final ta = _parseTime(a['sport_start']?.toString()) ?? DateTime(1970);
      final tb = _parseTime(b['sport_start']?.toString()) ?? DateTime(1970);
      return tb.compareTo(ta);
    });

    final limited = records.take(30);
    final grouped = <String, _SportDayGroup>{};

    for (final item in limited) {
      final startTime = _parseTime(item['sport_start']?.toString());
      final endTime = _parseTime(item['sport_end']?.toString());
      final dayKey = startTime == null
          ? '未知日期'
          : DateFormat('yyyy-MM-dd').format(startTime);
      final group = grouped.putIfAbsent(
        dayKey,
        () => _SportDayGroup(
          title: startTime == null
              ? '未知日期'
              : '${DateFormat('yyyy-MM-dd').format(startTime)} ${_weekdayLabel(startTime)}',
        ),
      );

      group.items.add(
        _SportRecordEntry(
          sportType: item['sport_type']?.toString() ?? '--',
          startTime: startTime,
          endTime: endTime,
          avgHeartRate: _asInt(item['avg_heart_rate']),
          avgSpo2: _asInt(item['avg_spo2']),
          avgTemp: _asDouble(item['avg_temp']),
          calorie: _asDouble(item['calorie']),
          suggestion: item['suggestion']?.toString() ?? '',
        ),
      );
    }

    return grouped.values.toList();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '嗨！\n${_authController.username.value.isEmpty ? '优秀福' : _authController.username.value}',
              style: const TextStyle(
                color: AppColors.textTitle,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                height: 2.12,
              ),
            ),
          ),
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 81,
      height: 81,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(40.5),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Image.asset('assets/images/image.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildChartCard(List<_CaloriePoint> points) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _toggleChartAxisMode,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primaryDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                minimumSize: const Size(112, 58),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _chartAxisMode == _ChartAxisMode.weekday ? '星期/天' : '天/星期',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: AppColors.textTitle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: _chartAxisMode == _ChartAxisMode.weekday
                ? _buildWeekBarChart()
                : _buildTimeLineChart(points),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBarChart() {
    final chart = Map<String, dynamic>.from(
      _sportSummaryData['chart'] as Map? ?? const {},
    );
    final days = List<Map<String, dynamic>>.from(chart['days'] ?? const []);

    if (days.isEmpty) {
      return const Center(
        child: Text(
          '暂无周数据',
          style: TextStyle(color: AppColors.textBody),
        ),
      );
    }

    final calories = days.map((day) => _asDouble(day['calorie']) ?? 0).toList();
    final maxCalorie = calories.reduce(math.max);
    final maxY = maxCalorie > 0 ? maxCalorie * 1.2 : 100.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)}千卡',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60, // Increased from 40 to 60 for larger font
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 24, // Doubled from 12 to 24
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final days = List<Map<String, dynamic>>.from(
                  chart['days'] ?? const [],
                );
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                final weekdayLabels = [
                  '周一',
                  '周二',
                  '周三',
                  '周四',
                  '周五',
                  '周六',
                  '周日'
                ];
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    (days[index]['weekday']?.toString().isNotEmpty == true)
                        ? days[index]['weekday'].toString()
                        : weekdayLabels[index],
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: days.asMap().entries.map((entry) {
          final item = entry.value;
          final calorie = _asDouble(item['calorie']) ?? 0;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: calorie,
                color: AppColors.primary,
                width: 24, // Increased from 16 to 24
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8)), // Increased from 4 to 8
                rodStackItems: [
                  BarChartRodStackItem(0, calorie, AppColors.primary),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeLineChart(List<_CaloriePoint> points) {
    final calorieValues = points.map((e) => e.calories).toList();
    final maxValue =
        calorieValues.isEmpty ? 1.0 : calorieValues.reduce(math.max);
    final minValue =
        calorieValues.isEmpty ? 0.0 : calorieValues.reduce(math.min);

    return MouseRegion(
      onHover: (event) {
        setState(() {
          _hoverChartDx = event.localPosition.dx;
        });
      },
      onExit: (_) {
        if (_hoverChartDx != null) {
          setState(() {
            _hoverChartDx = null;
          });
        }
      },
      child: CustomPaint(
        painter: _CalorieCurvePainter(
          points: points,
          axisMode: _chartAxisMode,
          minValue: minValue,
          maxValue: maxValue,
          hoverDx: _hoverChartDx,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildActivitySection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth <= 412;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: isNarrowScreen ? 320 : null,
        child: Container(
          margin: isNarrowScreen
              ? const EdgeInsets.fromLTRB(0, 14, 0, 0)
              : const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '今日活动',
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _sportTypes.length,
                        itemBuilder: (_, index) {
                          final type = _sportTypes[index];
                          final selected = _sportType == type;
                          final advice = _sportAdvice[type] ?? '保持稳定节奏，注意补水。';
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryLight.withValues(
                                      alpha: 0.32,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: selected ? 1.6 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : const [],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  _sportType = type;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: selected ? 16 : 9,
                                            height: selected ? 16 : 9,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: selected
                                                  ? AppColors.primary
                                                  : AppColors.textTip,
                                              boxShadow: selected
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColors.primary
                                                            .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                        blurRadius: 6,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ]
                                                  : const [],
                                            ),
                                          ),
                                          if (index != _sportTypes.length - 1)
                                            SizedBox(
                                              height: 28,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: List.generate(
                                                  6,
                                                  (_) => Container(
                                                    width: 1,
                                                    height: 3,
                                                    color: selected
                                                        ? AppColors.primary
                                                            .withValues(
                                                                alpha: 0.35)
                                                        : AppColors
                                                            .primaryLight,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            type,
                                            style: TextStyle(
                                              color: selected
                                                  ? AppColors.primaryDark
                                                  : AppColors.textTitle,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 30,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            advice,
                                            style: TextStyle(
                                              color: selected
                                                  ? AppColors.primaryDark
                                                      .withValues(alpha: 0.82)
                                                  : AppColors.textBody,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: isNarrowScreen ? 86 : 150,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              width: isNarrowScreen ? 80 : 150,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _toggleWorkout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isWorkoutRunning
                                      ? Colors.red
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 0,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _isWorkoutRunning ? '结束' : '开始',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: TextButton(
                                onPressed: () => Get.toNamed('/sport-calendar'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: AppColors.primaryDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.calendar_month,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isWorkoutRunning && _workoutStart != null) ...[
                const SizedBox(height: 8),
                Text(
                  '已开始: ${DateFormat('HH:mm:ss').format(_workoutStart!)}',
                  style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportHistorySection() {
    final groups = _buildSportHistoryGroups();

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '运动情况',
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (groups.isEmpty)
            Text(
              '暂无运动记录',
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 21,
              ),
            )
          else
            ...groups.expand((group) => [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      group.title,
                      style: const TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ...group.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primaryLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.sportType,
                                      style: const TextStyle(
                                        color: AppColors.textTitle,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        item.calorie == null
                                            ? '--'
                                            : '${item.calorie!.toStringAsFixed(1)}千卡',
                                        style: const TextStyle(
                                          color: AppColors.primaryDark,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.startTime == null
                                        ? '--'
                                        : '${DateFormat('HH:mm').format(item.startTime!)}  ${_formatCompactDuration(item.duration)}',
                                    style: const TextStyle(
                                      color: AppColors.textBody,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _buildMetricChip(
                                    '心率',
                                    item.avgHeartRate == null
                                        ? '--'
                                        : '${item.avgHeartRate} 次/分',
                                  ),
                                  _buildMetricChip(
                                    '血氧',
                                    item.avgSpo2 == null
                                        ? '--'
                                        : '${item.avgSpo2}%',
                                  ),
                                  _buildMetricChip(
                                    '体温',
                                    item.avgTemp == null
                                        ? '--'
                                        : '${item.avgTemp!.toStringAsFixed(1)}℃',
                                  ),
                                ],
                              ),
                              if (item.suggestion.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  item.suggestion,
                                  style: const TextStyle(
                                    color: AppColors.textBody,
                                    fontSize: 21,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )),
                ]),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label：$value',
        style: const TextStyle(
          color: AppColors.textBody,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartPoints = _buildChartPoints();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '燃烧的卡路里',
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildChartCard(chartPoints),
                Expanded(child: _buildActivitySection()),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomTabBar(currentIndex: 1),
    );
  }
}

class _CaloriePoint {
  const _CaloriePoint({
    required this.time,
    required this.calories,
    required this.isToday,
  });

  final DateTime time;
  final double calories;
  final bool isToday;
}

class _SportRecordEntry {
  _SportRecordEntry({
    required this.sportType,
    required this.startTime,
    required this.endTime,
    required this.avgHeartRate,
    required this.avgSpo2,
    required this.avgTemp,
    required this.calorie,
    required this.suggestion,
  });

  final String sportType;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? avgHeartRate;
  final int? avgSpo2;
  final double? avgTemp;
  final double? calorie;
  final String suggestion;

  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!);
  }
}

class _SportDayGroup {
  _SportDayGroup({required this.title});

  final String title;
  final List<_SportRecordEntry> items = <_SportRecordEntry>[];
}

enum _ChartAxisMode { weekday, time }

class _CalorieCurvePainter extends CustomPainter {
  _CalorieCurvePainter({
    required this.points,
    required this.axisMode,
    required this.minValue,
    required this.maxValue,
    required this.hoverDx,
  });

  final List<_CaloriePoint> points;
  final _ChartAxisMode axisMode;
  final double minValue;
  final double maxValue;
  final double? hoverDx;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final plotTop = 10.0;
    final plotBottom = size.height - 24;
    final plotLeft = 28.0;
    final plotWidth = size.width - plotLeft - 6;
    final plotHeight = plotBottom - plotTop;

    final minCalorie = math.min(minValue, maxValue);
    final maxCalorie = math.max(minValue, maxValue);
    final range = (maxCalorie - minCalorie).abs() < 0.001
        ? 1.0
        : (maxCalorie - minCalorie);

    final sorted = [...points]..sort((a, b) => a.time.compareTo(b.time));
    final rawMinTime = sorted.first.time;
    final rawMaxTime = sorted.last.time;
    final minTime = axisMode == _ChartAxisMode.time
        ? rawMinTime.subtract(const Duration(minutes: 30))
        : rawMinTime;
    final maxTime = axisMode == _ChartAxisMode.time
        ? rawMaxTime.add(const Duration(minutes: 30))
        : rawMaxTime;
    final timeSpan = math.max(1, maxTime.difference(minTime).inSeconds);

    final axisPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.8)
      ..strokeWidth = 1;

    final unitPainter = TextPainter(
      text: TextSpan(
        text: '千卡',
        style: TextStyle(
          color: AppColors.textBody,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    unitPainter.paint(canvas, const Offset(0, -24));

    const tickCount = 4;
    final labelStyle = const TextStyle(
      color: AppColors.textBody,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    for (var i = 0; i < tickCount; i++) {
      final ratio = i / (tickCount - 1);
      final y = plotTop + (plotHeight * ratio);
      canvas.drawLine(Offset(plotLeft, y), Offset(size.width, y), axisPaint);

      final value = maxCalorie - (range * ratio);
      final textPainter = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(0), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    final path = Path();
    final pointPositions = <Offset>[];
    for (final point in sorted) {
      final secondsFromStart = point.time.difference(minTime).inSeconds;
      final x = points.length == 1
          ? plotLeft + plotWidth / 2
          : plotLeft + (secondsFromStart / timeSpan) * plotWidth;
      final normalized = (point.calories - minCalorie) / range;
      final stretchedNormalized =
          (0.5 + (normalized - 0.5) * 1.4).clamp(0.0, 1.0).toDouble();
      final y = plotBottom - (normalized * plotHeight);
      final stretchedY = plotBottom - (stretchedNormalized * plotHeight);
      pointPositions.add(Offset(x, stretchedY));
    }

    path.moveTo(pointPositions.first.dx, pointPositions.first.dy);
    for (var i = 1; i < pointPositions.length; i++) {
      final previous = pointPositions[i - 1];
      final current = pointPositions[i];
      final control = Offset((previous.dx + current.dx) / 2, previous.dy);
      path.quadraticBezierTo(control.dx, control.dy, current.dx, current.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.32),
          AppColors.primary.withValues(alpha: 0.06),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = AppColors.primaryDark
      ..isAntiAlias = true;
    canvas.drawPath(path, strokePaint);

    final markerRadius = axisMode == _ChartAxisMode.time ? 3.0 : 4.2;
    for (final marker in pointPositions) {
      canvas.drawLine(
        Offset(marker.dx, plotBottom),
        Offset(marker.dx, marker.dy),
        Paint()
          ..color = AppColors.primaryLight.withValues(alpha: 0.8)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        marker,
        markerRadius,
        Paint()..color = AppColors.primary,
      );
    }

    final todayIndex = points.lastIndexWhere((e) => e.isToday);
    if (todayIndex >= 0) {
      final marker = pointPositions[todayIndex];
      final markerPaint = Paint()..color = AppColors.primaryDark;

      canvas.drawLine(
        Offset(marker.dx, marker.dy),
        Offset(marker.dx, size.height),
        Paint()
          ..color = AppColors.primaryDark.withValues(alpha: 0.6)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(marker, 5.8, markerPaint);
      canvas.drawCircle(
        marker,
        9,
        Paint()..color = AppColors.primaryDark.withValues(alpha: 0.3),
      );
    }

    if (axisMode == _ChartAxisMode.time &&
        hoverDx != null &&
        pointPositions.isNotEmpty) {
      var nearestIndex = 0;
      var minDistance = (pointPositions[0].dx - hoverDx!).abs();
      for (var i = 1; i < pointPositions.length; i++) {
        final distance = (pointPositions[i].dx - hoverDx!).abs();
        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      final marker = pointPositions[nearestIndex];
      final hoverPoint = sorted[nearestIndex];

      final dashPaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 1.2;
      const dashLength = 5.0;
      const dashGap = 4.0;
      var startY = plotTop;
      while (startY < plotBottom) {
        final endY = math.min(startY + dashLength, plotBottom);
        canvas.drawLine(
          Offset(marker.dx, startY),
          Offset(marker.dx, endY),
          dashPaint,
        );
        startY += dashLength + dashGap;
      }

      canvas.drawCircle(
        marker,
        5,
        Paint()..color = AppColors.primary,
      );
      canvas.drawCircle(
        marker,
        9,
        Paint()..color = AppColors.primary.withValues(alpha: 0.25),
      );

      final valueText = '${hoverPoint.calories.toStringAsFixed(1)}千卡';
      final valuePainter = TextPainter(
        text: TextSpan(
          text: valueText,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      const paddingX = 8.0;
      const paddingY = 4.0;
      final bubbleWidth = valuePainter.width + paddingX * 2;
      final bubbleHeight = valuePainter.height + paddingY * 2;
      final bubbleLeft = (marker.dx - bubbleWidth / 2)
          .clamp(plotLeft, size.width - bubbleWidth)
          .toDouble();
      final bubbleTop = math.max(0, plotTop - bubbleHeight - 6).toDouble();
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleWidth, bubbleHeight),
        const Radius.circular(8),
      );

      canvas.drawRRect(
        bubbleRect,
        Paint()..color = AppColors.primaryLight,
      );
      canvas.drawRRect(
        bubbleRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.primary,
      );
      valuePainter.paint(
          canvas, Offset(bubbleLeft + paddingX, bubbleTop + paddingY));
    }

    final labelMap = <int, String>{
      DateTime.monday: '星期一',
      DateTime.tuesday: '星期二',
      DateTime.wednesday: '星期三',
      DateTime.thursday: '星期四',
      DateTime.friday: '星期五',
      DateTime.saturday: '星期六',
      DateTime.sunday: '星期日',
    };

    for (var i = 0; i < sorted.length; i++) {
      final point = sorted[i];
      final x = pointPositions[i].dx;
      final label = axisMode == _ChartAxisMode.weekday
          ? (labelMap[point.time.weekday] ?? '星期?')
          : DateFormat('HH:mm').format(point.time);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AppColors.textBody,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout();

      final labelWidth = textPainter.width;
      final labelHeight = textPainter.height;
      final dx = math.max(
        plotLeft - 4,
        math.min(x - labelWidth / 2, size.width - labelWidth),
      );

      canvas.save();
      canvas.translate(dx + labelWidth / 2, plotBottom + 10);
      canvas.rotate(-0.72);
      textPainter.paint(
        canvas,
        Offset(-labelWidth / 2, -labelHeight / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieCurvePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.axisMode != axisMode ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.hoverDx != hoverDx;
  }
}
