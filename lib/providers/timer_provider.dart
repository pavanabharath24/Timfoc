import 'dart:async';
import 'dart:io';
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
  
  bool isContinuousMode = false;
  int totalStudyMinutes = 0;
  int accumulatedStudyMinutes = 0;

  TimerProvider() {
    _loadSettings();
    _initForegroundTask();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'timfoc_fg_service_v5',
        channelName: 'Timfoc Background Service',
        channelDescription: 'Keeps timer running in the background',
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

  void toggleContinuousMode(bool value, [int targetMinutes = 0]) {
    isContinuousMode = value;
    totalStudyMinutes = targetMinutes;
    accumulatedStudyMinutes = 0;
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

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _requestPermissions() async {
    // Notification permission (Android 13+)
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

    // 3. Start background service for background execution only
    await _requestPermissions();

    final sessionLabel = isWorkSession ? 'Focus' : 'Break';
    final blockedApps = StorageService.settingsBox.get('blockedApps', defaultValue: <String>[])?.cast<String>() ?? [];
    await FlutterForegroundTask.saveData(key: 'remainingSeconds', value: _remainingSeconds);
    await FlutterForegroundTask.saveData(key: 'sessionLabel', value: sessionLabel);
    await FlutterForegroundTask.saveData(key: 'blockedApps', value: blockedApps.join(','));

    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask('resume'); 
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Timfoc — $sessionLabel',
        notificationText: 'Timer running',
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

  /// Triggers vibration and alarm sound when session finishes
  Future<void> _playCompletionFeedback() async {
    // Strong vibration pattern
    try {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.heavyImpact();
    } catch (_) {}

    // Custom beep sound is handled via the flutter_local_notifications plugin
    // during the `showCompletionNotification` step.
  }

  void _finishTimer() {
    _timer?.cancel();
    _state = TimerState.finished;

    // Play vibration and beep
    _playCompletionFeedback();

    String notifyTitle = isWorkSession ? 'Focus Complete! 🎉' : 'Break Over! 💪';
    String notifyBody = isWorkSession ? 'Time for a ${breakDuration ~/ 60} minute break.' : 'Back to work!';
    
    // Show high-priority completion notification
    NotificationService.showCompletionNotification(
      title: notifyTitle, 
      body: notifyBody,
      playSound: soundEffects,
    );

    // Stop the foreground service
    FlutterForegroundTask.stopService();

    if (isWorkSession) {
      accumulatedStudyMinutes += (workDuration ~/ 60);
    }

    notifyListeners();

    if (isContinuousMode) {
      if (isWorkSession) {
        if (accumulatedStudyMinutes >= totalStudyMinutes) {
          // Reached target
          toggleContinuousMode(false);
        } else {
          _autoTransitionToBreak();
        }
      } else {
        // Just finished break, transition to work if not done
        if (accumulatedStudyMinutes < totalStudyMinutes) {
          _autoTransitionToWork();
        } else {
          toggleContinuousMode(false);
        }
      }
    } else {
      // Auto-start break if enabled and just finished work
      if (autoStartBreaks && isWorkSession) {
        _autoTransitionToBreak();
      }
    }
  }

  Future<void> _autoTransitionToWork() async {
    await Future.delayed(const Duration(seconds: 2));
    
    _sessionType = SessionType.work;
    _remainingSeconds = workDuration;
    _state = TimerState.initial;
    notifyListeners();

    await startTimer();
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
