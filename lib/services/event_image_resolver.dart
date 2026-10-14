import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EventImageResolver {
  EventImageResolver._();

  static final instance = EventImageResolver._();
  static const _cacheKey = 'event_og_image_cache_v1';
  static const _timeout = Duration(seconds: 3);

  final http.Client _client = http.Client();
  final Map<String, Future<String?>> _pending = {};

  Future<String?> resolve({String? imageUrl, String? sourceUrl}) async {
    final poster = _httpUrl(imageUrl);
    if (poster != null) return poster;

    final source = _httpUrl(sourceUrl);
    if (source == null) return null;
    return _pending.putIfAbsent(source, () => _resolveSource(source));
  }

  Future<String?> _resolveSource(String source) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final cached = _readCache(preferences.getString(_cacheKey));
      if (cached.containsKey(source)) {
        return cached[source]?.isNotEmpty == true ? cached[source] : null;
      }

      String? imageUrl;
      final response = await _client
          .get(
            Uri.parse(source),
            headers: const {'User-Agent': 'UEHero event poster preview'},
          )
          .timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        imageUrl = _extractOgImage(response.body, Uri.parse(source));
      }
      cached[source] = imageUrl ?? '';
      await preferences.setString(_cacheKey, jsonEncode(cached));
      return imageUrl;
    } catch (error, stackTrace) {
      debugPrint('Event poster lookup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Map<String, String> _readCache(String? raw) {
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
      }
    } catch (_) {
      return {};
    }
    return {};
  }

  String? _extractOgImage(String html, Uri source) {
    final tags = RegExp(r'<meta\b[^>]*>', caseSensitive: false, dotAll: true);
    for (final match in tags.allMatches(html)) {
      final tag = match.group(0)!;
      final property = _attribute(tag, 'property') ?? _attribute(tag, 'name');
      if (property?.toLowerCase() != 'og:image') continue;
      final content = _attribute(tag, 'content');
      if (content == null || content.trim().isEmpty) continue;
      final normalized = content
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .trim();
      final resolved = _httpUrl(source.resolve(normalized).toString());
      if (resolved != null) return resolved;
    }
    return null;
  }

  String? _attribute(String tag, String name) {
    final pattern = RegExp(
      '$name\\s*=\\s*([\'"])(.*?)\\1',
      caseSensitive: false,
      dotAll: true,
    );
    return pattern.firstMatch(tag)?.group(2);
  }

  String? _httpUrl(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return uri.toString();
  }
}