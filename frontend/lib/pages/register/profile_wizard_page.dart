import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/auth_controller.dart';
import '../../utils/color.dart';

class ProfileWizardPage extends StatefulWidget {
  const ProfileWizardPage({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.stepColor,
    required this.nextRoute,
    this.isFinalStep = false,
  });

  final int stepIndex;
  final String title;
  final String unit;
  final int minValue;
  final int maxValue;
  final int initialValue;
  final Color stepColor;
  final String nextRoute;
  final bool isFinalStep;

  @override
  State<ProfileWizardPage> createState() => _ProfileWizardPageState();
}

class _ProfileWizardPageState extends State<ProfileWizardPage> {
  final AuthController authController = Get.find<AuthController>();
  late FixedExtentScrollController _pickerController;
  late int _selectedValue;

  String get _stepKey {
    switch (widget.stepIndex) {
      case 0:
        return 'age';
      case 1:
        return 'height';
      default:
        return 'weight';
    }
  }

  int _initialValueFromDraft() {
    final draft = _draft();
    final value = draft[_stepKey];
    if (value is num) {
      return value.round().clamp(widget.minValue, widget.maxValue);
    }
    return widget.initialValue.clamp(widget.minValue, widget.maxValue);
  }

  Map<String, dynamic> _draft() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      return Map<String, dynamic>.from(args);
    }
    return <String, dynamic>{};
  }

  List<Widget> _buildStepIndicators() {
    return List.generate(3, (index) {
      final active = index == widget.stepIndex;
      return Expanded(
        child: Align(
          alignment: Alignment.center,
          widthFactor: 0.24,
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryDark : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      );
    });
  }

  String get _unitLeftLabel {
    switch (widget.stepIndex) {
      case 1:
        return '英寸';
      case 2:
        return '磅';
      default:
        return '';
    }
  }

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }

    Get.offNamed('/register');
  }

  Future<void> _goNext() async {
    final draft = _draft();
    draft[_stepKey] = _selectedValue;

    if (widget.isFinalStep) {
      await authController.register(draft);
      return;
    }

    Get.toNamed(widget.nextRoute, arguments: draft);
  }

  Widget _buildUnitToggle() {
    if (widget.stepIndex == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _UnitToggleItem(
                label: _unitLeftLabel,
                selected: false,
              ),
            ),
            Expanded(
              child: _UnitToggleItem(
                label: widget.unit,
                selected: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedValue = _initialValueFromDraft();
    _pickerController = FixedExtentScrollController(
      initialItem: _selectedValue - widget.minValue,
    );
  }

  @override
  void dispose() {
    _pickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(42, 30, 42, 8),
              child: Row(children: _buildStepIndicators()),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTitle,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildUnitToggle(),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              padding: const EdgeInsets.fromLTRB(14, 24, 14, 18),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.border.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 70,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$_selectedValue',
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            color: AppColors.textTitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 150,
                    child: CupertinoPicker(
                      scrollController: _pickerController,
                      backgroundColor: Colors.transparent,
                      magnification: 1.08,
                      useMagnifier: true,
                      itemExtent: 34,
                      selectionOverlay: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.textTitle,
                              width: 1.2,
                            ),
                            bottom: BorderSide(color: Colors.transparent),
                          ),
                        ),
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedValue = widget.minValue + index;
                        });
                      },
                      children: List.generate(
                        widget.maxValue - widget.minValue + 1,
                        (index) {
                          final value = widget.minValue + index;
                          final selected = value == _selectedValue;
                          return Center(
                            child: Text(
                              value.toString(),
                              style: TextStyle(
                                fontSize: selected ? 30 : 20,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w400,
                                color: selected
                                    ? AppColors.textTitle
                                    : AppColors.textTip,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Text(
                    widget.unit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  SizedBox(
                    width: 66,
                    height: 66,
                    child: OutlinedButton(
                      onPressed: () => _goBack(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        side: const BorderSide(color: AppColors.border),
                        backgroundColor: AppColors.card,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textTitle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 66,
                      child: ElevatedButton(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.isFinalStep ? '立即开始' : '下一个',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textTitle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              widget.isFinalStep
                                  ? Icons.check
                                  : Icons.double_arrow,
                              color: AppColors.textBody,
                            ),
                          ],
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
    );
  }
}

class _UnitToggleItem extends StatelessWidget {
  const _UnitToggleItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textTip,
        ),
      ),
    );
  }
}
