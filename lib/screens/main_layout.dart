import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'badges_screen.dart';
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const BadgesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // For bottom nav transparency
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).colorScheme.secondary, // Amber
                unselectedItemColor: Theme.of(context).colorScheme.outline,
                selectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                unselectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.timer),
                    label: 'FOCUS',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                    label: 'STATS',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.military_tech),
                    label: 'BADGES',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

