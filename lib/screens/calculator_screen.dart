import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../models/calculation_history.dart';
import '../models/calculation_result.dart';
import '../models/calculator_category.dart';
import '../services/history_storage.dart';
import 'results_screen.dart';

class CalculatorScreen extends StatefulWidget {
  final CalculatorCategory category;

  const CalculatorScreen({super.key, required this.category});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  int _selectedTabIndex = 0;
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _thicknessController = TextEditingController();

  String _selectedGrade = 'm200';
  double _reserve = 5;
  bool _parametersExpanded = true;

  final List<String> _tabs = ['Плита', 'Лента', 'Столб'];
  final List<IconData> _tabIcons = [
    Icons.grid_view,
    Icons.linear_scale,
    Icons.view_column,
  ];

  final Map<String, String> _grades = {
    'm100': 'M100 (В7.5) - Подготовка',
    'm150': 'M150 (В12.5) - Стяжка',
    'm200': 'M200 (В15) - Стандарт',
    'm250': 'M250 (В20) - Фундамент',
    'm300': 'M300 (В22.5) - Стены',
    'm350': 'M350 (В25) - Плиты',
  };

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _thicknessController.dispose();
    super.dispose();
  }

  String get _constructionName {
    switch (_selectedTabIndex) {
      case 1:
        return 'Ленточный фундамент';
      case 2:
        return 'Столбчатый фундамент';
      default:
        return 'Фундаментная плита';
    }
  }

  String get _lengthLabel {
    switch (_selectedTabIndex) {
      case 1:
        return 'Общая длина ленты';
      case 2:
        return 'Количество столбов';
      default:
        return 'Длина';
    }
  }

  String get _widthLabel {
    switch (_selectedTabIndex) {
      case 1:
        return 'Ширина ленты';
      case 2:
        return 'Сторона столба';
      default:
        return 'Ширина';
    }
  }

  String get _thicknessLabel {
    switch (_selectedTabIndex) {
      case 1:
        return 'Высота ленты';
      case 2:
        return 'Высота столба';
      default:
        return 'Толщина';
    }
  }

  String get _lengthUnit => _selectedTabIndex == 2 ? 'шт' : 'м';

  String get _widthUnit => _selectedTabIndex == 2 ? 'см' : 'м';

  String get _thicknessUnit => _selectedTabIndex == 2 ? 'м' : 'см';

  String? get _widthHint {
    if (_selectedTabIndex == 2) {
      return 'Обычно 30-40 см';
    }
    return null;
  }

  String get _thicknessHint {
    switch (_selectedTabIndex) {
      case 1:
        return 'Обычно 40-80 см';
      case 2:
        return 'Обычно 1.5-3 м';
      default:
        return 'Обычно 10-20 см';
    }
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
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

  _ConcreteVolumeData _buildVolumeData(
    double first,
    double second,
    double third,
  ) {
    switch (_selectedTabIndex) {
      case 1:
        final heightInMeters = third / 100;
        final volume = first * second * heightInMeters;
        final area = first * second;
        return _ConcreteVolumeData(
          volume: volume,
          area: area,
          formula:
              'V = ${first.toStringAsFixed(2)}м × ${second.toStringAsFixed(2)}м × '
              '${heightInMeters.toStringAsFixed(2)}м = ${volume.toStringAsFixed(2)} м³',
        );
      case 2:
        final sideInMeters = second / 100;
        final volume = first * sideInMeters * sideInMeters * third;
        final area = first * sideInMeters * sideInMeters;
        return _ConcreteVolumeData(
          volume: volume,
          area: area,
          formula:
              'V = ${first.toStringAsFixed(2)} × ${sideInMeters.toStringAsFixed(2)}м × '
              '${sideInMeters.toStringAsFixed(2)}м × ${third.toStringAsFixed(2)}м = '
              '${volume.toStringAsFixed(2)} м³',
        );
      default:
        final thicknessInMeters = third / 100;
        final volume = first * second * thicknessInMeters;
        final area = first * second;
        return _ConcreteVolumeData(
          volume: volume,
          area: area,
          formula:
              'V = ${first.toStringAsFixed(2)}м × ${second.toStringAsFixed(2)}м × '
              '${thicknessInMeters.toStringAsFixed(2)}м = ${volume.toStringAsFixed(2)} м³',
        );
    }
  }

  Future<void> _calculate() async {
    if (widget.category.type != 'concrete') {
      _showValidationError('Для этой категории калькулятор пока недоступен');
      return;
    }

    final first = _parseNumber(_lengthController.text);
    final second = _parseNumber(_widthController.text);
    final third = _parseNumber(_thicknessController.text);

    if (first == null || second == null || third == null) {
      _showValidationError('Введите корректные числовые значения');
      return;
    }

    if (first <= 0 || second <= 0 || third <= 0) {
      _showValidationError('Все параметры должны быть больше нуля');
      return;
    }

    final volumeData = _buildVolumeData(first, second, third);
    final volume = volumeData.volume;

    if (volume <= 0) {
      _showValidationError('Не удалось рассчитать объем. Проверьте параметры');
      return;
    }

    final reserveMultiplier = 1 + _reserve / 100;
    final totalVolume = volume * reserveMultiplier;

    // Typical mix proportions per 1 m³.
    final cementPerM3 = _getCementPerM3();
    final totalCement = (totalVolume * cementPerM3).ceil();
    final totalSand = (totalVolume * 600).ceil();
    final totalGravel = (totalVolume * 1200).ceil();
    final totalWater = (totalVolume * 200).ceil();

    final cementBags = (totalCement / 50).ceil();

    final gradeText = _grades[_selectedGrade] ?? 'M200 (В15) - Стандарт';
    final gradeShort = gradeText.split(' - ').first;

    final result = CalculationResult(
      title: 'Результаты: Бетон (${_tabs[_selectedTabIndex]})',
      mainValue: totalVolume.toStringAsFixed(2),
      mainUnit: 'м³',
      subtitle:
          'Вкл. запас ${_reserve.round()}% '
          '(${(volume * _reserve / 100).toStringAsFixed(2)} м³)',
      area: '${volumeData.area.toStringAsFixed(2)} м²',
      price: '~${(totalVolume * 5500).round()} ₽',
      materials: [
        MaterialItem(
          name: 'Цемент',
          quantity: '$cementBags мешков',
          details: '$gradeText, 50 кг',
          isChecked: true,
        ),
        MaterialItem(
          name: 'Песок',
          quantity: '${(totalSand / 1000).toStringAsFixed(2)} тонн',
          details: 'Речной, мытый',
        ),
        MaterialItem(
          name: 'Щебень',
          quantity: '${(totalGravel / 1000).toStringAsFixed(2)} тонн',
          details: 'Фракция 5-20 мм',
        ),
        MaterialItem(
          name: 'Вода',
          quantity: '$totalWater л',
          details: 'Чистая, питьевая',
        ),
      ],
      steps: [
        CalculationStep(
          title: '1. Расчет объема (${_tabs[_selectedTabIndex]})',
          formula: volumeData.formula,
        ),
        CalculationStep(
          title: '2. Добавление запаса (${_reserve.round()}%)',
          formula:
              'V_итого = ${volume.toStringAsFixed(2)} × '
              '${reserveMultiplier.toStringAsFixed(2)} = '
              '${totalVolume.toStringAsFixed(2)} м³',
        ),
        CalculationStep(
          title: '3. Расчет цемента',
          formula:
              'Цемент = ${totalVolume.toStringAsFixed(2)} × $cementPerM3 = '
              '$totalCement кг → $cementBags мешков',
        ),
        CalculationStep(
          title: '4. Расчет заполнителей',
          formula:
              'Песок: $totalSand кг, Щебень: $totalGravel кг, Вода: $totalWater л',
        ),
      ],
    );

    final now = DateTime.now();
    final historyItem = CalculationHistoryItem(
      id: now.microsecondsSinceEpoch.toString(),
      title: '${widget.category.name}: ${_tabs[_selectedTabIndex]}',
      subtitle: '${totalVolume.toStringAsFixed(2)} м³ • $gradeShort',
      createdAt: now,
      icon: _tabIcons[_selectedTabIndex],
      iconBgColor: widget.category.backgroundColor,
      iconColor: AppColors.primary,
      category: widget.category.name,
      result: result,
    );

    try {
      await HistoryStorage.instance.addItem(historyItem);
    } catch (_) {
      // Calculation should still be visible even if history persistence fails.
    }

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
    );
  }

  double _getCementPerM3() {
    switch (_selectedGrade) {
      case 'm100':
        return 170;
      case 'm150':
        return 200;
      case 'm200':
        return 240;
      case 'm250':
        return 300;
      case 'm300':
        return 350;
      case 'm350':
        return 400;
      default:
        return 240;
    }
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
          'Калькулятор ${widget.category.name}',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _tabIcons[_selectedTabIndex],
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _constructionName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: List.generate(3, (index) {
                        final isSelected = _selectedTabIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_selectedTabIndex == index) {
                                return;
                              }
                              setState(() {
                                _selectedTabIndex = index;
                                _lengthController.clear();
                                _widthController.clear();
                                _thicknessController.clear();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _tabIcons[index],
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _tabs[index],
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InputField(
                    controller: _lengthController,
                    label: _lengthLabel,
                    unit: _lengthUnit,
                    icon: Icons.straighten,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _widthController,
                    label: _widthLabel,
                    unit: _widthUnit,
                    icon: Icons.square_foot,
                    hint: _widthHint,
                  ),
                  const SizedBox(height: 16),
                  _InputField(
                    controller: _thicknessController,
                    label: _thicknessLabel,
                    unit: _thicknessUnit,
                    icon: Icons.layers,
                    hint: _thicknessHint,
                  ),
                  const SizedBox(height: 32),
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
                                  'Марка Бетона',
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
                                      value: _selectedGrade,
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
                                      items: _grades.entries.map((entry) {
                                        return DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(entry.value),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                            () => _selectedGrade = value,
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
                                      'Запас на усадку',
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

class _ConcreteVolumeData {
  final double volume;
  final double area;
  final String formula;

  const _ConcreteVolumeData({
    required this.volume,
    required this.area,
    required this.formula,
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
              prefixIcon: Icon(icon, color: AppColors.textHint),
              suffixText: unit,
              suffixStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              hint!,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
