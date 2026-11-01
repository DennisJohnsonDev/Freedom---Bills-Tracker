import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/colors.dart';
import 'core/theme.dart';
import 'data/hive_init.dart';
import 'data/widget_sync.dart';
import 'features/shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.ensureReady();
  // Fire-and-forget — never block app launch on widget plumbing.
  unawaited(WidgetSync.boot());

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: FreedomApp()));
}

class FreedomApp extends StatelessWidget {
  const FreedomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freedom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const AppShell(),
      scrollBehavior: const _NoGlowBehavior(),
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildOverscrollIndicator(_, Widget child, __) => child;
}
