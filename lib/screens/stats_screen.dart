import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../theme/lofi_theme.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsProvider = context.watch<StatsProvider>();
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AppBar replacement
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.spa, color: LofiTheme.secondary),
                    const SizedBox(width: 8),
                    Text('Timfoc', style: theme.textTheme.displaySmall?.copyWith(color: LofiTheme.secondary)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: LofiTheme.outline),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                )
              ],
            ),
            const SizedBox(height: 32),

            // Header Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PERFORMANCE HUB', style: theme.textTheme.labelMedium?.copyWith(color: LofiTheme.primary)),
                const SizedBox(height: 8),
                Text('Focus Mastery', style: theme.textTheme.displayLarge?.copyWith(fontSize: 40, height: 1.1)),
                const SizedBox(height: 8),
                Text(
                  'You\'ve maintained your sanctuary for ${statsProvider.currentStreak} consecutive days. The rhythm of deep work is becoming your nature.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CURRENT STREAK CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: LofiTheme.surfaceLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT STREAK', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: LofiTheme.outline)),
                      const SizedBox(height: 4),
                      Text('${statsProvider.currentStreak} Days', style: theme.textTheme.displaySmall?.copyWith(color: LofiTheme.secondary, fontSize: 32)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LofiTheme.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department, color: LofiTheme.secondary, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Weekly Momentum
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: LofiTheme.surfaceLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weekly Momentum', style: theme.textTheme.titleLarge),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: LofiTheme.surfaceHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('THIS WEEK', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBar('MON', statsProvider.weeklyMomentum[0], false),
                        _buildBar('TUE', statsProvider.weeklyMomentum[1], false),
                        _buildBar('WED', statsProvider.weeklyMomentum[2], true),
                        _buildBar('THU', statsProvider.weeklyMomentum[3], false),
                        _buildBar('FRI', statsProvider.weeklyMomentum[4], false),
                        _buildBar('SAT', statsProvider.weeklyMomentum[5], false),
                        _buildBar('SUN', statsProvider.weeklyMomentum[6], false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Consistency grid and Insights
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: LofiTheme.surfaceLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Daily Consistency', style: theme.textTheme.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16, color: LofiTheme.outline),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 14,
                    itemBuilder: (context, index) {
                      final minutes = statsProvider.last14DaysFocusMinutes[index];
                      Color boxColor;
                      Color textColor = LofiTheme.background;
                      bool hasBorder = false;

                      if (minutes > 60) {
                        boxColor = LofiTheme.secondary;
                      } else if (minutes > 0) {
                        boxColor = LofiTheme.secondary.withOpacity(0.5);
                      } else {
                        boxColor = LofiTheme.surfaceHighest;
                        textColor = LofiTheme.onSurfaceVariant;
                      }
                      
                      if (index == 13) hasBorder = true; // Today

                      final dayDate = DateTime.now().subtract(Duration(days: 13 - index));

                      return Container(
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(4),
                          border: hasBorder ? Border.all(color: LofiTheme.primary, width: 2) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${dayDate.day}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LofiTheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LofiTheme.outline.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Color(0xFFbac3ff), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                              children: [
                                const TextSpan(text: 'Consistency builds momentum. '),
                                TextSpan(text: 'Keep it going!', style: TextStyle(color: LofiTheme.onSurface, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Deep Dive Stats
            Row(
              children: [
                Expanded(child: _buildDeepDiveStat('Deep Focus', statsProvider.deepFocusTotalHours)),
                const SizedBox(width: 16),
                Expanded(child: _buildDeepDiveStat('Tasks Freed', '${statsProvider.totalSessions}')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDeepDiveStat('Avg Session', statsProvider.avgSessionDuration)),
              ],
            ),
            const SizedBox(height: 80), // Bottom nav padding
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double heightFraction, bool isActive) {
    if (heightFraction.isNaN || heightFraction.isInfinite) heightFraction = 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 120 * heightFraction,
          decoration: BoxDecoration(
            color: isActive ? LofiTheme.secondary : LofiTheme.surfaceHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: isActive
                ? [BoxShadow(color: LofiTheme.secondary.withOpacity(0.3), blurRadius: 20)]
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? LofiTheme.secondary : LofiTheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildDeepDiveStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LofiTheme.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: LofiTheme.outline, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LofiTheme.onSurface, fontFamily: 'Space Grotesk')),
        ],
      ),
    );
  }
}
