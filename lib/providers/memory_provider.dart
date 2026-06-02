import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/memory_profile.dart';
import '../utils/constants.dart';

class MemoryState {
  final String summary;

  const MemoryState({this.summary = ''});
}

class MemoryNotifier extends StateNotifier<MemoryState> {
  Box<MemoryProfile>? _box;

  MemoryNotifier() : super(const MemoryState());

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(MemoryProfileAdapter());
      }
      _box = await Hive.openBox<MemoryProfile>(Constants.memoryBoxName);
      final profile = _box!.get('default');
      if (profile != null) {
        state = MemoryState(summary: profile.summary);
      }
    } catch (e) {
      // If the Hive box is corrupted, start with an empty memory so the
      // app doesn't crash on startup.
      _box = null;
      state = const MemoryState();
    }
  }

  Future<void> update(String newSummary) async {
    if (_box == null) return;
    final profile = MemoryProfile(
      summary: newSummary,
      lastUpdated: DateTime.now(),
    );
    await _box!.put('default', profile);
    state = MemoryState(summary: newSummary);
  }

  Future<void> clear() async {
    if (_box == null) return;
    await _box!.delete('default');
    state = const MemoryState();
  }
}

final memoryProvider = StateNotifierProvider<MemoryNotifier, MemoryState>(
  (ref) => MemoryNotifier(),
);
