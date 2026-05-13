// AI page
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/api_service.dart';
import '../../component/bottom_tab_bar.dart';
import '../../controller/auth_controller.dart';
import '../../utils/api_formatter.dart';
import '../../utils/color.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final ApiService _apiService = ApiService();
  final AuthController _authController = Get.find<AuthController>();

  String aiAnalysisResult = '';
  bool loadingAI = false;
  bool loadingUserInfo = false;
  bool loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo().then((_) {
      if (mounted) {
        _fetchAIAnalysis();
      }
    });
  }

  Future<void> _loadUserInfo() async {
    if (!mounted) return;
    setState(() {
      loadingUserInfo = true;
    });

    await _authController.loadUserInfo();

    if (!mounted) return;
    setState(() {
      loadingUserInfo = false;
    });
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    setState(() {
      loggingOut = true;
    });

    await _authController.logout();
  }

  Future<void> _handleDeleteAccount() async {
    if (!mounted) return;
    setState(() {
      loggingOut = true;
    });

    await _authController.deleteAccount();
  }

  Future<void> _fetchAIAnalysis() async {
    if (!mounted) return;
    setState(() {
      loadingAI = true;
    });

    final userId = _authController.userId.value;
    if (userId <= 0) {
      if (!mounted) return;
      setState(() {
        aiAnalysisResult = '请先登录后再查看 AI 健康分析。';
        loadingAI = false;
      });
      return;
    }

    final result = await _apiService.aiPhysioAnalysis(userId);

    if (!mounted) return;
    setState(() {
      loadingAI = false;
      if (result['code'] == 200) {
        aiAnalysisResult = _extractSuggestionsText(result['data']);
      } else {
        aiAnalysisResult = result['msg']?.toString() ?? '获取 AI 分析失败';
      }
    });
  }

  String _extractSuggestionsText(dynamic data) {
    if (data is Map && data['suggestions'] is List) {
      final suggestions = (data['suggestions'] as List)
          .where((item) => item != null)
          .map((item) => item.toString().trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (suggestions.isNotEmpty) {
        return suggestions.join('\n\n');
      }
      return '暂无分析建议';
    }

    return ApiResponseFormatter.formatApiData(data);
  }

  Color _resolveGenderColor() {
    return AppColors.primaryDark;
  }

  Widget _buildInfoItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textTitle,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textBody),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final genderColor = _resolveGenderColor();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchAIAnalysis,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // ========== 头像 + 用户名 + 性别 + 两个按钮 同一行 ==========
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 头像
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/image.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 用户名 + 性别
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _authController.username.value.isEmpty
                              ? '未设置用户名'
                              : _authController.username.value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textTitle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: genderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _authController.userGender.value.isEmpty
                                ? '未知'
                                : _authController.userGender.value,
                            style: TextStyle(
                              color: genderColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 退出登录
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      minimumSize: const Size(60, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: loggingOut ? null : _handleLogout,
                    child: loggingOut
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('退出登录', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),

                  // 注销账号（最右侧）
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textBody,
                      side: const BorderSide(color: AppColors.primaryLight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      minimumSize: const Size(60, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: loggingOut ? null : _handleDeleteAccount,
                    child: loggingOut
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Text('注销账号', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 下面所有代码完全不动
              Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            genderColor.withOpacity(0.05),
                            genderColor.withOpacity(0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: genderColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround, // 水平居中
                        crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中
                        children: [
                          _buildInfoItem(
                            Icons.calendar_today,
                            '',
                            _authController.userAge.value > 0
                                ? '${_authController.userAge.value}岁'
                                : '--',
                            genderColor,
                          ),
                          _buildInfoItem(
                            Icons.line_weight,
                            '',
                            _authController.userWeight.value > 0
                                ? '${_authController.userWeight.value.toStringAsFixed(1)}kg'
                                : '--',
                            genderColor,
                          ),
                          _buildInfoItem(
                            Icons.height,
                            '',
                            _authController.userHeight.value > 0
                                ? '${_authController.userHeight.value.toStringAsFixed(1)}cm'
                                : '--',
                            genderColor,
                          ),
                        ],
                      ),
                    ),
                    if (loadingUserInfo) ...[
                      const SizedBox(height: 12),
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.analytics,
                                color: AppColors.primaryDark,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'AI 健康分析',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textTitle,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '基于您的健康数据',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        loadingAI
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : aiAnalysisResult.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '暂无分析结果，点击下方按钮获取建议',
                                        style: TextStyle(
                                          color: AppColors.textTip,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primaryLight,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      aiAnalysisResult,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textBody,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('重新分析'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: loadingAI ? null : _fetchAIAnalysis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomTabBar(currentIndex: 3),
    );
  }
}
