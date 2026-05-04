import 'package:hive/hive.dart';

part 'memory_profile.g.dart';

@HiveType(typeId: 5)
class MemoryProfile extends HiveObject {
  @HiveField(0)
  final String summary;

  @HiveField(1)
  final DateTime lastUpdated;

  MemoryProfile({
    required this.summary,
    required this.lastUpdated,
  });
}
