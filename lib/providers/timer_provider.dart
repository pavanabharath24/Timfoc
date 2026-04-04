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
        channelId: 'timfoc_timer_channel_v3',
        channelName: 'Timfoc Active Timer',
        channelDescription: 'Shows live countdown while focusing',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
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
    // 1. Update UI instantly
    _state = TimerState.running;
    notifyListeners();
    
    // 2. Start local UI timer for butter-smooth updates while app is open
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _finishTimer();
      }
    });

    // 3. Coordinate with background service
    await _requestPermissions();

    // Save state for the background task
    final sessionLabel = isWorkSession ? 'Focus' : 'Break';
    await FlutterForegroundTask.saveData(key: 'remainingSeconds', value: _remainingSeconds);
    await FlutterForegroundTask.saveData(key: 'sessionLabel', value: sessionLabel);

    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask('resume'); 
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Timfoc — $sessionLabel',
        notificationText: 'Timer is starting...',
        notificationButtons: [
          const NotificationButton(id: 'pause', text: 'Pause'),
          const NotificationButton(id: 'stop', text: 'Stop'),
        ],
        callback: startCallback,
      );
    }
  }

  void pauseTimer() {
    // 1. Instantly update UI
    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
    
    // 2. Tell background to pause
    FlutterForegroundTask.sendDataToTask('pause');
  }

  void stopTimer() {
    // 1. Instantly update UI
    _timer?.cancel();
    _state = TimerState.initial;
    _remainingSeconds = _sessionType == SessionType.work ? workDuration : breakDuration;
    notifyListeners();
    
    // 2. Tell background to stop
    FlutterForegroundTask.stopService();
  }

  /// Triggers vibration and/or beep when session finishes
  Future<void> _playCompletionFeedback() async {
    // Haptic feedback using Flutter's built-in services
    try {
      // Heavy vibration pattern
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    // System beep sound
    if (soundEffects) {
      try {
        await SystemSound.play(SystemSoundType.alert);
        // Play it twice for emphasis
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

    // Stop the foreground service notification
    FlutterForegroundTask.stopService();

    notifyListeners();

    // Auto-start break if setting is enabled and we just finished a work session
    if (autoStartBreaks && isWorkSession) {
      _autoTransitionToBreak();
    }
  }

  /// Automatically switch to break session and start it
  Future<void> _autoTransitionToBreak() async {
    // Small delay so user sees the "finished" state briefly
    await Future.delayed(const Duration(seconds: 2));
    
    _sessionType = SessionType.shortBreak;
    _remainingSeconds = breakDuration;
    _state = TimerState.initial;
    notifyListeners();

    // Auto-start the break timer
    await startTimer();
  }

  void toggleSessionType() {
    _sessionType = _sessionType == SessionType.work ? SessionType.shortBreak : SessionType.work;
    stopTimer();
  }

  // Session management is now handled by background task state
  void updateOnResume(DateTime now) {
    // Redundant now but kept for legacy UI sync
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
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    super.dispose();
  }
}
