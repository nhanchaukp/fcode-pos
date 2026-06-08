import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/ui/components/app_switch_tile.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

/// Mở bottom sheet chỉnh sửa slot và trả về [AccountSlot] mới nếu thành công.
Future<AccountSlot?> showSlotEditSheet(
  BuildContext context, {
  required AccountSlot slot,
  required AccountMasterService service,
}) {
  return showModalBottomSheet<AccountSlot>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SlotEditSheet(slot: slot, service: service),
  );
}

/// Bottom sheet chỉnh sửa thông tin một [AccountSlot].
///
/// Trả về [AccountSlot] đã cập nhật qua `Navigator.pop` khi thành công.
class SlotEditSheet extends StatefulWidget {
  final AccountSlot slot;
  final AccountMasterService service;

  const SlotEditSheet({super.key, required this.slot, required this.service});

  @override
  State<SlotEditSheet> createState() => _SlotEditSheetState();
}

class _SlotEditSheetState extends State<SlotEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pinController;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.slot.name);
    _pinController = TextEditingController(text: widget.slot.pin);
    _isActive = widget.slot.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await widget.service.updateSlot(
        widget.slot.id,
        name: _nameController.text.trim(),
        pin: _pinController.text.trim().isEmpty
            ? null
            : _pinController.text.trim(),
        isActive: _isActive,
      );
      if (!mounted) return;
      if (response.success && response.data != null) {
        Toastr.success('Cập nhật slot thành công', context: context);
        Navigator.of(context).pop(response.data);
      } else {
        Toastr.error(response.message ?? 'Cập nhật thất bại', context: context);
      }
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Lỗi: ${e.toString()}', context: context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    'Chỉnh sửa slot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tên slot
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên slot *',
                  hintText: 'Nhập tên slot',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên slot'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // PIN
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  hintText: 'Nhập PIN (không bắt buộc)',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),

              // Trạng thái hoạt động
              AppSwitchTile(
                icon: _isActive ? Icons.check_circle : Icons.cancel_outlined,
                title: 'Kích hoạt',
                subtitle: _isActive ? 'Đang hoạt động' : 'Tạm dừng',
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 20),

              // Submit
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: LoadingIcon(
                  icon: Icons.check_circle_outline_outlined,
                  loading: _isSubmitting,
                ),
                label: Text(_isSubmitting ? 'Đang cập nhật...' : 'Cập nhật'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
