import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/customer/customer_create_screen.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/services/customer_service.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/ui/components/order_status_badge.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/functions.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int? userId;
  final User? user;

  const CustomerDetailScreen({super.key, this.userId, this.user})
    : assert(
        userId != null || user != null,
        'Either userId or user must be provided',
      );

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late CustomerService _customerService;
  late OrderService _orderService;
  late TabController _tabController;
  User? _user;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _customerService = CustomerService();
    _orderService = OrderService();
    _tabController = TabController(length: 2, vsync: this);

    // If user model is provided, use it directly
    if (widget.user != null) {
      _user = widget.user;
    } else {
      // Otherwise, load from API
      _loadCustomerDetail();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToEdit() async {
    if (_user == null) return;
    final updated = await Navigator.push<User>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerCreateScreen(user: _user),
      ),
    );
    if (updated != null) {
      setState(() => _user = updated);
    }
  }

  Future<void> _loadCustomerDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _customerService.detail(widget.userId!);
      if (!mounted) return;
      setState(() {
        _user = response.data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading customer detail: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khách hàng'),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa',
              onPressed: _navigateToEdit,
            ),
          if (widget.userId != null && _user != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCustomerDetail,
            ),
        ],
        bottom: _user != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Thông tin', icon: Icon(Icons.person)),
                  Tab(text: 'Đơn hàng', icon: Icon(Icons.shopping_bag)),
                ],
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCustomerDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(child: Text('Không tìm thấy thông tin khách hàng'));
    }

    return TabBarView(
      controller: _tabController,
      children: [_buildInfoTab(), _buildOrdersTab()],
    );
  }

  Widget _buildInfoTab() {
    final user = _user!;
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 16),
          _buildSectionLabel('Thông tin liên hệ'),
          const SizedBox(height: 6),
          _buildContactCard(user),
          if (_hasBusinessInfo(user)) ...[
            const SizedBox(height: 16),
            _buildSectionLabel('Thông tin doanh nghiệp'),
            const SizedBox(height: 6),
            _buildBusinessCard(user),
          ],
          const SizedBox(height: 16),
          _buildSectionLabel('Tài khoản'),
          const SizedBox(height: 6),
          _buildAccountCard(user),
          if (_hasSocialInfo(user)) ...[
            const SizedBox(height: 16),
            _buildSectionLabel('Kết nối mạng xã hội'),
            const SizedBox(height: 6),
            _buildSocialCard(user),
          ],
        ],
      ),
    );

    if (widget.userId != null) {
      return RefreshIndicator(onRefresh: _loadCustomerDetail, child: content);
    }
    return content;
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRowData> rows) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _buildInfoRow(rows[i]),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto =
        (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty) ||
            (user.avatar != null && user.avatar!.isNotEmpty);
    final photoUrl = user.profilePhotoUrl?.isNotEmpty == true
        ? user.profilePhotoUrl!
        : user.avatar;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage:
                  hasPhoto ? NetworkImage(photoUrl!) : null,
              child: !hasPhoto
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (user.legalName != null && user.legalName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  user.legalName!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (user.buyerType != null) ...[
              const SizedBox(height: 8),
              _buildBuyerTypeBadge(user.buyerType!, colorScheme),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: colorScheme.onPrimaryContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Số dư: ${CurrencyHelper.formatCurrency(user.balance)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerTypeBadge(String buyerType, ColorScheme colorScheme) {
    final isCompany = buyerType == 'company';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCompany
            ? colorScheme.secondaryContainer
            : colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompany ? Icons.business : Icons.person,
            size: 14,
            color: isCompany
                ? colorScheme.onSecondaryContainer
                : colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isCompany ? 'Doanh nghiệp' : 'Cá nhân',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCompany
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(User user) {
    final rows = <_InfoRowData>[
      _InfoRowData(
        icon: Icons.email_outlined,
        label: 'Email',
        value: user.email,
        badge: user.emailVerifiedAt != null
            ? const Icon(Icons.verified, size: 16, color: Colors.green)
            : null,
        actions: [
          _InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.email, 'Email')),
          _InfoAction(Icons.send_outlined, 'Gửi email', () => _launchEmail(user.email)),
        ],
      ),
      if (user.phone != null && user.phone!.isNotEmpty)
        _InfoRowData(
          icon: Icons.phone_outlined,
          label: 'Số điện thoại',
          value: user.phone!,
          actions: [
            _InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.phone!, 'SĐT')),
            _InfoAction(Icons.call_outlined, 'Gọi điện', () => _launchPhone(user.phone!)),
          ],
        ),
      if (user.address != null && user.address!.isNotEmpty)
        _InfoRowData(
          icon: Icons.location_on_outlined,
          label: 'Địa chỉ',
          value: user.address!,
          actions: [
            _InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.address!, 'Địa chỉ')),
          ],
        ),
      if ((user.facebookUrl ?? user.facebook) != null &&
          (user.facebookUrl ?? user.facebook)!.isNotEmpty)
        _InfoRowData(
          icon: Icons.link,
          label: 'Facebook',
          value: (user.facebookUrl ?? user.facebook)!,
          actions: [
            _InfoAction(Icons.open_in_new, 'Mở', () => openUrl((user.facebookUrl ?? user.facebook)!)),
          ],
        ),
    ];
    return _buildInfoCard(rows);
  }

  bool _hasBusinessInfo(User user) =>
      (user.legalName != null && user.legalName!.isNotEmpty) ||
      (user.taxCode != null && user.taxCode!.isNotEmpty) ||
      (user.buyerCode != null && user.buyerCode!.isNotEmpty) ||
      (user.nationalId != null && user.nationalId!.isNotEmpty) ||
      (user.invoiceEmail != null && user.invoiceEmail!.isNotEmpty);

  Widget _buildBusinessCard(User user) {
    final rows = <_InfoRowData>[
      if (user.legalName != null && user.legalName!.isNotEmpty)
        _InfoRowData(
          icon: Icons.business_outlined,
          label: 'Tên pháp nhân',
          value: user.legalName!,
          actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.legalName!, 'Tên pháp nhân'))],
        ),
      if (user.taxCode != null && user.taxCode!.isNotEmpty)
        _InfoRowData(
          icon: Icons.receipt_outlined,
          label: 'Mã số thuế',
          value: user.taxCode!,
          actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.taxCode!, 'MST'))],
        ),
      if (user.invoiceEmail != null && user.invoiceEmail!.isNotEmpty)
        _InfoRowData(
          icon: Icons.mark_email_read_outlined,
          label: 'Email xuất hóa đơn',
          value: user.invoiceEmail!,
          actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.invoiceEmail!, 'Email HĐ'))],
        ),
      if (user.buyerCode != null && user.buyerCode!.isNotEmpty)
        _InfoRowData(
          icon: Icons.tag,
          label: 'Mã khách hàng',
          value: user.buyerCode!,
          actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.buyerCode!, 'Mã KH'))],
        ),
      if (user.nationalId != null && user.nationalId!.isNotEmpty)
        _InfoRowData(
          icon: Icons.badge_outlined,
          label: 'CMND / CCCD',
          value: user.nationalId!,
          actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.nationalId!, 'CCCD'))],
        ),
    ];
    return _buildInfoCard(rows);
  }

  Widget _buildAccountCard(User user) {
    final rows = <_InfoRowData>[
      _InfoRowData(
        icon: Icons.tag,
        label: 'ID',
        value: '#${user.id}',
        actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.id.toString(), 'ID'))],
      ),
      _InfoRowData(
        icon: Icons.person_outline,
        label: 'Username',
        value: user.username,
        actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.username, 'Username'))],
      ),
      if (user.createdAt != null)
        _InfoRowData(
          icon: Icons.calendar_today_outlined,
          label: 'Ngày tạo',
          value: DateHelper.formatDateTime(DateTime.parse(user.createdAt!)),
        ),
      if (user.updatedAt != null)
        _InfoRowData(
          icon: Icons.update_outlined,
          label: 'Cập nhật lần cuối',
          value: DateHelper.formatDateTime(DateTime.parse(user.updatedAt!)),
        ),
    ];
    return _buildInfoCard(rows);
  }

  bool _hasSocialInfo(User user) =>
      (user.googleId != null && user.googleId!.isNotEmpty) ||
      (user.facebookId != null && user.facebookId!.isNotEmpty) ||
      (user.telegramId != null && user.telegramId!.isNotEmpty) ||
      user.twoFactorConfirmedAt != null;

  Widget _buildSocialCard(User user) {
    final rows = <_InfoRowData>[
      if (user.googleId != null && user.googleId!.isNotEmpty)
        _InfoRowData(
          icon: Icons.g_mobiledata,
          label: 'Google',
          value: user.googleId!,
          actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.googleId!, 'Google ID'))],
        ),
      if (user.facebookId != null && user.facebookId!.isNotEmpty)
        _InfoRowData(
          icon: Icons.facebook,
          label: 'Facebook',
          value: user.facebookId!,
          actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.facebookId!, 'Facebook ID'))],
        ),
      if (user.telegramId != null && user.telegramId!.isNotEmpty)
        _InfoRowData(
          icon: Icons.telegram,
          label: 'Telegram',
          value: user.telegramId!,
          actions: [_InfoAction(Icons.copy, 'Copy', () => _copyToClipboard(user.telegramId!, 'Telegram ID'))],
        ),
      if (user.twoFactorConfirmedAt != null)
        _InfoRowData(
          icon: Icons.security,
          label: 'Xác thực 2 bước',
          value: 'Đã bật',
          valueColor: Colors.green,
        ),
    ];
    return _buildInfoCard(rows);
  }

  Widget _buildInfoRow(_InfoRowData data) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              data.icon,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: data.valueColor,
                            ),
                      ),
                    ),
                    if (data.badge != null) ...[
                      const SizedBox(width: 4),
                      data.badge!,
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (data.actions != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: data.actions!
                  .map(
                    (a) => IconButton(
                      icon: Icon(a.icon, size: 18),
                      onPressed: a.onTap,
                      tooltip: a.tooltip,
                      visualDensity: VisualDensity.compact,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_user == null) return const SizedBox.shrink();
    return _OrdersTabView(
      userId: _user!.id.toString(),
      orderService: _orderService,
    );
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      Toastr.success('Đã copy $label');
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        Toastr.error('Không thể mở ứng dụng email');
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        Toastr.error('Không thể gọi điện thoại');
      }
    }
  }
}

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
    this.actions,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? badge;
  final List<_InfoAction>? actions;
  final Color? valueColor;
}

