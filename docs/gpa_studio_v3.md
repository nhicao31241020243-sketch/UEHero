# GPA Journey V3 — Interactive Semester Studio

Design: https://www.figma.com/design/EfJ2FtL7VTtiCXcbVyX5WN?node-id=7-32

## Scope

A new preview entry point (`lib/gpa_studio_v3_preview.dart`) leaves the old Flutter,
Blender and Forge2D files untouched. No dependency or pubspec changes are required.
The existing GpaCalculator.projectedGpa calculation is reused.

The V3 main screen uses a raised GPA dial next to six extruded, draggable course
grade columns, followed by a target slider, fixed-order course controls, a grade
editor and two goal cards. It is a Flutter 2.5D rendering, not a real-time mesh
renderer. The existing Blender-rendered Physics Lab is a separate preserved
prototype; it is not silently presented as sharing this new controller.

## Synthetic demo

Base: 77 credits and 267.19 quality points (exact synthetic GPA 3.47).
Courses: AI 3, TI 5, MB 3, DB 3, QA 3, UX 3; 20 future credits total.
This is not a verified academic transcript. The provided F/D/D+/C/C+/B/B+/A-/A
conversion is a demo scale and is not asserted to be UEH's official scale.

Preset       AI   TI   MB   DB   QA   UX   Cumulative GPA (rounded)
Balanced     B+   B+   A    B    B+   A    3.49
Stretch      A    B+   A    B+   B+   A    3.52
All A        A    A    A    A    A    A    3.58
Blank        —    —    —    —    —    —    3.47 (partial only)

## Logic invariants

- A column's front height encodes one course grade on a fixed 0–4 axis.
  Equal width and decorative depth encode neither credits nor time.
- The dial encodes the credit-weighted cumulative GPA. One 5-credit course has
  more influence than a 3-credit course receiving the same grade change.
- A missing grade is excluded from the partial projection. F is a real assignment
  with all credits included and zero future quality points.
- Complete-term bounds hold assignments fixed and let only missing grades range
  from F through A. The all-A ceiling may replace every future assignment.
- Target means end of the listed future term, not graduation.
- Chart/slider drag updates an explicit preview. Release commits one undo action.
  Gesture cancel, leaving the chart's release bounds, or app interruption cancels
  the preview. Grade-button taps commit immediately.
- The shelf order never changes. Multiple courses may have the same grade.
- Target feasibility compares integer quality-point units, never rounded display
  strings. An all-A 3.579278... GPA does NOT reach target 3.58.
- The A-credit example uses a whole-course subset, assuming B+ in all other
  future courses. For target 3.50 the smallest feasible bundle is the 5-credit
  TI course, not a fictitious fractional 4.62-credit course.
- All session state lives in StudioController. Copy scenario exports committed
  values as JSON. There is no automatic disk/cloud persistence in this pass.

## Files

scenario.dart: immutable academic data, validation, bounds, integer comparisons.
controller.dart: selection, previews, commits, presets and undo.
visuals.dart: raised ring, dynamic 2.5D bars and tactile course controls.
screen.dart: responsive, vertically scrollable dashboard; full chart modal.
theme.dart: tokens matching the revised Figma design.

## Checks

dart analyze lib/features/gpa_studio_v3
dart analyze lib/gpa_studio_v3_preview.dart
flutter test test/gpa_studio_v3_test.dart test/gpa_studio_v3_widget_test.dart
flutter test test/gpa_calculator_test.dart
flutter run -t lib/gpa_studio_v3_preview.dart -d emulator-5554

This package was source-reviewed and its installer was checked in the authoring
sandbox with Dart/Flutter commands stubbed. Arithmetic was checked independently in Python. That sandbox has no Flutter SDK, so Flutter analysis, widget rendering
and Flutter tests have NOT been executed there. The installer runs those checks
on the user's development machine and stops rather than suppressing failures.

## Manual acceptance

1. Drag AI upward: column, preview dial and editor move together; release keeps A.
2. Tap Undo: AI and the weighted projection return to the original state.
3. Select TI and set F: verify the heavier credit impact. Clear it: it becomes
   unplanned, not F, and the partial/full-term range explanation appears.
4. Presets Balanced/Stretch/All A read 3.49/3.52/3.58 at default target 3.50.
5. Set target 3.58: all-A may DISPLAY 3.58 but feasibility must remain false.
6. Use the expand-chart action for larger drag lanes. The page scrolls outside
   the chart, and grade buttons provide an alternative to precision dragging.
7. Resize or test on a narrow device: the dial and chart stack rather than clip.

## Sources for the implementation API

https://api.flutter.dev/flutter/widgets/GestureDetector/onVerticalDragUpdate.html
https://api.flutter.dev/flutter/rendering/CustomPainter-class.html
https://api.flutter.dev/flutter/material/Slider/onChanged.html
https://api.flutter.dev/flutter/material/Slider/onChangeEnd.html
