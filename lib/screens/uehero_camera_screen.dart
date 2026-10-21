import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/career_goal.dart';
import '../models/character_data.dart';
import '../models/flashcard.dart';
import '../models/xp_entry.dart';
import '../services/points_manager.dart';
import '../services/mascot_selection_store.dart';
import '../services/flashcard_service.dart';
import 'flashcard_home_screen.dart';

class UEHeroCameraScreen extends StatefulWidget {
  const UEHeroCameraScreen({
    this.skillTopic,
    this.careerMapMilestoneId,
    super.key,
  });

  final String? skillTopic;
  final String? careerMapMilestoneId;

  @override
  State<UEHeroCameraScreen> createState() => _UEHeroCameraScreenState();
}

class _UEHeroCameraScreenState extends State<UEHeroCameraScreen>
    with WidgetsBindingObserver {
  static const _backgroundColor = Color(0xFF100E19);
  static const _surfaceColor = Color(0xFF211D2B);
  static const _accentColor = Color(0xFFBFA8FF);
  static const _cyanColor = Color(0xFF70D8F2);
  static const _minimumCropSize = 0.08;
  static const _historyKey = 'study_question_history';
  static const _skillPracticeKey = 'study_skill_practice_counts';
  static const _masteryKey = 'career_map_skills';

  final _imagePicker = ImagePicker();
  final _questionController = TextEditingController();
  final _followUpController = TextEditingController();
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
  String _questionText = '';
  String _subject = 'Khác';
  String? _matchedSkill;
  CharacterData _companion = characterData.first;
  CareerGoal? _careerGoal;
  int _thinkingStatus = 0;
  List<String> _solutionSteps = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLearningContext();
    _initializeCamera();
  }

  Future<void> _loadLearningContext() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMascot = (await MascotSelectionStore.instance.read(
      preferences: preferences,
    )).primary;
    final goal = careerGoalByTitle(preferences.getString('career_goal'));
    if (!mounted) return;
    setState(() {
      _companion =
          savedMascot ?? CharacterSelection.selected ?? characterData.first;
      CharacterSelection.selected = _companion;
      _careerGoal = goal;
    });
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
    _questionController.dispose();
    _followUpController.dispose();
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
        _questionText = 'Câu hỏi từ ảnh';
        _step = _CameraStep.confirmImage;
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

  String _normalize(String value) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ắ': 'a',
      'ằ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ấ': 'a',
      'ầ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'đ': 'd',
      'é': 'e',
      'è': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ế': 'e',
      'ề': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'í': 'i',
      'ì': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ó': 'o',
      'ò': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ố': 'o',
      'ồ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ớ': 'o',
      'ờ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ứ': 'u',
      'ừ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ý': 'y',
      'ỳ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
    };
    var normalized = value.toLowerCase();
    replacements.forEach((key, replacement) {
      normalized = normalized.replaceAll(key, replacement);
    });
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _detectSubject(String question) {
    final topic = widget.skillTopic?.trim();
    final source = _normalize(topic?.isNotEmpty == true ? topic! : question);
    const keywords = <String, List<String>>{
      'Kinh tế vi mô': [
        'kinh te vi mo',
        'cung cau',
        'do co dan',
        'chi phi bien',
      ],
      'Kinh tế vĩ mô': [
        'gdp',
        'lam phat',
        'that nghiep',
        'tong cau',
        'tong cung',
      ],
      'Thống kê': ['thong ke', 'trung binh', 'phuong sai', 'do lech chuan'],
      'Kinh tế lượng': ['kinh te luong', 'hoi quy', 'regression', 'ols'],
      'Kế toán': ['ke toan', 'but toan', 'tai khoan', 'bang can doi'],
      'Marketing': ['marketing', 'thuong hieu', 'phan khuc', '4p'],
      'Excel': ['excel', 'ham sum', 'vlookup', 'pivot'],
      'SQL': ['sql', 'select ', 'join ', ' from ', 'where '],
      'Python': ['python', 'def ', 'pandas', 'list comprehension'],
    };
    for (final entry in keywords.entries) {
      if (entry.value.any(source.contains)) return entry.key;
    }
    return topic?.isNotEmpty == true ? topic! : 'Khác';
  }

  String? _findCareerSkill(String subject) {
    final normalizedSubject = _normalize(subject);
    for (final skill in _careerGoal?.skills ?? const <CareerSkill>[]) {
      final normalizedSkill = _normalize(skill.name);
      if (normalizedSkill == normalizedSubject ||
          normalizedSkill.contains(normalizedSubject) ||
          normalizedSubject.contains(normalizedSkill)) {
        return skill.name;
      }
    }
    return null;
  }

  Future<void> _solveQuestion({String? followUp}) async {
    final question = (followUp ?? _questionController.text).trim();
    if (question.isEmpty && _croppedImageBytes == null) {
      _showMessage('Nhập câu hỏi hoặc chụp/chọn ảnh đề bài trước nhé.');
      return;
    }
    if (followUp != null) {
      _questionText = 'Câu hỏi: ${_questionText.trim()}\n\nHỏi tiếp: $question';
      _followUpController.clear();
    } else if (question.isNotEmpty) {
      _questionText = question;
    }
    final subject = _detectSubject(_questionText);
    setState(() {
      _subject = subject;
      _matchedSkill = _findCareerSkill(subject);
      _thinkingStatus = 0;
      _step = _CameraStep.thinking;
    });
    for (var status = 1; status <= 2; status++) {
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      setState(() => _thinkingStatus = status);
    }
    _solutionSteps = _makeSampleSteps(subject, _questionText);
    await _recordPractice(subject);
    if (!mounted) return;
    setState(() {
      _selectedMode = 1;
      _step = _CameraStep.result;
    });
  }

  List<String> _makeSampleSteps(String subject, String question) {
    final excerpt = question.length > 120
        ? '${question.substring(0, 117)}...'
        : question;
    // TODO(rag): replace this sample reasoning and references with the thesis RAG assistant.
    return [
      'Đọc đề: xác định dữ kiện và điều đề bài đang hỏi. Nội dung nhận được: "$excerpt".',
      'Chọn kiến thức "$subject" phù hợp, rồi viết công thức hoặc quy tắc cần dùng.',
      'Thay dữ kiện vào từng bước, tính toán cẩn thận và kiểm tra đơn vị/kết quả.',
      'Kết luận bằng một câu trả lời ngắn, đối chiếu lại với giả thiết ban đầu.',
    ];
  }

  Future<void> _recordPractice(String subject) async {
    final preferences = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final history =
        (jsonDecode(preferences.getString(_historyKey) ?? '[]') as List)
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
    history.insert(0, {
      'date': now.toIso8601String(),
      'subject': subject,
      'summary': _questionText.length > 90
          ? '${_questionText.substring(0, 87)}...'
          : _questionText,
      'skill': _matchedSkill,
    });
    await preferences.setString(
      _historyKey,
      jsonEncode(history.take(100).toList()),
    );

    final skill = _matchedSkill;
    if (skill == null) return;
    final practiceCounts =
        (jsonDecode(preferences.getString(_skillPracticeKey) ?? '{}')
                as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, (value as num).toInt()));
    final count = (practiceCounts[skill] ?? 0) + 1;
    practiceCounts[skill] = count;
    await preferences.setString(_skillPracticeKey, jsonEncode(practiceCounts));
    if (count % 3 != 0) return;

    final mastery =
        (jsonDecode(preferences.getString(_masteryKey) ?? '{}')
                as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, (value as num).toDouble()));
    mastery[skill] = ((mastery[skill] ?? 0) + 0.5).clamp(0.0, 10.0);
    await preferences.setString(_masteryKey, jsonEncode(mastery));
    await _awardDailyPracticePoints(now);
    if (widget.careerMapMilestoneId != null && count >= 3) {
      // TODO(career-map): mark the supplied milestone complete after three practice questions.
    }
  }

  Future<void> _awardDailyPracticePoints(DateTime now) async {
    final added = await PointsManager.instance.addXP(
      thanh: XpBar.thucChien,
      luong: 5,
      nguon: 'skill_practice',
      sourceRef: 'skill-practice-${now.toIso8601String()}',
      at: now,
    );
    if (added > 0) _showMessage('Ba câu luyện kỹ năng · +5 điểm UEHero!');
  }

  Future<void> _saveFlashcard() async {
    final flashcards = FlashcardService.instance;
    await flashcards.initialize();
    final createdAt = DateTime.now();
    await flashcards.addPracticeCards([
      Flashcard(
        id: 'study-buddy-${createdAt.microsecondsSinceEpoch}',
        deckId: FlashcardService.practiceDeckId,
        type: FlashcardType.scenario,
        front: _questionText,
        back: _solutionSteps.join('\n'),
        subTopic: _subject,
        tags: const ['Study Buddy'],
      ),
    ]);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/flashcards'),
        builder: (_) => const FlashcardHomeScreen(),
      ),
    );
    if (mounted) _showMessage('Đã lưu câu hỏi và lời giải vào Flashcard.');
  }

  Future<void> _showStudyHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final history =
        (jsonDecode(preferences.getString(_historyKey) ?? '[]') as List)
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      showDragHandle: true,
      builder: (context) => _StudyHistorySheet(history: history),
    );
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
        _CameraStep.confirmImage => _buildConfirmImageStep(),
        _CameraStep.thinking => _buildThinkingStep(),
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
                  firstLabel: 'Tìm trong kho',
                  secondLabel: 'Giải cùng trợ lý',
                  selectedIndex: _selectedMode,
                  onChanged: (index) => setState(() => _selectedMode = index),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_cameraError case final error?)
                        _buildCameraError(error)
                      else if (_cameraLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 18),
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      else
                        const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: _buildQuestionComposer(),
                      ),
                      _buildLiveCameraControls(),
                    ],
                  ),
                ),
              ),
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
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 14),
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

  Widget _buildQuestionComposer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _questionController,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _solveQuestion(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Hoặc nhập câu hỏi của bạn...',
              hintStyle: const TextStyle(
                color: Color(0xFFAAA5B8),
                fontSize: 12,
              ),
              filled: true,
              fillColor: const Color(0xE6211D2B),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.13),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.13),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _isBusy ? null : _solveQuestion,
          tooltip: 'Gửi câu hỏi',
          style: IconButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: const Color(0xFF211A30),
          ),
          icon: const Icon(Icons.arrow_upward_rounded),
        ),
      ],
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

  Widget _buildConfirmImageStep() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(onBack: () => setState(() => _step = _CameraStep.crop)),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Text(
              'Kiểm tra đề bài đã cắt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  color: _surfaceColor,
                  alignment: Alignment.center,
                  child: _croppedImageBytes == null
                      ? const Text(
                          'Không có ảnh để xem.',
                          style: TextStyle(color: Colors.white70),
                        )
                      : Image.memory(_croppedImageBytes!, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () => setState(() => _step = _CameraStep.liveCamera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Chụp lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isBusy ? null : _solveQuestion,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Gửi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: const Color(0xFF211A30),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingStep() {
    const messages = [
      'Đang đọc câu hỏi...',
      'Đang tìm kiến thức phù hợp...',
      'Đang sắp xếp lời giải từng bước...',
    ];
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(
            onBack: () => setState(() => _step = _CameraStep.liveCamera),
          ),
          const Spacer(),
          CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFF312747),
            child: Text(_companion.emoji, style: const TextStyle(fontSize: 38)),
          ),
          const SizedBox(height: 20),
          Text(
            '${_companion.name} đang suy nghĩ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                messages[_thinkingStatus.clamp(0, messages.length - 1)],
                key: ValueKey(_thinkingStatus),
                style: const TextStyle(color: Color(0xFFCFC7DC)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: _accentColor),
          const Spacer(),
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
          _buildTopBar(
            onBack: () => setState(() => _step = _CameraStep.liveCamera),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModeSwitch(
                    firstLabel: 'Tìm trong kho',
                    secondLabel: 'Giải cùng trợ lý',
                    selectedIndex: _selectedMode,
                    onChanged: (index) => setState(() => _selectedMode = index),
                  ),
                  const SizedBox(height: 14),
                  _buildSolutionCard(imageBytes),
                  const SizedBox(height: 12),
                  if (_selectedMode == 0)
                    _buildSectionCard(
                      title: 'Nguồn trong kho',
                      icon: Icons.menu_book_rounded,
                      child: const Text(
                        'Chưa tìm thấy tài liệu trùng khớp trong kho mẫu.',
                        style: TextStyle(color: Color(0xFFCFC7DC), height: 1.4),
                      ),
                    )
                  else
                    _buildTutorCard(),
                  const SizedBox(height: 12),
                  _buildNextStepActions(),
                  const SizedBox(height: 12),
                  _buildFollowUpComposer(),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Lời giải mang tính tham khảo',
                      style: TextStyle(color: Color(0xFFAAA5B8), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorCard() {
    return _buildSectionCard(
      title: 'Lời giải cùng ${_companion.name}',
      icon: Icons.auto_awesome_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: ModelViewer(
                  key: ValueKey('study-${_companion.modelPath}'),
                  src: _companion.modelPath,
                  alt: _companion.name,
                  autoPlay: true,
                  animationName: _companion.animationName,
                  autoRotate: true,
                  autoRotateDelay: 0,
                  cameraControls: false,
                  disableZoom: true,
                  backgroundColor: Colors.transparent,
                  debugLogging: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _matchedSkill == null
                      ? 'Mình sẽ cùng bạn chia câu hỏi thành các bước nhỏ nhé.'
                      : 'Câu này giúp bạn luyện $_matchedSkill. Mình sẽ cùng bạn đi từng bước nhé.',
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < _solutionSteps.length; index++)
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.white.withValues(alpha: 0.08)),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                iconColor: _cyanColor,
                collapsedIconColor: Colors.white70,
                title: Text(
                  'Bước ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _solutionSteps[index],
                      style: const TextStyle(
                        color: Color(0xFFCFC7DC),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Nguồn tham khảo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '• Giáo trình $_subject đại cương · Chương: Khái niệm và phương pháp cơ bản\n'
            '• Tài liệu học tập UEH · Phần bài tập vận dụng',
            style: const TextStyle(
              color: Color(0xFFCFC7DC),
              height: 1.45,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kiểm tra lại với giáo trình hoặc giảng viên.',
            style: TextStyle(color: Color(0xFFAAA5B8), fontSize: 12),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _reportIncorrectAnswer,
              child: const Text('Báo kết quả sai'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionCard(Uint8List? imageBytes) {
    return _buildSectionCard(
      title: 'Câu hỏi · $_subject',
      icon: Icons.question_answer_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                imageBytes,
                height: 170,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          if (imageBytes != null && _questionText.isNotEmpty)
            const SizedBox(height: 10),
          Text(
            _questionText.isEmpty ? 'Câu hỏi chưa có nội dung.' : _questionText,
            style: const TextStyle(color: Color(0xFFCFC7DC), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildNextStepActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              _solutionSteps = [
                'Nói đơn giản, trước tiên hãy xác định đề đang hỏi điều gì.',
                'Chọn quy tắc "$_subject" liên quan, rồi áp dụng từng bước.',
                'Đọc lại kết quả và so sánh với dữ kiện đề bài.',
              ];
            });
          },
          child: const Text('Giải thích đơn giản hơn'),
        ),
        OutlinedButton(
          onPressed: _showPracticeExercise,
          child: const Text('Cho bài tương tự'),
        ),
        OutlinedButton(
          onPressed: _saveFlashcard,
          child: const Text('Tạo flashcard'),
        ),
      ],
    );
  }

  Widget _buildFollowUpComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _followUpController,
            minLines: 1,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Hỏi tiếp về lời giải...',
              hintStyle: const TextStyle(color: Color(0xFFAAA5B8)),
              filled: true,
              fillColor: _surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onSubmitted: (value) => _solveQuestion(followUp: value),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: () => _solveQuestion(followUp: _followUpController.text),
          icon: const Icon(Icons.send_rounded),
        ),
      ],
    );
  }

  Future<void> _reportIncorrectAnswer() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surfaceColor,
        title: const Text(
          'Báo kết quả sai',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Cảm ơn bạn đã phản hồi. TODO(rag): gửi báo cáo tới hệ thống đánh giá lời giải.',
          style: TextStyle(color: Color(0xFFCFC7DC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPracticeExercise() async {
    final answerController = TextEditingController();
    String? result;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bài luyện tương tự',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_subject · Tính nhanh: 7 + 5 = ?',
                style: const TextStyle(color: Color(0xFFCFC7DC)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: answerController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nhập câu trả lời',
                  hintStyle: TextStyle(color: Color(0xFFAAA5B8)),
                ),
              ),
              if (result != null) ...[
                const SizedBox(height: 12),
                Text(
                  result!,
                  style: TextStyle(
                    color: result!.startsWith('Đúng')
                        ? _cyanColor
                        : const Color(0xFFFFC46B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setSheetState(() {
                    result = answerController.text.trim() == '12'
                        ? 'Đúng rồi! 7 + 5 = 12.'
                        : 'Chưa đúng, thử cộng lần lượt 7 rồi thêm 5 nhé.';
                  }),
                  child: const Text('Kiểm tra đáp án'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    answerController.dispose();
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
          IconButton(
            tooltip: 'Lịch sử học tập',
            onPressed: _showStudyHistory,
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
          ),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF312747),
            child: Text(_companion.emoji),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Đưa câu hỏi cho mình nào',
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

enum _CameraStep { liveCamera, crop, confirmImage, thinking, result }

class _StudyHistorySheet extends StatefulWidget {
  const _StudyHistorySheet({required this.history});

  final List<Map<String, dynamic>> history;

  @override
  State<_StudyHistorySheet> createState() => _StudyHistorySheetState();
}

class _StudyHistorySheetState extends State<_StudyHistorySheet> {
  String _selectedSubject = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final subjects = <String>{
      'Tất cả',
      ...widget.history.map((entry) => entry['subject']?.toString() ?? 'Khác'),
    }.toList();
    final filtered = widget.history.where((entry) {
      return _selectedSubject == 'Tất cả' ||
          entry['subject'] == _selectedSubject;
    }).toList();
    final today = DateTime.now();
    final todaysEntries = widget.history.where((entry) {
      final date = DateTime.tryParse(entry['date']?.toString() ?? '');
      return date != null &&
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    });
    final skillCounts = <String, int>{};
    for (final entry in todaysEntries) {
      final skill = entry['skill']?.toString();
      if (skill != null && skill.isNotEmpty) {
        skillCounts.update(skill, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final practiceSummary = skillCounts.isEmpty
        ? 'Hôm nay bạn chưa luyện câu nào cùng kỹ năng.'
        : 'Hôm nay bạn đã luyện ${skillCounts.values.reduce(math.max)} câu '
              '${skillCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key}.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử học tập',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              practiceSummary,
              style: const TextStyle(color: Color(0xFFCFC7DC)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: subjects.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return ChoiceChip(
                    label: Text(subject),
                    selected: subject == _selectedSubject,
                    onSelected: (_) =>
                        setState(() => _selectedSubject = subject),
                    selectedColor: const Color(0xFFBFA8FF),
                    backgroundColor: const Color(0xFF312D3B),
                    labelStyle: TextStyle(
                      color: subject == _selectedSubject
                          ? const Color(0xFF211A30)
                          : Colors.white,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Chưa có câu hỏi nào trong lịch sử.',
                          style: TextStyle(color: Color(0xFFCFC7DC)),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: Color(0x33FFFFFF)),
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        final date = DateTime.tryParse(
                          entry['date']?.toString() ?? '',
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry['summary']?.toString() ?? 'Câu hỏi',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${entry['subject'] ?? 'Khác'}'
                            '${date == null ? '' : ' · ${date.day}/${date.month}'}',
                            style: const TextStyle(
                              color: Color(0xFFAAA5B8),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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
