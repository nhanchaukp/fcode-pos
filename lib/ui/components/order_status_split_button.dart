import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';

/// Split button for displaying and updating order status quickly.
class OrderStatusSplitButton extends StatefulWidget {
  const OrderStatusSplitButton({
    super.key,
    required this.status,
    required this.onStatusSelected,
    this.isUpdating = false,
    this.onPrimaryPressed,
  });

  /// Current order status value.
  final String status;

  /// Callback when a new status is selected from the menu.
  final ValueChanged<enums.OrderStatus> onStatusSelected;

  /// Optional primary action when the left side is tapped.
  final VoidCallback? onPrimaryPressed;

  /// Indicates whether an update request is in progress.
  final bool isUpdating;

  @override
  State<OrderStatusSplitButton> createState() => _OrderStatusSplitButtonState();
}

class _OrderStatusSplitButtonState extends State<OrderStatusSplitButton> {
  late final MenuController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
  }

  Iterable<enums.OrderStatus> get _menuStatuses sync* {
    for (final status in enums.OrderStatus.values) {
      if (status == enums.OrderStatus.all) continue;
      yield status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = enums.OrderStatus.fromString(widget.status);
    final statusColor =
        currentStatus?.color ?? Theme.of(context).colorScheme.primary;

    return MenuAnchor(
      controller: _menuController,
      menuChildren: _menuStatuses.map((status) {
        final isCurrent = status == currentStatus;
        return MenuItemButton(
          onPressed: widget.isUpdating || isCurrent
              ? null
              : () {
                  widget.onStatusSelected(status);
                  _menuController.close();
                },
          leadingIcon: Icon(Icons.circle, size: 10, color: status.color),
          trailingIcon: isCurrent
              ? Icon(Icons.check, size: 16, color: status.color)
              : null,
          child: Text(status.label),
        );
      }).toList(),
      builder: (context, controller, child) {
        return Container(
          height: 32,
          decoration: ShapeDecoration(
            color: statusColor.applyOpacity(0.06),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: statusColor.applyOpacity(0.25)),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SplitButtonSegment(
                onPressed: widget.isUpdating
                    ? null
                    : (widget.onPrimaryPressed ??
                          () => _toggleMenu(controller)),
                label: currentStatus?.label ?? 'Trạng thái',
                color: statusColor,
              ),
              _SplitButtonDivider(color: statusColor),
              _SplitButtonIconSegment(
                isOpen: controller.isOpen,
                isBusy: widget.isUpdating,
                color: statusColor,
                onPressed: widget.isUpdating
                    ? null
                    : () => _toggleMenu(controller),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleMenu(MenuController controller) {
    if (!controller.isOpen) {
      controller.open();
    } else {
      controller.close();
    }
  }
}

class _SplitButtonSegment extends StatelessWidget {
  const _SplitButtonSegment({
    required this.onPressed,
    required this.label,
    required this.color,
  });

  final VoidCallback? onPressed;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      fit: FlexFit.loose,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: const RoundedRectangleBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitButtonDivider extends StatelessWidget {
  const _SplitButtonDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: color.applyOpacity(0.3));
  }
}

class _SplitButtonIconSegment extends StatelessWidget {
  const _SplitButtonIconSegment({
    required this.isOpen,
    required this.isBusy,
    required this.color,
    required this.onPressed,
  });

  final bool isOpen;
  final bool isBusy;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = isBusy
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        : Icon(
            isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: color,
          );

    return SizedBox(
      height: double.infinity,
      child: IconButton(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        splashRadius: 18,
        icon: icon,
      ),
    );
  }
}
