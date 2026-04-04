# App Locker & Continue Study Implementation Plan

This document outlines the approach for developing two major new features for the Timfoc app:
1. **App Locker**: Automatically locks user-selected distracting apps during Focus sessions, and unlocks them during Breaks.
2. **Continuous Study Mode**: Allows the user to set a total desired study duration (e.g., 90 mins) and automates the Focus ↔ Break cycle until the total target is met.

> [!NOTE]
> The App Locker functionality is heavily reliant on Android's `UsageStatsManager`. Due to iOS restrictions, this feature will be **Android-only**.

## Proposed Changes

### 1. App Locker Architecture
We will use the `usage_stats` package to read the foreground package name, and the `installed_apps` (or `device_apps`) package to allow the user to select which apps to block.

**Dependencies:**
- Add `usage_stats` and `installed_apps` to `pubspec.yaml`
- Add `android.permission.PACKAGE_USAGE_STATS` to `AndroidManifest.xml`

**User Interface:**
- Create an `AppLockerScreen` (accessible from Settings) that lists all installed user apps.
- Users can check/uncheck apps to add them to a "Blacklist".
- Store the blacklisted package names locally via Hive storage.

**Background Logic (`ForegroundTimerHandler`):**
- During the `onRepeatEvent` (which fires every 1 second), if the session is **Focus**, we query the `usage_stats` to get the current foreground app's package name.
- If the detected active package name is in the user's blacklist, we will immediately use `FlutterForegroundTask.launchApp()` to bring the Timfoc app back to the foreground, effectively preventing the user from using the distracting app.
- During the **Break** session, this check is bypassed, meaning the user can use the blacklisted apps freely.

### 2. Continue Study Mode (Multi-session looping)
We will introduce a `Continuous Mode` setting where the user defines a total study goal.

**Logic in `TimerProvider`:**
- Add variables for `totalDesiredStudyTime` and `accumulatedStudyTime`.
- Update `_finishTimer()` and `_autoTransitionToBreak()` routines:
  - If `Continuous Mode` is active, when a Focus session ends, automatically start a Break.
  - When the Break ends, automatically start the next Focus session.
  - Continue this loop until `accumulatedStudyTime >= totalDesiredStudyTime`.
  - At the end of the total study time, stop the timer completely.

---

## User Review Required

> [!WARNING]
> **Android Permissions:** The App Locker requires "Usage Access" permission on Android. The user *must* manually grant this in Android Settings. We will show a dialog prompting them to do so if not granted. Are you okay with adding a prompt in the app to ask for this permission from users?

> [!IMPORTANT]
> **Blocking Mechanism:** iOS does not allow an app to query foreground packages or automatically bring itself to the front. The App Locker will only function on Android devices. Please confirm if this is acceptable.

## Verification Plan

### Automated/Manual Testing
1. **App Selection:** Go to App Locker settings, list installed apps, and select a test app (e.g., YouTube or Instagram).
2. **Focus Phase Testing:** Start the Focus timer. Try returning to the homescreen and opening the test app. Verify Timfoc immediately jumps back to the foreground and blocks access.
3. **Break Phase Testing:** Wait for the Focus timer to end and Break timer to begin. Open the test app again. Verify it opens normally and is *not* blocked.
4. **Continuous Study Testing:** Set a 2-minute focus session and 1-minute break session, with a 4-minute total study goal. Validate that the app correctly loops `Focus -> Break -> Focus -> Stop`.
