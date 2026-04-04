import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/foreground_task_service.dart';

enum TimerState { initial, running, paused, finished }
enum SessionType { work, shortBreak }

class TimerProvider with ChangeNotifier {
  TimerState _state = TimerState.initial;
  SessionType _sessionType = SessionType.work;
  
  int workDuration = 25 * 60;
  int breakDuration = 5 * 60;
  
  late int _remainingSeconds = workDuration;
  Timer? _timer;

  bool autoStartBreaks = false;
  bool syncData = false;
  bool soundEffects = true;

  TimerProvider() {
    _loadSettings();
    _initForegroundTask();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'timfoc_foreground_channel',
        channelName: 'Timfoc Active Timer',
        channelDescription: 'Maintains the timer in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    // Listen to data from background task
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  }

  void _onForegroundTaskData(Object data) {
    if (data is Map) {
      if (data.containsKey('remainingSeconds')) {
        _remainingSeconds = data['remainingSeconds'];
      }
      
      final status = data['status'];
      if (status == 'running') {
        _state = TimerState.running;
      } else if (status == 'paused') {
        _state = TimerState.paused;
      } else if (status == 'finished') {
        // Log the session if it was a work session
        if (_sessionType == SessionType.work) {
          StorageService.addSessionProgress(workDuration ~/ 60);
        }
        _finishTimer();
      } else if (status == 'stopped') {
        _state = TimerState.initial;
        _remainingSeconds = _sessionType == SessionType.work ? workDuration : breakDuration;
      }
      notifyListeners();
    }
  }

  void _loadSettings() {
    autoStartBreaks = StorageService.settingsBox.get('autoStartBreaks', defaultValue: false);
    syncData = StorageService.settingsBox.get('syncData', defaultValue: false);
    soundEffects = StorageService.settingsBox.get('soundEffects', defaultValue: true);
  }

  void toggleAutoStartBreaks() {
    autoStartBreaks = !autoStartBreaks;
    StorageService.settingsBox.put('autoStartBreaks', autoStartBreaks);
    notifyListeners();
  }

  void toggleSyncData() {
    syncData = !syncData;
    StorageService.settingsBox.put('syncData', syncData);
    notifyListeners();
  }

  void toggleSoundEffects() {
    soundEffects = !soundEffects;
    StorageService.settingsBox.put('soundEffects', soundEffects);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await StorageService.clearAllData();
    workDuration = 25 * 60;
    breakDuration = 5 * 60;
    autoStartBreaks = false;
    syncData = false;
    soundEffects = true;
    _loadSettings();
    stopTimer();
    notifyListeners();
  }

  TimerState get state => _state;
  SessionType get sessionType => _sessionType;
  int get remainingSeconds => _remainingSeconds;
  
  bool get isWorkSession => _sessionType == SessionType.work;

  Future<void> _requestPermissions() async {
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<void> startTimer() async {
    await _requestPermissions();
    // Save duration so the background task can read it
    await FlutterForegroundTask.saveData(key: 'remainingSeconds', value: _remainingSeconds);

    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask('resume'); 
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Timfoc Active',
        notificationText: 'Timer is starting...',
        callback: startCallback,
      );
    }
    
    _state = TimerState.running;
    notifyListeners();
  }

  void pauseTimer() {
    FlutterForegroundTask.sendDataToTask('pause');
    _state = TimerState.paused;
    notifyListeners();
  }

  void stopTimer() {
    FlutterForegroundTask.stopService();
    _state = TimerState.initial;
    _remainingSeconds = _sessionType == SessionType.work ? workDuration : breakDuration;
    notifyListeners();
  }

  void _finishTimer() {
    _timer?.cancel();
    _state = TimerState.finished;
    
    String notifyTitle = isWorkSession ? 'Focus Complete!' : 'Break Over!';
    String notifyBody = isWorkSession ? 'Time for a 5 minute break.' : 'Back to work!';
    
    NotificationService.showNotification(
      id: 0, 
      title: notifyTitle, 
      body: notifyBody
    );
    notifyListeners();
  }

  void toggleSessionType() {
    _sessionType = _sessionType == SessionType.work ? SessionType.shortBreak : SessionType.work;
    stopTimer();
  }

  // Session management is now handled by background task state
  void updateOnResume(DateTime now) {
    // This is mostly redundant now but kept for legacy UI sync if needed
  }

  void setWorkDuration(int minutes) {
    workDuration = minutes * 60;
    if (_state == TimerState.initial && _sessionType == SessionType.work) {
      _remainingSeconds = workDuration;
      notifyListeners();
    }
  }

  void setBreakDuration(int minutes) {
    breakDuration = minutes * 60;
    if (_state == TimerState.initial && _sessionType == SessionType.shortBreak) {
      _remainingSeconds = breakDuration;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
