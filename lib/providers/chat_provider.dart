import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/ai_companion.dart';
import '../services/ai_service.dart';
import 'settings_provider.dart';
import 'memory_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;

  ChatNotifier(this._ref) : super(const ChatState());

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      isUser: true,
      content: text.trim(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    final settings = _ref.read(settingsProvider);
    final memory = _ref.read(memoryProvider);

    if (!settings.hasApiKey) {
      state = state.copyWith(
        isLoading: false,
        error: '尚未設定 Gemini API Key，請到設定頁面設定。',
      );
      return;
    }

    try {
      final companion = AiCompanion(name: settings.companionName);
      final ai = AiService(apiKey: settings.apiKey, model: settings.aiModel ?? 'gemini-2.5-flash');
      final response = await ai.sendMessage(
        userMessage: text.trim(),
        companion: companion,
        memorySummary: memory.summary.isNotEmpty ? memory.summary : null,
      );

      final aiMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        createdAt: DateTime.now(),
        isUser: false,
        content: response,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'AI 回應失敗：$e\n\n請確認 API Key 是否正確，或稍後再試。',
      );
    }
  }

  void startNewSession() {
    state = const ChatState();
  }

  void loadSessionMessages(List<ChatMessage> messages) {
    state = ChatState(messages: messages);
  }

  Future<String?> endSession() async {
    if (state.messages.isEmpty) return null;

    final settings = _ref.read(settingsProvider);
    final memoryNotifier = _ref.read(memoryProvider.notifier);
    final memory = _ref.read(memoryProvider);

    String? updatedMemory;

    if (settings.hasApiKey) {
      try {
        final conversation = _formatConversationForMemory(state.messages);
        final companion = AiCompanion(name: settings.companionName);
        final ai = AiService(apiKey: settings.apiKey, model: settings.aiModel ?? 'gemini-2.5-flash');
        updatedMemory = await ai.updateMemory(
          conversation: conversation,
          companion: companion,
          existingMemory: memory.summary.isNotEmpty ? memory.summary : null,
        );
        await memoryNotifier.update(updatedMemory);
      } catch (e) {
        // Memory update failed, but we still save the session
      }
    }

    return updatedMemory;
  }

  String _formatConversationForMemory(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    for (final msg in messages) {
      final role = msg.isUser ? '朋友' : '阿樹';
      buffer.write('$role：${msg.content}\n');
    }
    return buffer.toString();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);
