import 'package:hive/hive.dart';

part 'pomodoro_session.g.dart';

@HiveType(typeId: 0)
class PomodoroSession extends HiveObject {
  @HiveField(0)
  final DateTime startTime;

  @HiveField(1)
  final DateTime endTime;

  @HiveField(2)
  final int durationMinutes;

  @HiveField(3)
  final bool isWorkSession; // true for focus, false for break

  PomodoroSession({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.isWorkSession = true,
  });
}
