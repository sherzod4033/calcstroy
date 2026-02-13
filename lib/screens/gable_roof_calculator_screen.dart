import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../models/calculation_history.dart';
import '../models/calculation_result.dart';
import '../services/history_storage.dart';
import 'results_screen.dart';

class GableRoofCalculatorScreen extends StatefulWidget {
  final String roofTypeName;
  final String imagePath;

  const GableRoofCalculatorScreen({
    super.key,
    required this.roofTypeName,
    required this.imagePath,
  });

  @override
  State<GableRoofCalculatorScreen> createState() =>
      _GableRoofCalculatorScreenState();
}

class _GableRoofCalculatorScreenState extends State<GableRoofCalculatorScreen> {
  final _widthController = TextEditingController(text: '600');
  final _lengthController = TextEditingController(text: '800');
  final _heightController = TextEditingController(text: '300');
  final _eaveController = TextEditingController(text: '50');

  String _roofingMaterial = 'metallocherepitsa';
  double _reserve = 5;
  bool _parametersExpanded = true;

  final Map<String, String> _materials = {
    'keramicheskaya': 'Керамическая черепица',
    'cementno_peschanaya': 'Цементно-песчаная черепица',
    'bitumnaya': 'Битумная черепица',
    'metallocherepitsa': 'Металлочерепица',
    'shifer': 'Асбестоцементные плиты (шифер)',
    'faltsevaya': 'Стальная фальцевая кровля',
    'ondulin': 'Битумный шифер (ондулин)',
  };

  // Price per m² by material (approximate, in ₽)
  Map<String, double> get _pricePerM2 => {
    'keramicheskaya': 1200,
    'cementno_peschanaya': 900,
    'bitumnaya': 600,
    'metallocherepitsa': 450,
    'shifer': 200,
    'faltsevaya': 800,
    'ondulin': 350,
  };

  // Weight per m² by material (kg)
  Map<String, double> get _weightPerM2 => {
    'keramicheskaya': 45,
    'cementno_peschanaya': 40,
    'bitumnaya': 12,
    'metallocherepitsa': 5,
    'shifer': 15,
    'faltsevaya': 6,
    'ondulin': 4,
  };

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    _eaveController.dispose();
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
    final a1cm = _parseNumber(_widthController.text);
    final dCm = _parseNumber(_lengthController.text);
    final bCm = _parseNumber(_heightController.text);
    final cCm = _parseNumber(_eaveController.text);

    if (a1cm == null || dCm == null || bCm == null || cCm == null) {
      _showValidationError('Введите корректные числовые значения');
      return;
    }

    if (a1cm <= 0 || dCm <= 0 || bCm <= 0) {
      _showValidationError('Основные размеры должны быть больше нуля');
      return;
    }

    // Convert cm to meters
    final a1 = a1cm / 100; // ширина основания
    final d = dCm / 100; // длина основания
    final b = bCm / 100; // высота подъема
    final c = cCm / 100; // длина свеса

    // Half-width for symmetric gable
    final halfWidth = a1 / 2;

    // Rafter length (hypotenuse of half-width + height)
    final rafterLength = math.sqrt(halfWidth * halfWidth + b * b);

    // Full rafter with eave overhang
    final fullRafter = rafterLength + c;

    // Slope angle
    final slopeAngleDeg = math.atan(b / halfWidth) * 180 / math.pi;

    // Roof area (two slopes)
    final roofArea = 2 * fullRafter * d;

    // Reserve
    final reserveMultiplier = 1 + _reserve / 100;
    final totalArea = roofArea * reserveMultiplier;

    final materialName = _materials[_roofingMaterial]!;
    final price = _pricePerM2[_roofingMaterial]!;
    final weight = _weightPerM2[_roofingMaterial]!;

    // Total weight
    final totalWeight = totalArea * weight;

    // Ridge length
    final ridgeLength = d;

    // Rafters every 60 cm
    final rafterCount = (d / 0.6).ceil() + 1;
    final totalRafterCount = rafterCount * 2; // both slopes

