import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      text: 'Chào bạn! Mình là UEH AI Assistant. Bạn có thể hỏi về học tập, sự kiện và cuộc sống tại UEH.',
      fromAssistant: true,
    ),
    const _ChatMessage(
      text: 'Khung chat chưa kết nối dịch vụ AI. Tin nhắn bạn nhập hiện chỉ hiển thị trên thiết bị này.',
      fromAssistant: true,
      isNotice: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, fromAssistant: false));
      _messageController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100E19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191622),
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFBFA8FF),
              child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF211A35)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UEH AI Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Trợ lý đồng hành',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB5B0C1)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              itemCount: _messages.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _MessageBubble(message: _messages[index]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
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
                    onPressed: _sendMessage,
                    tooltip: 'Gửi tin nhắn',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFBFA8FF),
                      foregroundColor: const Color(0xFF211A35),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

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
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            border: message.isNotice
                ? Border.all(
                    color: const Color(0xFF8F79C6).withValues(alpha: 0.4),
                  )
                : null,
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.isNotice ? const Color(0xFFD3C7F3) : Colors.white,
              fontSize: 14,
              height: 1.45,
            ),
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
  });

  final String text;
  final bool fromAssistant;
  final bool isNotice;
}
