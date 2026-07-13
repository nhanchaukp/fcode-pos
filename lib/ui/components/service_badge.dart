import 'package:amazing_icons/twotone.dart';
import 'package:fcode_pos/ui/components/badge/badge_bulk_icon.dart';
import 'package:flutter/material.dart';

class ServiceBadge extends StatelessWidget {
  const ServiceBadge({
    super.key,
    required this.serviceType,
    this.size = 40,
    this.iconSize = 20,
    this.borderRadius = 10,
  });

  final String serviceType;
  final double size;
  final double iconSize;
  final double borderRadius;

  static (BulkIconBuilder, Color) getServiceStyle(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'netflix':
        return (AmazingIconTwotone.monitor, const Color(0xFFE50914));
      case 'youtube':
        return (AmazingIconTwotone.youtube, const Color(0xFFFF0000));
      case 'google_one':
        return (AmazingIconTwotone.googlePlay, const Color(0xFF4285F4));
      case 'chatgpt':
        return (AmazingIconTwotone.messageProgramming, const Color(0xFF10A37F));
      case 'microsoft':
        return (AmazingIconTwotone.setting, const Color(0xFF00A4EF));
      default:
        return (AmazingIconTwotone.infoCircle, const Color(0xFF9E9E9E));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, bgColor) = getServiceStyle(serviceType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: icon(size: iconSize, color: Colors.white, opacity: 0.35),
    );
  }
}
