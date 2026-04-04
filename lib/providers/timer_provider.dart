import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
        channelId: 'timfoc_timer_channel_v4',
        channelName: 'Timfoc Timer',
        channelDescription: 'Shows live timer countdown',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
        playSound: false,
        enableVibration: false,
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
    // 1. Update UI instantly
    _state = TimerState.running;
    notifyListeners();
    
    // 2. Start local UI timer for smooth updates
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _finishTimer();
      }
    });

    // 3. Start background service for notification + background execution
    await _requestPermissions();

    final sessionLabel = isWorkSession ? 'Focus' : 'Break';
    await FlutterForegroundTask.saveData(key: 'remainingSeconds', value: _remainingSeconds);
    await FlutterForegroundTask.saveData(key: 'sessionLabel', value: sessionLabel);

    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask('resume'); 
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Timfoc — $sessionLabel',
        notificationText: 'Starting...',
        callback: startCallback,
      );
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
    FlutterForegroundTask.sendDataToTask('pause');
  }

  void stopTimer() {
    _timer?.cancel();
    _state = TimerState.initial;
    _remainingSeconds = _sessionType == SessionType.work ? workDuration : breakDuration;
    notifyListeners();
    FlutterForegroundTask.stopService();
  }

  /// Triggers vibration and beep when session finishes
  Future<void> _playCompletionFeedback() async {
    // Strong vibration using platform channel
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 250));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 250));
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    // System alert sound
    if (soundEffects) {
      try {
        await SystemSound.play(SystemSoundType.alert);
        await Future.delayed(const Duration(milliseconds: 400));
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  void _finishTimer() {
    _timer?.cancel();
    _state = TimerState.finished;
    
    // Play vibration and beep
    _playCompletionFeedback();

    String notifyTitle = isWorkSession ? 'Focus Complete! 🎉' : 'Break Over! 💪';
    String notifyBody = isWorkSession ? 'Time for a ${breakDuration ~/ 60} minute break.' : 'Back to work!';
    
    NotificationService.showNotification(
      id: 0, 
      title: notifyTitle, 
      body: notifyBody,
    );

    // Stop the foreground service
    FlutterForegroundTask.stopService();

    notifyListeners();

    // Auto-start break if enabled and just finished work
    if (autoStartBreaks && isWorkSession) {
      _autoTransitionToBreak();
    }
  }

  Future<void> _autoTransitionToBreak() async {
    await Future.delayed(const Duration(seconds: 2));
    
    _sessionType = SessionType.shortBreak;
    _remainingSeconds = breakDuration;
    _state = TimerState.initial;
    notifyListeners();

    await startTimer();
  }

  void toggleSessionType() {
    _sessionType = _sessionType == SessionType.work ? SessionType.shortBreak : SessionType.work;
    stopTimer();
  }

  void updateOnResume(DateTime now) {}

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
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    super.dispose();
  }
}
