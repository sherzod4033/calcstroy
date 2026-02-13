import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../models/calculator_category.dart';
import 'calculator_screen.dart';
import 'brick_calculator_screen.dart';
import 'insulation_calculator_screen.dart';
import 'roofing_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Главная',
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        onPressed: () => _showFeatureMessage(
                          context,
                          'Уведомления будут добавлены позже',
                        ),
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск расчета (например, бетон, плитка)...',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textHint,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textHint,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => _showFeatureMessage(
                          context,
                          'Голосовой поиск пока недоступен',
                        ),
                        icon: const Icon(
                          Icons.mic_none,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Popular section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Популярное',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // Popular horizontal scroll
            SliverToBoxAdapter(
              child: SizedBox(
                height: 184,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: CalculatorCategory.popular.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final cat = CalculatorCategory.popular[index];
                    return _PopularCard(
                      category: cat,
                      onTap: () => _openCalculator(context, cat),
                    );
                  },
                ),
              ),
            ),

            // All tools header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Все инструменты',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showFeatureMessage(
                        context,
                        'Фильтрация будет добавлена позже',
                      ),
                      child: Text(
                        'Фильтр',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tools grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final cat = CalculatorCategory.all[index];
                  return _ToolCard(
                    category: cat,
                    onTap: () => _openCalculator(context, cat),
                  );
                }, childCount: CalculatorCategory.all.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCalculator(BuildContext context, CalculatorCategory category) {
    if (category.type == 'concrete') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CalculatorScreen(category: category)),
      );
      return;
    }

    if (category.type == 'roofing') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoofingSelectionScreen()),
      );
      return;
    }

    if (category.type == 'brick') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BrickCalculatorScreen()),
      );
      return;
    }

    if (category.type == 'insulation') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InsulationCalculatorScreen()),
      );
      return;
    }

    _showFeatureMessage(
      context,
      'Калькулятор "${category.name}" пока в разработке',
    );
  }

  void _showFeatureMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textSecondary,
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  final CalculatorCategory category;
  final VoidCallback onTap;
  static const double _scale = 0.8;
  static const double _widthScale = _scale * 1.1;

  const _PopularCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          width: 185 * _widthScale,
          child: _CategoryDesignCard(
            category: category,
            titleSize: 19 * _scale,
            subtitleSize: 11 * _scale,
            scale: _scale,
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final CalculatorCategory category;
  final VoidCallback onTap;
  static const double _scale = 0.8;
  static const double _widthScale = _scale * 1.1;

  const _ToolCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: _widthScale,
            heightFactor: _scale,
            child: _CategoryDesignCard(
              category: category,
              titleSize: 23 * _scale,
              subtitleSize: 13 * _scale,
              scale: _scale,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDesignCard extends StatelessWidget {
  final CalculatorCategory category;
  final double titleSize;
  final double subtitleSize;
  final double scale;

  const _CategoryDesignCard({
    required this.category,
    required this.titleSize,
    required this.subtitleSize,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: AppColors.primary, width: 2 * scale),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 14 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22 * scale),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFE9E9E9),
                padding: EdgeInsets.all(14 * scale),
                child: Image.asset(
                  category.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        category.icon,
                        size: 54 * scale,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(
                14 * scale,
                10 * scale,
                14 * scale,
                13 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    category.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: subtitleSize,
                      color: Colors.white.withValues(alpha: 0.96),
                      height: 1.18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
