import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../models/calculation_history.dart';
import '../models/calculation_result.dart';
import '../services/history_storage.dart';
import 'results_screen.dart';

class RoofingCalculatorScreen extends StatefulWidget {
  final String roofTypeName;
  final String imagePath;

  const RoofingCalculatorScreen({
    super.key,
    required this.roofTypeName,
    required this.imagePath,
  });

  @override
  State<RoofingCalculatorScreen> createState() =>
      _RoofingCalculatorScreenState();
}

class _RoofingCalculatorScreenState extends State<RoofingCalculatorScreen> {
  final _widthController = TextEditingController(text: '3');
  final _lengthController = TextEditingController(text: '6');
  final _heightController = TextEditingController(text: '1');
  final _k1Controller = TextEditingController(text: '0.3');
  final _k2Controller = TextEditingController(text: '0.3');
  final _t1Controller = TextEditingController(text: '0.3');
  final _t2Controller = TextEditingController(text: '0.3');

  String _roofingMaterial = 'profnastil';
  double _reserve = 5;
  bool _parametersExpanded = true;

  final Map<String, String> _materials = {
    'profnastil': 'Профнастил',
    'metallocherepitsa': 'Металлочерепица',
    'ondulin': 'Ондулин',
    'shifer': 'Шифер',
    'myagkaya': 'Мягкая кровля',
  };