    // Fasteners: ~8 per m²
    final fastenerCount = (totalArea * 8).ceil();

    // Waterproofing membrane (rolls 1.5m × 50m)
    final membraneRolls = (totalArea / (1.5 * 50 * 0.85)).ceil();

    final totalPrice = (totalArea * price).round();

    final result = CalculationResult(
      title: 'Результаты: ${widget.roofTypeName}',
      mainValue: totalArea.toStringAsFixed(2),
      mainUnit: 'м²',
      subtitle:
          'Вкл. запас ${_reserve.round()}% '
          '(${(roofArea * _reserve / 100).toStringAsFixed(2)} м²)',
      area: '${roofArea.toStringAsFixed(2)} м²',
      price: '~$totalPrice ₽',
      materials: [
        MaterialItem(
          name: materialName,
          quantity: '${totalArea.toStringAsFixed(1)} м²',
          details: '~${totalWeight.toStringAsFixed(0)} кг',
          isChecked: true,
        ),
        MaterialItem(
          name: 'Стропила',
          quantity: '$totalRafterCount шт',
          details: '${fullRafter.toStringAsFixed(2)} м, сечение 50×150 мм',
        ),
        MaterialItem(
          name: 'Гидроизоляция',
          quantity: '$membraneRolls рулонов',
          details: 'Мембрана 1.5×50 м',
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
              'L = √((A1/2)² + B²) = √((${(a1 / 2).toStringAsFixed(2)})² + ${b.toStringAsFixed(2)}²) = '
              '${rafterLength.toStringAsFixed(2)} м',
        ),
        CalculationStep(
          title: '2. С учётом свеса',
          formula:
              'L_полн = ${rafterLength.toStringAsFixed(2)} + ${c.toStringAsFixed(2)} = '
              '${fullRafter.toStringAsFixed(2)} м',
        ),
        CalculationStep(
          title: '3. Угол наклона',
          formula:
              'α = arctan(B / (A1/2)) = arctan(${b.toStringAsFixed(2)} / ${halfWidth.toStringAsFixed(2)}) = '
              '${slopeAngleDeg.toStringAsFixed(1)}°',
        ),
        CalculationStep(
          title: '4. Площадь кровли (2 ската)',
          formula:
              'S = 2 × ${fullRafter.toStringAsFixed(2)} × ${d.toStringAsFixed(2)} = '
              '${roofArea.toStringAsFixed(2)} м²',
        ),
        CalculationStep(
          title: '5. С учётом запаса (${_reserve.round()}%)',
          formula:
              'S_итого = ${roofArea.toStringAsFixed(2)} × ${reserveMultiplier.toStringAsFixed(2)} = '
              '${totalArea.toStringAsFixed(2)} м²',
        ),
        CalculationStep(
          title: '6. Вес кровельного покрытия',
          formula:
              'Масса = ${totalArea.toStringAsFixed(2)} × ${weight.toStringAsFixed(0)} = '
              '${totalWeight.toStringAsFixed(0)} кг',
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
      iconBgColor: AppColors.categoryTeal,
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
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
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

                  // Material selector
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.roofing,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Материал',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _roofingMaterial,
                                isExpanded: true,
                                icon: Icon(
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
                                    child: Text(
                                      entry.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _roofingMaterial = value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Input fields
                  _InputField(
                    controller: _widthController,
                    label: 'Ширина основания A1',
                    unit: 'см',
                    icon: Icons.straighten,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _lengthController,
                    label: 'Длина основания D',
                    unit: 'см',
                    icon: Icons.straighten,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _heightController,
                    label: 'Высота подъема B',
                    unit: 'см',
                    icon: Icons.height,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _eaveController,
                    label: 'Длина свеса C',
                    unit: 'см',
                    icon: Icons.expand,
                  ),

                  const SizedBox(height: 32),

                  // Reserve parameter
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
                                  child: Icon(
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        style: GoogleFonts.inter(fontSize: 18, color: AppColors.textPrimary),
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
    );
  }
}
