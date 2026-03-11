import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fcode_pos/appwrite.dart';
import 'package:fcode_pos/config/environment.dart';
import 'package:fcode_pos/providers/theme_provider.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/screens/splash_screen.dart';
import 'package:fcode_pos/services/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcodePosApp extends ConsumerWidget {
  const FcodePosApp({super.key});

  ThemeData _buildLightTheme(Color seedColor) {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'MomoTrustSans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      colorScheme: base.colorScheme,
      textTheme: base.textTheme
          .copyWith(
            bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 13),
            bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12),
            labelLarge: base.textTheme.labelLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            labelMedium: base.textTheme.labelMedium?.copyWith(fontSize: 12),
          )
          .apply(
            bodyColor: base.colorScheme.onSurface,
            displayColor: base.colorScheme.onSurface,
          ),
      scaffoldBackgroundColor: base.colorScheme.surface,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: base.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        foregroundColor: base.colorScheme.onSurface,
      ),
      cardTheme:
          CardThemeData(
                color: base.colorScheme.surfaceContainerLowest,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              )
              as dynamic,
      inputDecorationTheme:
          _buildInputDecorationTheme(
                base.inputDecorationTheme,
                base.colorScheme,
              )
              as dynamic,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: 60,
        backgroundColor: base.colorScheme.surface,
        indicatorColor: base.colorScheme.secondaryContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  ThemeData _buildDarkTheme(Color seedColor) {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'MomoTrustSans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      colorScheme: base.colorScheme,
      textTheme: base.textTheme
          .copyWith(
            bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 13),
            bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12),
            labelLarge: base.textTheme.labelLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            labelMedium: base.textTheme.labelMedium?.copyWith(fontSize: 12),
          )
          .apply(
            bodyColor: base.colorScheme.onSurface,
            displayColor: base.colorScheme.onSurface,
          ),
      scaffoldBackgroundColor: base.colorScheme.surface,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: base.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        foregroundColor: base.colorScheme.onSurface,
      ),
      cardTheme:
          CardThemeData(
                color: base.colorScheme.surfaceContainerHigh,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              )
              as dynamic,
      inputDecorationTheme:
          _buildInputDecorationTheme(
                base.inputDecorationTheme,
                base.colorScheme,
              )
              as dynamic,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: 60,
        backgroundColor: base.colorScheme.surface,
        indicatorColor: base.colorScheme.secondaryContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  dynamic _buildInputDecorationTheme(
    dynamic baseTheme,
    ColorScheme colorScheme,
  ) {
    const inputRadius = BorderRadius.all(Radius.circular(10));
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return baseTheme.copyWith(
      isDense: true,
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      border: outline(colorScheme.outlineVariant.withOpacity(0.5)),
      enabledBorder: outline(colorScheme.outlineVariant.withOpacity(0.5)),
      disabledBorder: outline(colorScheme.outlineVariant.withOpacity(0.3)),
      focusedBorder: outline(colorScheme.primary, 1.2),
      errorBorder: outline(colorScheme.error),
      focusedErrorBorder: outline(colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final seedColorIndex = ref.watch(themeSeedColorIndexProvider);
    int clampedIndex = seedColorIndex;
    if (clampedIndex < 0) {
      clampedIndex = 0;
    } else if (clampedIndex >= material3SeedColors.length) {
      clampedIndex = material3SeedColors.length - 1;
    }
    final seedColor = material3SeedColors[clampedIndex];

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
        title: Environment.appName,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(seedColor),
        darkTheme: _buildDarkTheme(seedColor),
        themeMode: themeMode,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        onGenerateRoute: _onGenerateRoute,
        home: const _DeepLinkWrapper(child: SplashScreen()),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/order-detail':
        final orderId = settings.arguments as String?;
        if (orderId != null) {
          return MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
            settings: settings,
          );
        }
        return null;
      default:
        return null;
    }
  }
}

/// Wrapper widget to handle deep links when app is launched
class _DeepLinkWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const _DeepLinkWrapper({required this.child});

  @override
  ConsumerState<_DeepLinkWrapper> createState() => _DeepLinkWrapperState();
}

class _DeepLinkWrapperState extends ConsumerState<_DeepLinkWrapper> {
  late AppLinks _appLinks;
  late StreamSubscription _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() {
    // Handle deep link when app is launched
    _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 Deep link received: $uri');
        DeepLinkService.handleDeepLink(uri.toString());
      },
      onError: (err) {
        debugPrint('❌ Deep link error: $err');
      },
    );
  }

  @override
  void dispose() {
    _deepLinkSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
