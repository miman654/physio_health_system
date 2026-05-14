import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controller/auth_controller.dart';
import '../../controller/data_controller.dart';

class SportCalendarPage extends StatefulWidget {
  const SportCalendarPage({super.key});

  @override
  State<SportCalendarPage> createState() => _SportCalendarPageState();
}

class _SportCalendarPageState extends State<SportCalendarPage> {
  final AuthController _authController = Get.find<AuthController>();
  final DataController _dataController = Get.find<DataController>();

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> _calendarData = {};
  String? _selectedDateKey;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDateKey = _dateKey(DateTime.now());
    _loadMonth();
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _loadMonth() async {
    setState(() {
      _loading = true;
    });

    final result = await _dataController.querySportSummary(
      granularity: 'month',
      year: _focusedMonth.year,
      month: _focusedMonth.month,
    );
    await _dataController.querySportRecord(limit: 30);

    if (!mounted) return;

    final data = result?['data'];
    setState(() {
      _calendarData = data is Map<String, dynamic>
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      _loading = false;
      _selectedDateKey ??= _firstWorkoutDateKey();
      _selectedDateKey ??=
          _dateKey(DateTime(_focusedMonth.year, _focusedMonth.month, 1));
    });
  }

  String? _firstWorkoutDateKey() {
    final days = List<Map<String, dynamic>>.from(
      (_calendarData['calendar'] as Map?)?['days'] ?? const [],
    );
    for (final day in days) {
      if (day['has_workout'] == true) {
        final date = day['date']?.toString();
        if (date != null && date.isNotEmpty) {
          return date;
        }
      }
    }
    return null;
  }

  Future<void> _changeMonth(int delta) async {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    setState(() {
      _focusedMonth = DateTime(next.year, next.month);
      _selectedDateKey = null;
    });
    await _loadMonth();
  }

  int _daysInMonth() =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

  int _leadingEmptyCells() {
    final weekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    return weekday == DateTime.monday ? 0 : weekday - 1;
  }

  Map<String, Map<String, dynamic>> _dayMap() {
    final days = List<Map<String, dynamic>>.from(
      (_calendarData['calendar'] as Map?)?['days'] ?? const [],
    );
    return {
      for (final day in days)
        day['date']?.toString() ?? '': Map<String, dynamic>.from(day),
    };
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
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

  List<_SportDayGroup> _buildSportHistoryGroups() {
    final raw = _dataController.sportDataList.cast<dynamic>().toList();
    final records = raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    records.sort((a, b) {
      final ta = DateTime.tryParse(a['sport_start']?.toString() ?? '') ??
          DateTime(1970);
      final tb = DateTime.tryParse(b['sport_start']?.toString() ?? '') ??
          DateTime(1970);
      return tb.compareTo(ta);
    });

    final limited = records.take(30);
    final grouped = <String, _SportDayGroup>{};

    for (final item in limited) {
      final startTime =
          DateTime.tryParse(item['sport_start']?.toString() ?? '');
      final endTime = DateTime.tryParse(item['sport_end']?.toString() ?? '');
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

  double _monthMaxCalorie() {
    final value = (_calendarData['summary'] as Map?)?['month_max_calorie'];
    if (value is num) return value.toDouble();
    return 0;
  }

  Color _calorieColor(double calorie, double maxCalorie) {
    if (calorie <= 0) {
      return const Color(0xFF4B3E63).withValues(alpha: 0.28);
    }
    if (maxCalorie <= 0) {
      return const Color(0xFFF6BFD4);
    }
    final ratio = (calorie / maxCalorie).clamp(0.0, 1.0);
    return Color.lerp(
          const Color(0xFFF7C5D8),
          const Color(0xFFE12F86),
          ratio,
        ) ??
        const Color(0xFFF7C5D8);
  }

  Widget _buildHeader() {
    final monthLabel = DateFormat('yyyy年M月').format(_focusedMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              monthLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _changeMonth(-1),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(36, 36),
            ),
            child: const Icon(Icons.chevron_left, size: 28),
          ),
          TextButton(
            onPressed: () => _changeMonth(1),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(36, 36),
            ),
            child: const Icon(Icons.chevron_right, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _calendarData['summary'] as Map? ?? const {};
    final totalCount = (summary['month_total_count'] as num?)?.toInt() ?? 0;
    final totalCalorie =
        (summary['month_total_calorie'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem('本月运动', '$totalCount 次'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryItem(
                '总消耗', '${totalCalorie.toStringAsFixed(1)} 千卡'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7DADF).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        children: labels
            .map(
              (label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = _daysInMonth();
    final leading = _leadingEmptyCells();
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;
    final dayMap = _dayMap();
    final maxCalorie = _monthMaxCalorie();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalCells,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (_, index) {
          if (index < leading || index >= leading + daysInMonth) {
            return const SizedBox.shrink();
          }

          final day = index - leading + 1;
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          final key = _dateKey(date);
          final info = dayMap[key];
          final hasWorkout = info?['has_workout'] == true;
          final calorie = (info?['total_calorie'] as num?)?.toDouble() ?? 0;
          final selected = _selectedDateKey == key;
          final circleColor = _calorieColor(calorie, maxCalorie);

          return GestureDetector(
            onTap: hasWorkout
                ? () => setState(() {
                      _selectedDateKey = key;
                    })
                : () => setState(() {
                      _selectedDateKey = key;
                    }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasWorkout ? circleColor : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.26),
                  width: selected ? 2.2 : 1.2,
                ),
                boxShadow: hasWorkout
                    ? [
                        BoxShadow(
                          color: circleColor.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: hasWorkout ? Colors.black : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasWorkout)
                    Positioned(
                      bottom: 5,
                      child: Text(
                        '${calorie.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSportHistorySection() {
    final groups = _buildSportHistoryGroups();

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '运动情况',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (groups.isEmpty)
            Text(
              '暂无运动记录',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
              ),
            )
          else
            ...groups.expand((group) => [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7DADF).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      group.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ...group.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9FB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.sportType,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
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
                                          color: Colors.green,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.startTime == null
                                        ? '--'
                                        : '${DateFormat('HH:mm').format(item.startTime!)}  ${_formatCompactDuration(item.duration)}',
                                    style: TextStyle(
                                      color:
                                          Colors.black.withValues(alpha: 0.72),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
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
                                const SizedBox(height: 8),
                                Text(
                                  item.suggestion,
                                  style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.82),
                                    fontSize: 13,
                                    height: 1.25,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E2E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label：$value',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF241D3D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2144), Color(0xFF1B152E)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadMonth,
            color: const Color(0xFFE12F86),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildHeader(),
                _buildSummaryCard(),
                _buildWeekHeader(),
                _buildCalendarGrid(),
                _buildSportHistorySection(),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
