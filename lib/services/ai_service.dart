import 'package:dio/dio.dart';
import '../models/ai_companion.dart';

class AiService {
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));
  final String _apiKey;
  final String _provider;
  final String _model;

  static const String _geminiApiBase =
      'https://generativelanguage.googleapis.com/v1beta';
  static const Map<String, String> _openAiCompatibleBase = {
    'openai': 'https://api.openai.com/v1',
    'moonshot': 'https://api.moonshot.cn/v1',
  };
  static const Map<String, String> _defaultModel = {
    'gemini': 'gemini-2.5-flash',
    'openai': 'gpt-4o-mini',
    'moonshot': 'moonshot-v1-8k',
  };

  AiService({required String apiKey, String provider = 'gemini', String? model})
      : _apiKey = apiKey,
        _provider = provider,
        _model = model ?? _defaultModel[provider] ?? 'gemini-2.5-flash';

  Future<String> sendMessage({
    required String userMessage,
    required AiCompanion companion,
    String? memorySummary,
  }) async {
    final systemPrompt = companion.buildSystemPrompt(memorySummary);

    final text = _provider == 'gemini'
        ? await _callGemini(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            maxOutputTokens: 300,
            temperature: 0.8,
          )
        : await _callOpenAiCompatible(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            maxTokens: 300,
            temperature: 0.8,
          );
    return text ?? '';
  }

  Future<String> updateMemory({
    required String conversation,
    required AiCompanion companion,
    String? existingMemory,
  }) async {
    try {
      final prompt = companion.buildMemoryUpdatePrompt(conversation, existingMemory);

      final text = _provider == 'gemini'
          ? await _callGemini(userMessage: prompt, maxOutputTokens: 500, temperature: 0.5)
          : await _callOpenAiCompatible(
              userMessage: prompt, maxTokens: 500, temperature: 0.5);
      return text ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String?> _callGemini({
    String? systemPrompt,
    required String userMessage,
    required int maxOutputTokens,
    required double temperature,
  }) async {
    final response = await _dio.post(
      '$_geminiApiBase/models/$_model:generateContent?key=$_apiKey',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        if (systemPrompt != null)
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt}
            ],
          },
        'contents': [
          {
            'parts': [
              {'text': userMessage}
            ],
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxOutputTokens,
        },
      },
    );
    return _extractGeminiText(response.data);
  }

  Future<String?> _callOpenAiCompatible({
    String? systemPrompt,
    required String userMessage,
    required int maxTokens,
    required double temperature,
  }) async {
    final base = _openAiCompatibleBase[_provider];
    if (base == null) {
      throw Exception('不支援的 AI 提供者：$_provider');
    }
    final response = await _dio.post(
      '$base/chat/completions',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      }),
      data: {
        'model': _model,
        'messages': [
          if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
    );
    return _extractOpenAiText(response.data);
  }

  String? _extractGeminiText(dynamic data) {
    final candidates = data?['candidates'] as List<dynamic>?;
    final first = candidates?.firstOrNull as Map<String, dynamic>?;
    final content = first?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.firstOrNull?['text'] as String?;
    return text?.trim();
  }

  String? _extractOpenAiText(dynamic data) {
    final choices = data?['choices'] as List<dynamic>?;
    final first = choices?.firstOrNull as Map<String, dynamic>?;
    final message = first?['message'] as Map<String, dynamic>?;
    final text = message?['content'] as String?;
    return text?.trim();
  }
}
