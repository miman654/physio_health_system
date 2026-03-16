import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 底部Tab导航组件（全局复用）
class BottomTabBar extends StatelessWidget {
  // 当前选中的Tab索引（必传参数）
  final int currentIndex;
  const BottomTabBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      // 当前选中项
      currentIndex: currentIndex,
      // 固定Tab数量（超过3个必须加这个，否则布局错乱）
      type: BottomNavigationBarType.fixed,
      // 选中颜色
      selectedItemColor: Colors.blue,
      // 未选中颜色
      unselectedItemColor: Colors.grey,
      // 显示未选中的文字
      showUnselectedLabels: true,
      // Tab选项配置
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "首页",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.run_circle),
          label: "运动",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bed),
          label: "睡眠",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: "我的",
        ),
      ],
      // Tab点击事件（跳转对应页面）
      onTap: (index) {
        switch (index) {
          case 0:
            if (Get.currentRoute != "/home") Get.offAllNamed("/home");
            break;
          case 1:
            if (Get.currentRoute != "/sport") Get.offAllNamed("/sport");
            break;
          case 2:
            if (Get.currentRoute != "/sleep") Get.offAllNamed("/sleep");
            break;
          case 3:
            if (Get.currentRoute != "/ai") Get.offAllNamed("/ai");
            break;
        }
      },
    );
  }
}
