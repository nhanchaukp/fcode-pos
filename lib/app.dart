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
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme:
          CardThemeData(
                color: base.colorScheme.surfaceContainerLowest,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: base.colorScheme.outlineVariant.applyOpacity(0.5),
                    width: 0.5,
                  ),
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
        // height: 60,
        backgroundColor: base.colorScheme.surface,
        indicatorColor: base.colorScheme.secondaryContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  // ColorScheme trung tính hoàn toàn (không hue) cho chế độ đen tuyệt đối.
  // Không dùng fromSeed vì M3 tonal algorithm luôn thêm chroma tối thiểu
  // làm primary/secondary bị tím/hồng dù seed là black.
  static const _blackNeutralScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFDDDDDD),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF282828),
    onPrimaryContainer: Color(0xFFEEEEEE),
    secondary: Color(0xFFAAAAAA),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF242424),
    onSecondaryContainer: Color(0xFFCCCCCC),
    tertiary: Color(0xFF888888),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF1E1E1E),
    onTertiaryContainer: Color(0xFFBBBBBB),
    error: Color(0xFFCF6679),
    onError: Color(0xFF000000),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFE3E3E3),
    surfaceDim: Color(0xFF000000),
    surfaceBright: Color(0xFF1E1E1E),
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF0A0A0A),
    surfaceContainer: Color(0xFF111111),
    surfaceContainerHigh: Color(0xFF181818),
    surfaceContainerHighest: Color(0xFF222222),
    onSurfaceVariant: Color(0xFFAAAAAA),
    outline: Color(0xFF555555),
    outlineVariant: Color(0xFF333333),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE3E3E3),
    onInverseSurface: Color(0xFF1C1C1C),
    inversePrimary: Color(0xFF333333),
  );

  ThemeData _buildDarkTheme(Color seedColor) {
    final isBlack = seedColor.toARGB32() == Colors.black.toARGB32();

    // Với seed đen, dùng scheme trung tính — bỏ qua fromSeed hoàn toàn.
    final colorScheme = isBlack
        ? _blackNeutralScheme
        : ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark);

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
      cardTheme: CardThemeData(
            color: colorScheme.surfaceContainer,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.applyOpacity(0.5),
                width: 0.5,
              ),
            ),
          ) as dynamic,
      inputDecorationTheme: _buildInputDecorationTheme(
            base.inputDecorationTheme,
            colorScheme,
          ) as dynamic,
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
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
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
      fillColor: colorScheme.surfaceContainerHigh,
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
    final seedColorIndex = ref.watch(themeSeedColorIndexProvider);
    int clampedIndex = seedColorIndex;
    if (clampedIndex < 0) {
      clampedIndex = 0;
    } else if (clampedIndex >= material3SeedColors.length) {
      clampedIndex = material3SeedColors.length - 1;
    }
    final seedColor = material3SeedColors[clampedIndex];

    return MaterialApp(
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
