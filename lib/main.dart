import 'package:fcode_pos/app.dart';
import 'package:fcode_pos/utils/app_initializer.dart';
import 'package:fcode_pos/utils/global_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  // Initialize global error handler
  GlobalErrorHandler.initialize();

  await AppInitializer.initialize();
  runApp(const ProviderScope(child: AppwriteApp()));
}
