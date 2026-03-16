import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key}) {
    // 注册AuthController，防止Get.find报错
    Get.put(AuthController());
  }

  // 获取全局鉴权控制器
  final AuthController authController = Get.find<AuthController>();
  // 登录输入框控制器
  final TextEditingController usernameCtrl =
      TextEditingController(text: "test");
  final TextEditingController pwdCtrl = TextEditingController(text: "123456");

  // 显示注册弹窗
  void _showRegisterDialog() {
    final TextEditingController regNameCtrl = TextEditingController();
    final TextEditingController regPwdCtrl = TextEditingController();
    final TextEditingController ageCtrl = TextEditingController();
    final TextEditingController weightCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text("用户注册",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 用户名
              TextField(
                controller: regNameCtrl,
                decoration: const InputDecoration(
                  labelText: "用户名",
                  hintText: "请输入注册用户名",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // 密码
              TextField(
                controller: regPwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "密码",
                  hintText: "请输入注册密码",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // 年龄
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "年龄",
                  hintText: "请输入年龄",
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // 体重(kg)
              TextField(
                controller: weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "体重(kg)",
                  hintText: "请输入体重（如70.5）",
                  prefixIcon: Icon(Icons.line_weight),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // 取消按钮
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          // 注册按钮
          Obx(
            () => ElevatedButton(
              onPressed: authController.isLoading.value
                  ? null
                  : () {
                      authController.register({
                        "username": regNameCtrl.text.trim(),
                        "password": regPwdCtrl.text.trim(),
                        "age": int.tryParse(ageCtrl.text.trim()) ?? 20,
                        "weight":
                            double.tryParse(weightCtrl.text.trim()) ?? 60.0,
                      });
                    },
              child: authController.isLoading.value
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text("注册"),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 标题
            const Text(
              "健康管理系统",
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const SizedBox(height: 60),
            // 用户名输入框
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: "用户名",
                hintText: "请输入用户名",
                prefixIcon: Icon(Icons.person, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 密码输入框
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: "密码",
                hintText: "请输入密码",
                prefixIcon: Icon(Icons.lock, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // 登录按钮
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  onPressed: authController.isLoading.value
                      ? null
                      : () =>
                          authController.login(usernameCtrl.text, pwdCtrl.text),
                  child: authController.isLoading.value
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3)
                      : const Text("登录",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 注册入口
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("还没有账号？"),
                TextButton(
                  onPressed: _showRegisterDialog,
                  child:
                      const Text("立即注册", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
