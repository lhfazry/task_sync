import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:task_sync/features/workspace/domain/entities/workspace.dart';

part 'workspace_model.freezed.dart';
part 'workspace_model.g.dart';

@freezed
abstract class WorkspaceModel with _$WorkspaceModel {
  const factory WorkspaceModel({
    required String id,
    required String name,
    @Default(1) int memberCount,
  }) = _WorkspaceModel;

  const WorkspaceModel._();

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceModelFromJson(json);

  Workspace toEntity() =>
      Workspace(id: id, name: name, memberCount: memberCount);

  factory WorkspaceModel.fromEntity(Workspace workspace) {
    return WorkspaceModel(
      id: workspace.id,
      name: workspace.name,
      memberCount: workspace.memberCount,
    );
  }
}
