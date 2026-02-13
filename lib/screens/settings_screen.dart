import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/app_info.dart';
import '../models/calculation_history.dart';
import '../services/app_settings_controller.dart';
import '../services/history_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettingsController _settings = AppSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String get _themeSubtitle {
    switch (_settings.themePreference) {
      case AppThemePreference.system:
        return 'Системная';
      case AppThemePreference.light:
        return 'Светлая';
      case AppThemePreference.dark:
        return 'Тёмная';
    }
  }

  String get _languageSubtitle {
    switch (_settings.language) {
      case AppLanguage.russian:
        return 'Русский';
      case AppLanguage.english:
        return 'English';
    }
  }

  String get _measurementSubtitle {
    switch (_settings.measurementSystem) {
      case MeasurementSystem.metric:
        return 'Метрические';
      case MeasurementSystem.imperial:
        return 'Имперские';
    }
  }

  String get _ratingSubtitle {
    final rating = _settings.rating;
    if (rating == null) {
      return 'Не оценено';
    }
    return '$rating / 5';
  }

  Future<void> _selectTheme() async {
    final selected = await _showSelectionSheet<AppThemePreference>(
      title: 'Выберите тему',
      selectedValue: _settings.themePreference,
      options: const [
        _SelectionOption(
          value: AppThemePreference.system,
          title: 'Системная',
          subtitle: 'Подстраиваться под тему устройства',
        ),
        _SelectionOption(value: AppThemePreference.light, title: 'Светлая'),
        _SelectionOption(value: AppThemePreference.dark, title: 'Тёмная'),
      ],
    );

    if (selected != null) {
      await _settings.setThemePreference(selected);
    }
  }

  Future<void> _selectLanguage() async {
    final selected = await _showSelectionSheet<AppLanguage>(
      title: 'Выберите язык',
      selectedValue: _settings.language,
      options: const [
        _SelectionOption(value: AppLanguage.russian, title: 'Русский'),
        _SelectionOption(value: AppLanguage.english, title: 'English'),
      ],
    );

    if (selected != null) {
      await _settings.setLanguage(selected);
      if (!mounted) {
        return;
      }
      _showSnackBar('Язык интерфейса обновлен');
    }
  }

  Future<void> _selectMeasurementSystem() async {
    final selected = await _showSelectionSheet<MeasurementSystem>(
      title: 'Единицы измерения',
      selectedValue: _settings.measurementSystem,
      options: const [
        _SelectionOption(
          value: MeasurementSystem.metric,
          title: 'Метрические',
          subtitle: 'м, см, м², м³',
        ),
        _SelectionOption(
          value: MeasurementSystem.imperial,
          title: 'Имперские',
          subtitle: 'ft, in, ft², ft³',
        ),
      ],
    );

    if (selected != null) {
      await _settings.setMeasurementSystem(selected);
      if (!mounted) {
        return;
      }
      _showSnackBar('Система единиц обновлена');
    }
  }

  Future<void> _exportHistory() async {
    final items = await HistoryStorage.instance.loadItems();
    if (items.isEmpty) {
      if (!mounted) {
        return;
      }
      _showSnackBar('История расчетов пуста');
      return;
    }

    if (!mounted) {
      return;
    }

    final format = await showModalBottomSheet<_ExportFormat>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Экспорт истории',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Выберите формат, данные будут скопированы в буфер обмена.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.data_object_outlined),
                  title: Text('JSON', style: GoogleFonts.inter()),
                  subtitle: Text(
                    'Полная структура расчетов',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  onTap: () => Navigator.pop(context, _ExportFormat.json),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.table_chart_outlined),
                  title: Text('CSV', style: GoogleFonts.inter()),
                  subtitle: Text(
                    'Упрощенный формат для таблиц',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  onTap: () => Navigator.pop(context, _ExportFormat.csv),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (format == null) {
      return;
    }

    final data = format == _ExportFormat.json
        ? _buildHistoryJson(items)
        : _buildHistoryCsv(items);

    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) {
      return;
    }
    _showSnackBar('Экспорт ${format.label} скопирован в буфер обмена');
  }

  Future<void> _clearHistory() async {
    final items = await HistoryStorage.instance.loadItems();
    if (items.isEmpty) {
      if (!mounted) {
        return;
      }
      _showSnackBar('История уже пуста');
      return;
    }

    if (!mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Очистить историю?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Будут удалены все сохраненные расчеты. Это действие нельзя отменить.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Отмена', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Очистить',
                style: GoogleFonts.inter(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await HistoryStorage.instance.clear();
    if (!mounted) {
      return;
    }
    _showSnackBar('История очищена');
  }

  Future<void> _rateApp() async {
    final selectedRating = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Оцените приложение',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Насколько вам полезен BuildCalc?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  final isSelected =
                      _settings.rating != null && value <= _settings.rating!;
                  return InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => Navigator.pop(context, value),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: GoogleFonts.inter()),
            ),
          ],
        );
      },
    );

    if (selectedRating == null) {
      return;
    }

    await _settings.setRating(selectedRating);
    if (!mounted) {
      return;
    }
    _showSnackBar('Спасибо за оценку!');
  }

  void _showVersionInfo() {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.appName,
      applicationVersion: AppInfo.version,
      children: [
        Text(
          'BuildCalc помогает быстро считать строительные материалы и сохранять расчеты в истории.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<T?> _showSelectionSheet<T>({
    required String title,
    required T selectedValue,
    required List<_SelectionOption<T>> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((option) {
                  final isSelected = option.value == selectedValue;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option.title,
                      style: GoogleFonts.inter(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: option.subtitle != null
                        ? Text(
                            option.subtitle!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: AppColors.primary)
                        : Icon(
                            Icons.radio_button_unchecked,
                            color: AppColors.textHint,
                          ),
                    onTap: () => Navigator.pop(context, option.value),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildHistoryJson(List<CalculationHistoryItem> items) {
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': AppInfo.version,
      'language': _settings.language.name,
      'measurementSystem': _settings.measurementSystem.name,
      'itemsCount': items.length,
      'items': items.map((item) => item.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _buildHistoryCsv(List<CalculationHistoryItem> items) {
    final headers = <String>[
      'id',
      'createdAt',
      'category',
      'title',
      'subtitle',
      'resultTitle',
      'mainValue',
      'mainUnit',
      'area',
      'price',
    ];

    final rows = <String>[headers.join(';')];
    for (final item in items) {
      rows.add(
        [
          item.id,
          item.createdAt.toIso8601String(),
          item.category,
          item.title,
          item.subtitle,
          item.result.title,
          item.result.mainValue,
          item.result.mainUnit,
          item.result.area,
          item.result.price,
        ].map(_escapeCsvValue).join(';'),
      );
    }
    return rows.join('\n');
  }

  String _escapeCsvValue(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(RegExp(r'[;"\n]'))) {
      return '"$escaped"';
    }
    return escaped;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
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
            _SettingsGroup(
              title: 'Общие',
              items: [
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Тема',
                  subtitle: _themeSubtitle,
                  onTap: _selectTheme,
                ),
                _SettingsItem(
                  icon: Icons.language,
                  title: 'Язык',
                  subtitle: _languageSubtitle,
                  onTap: _selectLanguage,
                ),
                _SettingsItem(
                  icon: Icons.straighten,
                  title: 'Единицы измерения',
                  subtitle: _measurementSubtitle,
                  onTap: _selectMeasurementSystem,
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
                  onTap: _exportHistory,
                ),
                _SettingsItem(
                  icon: Icons.delete_outline,
                  title: 'Очистить историю',
                  titleColor: AppColors.error,
                  onTap: _clearHistory,
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
                  subtitle: AppInfo.version,
                  onTap: _showVersionInfo,
                ),
                _SettingsItem(
                  icon: Icons.star_outline,
                  title: 'Оценить',
                  subtitle: _ratingSubtitle,
                  onTap: _rateApp,
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
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
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

class _SelectionOption<T> {
  final T value;
  final String title;
  final String? subtitle;

  const _SelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
  });
}

enum _ExportFormat { json, csv }

extension on _ExportFormat {
  String get label {
    switch (this) {
      case _ExportFormat.json:
        return 'JSON';
      case _ExportFormat.csv:
        return 'CSV';
    }
  }
}
