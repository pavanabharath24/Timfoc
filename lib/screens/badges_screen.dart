import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../theme/lofi_theme.dart';
import 'settings_screen.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  static const List<_BadgeData> badges = [
    _BadgeData(Icons.shield_outlined, 'Bronze', 3, Color(0xFFC56F3F)),
    _BadgeData(Icons.shield, 'Silver', 7, Color(0xFFA1A3A6)),
    _BadgeData(Icons.military_tech, 'Gold', 14, Color(0xFFD4A716)),
    _BadgeData(Icons.diamond_outlined, 'Platinum', 21, Color(0xFF0A9B9F)),
    _BadgeData(Icons.diamond, 'Diamond', 30, Color(0xFF0D79B3)),
    _BadgeData(Icons.emoji_events, 'Crown', 50, Color(0xFFD18915)),
    _BadgeData(Icons.grade, 'Ace', 75, Color(0xFFD24141)),
    _BadgeData(Icons.stars, 'Master', 100, Color(0xFF8F2AA3)),
    _BadgeData(Icons.auto_awesome, 'Grandmaster', 150, Color(0xFF5D38A2)),
    _BadgeData(Icons.workspace_premium, 'Legend', 200, Color(0xFFCC331A)),
    _BadgeData(Icons.brightness_high, 'Mythic', 300, Color(0xFFCF1B56)),
    _BadgeData(Icons.local_fire_department, 'Immortal', 365, Color(0xFF651B8D)),
    _BadgeData(Icons.bolt, 'Conqueror', 500, Color(0xFFA91629)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            Text('COLLECTION', style: theme.textTheme.labelMedium?.copyWith(color: LofiTheme.primary)),
            const SizedBox(height: 8),
            Text('Trophies', style: theme.textTheme.displayLarge?.copyWith(fontSize: 40, height: 1.1)),
            const SizedBox(height: 8),
            Text(
              'Milestones of your focus journey. Each badge represents hours of dedicated effort.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            Consumer<StatsProvider>(
              builder: (context, statsProvider, _) {
                final currentStreak = statsProvider.currentStreak;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Milestone', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildNextMilestoneCard(context, currentStreak),
                    const SizedBox(height: 32),
                    Text('All Ranks', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: badges.length, 
                      itemBuilder: (context, index) {
                        return _buildGridBadge(context, currentStreak, index);
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 120), // Bottom nav padding
          ],
        ),
      ),
    );
  }

  Widget _buildNextMilestoneCard(BuildContext context, int currentStreak) {
    _BadgeData? currentBadge;
    _BadgeData? nextBadge;
    int prevRequired = 0;

    for (int i = 0; i < badges.length; i++) {
      if (currentStreak < badges[i].requiredStreak) {
        nextBadge = badges[i];
        if (i > 0) {
          currentBadge = badges[i - 1];
          prevRequired = currentBadge.requiredStreak;
        }
        break;
      }
    }

    if (nextBadge == null) {
      currentBadge = badges.last;
    }

    final currentTitle = currentBadge?.name ?? 'Beginner';
    final currentIcon = currentBadge?.icon ?? Icons.eco;
    final currentColor = currentBadge?.color ?? LofiTheme.outline;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LofiTheme.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LofiTheme.outline.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: LofiTheme.surfaceHighest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: currentBadge != null ? [
                    BoxShadow(color: currentColor.withOpacity(0.3), blurRadius: 20, spreadRadius: -5)
                  ] : [],
                  border: Border.all(color: LofiTheme.surfaceHighest.withOpacity(0.5)),
                ),
                child: Center(
                  child: Icon(currentIcon, size: 40, color: currentBadge != null ? currentColor : LofiTheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            currentTitle, 
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24), 
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (currentBadge == null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.lock_outline, size: 16, color: LofiTheme.outline),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$currentStreak days active', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: LofiTheme.outline)),
                  ],
                ),
              ),
            ],
          ),
          if (nextBadge != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Next: ${nextBadge.name}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: nextBadge.color, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(nextBadge.icon, size: 14, color: nextBadge.color),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${nextBadge.requiredStreak - currentStreak} days left',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (currentStreak - prevRequired) / (nextBadge.requiredStreak - prevRequired),
                minHeight: 6,
                backgroundColor: LofiTheme.surfaceHighest,
                valueColor: AlwaysStoppedAnimation<Color>(nextBadge.color),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('MAXIMUM RANK ACHIEVED', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: currentColor, fontSize: 14)),
                const SizedBox(width: 6),
                Icon(currentIcon, size: 14, color: currentColor),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildGridBadge(BuildContext context, int currentStreak, int index) {
    final badge = badges[index];
    bool isUnlocked = currentStreak >= badge.requiredStreak;

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.6,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
              color: badge.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: badge.color.withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(badge.icon, color: badge.color, size: 32),
                if (!isUnlocked)
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: LofiTheme.surfaceHigh, shape: BoxShape.circle),
                      child: const Icon(Icons.lock, size: 10, color: LofiTheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(badge.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: LofiTheme.onSurface)),
          const SizedBox(height: 2),
          Text('${badge.requiredStreak}d', style: const TextStyle(fontSize: 11, color: LofiTheme.outline)),
        ],
      ),
    );
  }
}

class _BadgeData {
  final IconData icon;
  final String name;
  final int requiredStreak;
  final Color color;

  const _BadgeData(this.icon, this.name, this.requiredStreak, this.color);
}