  // Sheet dimensions in meters per material type
  Map<String, _SheetSize> get _sheetSizes => {
    'profnastil': const _SheetSize(width: 1.05, height: 2.0, name: 'лист 1.05×2.0 м'),
    'metallocherepitsa': const _SheetSize(width: 1.10, height: 2.20, name: 'лист 1.10×2.20 м'),
    'ondulin': const _SheetSize(width: 0.95, height: 2.0, name: 'лист 0.95×2.0 м'),
    'shifer': const _SheetSize(width: 0.98, height: 1.75, name: 'лист 0.98×1.75 м'),
    'myagkaya': const _SheetSize(width: 1.0, height: 0.33, name: 'гонт 1.0×0.33 м'),
  };

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    _k1Controller.dispose();
    _k2Controller.dispose();
    _t1Controller.dispose();
    _t2Controller.dispose();
    super.dispose();
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _calculate() async {
    final a = _parseNumber(_widthController.text);
    final d = _parseNumber(_lengthController.text);
    final b = _parseNumber(_heightController.text);
    final k1 = _parseNumber(_k1Controller.text);
    final k2 = _parseNumber(_k2Controller.text);
    final t1 = _parseNumber(_t1Controller.text);
    final t2 = _parseNumber(_t2Controller.text);

    if (a == null || d == null || b == null ||
        k1 == null || k2 == null || t1 == null || t2 == null) {
      _showValidationError('Введите корректные числовые значения');
      return;
    }

    if (a <= 0 || d <= 0 || b <= 0) {
      _showValidationError('Основные размеры должны быть больше нуля');
      return;
    }

    // Calculate rafter length (hypotenuse of right triangle: width + overhangs, height)
    final totalWidth = a + k1 + k2;
    final rafterLength = math.sqrt(totalWidth * totalWidth + b * b);

    // Total length with eave overhang
    final totalLength = d + t1 + t2;

    // Roof area
    final roofArea = rafterLength * totalLength;

    // Slope angle
    final slopeAngleDeg = math.atan(b / (a + k1 + k2)) * 180 / math.pi;

    // Reserve
    final reserveMultiplier = 1 + _reserve / 100;
    final totalArea = roofArea * reserveMultiplier;

    // Material calculation
    final sheet = _sheetSizes[_roofingMaterial]!;
    final materialName = _materials[_roofingMaterial]!;

    // Sheets needed (with 10% overlap)
    final usableWidth = sheet.width * 0.9;
    final usableHeight = sheet.height * 0.85;
    final sheetsAcross = (totalLength / usableWidth).ceil();
    final sheetsDown = (rafterLength / usableHeight).ceil();
    final totalSheets = sheetsAcross * sheetsDown;

    // Ridge length
    final ridgeLength = totalLength;

    // Waterproofing membrane (rolls 1.5m × 50m)
    final membraneRolls = (totalArea / (1.5 * 50 * 0.85)).ceil();

    // Rafters calculation: every 0.6m
    final rafterCount = (totalLength / 0.6).ceil() + 1;

    // Fasteners: ~8 per m²
    final fastenerCount = (totalArea * 8).ceil();

    final result = CalculationResult(
      title: 'Результаты: ${widget.roofTypeName}',
      mainValue: totalArea.toStringAsFixed(2),
      mainUnit: 'м²',
      subtitle:
          'Вкл. запас ${_reserve.round()}% '
          '(${(roofArea * _reserve / 100).toStringAsFixed(2)} м²)',
      area: '${roofArea.toStringAsFixed(2)} м²',
      price: '~${(totalArea * 450).round()} ₽',
      materials: [
        MaterialItem(
          name: materialName,
          quantity: '$totalSheets листов',
          details: sheet.name,
          isChecked: true,
        ),
        MaterialItem(
          name: 'Гидроизоляция',
          quantity: '$membraneRolls рулонов',
          details: 'Мембрана 1.5×50 м',
        ),
        MaterialItem(
          name: 'Стропила',
          quantity: '$rafterCount шт',
          details: '${rafterLength.toStringAsFixed(2)} м, сечение 50×150 мм',
        ),
        MaterialItem(
          name: 'Конёк',
          quantity: '${ridgeLength.toStringAsFixed(2)} м.п.',
          details: 'Планка конька',
        ),
        MaterialItem(
          name: 'Саморезы',
          quantity: '$fastenerCount шт',
          details: 'Кровельные 4.8×35 мм',
        ),
      ],
      steps: [
        CalculationStep(
          title: '1. Длина стропила',
          formula:
              'L = √((A+K1+K2)² + B²) = √((${a.toStringAsFixed(2)}+${k1.toStringAsFixed(2)}+${k2.toStringAsFixed(2)})² + ${b.toStringAsFixed(2)}²) = '
              '${rafterLength.toStringAsFixed(2)} м',
        ),
        CalculationStep(
          title: '2. Длина ската с выпусками',
          formula:
              'D_полн = D+T1+T2 = ${d.toStringAsFixed(2)}+${t1.toStringAsFixed(2)}+${t2.toStringAsFixed(2)} = '
              '${totalLength.toStringAsFixed(2)} м',
        ),
        CalculationStep(
          title: '3. Площадь кровли',
          formula:
              'S = ${rafterLength.toStringAsFixed(2)} × ${totalLength.toStringAsFixed(2)} = '
              '${roofArea.toStringAsFixed(2)} м²',
        ),
        CalculationStep(
          title: '4. Угол наклона',
          formula: 'α = arctan(B / (A+K1+K2)) = ${slopeAngleDeg.toStringAsFixed(1)}°',
        ),
        CalculationStep(
          title: '5. С учётом запаса (${_reserve.round()}%)',
          formula:
              'S_итого = ${roofArea.toStringAsFixed(2)} × ${reserveMultiplier.toStringAsFixed(2)} = '
              '${totalArea.toStringAsFixed(2)} м²',
        ),
        CalculationStep(
          title: '6. Количество листов ($materialName)',
          formula:
              'По ширине: ${sheetsAcross} шт, по высоте: ${sheetsDown} шт → итого $totalSheets листов',
        ),
      ],
    );

    final now = DateTime.now();
    final historyItem = CalculationHistoryItem(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Кровля: ${widget.roofTypeName}',
      subtitle: '${totalArea.toStringAsFixed(2)} м² • $materialName',
      createdAt: now,
      icon: Icons.roofing,
      iconBgColor: const Color(0xFFF0FDFA),
      iconColor: AppColors.primary,
      category: 'Кровля',
      result: result,
    );

    try {
      await HistoryStorage.instance.addItem(historyItem);
    } catch (_) {}

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.roofTypeName,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Roof diagram
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Image.asset(
                      widget.imagePath,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main dimensions
                  _InputField(
                    controller: _widthController,
                    label: 'Ширина основания A',
                    unit: 'метров',
                    icon: Icons.straighten,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _lengthController,
                    label: 'Длина основания D',
                    unit: 'метров',
                    icon: Icons.straighten,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _heightController,
                    label: 'Высота подъема B',
                    unit: 'метров',
                    icon: Icons.height,
                  ),

                  const SizedBox(height: 24),

                  // Eave overhangs section header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Свес карниза',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: _k1Controller,
                          label: 'Слева K1',
                          unit: 'м',
                          icon: Icons.keyboard_arrow_left,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InputField(
                          controller: _k2Controller,
                          label: 'Справа K2',
                          unit: 'м',
                          icon: Icons.keyboard_arrow_right,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Eave projections section header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Выпуск карниза с торца',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: _t1Controller,
                          label: 'Левый T1',
                          unit: 'м',
                          icon: Icons.keyboard_arrow_left,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InputField(
                          controller: _t2Controller,
                          label: 'Правый T2',
                          unit: 'м',
                          icon: Icons.keyboard_arrow_right,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Parameters section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _parametersExpanded = !_parametersExpanded;
                            });
                          },
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.tune,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Параметры',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                AnimatedRotation(
                                  turns: _parametersExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(
                                    Icons.expand_more,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_parametersExpanded) ...[
                          Divider(
                            height: 1,
                            color: AppColors.outline.withValues(alpha: 0.3),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Кровельный материал',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textHint,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _roofingMaterial,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.textHint,
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                      items: _materials.entries.map((entry) {
                                        return DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(entry.value),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                            () => _roofingMaterial = value,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Запас на подрезку',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${_reserve.round()}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: AppColors.outline,
                                    thumbColor: AppColors.primary,
                                    overlayColor: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    trackHeight: 6,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 10,
                                      elevation: 3,
                                    ),
                                  ),
                                  child: Slider(
                                    value: _reserve,
                                    min: 0,
                                    max: 20,
                                    divisions: 20,
                                    onChanged: (value) {
                                      setState(() => _reserve = value);
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '0%',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                    Text(
                                      '10%',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                    Text(
                                      '20%',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0),
                  AppColors.background,
                  AppColors.background,
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: Text(
                  'Рассчитать',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSize {
  final double width;
  final double height;
  final String name;

  const _SheetSize({
    required this.width,
    required this.height,
    required this.name,
  });
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final String? hint;

  const _InputField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,
              ),
              floatingLabelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
              suffixText: unit,
              suffixStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textHint,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              hint!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ),
      ],
    );
  }
}
