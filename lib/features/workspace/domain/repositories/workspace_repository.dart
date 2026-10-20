import 'package:task_sync/features/workspace/domain/entities/workspace.dart';

abstract class WorkspaceRepository {
  Future<List<Workspace>> fetchWorkspaces();
}
