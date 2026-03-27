import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import '../models/pomodoro_session.dart';
import '../models/daily_progress.dart';
import '../models/timfoc_badge.dart';

class StorageService {
  static const String sessionBoxName = 'sessions';
  static const String progressBoxName = 'progress';
  static const String badgeBoxName = 'badges';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(PomodoroSessionAdapter());
    Hive.registerAdapter(DailyProgressAdapter());
    Hive.registerAdapter(TimfocBadgeAdapter());

    // Open Boxes
    await Hive.openBox<PomodoroSession>(sessionBoxName);
    await Hive.openBox<DailyProgress>(progressBoxName);
    await Hive.openBox<TimfocBadge>(badgeBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box get settingsBox => Hive.box(settingsBoxName);

  static Future<void> clearAllData() async {
    await sessionBox.clear();
    await progressBox.clear();
    await badgeBox.clear();
    await settingsBox.clear();
  }

  // Session Methods
  static Box<PomodoroSession> get sessionBox => Hive.box<PomodoroSession>(sessionBoxName);

  static Future<void> saveSession(PomodoroSession session) async {
    await sessionBox.add(session);
  }

  static List<PomodoroSession> getAllSessions() {
    return sessionBox.values.toList();
  }

  // Progress Methods
  static Box<DailyProgress> get progressBox => Hive.box<DailyProgress>(progressBoxName);

  static Future<void> saveProgress(DailyProgress progress) async {
    // We use the date string as the key to easily retrieve today's progress
    final key = '${progress.date.year}-${progress.date.month}-${progress.date.day}';
    await progressBox.put(key, progress);
  }

  static DailyProgress? getProgressForDate(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';
    return progressBox.get(key);
  }

  static List<DailyProgress> getAllProgress() {
    return progressBox.values.toList();
  }

  static Future<void> addSessionProgress(int minutes) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var p = getProgressForDate(today) ?? DailyProgress(date: today);
    p.completedSessions += 1;
    p.totalFocusMinutes += minutes;
    await saveProgress(p);
  }

  // Badge Methods
  static Box<TimfocBadge> get badgeBox => Hive.box<TimfocBadge>(badgeBoxName);

  static Future<void> saveBadge(TimfocBadge badge) async {
    await badgeBox.put(badge.id, badge);
  }

  static List<TimfocBadge> getAllBadges() {
    return badgeBox.values.toList();
  }
}
