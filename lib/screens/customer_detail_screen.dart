import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/order_detail_screen.dart';
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
  final String? userId;
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
          // Only show refresh button if userId is provided (can reload from API)
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
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildAccountInfoCard(),
          const SizedBox(height: 16),
          _buildContactInfoCard(),
          const SizedBox(height: 16),
          _buildAdditionalInfoCard(),
        ],
      ),
    );

    // Only enable pull-to-refresh if userId is provided
    if (widget.userId != null) {
      return RefreshIndicator(onRefresh: _loadCustomerDetail, child: content);
    }

    return content;
  }

  Widget _buildOrdersTab() {
    if (_user == null) return const SizedBox.shrink();
    return _OrdersTabView(
      userId: _user!.id.toString(),
      orderService: _orderService,
    );
  }

  Widget _buildProfileCard() {
    final user = _user!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  user.profilePhotoUrl != null &&
                      user.profilePhotoUrl!.isNotEmpty
                  ? NetworkImage(user.profilePhotoUrl!)
                  : user.avatar != null && user.avatar!.isNotEmpty
                  ? NetworkImage(user.avatar!)
                  : null,
              child:
                  (user.profilePhotoUrl == null ||
                          user.profilePhotoUrl!.isEmpty) &&
                      (user.avatar == null || user.avatar!.isEmpty)
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 40,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              user.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (user.fullname != null && user.fullname!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  user.fullname!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 8),
            // Username
            Text(
              '@${user.username}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // Balance
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Số dư: ${CurrencyHelper.formatCurrency(user.balance)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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

  Widget _buildAccountInfoCard() {
    final user = _user!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin tài khoản',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.tag,
              label: 'ID',
              value: user.id.toString(),
              onCopy: () => _copyToClipboard(user.id.toString(), 'ID'),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Username',
              value: user.username,
              onCopy: () => _copyToClipboard(user.username, 'Username'),
            ),
            if (user.currentTeamId != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                icon: Icons.group,
                label: 'Team ID',
                value: user.currentTeamId.toString(),
                onCopy: () =>
                    _copyToClipboard(user.currentTeamId.toString(), 'Team ID'),
              ),
            ],
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Ngày tạo',
              value: user.createdAt != null
                  ? DateHelper.formatDateTime(DateTime.parse(user.createdAt!))
                  : 'N/A',
            ),
            if (user.updatedAt != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                icon: Icons.update,
                label: 'Cập nhật lần cuối',
                value: DateHelper.formatDateTime(
                  DateTime.parse(user.updatedAt!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    final user = _user!;
    final hasEmail = user.email.isNotEmpty;
    final hasPhone = user.phone != null && user.phone!.isNotEmpty;
    final hasAddress = user.address != null && user.address!.isNotEmpty;
    final hasFacebook = user.facebook != null && user.facebook!.isNotEmpty;
    final hasProvinceId = user.provinceId != null;

    if (!hasEmail &&
        !hasPhone &&
        !hasAddress &&
        !hasFacebook &&
        !hasProvinceId) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin liên hệ',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (hasEmail) ...[
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: user.email,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.emailVerifiedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.verified,
                          size: 20,
                          color: Colors.green,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copyToClipboard(user.email, 'Email'),
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      icon: const Icon(Icons.email, size: 20),
                      onPressed: () => _launchEmail(user.email),
                      tooltip: 'Gửi email',
                    ),
                  ],
                ),
              ),
              if (hasPhone || hasAddress || hasFacebook || hasProvinceId)
                const Divider(height: 24),
            ],
            if (hasPhone) ...[
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Số điện thoại',
                value: user.phone!,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () =>
                          _copyToClipboard(user.phone!, 'Số điện thoại'),
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone, size: 20),
                      onPressed: () => _launchPhone(user.phone!),
                      tooltip: 'Gọi điện',
                    ),
                  ],
                ),
              ),
              if (hasAddress || hasFacebook || hasProvinceId)
                const Divider(height: 24),
            ],
            if (hasAddress) ...[
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Địa chỉ',
                value: user.address!,
                onCopy: () => _copyToClipboard(user.address!, 'Địa chỉ'),
              ),
              if (hasFacebook || hasProvinceId) const Divider(height: 24),
            ],
            if (hasProvinceId) ...[
              _buildInfoRow(
                icon: Icons.map,
                label: 'Province ID',
                value: user.provinceId.toString(),
                onCopy: () =>
                    _copyToClipboard(user.provinceId.toString(), 'Province ID'),
              ),
              if (hasFacebook) const Divider(height: 24),
            ],
            if (hasFacebook)
              _buildInfoRow(
                icon: Icons.facebook,
                label: 'Facebook URL',
                value: user.facebook!,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () =>
                          _copyToClipboard(user.facebook!, 'Facebook URL'),
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      onPressed: () => openUrl(user.facebook!),
                      tooltip: 'Mở',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    final user = _user!;
    final hasGoogleId = user.googleId != null && user.googleId!.isNotEmpty;
    final hasFacebookId =
        user.facebookId != null && user.facebookId!.isNotEmpty;
    final hasTelegramId =
        user.telegramId != null && user.telegramId!.isNotEmpty;
    final hasTwoFactor = user.twoFactorConfirmedAt != null;
    final hasProfilePhotoPath =
        user.profilePhotoPath != null && user.profilePhotoPath!.isNotEmpty;
    final hasSessionLogin =
        user.sessionLogin != null && user.sessionLogin!.isNotEmpty;
    final hasFacebook = user.facebook != null && user.facebook!.isNotEmpty;
    final hasFcmToken = user.fcmToken != null && user.fcmToken!.isNotEmpty;
    final hasSettings = user.settings != null && user.settings!.isNotEmpty;

    if (!hasGoogleId &&
        !hasFacebookId &&
        !hasTelegramId &&
        !hasTwoFactor &&
        !hasProfilePhotoPath &&
        !hasSessionLogin &&
        !hasFacebook &&
        !hasFcmToken &&
        !hasSettings) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin bổ sung',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (hasGoogleId) ...[
              const Divider(height: 24),
              _buildInfoRow(
                icon: Icons.g_mobiledata,
                label: 'Google ID',
                value: user.googleId!,
                onCopy: () => _copyToClipboard(user.googleId!, 'Google ID'),
              ),
              if (hasFacebookId || hasTelegramId || hasTwoFactor)
                const Divider(height: 24),
            ],
            if (hasFacebookId) ...[
              _buildInfoRow(
                icon: Icons.facebook,
                label: 'Facebook ID',
                value: user.facebookId!,
                onCopy: () => _copyToClipboard(user.facebookId!, 'Facebook ID'),
              ),
              if (hasTelegramId || hasTwoFactor) const Divider(height: 24),
            ],
            if (hasTelegramId) ...[
              _buildInfoRow(
                icon: Icons.telegram,
                label: 'Telegram ID',
                value: user.telegramId!,
                onCopy: () => _copyToClipboard(user.telegramId!, 'Telegram ID'),
              ),
              if (hasTwoFactor) const Divider(height: 24),
            ],
            if (hasTwoFactor) ...[
              _buildInfoRow(
                icon: Icons.security,
                label: 'Xác thực 2 bước',
                value:
                    'Đã bật từ ${DateHelper.formatDateTime(DateTime.parse(user.twoFactorConfirmedAt!))}',
                valueColor: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
    Widget? trailing,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          trailing
        else if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: onCopy,
            tooltip: 'Copy',
          ),
      ],
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
