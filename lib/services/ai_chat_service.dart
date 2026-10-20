import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Connects the Flutter career companion to the locally hosted UEHero backend.
/// Configure via: --dart-define=UEHERO_AI_API_URL=http://127.0.0.1:8000
class AiChatService {
  const AiChatService();

  static const String _baseUrl = String.fromEnvironment(
    'UEHERO_AI_API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  Future<String> ask({
    required String message,
    required List<Map<String, String>> history,
    String appContext = '',
  }) async {
    final uri = Uri.parse('$_baseUrl/chat');
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'history': history,
              'app_context': appContext,
            }),
          )
          .timeout(const Duration(seconds: 160));
    } on TimeoutException {
      throw const AiChatException(
        'AI phản hồi quá lâu. Hãy thử lại với một câu hỏi ngắn hơn.',
      );
    } on http.ClientException {
      throw const AiChatException(
        'Không kết nối được AI. Hãy kiểm tra FastAPI ở cổng 8000 '
        '(hoặc URL bạn cấu hình khi chạy Flutter).',
      );
    } catch (_) {
      throw const AiChatException(
        'Không liên lạc được backend AI. Kiểm tra server đang chạy.',
      );
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw const AiChatException('Backend trả về dữ liệu không hợp lệ.');
    } on TypeError {
      throw const AiChatException('Backend trả về dữ liệu không đúng định dạng.');
    }
    if (response.statusCode != 200) {
      final detail = json['detail'];
      throw AiChatException(
        detail is String ? detail : 'Backend báo lỗi HTTP ${response.statusCode}.',
      );
    }
    final reply = json['reply'];
    if (reply is! String || reply.trim().isEmpty) {
      throw const AiChatException('Model trả về câu trả lời trống.');
    }
    return reply.trim();
  }
}

class AiChatException implements Exception {
  const AiChatException(this.message);
  final String message;

  @override
  String toString() => message;
}
