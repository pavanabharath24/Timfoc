import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/daily_progress.dart';
import '../models/pomodoro_session.dart';
import '../models/timfoc_badge.dart';
import '../services/storage_service.dart';

class StatsProvider with ChangeNotifier {
  late DailyProgress _todayProgress;
  List<TimfocBadge> _badges = [];

  StatsProvider() {
    _loadData();
  }

  DailyProgress get todayProgress => _todayProgress;
  List<TimfocBadge> get badges => _badges;

  int get currentStreak {
    int streak = 0;
    DateTime date = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    while (true) {
      final p = StorageService.getProgressForDate(date);
      if (p != null && (p.completedSessions > 0 || p.totalFocusMinutes > 0)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else if (date.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays == 0) {
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int get totalFocusMinutes {
    int total = 0;
    for (var p in StorageService.getAllProgress()) {
      total += p.totalFocusMinutes;
    }
    return total;
  }

  int get totalSessions {
    int total = 0;
    for (var p in StorageService.getAllProgress()) {
      total += p.completedSessions;
    }
    return total;
  }

  String get deepFocusTotalHours {
    return '${(totalFocusMinutes / 60).floor()}h';
  }

  String get avgSessionDuration {
    if (totalSessions == 0) return '0m';
    return '${(totalFocusMinutes / totalSessions).round()}m';
  }

  List<double> get weeklyMomentum {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday;
    final monday = now.subtract(Duration(days: currentDayOfWeek - 1));
    final List<double> momentum = List.filled(7, 0.0);
    const double goalTarget = 120.0; 

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final p = StorageService.getProgressForDate(day);
      if (p != null) {
        double val = p.totalFocusMinutes / goalTarget;
        momentum[i] = min(1.0, val);
      }
    }
    return momentum;
  }

  List<int> get last14DaysFocusMinutes {
    final now = DateTime.now();
    final List<int> minutes = List.filled(14, 0);
    for (int i = 0; i < 14; i++) {
        final day = now.subtract(Duration(days: 13 - i));
        final p = StorageService.getProgressForDate(day);
        minutes[i] = p?.totalFocusMinutes ?? 0;
    }
    return minutes;
  }

  void _loadData() {
    final now = DateTime.now();
    _todayProgress = StorageService.getProgressForDate(now) ??
        DailyProgress(date: DateTime(now.year, now.month, now.day));
    
    _badges = StorageService.getAllBadges();
    if (_badges.isEmpty) {
      _initDefaultBadges();
    }
    notifyListeners();
  }

  void refresh() {
    _loadData();
  }

  void _initDefaultBadges() {
    final initialBadges = [
      TimfocBadge(id: 'badge_1', name: 'First Focus', description: 'Completed first pomodoro', iconAsset: 'first.png'),
      TimfocBadge(id: 'badge_2', name: 'Focus Master', description: 'Completed 10 pomodoros', iconAsset: 'master.png'),
    ];
    for (var b in initialBadges) {
      StorageService.saveBadge(b);
    }
    _badges = initialBadges;
  }

  Future<void> addSession(PomodoroSession session) async {
    await StorageService.saveSession(session);
    
    if (session.isWorkSession) {
      _todayProgress.totalFocusMinutes += session.durationMinutes;
      _todayProgress.completedSessions += 1;
      await StorageService.saveProgress(_todayProgress);
      _checkBadges();
      notifyListeners();
    }
  }

  void _checkBadges() {
    // Simple gamification logic
    final totalSessions = StorageService.getAllSessions().where((s) => s.isWorkSession).length;
    
    for (int i = 0; i < _badges.length; i++) {
      if (!_badges[i].isUnlocked) {
        bool unlock = false;
        if (_badges[i].id == 'badge_1' && totalSessions >= 1) unlock = true;
        if (_badges[i].id == 'badge_2' && totalSessions >= 10) unlock = true;
        
        if (unlock) {
          _badges[i] = _badges[i].copyWith(unlockedAt: DateTime.now());
          StorageService.saveBadge(_badges[i]);
          // Could trigger a UI effect or notification here
        }
      }
    }
  }
}
