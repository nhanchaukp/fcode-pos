import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  static (IconData, Color) getServiceStyle(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'netflix':
        return (FontAwesomeIcons.tv, const Color(0xFFE50914));
      case 'youtube':
        return (FontAwesomeIcons.youtube, const Color(0xFFFF0000));
      case 'google_one':
        return (FontAwesomeIcons.google, const Color(0xFF4285F4));
      case 'chatgpt':
        return (FontAwesomeIcons.robot, const Color(0xFF10A37F));
      case 'microsoft':
        return (FontAwesomeIcons.microsoft, const Color(0xFF00A4EF));
      default:
        return (FontAwesomeIcons.circleQuestion, const Color(0xFF9E9E9E));
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
      child: FaIcon(icon, size: iconSize, color: Colors.white),
    );
  }
}
