import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../theme/lofi_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerProvider = context.watch<TimerProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/logo.png', width: 32, height: 32),
                    ),
                    const SizedBox(width: 8),
                    Text('Timfoc', style: theme.textTheme.displaySmall?.copyWith(color: LofiTheme.secondary)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: LofiTheme.outline),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 32),

            // Header Section
            Text('PREFERENCES', style: theme.textTheme.labelMedium?.copyWith(color: LofiTheme.primary)),
            const SizedBox(height: 8),
            Text('Your Sanctum.', style: theme.textTheme.displayLarge?.copyWith(fontSize: 40, height: 1.1)),
            const SizedBox(height: 32),

            // Profile Section removed per request

            // Focus Duration Slider Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: LofiTheme.surfaceLow,
                borderRadius: BorderRadius.circular(24), 
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: LofiTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.schedule, color: LofiTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text('Focus Duration', style: theme.textTheme.titleMedium?.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Work Session Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Work Session', style: theme.textTheme.bodyMedium?.copyWith(color: LofiTheme.onSurfaceVariant)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${timerProvider.workDuration ~/ 60}', style: theme.textTheme.displaySmall?.copyWith(fontSize: 28, color: LofiTheme.secondary)),
                          const SizedBox(width: 4),
                          Text('MIN', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: LofiTheme.secondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: (timerProvider.workDuration ~/ 60).toDouble(),
                      min: 1,
                      max: 120,
                      activeColor: LofiTheme.secondary,
                      inactiveColor: LofiTheme.surfaceHighest,
                      onChanged: (val) {
                        timerProvider.setWorkDuration(val.toInt());
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Short Break Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Short Break', style: theme.textTheme.bodyMedium?.copyWith(color: LofiTheme.onSurfaceVariant)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${timerProvider.breakDuration ~/ 60}', style: theme.textTheme.displaySmall?.copyWith(fontSize: 28, color: LofiTheme.secondary)),
                          const SizedBox(width: 4),
                          Text('MIN', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: LofiTheme.secondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: (timerProvider.breakDuration ~/ 60).toDouble(),
                      min: 1,
                      max: 60,
                      activeColor: LofiTheme.secondary,
                      inactiveColor: LofiTheme.surfaceHighest,
                      onChanged: (val) {
                        timerProvider.setBreakDuration(val.toInt());
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Timer Settings
            _buildSectionHeader('TIMER & WORKFLOW', Icons.timer),
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildToggleRow(
                'Auto-start Breaks',
                'Start break timer automatically after focus ends',
                timerProvider.autoStartBreaks,
                (val) => timerProvider.toggleAutoStartBreaks(),
              ),
              const Divider(color: LofiTheme.surfaceHighest, height: 1),
              _buildToggleRow('Sync Data', 'Keep your history safe across devices', timerProvider.syncData, (val) => timerProvider.toggleSyncData()),
            ]),
            const SizedBox(height: 32),

            // Environment
            _buildSectionHeader('FEEDBACK & ALERTS', Icons.notifications),
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildToggleRow(
                'Sound Effects',
                'Play alert beep when timer finishes',
                timerProvider.soundEffects,
                (val) => timerProvider.toggleSoundEffects(),
              ),
              const Divider(color: LofiTheme.surfaceHighest, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vibration', style: theme.textTheme.titleMedium?.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Haptic feedback on completion', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: LofiTheme.secondary.withOpacity(0.1),
                        border: Border.all(color: LofiTheme.secondary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Always On', style: theme.textTheme.labelSmall?.copyWith(color: LofiTheme.secondary)),
                    ),
                  ],
                ),
              ),
              const Divider(color: LofiTheme.surfaceHighest, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lo-Fi Aesthetic', style: theme.textTheme.titleMedium?.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Dark mode, warm accents', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: LofiTheme.secondary.withOpacity(0.1),
                        border: Border.all(color: LofiTheme.secondary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Active', style: theme.textTheme.labelSmall?.copyWith(color: LofiTheme.secondary)),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 32),

            // Danger Zone
            _buildSectionHeader('DANGER ZONE', Icons.warning),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: LofiTheme.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LofiTheme.error.withOpacity(0.2)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text('Clear All Data', style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, color: LofiTheme.error)),
                subtitle: Text('Irreversibly delete history, badges, and settings', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: LofiTheme.error.withOpacity(0.7))),
                trailing: const Icon(Icons.delete_forever, color: LofiTheme.error),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: LofiTheme.surfaceHigh,
                      title: Text('Clear All Data?', style: theme.textTheme.displaySmall),
                      content: Text('This will irreversibly delete all history, badges, and settings.', style: theme.textTheme.bodyMedium),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: theme.textTheme.labelMedium),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: LofiTheme.error),
                          child: const Text('Delete', style: TextStyle(color: LofiTheme.surfaceLow, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await timerProvider.clearAllData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All data cleared successfully.', style: TextStyle(color: LofiTheme.surfaceLow)), backgroundColor: LofiTheme.secondary),
                      );
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 120), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: LofiTheme.outline),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LofiTheme.outline)),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: LofiTheme.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LofiTheme.secondary,
            activeTrackColor: LofiTheme.secondary.withOpacity(0.3),
            inactiveThumbColor: LofiTheme.outline,
            inactiveTrackColor: LofiTheme.surfaceHighest,
          ),
        ],
      ),
    );
  }
}
