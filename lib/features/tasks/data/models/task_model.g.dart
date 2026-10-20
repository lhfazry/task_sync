// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => _TaskModel(
  id: json['id'] as String,
  title: json['title'] as String,
  column: json['column'] as String? ?? 'todo',
  isDone: json['isDone'] as bool? ?? false,
  isSyncing: json['isSyncing'] as bool? ?? false,
);

Map<String, dynamic> _$TaskModelToJson(_TaskModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'column': instance.column,
      'isDone': instance.isDone,
      'isSyncing': instance.isSyncing,
    };
