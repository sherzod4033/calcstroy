import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../models/calculation_history.dart';
import '../models/calculation_result.dart';
import '../services/history_storage.dart';
import 'results_screen.dart';

class InsulationCalculatorScreen extends StatefulWidget {
  const InsulationCalculatorScreen({super.key});

  @override
  State<InsulationCalculatorScreen> createState() =>
      _InsulationCalculatorScreenState();
}

class _InsulationCalculatorScreenState
    extends State<InsulationCalculatorScreen> {
  // Insulation type
  String _insulationType = 'basalt';

  final Map<String, String> _insulationLabels = {
    'basalt': 'Базальтовая вата',
    'mineral': 'Минеральная вата',
    'penoplast': 'Пенопласт (ПСБ)',
    'penoplex': 'Пенополистирол (ЭППС)',
    'penoizol': 'Пеноизол',
    'ecovata': 'Эковата',
  };

  // Main inputs
  final _thicknessController = TextEditingController(text: '15');
  final _perimeterController = TextEditingController(text: '30');
  final _wallHeightController = TextEditingController(text: '300');
  final _densityController = TextEditingController(text: '30');

  // Cost section
  bool _costExpanded = false;
  final _pricePerM3Controller = TextEditingController(text: '1500');
  final _dowelPriceController = TextEditingController(text: '4');

  // Gables
  bool _gablesExpanded = false;
  final _gableCountController = TextEditingController(text: '0');
  final _gableHeightController = TextEditingController(text: '0');
  final _gableWidthController = TextEditingController(text: '0');

  // Windows & doors
  bool _openingsExpanded = false;
  final _windowHeightController = TextEditingController(text: '0');
  final _windowWidthController = TextEditingController(text: '0');
  final _windowCountController = TextEditingController(text: '0');
  final _doorHeightController = TextEditingController(text: '0');
  final _doorWidthController = TextEditingController(text: '0');
  final _doorCountController = TextEditingController(text: '0');

  @override
  void dispose() {
    _thicknessController.dispose();
    _perimeterController.dispose();
    _wallHeightController.dispose();
    _densityController.dispose();
    _pricePerM3Controller.dispose();
    _dowelPriceController.dispose();
    _gableCountController.dispose();
    _gableHeightController.dispose();
    _gableWidthController.dispose();
    _windowHeightController.dispose();
    _windowWidthController.dispose();
    _windowCountController.dispose();
    _doorHeightController.dispose();
    _doorWidthController.dispose();
    _doorCountController.dispose();
    super.dispose();
  }

  double? _p(String v) {
    final n = v.trim().replaceAll(',', '.');
    if (n.isEmpty) return null;
    return double.tryParse(n);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _calculate() async {
    final thicknessCm = _p(_thicknessController.text);
    final perimeter = _p(_perimeterController.text);
    final wallHeightCm = _p(_wallHeightController.text);
    final density = _p(_densityController.text) ?? 30;

    if (thicknessCm == null || perimeter == null || wallHeightCm == null) {
      _showError('Заполните все обязательные поля');
      return;
    }
    if (thicknessCm <= 0 || perimeter <= 0 || wallHeightCm <= 0) {
      _showError('Значения должны быть больше нуля');
      return;
    }

    final thicknessM = thicknessCm / 100;
    final wallHeightM = wallHeightCm / 100;

    // Gross wall area
    final grossArea = perimeter * wallHeightM;

    // Gable area
    final gableCount = (_p(_gableCountController.text) ?? 0).toInt();
    final gableH = (_p(_gableHeightController.text) ?? 0) / 100;
    final gableW = (_p(_gableWidthController.text) ?? 0) / 100;
    final gableArea = gableCount * 0.5 * gableW * gableH;

    // Window area
    final winCount = (_p(_windowCountController.text) ?? 0).toInt();
    final winH = (_p(_windowHeightController.text) ?? 0) / 100;
    final winW = (_p(_windowWidthController.text) ?? 0) / 100;
    final windowArea = winCount * winH * winW;

    // Door area
    final doorCount = (_p(_doorCountController.text) ?? 0).toInt();
    final doorH = (_p(_doorHeightController.text) ?? 0) / 100;
    final doorW = (_p(_doorWidthController.text) ?? 0) / 100;
    final doorArea = doorCount * doorH * doorW;

    // Net area
    final netArea = grossArea + gableArea - windowArea - doorArea;
    if (netArea <= 0) {
      _showError('Площадь утепления ≤ 0. Проверьте размеры.');
      return;
    }

    // Volume of insulation
    final volume = netArea * thicknessM;

    // Weight
    final weight = volume * density;

    // Number of layers (standard slab 50mm thick)
    final layersCount = (thicknessCm / 5).ceil();

    // Dowels: ~5–6 per m² per layer
    final dowelsPerM2 = 5;
    final totalDowels = (netArea * dowelsPerM2 * layersCount).ceil();

    // Standard pack coverage: 0.36 m³ per pack (typical for basalt/mineral)
    final packsNeeded = (volume / 0.36).ceil();

    // Cost
    final pricePerM3 = _p(_pricePerM3Controller.text) ?? 0;
    final dowelPrice = _p(_dowelPriceController.text) ?? 0;
    final insulationCost = (volume * pricePerM3).round();
    final dowelCost = (totalDowels * dowelPrice).round();
    final totalCost = insulationCost + dowelCost;

    final materialName = _insulationLabels[_insulationType]!;

    final result = CalculationResult(
      title: 'Результаты: Утепление',
      mainValue: volume.toStringAsFixed(2),
      mainUnit: 'м³',
      subtitle: materialName,
      area: '${netArea.toStringAsFixed(2)} м²',
      price: pricePerM3 > 0 ? '~$totalCost ₽' : 'Цена не указана',
      materials: [
        MaterialItem(
          name: materialName,
          quantity: '${volume.toStringAsFixed(2)} м³',
          details: '~${weight.toStringAsFixed(0)} кг (плотность ${density.toStringAsFixed(0)} кг/м³)',
          isChecked: true,
        ),
        MaterialItem(
          name: 'Кол-во упаковок',
          quantity: '$packsNeeded уп.',
          details: '~0.36 м³/уп.',
        ),
        MaterialItem(
          name: 'Слоёв утеплителя',
          quantity: '$layersCount шт',
          details: 'По 50 мм',
        ),
        MaterialItem(
          name: 'Дюбели «грибок»',
          quantity: '$totalDowels шт',
          details: '~$dowelsPerM2 шт/м² × $layersCount слоёв',
        ),
      ],
      steps: [
        CalculationStep(
          title: '1. Площадь стен (брутто)',
          formula: 'S = $perimeter × ${wallHeightM.toStringAsFixed(2)} = '
              '${grossArea.toStringAsFixed(2)} м²',
        ),
        if (gableArea > 0)
          CalculationStep(
            title: '2. Площадь фронтонов',
            formula: 'S_ф = ${gableArea.toStringAsFixed(2)} м²',
          ),
        if (windowArea > 0 || doorArea > 0)
          CalculationStep(
            title: '3. Вычет проёмов',
            formula: 'Окна: ${windowArea.toStringAsFixed(2)} м², '
                'Двери: ${doorArea.toStringAsFixed(2)} м²',
          ),
        CalculationStep(
          title: 'Чистая площадь утепления',
          formula: 'S = ${netArea.toStringAsFixed(2)} м²',
        ),
        CalculationStep(
          title: 'Объём утеплителя',
          formula: 'V = ${netArea.toStringAsFixed(2)} × ${thicknessM.toStringAsFixed(2)} = '
              '${volume.toStringAsFixed(2)} м³',
        ),
        CalculationStep(
          title: 'Масса утеплителя',
          formula: 'M = ${volume.toStringAsFixed(2)} × ${density.toStringAsFixed(0)} = '
              '${weight.toStringAsFixed(0)} кг',
        ),
        if (pricePerM3 > 0)
          CalculationStep(
            title: 'Стоимость',
            formula: 'Утеплитель: $insulationCost ₽, '
                'Дюбели: $dowelCost ₽, '
                'Итого: $totalCost ₽',
          ),
      ],
    );

    final now = DateTime.now();
    final historyItem = CalculationHistoryItem(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Утепление',
      subtitle: '${volume.toStringAsFixed(2)} м³ • $materialName',
      createdAt: now,
      icon: Icons.ac_unit,
      iconBgColor: const Color(0xFFFFFBEB),
      iconColor: AppColors.primary,
      category: 'Утепление',
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
          'Калькулятор утепления',
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

                  // Insulation type
                  _buildDropdownContainer(
                    icon: Icons.ac_unit,
                    label: 'Вид утеплителя',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _insulationType,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        items: _insulationLabels.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _insulationType = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _InputField(
                    controller: _thicknessController,
                    label: 'Толщина утеплителя',
                    unit: 'см',
                    icon: Icons.layers,
                  ),
                  const SizedBox(height: 16),

                  _InputField(
                    controller: _perimeterController,
                    label: 'Общая длина всех стен (периметр)',
                    unit: 'м',
                    icon: Icons.straighten,
                  ),
                  const SizedBox(height: 16),

                  _InputField(
                    controller: _wallHeightController,
                    label: 'Высота стен',
                    unit: 'см',
                    icon: Icons.height,
                  ),
                  const SizedBox(height: 16),

                  _InputField(
                    controller: _densityController,
                    label: 'Плотность утеплителя',
                    unit: 'кг/м³',
                    icon: Icons.density_medium,
                  ),

                  const SizedBox(height: 24),

                  // Cost section
                  _buildExpandableSection(
                    title: 'Стоимость',
                    icon: Icons.attach_money,
                    expanded: _costExpanded,
                    onTap: () => setState(() => _costExpanded = !_costExpanded),
                    children: [
                      _InputField(
                        controller: _pricePerM3Controller,
                        label: 'Цена за 1 кубометр утеплителя',
                        unit: 'руб',
                        icon: Icons.payments,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: _dowelPriceController,
                        label: 'Цена за 1 дюбель «грибок»',
                        unit: 'руб',
                        icon: Icons.push_pin,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gables
                  _buildExpandableSection(
                    title: 'Фронтоны',
                    icon: Icons.change_history,
                    expanded: _gablesExpanded,
                    onTap: () => setState(() => _gablesExpanded = !_gablesExpanded),
                    children: [
                      _InputField(
                        controller: _gableCountController,
                        label: 'Количество фронтонов',
                        unit: 'шт',
                        icon: Icons.tag,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: _gableHeightController,
                        label: 'Высота фронтонов',
                        unit: 'см',
                        icon: Icons.height,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: _gableWidthController,
                        label: 'Ширина фронтонов',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Windows & doors
                  _buildExpandableSection(
                    title: 'Учесть окна и двери',
                    icon: Icons.door_front_door,
                    expanded: _openingsExpanded,
                    onTap: () => setState(() => _openingsExpanded = !_openingsExpanded),
                    children: [
                      _InputField(
                        controller: _windowHeightController,
                        label: 'Высота окна A',
                        unit: 'см',
                        icon: Icons.crop_portrait,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: _windowWidthController,
                        label: 'Ширина окна B',
                        unit: 'см',
                        icon: Icons.crop_landscape,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: _windowCountController,
                        label: 'Количество таких окон',
                        unit: 'шт',
                        icon: Icons.tag,
                      ),
                      const SizedBox(height: 20),
                      _InputField(
                        controller: _doorHeightController,
                        label: 'Высота двери C',
                        unit: 'см',
                        icon: Icons.crop_portrait,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: _doorWidthController,
                        label: 'Ширина двери D',
                        unit: 'см',
                        icon: Icons.crop_landscape,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: _doorCountController,
                        label: 'Количество таких дверей',
                        unit: 'шт',
                        icon: Icons.tag,
                      ),
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Calculate button
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

  Widget _buildDropdownContainer({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool expanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: expanded ? Radius.zero : const Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: AppColors.outline.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: children),
            ),
          ],
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          ),
          floatingLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          suffixText: unit,
          suffixStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
