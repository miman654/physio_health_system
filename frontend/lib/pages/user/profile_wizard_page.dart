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
  FixedExtentScrollController? _decimalPickerController;
  late int _selectedIntegerValue;
  late int _selectedDecimalValue;

  bool get _usesDecimalPicker => widget.stepIndex != 0;

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

  double _initialValueFromDraft() {
    final draft = _draft();
    final value = draft[_stepKey];
    if (value is num) {
      return value
          .toDouble()
          .clamp(widget.minValue.toDouble(), widget.maxValue.toDouble());
    }
    return widget.initialValue
        .toDouble()
        .clamp(widget.minValue.toDouble(), widget.maxValue.toDouble());
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

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }

    Get.offNamed('/register');
  }

  Future<void> _goNext() async {
    final draft = _draft();
    draft[_stepKey] = _usesDecimalPicker
        ? _selectedIntegerValue + (_selectedDecimalValue / 10.0)
        : _selectedIntegerValue;

    if (widget.isFinalStep) {
      await authController.register(draft);
      return;
    }

    Get.toNamed(widget.nextRoute, arguments: draft);
  }

  Widget _buildUnitToggle() {
    return const SizedBox.shrink();
  }

  String _displayValueText() {
    if (!_usesDecimalPicker) {
      return '$_selectedIntegerValue';
    }

    return '$_selectedIntegerValue.${_selectedDecimalValue}';
  }

  Widget _buildDecimalPicker() {
    if (!_usesDecimalPicker) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: SizedBox(
        height: 58,
        child: RotatedBox(
          quarterTurns: 3,
          child: CupertinoPicker(
            scrollController: _decimalPickerController,
            backgroundColor: Colors.transparent,
            magnification: 1.06,
            useMagnifier: true,
            itemExtent: 34,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedDecimalValue = index;
              });
            },
            children: List.generate(10, (index) {
              final selected = index == _selectedDecimalValue;
              return RotatedBox(
                quarterTurns: 1,
                child: Center(
                  child: Text(
                    '0.$index',
                    style: TextStyle(
                      fontSize: selected ? 18 : 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                      color: selected ? AppColors.textTitle : AppColors.textTip,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final initialValue = _initialValueFromDraft();
    _selectedIntegerValue = initialValue.floor();
    _selectedDecimalValue = ((initialValue * 10).round() % 10).clamp(0, 9);
    _pickerController = FixedExtentScrollController(
      initialItem: _selectedIntegerValue - widget.minValue,
    );
    if (_usesDecimalPicker) {
      _decimalPickerController = FixedExtentScrollController(
        initialItem: _selectedDecimalValue,
      );
    }
  }

  @override
  void dispose() {
    _pickerController.dispose();
    _decimalPickerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                                    _displayValueText(),
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
                              height: 132,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: CupertinoPicker(
                                  scrollController: _pickerController,
                                  backgroundColor: Colors.transparent,
                                  magnification: 1.08,
                                  useMagnifier: true,
                                  itemExtent: 64,
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      _selectedIntegerValue =
                                          widget.minValue + index;
                                      if (_usesDecimalPicker &&
                                          _selectedIntegerValue >=
                                              widget.maxValue) {
                                        _selectedDecimalValue = 0;
                                        _decimalPickerController?.jumpToItem(0);
                                      }
                                    });
                                  },
                                  children: List.generate(
                                    widget.maxValue - widget.minValue + 1,
                                    (index) {
                                      final value = widget.minValue + index;
                                      final selected =
                                          value == _selectedIntegerValue;
                                      return RotatedBox(
                                        quarterTurns: 1,
                                        child: Center(
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
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            _buildDecimalPicker(),
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
                                  side:
                                      const BorderSide(color: AppColors.border),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
