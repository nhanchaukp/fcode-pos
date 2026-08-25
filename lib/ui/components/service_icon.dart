import 'package:fcode_pos/config/app_color.dart';
import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Helper mapping service types to their SVG asset paths and brand attributes.
class ServiceIconHelper {
  const ServiceIconHelper._();

  static const String netflixSvg = 'assets/svgs/netflix.svg';
  static const String youtubeSvg = 'assets/svgs/youtube.svg';
  static const String googleOneSvg = 'assets/svgs/google-one.svg';
  static const String openAiSvg = 'assets/svgs/openai.svg';
  static const String microsoftOfficeSvg = 'assets/svgs/microsoft-office.svg';

  /// Returns the relative SVG asset path for a given [serviceType].
  static String? getSvgAsset(dynamic serviceType) {
    final key = _normalizeKey(serviceType);
    return switch (key) {
      'netflix' => netflixSvg,
      'youtube' => youtubeSvg,
      'google_one' || 'google-one' || 'googleone' => googleOneSvg,
      'chatgpt' || 'openai' => openAiSvg,
      'microsoft' || 'microsoft-office' || 'microsoft_office' || 'office' =>
        microsoftOfficeSvg,
      _ => null,
    };
  }

  /// Returns the primary brand color for a given [serviceType].
  static Color getBrandColor(dynamic serviceType) {
    final key = _normalizeKey(serviceType);
    return switch (key) {
      'netflix' => const Color(0xFFE50914),
      'youtube' => const Color(0xFFFF0000),
      'google_one' || 'google-one' || 'googleone' => const Color(0xFF4285F4),
      'chatgpt' || 'openai' => const Color(0xFF10A37F),
      'microsoft' || 'microsoft-office' || 'microsoft_office' || 'office' =>
        const Color(0xFFD83B01),
      _ => AppColor.gray,
    };
  }

  /// Returns a human-friendly display label for a given [serviceType].
  static String getBrandLabel(dynamic serviceType) {
    final key = _normalizeKey(serviceType);
    return switch (key) {
      'netflix' => 'Netflix',
      'youtube' => 'YouTube',
      'google_one' || 'google-one' || 'googleone' => 'Google One',
      'chatgpt' || 'openai' => 'ChatGPT',
      'microsoft' || 'microsoft-office' || 'microsoft_office' || 'office' =>
        'Microsoft',
      _ => (serviceType?.toString().trim().isNotEmpty ?? false)
          ? serviceType.toString()
          : 'Dịch vụ',
    };
  }

  static String _normalizeKey(dynamic serviceType) {
    if (serviceType == null) return '';
    if (serviceType is enums.AccountMasterServiceType) {
      return serviceType.value.toLowerCase().trim();
    }
    return serviceType.toString().toLowerCase().trim();
  }
}

/// Component hiển thị biểu tượng SVG của dịch vụ (Netflix, YouTube, Google One, ChatGPT, Microsoft).
///
/// Hỗ trợ cả [String] (ví dụ: 'netflix', 'google_one') và [enums.AccountMasterServiceType].
class ServiceIcon extends StatelessWidget {
  const ServiceIcon({
    super.key,
    required this.serviceType,
    this.size = 24,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorFilter,
    this.fallback,
  });

  /// Loại dịch vụ (String hoặc enums.AccountMasterServiceType).
  final dynamic serviceType;

  /// Kích thước mặc định cho cả chiều rộng và chiều cao.
  final double size;

  /// Chiều rộng ghi đè (nếu có).
  final double? width;

  /// Chiều cao ghi đè (nếu có).
  final double? height;

  /// Cách co giãn hình SVG.
  final BoxFit fit;

  /// Màu sắc nếu muốn áp dụng bộ lọc màu cho icon đơn sắc.
  final Color? color;

  /// Bộ lọc màu tùy biến.
  final ColorFilter? colorFilter;

  /// Widget fallback nếu không tìm thấy SVG phù hợp.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final assetPath = ServiceIconHelper.getSvgAsset(serviceType);
    final w = width ?? size;
    final h = height ?? size;

    if (assetPath == null) {
      return fallback ??
          Icon(
            Icons.category_outlined,
            size: w,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
    }

    final effectiveColorFilter =
        colorFilter ??
        (color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null);

    return SvgPicture.asset(
      assetPath,
      width: w,
      height: h,
      fit: fit,
      colorFilter: effectiveColorFilter,
      placeholderBuilder: (_) => SizedBox(
        width: w,
        height: h,
        child: const Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Badge hiển thị biểu tượng SVG của dịch vụ trong khung viền bo tròn bo góc đẹp mắt.
///
/// Dùng trong danh sách tài khoản, tiêu đề chi tiết hoặc dropdown.
class ServiceBadge extends StatelessWidget {
  const ServiceBadge({
    super.key,
    required this.serviceType,
    this.size = 40,
    this.iconSize = 22,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.filled = false,
  });

  /// Loại dịch vụ (String hoặc enums.AccountMasterServiceType).
  final dynamic serviceType;

  /// Kích thước khung chứa bên ngoài (width & height).
  final double size;

  /// Kích thước của SVG icon bên trong.
  final double iconSize;

  /// Độ bo góc của badge. Mặc định theo theme ứng dụng.
  final double? borderRadius;

  /// Màu nền tùy biến cho badge.
  final Color? backgroundColor;

  /// Màu đường viền tùy biến.
  final Color? borderColor;

  /// Nếu true, sử dụng nền màu thương hiệu (filled color). Nếu false, sử dụng nền surface dịu nhẹ.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = AppBadgeTheme.borderRadius(
      context,
      override: borderRadius,
    );
    final brandColor = ServiceIconHelper.getBrandColor(serviceType);

    final effectiveBgColor = backgroundColor ??
        (filled
            ? brandColor
            : brandColor.withValues(alpha: 0.1));

    final effectiveBorder = borderColor != null
        ? Border.all(color: borderColor!)
        : (!filled
            ? Border.all(color: brandColor.withValues(alpha: 0.2), width: 1)
            : null);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(resolvedRadius),
        border: effectiveBorder,
      ),
      alignment: Alignment.center,
      child: ServiceIcon(
        serviceType: serviceType,
        size: iconSize,
        color: filled ? Colors.white : null,
      ),
    );
  }
}
