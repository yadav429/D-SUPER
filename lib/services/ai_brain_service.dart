import 'dart:convert';

import 'package:http/http.dart' as http;

/// Hybrid assistant: use the configured secure backend when available,
/// otherwise provide a small, honest offline command/help layer.
class AiBrainService {
  AiBrainService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _baseUrl = String.fromEnvironment('AI_API_BASE_URL');

  Future<AiReply> ask(String message, {required bool hindi}) async {
    final clean = message.trim();
    if (clean.isEmpty) {
      return AiReply(
        text: hindi ? 'कृपया अपना सवाल लिखें।' : 'Please enter a question.',
        online: false,
      );
    }

    if (_baseUrl.isNotEmpty) {
      try {
        final uri = Uri.parse('${_baseUrl.replaceFirst(RegExp(r'/+$'), '')}/v1/chat');
        final response = await _client
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'message': clean,
                'language': hindi ? 'hi' : 'en',
              }),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            final answer = (data['answer'] ?? data['reply'] ?? data['message'])
                ?.toString()
                .trim();
            if (answer != null && answer.isNotEmpty) {
              return AiReply(text: answer, online: true);
            }
          }
          throw const FormatException('Backend response has no answer field.');
        }
        throw Exception('AI server returned HTTP ${response.statusCode}.');
      } catch (_) {
        // Fall through to offline mode if the network/server is unavailable.
      }
    }

    return AiReply(
      text: _offlineAnswer(clean, hindi),
      online: false,
    );
  }

  String _offlineAnswer(String message, bool hindi) {
    final q = message.toLowerCase().trim();

    if (RegExp(r'^(hi|hello|hey|नमस्ते|नमस्कार|हेलो)[!. ]*$').hasMatch(q)) {
      return hindi
          ? 'नमस्ते! मैं D-SUPER का Offline AI Brain हूँ। मैं बेसिक कमांड और मदद दे सकता हूँ।'
          : 'Hello! I am D-SUPER Offline AI Brain. I can help with basic commands.';
    }
    if (q.contains('time') || q.contains('समय')) {
      final now = DateTime.now();
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      return hindi ? 'अभी समय $time है।' : 'The current device time is $time.';
    }
    if (q.contains('date') || q.contains('तारीख') || q.contains('आज कौन सा दिन')) {
      final now = DateTime.now();
      return hindi
          ? 'आज ${now.day}-${now.month}-${now.year} है।'
          : 'Today is ${now.day}-${now.month}-${now.year}.';
    }
    if (q.contains('calculator') || q.contains('कैलकुलेटर')) {
      return hindi
          ? 'कैलकुलेटर खोलने के लिए डैशबोर्ड में Calculator मॉड्यूल चुनें।'
          : 'Open the Calculator module from the dashboard.';
    }
    if (q.contains('offline') || q.contains('ऑफलाइन')) {
      return hindi
          ? 'Offline mode में बेसिक कमांड और डिवाइस की तारीख/समय उपलब्ध हैं। विस्तृत AI जवाब के लिए इंटरनेट और सुरक्षित AI backend चाहिए।'
          : 'Offline mode supports basic commands and device date/time. Advanced AI answers need internet and a configured secure backend.';
    }
    return hindi
        ? 'अभी Online AI server configure नहीं है या उपलब्ध नहीं है। Offline mode में मैं सीमित मदद कर सकता हूँ। Advanced जवाबों के लिए AI backend URL configure करना होगा।'
        : 'The online AI server is not configured or is unavailable. I can provide limited offline help. Configure the AI backend URL for advanced answers.';
  }

  void dispose() => _client.close();
}

class AiReply {
  const AiReply({required this.text, required this.online});
  final String text;
  final bool online;
}
