import 'dart:async';

import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/services/customer_service.dart';
import 'package:fcode_pos/ui/components/copyable_icon_text.dart';
import 'package:fcode_pos/ui/components/icon_text.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/functions.dart';
import 'package:flutter/material.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _lastSearchValue = '';

  PaginatedData<User>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final currentValue = _searchController.text.trim();

    // Only trigger search if text actually changed
    if (currentValue == _lastSearchValue) {
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _lastSearchValue = currentValue;
      _loadCustomers(page: 1);
    });

    // Update UI for suffix icon
    if (mounted) setState(() {});
  }

  Future<void> _loadCustomers({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final response = await _customerService.list(
        search: _searchController.text.trim(),
        page: page,
        perPage: _perPage,
      );

      if (!mounted) return;
      setState(() {
        _page = response.data;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _page = null;
      });
    } catch (e, stackTrace) {
      debugPrintStack(
        stackTrace: stackTrace,
        label: 'Load customers error: $e',
      );
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải danh sách khách hàng.';
        _page = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToCustomerDetail(User user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerDetailScreen(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = _page?.items ?? const <User>[];
    final pagination = _page?.pagination;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          title: SearchBar(
            controller: _searchController,
            hintText: 'Tìm kiếm khách hàng',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            trailing: _searchController.text.isEmpty
                ? null
                : [
                    IconButton(
                      tooltip: 'Xóa',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _loadCustomers(page: 1);
                      },
                    ),
                  ],
            onSubmitted: (_) => _loadCustomers(page: 1),
            textInputAction: TextInputAction.search,
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
        body: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildContent(customers)),
            _buildPaginationControls(pagination),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<User> customers) {
    if (_isLoading && _page == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _loadCustomers(page: _currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (customers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Không tìm thấy khách hàng phù hợp'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCustomers(page: _currentPage),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: customers.length,
        separatorBuilder: (context, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final customer = customers[index];
          return _CustomerCard(
            user: customer,
            onTap: () => _navigateToCustomerDetail(customer),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(Pagination? pagination) {
    if (pagination == null || pagination.lastPage <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                ? () => _loadCustomers(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed:
                !_isLoading && pagination.currentPage < pagination.lastPage
                ? () => _loadCustomers(page: pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.user, this.onTap});

  final User user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = user.name.isNotEmpty ? user.name : user.username;
    final email = user.email;
    final facebookUrl = user.facebookUrl;
    final balanceLabel = CurrencyHelper.formatCurrency(user.balance);
    final phone = user.phone;
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 22, child: Text(initial)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.mail_outlined,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: IconText(
                      icon: Icons.account_balance_wallet_outlined,
                      value: balanceLabel,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (facebookUrl != null && facebookUrl.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => openUrl(facebookUrl),
                        child: IconText(
                          icon: Icons.link,
                          value: 'Facebook',
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                CopyableIconText(
                  icon: Icons.phone_outlined,
                  value: phone,
                  color: colorScheme.tertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
