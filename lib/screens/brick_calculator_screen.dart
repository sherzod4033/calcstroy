import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../models/calculation_history.dart';
import '../models/calculation_result.dart';
import '../services/history_storage.dart';
import 'results_screen.dart';

/// Brick size: length × width × height (mm)
class BrickSize {
  final String label;
  final double length;
  final double width;
  final double height;

  const BrickSize({
    required this.label,
    required this.length,
    required this.width,
    required this.height,
  });

  static const List<BrickSize> all = [
    BrickSize(
      label: '250×120×65 Облицовочный (одинарный)',
      length: 250,
      width: 120,
      height: 65,
    ),
    BrickSize(
      label: '250×120×65 1 НФ (одинарный)',
      length: 250,
      width: 120,
      height: 65,
    ),
    BrickSize(
      label: '250×120×88 1,4 НФ (полуторный)',
      length: 250,
      width: 120,
      height: 88,
    ),
    BrickSize(
      label: '250×120×140 2,1 НФ (двойной)',
      length: 250,
      width: 120,
      height: 140,
    ),
    BrickSize(
      label: '250×85×65 0,7 НФ (Евро)',
      length: 250,
      width: 85,
      height: 65,
    ),
    BrickSize(
      label: '288×63×138 1,3 НФ (модульный)',
      length: 288,
      width: 63,
      height: 138,
    ),
    BrickSize(
      label: '250×120×138 Силикатный 3х пустотный',
      length: 250,
      width: 120,
      height: 138,
    ),
  ];
}

class BrickCalculatorScreen extends StatefulWidget {
  const BrickCalculatorScreen({super.key});

  @override
  State<BrickCalculatorScreen> createState() => _BrickCalculatorScreenState();
}

class _BrickCalculatorScreenState extends State<BrickCalculatorScreen> {
  int _selectedBrickIndex = 0;

  // Main inputs
  final _perimeterController = TextEditingController(text: '30');
  final _wallHeightController = TextEditingController(text: '300');
  final _priceController = TextEditingController(text: '0');
  final _hollownessController = TextEditingController(text: '0');

  // Dropdowns
  String _wallThickness = 'two'; // Половина, 1, 1.5, 2
  String _mortarThickness = '10'; // mm
  String _meshFrequency = 'every_3'; // mesh frequency

  // Gables (expandable)
  bool _gablesExpanded = false;
  final _gableCountController = TextEditingController(text: '0');
  final _gableHeightController = TextEditingController(text: '0');
  final _gableWidthController = TextEditingController(text: '0');

  // Windows & doors (expandable)
  bool _openingsExpanded = false;
  final _windowHeightController = TextEditingController(text: '0');
  final _windowWidthController = TextEditingController(text: '0');
  final _windowCountController = TextEditingController(text: '0');
  final _doorHeightController = TextEditingController(text: '0');
  final _doorWidthController = TextEditingController(text: '0');
  final _doorCountController = TextEditingController(text: '0');

  // Wall thickness multiplier (in bricks)
  final Map<String, String> _thicknessLabels = {
    'half': 'Половина кирпича',
    'one': 'В 1 кирпич',
    'one_half': 'В 1,5 кирпича',
    'two': 'В 2 кирпича',
  };

  final Map<String, double> _thicknessMultiplier = {
    'half': 0.5,
    'one': 1.0,
    'one_half': 1.5,
    'two': 2.0,
  };

  final Map<String, String> _mortarLabels = {
    '5': 'Раствор 5 мм',
    '10': 'Раствор 10 мм',
    '15': 'Раствор 15 мм',
  };

  final Map<String, String> _meshLabels = {
    'every_1': 'Каждый ряд',
    'every_2': 'Через ряд',
    'every_3': 'Через 2 ряда',
    'every_4': 'Через 3 ряда',
    'every_5': 'Через 4 ряда',
  };

  final Map<String, int> _meshInterval = {
    'every_1': 1,
    'every_2': 2,
    'every_3': 3,
    'every_4': 4,
    'every_5': 5,
  };

