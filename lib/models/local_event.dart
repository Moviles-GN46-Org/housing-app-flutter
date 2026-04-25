import 'package:hive/hive.dart';
part 'local_event.g.dart';

@HiveType(typeId: 0)
class LocalEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double lat;

  @HiveField(2)
  final double lng;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  bool isSynced;

  LocalEvent({
    required this.id,
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.isSynced = false,
  });
}