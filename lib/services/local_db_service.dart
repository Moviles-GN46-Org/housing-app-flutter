import 'package:hive/hive.dart';
import '../models/local_event.dart';

class LocalDbService {
  static const String boxName = 'pending_locations';


  Future<void> saveLocationEvent(LocalEvent event) async {
    final box = Hive.box<LocalEvent>(boxName);
    await box.put(event.id, event);
  }


  List<LocalEvent> getUnsyncedEvents() {
    final box = Hive.box<LocalEvent>(boxName);
    return box.values.where((e) => !e.isSynced).toList();
  }


  Future<void> markAsSynced(String id) async {
    final box = Hive.box<LocalEvent>(boxName);
    final event = box.get(id);
    if (event != null) {
      event.isSynced = true;
      await event.save(); 
    }
  }

  Future<void> clearSyncedEvents() async {
    final box = Hive.box<LocalEvent>(boxName);
    final syncedIds = box.values
        .where((e) => e.isSynced)
        .map((e) => e.id)
        .toList();
    for (var id in syncedIds) {
      await box.delete(id);
    }
  }
}