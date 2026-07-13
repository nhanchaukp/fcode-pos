import 'dart:async';

import 'package:fcode_pos/ui/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Scaffold dùng chung với AppBar tuỳ biến (thay cho AppBar của Material).
///
/// Bố cục thanh trên cùng:
/// - Hàng trên (luôn ghim): [nút back?] + tiêu đề + tiêu đề phụ (nếu có), bên
///   phải là các [actions] (nếu có).
/// - Hàng dưới (tuỳ chọn): ô tìm kiếm, chỉ hiện đầy đủ khi trang ở trên cùng.
///   Khi cuộn xuống ô tìm kiếm thu gọn dần, cuộn về đúng đỉnh sẽ hiện lại.
///
/// Body được cung cấp qua [body] kèm một [ScrollController] để đồng bộ hành vi
/// thu gọn. Hãy gắn controller này vào scrollable chính của trang (ListView...).
class AppScaffold extends StatefulWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.showBack,
    this.onBack,
    this.actions = const [],
    this.enableSearch = false,
    this.searchHint = 'Tìm kiếm...',
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.searchDebounce = const Duration(milliseconds: 350),
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  /// Tiêu đề chính.
  final String title;

  /// Tiêu đề phụ (nếu có).
  final String? subtitle;

  /// Có hiện nút back bên trái hay không. Mặc định tự suy ra theo
  /// [Navigator.canPop].
  final bool? showBack;

  /// Xử lý khi bấm back. Mặc định [Navigator.maybePop].
  final VoidCallback? onBack;

  /// Các action bên phải (nếu có).
  final List<Widget> actions;

  /// Bật hàng ô tìm kiếm bên dưới.
  final bool enableSearch;

  final String searchHint;

  /// Controller cho ô tìm kiếm (tuỳ chọn). Nếu null sẽ tự tạo bên trong.
  final TextEditingController? searchController;

  /// Callback khi nội dung tìm kiếm đổi (đã debounce theo [searchDebounce]).
  final ValueChanged<String>? onSearchChanged;

  /// Callback khi người dùng submit ô tìm kiếm.
  final ValueChanged<String>? onSearchSubmitted;

  final Duration searchDebounce;

  /// Builder cho body, nhận [ScrollController] cần gắn vào scrollable chính.
  final Widget Function(BuildContext context, ScrollController controller) body;

  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final onBack = widget.onBack ?? () => Navigator.of(context).maybePop();
    final showBack = widget.showBack ?? Navigator.of(context).canPop();

    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Column(
        children: [
          _AppTopBar(
            title: widget.title,
            subtitle: widget.subtitle,
            showBack: showBack,
            onBack: onBack,
            actions: widget.actions,
            enableSearch: widget.enableSearch,
            searchHint: widget.searchHint,
            searchController: widget.searchController,
            onSearchChanged: widget.onSearchChanged,
            onSearchSubmitted: widget.onSearchSubmitted,
            searchDebounce: widget.searchDebounce,
            scrollController: _scrollController,
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: widget.body(context, _scrollController),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// Thanh AppBar tuỳ biến: hàng tiêu đề ghim + hàng tìm kiếm thu gọn theo cuộn.
class _AppTopBar extends StatelessWidget {
  const _AppTopBar({
    required this.title,
    required this.subtitle,
    required this.showBack,
    required this.onBack,
    required this.actions,
    required this.enableSearch,
    required this.searchHint,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.searchDebounce,
    required this.scrollController,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback onBack;
  final List<Widget> actions;
  final bool enableSearch;
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final Duration searchDebounce;
  final ScrollController scrollController;

  /// Chiều cao hàng tiêu đề (compact).
  static const double _titleRowHeight = 44;

  /// Chiều cao hàng ô tìm kiếm, cũng là ngưỡng cuộn để thu gọn.
  static const double _searchRowHeight = 44;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final offset =
            scrollController.hasClients ? scrollController.offset : 0.0;
        // 0 = mở hết (ở đỉnh), 1 = thu gọn hết (đã cuộn xuống).
        final collapse = enableSearch
            ? (offset / _searchRowHeight).clamp(0.0, 1.0)
            : 0.0;
        final scrolledUnder = offset > 0.5;

        return Material(
          color: scrolledUnder ? cs.surfaceContainer : cs.surface,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTitleRow(context),
                if (enableSearch)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: 1 - collapse,
                      child: Opacity(
                        opacity: 1 - collapse,
                        child: _buildSearchRow(context),
                      ),
                    ),
                  ),
                if (scrolledUnder)
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      height: _titleRowHeight,
      child: Padding(
        padding: EdgeInsets.only(
          left: showBack ? 0 : AppSpacing.m,
          right: AppSpacing.xs,
        ),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                iconSize: 20,
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              Row(mainAxisSize: MainAxisSize.min, children: actions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.xs,
      ),
      child: _SearchField(
        hint: searchHint,
        controller: searchController,
        onChanged: onSearchChanged,
        onSubmitted: onSearchSubmitted,
        debounce: searchDebounce,
      ),
    );
  }
}

/// Ô tìm kiếm nội bộ: có debounce cho [onChanged] và nút xoá nhanh.
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.hint,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.debounce,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Duration debounce;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _lastNotified = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _lastNotified = _controller.text.trim();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // Controller cũng notify khi chỉ đổi selection (focus/tap), không phải text.
    final current = _controller.text.trim();
    if (current == _lastNotified) {
      if (mounted) setState(() {});
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () {
      if (!mounted) return;
      final value = _controller.text.trim();
      if (value == _lastNotified) return;
      _lastNotified = value;
      widget.onChanged?.call(value);
    });
    if (mounted) setState(() {});
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    if (_lastNotified.isEmpty) return;
    _lastNotified = '';
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      style: const TextStyle(fontSize: 13),
      textInputAction: TextInputAction.search,
      onSubmitted: (v) {
        final value = v.trim();
        if (value == _lastNotified) return;
        _debounce?.cancel();
        _lastNotified = value;
        widget.onSubmitted?.call(value);
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        hintText: widget.hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: cs.onSurfaceVariant.withValues(alpha: 0.55),
        ),
        prefixIcon: const Icon(Icons.search, size: 18),
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 32),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xoá',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.close, size: 16),
                onPressed: _clear,
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        border: OutlineInputBorder(
          borderRadius: AppRadius.s,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.s,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.s,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
