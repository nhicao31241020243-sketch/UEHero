import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Book cover with a 2:3 ratio. Sources are tried in order: explicit
/// [coverUrl], Open Library by ISBN or title, then a themed placeholder.
/// Set [lookupOnline] to false (e.g. for online courses) to skip network
/// lookups and show the placeholder directly.
class BookCover extends StatefulWidget {
  const BookCover({
    required this.id,
    required this.title,
    required this.author,
    this.isbn = '',
    this.coverUrl,
    this.lookupOnline = true,
    super.key,
  });

  final String id;
  final String title;
  final String author;
  final String isbn;
  final String? coverUrl;
  final bool lookupOnline;

  @override
  State<BookCover> createState() => _BookCoverState();
}

class _BookCoverState extends State<BookCover> {
  static const _cacheKey = 'resource_cover_cache';
  static const _accent = Color(0xFFBFA8FF);
  static const _timeout = Duration(seconds: 4);
  // Books Open Library could not match this session, so lookups are not repeated.
  static final _openLibraryMisses = <String>{};

  String? _imageUrl;
  bool _showingFallback = false;
  bool _resolving = false;
  // -1 = not started; 0 explicit URL, 1 cache/ISBN, 2 Open Library search.
  int _stage = -1;
  bool _cached = false;

  @override
  void initState() {
    super.initState();
    _advance(_stage);
  }

  @override
  void didUpdateWidget(BookCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.isbn != widget.isbn ||
        oldWidget.lookupOnline != widget.lookupOnline) {
      _imageUrl = null;
      _showingFallback = false;
      _cached = false;
      _stage = -1;
      _advance(_stage);
    }
  }

  /// Resolves the first usable URL after [from]; falls back to the placeholder.
  Future<void> _advance(int from) async {
    if (_resolving) return;
    _resolving = true;
    try {
      final lastStage = widget.lookupOnline ? 2 : 0;
      for (var stage = from + 1; stage <= lastStage; stage++) {
        final url = await _urlFor(stage);
        if (!mounted) return;
        if (url != null && url.isNotEmpty && url != _imageUrl) {
          setState(() {
            _stage = stage;
            _imageUrl = url;
          });
          return;
        }
      }
      if (mounted) setState(() => _showingFallback = true);
    } finally {
      _resolving = false;
    }
  }

  Future<String?> _urlFor(int stage) async {
    try {
      switch (stage) {
        case 0:
          final explicit = widget.coverUrl?.trim();
          return explicit == null || explicit.isEmpty ? null : explicit;
        case 1:
          final preferences = await SharedPreferences.getInstance();
          final cached = _readCache(
            preferences.getString(_cacheKey),
          )[widget.id];
          if (cached != null && cached.isNotEmpty) return cached;
          return widget.isbn.isEmpty
              ? null
              : 'https://covers.openlibrary.org/b/isbn/${Uri.encodeComponent(widget.isbn)}-M.jpg?default=false';
        case 2:
          if (_openLibraryMisses.contains(widget.id)) return null;
          final found = await _openLibraryTitleCover();
          if (found == null) _openLibraryMisses.add(widget.id);
          return found;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<dynamic> _getJson(Uri uri) async {
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw StateError('Open Library responded ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<String?> _openLibraryTitleCover() async {
    final decoded = await _getJson(
      Uri.https('openlibrary.org', '/search.json', {
        'title': widget.title,
        if (widget.author.isNotEmpty) 'author': widget.author,
        'limit': '1',
        'fields': 'cover_i',
      }),
    );
    final docs = decoded is Map ? decoded['docs'] : null;
    final first = docs is List && docs.isNotEmpty ? docs.first : null;
    final coverId = first is Map ? first['cover_i'] : null;
    return coverId is int
        ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg?default=false'
        : null;
  }

  Future<void> _rememberUrl(String url) async {
    if (_cached || url == widget.coverUrl) return;
    _cached = true;
    final preferences = await SharedPreferences.getInstance();
    final cache = _readCache(preferences.getString(_cacheKey));
    cache[widget.id] = url;
    await preferences.setString(_cacheKey, jsonEncode(cache));
  }

  Future<void> _forgetUrl() async {
    final preferences = await SharedPreferences.getInstance();
    final cache = _readCache(preferences.getString(_cacheKey));
    if (cache.remove(widget.id) != null) {
      await preferences.setString(_cacheKey, jsonEncode(cache));
    }
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

  void _onImageError() {
    if (_stage == 1) unawaited(_forgetUrl());
    _advance(_stage);
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl;
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
          child: url != null && !_showingFallback
              ? CachedNetworkImage(
                  key: ValueKey(url),
                  imageUrl: url,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 180),
                  placeholder: (context, _) => _loadingCover(),
                  imageBuilder: (context, provider) {
                    unawaited(_rememberUrl(url));
                    return Image(image: provider, fit: BoxFit.cover);
                  },
                  errorWidget: (context, _, _) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && url == _imageUrl) _onImageError();
                    });
                    return _loadingCover();
                  },
                )
              : (_showingFallback ? _fakeCover() : _loadingCover()),
        ),
      ),
    );
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
        const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 18),
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
