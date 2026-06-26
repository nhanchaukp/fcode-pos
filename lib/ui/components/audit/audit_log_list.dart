import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/api/api_response.dart';
import 'package:fcode_pos/ui/components/audit/audit_tile.dart';
import 'package:flutter/material.dart';

typedef AuditFetcher =
    Future<ApiResponse<PaginatedData<Auditable>>> Function(int page);

/// Reusable audit log list widget with built-in pagination, pull-to-refresh,
/// loading, error, and empty states.
///
/// Can be embedded directly inside tabs or other screens.
class AuditLogList extends StatefulWidget {
  const AuditLogList({required this.fetcher, super.key});

  final AuditFetcher fetcher;

  @override
  State<AuditLogList> createState() => _AuditLogListState();
}

class _AuditLogListState extends State<AuditLogList> {
  final _scrollController = ScrollController();
  final List<Auditable> _items = [];

  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await widget.fetcher(_page);
      if (!mounted) return;
      final data = res.data;
      if (data == null) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _items.addAll(data.items);
        _hasMore = data.pagination.currentPage < data.pagination.lastPage;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _refresh, child: _buildBody());
  }

  Widget _buildBody() {
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _refresh,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 52,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử thay đổi',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: _items.length + (_hasMore || _isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final audit = _items[index];
        final isLast = index == _items.length - 1;
        return AuditTile(audit: audit, isLast: isLast);
      },
    );
  }
}
