import 'package:fcode_pos/data/models/status.dart';
import 'package:fcode_pos/ui/icons/appwrite.dart';
import 'package:fcode_pos/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

import 'connection_line.dart';

/// A widget that displays a row containing platform icons and a connection line between them.
/// The connection line indicates the status of the platform connection.
///
/// [status] - A boolean indicating whether the connection is successful.
class TopPlatformView extends StatelessWidget {
  final Status status;

  const TopPlatformView({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        PlatformIcon(
          size: context.isExtraWideScreen ? 142 : 100,
          child: FlutterLogo(size: context.isExtraWideScreen ? 56 : 40),
        ),
        ConnectionLine(show: status == Status.success),
        PlatformIcon(
          size: context.isExtraWideScreen ? 142 : 100,
          child: AppwriteIcon(size: context.isExtraWideScreen ? 56 : 40),
        ),
      ],
    );
  }
}

/// A widget that displays a stylized platform icon with a customizable content block.
/// The icon is rendered with shadows, rounded corners, and a layered background.
///
/// [size] - The size of the platform icon.
/// [child] - The inner content of the icon (e.g., an image or icon).
class PlatformIcon extends StatelessWidget {
  final double size;
  final Widget child;

  const PlatformIcon({
    super.key,
    this.size = 100.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFD),
        borderRadius:
            BorderRadius.circular(context.isExtraWideScreen ? size * 0.2 : 24),
        border: Border.all(color: const Color(0x0A19191C), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x08000000),
            blurRadius: 9.36,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.86,
          height: size * 0.86,
          margin: context.isExtraWideScreen ? EdgeInsets.all(8) : null,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
                context.isExtraWideScreen ? size * 0.2 : 16),
            border: Border.all(color: const Color(0xFFFAFAFB), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0x05000000),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: const Color(0x05000000),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
