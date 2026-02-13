import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import 'gable_roof_calculator_screen.dart';
import 'roofing_calculator_screen.dart';

class RoofType {
  final String name;
  final String description;
  final String imagePath;
  final String calcImagePath;

  const RoofType({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.calcImagePath,
  });

  static const List<RoofType> all = [
    RoofType(
      name: 'Односкатная крыша',
      description: 'Простая конструкция с одним скатом. Подходит для пристроек, гаражей и хозпостроек.',
      imagePath: 'assets/images/roof_single.png',
      calcImagePath: 'assets/images/roof_single_calc.png',
    ),
    RoofType(
      name: 'Двухскатная крыша',
      description: 'Классическая форма с двумя скатами. Самый популярный тип для жилых домов.',
      imagePath: 'assets/images/roof_gable.png',
      calcImagePath: 'assets/images/roof_gable_calc.png',
    ),
    RoofType(
      name: 'Мансардная крыша',
      description: 'Ломаная конструкция для увеличения жилого пространства под крышей.',
      imagePath: 'assets/images/roof_mansard.png',
      calcImagePath: 'assets/images/roof_mansard_calc.png',
    ),
    RoofType(
      name: 'Вальмовая крыша',
      description: 'Четырёхскатная крыша без фронтонов. Устойчива к ветровым нагрузкам.',
      imagePath: 'assets/images/roof_hip.png',
      calcImagePath: 'assets/images/roof_hip_calc.png',
    ),
  ];
}

class RoofingSelectionScreen extends StatelessWidget {
  const RoofingSelectionScreen({super.key});

  void _openCalculator(BuildContext context, RoofType roof) {
    Widget screen;
    if (roof.name == 'Двухскатная крыша') {
      screen = GableRoofCalculatorScreen(
        roofTypeName: roof.name,
        imagePath: roof.calcImagePath,
      );
    } else {
      screen = RoofingCalculatorScreen(
        roofTypeName: roof.name,
        imagePath: roof.calcImagePath,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Кровля',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Выберите тип крыши',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...RoofType.all.map((roof) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _RoofCard(
                  roof: roof,
                  onTap: () => _openCalculator(context, roof),
                ),
              )),
        ],
      ),
    );
  }
}

class _RoofCard extends StatelessWidget {
  final RoofType roof;
  final VoidCallback onTap;

  const _RoofCard({required this.roof, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  color: AppColors.secondaryBackground,
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    roof.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Text area
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roof.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      roof.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Рассчитать',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
