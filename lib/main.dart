import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/core/local_storage/local_cache_service.dart';
import 'src/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalCacheService().init();
  setupServiceLocator();
  runApp(const App());
}
