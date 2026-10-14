import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanionSettingsStore {
  CompanionSettingsStore._();

  static final instance = CompanionSettingsStore._();
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static const maximumBubblesPerDay = 3;
  static const minimumBubbleInterval = Duration(minutes: 10);
  static const bubbleDuration = Duration(seconds: 6);
  static const _overlayEnabledKey = 'companion_overlay_enabled_v1';
  static const _bubblesEnabledKey = 'companion_bubbles_enabled_v1';
  static const _autoMovementEnabledKey = 'companion_auto_movement_enabled_v1';
  static const _hiddenTodayKey = 'companion_hidden_today_v1';
  static const _bubbleDateKey = 'companion_bubble_date_v1';
  static const _bubbleCountKey = 'companion_bubble_count_v1';
  static const _lastBubbleAtKey = 'companion_last_bubble_at_v1';
  static const _overlayPositionKey = 'companion_overlay_position_v1';

  Future<bool> overlayEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_overlayEnabledKey) ?? true;
  }

  Future<void> setOverlayEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_overlayEnabledKey, enabled);
    changes.value++;
  }

  Future<bool> bubblesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bubblesEnabledKey) ?? true;
  }

  Future<void> setBubblesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bubblesEnabledKey, enabled);
    changes.value++;
  }

  Future<bool> autoMovementEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoMovementEnabledKey) ?? true;
  }

  Future<void> setAutoMovementEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoMovementEnabledKey, enabled);
    changes.value++;
  }

  Future<void> hideToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hiddenTodayKey, _todayKey());
    changes.value++;
  }

  Future<bool> isHiddenToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hiddenTodayKey) == _todayKey();
  }

  Future<Offset> position() async {
    final prefs = await SharedPreferences.getInstance();
    final parts = prefs.getString(_overlayPositionKey)?.split(',');
    if (parts == null || parts.length != 2) return const Offset(0.88, 0.56);
    final x = double.tryParse(parts[0]);
    final y = double.tryParse(parts[1]);
    if (x == null || y == null) return const Offset(0.88, 0.56);
    return Offset(x.clamp(0, 1).toDouble(), y.clamp(0, 1).toDouble());
  }

  Future<void> savePosition(Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _overlayPositionKey,
      '${position.dx.clamp(0, 1)},${position.dy.clamp(0, 1)}',
    );
  }

  Future<bool> tryReserveBubble({DateTime? at}) async {
    final now = at ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey(now);
    final savedDate = prefs.getString(_bubbleDateKey);
    final count = savedDate == today ? prefs.getInt(_bubbleCountKey) ?? 0 : 0;
    final previous = DateTime.tryParse(prefs.getString(_lastBubbleAtKey) ?? '');
    if (count >= maximumBubblesPerDay ||
        (previous != null &&
            now.difference(previous) < minimumBubbleInterval)) {
      return false;
    }
    await prefs.setString(_bubbleDateKey, today);
    await prefs.setInt(_bubbleCountKey, count + 1);
    await prefs.setString(_lastBubbleAtKey, now.toIso8601String());
    return true;
  }

  static String _todayKey([DateTime? date]) {
    final value = date ?? DateTime.now();
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
