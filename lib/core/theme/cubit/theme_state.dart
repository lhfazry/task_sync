import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AppTheme { light, dark }

class ThemeState extends Equatable {
  final AppTheme mode;
  final ThemeMode themeMode;

  const ThemeState({
    this.mode = AppTheme.light,
    this.themeMode = ThemeMode.light,
  });

  ThemeState copyWith({AppTheme? mode, ThemeMode? themeMode}) {
    return ThemeState(
      mode: mode ?? this.mode,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [mode, themeMode];
}
