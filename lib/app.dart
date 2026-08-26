import 'package:fcode_pos/appwrite.dart';
import 'package:fcode_pos/config/environment.dart';
import 'package:fcode_pos/config/theme_colors.dart';
import 'package:fcode_pos/providers/theme_provider.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/screens/splash_screen.dart';
import 'package:fcode_pos/services/deep_link_service.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:fcode_pos/widgets/deep_link_listener.dart';
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
    final cardBorder = colorScheme.outlineVariant.a == 0
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

    final menuBackgroundColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceContainerLowest;

    return base.copyWith(
      colorScheme: colorScheme,
      canvasColor: menuBackgroundColor,
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
      // Dropdown & Popup Menu styling theo theme palette
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: base.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: colorScheme.onSurface,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(menuBackgroundColor),
          elevation: const WidgetStatePropertyAll(3),
          shadowColor: WidgetStatePropertyAll(
            colorScheme.shadow.withValues(alpha: isDark ? 0.35 : 0.08),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: br, side: cardBorder),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: menuBackgroundColor,
        elevation: 3,
        shadowColor: colorScheme.shadow.withValues(alpha: isDark ? 0.35 : 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: br, side: cardBorder),
        textStyle: base.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: colorScheme.onSurface,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return base.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: colorScheme.onSurface,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          );
        }),
        position: PopupMenuPosition.under,
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(menuBackgroundColor),
          elevation: const WidgetStatePropertyAll(3),
          shadowColor: WidgetStatePropertyAll(
            colorScheme.shadow.withValues(alpha: isDark ? 0.35 : 0.08),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: br, side: cardBorder),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          ),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          textStyle: base.textTheme.bodyMedium?.copyWith(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius > 4 ? borderRadius - 4 : 0,
            ),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: menuBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: br, side: cardBorder),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: menuBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius > 0 ? borderRadius + 4 : 0),
          ),
        ),
        showDragHandle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: br * 2),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 44),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: br * 2),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          side: BorderSide(
            color: colorScheme.outlineVariant.applyOpacity(0.8),
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: br * 2),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: br * 2),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: br * 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: br * 2),
        extendedTextStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: br * 2),
          textStyle: base.textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // Chip: viền tĩnh để luôn nhìn thấy; color theo state để phân biệt
      // selected (primaryContainer) vs unselected (surfaceContainerLow).
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: br * 2),
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerLow;
        }),
      ),
      // Switch ở trạng thái off có track outline rõ ràng.
      switchTheme: base.switchTheme.copyWith(
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outline.withValues(alpha: 0.6);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return null;
          return colorScheme.surfaceContainer;
        }),
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
      fillColor: colorScheme.brightness == Brightness.dark
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        fontSize: 13,
      ),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
        fontSize: 13,
      ),
      floatingLabelStyle: TextStyle(color: colorScheme.primary, fontSize: 13),
      prefixIconColor: colorScheme.onSurfaceVariant.applyOpacity(0.7),
      suffixIconColor: colorScheme.onSurfaceVariant.applyOpacity(0.7),
      iconColor: colorScheme.onSurfaceVariant.applyOpacity(0.7),
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
      home: const DeepLinkListener(child: SplashScreen()),
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