  @override
  void dispose() {
    _perimeterController.dispose();
    _wallHeightController.dispose();
    _priceController.dispose();
    _hollownessController.dispose();
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
    final perimeter = _p(_perimeterController.text);
    final wallHeightCm = _p(_wallHeightController.text);
    final price = _p(_priceController.text) ?? 0;
    final hollowness = _p(_hollownessController.text) ?? 0;

    if (perimeter == null || wallHeightCm == null) {
      _showError('Введите периметр и высоту стен');
      return;
    }
    if (perimeter <= 0 || wallHeightCm <= 0) {
      _showError('Значения должны быть больше нуля');
      return;
    }

    final brick = BrickSize.all[_selectedBrickIndex];
    final mortarMm = double.parse(_mortarThickness);
    final thicknessMult = _thicknessMultiplier[_wallThickness]!;

    // Convert to meters where needed
    final wallHeightM = wallHeightCm / 100;
    final brickH = brick.height / 1000; // m
    final brickL = brick.length / 1000; // m
    final brickW = brick.width / 1000; // m
    final mortarM = mortarMm / 1000; // m

    // Gross wall area (m²)
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

    // Net wall area
    final netArea = grossArea + gableArea - windowArea - doorArea;
    if (netArea <= 0) {
      _showError('Площадь стен получилась ≤ 0. Проверьте размеры.');
      return;
    }

    // Bricks per m² for one layer (with mortar)
    final bricksPerRowM = 1 / (brickL + mortarM);
    final rowsPerM = 1 / (brickH + mortarM);
    final bricksPerM2Single = bricksPerRowM * rowsPerM;

    // Total for wall thickness
    final bricksPerM2 = bricksPerM2Single * (thicknessMult * 2);
    // thicknessMult * 2 because half-brick = 1 layer of widthwise

    // Actually, the standard approach: number of bricks per m² depends on thickness:
    // Half brick = 1 layer → bricksPerM2Single
    // 1 brick = 2 layers → bricksPerM2Single * 2
    // 1.5 brick = 3 layers → bricksPerM2Single * 3
    // 2 brick = 4 layers → bricksPerM2Single * 4
    final layers = (thicknessMult * 2).round();
    final totalBricksPerM2 = bricksPerM2Single * layers;

    final totalBricks = (totalBricksPerM2 * netArea).ceil();

    // Mortar volume (approximate: 0.2-0.3 m³ per 1000 bricks for 10mm joints)
    final mortarPer1000 = mortarMm == 5 ? 0.15 : mortarMm == 10 ? 0.25 : 0.35;
    final mortarVolume = totalBricks / 1000 * mortarPer1000;

    // Rows of bricks in wall height
    final rowsInHeight = (wallHeightM / (brickH + mortarM)).ceil();

    // Masonry mesh: perimeter × mesh every N rows
    final meshInterval = _meshInterval[_meshFrequency]!;
    final meshRows = (rowsInHeight / meshInterval).floor();
    // Wall thickness in m
    final wallThicknessM = thicknessMult * brickW;
    final meshArea = meshRows * perimeter * wallThicknessM;

    // Weight per brick (approximate)
    final brickVolumeCm3 = (brick.length / 10) * (brick.width / 10) * (brick.height / 10);
    final solidDensity = 1.8; // g/cm³ typical
    final brickWeight = brickVolumeCm3 * solidDensity * (1 - hollowness / 100) / 1000; // kg

    final totalWeight = totalBricks * brickWeight;

    final totalPrice = (totalBricks * price).round();

    final result = CalculationResult(
      title: 'Результаты: Кирпич',
      mainValue: totalBricks.toString(),
      mainUnit: 'шт',
      subtitle: brick.label,
      area: '${netArea.toStringAsFixed(2)} м²',
      price: price > 0 ? '~$totalPrice ₽' : 'Цена не указана',
      materials: [
        MaterialItem(
          name: 'Кирпич',
          quantity: '$totalBricks шт',
          details: '~${totalWeight.toStringAsFixed(0)} кг',
          isChecked: true,
        ),
        MaterialItem(
          name: 'Кладочный раствор',
          quantity: '${mortarVolume.toStringAsFixed(2)} м³',
          details: 'Толщина шва $mortarMm мм',
        ),
        MaterialItem(
          name: 'Кладочная сетка',
          quantity: '${meshArea.toStringAsFixed(1)} м²',
          details: '${_meshLabels[_meshFrequency]}',
        ),
        if (gableCount > 0)
          MaterialItem(
            name: 'Фронтоны',
            quantity: '$gableCount шт',
            details: '${gableArea.toStringAsFixed(2)} м²',
          ),
      ],
      steps: [
        CalculationStep(
          title: '1. Общая площадь стен',
          formula: 'S = $perimeter × ${wallHeightM.toStringAsFixed(2)} = '
              '${grossArea.toStringAsFixed(2)} м²',
        ),
        if (gableArea > 0)
          CalculationStep(
            title: '2. Площадь фронтонов',
            formula: 'S_ф = $gableCount × 0.5 × ${gableW.toStringAsFixed(2)} × '
                '${gableH.toStringAsFixed(2)} = ${gableArea.toStringAsFixed(2)} м²',
          ),
        if (windowArea > 0 || doorArea > 0)
          CalculationStep(
            title: '3. Вычет проёмов',
            formula: 'S_окна = ${windowArea.toStringAsFixed(2)} м², '
                'S_двери = ${doorArea.toStringAsFixed(2)} м²',
          ),
        CalculationStep(
          title: '${windowArea > 0 || doorArea > 0 || gableArea > 0 ? "4" : "2"}. Чистая площадь',
          formula: 'S_нетто = ${netArea.toStringAsFixed(2)} м²',
        ),
        CalculationStep(
          title: 'Кирпичей на 1 м² (${_thicknessLabels[_wallThickness]})',
          formula: '${totalBricksPerM2.toStringAsFixed(1)} шт/м²',
        ),
        CalculationStep(
          title: 'Общее количество',
          formula: '${totalBricksPerM2.toStringAsFixed(1)} × ${netArea.toStringAsFixed(2)} = '
              '$totalBricks шт',
        ),
        CalculationStep(
          title: 'Объём раствора',
          formula: '$totalBricks / 1000 × ${mortarPer1000.toStringAsFixed(2)} = '
              '${mortarVolume.toStringAsFixed(2)} м³',
        ),
      ],
    );

    final now = DateTime.now();
    final historyItem = CalculationHistoryItem(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Кирпич',
      subtitle: '$totalBricks шт • ${brick.label.split(' ').take(2).join(' ')}',
      createdAt: now,
      icon: Icons.view_compact,
      iconBgColor: const Color(0xFFFEF2F2),
      iconColor: AppColors.primary,
      category: 'Кирпич',
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
          'Калькулятор кирпича',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Brick type dropdown
                  _buildDropdownContainer(
                    icon: Icons.view_compact,
                    label: 'Вид кирпича',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedBrickIndex,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        items: List.generate(BrickSize.all.length, (i) {
                          return DropdownMenuItem(
                            value: i,
                            child: Text(
                              BrickSize.all[i].label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedBrickIndex = v);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Perimeter
                  _InputField(
                    controller: _perimeterController,
                    label: 'Общая длина стен (периметр)',
                    unit: 'м',
                    icon: Icons.straighten,
                  ),
                  const SizedBox(height: 16),

                  // Wall height
                  _InputField(
                    controller: _wallHeightController,
                    label: 'Высота стен по углам',
                    unit: 'см',
                    icon: Icons.height,
                  ),
                  const SizedBox(height: 16),

                  // Wall thickness
                  _buildDropdownContainer(
                    icon: Icons.layers,
                    label: 'Толщина стен',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _wallThickness,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        items: _thicknessLabels.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _wallThickness = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mortar thickness
                  _buildDropdownContainer(
                    icon: Icons.format_line_spacing,
                    label: 'Толщина раствора',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _mortarThickness,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        items: _mortarLabels.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _mortarThickness = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Masonry mesh
                  _buildDropdownContainer(
                    icon: Icons.grid_on,
                    label: 'Кладочная сетка',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _meshFrequency,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        items: _meshLabels.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _meshFrequency = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price per brick
                  _InputField(
                    controller: _priceController,
                    label: 'Цена за 1 шт',
                    unit: 'руб',
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(height: 16),

                  // Hollowness
                  _InputField(
                    controller: _hollownessController,
                    label: 'Пустотность кирпича',
                    unit: '%',
                    icon: Icons.donut_large,
                  ),

                  const SizedBox(height: 24),

                  // Gables section
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

                  // Windows & doors section
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
