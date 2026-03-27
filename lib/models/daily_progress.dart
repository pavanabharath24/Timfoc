import 'package:hive/hive.dart';

part 'daily_progress.g.dart';

@HiveType(typeId: 1)
class DailyProgress extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  int totalFocusMinutes;

  @HiveField(2)
  int completedSessions;

  DailyProgress({
    required this.date,
    this.totalFocusMinutes = 0,
    this.completedSessions = 0,
  });
}
