import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        color: AppColors.background,
        child: SafeArea(
          child: SizedBox(
            height: 67,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.84,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 7),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.24),
                          blurRadius: 11,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            icon: Icons.home_rounded,
                            semanticLabel: 'Главная',
                            isSelected: _currentIndex == 0,
                            onTap: () => setState(() => _currentIndex = 0),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: Icons.history_rounded,
                            semanticLabel: 'История',
                            isSelected: _currentIndex == 1,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: Icons.settings_rounded,
                            semanticLabel: 'Настройки',
                            isSelected: _currentIndex == 2,
                            onTap: () => setState(() => _currentIndex = 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.semanticLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              size: 23,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ),
      ),
    );
  }
}
