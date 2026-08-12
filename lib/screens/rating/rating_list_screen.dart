import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/rating_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/badge/status_badges.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class RatingListScreen extends StatefulWidget {
  const RatingListScreen({super.key});

  @override
  State<RatingListScreen> createState() => _RatingListScreenState();
}

class _RatingListScreenState extends State<RatingListScreen> {
  final _ratingService = RatingService();

  PaginatedData<Rating>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool? _approvedFilter;
  static const int _perPage = 10;
  final Set<int> _actioningIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final response = await _ratingService.list(
        approved: _approvedFilter,
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
      debugPrintStack(stackTrace: stackTrace, label: 'Load ratings error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải danh sách đánh giá.';
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

  Future<void> _toggleApproval(Rating rating) async {
    if (_actioningIds.contains(rating.id)) return;

    setState(() {
      _actioningIds.add(rating.id);
    });

    try {
      if (rating.approved) {
        await _ratingService.reject(rating.id);
      } else {
        await _ratingService.approve(rating.id);
      }

      if (!mounted) return;

      // Reload current page
      await _loadRatings(page: _currentPage);

      if (!mounted) return;
      Toastr.success(
        rating.approved ? 'Đã hủy duyệt đánh giá' : 'Đã duyệt đánh giá',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Toastr.error(e.message);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Có lỗi xảy ra: $e');
    } finally {
      if (mounted) {
        setState(() {
          _actioningIds.remove(rating.id);
        });
      }
    }
  }

  Future<void> _deleteRating(Rating rating) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (_actioningIds.contains(rating.id)) return;

    setState(() {
      _actioningIds.add(rating.id);
    });

    try {
      await _ratingService.delete(rating.id);

      if (!mounted) return;

      await _loadRatings(page: _currentPage);

      if (!mounted) return;
      Toastr.success('Đã xóa đánh giá');
    } on ApiException catch (e) {
      if (!mounted) return;
      Toastr.error(e.message);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Có lỗi xảy ra: $e');
    } finally {
      if (mounted) {
        setState(() {
          _actioningIds.remove(rating.id);
        });
      }
    }
  }

  void _changeFilter(bool? approved) {
    setState(() {
      _approvedFilter = approved;
    });
    _loadRatings(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    final ratings = _page?.items ?? const <Rating>[];
    final pagination = _page?.pagination;

    return AppScaffold(
      title: 'Đánh giá',
      actions: [
        PopupMenuButton<bool?>(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Lọc theo trạng thái',
          onSelected: _changeFilter,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: null,
              child: Row(
                children: [
                  if (_approvedFilter == null)
                    const Icon(Icons.check, size: 20)
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  const Text('Tất cả'),
                ],
              ),
            ),
            PopupMenuItem(
              value: true,
              child: Row(
                children: [
                  if (_approvedFilter == true)
                    const Icon(Icons.check, size: 20)
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  const Text('Đã duyệt'),
                ],
              ),
            ),
            PopupMenuItem(
              value: false,
              child: Row(
                children: [
                  if (_approvedFilter == false)
                    const Icon(Icons.check, size: 20)
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  const Text('Chưa duyệt'),
                ],
              ),
            ),
          ],
        ),
      ],
      body: (context, scrollController) => Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent(ratings, scrollController)),
          _buildPaginationControls(pagination),
        ],
      ),
    );
  }

  Widget _buildContent(List<Rating> ratings, ScrollController scrollController) {
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
              onPressed: () => _loadRatings(page: _currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (ratings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Không có đánh giá nào'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadRatings(page: _currentPage),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: ratings.length,
        itemBuilder: (context, index) {
          final rating = ratings[index];
          final isActioning = _actioningIds.contains(rating.id);
          return _RatingTile(
            rating: rating,
            isActioning: isActioning,
            onToggleApproval: () => _toggleApproval(rating),
            onDelete: () => _deleteRating(rating),
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
                ? () => _loadRatings(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed:
                !_isLoading && pagination.currentPage < pagination.lastPage
                ? () => _loadRatings(page: pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.rating,
    required this.isActioning,
    required this.onToggleApproval,
    required this.onDelete,
  });

  final Rating rating;
  final bool isActioning;
  final VoidCallback onToggleApproval;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = rating.user;
    final rateable = rating.rateable;
    final displayName = user != null
        ? (user.name.isNotEmpty ? user.name : user.username)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayName != null)
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (rateable != null) ...[
                      if (displayName != null) const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              rateable.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ApprovalChip(approved: rating.approved),
                  const SizedBox(height: 4),
                  _buildStars(rating.rating),
                ],
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              rating.comment!,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              if (rating.createdAt != null) ...[
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Text(
                  DateHelper.formatDateTime(rating.createdAt!),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(),
              if (isActioning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                IconButton(
                  icon: Icon(
                    rating.approved ? Icons.cancel : Icons.check_circle,
                    size: 20,
                    color: rating.approved
                        ? colorScheme.outline
                        : colorScheme.primary,
                  ),
                  tooltip: rating.approved ? 'Hủy duyệt' : 'Duyệt',
                  onPressed: onToggleApproval,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  tooltip: 'Xóa',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 14,
        ),
      ),
    );
  }
}

class _ApprovalChip extends StatelessWidget {
  const _ApprovalChip({required this.approved});

  final bool approved;

  @override
  Widget build(BuildContext context) {
    return ApprovalStatusBadge(isApproved: approved);
  }
}
