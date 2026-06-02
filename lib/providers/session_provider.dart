import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../utils/constants.dart';

class SessionNotifier extends StateNotifier<List<ChatSession>> {
  Box<ChatSession>? _box;

  SessionNotifier() : super([]);

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ChatMessageAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ChatSessionAdapter());
      }
      _box = await Hive.openBox<ChatSession>(Constants.chatSessionsBoxName);
      state = _box!.values.toList().reversed.toList();
    } catch (e) {
      // If the Hive box is corrupted, start with an empty session list
      // so the app doesn't crash on startup.
      _box = null;
      state = [];
    }
  }

  Future<void> addSession(ChatSession session) async {
    if (_box == null) return;
    await _box!.put(session.id, session);
    state = [session, ...state];
  }

  Future<void> deleteSession(String id) async {
    if (_box == null) return;
    await _box!.delete(id);
    state = state.where((s) => s.id != id).toList();
  }

  Future<void> clearAll() async {
    if (_box == null) return;
    await _box!.clear();
    state = [];
  }

  List<ChatSession> getSessionsForDate(DateTime date) {
    return state.where((s) {
      final d = s.startedAt;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, List<ChatSession>>(
  (ref) => SessionNotifier(),
);
