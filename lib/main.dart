import 'package:fcode_pos/app.dart';
import 'package:fcode_pos/providers/theme_provider.dart';
import 'package:fcode_pos/utils/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await AppInitializer.initialize(themeMode: container.read(themeModeProvider));
  runApp(const ProviderScope(child: FcodePosApp()));
}
