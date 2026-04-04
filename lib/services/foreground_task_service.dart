import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTimerHandler());
}

class ForegroundTimerHandler extends TaskHandler {
  int _remainingSeconds = 0;
  bool _isPaused = false;
  
  // Custom action buttons
  static const String actionPause = 'pause';
  static const String actionResume = 'resume';
  static const String actionStop = 'stop';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final customData = await FlutterForegroundTask.getData<int>(key: 'remainingSeconds');
    _remainingSeconds = customData ?? 0;
    _isPaused = false;
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
      'status': 'paused'
    });
    _updateNotification();
  }

  void _finishTimer() {
    _isPaused = true;
    FlutterForegroundTask.sendDataToMain({
      'remainingSeconds': 0,
      'status': 'finished'
    });
    FlutterForegroundTask.updateService(
      notificationTitle: 'Focus Complete!',
      notificationText: 'Time is up.',
      notificationButtons: [],
    );
  }

  void _updateNotification() {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final timeString = '$minutes:$seconds';

    FlutterForegroundTask.updateService(
      notificationTitle: 'Timfoc Active',
      notificationText: _isPaused ? 'Paused ($timeString)' : 'Focusing: $timeString',
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
        'status': 'running'
      });
      
      // Update notification
      _updateNotification();
    } else if (_remainingSeconds == 0) {
      _remainingSeconds--; // Prevent multiple calls
      _finishTimer();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
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
