import 'package:task_sync/features/workspace/data/models/workspace_model.dart';
import 'package:task_sync/features/workspace/domain/entities/workspace.dart';
import 'package:task_sync/features/workspace/domain/repositories/workspace_repository.dart';

class InMemoryWorkspaceRepository implements WorkspaceRepository {
  @override
  Future<List<Workspace>> fetchWorkspaces() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const [
      WorkspaceModel(
        id: '14ac39e4-aa2f-45d3-923b-09ef1f7773cb',
        name: 'Mobile Team',
        memberCount: 4,
      ),
      //WorkspaceModel(id: 'w2', name: 'Design Guild', memberCount: 2),
    ].map((m) => m.toEntity()).toList();
  }
}
