import 'package:fcode_pos/ui/components/icon_text.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableIconText extends StatelessWidget {
  const CopyableIconText({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        Toastr.success('Số điện thoại đã được sao chép vào clipboard.');
      },
      child: IconText(icon: icon, value: value, color: color),
    );
  }
}
