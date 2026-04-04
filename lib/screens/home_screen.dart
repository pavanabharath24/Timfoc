import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/timer_provider.dart';
import '../providers/stats_provider.dart';
import '../models/pomodoro_session.dart';
import '../theme/lofi_theme.dart';
import 'settings_screen.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TimerProvider>().updateOnResume(DateTime.now());
    }
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getAnimationAsset(TimerProvider provider) {
    if (provider.state == TimerState.initial) {
      return 'assets/animations/morty_dance_loader.json';
    } else if (provider.state == TimerState.running || provider.state == TimerState.paused) {
      if (provider.isWorkSession) {
        return 'assets/animations/student.json';
      } else {
        return 'assets/animations/cafe.json';
      }
    }
    return 'assets/animations/morty_dance_loader.json';
  }

  void _onTimerFinished(TimerProvider timerProvider, StatsProvider statsProvider) async {
    final wasWorkSession = timerProvider.isWorkSession;
    final session = PomodoroSession(
      startTime: DateTime.now().subtract(
          Duration(seconds: wasWorkSession ? timerProvider.workDuration : timerProvider.breakDuration)),
      endTime: DateTime.now(),
      durationMinutes: (wasWorkSession ? timerProvider.workDuration : timerProvider.breakDuration) ~/ 60,
      isWorkSession: wasWorkSession,
    );
    await statsProvider.addSession(session);

    // Only show dialog if NOT auto-transitioning to break
    final willAutoStart = timerProvider.autoStartBreaks && wasWorkSession;

    if (mounted && !willAutoStart) {
      timerProvider.stopTimer();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: LofiTheme.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animations/successful_target.json', height: 200, repeat: false),
              const SizedBox(height: 16),
              Text(
                wasWorkSession ? 'Focus Session Complete!' : 'Break Complete!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: LofiTheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Awesome!', style: TextStyle(color: LofiTheme.secondary, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
    // If auto-start break is ON, _finishTimer in the provider handles the transition
  }



  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final statsProvider = context.read<StatsProvider>();
    final theme = Theme.of(context);

    if (timerProvider.state == TimerState.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onTimerFinished(timerProvider, statsProvider);
      });
    }

    double totalSeconds = (timerProvider.isWorkSession ? timerProvider.workDuration : timerProvider.breakDuration).toDouble();
    double percent = 1.0 - (timerProvider.remainingSeconds / totalSeconds);
    if (percent < 0) percent = 0;
    if (percent > 1) percent = 1;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
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
                  icon: const Icon(Icons.settings, color: LofiTheme.outline),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                )
              ],
            ),
            const SizedBox(height: 32),

            // Focus Totem
            SizedBox(
              width: 320,
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.loose,
                children: [
                  // Outer subtle ring for aesthetic
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: LofiTheme.outline.withOpacity(0.05), width: 2),
                    ),
                  ),
                  // Progress Arc
                  CircularPercentIndicator(
                    radius: 140.0,
                    lineWidth: 12.0,
                    percent: percent,
                    circularStrokeCap: CircularStrokeCap.round,
                    backgroundColor: LofiTheme.surfaceHigh,
                    progressColor: LofiTheme.secondary,
                    animation: true,
                    animateFromLastPercent: true,
                    center: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background animation bounded neatly inner circle
                        ClipOval(
                          child: Opacity(
                            opacity: 0.8,
                            child: Lottie.asset(
                              _getAnimationAsset(timerProvider),
                              width: 250,
                              height: 250,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        // Timer logic
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (timerProvider.state == TimerState.initial)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: LofiTheme.outline),
                                    onPressed: () {
                                      if (timerProvider.isWorkSession) {
                                        timerProvider.setWorkDuration((timerProvider.workDuration~/60 - 1).clamp(1, 120));
                                      } else {
                                        timerProvider.setBreakDuration((timerProvider.breakDuration~/60 - 1).clamp(1, 60));
                                      }
                                    },
                                  )
                                else 
                                  const SizedBox(width: 48), // Padding equivalent
                                
                                Text(
                                  _formatTime(timerProvider.remainingSeconds),
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    fontSize: 56, 
                                    height: 1.0, 
                                    letterSpacing: -2,
                                    color: LofiTheme.onSurface,
                                  ),
                                ),
                                
                                if (timerProvider.state == TimerState.initial)
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: LofiTheme.outline),
                                    onPressed: () {
                                      if (timerProvider.isWorkSession) {
                                        timerProvider.setWorkDuration((timerProvider.workDuration~/60 + 1).clamp(1, 120));
                                      } else {
                                        timerProvider.setBreakDuration((timerProvider.breakDuration~/60 + 1).clamp(1, 60));
                                      }
                                    },
                                  )
                                else 
                                  const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: timerProvider.isWorkSession 
                                    ? LofiTheme.secondary.withOpacity(0.1) 
                                    : LofiTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                timerProvider.isWorkSession ? 'FOCUS' : 'BREAK',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: timerProvider.isWorkSession ? LofiTheme.secondary : LofiTheme.primary,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: Icons.skip_next,
                  onPressed: () => timerProvider.toggleSessionType(),
                  isPrimary: false,
                ),
                const SizedBox(width: 24),
                _ControlButton(
                  icon: timerProvider.state == TimerState.running ? Icons.pause : Icons.play_arrow,
                  onPressed: () {
                    if (timerProvider.state == TimerState.running) {
                      timerProvider.pauseTimer();
                    } else {
                      timerProvider.startTimer();
                    }
                  },
                  isPrimary: true,
                  size: 80,
                ),
                const SizedBox(width: 24),
                _ControlButton(
                  icon: Icons.refresh,
                  onPressed: () => timerProvider.stopTimer(),
                  isPrimary: false,
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Session Stats Grid (Bento)
            Row(
              children: [
                Expanded(
                  child: _BentoStat(
                    icon: Icons.local_fire_department,
                    iconColor: LofiTheme.secondary,
                    label: 'DAILY STREAK',
                    value: '${statsProvider.currentStreak} Days',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BentoStat(
                    icon: Icons.schedule,
                    iconColor: LofiTheme.primary,
                    label: 'FOCUS TIME',
                    value: '${statsProvider.todayProgress.totalFocusMinutes} m',
                  ),
                ),
              ],
            ),

            // Quote
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '"The secret of getting ahead is getting started."',
                      style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: LofiTheme.onSurfaceVariant),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, width: 48, color: LofiTheme.secondary.withOpacity(0.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), // padding for bottom nav
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary ? LofiTheme.secondary : Colors.transparent,
          border: isPrimary ? null : Border.all(color: LofiTheme.outline.withOpacity(0.2)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: LofiTheme.secondary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: isPrimary ? LofiTheme.background : LofiTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BentoStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _BentoStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LofiTheme.surfaceHigh.withOpacity(0.5),
        border: Border.all(color: LofiTheme.outline.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: LofiTheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.displaySmall?.copyWith(fontSize: 20)),
        ],
      ),
    );
  }
}
