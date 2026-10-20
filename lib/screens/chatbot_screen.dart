import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/character_data.dart';
import '../services/ai_chat_service.dart';
import '../services/companion_context_service.dart';
import '../services/mascot_selection_store.dart';
import 'calendar_screen.dart';
import 'flashcard_home_screen.dart';
import '../home_event_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({this.initialPrompt, super.key});

  final String? initialPrompt;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const _historyKey = 'companion_chat_history_v1';

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  final _aiService = const AiChatService();
  bool _isSending = false;
  CharacterData? _companion;
  CompanionContext? _contextData;
  Future<void> _persistQueue = Future.value();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.initialPrompt ?? '';
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final rawHistory = prefs.getString(_historyKey);
    final mascotSelection = await MascotSelectionStore.instance.read(
      preferences: prefs,
    );
    final contextData = await CompanionContextService.instance.load();
    final history = rawHistory == null
        ? <_ChatMessage>[]
        : (jsonDecode(rawHistory) as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(_ChatMessage.fromJson)
              .toList();
    if (!mounted) return;
    setState(() {
      _messages.addAll(history);
      _companion = mascotSelection.aiCompanion;
      _contextData = contextData;
      if (_messages.isEmpty) {
        _messages.add(
          _ChatMessage(
            text:
                'Chào bạn! Mình là ${mascotSelection.aiCompanion?.name ?? 'bạn đồng hành'}.\n'
                'Ngữ cảnh hiện tại: ${contextData.summary}',
            fromAssistant: true,
            isNotice: true,
          ),
        );
      }
      _loading = false;
    });
    if (rawHistory == null) _persistHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_isSending || _loading) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    FocusScope.of(context).unfocus();
    if (const {
      'Hôm nay có gì?',
      'Còn bao nhiêu thẻ chưa học?',
      'Cuộc thi sắp hết hạn?',
      'Nên làm gì trước?',
    }.contains(text)) {
      await _answerQuickQuestion(text);
      return;
    }

    // Send only conversation turns (not notices) to preserve chat context.
    final history = _messages
        .where((message) => !message.isNotice)
        .map((message) => {
              'role': message.fromAssistant ? 'assistant' : 'user',
              'content': message.text,
            })
        .toList()
        .reversed
        .take(10)
        .toList()
        .reversed
        .toList();

    setState(() {
      _messages.add(_ChatMessage(text: text, fromAssistant: false));
      _isSending = true;
    });
    _scrollToBottom();
    try {
      final answer = await _aiService.ask(
        message: text,
        history: history,
        appContext: _contextData?.summary ?? '',
      );
      if (!mounted) return;
      setState(() => _messages.add(
        _ChatMessage(text: answer, fromAssistant: true),
      ));
    } on AiChatException catch (error) {
      if (!mounted) return;
      setState(() => _messages.add(
        _ChatMessage(text: error.message, fromAssistant: true, isNotice: true),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.add(const _ChatMessage(
        text: 'Không thể nhận phản hồi AI. Kiểm tra backend và thử lại.',
        fromAssistant: true,
        isNotice: true,
      )));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        await _persistHistory();
        _scrollToBottom();
      }
    }
  }

  void _askSuggestion(String suggestion) {
    if (_isSending || _loading) return;
    _messageController.text = suggestion;
    _sendMessage();
  }

  Future<void> _answerQuickQuestion(String question) async {
    if (_isSending || _loading) return;
    final data = _contextData ?? await CompanionContextService.instance.load();
    if (!mounted) return;
    final route = _routeForQuestion(question, data);
    setState(() {
      _messages.add(_ChatMessage(text: question, fromAssistant: false));
      _messages.add(
        _ChatMessage(
          text: data.answerFor(question),
          fromAssistant: true,
          actionLabel: route == null ? null : _labelForRoute(route),
          actionRoute: route,
        ),
      );
      _contextData = data;
    });
    await _persistHistory();
    _scrollToBottom();
  }

  String? _routeForQuestion(String question, CompanionContext data) {
    final normalized = question.toLowerCase();
    if (normalized.contains('thẻ')) return '/flashcards';
    if (normalized.contains('cuộc thi')) return '/events';
    if (normalized.contains('trước') &&
        data.dueCards > 0 &&
        data.todayTasks.isEmpty &&
        data.overdueTasks.isEmpty) {
      return '/flashcards';
    }
    return '/weekly-plan';
  }

  String _labelForRoute(String route) => switch (route) {
    '/flashcards' => 'Mở Flashcard',
    '/events' => 'Mở Cuộc thi',
    _ => 'Mở Weekly Plan',
  };

  Future<void> _persistHistory() {
    final snapshot = _messages
        .skip((_messages.length - 100).clamp(0, _messages.length))
        .map((message) => message.toJson())
        .toList(growable: false);
    _persistQueue = _persistQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(snapshot));
    });
    return _persistQueue;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _openRoute(String route) {
    final page = switch (route) {
      '/flashcards' => const FlashcardHomeScreen(),
      '/events' => const HomeEventScreen(),
      _ => const CalendarScreen(),
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: route),
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companion = _companion;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleSpacing: 8,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF34284C),
              child: companion == null
                  ? const Icon(Icons.pets, color: Color(0xFFBFA8FF))
                  : ClipOval(
                      child: Image.asset(
                        companion.previewAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stack) =>
                            const Icon(Icons.pets, color: Color(0xFFBFA8FF)),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companion?.name ?? 'Bạn đồng hành AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Trợ lý đồng hành',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB5B0C1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildQuickQuestions(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFBFA8FF),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _messages.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => _MessageBubble(
                        message: _messages[index],
                        onAction: _openRoute,
                      ),
                    ),
            ),
            if (_isSending)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFBFA8FF),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'UEHero AI đang trả lời...',
                      style: TextStyle(color: Color(0xFFB5B0C1), fontSize: 12),
                    ),
                  ],
                ),
              ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() => SizedBox(
    height: 54,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      children: [
        'Có sự kiện nghề nghiệp nào phù hợp?',
        'Luyện phỏng vấn Business Analyst intern',
        'CV thực tập nên viết thế nào?',
        'Hôm nay có gì?',
        'Còn bao nhiêu thẻ chưa học?',
        'Cuộc thi sắp hết hạn?',
        'Nên làm gì trước?',
      ].map((question) {
        final isLocalQuestion = const {
          'Hôm nay có gì?',
          'Còn bao nhiêu thẻ chưa học?',
          'Cuộc thi sắp hết hạn?',
          'Nên làm gì trước?',
        }.contains(question);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ActionChip(
            backgroundColor: const Color(0xFF29233A),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            label: Text(
              question,
              style: const TextStyle(color: Color(0xFFE9E2FF), fontSize: 12),
            ),
            onPressed: _loading || _isSending
                ? null
                : () => isLocalQuestion
                    ? _answerQuickQuestion(question)
                    : _askSuggestion(question),
          ),
        );
      }).toList(),
    ),
  );

  Widget _buildComposer() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập câu hỏi của bạn...',
              hintStyle: const TextStyle(color: Color(0xFF9993A8)),
              filled: true,
              fillColor: const Color(0xFF211E2D),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        IconButton.filled(
          onPressed: _isSending || _loading ? null : _sendMessage,
          tooltip: 'Gửi tin nhắn',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFBFA8FF),
            foregroundColor: const Color(0xFF211A35),
          ),
          icon: const Icon(Icons.arrow_upward_rounded),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onAction});

  final _ChatMessage message;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final alignment = message.fromAssistant
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final bubbleColor = message.isNotice
        ? const Color(0xFF29233A)
        : message.fromAssistant
        ? const Color(0xFF211E2D)
        : const Color(0xFF6952A5);
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.84,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            border: message.isNotice
                ? Border.all(color: const Color(0x668F79C6))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: message.isNotice
                      ? const Color(0xFFD3C7F3)
                      : Colors.white,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              if (message.actionLabel != null && message.actionRoute != null)
                TextButton.icon(
                  onPressed: () => onAction(message.actionRoute!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(message.actionLabel!),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFCFBBFF),
                    padding: const EdgeInsets.only(top: 8),
                    minimumSize: const Size(44, 44),
                    alignment: Alignment.centerLeft,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromAssistant,
    this.isNotice = false,
    this.actionLabel,
    this.actionRoute,
  });

  final String text;
  final bool fromAssistant;
  final bool isNotice;
  final String? actionLabel;
  final String? actionRoute;

  Map<String, Object?> toJson() => {
    'text': text,
    'fromAssistant': fromAssistant,
    'isNotice': isNotice,
    'actionLabel': actionLabel,
    'actionRoute': actionRoute,
  };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
    text: json['text'] as String,
    fromAssistant: json['fromAssistant'] as bool,
    isNotice: json['isNotice'] as bool? ?? false,
    actionLabel: json['actionLabel'] as String?,
    actionRoute: json['actionRoute'] as String?,
  );
}
