import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key}) {
    // 注册AuthController，防止Get.find报错
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
  }

  // 主题色使用8位16进制（前2位是透明度FF=不透明）
  static const primaryColor = Color(0xFFFFB7C5);

  // 获取全局鉴权控制器
  final AuthController authController = Get.find<AuthController>();

  // 登录输入框控制器（初始化空字符串，避免null）
  final TextEditingController usernameCtrl = TextEditingController(text: "");
  final TextEditingController pwdCtrl = TextEditingController(text: "");

  List<String> _passwordRuleIssues(String password) {
    final issues = <String>[];

    if (password.length < 8) {
      issues.add("长度至少 8 位");
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      issues.add("大写字母");
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      issues.add("小写字母");
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      issues.add("数字");
    }
    if (!RegExp(r'[^\w\s]').hasMatch(password)) {
      issues.add("符号");
    }

    return issues;
  }

  String _passwordRuleHint(String password) {
    if (password.isEmpty) {
      return "至少 8 位，且包含大写字母、小写字母、数字和符号";
    }

    final issues = _passwordRuleIssues(password);
    if (issues.isEmpty) {
      return "密码强度符合要求";
    }

    return "缺少：${issues.join('、')}";
  }

  // 显示注册弹窗（优化样式，主题色改为#FFB7C5）
  void _showRegisterDialog() {
    final TextEditingController regNameCtrl = TextEditingController();
    final TextEditingController regPwdCtrl = TextEditingController();
    final TextEditingController ageCtrl = TextEditingController();
    final TextEditingController weightCtrl = TextEditingController();
    final TextEditingController heightCtrl = TextEditingController();
    final RxString selectedGender = "男".obs; // 默认选择男性

    Get.dialog(
      Obx(() {
        final isLoading = authController.isLoading.value;

        return StatefulBuilder(
          builder: (context, setState) {
            final passwordText = regPwdCtrl.text.trim();
            final passwordIssues = _passwordRuleIssues(passwordText);
            final passwordHint = _passwordRuleHint(passwordText);
            final canSubmit = !isLoading &&
                regNameCtrl.text.trim().isNotEmpty &&
                passwordIssues.isEmpty;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(255, 183, 197, 0.1),
                      blurRadius: 15,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 注册标题栏
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: const Text(
                          "用户注册",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: primaryColor,
                          ),
                        ),
                      ),

                      // 用户名
                      TextField(
                        controller: regNameCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: "用户名",
                          hintText: "请输入注册用户名",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.person, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 密码
                      TextField(
                        controller: regPwdCtrl,
                        obscureText: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: "密码",
                          hintText: "请输入注册密码",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.lock, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          passwordHint,
                          style: TextStyle(
                            color: passwordIssues.isEmpty &&
                                    passwordText.isNotEmpty
                                ? const Color(0xff1d9d72)
                                : const Color(0xffd14d72),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 年龄
                      TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "年龄",
                          hintText: "请输入年龄",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon:
                              Icon(Icons.calendar_today, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 体重(kg)
                      TextField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: "体重(kg)",
                          hintText: "请输入体重（如70.5）",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon:
                              Icon(Icons.line_weight, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 身高(cm)
                      TextField(
                        controller: heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: "身高(cm)",
                          hintText: "请输入身高（如175.0）",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.height, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 性别选择
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, color: primaryColor),
                            const SizedBox(width: 10),
                            const Text(
                              "性别",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(width: 20),
                            Obx(
                              () => Row(
                                children: [
                                  Radio<String>(
                                    value: "男",
                                    groupValue: selectedGender.value,
                                    onChanged: (value) {
                                      if (value != null) {
                                        selectedGender.value = value;
                                      }
                                    },
                                    activeColor: primaryColor,
                                  ),
                                  const Text("男",
                                      style: TextStyle(fontSize: 15)),
                                  const SizedBox(width: 20),
                                  Radio<String>(
                                    value: "女",
                                    groupValue: selectedGender.value,
                                    onChanged: (value) {
                                      if (value != null) {
                                        selectedGender.value = value;
                                      }
                                    },
                                    activeColor: primaryColor,
                                  ),
                                  const Text("女",
                                      style: TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 按钮区域
                      Row(
                        children: [
                          // 取消按钮
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: const Color.fromRGBO(
                                          255, 183, 197, 0.5)),
                                ),
                              ),
                              onPressed: () {
                                if (Get.isDialogOpen ?? false) {
                                  Get.back(); // 关闭弹窗
                                }
                              },
                              child: Text(
                                "取消",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 注册按钮
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canSubmit
                                    ? primaryColor
                                    : primaryColor.withOpacity(0.45),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              onPressed: canSubmit
                                  ? () async {
                                      // 构建注册参数
                                      final Map<String, dynamic>
                                          registerParams = {
                                        "username": regNameCtrl.text.trim(),
                                        "password": regPwdCtrl.text.trim(),
                                        "age":
                                            int.tryParse(ageCtrl.text.trim()),
                                        "weight": double.tryParse(
                                            weightCtrl.text.trim()),
                                        "height": double.tryParse(
                                            heightCtrl.text.trim()),
                                        "gender": selectedGender.value,
                                      };

                                      // 移除空值字段
                                      registerParams.removeWhere(
                                          (key, value) => value == null);

                                      // 直接提交，成功后由控制器关闭弹窗
                                      await authController
                                          .register(registerParams);
                                    }
                                  : null,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "注册",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
      barrierDismissible: true, // 允许点击外部关闭弹窗
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 标题区域
            Container(
              margin: const EdgeInsets.only(bottom: 60),
              child: Column(
                children: [
                  const Text(
                    "健康管理系统",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 3,
                    color: const Color.fromRGBO(255, 183, 197, 0.5),
                  ),
                ],
              ),
            ),

            // 用户名输入框
            Container(
              // 修复：InputDecoration不支持boxShadow，移到外层Container
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(255, 183, 197, 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "用户名",
                  hintText: "请输入用户名",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 密码输入框
            Container(
              // 修复：InputDecoration不支持boxShadow，移到外层Container
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(255, 183, 197, 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: pwdCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "密码",
                  hintText: "请输入密码",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.lock, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color.fromRGBO(255, 183, 197, 0.3),
                  ),
                  onPressed: authController.isLoading.value
                      ? null
                      : () => authController.login(
                          usernameCtrl.text.trim(), pwdCtrl.text.trim()),
                  child: authController.isLoading.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "登录",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 注册入口
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "还没有账号？",
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _showRegisterDialog,
                  child: Text(
                    "立即注册",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
