import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../models/calculation_history.dart';
import '../models/calculator_category.dart';
import '../services/history_storage.dart';
import 'calculator_screen.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'Все';
  List<String> _filters = const ['Все'];
  List<CalculationHistoryItem> _items = const [];

  @override
  void initState() {
    super.initState();
    HistoryStorage.changes.addListener(_onHistoryChanged);
    _loadHistory();
  }

  @override
  void dispose() {
    HistoryStorage.changes.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await HistoryStorage.instance.loadItems();
    if (!mounted) {
      return;
    }

    final categories = items.map((item) => item.category).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    final filters = ['Все', ...categories];

    setState(() {
      _items = items;
      _filters = filters;
      if (!filters.contains(_selectedFilter)) {
        _selectedFilter = 'Все';
      }
      _isLoading = false;
    });
  }

  List<CalculationHistoryItem> get _filteredItems {
    if (_selectedFilter == 'Все') {
      return _items;
    }
    return _items.where((item) => item.category == _selectedFilter).toList();
  }

  List<CalculationHistoryItem> get _todayItems {
    final now = DateTime.now();
    return _filteredItems
        .where((item) => _isSameDay(item.createdAt, now))
        .toList();
  }

  List<CalculationHistoryItem> get _yesterdayItems {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _filteredItems
        .where((item) => _isSameDay(item.createdAt, yesterday))
        .toList();
  }

  List<CalculationHistoryItem> get _olderItems {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return _filteredItems
        .where(
          (item) =>
              !_isSameDay(item.createdAt, now) &&
              !_isSameDay(item.createdAt, yesterday),
        )
        .toList();
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Очистить историю?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Все сохраненные расчеты будут удалены без возможности восстановления.',
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

    if (confirmed == true) {
      await HistoryStorage.instance.clear();
    }
  }

  void _openHistoryItem(CalculationHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultsScreen(result: item.result)),
    );
  }

  void _startNewCalculation() {
    final category = CalculatorCategory.popular.firstWhere(
      (item) => item.type == 'concrete',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CalculatorScreen(category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayItems;
    final yesterday = _yesterdayItems;
    final older = _olderItems;
    final hasItems =
        today.isNotEmpty || yesterday.isNotEmpty || older.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'История',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: hasItems ? _clearHistory : null,
                    icon: Icon(
                      Icons.delete_outline,
                      color: hasItems
                          ? AppColors.textSecondary
                          : AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.outline.withValues(alpha: 0.5),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          filter,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasItems
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      children: [
                        if (today.isNotEmpty) ...[
                          _SectionLabel(title: 'СЕГОДНЯ'),
                          ...today.map(
                            (item) => _HistoryCard(
                              item: item,
                              timeLabel: _formatTime(item.createdAt),
                              onTap: () => _openHistoryItem(item),
                            ),
                          ),
                        ],
                        if (yesterday.isNotEmpty) ...[
                          _SectionLabel(title: 'ВЧЕРА'),
                          ...yesterday.map(
                            (item) => _HistoryCard(
                              item: item,
                              timeLabel: _formatTime(item.createdAt),
                              onTap: () => _openHistoryItem(item),
                            ),
                          ),
                        ],
                        if (older.isNotEmpty) ...[
                          _SectionLabel(title: 'РАНЕЕ'),
                          ...older.map(
                            (item) => _HistoryCard(
                              item: item,
                              timeLabel: DateFormat(
                                'dd.MM.yy HH:mm',
                              ).format(item.createdAt),
                              onTap: () => _openHistoryItem(item),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Center(child: _EmptyState()),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewCalculation,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CalculationHistoryItem item;
  final String timeLabel;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.item,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.outline,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(60),
          ),
          child: const Icon(
            Icons.calculate_outlined,
            size: 56,
            color: AppColors.outline,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Нет расчетов',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 200,
          child: Text(
            'Здесь пока ничего нет. Начните новый расчет на главном экране.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }
}
