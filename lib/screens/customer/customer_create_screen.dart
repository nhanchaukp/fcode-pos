import 'dart:async';

import 'package:fcode_pos/enums/buyer_type.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/models/viet_qr_business_info.dart';
import 'package:fcode_pos/services/viet_qr_service.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/models/dto/customer_create_data.dart';
import 'package:fcode_pos/services/customer_service.dart';
import 'package:fcode_pos/ui/components/section_header.dart';

class CustomerCreateScreen extends StatefulWidget {
  /// Khi [user] được cung cấp, màn hình chạy ở chế độ chỉnh sửa.
  const CustomerCreateScreen({super.key, this.user});

  final User? user;

  bool get isEditing => user != null;

  @override
  State<CustomerCreateScreen> createState() => _CustomerCreateScreenState();
}

class _CustomerCreateScreenState extends State<CustomerCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Thông tin cơ bản ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  // --- Loại khách hàng ---
  BuyerType _buyerType = BuyerType.personal;

  // --- Thông tin doanh nghiệp ---
  final _legalNameController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _addressController = TextEditingController();

  // --- Thông tin bổ sung ---
  final _buyerCodeController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _invoiceEmailController = TextEditingController();
  final _facebookController = TextEditingController();
  bool _extraExpanded = false;

  // --- MST lookup ---
  bool _isFetchingTaxInfo = false;
  VietQrBusinessInfo? _fetchedBusinessInfo;
  Timer? _taxDebounce;

  bool _isLoading = false;

  bool get _isCompany => _buyerType == BuyerType.company;
  bool get _isEditing => widget.isEditing;

  @override
  void initState() {
    super.initState();
    _taxCodeController.addListener(_onTaxCodeChanged);
    if (_isEditing) _prefillFromUser(widget.user!);
  }

  void _prefillFromUser(User u) {
    _nameController.text = u.name;
    _emailController.text = u.email;
    _phoneController.text = u.phone ?? '';
    _facebookController.text = u.facebookUrl ?? u.facebook ?? '';
    _buyerType = BuyerType.fromValue(u.buyerType) ?? BuyerType.personal;
    _legalNameController.text = u.legalName ?? '';
    _taxCodeController.text = u.taxCode ?? '';
    _addressController.text = u.address ?? '';
    _buyerCodeController.text = u.buyerCode ?? '';
    _nationalIdController.text = u.nationalId ?? '';
    _invoiceEmailController.text = u.invoiceEmail ?? '';
    if (_legalNameController.text.isNotEmpty ||
        _buyerCodeController.text.isNotEmpty ||
        _nationalIdController.text.isNotEmpty ||
        _invoiceEmailController.text.isNotEmpty ||
        _facebookController.text.isNotEmpty) {
      _extraExpanded = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _legalNameController.dispose();
    _taxCodeController.dispose();
    _addressController.dispose();
    _buyerCodeController.dispose();
    _nationalIdController.dispose();
    _invoiceEmailController.dispose();
    _facebookController.dispose();
    _taxDebounce?.cancel();
    super.dispose();
  }

  void _onTaxCodeChanged() {
    _taxDebounce?.cancel();
    final code = _taxCodeController.text.trim();
    if (code.isEmpty) {
      if (_fetchedBusinessInfo != null) {
        setState(() => _fetchedBusinessInfo = null);
      }
      return;
    }
    _taxDebounce = Timer(const Duration(milliseconds: 800), () {
      _fetchTaxInfo(code);
    });
  }

  Future<void> _fetchTaxInfo(String taxCode) async {
    setState(() {
      _isFetchingTaxInfo = true;
      _fetchedBusinessInfo = null;
    });
    final info = await VietQrService().lookupByTaxCode(taxCode);
    if (!mounted) return;
    setState(() {
      _isFetchingTaxInfo = false;
      _fetchedBusinessInfo = info;
    });
    if (info != null) {
      if (_legalNameController.text.trim().isEmpty) {
        _legalNameController.text = info.name;
      }
      if (_addressController.text.trim().isEmpty) {
        _addressController.text = info.address;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = CustomerCreateData(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      buyerType: _buyerType,
      password: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      legalName: _legalNameController.text.trim().isEmpty
          ? null
          : _legalNameController.text.trim(),
      taxCode: _taxCodeController.text.trim().isEmpty
          ? null
          : _taxCodeController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      buyerCode: _buyerCodeController.text.trim().isEmpty
          ? null
          : _buyerCodeController.text.trim(),
      nationalId: _nationalIdController.text.trim().isEmpty
          ? null
          : _nationalIdController.text.trim(),
      invoiceEmail: _invoiceEmailController.text.trim().isEmpty
          ? null
          : _invoiceEmailController.text.trim(),
      facebookUrl: _facebookController.text.trim().isEmpty
          ? null
          : _facebookController.text.trim(),
    );

    try {
      final service = CustomerService();
      final response = _isEditing
          ? await service.update(widget.user!.id, data)
          : await service.create(data);
      if (!mounted) return;
      if (response.data != null) {
        Navigator.of(context).pop(response.data);
      } else {
        Toastr.error(
          _isEditing
              ? 'Không thể cập nhật khách hàng.'
              : 'Không thể tạo khách hàng.',
        );
      }
    } catch (e) {
      Toastr.error(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa khách hàng' : 'Thêm khách hàng mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _buildSection(
              colorScheme: colorScheme,
              icon: Icons.person_outline,
              title: 'Thông tin cơ bản',
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'Tên khách hàng',
                  hint: 'Nguyễn Văn A',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Bắt buộc nhập tên';
                    }
                    if (v.trim().length > 255) return 'Tối đa 255 ký tự';
                    return null;
                  },
                ),
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Bắt buộc nhập email';
                    }
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(v.trim())) {
                      return 'Email không hợp lệ';
                    }
                    if (v.trim().length > 255) return 'Tối đa 255 ký tự';
                    return null;
                  },
                ),
                _buildField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hint: '0901234567',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v != null && v.trim().length > 20) {
                      return 'Tối đa 20 ký tự';
                    }
                    return null;
                  },
                ),
                _buildPasswordField(),
              ],
            ),
            const SizedBox(height: 8),
            _buildSection(
              colorScheme: colorScheme,
              icon: Icons.badge_outlined,
              title: 'Loại khách hàng',
              children: [_buildBuyerTypeSelector()],
            ),
            if (_isCompany) ...[
              const SizedBox(height: 8),
              _buildSection(
                colorScheme: colorScheme,
                icon: Icons.business_outlined,
                title: 'Thông tin doanh nghiệp',
                children: [
                  _buildTaxCodeField(),
                  if (_fetchedBusinessInfo != null)
                    _buildBusinessInfoCard(colorScheme),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _legalNameController,
                    label: 'Tên pháp nhân',
                    hint: 'Tên công ty theo đăng ký kinh doanh',
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (_isCompany && (v == null || v.trim().isEmpty)) {
                        return 'Bắt buộc nhập tên pháp nhân khi là doanh nghiệp';
                      }
                      if (v != null && v.trim().length > 255) {
                        return 'Tối đa 255 ký tự';
                      }
                      return null;
                    },
                  ),
                  _buildField(
                    controller: _addressController,
                    label: 'Địa chỉ',
                    hint: 'Địa chỉ trụ sở doanh nghiệp',
                    maxLines: 2,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _buildExpandableSection(
              colorScheme: colorScheme,
              icon: Icons.receipt_long_outlined,
              title: 'Thông tin bổ sung',
              expanded: _extraExpanded,
              onToggle: () => setState(() => _extraExpanded = !_extraExpanded),
              children: [
                _buildField(
                  controller: _buyerCodeController,
                  label: 'Mã khách hàng',
                  hint: 'Mã nội bộ (tùy chọn)',
                  validator: (v) {
                    if (v != null && v.trim().length > 50) {
                      return 'Tối đa 50 ký tự';
                    }
                    return null;
                  },
                ),
                _buildField(
                  controller: _nationalIdController,
                  label: 'CMND / CCCD',
                  hint: 'Số căn cước công dân',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.trim().length > 50) {
                      return 'Tối đa 50 ký tự';
                    }
                    return null;
                  },
                ),
                _buildField(
                  controller: _invoiceEmailController,
                  label: 'Email xuất hóa đơn',
                  hint: 'invoice@company.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(v.trim())) {
                        return 'Email không hợp lệ';
                      }
                      if (v.trim().length > 255) return 'Tối đa 255 ký tự';
                    }
                    return null;
                  },
                ),
                _buildField(
                  controller: _facebookController,
                  label: 'Facebook URL',
                  hint: 'https://facebook.com/...',
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    if (v != null && v.trim().length > 255) {
                      return 'Tối đa 255 ký tự';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Lưu thay đổi' : 'Tạo khách hàng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(icon: icon, title: title),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: SectionHeader(
              icon: icon,
              title: title,
              action: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (expanded) ...[const SizedBox(height: 12), ...children],
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
        keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: 'Mật khẩu',
          hintText: 'Tối thiểu 8 ký tự (để trống nếu không cần)',
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) {
          if (v != null && v.isNotEmpty && v.length < 8) {
            return 'Tối thiểu 8 ký tự';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildBuyerTypeSelector() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<BuyerType>(
        segments: BuyerType.values
            .map(
              (type) => ButtonSegment<BuyerType>(
                value: type,
                label: Text(type.label),
              ),
            )
            .toList(),
        selected: {_buyerType},
        onSelectionChanged: (s) => setState(() => _buyerType = s.first),
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: SegmentedButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildTaxCodeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _taxCodeController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Mã số thuế',
          hintText: 'Nhập MST để tra cứu tự động',
          suffixIcon: _isFetchingTaxInfo
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _fetchedBusinessInfo != null
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
        ),
        validator: (v) {
          if (_isCompany && (v == null || v.trim().isEmpty)) {
            return 'Bắt buộc nhập mã số thuế khi là doanh nghiệp';
          }
          if (v != null && v.trim().length > 30) return 'Tối đa 30 ký tự';
          return null;
        },
      ),
    );
  }

  Widget _buildBusinessInfoCard(ColorScheme colorScheme) {
    final info = _fetchedBusinessInfo!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Thông tin tra cứu MST',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _infoRow('Tên công ty', info.name),
          if (info.shortName.isNotEmpty)
            _infoRow('Tên viết tắt', info.shortName),
          _infoRow('Trạng thái', info.status),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            TextSpan(text: value, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
