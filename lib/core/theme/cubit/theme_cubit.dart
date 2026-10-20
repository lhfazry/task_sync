import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_sync/core/theme/cubit/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  void toggle() {
    final isLight = state.mode == AppTheme.light;
    emit(state.copyWith(mode: isLight ? AppTheme.dark : AppTheme.light));
  }

  void setMode(AppTheme mode) {
    emit(state.copyWith(mode: mode));
  }
}
