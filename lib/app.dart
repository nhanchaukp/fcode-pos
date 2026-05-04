import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fcode_pos/appwrite.dart';
import 'package:fcode_pos/config/environment.dart';
import 'package:fcode_pos/config/theme_colors.dart';
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

  /// Build [ThemeData] từ [palette] và [brightness].
  /// Đăng ký [AppColors] extension để SnackBar / badge có thể dùng màu semantic.
  ThemeData _buildTheme(ThemePalette palette, Brightness brightness) {
    final colorScheme = brightness == Brightness.light
        ? palette.lightScheme
        : palette.darkScheme;
    final borderRadius = palette.borderRadius;
    final isDark = brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceContainerLowest;
    final br = BorderRadius.circular(borderRadius);
    final cardBorder = colorScheme.outlineVariant.alpha == 0
        ? BorderSide.none
        : BorderSide(
            color: colorScheme.outlineVariant.applyOpacity(0.5),
            width: 0.5,
          );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'MomoTrustSans',
      colorScheme: colorScheme,
    );

    return base.copyWith(
      colorScheme: colorScheme,
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
            bodyColor: colorScheme.onSurface,
            displayColor: colorScheme.onSurface,
          ),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme:
          CardThemeData(
                color: cardColor,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: br,
                  side: cardBorder,
                ),
              )
              as dynamic,
      inputDecorationTheme:
          _buildInputDecorationTheme(
                base.inputDecorationTheme,
                colorScheme,
                borderRadius: borderRadius,
              )
              as dynamic,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: br),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: {palette.colors},
    );
  }

  dynamic _buildInputDecorationTheme(
    dynamic baseTheme,
    ColorScheme colorScheme, {
    double borderRadius = 12,
  }) {
    final inputBr = BorderRadius.circular(
      borderRadius > 0 ? borderRadius - 2 : 0,
    );
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: inputBr,
          borderSide: BorderSide(color: color, width: width),
        );

    return baseTheme.copyWith(
      isDense: true,
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      border: outline(colorScheme.outlineVariant.withValues(alpha: 0.5)),
      enabledBorder: outline(colorScheme.outlineVariant.withValues(alpha: 0.5)),
      disabledBorder: outline(
        colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      focusedBorder: outline(colorScheme.primary, 1.2),
      errorBorder: outline(colorScheme.error),
      focusedErrorBorder: outline(colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final paletteIndex = ref.watch(themePaletteIndexProvider);
    final idx = paletteIndex.clamp(0, themePalettes.length - 1);
    final palette = themePalettes[idx];

    return MaterialApp(
      title: Environment.appName,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(palette, Brightness.light),
      darkTheme: _buildTheme(palette, Brightness.dark),
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
