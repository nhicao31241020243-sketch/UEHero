import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../models/character_data.dart';
import '../screens/chatbot_screen.dart';
import '../screens/mascot_hub_screen.dart';
import '../services/app_navigation.dart';
import '../services/companion_context_service.dart';
import '../services/companion_settings_store.dart';
import '../services/mascot_selection_store.dart';
import '../services/route_observer.dart';

class CompanionOverlay extends StatefulWidget {
  const CompanionOverlay({super.key});

  @override
  State<CompanionOverlay> createState() => _CompanionOverlayState();
}

class _CompanionOverlayState extends State<CompanionOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _modelSize = 112.0;
  static const _horizontalInset = 12.0;
  static const _topInset = 86.0;
  static const _bottomInset = 180.0;

  final _random = math.Random();
  CharacterData? _companion;
  Offset _position = const Offset(0.88, 0.56);
  Size _screenSize = Size.zero;
  bool _overlayEnabled = true;
  bool _hiddenToday = false;
  bool _autoMovementEnabled = true;
  bool _settingsLoaded = false;
  bool _dragging = false;
  bool _positionInitialized = false;
  bool _appResumed = true;
  bool _movementAllowed = false;
  int _edge = 1;
  double _edgeStartProgress = 0;
  String? _bubbleText;
  String? _bubblePrompt;
  Timer? _bubbleTimer;
  Timer? _movementTimer;
  late final AnimationController _movementController;

  bool get _isFlyingBee =>
      _companion?.modelPath.endsWith('animal-bee.glb') ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _movementController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..addStatusListener(_onMovementStatus);
    companionRouteObserver.routeChanges.addListener(_onRouteChanged);
    MascotSelectionStore.selectionChanges.addListener(_onSelectionChanged);
    CompanionSettingsStore.changes.addListener(_onSettingsChanged);
    _loadState();
  }

  Future<void> _loadState() async {
    final values = await Future.wait<Object>([
      MascotSelectionStore.instance.read(),
      CompanionSettingsStore.instance.position(),
      CompanionSettingsStore.instance.overlayEnabled(),
      CompanionSettingsStore.instance.isHiddenToday(),
      CompanionSettingsStore.instance.autoMovementEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _companion = (values[0] as MascotSelection).aiCompanion;
      _position = values[1] as Offset;
      _overlayEnabled = values[2] as bool;
      _hiddenToday = values[3] as bool;
      _autoMovementEnabled = values[4] as bool;
      _settingsLoaded = true;
    });
  }

  void _onSelectionChanged() {
    final selected = MascotSelectionStore.selectionChanges.value?.aiCompanion;
    if (!mounted || selected?.id == _companion?.id) return;
    _stopMovement();
    setState(() {
      _companion = selected;
      _positionInitialized = false;
    });
    _scheduleMovement(const Duration(seconds: 5));
  }

  Future<void> _onSettingsChanged() async {
    final values = await Future.wait([
      CompanionSettingsStore.instance.overlayEnabled(),
      CompanionSettingsStore.instance.isHiddenToday(),
      CompanionSettingsStore.instance.autoMovementEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _overlayEnabled = values[0];
      _hiddenToday = values[1];
      _autoMovementEnabled = values[2];
    });
  }

  void _onRouteChanged() {
    if (!mounted) return;
    _bubbleTimer?.cancel();
    setState(() {
      _bubbleText = null;
      _bubblePrompt = null;
    });
    _syncMovement();
    _maybeShowReminder();
  }

  Future<void> _maybeShowReminder() async {
    if (!_settingsLoaded ||
        !_overlayEnabled ||
        _hiddenToday ||
        _companion == null ||
        !await CompanionSettingsStore.instance.bubblesEnabled()) {
      return;
    }
    final route = companionRouteObserver.routeChanges.value;
    if (!_routeCanShow(route)) return;
    final contextData = await CompanionContextService.instance.load();
    final currentRoute = companionRouteObserver.routeChanges.value;
    if (!mounted ||
        !_routeCanShow(currentRoute) ||
        currentRoute.name != route.name) {
      return;
    }
    final text = contextData.reminderForRoute(route.name);
    if (text == null ||
        !await CompanionSettingsStore.instance.tryReserveBubble()) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _bubbleText = text;
      _bubblePrompt = _promptForRoute(route.name);
    });
    _bubbleTimer = Timer(CompanionSettingsStore.bubbleDuration, () {
      if (!mounted) return;
      setState(() {
        _bubbleText = null;
        _bubblePrompt = null;
      });
    });
  }

  bool _routeCanShow(AppRouteSnapshot route) {
    if (!route.isPageRoute) return false;
    final name = (route.name ?? '').toLowerCase();
    return ![
      'onboarding',
      'mascot-hub',
      'mascot-selector',
      'chatbot',
      'interview-room',
      'camera',
      'full-screen',
    ].any(name.contains);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    _syncMovement();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bubbleTimer?.cancel();
    _movementTimer?.cancel();
    _movementController.dispose();
    companionRouteObserver.routeChanges.removeListener(_onRouteChanged);
    MascotSelectionStore.selectionChanges.removeListener(_onSelectionChanged);
    CompanionSettingsStore.changes.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    _screenSize = media.size;
    final visible =
        _settingsLoaded &&
        _companion != null &&
        _overlayEnabled &&
        !_hiddenToday &&
        media.viewInsets.bottom <= 0 &&
        _appResumed &&
        _routeCanShow(companionRouteObserver.routeChanges.value);
    _syncMovement(visible: visible);
    if (!visible) return const SizedBox.shrink();
    _initializePerimeterPosition();
    return _buildOverlay(media.size);
  }

  void _syncMovement({bool? visible}) {
    final currentRoute = companionRouteObserver.routeChanges.value;
    final canShow =
        visible ??
        (_settingsLoaded &&
            _companion != null &&
            _overlayEnabled &&
            !_hiddenToday &&
            _appResumed &&
            _routeCanShow(currentRoute));
    final canMove = canShow && _autoMovementEnabled && !_dragging;
    if (_movementAllowed == canMove) return;
    _movementAllowed = canMove;
    if (!canMove) {
      _movementTimer?.cancel();
      _movementTimer = null;
      if (_movementController.isAnimating) {
        _edgeStartProgress = _movementController.value;
      }
      _movementController.stop();
    } else {
      _scheduleMovement(Duration.zero);
    }
  }

  void _initializePerimeterPosition() {
    if (_positionInitialized ||
        _screenSize == Size.zero ||
        _movementController.isAnimating) {
      return;
    }
    final bounds = _safeBounds;
    final current = _positionToPixels(_position, bounds);
    final distances = [
      (current.dy - bounds.top).abs(),
      (current.dx - bounds.right).abs(),
      (current.dy - bounds.bottom).abs(),
      (current.dx - bounds.left).abs(),
    ];
    _edge = distances.indexOf(distances.reduce(math.min));
    final projected = switch (_edge) {
      0 => Offset(current.dx.clamp(bounds.left, bounds.right), bounds.top),
      1 => Offset(bounds.right, current.dy.clamp(bounds.top, bounds.bottom)),
      2 => Offset(current.dx.clamp(bounds.left, bounds.right), bounds.bottom),
      _ => Offset(bounds.left, current.dy.clamp(bounds.top, bounds.bottom)),
    };
    _position = _pixelsToPosition(projected, bounds);
    _edgeStartProgress = _progressOnEdge(projected, bounds, _edge);
    _positionInitialized = true;
  }

  Rect get _safeBounds {
    final right = math.max(
      _horizontalInset,
      _screenSize.width - _modelSize - _horizontalInset,
    );
    final bottom = math.max(
      _topInset,
      _screenSize.height - _bottomInset - _modelSize,
    );
    return Rect.fromLTRB(_horizontalInset, _topInset, right, bottom);
  }

  Offset _positionToPixels(Offset normalized, Rect bounds) => Offset(
    bounds.left + normalized.dx * (bounds.right - bounds.left),
    bounds.top + normalized.dy * (bounds.bottom - bounds.top),
  );

  Offset _pixelsToPosition(Offset pixels, Rect bounds) => Offset(
    ((pixels.dx - bounds.left) / (bounds.right - bounds.left)).clamp(0.0, 1.0),
    ((pixels.dy - bounds.top) / (bounds.bottom - bounds.top)).clamp(0.0, 1.0),
  );

  double _progressOnEdge(Offset point, Rect bounds, int edge) => switch (edge) {
    0 => (point.dx - bounds.left) / (bounds.right - bounds.left),
    1 => (point.dy - bounds.top) / (bounds.bottom - bounds.top),
    2 => (bounds.right - point.dx) / (bounds.right - bounds.left),
    _ => (bounds.bottom - point.dy) / (bounds.bottom - bounds.top),
  };

  void _scheduleMovement(Duration delay) {
    _movementTimer?.cancel();
    if (!_movementAllowed || !_autoMovementEnabled) return;
    _movementTimer = Timer(delay, _startMovementSegment);
  }

  void _startMovementSegment() {
    if (!_movementAllowed || !_autoMovementEnabled || _dragging) return;
    final durationSeconds = _isFlyingBee ? 6 : 9;
    _movementController.duration = Duration(
      milliseconds: durationSeconds * 1000 + _random.nextInt(2500),
    );
    _movementController.forward(from: _edgeStartProgress);
    _edgeStartProgress = 0;
    _updateMovingPosition();
  }

  void _onMovementStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_movementAllowed) return;
    _edge = (_edge + 1) % 4;
    _edgeStartProgress = 0;
    final rest = Duration(milliseconds: 1000 + _random.nextInt(3500));
    _scheduleMovement(rest);
  }

  void _updateMovingPosition() {
    if (!_movementAllowed || _dragging) return;
    final bounds = _safeBounds;
    final progress = _movementController.value;
    var point = switch (_edge) {
      0 => Offset(
        bounds.left + (bounds.right - bounds.left) * progress,
        bounds.top,
      ),
      1 => Offset(
        bounds.right,
        bounds.top + (bounds.bottom - bounds.top) * progress,
      ),
      2 => Offset(
        bounds.right - (bounds.right - bounds.left) * progress,
        bounds.bottom,
      ),
      _ => Offset(
        bounds.left,
        bounds.bottom - (bounds.bottom - bounds.top) * progress,
      ),
    };
    if (_isFlyingBee) {
      final curve = math.sin(progress * math.pi) * 22;
      point = switch (_edge) {
        0 || 2 => point.translate(0, curve),
        _ => point.translate(curve, 0),
      };
    } else {
      final bob = math.sin(progress * math.pi * 8) * 3;
      point = point.translate(0, bob);
    }
    _position = _pixelsToPosition(point, bounds);
  }

  bool get _facingLeft => _edge == 2 || _edge == 3;

  void _onPanStart(DragStartDetails details) {
    _dragging = true;
    _movementAllowed = false;
    _movementTimer?.cancel();
    _movementTimer = null;
    if (_movementController.isAnimating) {
      _edgeStartProgress = _movementController.value;
    }
    _movementController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final bounds = _safeBounds;
    final point = Offset(
      details.globalPosition.dx - _modelSize / 2,
      details.globalPosition.dy - _modelSize / 2,
    );
    setState(() => _position = _pixelsToPosition(point, bounds));
  }

  void _onPanEnd(DragEndDetails details) {
    final bounds = _safeBounds;
    final point = _positionToPixels(_position, bounds);
    final side = point.dx < bounds.left + bounds.width / 2 ? 3 : 1;
    final snapped = Offset(
      side == 3 ? bounds.left : bounds.right,
      point.dy.clamp(bounds.top, bounds.bottom),
    );
    setState(() {
      _position = _pixelsToPosition(snapped, bounds);
      _edge = side;
      _edgeStartProgress = _progressOnEdge(snapped, bounds, side);
      _dragging = false;
      _positionInitialized = true;
    });
    CompanionSettingsStore.instance.savePosition(_position);
    _syncMovement();
    if (_autoMovementEnabled) {
      _scheduleMovement(const Duration(seconds: 5));
    }
  }

  void _stopMovement() {
    _movementTimer?.cancel();
    _movementTimer = null;
    _movementAllowed = false;
    if (_movementController.isAnimating) {
      _edgeStartProgress = _movementController.value;
    }
    _movementController.stop();
  }

  Widget _buildOverlay(Size size) {
    final companion = _companion!;
    final bounds = _safeBounds;
    final position = _positionToPixels(_position, bounds);
    final bubbleLeft = (position.dx - 190).clamp(8.0, size.width - 208);
    final bubbleTop = (position.dy - 76).clamp(_topInset, size.height - 70);

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _movementController,
          child: _buildInteractiveModel(companion),
          builder: (context, child) {
            if (_movementController.isAnimating) _updateMovingPosition();
            final currentPosition = _positionToPixels(_position, bounds);
            return Positioned.fill(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Transform.translate(
                    offset: currentPosition,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(
                        _facingLeft ? -1 : 1,
                        1,
                        1,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (_bubbleText case final text?)
          Positioned(
            left: bubbleLeft,
            top: bubbleTop,
            child: GestureDetector(
              onTap: () => _openChat(initialPrompt: _bubblePrompt),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF33284D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFA8FF)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 12),
                  ],
                ),
                child: Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInteractiveModel(CharacterData companion) {
    return SizedBox(
      width: _modelSize,
      height: _modelSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openChat,
        onLongPress: _showMenu,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: () => _onPanEnd(DragEndDetails()),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: ModelViewer(
                key: ValueKey('companion-model-${companion.id}'),
                src: companion.modelPath,
                alt: companion.name,
                autoPlay: true,
                animationName: companion.animationName,
                autoRotate: false,
                cameraControls: false,
                disableZoom: true,
                backgroundColor: Colors.transparent,
                cameraOrbit: '0deg 75deg 105%',
                fieldOfView: '30deg',
                loading: Loading.eager,
                reveal: Reveal.auto,
                debugLogging: false,
              ),
            ),
            const Positioned.fill(child: ColoredBox(color: Colors.transparent)),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat({String? initialPrompt}) async {
    _bubbleTimer?.cancel();
    if (mounted) {
      setState(() {
        _bubbleText = null;
        _bubblePrompt = null;
      });
    }
    await appNavigatorKey.currentState?.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/chatbot'),
        builder: (_) => ChatbotScreen(initialPrompt: initialPrompt),
      ),
    );
  }

  String _promptForRoute(String? routeName) {
    final route = (routeName ?? '').toLowerCase();
    if (route.contains('flashcard')) return 'Còn bao nhiêu thẻ chưa học?';
    if (route.contains('event') || route.contains('competition')) {
      return 'Cuộc thi sắp hết hạn?';
    }
    if (route.contains('weekly') || route.contains('calendar')) {
      return 'Nên làm gì trước?';
    }
    return 'Hôm nay có gì?';
  }

  Future<void> _showMenu() async {
    final navigatorContext = appNavigatorKey.currentContext;
    if (navigatorContext == null) return;
    final action = await showModalBottomSheet<String>(
      context: navigatorContext,
      backgroundColor: const Color(0xFF211D2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(context, 'today', 'Ẩn hôm nay', Icons.visibility_off),
            _menuItem(context, 'never', 'Ẩn hẳn', Icons.hide_source),
            _menuItem(context, 'change', 'Đổi bạn đồng hành', Icons.pets),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    switch (action) {
      case 'today':
        await CompanionSettingsStore.instance.hideToday();
      case 'never':
        await CompanionSettingsStore.instance.setOverlayEnabled(false);
      case 'change':
        final selection = await MascotSelectionStore.instance.read();
        await appNavigatorKey.currentState?.push<void>(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/mascot-hub'),
            builder: (_) => MascotHubScreen(initialSelection: selection),
          ),
        );
    }
  }

  Widget _menuItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFBFA8FF)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}
