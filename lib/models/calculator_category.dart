import 'package:flutter/material.dart';

class CalculatorCategory {
  final String name;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final String type;
  final String imagePath;

  const CalculatorCategory({
    required this.name,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.type,
    required this.imagePath,
  });

  static const List<CalculatorCategory> popular = [
    CalculatorCategory(
      name: 'Бетон',
      description: 'Объем м³, состав',
      icon: Icons.foundation,
      backgroundColor: Color(0xFFFFF0E5),
      type: 'concrete',
      imagePath: 'assets/images/concrete.png',
    ),
    CalculatorCategory(
      name: 'Покраска',
      description: 'Площадь, слои',
      icon: Icons.format_paint,
      backgroundColor: Color(0xFFEFF6FF),
      type: 'paint',
      imagePath: 'assets/images/paint.png',
    ),
    CalculatorCategory(
      name: 'Плитка',
      description: 'Раскладка, клей',
      icon: Icons.grid_view,
      backgroundColor: Color(0xFFFFFBEB),
      type: 'tile',
      imagePath: 'assets/images/tile.png',
    ),
  ];

  static const List<CalculatorCategory> all = [
    CalculatorCategory(
      name: 'Кирпич',
      description: 'Кладка, блоки',
      icon: Icons.view_compact,
      backgroundColor: Color(0xFFFEF2F2),
      type: 'brick',
      imagePath: 'assets/images/brick.png',
    ),
    CalculatorCategory(
      name: 'Штукатурка',
      description: 'Расход смеси',
      icon: Icons.brush,
      backgroundColor: Color(0xFFFAF5FF),
      type: 'plaster',
      imagePath: 'assets/images/plaster.png',
    ),
    CalculatorCategory(
      name: 'Кровля',
      description: 'Черепица, профнастил',
      icon: Icons.roofing,
      backgroundColor: Color(0xFFF0FDFA),
      type: 'roofing',
      imagePath: 'assets/images/roofing.png',
    ),
    CalculatorCategory(
      name: 'Утепление',
      description: 'Минвата, пенопласт',
      icon: Icons.ac_unit,
      backgroundColor: Color(0xFFFFFBEB),
      type: 'insulation',
      imagePath: 'assets/images/insulation.png',
    ),
    CalculatorCategory(
      name: 'Обои',
      description: 'Расчет рулонов',
      icon: Icons.wallpaper,
      backgroundColor: Color(0xFFFDF2F8),
      type: 'wallpaper',
      imagePath: 'assets/images/wallpaper.png',
    ),
    CalculatorCategory(
      name: 'Бетон',
      description: 'Фундамент, стяжка',
      icon: Icons.foundation,
      backgroundColor: Color(0xFFFFF0E5),
      type: 'concrete',
      imagePath: 'assets/images/concrete.png',
    ),
  ];
}
