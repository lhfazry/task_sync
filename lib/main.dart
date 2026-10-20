import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:task_sync/app/app.dart';
import 'package:task_sync/app/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize hive
  await Hive.initFlutter();
  final storeBox = await Hive.openBox('tasksync');

  // initialize supabase
  if (supabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    setupInjection(storeBox: storeBox, useSupabase: true);
  } else {
    setupInjection(storeBox: storeBox);
  }

  runApp(const TaskSyncApp());
}
