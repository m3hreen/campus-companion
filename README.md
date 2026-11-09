# Campus Companion - Part 2 working build

## Run and check

From the repository root:

```bash
cd code
flutter pub get
flutter analyze
flutter test
flutter run
```

Choose an Android emulator or Android phone for grading and the demo. Chrome is useful during development. No login or API keys are required by this build. Dart constraint: ^3.13.3. No packages were added in this update.

## This update

- Welcome screen with Begin leading to the existing home dashboard.
- Shared feedback helper queues snackbars; timer completion no longer dismisses deletion Undo.
- Completing or uncompleting an assignment offers Undo. Revision checks prevent an older queued Undo reversing a newer completion change.
- Countdown and Stopwatch modes with pause/resume, reset confirmation and saved elapsed study time. Save or reset before changing mode/course.
- Seven-day vertical bar chart with minutes scale, exact-value tooltips and screen-reader labels.
- Consistent rounded inputs, buttons and cards, retaining the teal palette and dark mode.
- Replaced the obsolete counter test with welcome, feedback conflict and timer-mode regression tests.

## Organization

lib/app.dart owns theme and welcome state. screens/main_screen.dart owns shared courses, assignments, saved sessions and goals. Other screens receive data and callbacks. models contains simple data classes; dialogs contains validated input; widgets contains reusable visual components; utils/app_feedback.dart centralizes queued snackbars. Existing Home, Academics, Study, Insights, drawer and settings features are retained.

## Verification status

Local import and delimiter checks were performed in the editing environment. Flutter/Dart are not installed there, so flutter analyze, flutter test, Android build and visual verification have NOT been executed. Run the commands above on your development machine and resolve any failures before submission.

## Manual regression checks

1. Begin opens Home; drawer and bottom navigation agree; theme switches stay synchronized.
2. Submit empty course and assignment forms. Add a course and assignment; edit and cancel editing; check date/time pickers.
3. Complete an assignment on Home, press Undo, and verify it reappears. Repeat in Academics. Completed tasks remain accessible with Show completed assignments.
4. Start a one-minute countdown. Shortly before completion, delete an assignment in Academics. When the timer ends, verify Undo stays visible and restores it. The timer message queues behind existing feedback.
5. Switch to Stopwatch, choose a course, start, pause, resume and save. Verify session seconds, Home goal and Insights. Attempt to save twice; no duplicate should be added.
6. Cancel a timer reset; then confirm reset. Switch back to Countdown after saving/resetting.
7. Check the seven-day chart with no sessions and with short saved sessions, in light/dark mode and on a narrow Android emulator.

## Known limitations and remaining work

Data, goals and settings remain in memory and reset on restart. No device notifications, cloud/local persistence, weather HTTP integration or login. Timer completion is in-app feedback; suspended apps may show it only on resuming. Course rename/delete is not implemented. Campus Map is still a placeholder. These remain separate group tasks. Sessions are attributed to their completion date. Snackbars are queued and can appear later if several actions occur quickly.

## Part 2 submission still required

This is a working code package, not the completed Canvas submission. Add a progress report PDF covering completed/remaining work (owners/dates), changes, known issues and actual member contributions. Record the exact version on Android as an MP4 of at most 2 minutes, with captions. Include README.md, report/, video/ and code/ in GroupXX_CampusCompanion_Part2.zip. Run flutter clean before packaging; exclude build and .dart_tool. Verify by unzipping and building on another machine.

## AI acknowledgement

We used ChatGPT to help organize and clean up our Flutter code, improve indentation, and add comments. It also helped us connect files and screens, set up navigation, and understand how data and user actions flow between pages. We used our class examples and lab exercises as references for the Flutter patterns in the app, including forms, dialogs, navigation, and screen layouts.