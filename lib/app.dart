import 'package:fcode_pos/appwrite.dart';
import 'package:fcode_pos/providers/theme_provider.dart';
import 'package:fcode_pos/screens/splash_screen.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppwriteApp extends ConsumerWidget {
  const AppwriteApp({super.key});

  ThemeData _buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'GoogleSans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: base.colorScheme.surface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: base.colorScheme.onPrimary,
        ),
      ),
      inputDecorationTheme: _buildInputDecorationTheme(
        base.inputDecorationTheme,
        base.colorScheme,
      ),
      appBarTheme: base.appBarTheme.copyWith(elevation: 0, centerTitle: false),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'GoogleSans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: base.colorScheme.surface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: base.colorScheme.onPrimary,
        ),
      ),
      inputDecorationTheme: _buildInputDecorationTheme(
        base.inputDecorationTheme,
        base.colorScheme,
      ),
      appBarTheme: base.appBarTheme.copyWith(elevation: 0, centerTitle: false),
    );
  }

  InputDecorationThemeData _buildInputDecorationTheme(
    InputDecorationThemeData baseTheme,
    ColorScheme colorScheme,
  ) {
    const inputRadius = BorderRadius.all(Radius.circular(12));
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: BorderSide(color: color),
    );

    return baseTheme.copyWith(
      border: outline(colorScheme.outlineVariant),
      enabledBorder: outline(colorScheme.outlineVariant),
      disabledBorder: outline(colorScheme.outlineVariant.applyOpacity(0.5)),
      focusedBorder: outline(colorScheme.primary),
      errorBorder: outline(colorScheme.error),
      focusedErrorBorder: outline(colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
        title: 'FCODE Pos',
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: themeMode,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
