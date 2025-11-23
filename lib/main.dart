import 'package:fcode_pos/app.dart';
import 'package:fcode_pos/utils/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  await AppInitializer.initialize();
  runApp(const ProviderScope(child: FcodePosApp()));
}
