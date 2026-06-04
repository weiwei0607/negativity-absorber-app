import 'package:dio/dio.dart';
import '../models/ai_companion.dart';

class AiService {
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));
  final String _apiKey;
  final String _model;

  static const String _apiBase = 'https://generativelanguage.googleapis.com/v1beta';

  AiService({required String apiKey, String model = 'gemini-2.5-flash'})
      : _apiKey = apiKey,
        _model = model;

  Future<String> sendMessage({
    required String userMessage,
    required AiCompanion companion,
    String? memorySummary,
  }) async {
    try {
      final systemPrompt = companion.buildSystemPrompt(memorySummary);

      final response = await _dio.post(
        '$_apiBase/models/$_model:generateContent?key=$_apiKey',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'systemInstruction': {
            'parts': [{'text': systemPrompt}],
          },
          'contents': [
            {
              'parts': [{'text': userMessage}],
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 300,
          },
        },
      );

      final text = _extractText(response.data);
      return text ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> updateMemory({
    required String conversation,
    required AiCompanion companion,
    String? existingMemory,
  }) async {
    try {
      final prompt = companion.buildMemoryUpdatePrompt(conversation, existingMemory);

      final response = await _dio.post(
        '$_apiBase/models/$_model:generateContent?key=$_apiKey',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'contents': [
            {
              'parts': [{'text': prompt}],
            }
          ],
          'generationConfig': {
            'temperature': 0.5,
            'maxOutputTokens': 500,
          },
        },
      );

      final text = _extractText(response.data);
      return text ?? '';
    } catch (e) {
      return '';
    }
  }

  String? _extractText(dynamic data) {
    final candidates = data?['candidates'] as List<dynamic>?;
    final first = candidates?.firstOrNull as Map<String, dynamic>?;
    final content = first?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.firstOrNull?['text'] as String?;
    return text?.trim();
  }
}
