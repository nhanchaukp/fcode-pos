import 'dart:async';

import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/supply/supply_form_screen.dart';
import 'package:fcode_pos/services/supply_service.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:flutter/material.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _supplyService = SupplyService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _lastSearchValue = '';

  PaginatedData<Supply>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSuppliers();
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
      _loadSuppliers(page: 1);
    });

    // Update UI for suffix icon
    if (mounted) setState(() {});
  }

  Future<void> _loadSuppliers({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final response = await _supplyService.list(
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
        label: 'Load suppliers error: $e',
      );
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải danh sách nhà cung cấp.';
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

  @override
  Widget build(BuildContext context) {
    final supplies = _page?.items ?? const <Supply>[];
    final pagination = _page?.pagination;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          title: SearchBar(
            controller: _searchController,
            hintText: 'Tìm kiếm nhà cung cấp',
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
                        _loadSuppliers(page: 1);
                      },
                    ),
                  ],
            onSubmitted: (_) => _loadSuppliers(page: 1),
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
            Expanded(child: _buildContent(supplies)),
            _buildPaginationControls(pagination),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _handleCreateSupply,
          tooltip: 'Thêm nhà cung cấp',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _handleCreateSupply() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SupplyFormScreen()),
    );

    if (result == true && mounted) {
      _loadSuppliers(page: _currentPage);
    }
  }

  Future<void> _handleEditSupply(Supply supply) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => SupplyFormScreen(supply: supply)),
    );

    if (result == true && mounted) {
      _loadSuppliers(page: _currentPage);
    }
  }

  Widget _buildContent(List<Supply> supplies) {
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
              onPressed: () => _loadSuppliers(page: _currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (supplies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store_mall_directory_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text('Không tìm thấy nhà cung cấp phù hợp'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSuppliers(page: _currentPage),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: supplies.length,
        separatorBuilder: (context, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final supply = supplies[index];
          return _SupplyCard(
            supply: supply,
            onTap: () => _handleEditSupply(supply),
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
                ? () => _loadSuppliers(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed:
                !_isLoading && pagination.currentPage < pagination.lastPage
                ? () => _loadSuppliers(page: pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _SupplyCard extends StatelessWidget {
  const _SupplyCard({required this.supply, required this.onTap});

  final Supply supply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final createdLabel = DateHelper.formatDate(supply.createdAt);
    final updatedLabel = DateHelper.timeAgo(supply.updatedAt);
    final description = supply.content;

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
                children: [
                  Icon(
                    Icons.warehouse_outlined,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      supply.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _IconValue(
                      icon: Icons.event_outlined,
                      value: createdLabel,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _IconValue(
                      icon: Icons.update_outlined,
                      value: updatedLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconValue extends StatelessWidget {
  const _IconValue({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
