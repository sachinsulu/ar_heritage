// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/utils/classifier.dart';
import 'core/services/recents_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final classifierOk = await Classifier.instance.init();
  AppBootstrap.classifierReady = classifierOk;
  AppBootstrap.classifierError =
      classifierOk ? null : Classifier.instance.initError;

  await RecentsService.instance.init();

  runApp(const ArHeritageApp());
}

class ArHeritageApp extends StatelessWidget {
  const ArHeritageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smarter Heritage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
