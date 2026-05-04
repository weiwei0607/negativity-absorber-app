import 'package:dio/dio.dart';
import '../models/ai_companion.dart';

class AiService {
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));
  final String _proxyUrl;

  AiService({String proxyUrl = 'http://localhost:3000'}) : _proxyUrl = proxyUrl;

  /// Send a single chat message and get AI response
  Future<String> sendMessage({
    required String userMessage,
    required AiCompanion companion,
    String? memorySummary,
    String? provider,
    String? model,
  }) async {
    final systemPrompt = companion.buildSystemPrompt(memorySummary);

    final response = await _dio.post(
      '$_proxyUrl/api/chat',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'provider': provider ?? 'gemini',
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.8,
        'max_tokens': 300,
      },
    );

    return (response.data['content'] as String).trim();
  }

  /// Update memory profile based on conversation history
  Future<String> updateMemory({
    required String conversation,
    required AiCompanion companion,
    String? existingMemory,
    String? provider,
    String? model,
  }) async {
    final prompt = companion.buildMemoryUpdatePrompt(conversation, existingMemory);

    final response = await _dio.post(
      '$_proxyUrl/api/chat',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'provider': provider ?? 'gemini',
        'model': model,
        'messages': [
          {'role': 'system', 'content': '你是一個擅長整理記憶的助手。'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.5,
        'max_tokens': 500,
      },
    );

    return (response.data['content'] as String).trim();
  }
}
