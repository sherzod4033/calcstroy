import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Text(
                'Настройки',
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Settings groups
            _SettingsGroup(
              title: 'Общие',
              items: [
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Тема',
                  subtitle: 'Светлая',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.language,
                  title: 'Язык',
                  subtitle: 'Русский',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.straighten,
                  title: 'Единицы измерения',
                  subtitle: 'Метрические',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Данные',
              items: [
                _SettingsItem(
                  icon: Icons.file_download_outlined,
                  title: 'Экспорт истории',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.delete_outline,
                  title: 'Очистить историю',
                  titleColor: AppColors.error,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'О приложении',
              items: [
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'Версия',
                  subtitle: '1.0.0',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.star_outline,
                  title: 'Оценить',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.outline.withValues(alpha: 0.3),
                    ),
                  items[index],
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: titleColor ?? AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.outline.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
