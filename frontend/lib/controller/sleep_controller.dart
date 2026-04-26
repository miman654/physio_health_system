import 'package:get/get.dart';

class SleepController extends GetxController {
  // 睡眠状态
  final RxBool isSleeping = false.obs;
  final Rx<DateTime?> sleepStartAt = Rx<DateTime?>(null);
  
  // 开始睡眠
  void startSleep() {
    isSleeping.value = true;
    sleepStartAt.value = DateTime.now();
  }
  
  // 结束睡眠
  void endSleep() {
    isSleeping.value = false;
    sleepStartAt.value = null;
  }
  
  // 获取睡眠开始时间
  DateTime? getSleepStartAt() {
    return sleepStartAt.value;
  }
  
  // 检查是否正在睡眠
  bool getIsSleeping() {
    return isSleeping.value;
  }
}