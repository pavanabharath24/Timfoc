import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:usage_stats/usage_stats.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTimerHandler());
}

class ForegroundTimerHandler extends TaskHandler {
  int _remainingSeconds = 0;
  bool _isPaused = false;
  String _sessionLabel = 'Focus';
  List<String> _blockedApps = [];
  
  // Custom action button IDs
  static const String actionPause = 'pause';
  static const String actionResume = 'resume';
  static const String actionStop = 'stop';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final seconds = await FlutterForegroundTask.getData<int>(key: 'remainingSeconds');
    final label = await FlutterForegroundTask.getData<String>(key: 'sessionLabel');
    final blockedAppsStr = await FlutterForegroundTask.getData<String>(key: 'blockedApps');
    
    _remainingSeconds = seconds ?? 0;
    _sessionLabel = label ?? 'Focus';
    _isPaused = false;
    _blockedApps = (blockedAppsStr != null && blockedAppsStr.isNotEmpty) 
        ? blockedAppsStr.split(',') 
        : [];
    _updateNotification();
  }

  void _startTimer() {
    _isPaused = false;
    _updateNotification();
  }

  void _pauseTimer() {
    _isPaused = true;
    FlutterForegroundTask.sendDataToMain({
      'remainingSeconds': _remainingSeconds,
      'status': 'paused',
    });
    _updateNotification();
  }

  void _finishTimer() {
    _isPaused = true;
    FlutterForegroundTask.sendDataToMain({
      'remainingSeconds': 0,
      'status': 'finished',
    });
    FlutterForegroundTask.updateService(
      notificationTitle: '$_sessionLabel Complete!',
      notificationText: 'Session finished.',
      notificationButtons: [],
    );
  }

  void _updateNotification() {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final timeString = '$minutes:$seconds';

    final title = _isPaused
        ? 'Timfoc — $_sessionLabel Paused'
        : 'Timfoc — $_sessionLabel';

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: _isPaused ? '⏸ Paused at $timeString' : '⏱ $timeString remaining',
      notificationButtons: [
        if (!_isPaused)
          const NotificationButton(id: actionPause, text: 'Pause')
        else
          const NotificationButton(id: actionResume, text: 'Resume'),
        const NotificationButton(id: actionStop, text: 'Stop'),
      ],
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_isPaused) return;

    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      
      // Notify main isolate
      FlutterForegroundTask.sendDataToMain({
        'remainingSeconds': _remainingSeconds,
        'status': 'running',
      });
      
      // Check for blocked apps if in Focus mode
      if (_sessionLabel == 'Focus' && _blockedApps.isNotEmpty) {
        _checkForegroundApp();
      }
      
      // Update notification every second
      _updateNotification();
    } else if (_remainingSeconds == 0) {
      _remainingSeconds = -1; // Prevent multiple calls
      _finishTimer();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // cleanup
  }

  /// Queries UsageStats to find the currently active app.
  /// If it's in the blocked list, brings Timfoc back to the foreground.
  Future<void> _checkForegroundApp() async {
    try {
      final now = DateTime.now();
      // Query usage events from the last 5 seconds
      final events = await UsageStats.queryEvents(
        now.subtract(const Duration(seconds: 5)),
        now,
      );

      if (events == null || events.isEmpty) return;

      // Find the most recent MOVE_TO_FOREGROUND event (eventType == 1)
      String? lastForegroundPackage;
      for (final event in events) {
        if (event.eventType == '1') {
          lastForegroundPackage = event.packageName;
        }
      }

      if (lastForegroundPackage != null &&
          _blockedApps.contains(lastForegroundPackage)) {
        // Blocked app detected — bring Timfoc back to the foreground
        FlutterForegroundTask.launchApp();
      }
    } catch (_) {
      // Silently fail — permission might not be granted yet
    }
  }

  @override
  void onReceiveData(Object data) {
    if (data is String) {
      if (data == 'pause') {
        _pauseTimer();
      } else if (data == 'resume') {
        _startTimer();
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == actionPause) {
      _pauseTimer();
    } else if (id == actionResume) {
      _startTimer();
    } else if (id == actionStop) {
      FlutterForegroundTask.sendDataToMain({'status': 'stopped'});
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
