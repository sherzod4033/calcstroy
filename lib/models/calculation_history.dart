import 'package:flutter/material.dart';
import 'calculation_result.dart';

class CalculationHistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String category;
  final CalculationResult result;

  const CalculationHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.category,
    required this.result,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'createdAt': createdAt.toIso8601String(),
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'iconMatchTextDirection': icon.matchTextDirection,
      'iconBgColor': iconBgColor.toARGB32(),
      'iconColor': iconColor.toARGB32(),
      'category': category,
      'result': result.toJson(),
    };
  }

  factory CalculationHistoryItem.fromJson(Map<String, dynamic> json) {
    return CalculationHistoryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      icon: IconData(
        json['iconCodePoint'] as int? ?? Icons.calculate.codePoint,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
        matchTextDirection: json['iconMatchTextDirection'] as bool? ?? false,
      ),
      iconBgColor: Color(json['iconBgColor'] as int? ?? 0xFFEFF6FF),
      iconColor: Color(json['iconColor'] as int? ?? 0xFF1565C0),
      category: json['category'] as String? ?? 'Прочее',
      result: CalculationResult.fromJson(
        Map<String, dynamic>.from(
          (json['result'] as Map?) ?? <String, dynamic>{},
        ),
      ),
    );
  }
}
