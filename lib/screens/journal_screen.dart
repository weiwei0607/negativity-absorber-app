import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/session_provider.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../services/export_service.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 對話紀錄'),
        actions: [
          if (sessions.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'export_text') {
                  await ExportService.exportToText(sessions);
                } else if (value == 'export_pdf') {
                  await ExportService.exportToPdf(sessions);
                } else if (value == 'clear') {
                  _confirmClear(context, ref);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'export_text', child: Text('📄 匯出文字')),
                const PopupMenuItem(value: 'export_pdf', child: Text('📑 匯出 PDF')),
                const PopupMenuItem(value: 'clear', child: Text('🗑️ 清空紀錄')),
              ],
            ),
        ],
      ),
      body: sessions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '還沒有對話紀錄',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '去「聊天」頁面開始對話吧！',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Dismissible(
                  key: Key(session.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(sessionProvider.notifier).deleteSession(session.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已刪除')),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF3A3A5C),
                        child: Text('${session.messages.length}'),
                      ),
                      title: Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(session.startedAt),
                        style: const TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        session.messages.isNotEmpty
                            ? (session.messages.first.content.length > 30
                                ? '${session.messages.first.content.substring(0, 30)}...'
                                : session.messages.first.content)
                            : '無訊息',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => _openSessionDetail(context, session),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _openSessionDetail(BuildContext context, ChatSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(session: session),
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空紀錄'),
        content: const Text('確定要刪除所有對話紀錄嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(sessionProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class SessionDetailScreen extends StatelessWidget {
  final ChatSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MM/dd HH:mm').format(session.startedAt)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: session.messages.length,
        itemBuilder: (context, index) {
          final msg = session.messages[index];
          return _buildMessageBubble(context, msg);
        },
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg) {
    final isUser = msg.isUser;
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
          border: isUser ? null : Border.all(color: const Color(0xFF333355)),
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
