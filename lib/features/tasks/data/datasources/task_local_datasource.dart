import 'package:hive/hive.dart';

class TaskLocalDatasource {
  final Box? box;

  TaskLocalDatasource(this.box);

  static String boardKey(String workspaceId) => 'board_$workspaceId';
  static const queueKey = 'queue';

  Future<void> saveBoard(
    String workspaceId,
    List<Map<String, dynamic>> json,
  ) async {
    await box?.put(boardKey(workspaceId), json);
  }

  List<Map<String, dynamic>> loadBoard(String workspaceId) {
    final raw = box?.get(boardKey(workspaceId));
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> enqueque(Map<String, dynamic> op) async {
    final queue = pendingOps();
    queue.add(Map<String, dynamic>.from(op));
    await box?.put(queueKey, queue);
  }

  List<Map<String, dynamic>> pendingOps() {
    final raw = box?.get(queueKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> dequeue(Map<String, dynamic> op) async {
    final queue = pendingOps();
    queue.removeWhere((m) => m['op'] == op['op'] && m['id'] == op['id']);
    await box?.put(queueKey, queue);
  }

  Future<void> clear() async => box?.clear();
}
