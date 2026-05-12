import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const primaryColor = Color(0xFFFFB7C5);

  final AuthController authController = Get.find<AuthController>();
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController pwdCtrl = TextEditingController();
  final TextEditingController ageCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController heightCtrl = TextEditingController();

  String selectedGender = '男';

  List<String> _passwordRuleIssues(String password) {
    final issues = <String>[];

    if (password.length < 8) {
      issues.add('长度至少 8 位');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      issues.add('大写字母');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      issues.add('小写字母');
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      issues.add('数字');
    }
    if (!RegExp(r'[^\w\s]').hasMatch(password)) {
      issues.add('符号');
    }

    return issues;
  }

  String _passwordRuleHint(String password) {
    if (password.isEmpty) {
      return '至少 8 位，且包含大写字母、小写字母、数字和符号';
    }

    final issues = _passwordRuleIssues(password);
    if (issues.isEmpty) {
      return '密码强度符合要求';
    }

    return '缺少：${issues.join('、')}';
  }

  @override
  void dispose() {
    usernameCtrl.dispose();
    pwdCtrl.dispose();
    ageCtrl.dispose();
    weightCtrl.dispose();
    heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passwordText = pwdCtrl.text.trim();
    final passwordIssues = _passwordRuleIssues(passwordText);
    final passwordHint = _passwordRuleHint(passwordText);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('用户注册'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '创建账号',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: '用户名',
                        hintText: '请输入注册用户名',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.person, color: primaryColor),
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
                    TextField(
                      controller: pwdCtrl,
                      obscureText: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: '密码',
                        hintText: '请输入注册密码',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.lock, color: primaryColor),
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
                          color: passwordIssues.isEmpty && passwordText.isNotEmpty
                              ? const Color(0xff1d9d72)
                              : const Color(0xffd14d72),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '年龄',
                        hintText: '请输入年龄',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon:
                            const Icon(Icons.calendar_today, color: primaryColor),
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
                    TextField(
                      controller: weightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '体重(kg)',
                        hintText: '请输入体重（如70.5）',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon:
                            const Icon(Icons.line_weight, color: primaryColor),
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
                    TextField(
                      controller: heightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '身高(cm)',
                        hintText: '请输入身高（如175.0）',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.height, color: primaryColor),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: primaryColor),
                          const SizedBox(width: 10),
                          const Text(
                            '性别',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(width: 20),
                          Row(
                            children: [
                              Radio<String>(
                                value: '男',
                                groupValue: selectedGender,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedGender = value;
                                    });
                                  }
                                },
                                activeColor: primaryColor,
                              ),
                              const Text('男', style: TextStyle(fontSize: 15)),
                              const SizedBox(width: 20),
                              Radio<String>(
                                value: '女',
                                groupValue: selectedGender,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedGender = value;
                                    });
                                  }
                                },
                                activeColor: primaryColor,
                              ),
                              const Text('女', style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: const Color.fromRGBO(
                                    255,
                                    183,
                                    197,
                                    0.5,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () => Get.back(),
                            child: Text(
                              '取消',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Obx(() {
                            final isLoading = authController.isLoading.value;
                            final submitEnabled = !isLoading &&
                                usernameCtrl.text.trim().isNotEmpty &&
                                _passwordRuleIssues(pwdCtrl.text.trim()).isEmpty;

                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: submitEnabled
                                    ? primaryColor
                                    : primaryColor.withOpacity(0.45),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              onPressed: submitEnabled
                                  ? () async {
                                      final registerParams = <String, dynamic>{
                                        'username': usernameCtrl.text.trim(),
                                        'password': pwdCtrl.text.trim(),
                                        'age': int.tryParse(ageCtrl.text.trim()),
                                        'weight': double.tryParse(
                                            weightCtrl.text.trim()),
                                        'height': double.tryParse(
                                            heightCtrl.text.trim()),
                                        'gender': selectedGender,
                                      };

                                      registerParams.removeWhere(
                                        (key, value) => value == null,
                                      );

                                      await authController.register(registerParams);
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
                                      '注册',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
