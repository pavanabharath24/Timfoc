import 'package:flutter/services.dart';

/// Native wrapper for Android UsageStatsManager.
/// Replaces the broken `usage_stats` pub package.
class UsageStatsService {
  static const _channel = MethodChannel('com.timfoc.timfoc/usage_stats');

  /// Returns true if Usage Access permission is granted.
  static Future<bool> checkUsagePermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkUsagePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android Settings → Usage Access for the user to grant permission.
  static Future<void> grantUsagePermission() async {
    try {
      await _channel.invokeMethod('grantUsagePermission');
    } catch (_) {
      // Silently fail if not available
    }
  }

  /// Returns the package name of the currently foreground app, or null.
  static Future<String?> getForegroundApp() async {
    try {
      return await _channel.invokeMethod<String>('getForegroundApp');
    } catch (_) {
      return null;
    }
  }
}