class _InfoAction {
  const _InfoAction(this.icon, this.tooltip, this.onTap);

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
}

class _OrdersTabView extends StatefulWidget {
  final String userId;
  final OrderService orderService;

  const _OrdersTabView({required this.userId, required this.orderService});

  @override
  State<_OrdersTabView> createState() => _OrdersTabViewState();
}

class _OrdersTabViewState extends State<_OrdersTabView>
    with AutomaticKeepAliveClientMixin {
  PaginatedData<Order>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  static const int _perPage = 20;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final response = await widget.orderService.list(
        page: page,
        perPage: _perPage,
        userId: widget.userId,
      );

      if (!mounted) return;
      setState(() {
        _page = response.data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final orders = _page?.items ?? const <Order>[];
    final pagination = _page?.pagination;

    return Column(
      children: [
        if (_isLoading && _page == null)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text('Lỗi: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadOrders(page: _currentPage),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          )
        else if (orders.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text('Không có đơn hàng nào'),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadOrders(page: _currentPage),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderCard(order: order);
                },
              ),
            ),
          ),
        if (pagination != null && pagination.lastPage > 1)
          _buildPaginationControls(pagination),
      ],
    );
  }

  Widget _buildPaginationControls(Pagination pagination) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Trang ${pagination.currentPage}/${pagination.lastPage}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: !_isLoading && pagination.currentPage > 1
                ? () => _loadOrders(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed:
                !_isLoading && pagination.currentPage < pagination.lastPage
                ? () => _loadOrders(page: pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderDetailScreen(orderId: order.id.toString()),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đơn hàng #${order.id}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.createdAt != null
                        ? DateHelper.formatDateTime(order.createdAt!)
                        : 'N/A',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${order.itemCount} sản phẩm',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyHelper.formatCurrency(order.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (order.note != null && order.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.note!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
