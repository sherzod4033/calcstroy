import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class CalculatorCategory {
  final String name;
  final String description;
  final IconData icon;
  final Color Function() _backgroundColorGetter;
  final String type;
  final String imagePath;

  Color get backgroundColor => _backgroundColorGetter();

  const CalculatorCategory({
    required this.name,
    required this.description,
    required this.icon,
    required Color Function() backgroundColorGetter,
    required this.type,
    required this.imagePath,
  }) : _backgroundColorGetter = backgroundColorGetter;

  static final List<CalculatorCategory> popular = [
    CalculatorCategory(
      name: 'Бетон',
      description: 'Объем м³, состав',
      icon: Icons.foundation,
      backgroundColorGetter: () => AppColors.primaryLight,
      type: 'concrete',
      imagePath: 'assets/images/concrete.png',
    ),
    CalculatorCategory(
      name: 'Покраска',
      description: 'Площадь, слои',
      icon: Icons.format_paint,
      backgroundColorGetter: () => AppColors.categoryBlue,
      type: 'paint',
      imagePath: 'assets/images/paint.png',
    ),
    CalculatorCategory(
      name: 'Плитка',
      description: 'Раскладка, клей',
      icon: Icons.grid_view,
      backgroundColorGetter: () => AppColors.categoryYellow,
      type: 'tile',
      imagePath: 'assets/images/tile.png',
    ),
  ];

  static final List<CalculatorCategory> all = [
    CalculatorCategory(
      name: 'Кирпич',
      description: 'Кладка, блоки',
      icon: Icons.view_compact,
      backgroundColorGetter: () => AppColors.categoryRed,
      type: 'brick',
      imagePath: 'assets/images/brick.png',
    ),
    CalculatorCategory(
      name: 'Штукатурка',
      description: 'Расход смеси',
      icon: Icons.brush,
      backgroundColorGetter: () => AppColors.categoryPurple,
      type: 'plaster',
      imagePath: 'assets/images/plaster.png',
    ),
    CalculatorCategory(
      name: 'Кровля',
      description: 'Черепица, профнастил',
      icon: Icons.roofing,
      backgroundColorGetter: () => AppColors.categoryTeal,
      type: 'roofing',
      imagePath: 'assets/images/roofing.png',
    ),
    CalculatorCategory(
      name: 'Утепление',
      description: 'Минвата, пенопласт',
      icon: Icons.ac_unit,
      backgroundColorGetter: () => AppColors.categoryYellow,
      type: 'insulation',
      imagePath: 'assets/images/insulation.png',
    ),
    CalculatorCategory(
      name: 'Обои',
      description: 'Расчет рулонов',
      icon: Icons.wallpaper,
      backgroundColorGetter: () => AppColors.categoryPink,
      type: 'wallpaper',
      imagePath: 'assets/images/wallpaper.png',
    ),
    CalculatorCategory(
      name: 'Бетон',
      description: 'Фундамент, стяжка',
      icon: Icons.foundation,
      backgroundColorGetter: () => AppColors.primaryLight,
      type: 'concrete',
      imagePath: 'assets/images/concrete.png',
    ),
  ];
}
