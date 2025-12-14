import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fcode_pos/appwrite.dart';
import 'package:fcode_pos/config/environment.dart';
import 'package:fcode_pos/providers/theme_provider.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/screens/splash_screen.dart';
import 'package:fcode_pos/services/deep_link_service.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcodePosApp extends ConsumerWidget {
  const FcodePosApp({super.key});

  ThemeData _buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'MomoTrustSans',
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
      fontFamily: 'MomoTrustSans',
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
        title: Environment.appName,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        navigatorKey: navigatorKey,
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
