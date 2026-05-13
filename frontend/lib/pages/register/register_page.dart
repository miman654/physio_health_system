import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const primaryColor = Color(0xFFFFB7C5);
  final ApiService _apiService = ApiService();

  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController pwdCtrl = TextEditingController();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passwordText = pwdCtrl.text.trim();
    final passwordIssues = _passwordRuleIssues(passwordText);
    final passwordHint = _passwordRuleHint(passwordText);
    final canGoNext =
        usernameCtrl.text.trim().isNotEmpty && passwordIssues.isEmpty;

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
                        prefixIcon:
                            const Icon(Icons.person, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        passwordHint,
                        style: TextStyle(
                          color:
                              passwordIssues.isEmpty && passwordText.isNotEmpty
                                  ? const Color(0xff1d9d72)
                                  : const Color(0xffd14d72),
                          fontSize: 12,
                          height: 1.3,
                        ),
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
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canGoNext
                                  ? primaryColor
                                  : primaryColor.withOpacity(0.45),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            onPressed: canGoNext
                                ? () async {
                                    final username = usernameCtrl.text.trim();
                                    final password = pwdCtrl.text.trim();
                                    final result = await _apiService
                                        .checkUsername(username);

                                    if (!mounted) {
                                      return;
                                    }

                                    if (result["code"] == 200) {
                                      final exists =
                                          result["data"]?["exists"] == true;
                                      if (exists) {
                                        Get.snackbar(
                                          '注册失败',
                                          '用户名已存在',
                                          backgroundColor:
                                              Colors.red.withOpacity(0.8),
                                          colorText: Colors.white,
                                        );
                                        return;
                                      }

                                      Get.toNamed(
                                        '/register/age',
                                        arguments: <String, dynamic>{
                                          'username': username,
                                          'password': password,
                                          'gender': selectedGender,
                                        },
                                      );
                                      return;
                                    }

                                    Get.snackbar(
                                      '注册失败',
                                      result["msg"] ?? '用户名校验失败',
                                      backgroundColor:
                                          Colors.red.withOpacity(0.8),
                                      colorText: Colors.white,
                                    );
                                  }
                                : null,
                            child: const Text(
                              '注册',
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
            ],
          ),
        ),
      ),
    );
  }
}
