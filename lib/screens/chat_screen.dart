import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/emotion_type.dart';
import '../providers/chat_provider.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _speech = SpeechToText();
  bool _isListening = false;

  // Typing effect state
  final Map<String, int> _typingProgress = {};
  final Set<String> _completedTyping = {};
  final _random = Random();
  Timer? _typingTimer;
  String? _currentlyTypingId;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForNewAiMessages());
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkForNewAiMessages() {
    final messages = ref.read(chatProvider).messages;
    if (messages.isEmpty) return;

    final lastMsg = messages.last;
    if (lastMsg.isUser) return;
    if (_completedTyping.contains(lastMsg.id)) return;
    if (_currentlyTypingId == lastMsg.id) return;

    // Start typing effect for this new AI message
    _startTypingEffect(lastMsg.id, lastMsg.content);
  }

  void _startTypingEffect(String messageId, String fullText) {
    _typingTimer?.cancel();
    _currentlyTypingId = messageId;
    _typingProgress[messageId] = 0;

    _typeNextChar(messageId, fullText, 0);
  }

  void _typeNextChar(String messageId, String fullText, int index) {
    if (index >= fullText.length) {
      _completedTyping.add(messageId);
      _currentlyTypingId = null;
      _typingProgress.remove(messageId);
      if (mounted) setState(() {});
      return;
    }

    final delay = _computeTypingDelay(fullText, index);

    _typingTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      if (_currentlyTypingId != messageId) return;

      _typingProgress[messageId] = index + 1;
      setState(() {});
      _scrollToBottom();

      _typeNextChar(messageId, fullText, index + 1);
    });
  }

  int _computeTypingDelay(String text, int index) {
    final char = text[index];
    final remaining = text.length - index;

    // Base delay: 30-55ms
    var delay = 30 + _random.nextInt(25);

    // Punctuation pause
    if ('。，！？；：'.contains(char)) {
      delay += 150 + _random.nextInt(200);
    }

    // Newline pause
    if (char == '\n') {
      delay += 200 + _random.nextInt(200);
    }

    // Long sentence: slightly faster
    if (remaining > 40) delay -= 5;
    // Short sentence: slightly slower
    if (remaining < 15) delay += 10;

    return delay.clamp(15, 500);
  }

  Future<void> _startListening() async {
    if (!_speech.isAvailable) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        _textController.text = result.recognizedWords;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      },
      localeId: 'zh_TW',
    );
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('結束對話'),
        content: const Text('結束後我會記住我們聊過的事，下次再聊時我會記得。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('繼續聊'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('結束', style: TextStyle(color: Color(0xFFE94560))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final chatState = ref.read(chatProvider);
    if (chatState.messages.isEmpty) return;

    // Ask for emotion tag
    if (!mounted) return;
    final emotion = await showDialog<EmotionType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('這次對話主要的情緒是？'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmotionType.values.map((e) {
            return ActionChip(
              avatar: Text(e.emoji),
              label: Text(e.label),
              onPressed: () => Navigator.pop(context, e),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('跳過'),
          ),
        ],
      ),
    );

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    // Update memory
    final updatedMemory = await ref.read(chatProvider.notifier).endSession();

    // Save session
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: chatState.messages.first.createdAt,
      endedAt: DateTime.now(),
      messages: List.from(chatState.messages),
      taggedEmotion: emotion,
    );
    await ref.read(sessionProvider.notifier).addSession(session);

    // Reset chat
    ref.read(chatProvider.notifier).startNewSession();

    if (mounted) {
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedMemory != null ? '對話已儲存，我記住了 ✨' : '對話已儲存'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider);
    final companionName = settings.companionName;

    return Scaffold(
      appBar: AppBar(
        title: Text('💬 $companionName'),
        actions: [
          if (chatState.messages.isNotEmpty)
            TextButton(
              onPressed: _endSession,
              child: const Text('結束對話', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          if (chatState.isLoading || _currentlyTypingId != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTypingBubble(),
                ],
              ),
            ),
          if (chatState.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final settings = ref.watch(settingsProvider);
    final hasApi = settings.hasApiKey;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            hasApi ? '嗨，我是 ${settings.companionName}' : '需要先設定 AI API',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            hasApi
                ? '有什麼想說的，都可以跟我說。'
                : '請到「設定」頁面輸入 API Key，我才能陪你聊天。',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (!hasApi) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to settings tab - need to find a way
                // For now just show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請點下方「設定」頁籤')),
                );
              },
              child: const Text('去設定'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final isTyping = _typingProgress.containsKey(msg.id) && !_completedTyping.contains(msg.id);
    final displayText = isTyping
        ? msg.content.substring(0, _typingProgress[msg.id]!.clamp(0, msg.content.length))
        : msg.content;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF3A3A5C)
              : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: isUser
              ? null
              : Border.all(color: const Color(0xFF333355)),
        ),
        child: Text.rich(
          TextSpan(
            text: displayText,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
            ),
            children: isTyping
                ? [
                    WidgetSpan(
                      child: _BlinkingCursor(),
                      alignment: PlaceholderAlignment.middle,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: const Radius.circular(4),
        ),
        border: Border.all(color: const Color(0xFF333355)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypingDot(delay: 0),
          const SizedBox(width: 4),
          _TypingDot(delay: 200),
          const SizedBox(width: 4),
          _TypingDot(delay: 400),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final settings = ref.watch(settingsProvider);
    final hasApi = settings.hasApiKey;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? const Color(0xFFE94560) : Colors.grey,
              ),
              onPressed: _isListening ? _stopListening : _startListening,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                enabled: hasApi,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: hasApi
                      ? '說點什麼...'
                      : '請先設定 API Key',
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF00B894)),
              onPressed: hasApi ? _sendMessage : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: const Text(
            '|',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF00B894),
              fontWeight: FontWeight.w300,
            ),
          ),
        );
      },
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.7),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
