class MaterialItem {
  final String name;
  final String quantity;
  final String details;
  final bool isChecked;

  const MaterialItem({
    required this.name,
    required this.quantity,
    required this.details,
    this.isChecked = false,
  });

  MaterialItem copyWith({bool? isChecked}) {
    return MaterialItem(
      name: name,
      quantity: quantity,
      details: details,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'details': details,
      'isChecked': isChecked,
    };
  }

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      details: json['details'] as String? ?? '',
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }
}

class CalculationStep {
  final String title;
  final String formula;

  const CalculationStep({required this.title, required this.formula});

  Map<String, dynamic> toJson() {
    return {'title': title, 'formula': formula};
  }

  factory CalculationStep.fromJson(Map<String, dynamic> json) {
    return CalculationStep(
      title: json['title'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
    );
  }
}

class CalculationResult {
  final String title;
  final String mainValue;
  final String mainUnit;
  final String subtitle;
  final String area;
  final String price;
  final List<MaterialItem> materials;
  final List<CalculationStep> steps;

  const CalculationResult({
    required this.title,
    required this.mainValue,
    required this.mainUnit,
    required this.subtitle,
    required this.area,
    required this.price,
    required this.materials,
    required this.steps,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'mainValue': mainValue,
      'mainUnit': mainUnit,
      'subtitle': subtitle,
      'area': area,
      'price': price,
      'materials': materials.map((item) => item.toJson()).toList(),
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }

  factory CalculationResult.fromJson(Map<String, dynamic> json) {
    final materialsRaw = json['materials'] as List<dynamic>? ?? const [];
    final stepsRaw = json['steps'] as List<dynamic>? ?? const [];

    return CalculationResult(
      title: json['title'] as String? ?? '',
      mainValue: json['mainValue'] as String? ?? '',
      mainUnit: json['mainUnit'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      area: json['area'] as String? ?? '',
      price: json['price'] as String? ?? '',
      materials: materialsRaw
          .whereType<Map>()
          .map((item) => MaterialItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      steps: stepsRaw
          .whereType<Map>()
          .map(
            (step) => CalculationStep.fromJson(Map<String, dynamic>.from(step)),
          )
          .toList(),
    );
  }
}
