import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookCover extends StatefulWidget {
  const BookCover({
    required this.id,
    required this.title,
    required this.author,
    this.isbn = '',
    super.key,
  });

  final String id;
  final String title;
  final String author;
  final String isbn;

  @override
  State<BookCover> createState() => _BookCoverState();
}

class _BookCoverState extends State<BookCover> {
  static const _cacheKey = 'resource_cover_cache';
  static const _accent = Color(0xFFBFA8FF);

  String? _imageUrl;
  bool _showingFallback = false;

  @override
  void initState() {
    super.initState();
    _resolveCover();
  }

  Future<void> _resolveCover() async {
    final preferences = await SharedPreferences.getInstance();
    final cache = _readCache(preferences.getString(_cacheKey));
    final cachedUrl = cache[widget.id];
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      if (mounted) setState(() => _imageUrl = cachedUrl);
      return;
    }

    if (widget.isbn.isNotEmpty) {
      final coverUrl =
          'https://covers.openlibrary.org/b/isbn/${Uri.encodeComponent(widget.isbn)}-M.jpg?default=false';
      await _saveCachedUrl(preferences, cache, coverUrl);
      if (mounted) setState(() => _imageUrl = coverUrl);
      return;
    }

    await _findGoogleBooksCover(preferences, cache);
  }

  Future<void> _findGoogleBooksCover(
    SharedPreferences preferences,
    Map<String, String> cache,
  ) async {
    HttpClient? client;
    try {
      final query = 'intitle:${widget.title} inauthor:${widget.author}'.trim();
      final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': query,
        'maxResults': '1',
      });
      client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 4));
      final response = await request.close().timeout(
        const Duration(seconds: 4),
      );
      if (response.statusCode != HttpStatus.ok) {
        _useFallback();
        return;
      }
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 4));
      final decoded = jsonDecode(body);
      final items = decoded is Map<String, dynamic> ? decoded['items'] : null;
      final volumeInfo = items is List && items.isNotEmpty && items.first is Map
          ? (items.first as Map)['volumeInfo']
          : null;
      final imageLinks = volumeInfo is Map ? volumeInfo['imageLinks'] : null;
      final thumbnail = imageLinks is Map
          ? imageLinks['thumbnail']?.toString()
          : null;
      if (thumbnail == null || thumbnail.isEmpty) {
        _useFallback();
        return;
      }
      final secureUrl = thumbnail.replaceFirst(RegExp(r'^http:'), 'https:');
      await _saveCachedUrl(preferences, cache, secureUrl);
      if (mounted) setState(() => _imageUrl = secureUrl);
    } catch (_) {
      _useFallback();
    } finally {
      client?.close(force: true);
    }
  }

  Future<void> _saveCachedUrl(
    SharedPreferences preferences,
    Map<String, String> cache,
    String url,
  ) async {
    cache[widget.id] = url;
    await preferences.setString(_cacheKey, jsonEncode(cache));
  }

  Map<String, String> _readCache(String? encoded) {
    if (encoded == null) return {};
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } catch (_) {
      return {};
    }
    return {};
  }

  void _useFallback() {
    if (mounted) setState(() => _showingFallback = true);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _imageUrl != null && !_showingFallback
              ? Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _loadingCover();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_showingFallback && widget.isbn.isNotEmpty) {
                        _findFallbackAfterIsbnError();
                      } else {
                        _useFallback();
                      }
                    });
                    return _loadingCover();
                  },
                )
              : _fakeCover(),
        ),
      ),
    );
  }

  Future<void> _findFallbackAfterIsbnError() async {
    if (_showingFallback) return;
    _showingFallback = true;
    final preferences = await SharedPreferences.getInstance();
    final cache = _readCache(preferences.getString(_cacheKey));
    cache.remove(widget.id);
    await preferences.setString(_cacheKey, jsonEncode(cache));
    _showingFallback = false;
    await _findGoogleBooksCover(preferences, cache);
  }

  Widget _loadingCover() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF302747), Color(0xFF211D2B), Color(0xFF392D53)],
      ),
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.auto_awesome_rounded, color: _accent, size: 24),
  );

  Widget _fakeCover() => Container(
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7860B5), Color(0xFF282B53), Color(0xFF171827)],
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.public_rounded, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          widget.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
