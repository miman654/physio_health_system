// Sport page

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../component/bottom_tab_bar.dart';
import '../api/api_service.dart';

class SportPage extends StatefulWidget {
  const SportPage({super.key});

  @override
  State<SportPage> createState() => _SportPageState();
}

class _SportPageState extends State<SportPage> {
  final ApiService _apiService = ApiService();

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController heartRateController = TextEditingController();
  final TextEditingController calorieController = TextEditingController();

  String sportType = '跑步';

  bool loading = false;
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    fetchSportRecords();
  }

  Future<void> fetchSportRecords() async {
    setState(() {
      loading = true;
    });
    final resp = await _apiService.querySportRecord(1, limit: 10);
    setState(() {
      loading = false;
      if (resp["code"] == 200) {
        records = List<Map<String, dynamic>>.from(resp["data"]);
      } else {
        records = [];
        Get.snackbar('查询失败', resp["msg"] ?? '未知错误');
      }
    });
  }

  Future<void> uploadSportRecord() async {
    final start = startController.text;
    final end = endController.text;
    final hr = int.tryParse(heartRateController.text);
    final calorie = double.tryParse(calorieController.text);
    if (start.isEmpty || end.isEmpty || hr == null || calorie == null) {
      Get.snackbar('提示', '请填写全部必填项');
      return;
    }

    setState(() {
      loading = true;
    });

    final resp = await _apiService.uploadSportRecord({
      'user_id': 1,
      'sport_type': sportType,
      'sport_start': _formatWithSeconds(start),
      'sport_end': _formatWithSeconds(end),
      'avg_heart_rate': hr,
      'calorie': calorie,
    });

    setState(() {
      loading = false;
    });

    if (resp["code"] == 200) {
      Get.snackbar('上传成功', '运动记录已上传');
      fetchSportRecords();
    } else {
      Get.snackbar('上传失败', resp["msg"] ?? '未知错误');
    }
  }

  String _formatWithSeconds(String value) {
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(value);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (_) {
      return value;
    }
  }

  Future<void> _pickDateTime(
      BuildContext context, TextEditingController controller) async {
    DateTime initial = DateTime.now();
    try {
      initial = DateFormat('yyyy-MM-dd HH:mm').parse(controller.text);
    } catch (_) {
      try {
        initial = DateFormat('yyyy-MM-dd HH:mm:ss').parse(controller.text);
      } catch (_) {}
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;
    if (time == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    controller.text = DateFormat('yyyy-MM-dd HH:mm').format(selected);
  }

  Widget buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.yellow),
            borderRadius: BorderRadius.circular(10),
          ),
          fillColor: Colors.white.withOpacity(0.05),
          filled: true,
        ),
      ),
    );
  }

  Widget buildRecordItem(Map<String, dynamic> record) {
    final start = record['sport_start']?.toString() ?? '';
    final end = record['sport_end']?.toString() ?? '';
    final type = record['sport_type']?.toString() ?? '';
    final hr = record['avg_heart_rate']?.toString() ?? '--';
    final calorie = record['calorie']?.toString() ?? '--';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('类型: $type', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('开始: $start', style: const TextStyle(color: Colors.white)),
          Text('结束: $end', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('心率: $hr', style: const TextStyle(color: Colors.white70)),
          Text('热量: $calorie kcal',
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'images/sport.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.25)),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    '运动记录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.white.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('上传运动记录',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          buildDropdown(),
                          buildDateTimeField(startController, '开始时间'),
                          buildDateTimeField(endController, '结束时间'),
                          buildTextField(heartRateController, '平均心率',
                              inputType: TextInputType.number),
                          buildTextField(calorieController, '消耗卡路里',
                              inputType: TextInputType.number),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: loading ? null : uploadSportRecord,
                              child: loading
                                  ? const CircularProgressIndicator()
                                  : const Text('上传'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  buildRecordsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomTabBar(currentIndex: 1),
    );
  }

  Widget buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<String>(
          value: sportType,
          dropdownColor: Colors.black87,
          isExpanded: true,
          underline: const SizedBox(),
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(value: '跑步', child: Text('跑步')),
            DropdownMenuItem(value: '步行', child: Text('步行')),
            DropdownMenuItem(value: '骑行', child: Text('骑行')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                sportType = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget buildDateTimeField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.yellow),
            borderRadius: BorderRadius.circular(10),
          ),
          fillColor: Colors.white.withOpacity(0.05),
          filled: true,
        ),
        onTap: () => _pickDateTime(context, controller),
      ),
    );
  }

  Widget buildRecordsSection() {
    return Card(
      color: Colors.white.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('运动记录',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (records.isEmpty)
              const Text('暂无记录', style: TextStyle(color: Colors.white70))
            else
              ...records.map((record) => buildRecordItem(record)),
          ],
        ),
      ),
    );
  }
}
