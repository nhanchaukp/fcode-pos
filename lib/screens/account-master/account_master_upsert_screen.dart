import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/dto/account_master_data.dart';
import 'package:fcode_pos/repositories/cache_repository.dart';
import 'package:fcode_pos/screens/account-master/account_master_detail_screen.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/app_section_card.dart';
import 'package:fcode_pos/ui/components/app_switch_tile.dart';
import 'package:fcode_pos/ui/components/dropdown/account_master_external_source_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/account_master_service_type_dropdown.dart';
import 'package:fcode_pos/ui/components/dropdown/supply_dropdown.dart';
import 'package:fcode_pos/ui/components/key_value_editor.dart';
import 'package:fcode_pos/ui/components/money_form_field.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AccountMasterUpsertScreen extends StatefulWidget {
  final AccountMaster? accountMaster;

  const AccountMasterUpsertScreen({super.key, this.accountMaster});

  @override
  State<AccountMasterUpsertScreen> createState() =>
      _AccountMasterUpsertScreenState();
}

class _AccountMasterUpsertScreenState extends State<AccountMasterUpsertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keyValueEditorKey = GlobalKey<KeyValueEditorState>();
  late AccountMasterService _accountMasterService;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  enums.AccountMasterServiceType? _serviceType;
  late TextEditingController _maxSlotsController;
  late TextEditingController _notesController;
  late TextEditingController _monthlyCostController;
  late TextEditingController _costNotesController;
  late TextEditingController _cookiesController;
  late TextEditingController _detailsController;
  String? _externalSrc;

  DateTime? _paymentDate;
  Supply? _selectedSupply;
  bool _isActive = true;
  bool _showPassword = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _accountMasterService = AccountMasterService();

    // Initialize controllers with existing data if updating
    final account = widget.accountMaster;
    _nameController = TextEditingController(text: account?.name ?? '');
    _usernameController = TextEditingController(text: account?.username ?? '');
    _passwordController = TextEditingController(text: account?.password ?? '');
    _serviceType = enums.AccountMasterServiceType.fromValue(
      account?.serviceType,
    );
    _maxSlotsController = TextEditingController(
      text: account?.maxSlots.toString() ?? '',
    );
    _notesController = TextEditingController(text: account?.notes ?? '');
    _monthlyCostController = TextEditingController(
      text: account?.monthlyCost?.toString() ?? '',
    );
    _costNotesController = TextEditingController(
      text: account?.costNotes ?? '',
    );
    _cookiesController = TextEditingController(text: account?.cookies ?? '');
    _detailsController = TextEditingController(text: account?.details ?? '');
    _externalSrc = account?.externalSrc;

    _paymentDate = account?.paymentDate;
    _selectedSupply = account?.supply;
    _isActive = account?.isActive ?? true;
    _showPassword = account?.showPassword ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _maxSlotsController.dispose();
    _notesController.dispose();
    _monthlyCostController.dispose();
    _costNotesController.dispose();
    _cookiesController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  bool get _isUpdate => widget.accountMaster != null;

  Future<void> _selectPaymentDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parsedExternalConfig = _keyValueEditorKey.currentState?.getValueMap();

    setState(() {
      _isLoading = true;
    });

    try {
      final data = AccountMasterData(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        serviceType: _serviceType!.value,
        maxSlots: int.parse(_maxSlotsController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        paymentDate: _paymentDate,
        monthlyCost: _monthlyCostController.moneyValue == 0
            ? null
            : _monthlyCostController.moneyValue,
        costNotes: _costNotesController.text.trim().isEmpty
            ? null
            : _costNotesController.text.trim(),
        isActive: _isActive,
        showPassword: _showPassword,
        cookies: _cookiesController.text.trim().isEmpty
            ? null
            : _cookiesController.text.trim(),
        details: _detailsController.text.trim().isEmpty
            ? null
            : _detailsController.text.trim(),
        supplyId: _selectedSupply?.id,
        externalSrc: (_externalSrc != null && _externalSrc!.trim().isNotEmpty)
            ? _externalSrc!.trim()
            : null,
        externalConfig: parsedExternalConfig,
      );

      if (_isUpdate) {
        await _accountMasterService.update(widget.accountMaster!.id, data);
        CacheRepository.instance.invalidateAccountMasters();
        if (!mounted) return;
        Toastr.success('Cập nhật tài khoản thành công');
        Navigator.pop(context, true);
        return;
      }

      final response = await _accountMasterService.create(data);
      CacheRepository.instance.invalidateAccountMasters();
      if (!mounted) return;

      Toastr.success('Tạo tài khoản thành công');

      final created = response.data;
      if (created != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AccountMasterDetailScreen(accountMaster: created),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isUpdate ? 'Chỉnh sửa tài khoản' : 'Tạo tài khoản mới',
      actions: [
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submit,
            tooltip: 'Lưu',
          ),
      ],
      body: (context, scrollController) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            AppSectionCard(
              title: 'Thông tin cơ bản',
              icon: Icons.info_outline,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tài khoản *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên tài khoản';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      tooltip: _obscurePassword
                          ? 'Hiển thị mật khẩu'
                          : 'Ẩn mật khẩu',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AccountMasterServiceTypeDropdown(
                  initialValue: _serviceType,
                  showPrefixIcon: true,
                  onChanged: (value) {
                    setState(() {
                      _serviceType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SupplyDropdown(
                  selectedSupply: _selectedSupply,
                  onChanged: (supply) {
                    setState(() {
                      _selectedSupply = supply;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxSlotsController,
                  decoration: const InputDecoration(
                    labelText: 'Số slot tối đa *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.dns),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số slot tối đa';
                    }
                    final slots = int.tryParse(value);
                    if (slots == null || slots <= 0) {
                      return 'Số slot phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppSwitchTile(
                  title: 'Trạng thái hoạt động',
                  subtitle: _isActive ? 'Active' : 'Inactive',
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 8),
                AppSwitchTile(
                  title: 'Hiển thị mật khẩu',
                  subtitle:
                      'Mật khẩu sẽ hiển thị khi người dùng truy cập qua Access Link',
                  value: _showPassword,
                  onChanged: (v) => setState(() => _showPassword = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Information Section
            AppSectionCard(
              title: 'Thông tin thanh toán',
              icon: Icons.payments_outlined,
              children: [
                InkWell(
                  onTap: _selectPaymentDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày thanh toán',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _paymentDate != null
                          ? DateFormat('dd/MM/yyyy').format(_paymentDate!)
                          : 'Chưa chọn',
                      style: TextStyle(
                        color: _paymentDate != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                MoneyFormField(
                  controller: _monthlyCostController,
                  labelText: 'Chi phí hàng tháng',
                  hintText: '0',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'VNĐ',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costNotesController,
                  decoration: const InputDecoration(labelText: 'Ghi chú chi phí'),
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Additional Information Section
            AppSectionCard(
              title: 'Thông tin bổ sung',
              icon: Icons.tune_outlined,
              children: [
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                AccountMasterExternalSourceDropdown(
                  initialValue: _externalSrc,
                  labelText: 'Nguồn ngoài',
                  onChanged: (value) {
                    setState(() {
                      _externalSrc = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Cấu hình ngoài (external_config)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                KeyValueEditor(
                  key: _keyValueEditorKey,
                  initialValue: widget.accountMaster?.externalConfig,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_isUpdate ? Icons.save : Icons.add),
              label: Text(_isUpdate ? 'Cập nhật' : 'Tạo mới'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
