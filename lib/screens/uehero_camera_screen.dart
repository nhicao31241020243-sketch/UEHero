import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class UEHeroCameraScreen extends StatefulWidget {
  const UEHeroCameraScreen({super.key});

  @override
  State<UEHeroCameraScreen> createState() => _UEHeroCameraScreenState();
}

class _UEHeroCameraScreenState extends State<UEHeroCameraScreen>
    with WidgetsBindingObserver {
  static const _backgroundColor = Color(0xFF100E19);
  static const _accentColor = Color(0xFFBFA8FF);
  static const _minimumCropSize = 0.08;

  final _imagePicker = ImagePicker();
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  Uint8List? _sourceImageBytes;
  Uint8List? _croppedImageBytes;
  Size? _sourceImageSize;
  Rect _cropRect = const Rect.fromLTRB(0.08, 0.2, 0.92, 0.72);
  Rect _cropRectAtDragStart = Rect.zero;
  Offset _dragStart = Offset.zero;
  _CropDragMode _cropDragMode = _CropDragMode.none;
  _CameraStep _step = _CameraStep.liveCamera;
  int _selectedMode = 0;
  int _questionCountMode = 0;
  int _cameraGeneration = 0;
  bool _cameraLoading = true;
  bool _isBusy = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cameraGeneration++;
      _cameraController = null;
      if (controller != null) {
        controller.dispose();
      }
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _cameraController == null &&
        mounted) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    final generation = ++_cameraGeneration;
    setState(() {
      _cameraLoading = true;
      _cameraError = null;
    });

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (!mounted || generation != _cameraGeneration) return;
      if (cameras.isEmpty) {
        setState(() {
          _cameraLoading = false;
          _cameraError = 'Không tìm thấy camera trên thiết bị này.';
        });
        return;
      }

      final description =
          _cameraDescription ??
          cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );
      controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = controller;
      await controller.initialize();

      if (!mounted || generation != _cameraGeneration) {
        await controller.dispose();
        return;
      }

      _cameraDescription = description;
      setState(() {
        _cameraLoading = false;
        _cameraError = null;
      });
    } on CameraException catch (error) {
      if (controller != null && _cameraController == controller) {
        _cameraController = null;
        await controller.dispose();
      }
      if (!mounted || generation != _cameraGeneration) return;
      setState(() {
        _cameraLoading = false;
        _cameraError = _cameraErrorMessage(error);
      });
    } on Exception catch (error) {
      if (controller != null && _cameraController == controller) {
        _cameraController = null;
        await controller.dispose();
      }
      if (!mounted || generation != _cameraGeneration) return;
      setState(() {
        _cameraLoading = false;
        _cameraError = 'Không thể mở camera: $error';
      });
    }
  }

  String _cameraErrorMessage(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' => 'UEHero cần quyền Camera để chụp ảnh. Hãy cấp quyền trong Cài đặt rồi thử lại.',
      _ => 'Không thể mở camera: ${error.description ?? error.code}',
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraGeneration++;
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (_isBusy ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final imageFile = await controller.takePicture();
      final imageBytes = await imageFile.readAsBytes();
      await _showCropStep(imageBytes);
    } on CameraException catch (error) {
      _showMessage('Không thể chụp ảnh: ${error.description ?? error.code}');
    } on Exception catch (error) {
      _showMessage('Không thể đọc ảnh vừa chụp: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _pickPhotoFromAlbum() async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (image == null || !mounted) return;
      await _showCropStep(await image.readAsBytes());
    } on PlatformException catch (error) {
      _showMessage('Không thể mở Album: ${error.message ?? error.code}');
    } on Exception catch (error) {
      _showMessage('Không thể đọc ảnh đã chọn: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showCropStep(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    late final Size imageSize;
    ui.Image? image;
    try {
      final frame = await codec.getNextFrame();
      image = frame.image;
      imageSize = Size(image.width.toDouble(), image.height.toDouble());
    } finally {
      image?.dispose();
      codec.dispose();
    }

    if (!mounted) return;
    setState(() {
      _sourceImageBytes = imageBytes;
      _sourceImageSize = imageSize;
      _cropRect = const Rect.fromLTRB(0.08, 0.2, 0.92, 0.72);
      _step = _CameraStep.crop;
    });
  }

  Future<void> _confirmCrop() async {
    final sourceBytes = _sourceImageBytes;
    final sourceSize = _sourceImageSize;
    if (_isBusy || sourceBytes == null || sourceSize == null) return;

    setState(() => _isBusy = true);
    ui.Codec? codec;
    ui.Image? sourceImage;
    ui.Image? croppedImage;
    try {
      codec = await ui.instantiateImageCodec(sourceBytes);
      final frame = await codec.getNextFrame();
      sourceImage = frame.image;

      final left = (_cropRect.left * sourceSize.width).floor().clamp(
        0,
        sourceImage.width - 1,
      );
      final top = (_cropRect.top * sourceSize.height).floor().clamp(
        0,
        sourceImage.height - 1,
      );
      final right = (_cropRect.right * sourceSize.width).ceil().clamp(
        left + 1,
        sourceImage.width,
      );
      final bottom = (_cropRect.bottom * sourceSize.height).ceil().clamp(
        top + 1,
        sourceImage.height,
      );
      final outputWidth = right - left;
      final outputHeight = bottom - top;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        sourceImage,
        Rect.fromLTRB(
          left.toDouble(),
          top.toDouble(),
          right.toDouble(),
          bottom.toDouble(),
        ),
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();
      croppedImage = await picture.toImage(outputWidth, outputHeight);
      picture.dispose();
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        throw StateError('Không thể tạo ảnh đã cắt.');
      }

      if (!mounted) return;
      setState(() {
        _croppedImageBytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        _step = _CameraStep.result;
      });
    } on Exception catch (error) {
      _showMessage('Không thể cắt ảnh: $error');
    } finally {
      sourceImage?.dispose();
      croppedImage?.dispose();
      codec?.dispose();
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Rect _imageRect(Size availableSize) {
    final imageSize = _sourceImageSize;
    if (imageSize == null ||
        availableSize.width <= 0 ||
        availableSize.height <= 0) {
      return Offset.zero & availableSize;
    }
    final scale = math.min(
      availableSize.width / imageSize.width,
      availableSize.height / imageSize.height,
    );
    final width = imageSize.width * scale;
    final height = imageSize.height * scale;
    return Rect.fromLTWH(
      (availableSize.width - width) / 2,
      (availableSize.height - height) / 2,
      width,
      height,
    );
  }

  Offset _normalizedPoint(Offset point, Rect imageRect) {
    return Offset(
      ((point.dx - imageRect.left) / imageRect.width).clamp(0.0, 1.0),
      ((point.dy - imageRect.top) / imageRect.height).clamp(0.0, 1.0),
    );
  }

  void _startCropDrag(DragStartDetails details, Rect imageRect) {
    final position = details.localPosition;
    final cropOnScreen = Rect.fromLTRB(
      imageRect.left + _cropRect.left * imageRect.width,
      imageRect.top + _cropRect.top * imageRect.height,
      imageRect.left + _cropRect.right * imageRect.width,
      imageRect.top + _cropRect.bottom * imageRect.height,
    );
    final handle = _nearestCropHandle(position, cropOnScreen);

    _dragStart = _normalizedPoint(position, imageRect);
    _cropRectAtDragStart = _cropRect;
    if (handle != _CropDragMode.none) {
      _cropDragMode = handle;
    } else if (cropOnScreen.contains(position)) {
      _cropDragMode = _CropDragMode.move;
    } else {
      _cropDragMode = _CropDragMode.create;
      setState(() {
        _cropRect = Rect.fromPoints(_dragStart, _dragStart);
      });
    }
  }

  _CropDragMode _nearestCropHandle(Offset position, Rect cropRect) {
    const handleRadius = 36.0;
    final handles = <(_CropDragMode, Offset)>[
      (_CropDragMode.topLeft, cropRect.topLeft),
      (_CropDragMode.topRight, cropRect.topRight),
      (_CropDragMode.bottomLeft, cropRect.bottomLeft),
      (_CropDragMode.bottomRight, cropRect.bottomRight),
    ];
    final nearest = handles.reduce(
      (first, second) =>
          (position - first.$2).distance <= (position - second.$2).distance
          ? first
          : second,
    );
    return (position - nearest.$2).distance <= handleRadius
        ? nearest.$1
        : _CropDragMode.none;
  }

  void _updateCropDrag(DragUpdateDetails details, Rect imageRect) {
    final point = _normalizedPoint(details.localPosition, imageRect);
    final initial = _cropRectAtDragStart;
    Rect updated;

    switch (_cropDragMode) {
      case _CropDragMode.move:
        final delta = point - _dragStart;
        final left = (initial.left + delta.dx).clamp(0.0, 1.0 - initial.width);
        final top = (initial.top + delta.dy).clamp(0.0, 1.0 - initial.height);
        updated = Rect.fromLTWH(left, top, initial.width, initial.height);
      case _CropDragMode.create:
        final left = math
            .min(_dragStart.dx, point.dx)
            .clamp(0.0, 1.0 - _minimumCropSize);
        final top = math
            .min(_dragStart.dy, point.dy)
            .clamp(0.0, 1.0 - _minimumCropSize);
        final right = math
            .max(math.max(_dragStart.dx, point.dx), left + _minimumCropSize)
            .clamp(left + _minimumCropSize, 1.0);
        final bottom = math
            .max(math.max(_dragStart.dy, point.dy), top + _minimumCropSize)
            .clamp(top + _minimumCropSize, 1.0);
        updated = Rect.fromLTRB(left, top, right, bottom);
      case _CropDragMode.topLeft:
        updated = Rect.fromLTRB(
          point.dx.clamp(0.0, initial.right - _minimumCropSize),
          point.dy.clamp(0.0, initial.bottom - _minimumCropSize),
          initial.right,
          initial.bottom,
        );
      case _CropDragMode.topRight:
        updated = Rect.fromLTRB(
          initial.left,
          point.dy.clamp(0.0, initial.bottom - _minimumCropSize),
          point.dx.clamp(initial.left + _minimumCropSize, 1.0),
          initial.bottom,
        );
      case _CropDragMode.bottomLeft:
        updated = Rect.fromLTRB(
          point.dx.clamp(0.0, initial.right - _minimumCropSize),
          initial.top,
          initial.right,
          point.dy.clamp(initial.top + _minimumCropSize, 1.0),
        );
      case _CropDragMode.bottomRight:
        updated = Rect.fromLTRB(
          initial.left,
          initial.top,
          point.dx.clamp(initial.left + _minimumCropSize, 1.0),
          point.dy.clamp(initial.top + _minimumCropSize, 1.0),
        );
      case _CropDragMode.none:
        return;
    }

    setState(() => _cropRect = updated);
  }

  void _endCropDrag(DragEndDetails details) {
    _cropDragMode = _CropDragMode.none;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: switch (_step) {
        _CameraStep.liveCamera => _buildLiveCamera(),
        _CameraStep.crop => _buildCropStep(),
        _CameraStep.result => _buildResultStep(),
      },
    );
  }

  Widget _buildLiveCamera() {
    final controller = _cameraController;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller != null && controller.value.isInitialized)
          _buildCameraPreview(controller)
        else
          const ColoredBox(color: _backgroundColor),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC0A0810),
                Color(0x330A0810),
                Colors.transparent,
                Color(0x990A0810),
              ],
              stops: [0, 0.24, 0.54, 1],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(onBack: () => Navigator.of(context).maybePop()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: _buildBanner(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildModeSwitch(
                  firstLabel: 'Tìm kiếm lời giải',
                  secondLabel: 'Lời giải AI',
                  selectedIndex: _selectedMode,
                  onChanged: (index) => setState(() => _selectedMode = index),
                ),
              ),
              const Spacer(),
              if (_cameraError case final error?)
                _buildCameraError(error)
              else if (_cameraLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              _buildLiveCameraControls(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final previewAspectRatio = isLandscape
        ? controller.value.aspectRatio
        : 1 / controller.value.aspectRatio;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: 1000 * previewAspectRatio,
        height: 1000,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildCameraError(String error) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cameraLoading ? null : _initializeCamera,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCameraControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildAlbumButton(),
            ),
          ),
          Expanded(
            child: Center(
              child: _buildShutterButton(
                onPressed:
                    _isBusy || _cameraController?.value.isInitialized != true
                    ? null
                    : _capturePhoto,
                isBusy: _isBusy,
              ),
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildCropStep() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(
            onBack: () => setState(() => _step = _CameraStep.liveCamera),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Text(
              'Cắt gọn vùng câu hỏi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _buildInteractiveCropper(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: _buildModeSwitch(
              firstLabel: '1 câu hỏi',
              secondLabel: 'Nhiều câu hỏi',
              selectedIndex: _questionCountMode,
              onChanged: (index) => setState(() => _questionCountMode = index),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isBusy ? null : _confirmCrop,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF191522),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Đặt câu hỏi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCropper() {
    final imageBytes = _sourceImageBytes;
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageRect = _imageRect(constraints.biggest);
        return Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null)
              Image.memory(imageBytes, fit: BoxFit.contain)
            else
              const SizedBox.shrink(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => _startCropDrag(details, imageRect),
              onPanUpdate: (details) => _updateCropDrag(details, imageRect),
              onPanEnd: _endCropDrag,
              child: CustomPaint(
                painter: _CropOverlayPainter(
                  imageRect: imageRect,
                  cropRect: _cropRect,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultStep() {
    final imageBytes = _croppedImageBytes;
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(onBack: () => setState(() => _step = _CameraStep.crop)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 270,
                        width: double.infinity,
                        color: const Color(0xFF17141F),
                        alignment: Alignment.center,
                        child: imageBytes == null
                            ? const Text(
                                'Không có ảnh đã cắt.',
                                style: TextStyle(color: Colors.white70),
                              )
                            : Image.memory(imageBytes, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildModeSwitch(
                      firstLabel: 'Tìm kiếm lời giải',
                      secondLabel: 'Lời giải AI',
                      selectedIndex: _selectedMode,
                      onChanged: (index) =>
                          setState(() => _selectedMode = index),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTutorCard(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _step = _CameraStep.liveCamera;
                    _croppedImageBytes = null;
                    _sourceImageBytes = null;
                    _sourceImageSize = null;
                  });
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp câu hỏi khác'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312747), Color(0xFF211D2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_rounded, color: _accentColor, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hỏi gia sư trực tiếp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 34, top: 5),
            child: Text(
              'Trả lời trong 5 phút',
              style: TextStyle(color: Color(0xFFCFC7DC), fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () =>
                  _showMessage('Tính năng hỏi gia sư trực tiếp sẽ sớm ra mắt.'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF191522),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Đặt câu hỏi',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar({required VoidCallback onBack}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 20, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: _step == _CameraStep.liveCamera ? 'Đóng' : 'Quay lại',
            onPressed: onBack,
            icon: Icon(
              _step == _CameraStep.liveCamera
                  ? Icons.close_rounded
                  : Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          const Icon(Icons.auto_awesome_rounded, color: _accentColor, size: 19),
          const SizedBox(width: 7),
          const Text(
            'UEH HERO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xD9211D2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accentColor.withValues(alpha: 0.32)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: _accentColor, size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Vui lòng chụp ảnh câu hỏi mà bạn đang giải.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch({
    required String firstLabel,
    required String secondLabel,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xE6211D2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _buildModeButton(
            label: firstLabel,
            isSelected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _buildModeButton(
            label: secondLabel,
            isSelected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? _accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? const Color(0xFF211A30) : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: const Color(0xD9211D2B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: _isBusy ? null : _pickPhotoFromAlbum,
            child: SizedBox(
              width: 58,
              height: 58,
              child: _isBusy
                  ? const Padding(
                      padding: EdgeInsets.all(17),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Album',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildShutterButton({
    required VoidCallback? onPressed,
    required bool isBusy,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.3),
                  blurRadius: 22,
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onPressed == null
                    ? Colors.white24
                    : Colors.white.withValues(alpha: 0.95),
              ),
              child: isBusy
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF211A30),
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF211A30),
                      size: 29,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'CHỤP ẢNH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

enum _CameraStep { liveCamera, crop, result }

enum _CropDragMode {
  none,
  move,
  create,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({required this.imageRect, required this.cropRect});

  final Rect imageRect;
  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect.isEmpty) return;

    final crop = Rect.fromLTRB(
      imageRect.left + cropRect.left * imageRect.width,
      imageRect.top + cropRect.top * imageRect.height,
      imageRect.left + cropRect.right * imageRect.width,
      imageRect.top + cropRect.bottom * imageRect.height,
    );
    final shade = Paint()..color = const Color(0x99000000);
    canvas
      ..drawRect(Rect.fromLTRB(0, 0, size.width, crop.top), shade)
      ..drawRect(Rect.fromLTRB(0, crop.bottom, size.width, size.height), shade)
      ..drawRect(Rect.fromLTRB(0, crop.top, crop.left, crop.bottom), shade)
      ..drawRect(
        Rect.fromLTRB(crop.right, crop.top, size.width, crop.bottom),
        shade,
      );

    final border = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(crop, border);

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 0.8;
    for (var i = 1; i <= 2; i++) {
      final dx = crop.left + crop.width * i / 3;
      final dy = crop.top + crop.height * i / 3;
      canvas
        ..drawLine(Offset(dx, crop.top), Offset(dx, crop.bottom), grid)
        ..drawLine(Offset(crop.left, dy), Offset(crop.right, dy), grid);
    }

    final handles = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const cornerLength = 24.0;
    final cornerPaths = <Path>[
      Path()
        ..moveTo(crop.left + cornerLength, crop.top)
        ..lineTo(crop.left, crop.top)
        ..lineTo(crop.left, crop.top + cornerLength),
      Path()
        ..moveTo(crop.right - cornerLength, crop.top)
        ..lineTo(crop.right, crop.top)
        ..lineTo(crop.right, crop.top + cornerLength),
      Path()
        ..moveTo(crop.left, crop.bottom - cornerLength)
        ..lineTo(crop.left, crop.bottom)
        ..lineTo(crop.left + cornerLength, crop.bottom),
      Path()
        ..moveTo(crop.right - cornerLength, crop.bottom)
        ..lineTo(crop.right, crop.bottom)
        ..lineTo(crop.right, crop.bottom - cornerLength),
    ];
    for (final path in cornerPaths) {
      canvas.drawPath(path, handles);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.imageRect != imageRect || oldDelegate.cropRect != cropRect;
}
