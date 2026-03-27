# Goal Description
The goal is to fix visual overflow errors, incorrectly escaped string interpolations displaying as raw text, and a rendering glitch causing a massive yellow circle on the Focus screen.

## Proposed Changes
### /home/pavana/Timfoc/lib/screens/stats_screen.dart
#### [MODIFY] stats_screen.dart
* Remove `Expanded` wrapper on the 'Current Streak' container in the header, letting it size inherently, preventing the flex row overflow.
* Change the string `'\${index + 12}'` to `'${index + 12}'` inside the Daily Consistency grid to properly evaluate the dart variable.

### /home/pavana/Timfoc/lib/screens/home_screen.dart
#### [MODIFY] home_screen.dart
* Change the Glow container inside the 'Focus Totem' from using a massive `BoxShadow` (which can cause Skia/Impeller renderer glitches resulting in a solid circle) to a `RadialGradient` for a safe, smooth glow.
* Fix the string interpolation in the Bento stat card from `'\${statsProvider.todayProgress.totalFocusMinutes} m'` to `'${statsProvider.todayProgress.totalFocusMinutes} m'`.

## Verification Plan
### Automated Tests
Run `flutter test` if any widget tests exist for string interpolation display.
### Manual Verification
Ask the user to hot reload or restart the application (`flutter run`) and navigate to the Focus and Stats screen to visually confirm:
1. No massive yellow circle blocks the Focus UI.
2. The bottom right bento box shows the actual duration (e.g., '0 m') instead of '$\\{...\\}'.
3. The Stats screen header no longer shows yellow overflow tape.
4. The daily consistency grid shows correct numbers (e.g., 12, 13, 14...) instead of '$\\{index + 12\\}'.
