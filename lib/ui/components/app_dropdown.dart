import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';

typedef AppDropdownItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  bool isSelected,
  VoidCallback onItemSelect,
);

typedef AppDropdownHeaderBuilder<T> = Widget Function(
  BuildContext context,
  T selectedItem,
  bool enabled,
);

typedef AppDropdownHeaderListBuilder<T> = Widget Function(
  BuildContext context,
  List<T> selectedItems,
  bool enabled,
);

typedef AppDropdownHintBuilder = Widget Function(
  BuildContext context,
  String hint,
  bool enabled,
);

typedef AppDropdownNoResultFoundBuilder = Widget Function(
  BuildContext context,
  String text,
);

typedef AppDropdownGroupHeaderBuilder = Widget Function(
  BuildContext context,
  String group,
);

/// Helper to generate theme-aware [CustomDropdownDecoration] matching the app design system.
class AppDropdownDecoration {
  static CustomDropdownDecoration of(
    BuildContext context, {
    Widget? prefixIcon,
    Widget? closedSuffixIcon,
    Widget? expandedSuffixIcon,
    TextStyle? headerStyle,
    TextStyle? hintStyle,
    TextStyle? listItemStyle,
    TextStyle? noResultFoundStyle,
    Color? closedFillColor,
    Color? expandedFillColor,
    BoxBorder? closedBorder,
    BoxBorder? expandedBorder,
    BorderRadius? borderRadius,
    List<BoxShadow>? closedShadow,
    List<BoxShadow>? expandedShadow,
    ListItemDecoration? listItemDecoration,
    SearchFieldDecoration? searchFieldDecoration,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final cardBorderColor =
        colorScheme.outlineVariant.a == 0
            ? Colors.transparent
            : colorScheme.outlineVariant.applyOpacity(0.5);

    final defaultBorder = Border.all(color: cardBorderColor, width: 1);
    final defaultExpandedBorder = Border.all(
      color: colorScheme.primary.applyOpacity(0.8),
      width: 1.2,
    );
    final defaultBr = borderRadius ?? BorderRadius.circular(10);

    return CustomDropdownDecoration(
      closedFillColor:
          closedFillColor ??
          (isDark
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerLowest),
      expandedFillColor:
          expandedFillColor ??
          (isDark
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerLowest),
      closedBorder: closedBorder ?? defaultBorder,
      expandedBorder: expandedBorder ?? defaultExpandedBorder,
      closedBorderRadius: defaultBr,
      expandedBorderRadius: defaultBr,
      closedShadow:
          closedShadow ??
          [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
      expandedShadow:
          expandedShadow ??
          [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
      headerStyle:
          headerStyle ??
          TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
      hintStyle:
          hintStyle ??
          TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant.applyOpacity(0.55),
          ),
      listItemStyle:
          listItemStyle ??
          TextStyle(fontSize: 13, color: colorScheme.onSurface),
      noResultFoundStyle:
          noResultFoundStyle ??
          TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant.applyOpacity(0.6),
          ),
      listItemDecoration:
          listItemDecoration ??
          ListItemDecoration(
            selectedColor: colorScheme.primary.withValues(alpha: 0.1),
            highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          ),
      searchFieldDecoration: searchFieldDecoration ??
          SearchFieldDecoration(
            fillColor: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: defaultBr,
              borderSide: BorderSide(color: cardBorderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: defaultBr,
              borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
            ),
            hintStyle: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant.applyOpacity(0.55),
            ),
            textStyle: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
      prefixIcon: prefixIcon,
      closedSuffixIcon: closedSuffixIcon,
      expandedSuffixIcon: expandedSuffixIcon,
    );
  }
}

enum _AppDropdownVariant {
  simple,
  search,
  searchRequest,
  multiSelect,
  multiSelectSearch,
  multiSelectSearchRequest,
}

/// A theme-aware wrapper around [DropdownFlutter] that:
/// 1. Prevents duplicate border rendering caused by ambient [InputDecorationTheme].
/// 2. Automatically inherits theme colors, borders, shadows, and fonts.
/// 3. Supports all standard [DropdownFlutter] constructors (`simple`, `search`, `searchRequest`, `multiSelect`, etc.).
class AppDropdown<T> extends StatelessWidget {
  final _AppDropdownVariant _variant;

  // Common properties
  final List<T>? items;
  final T? initialItem;
  final List<T>? initialItems;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<List<T>>? onListChanged;
  final String? Function(T?)? validator;
  final String? Function(List<T>)? listValidator;
  final String? hintText;
  final String? labelText;
  final String? searchHintText;
  final Widget? prefixIcon;
  final CustomDropdownDecoration? decoration;
  final CustomDropdownDisabledDecoration? disabledDecoration;
  final SingleSelectController<T?>? controller;
  final MultiSelectController<T>? multiSelectController;
  final OverlayPortalController? overlayController;
  final ScrollController? itemsScrollController;
  final AppDropdownHeaderBuilder<T>? headerBuilder;
  final AppDropdownHeaderListBuilder<T>? headerListBuilder;
  final AppDropdownItemBuilder<T>? listItemBuilder;
  final AppDropdownHintBuilder? hintBuilder;
  final AppDropdownNoResultFoundBuilder? noResultFoundBuilder;
  final AppDropdownGroupHeaderBuilder? groupHeaderBuilder;
  final String Function(T)? groupBy;
  final Future<List<T>> Function(String)? futureRequest;
  final Duration? futureRequestDelay;
  final Widget? searchRequestLoadingIndicator;
  final String? noResultFoundText;
  final double? overlayHeight;
  final double? listItemHeight;
  final EdgeInsets? listItemPadding;
  final EdgeInsets? itemsListPadding;
  final EdgeInsets? closedHeaderPadding;
  final EdgeInsets? expandedHeaderPadding;
  final bool enabled;
  final bool validateOnChange;
  final bool canCloseOutsideBounds;
  final bool hideSelectedFieldWhenExpanded;
  final bool closeDropDownOnClearFilterSearch;
  final bool excludeSelected;
  final bool enableHapticFeedback;
  final bool enableKeyboardNavigation;
  final bool highlightMatchedText;
  final bool showSelectAll;
  final String? selectAllText;
  final String? clearAllText;
  final int recentSelectionsMaxCount;
  final List<T>? initialRecentItems;
  final ValueChanged<List<T>>? onRecentItemsChanged;
  final Duration? animationDuration;
  final Curve? animationCurve;
  final int maxlines;

  /// Default simple dropdown
  const AppDropdown({
    super.key,
    required this.items,
    this.initialItem,
    this.onChanged,
    this.validator,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.decoration,
    this.disabledDecoration,
    this.controller,
    this.overlayController,
    this.itemsScrollController,
    this.headerBuilder,
    this.listItemBuilder,
    this.hintBuilder,
    this.overlayHeight,
    this.listItemHeight,
    this.listItemPadding,
    this.itemsListPadding,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.enabled = true,
    this.validateOnChange = true,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.excludeSelected = false,
    this.enableHapticFeedback = false,
    this.enableKeyboardNavigation = false,
    this.animationDuration,
    this.animationCurve,
    this.maxlines = 1,
    this.groupBy,
    this.groupHeaderBuilder,
    this.recentSelectionsMaxCount = 0,
    this.initialRecentItems,
    this.onRecentItemsChanged,
  })  : _variant = _AppDropdownVariant.simple,
        initialItems = null,
        onListChanged = null,
        listValidator = null,
        searchHintText = null,
        futureRequest = null,
        futureRequestDelay = null,
        searchRequestLoadingIndicator = null,
        noResultFoundText = null,
        noResultFoundBuilder = null,
        headerListBuilder = null,
        multiSelectController = null,
        closeDropDownOnClearFilterSearch = false,
        highlightMatchedText = false,
        showSelectAll = false,
        selectAllText = null,
        clearAllText = null;

  /// Searchable dropdown with local filtering
  const AppDropdown.search({
    super.key,
    required this.items,
    this.initialItem,
    this.onChanged,
    this.validator,
    this.hintText,
    this.labelText,
    this.searchHintText,
    this.prefixIcon,
    this.decoration,
    this.disabledDecoration,
    this.controller,
    this.overlayController,
    this.itemsScrollController,
    this.headerBuilder,
    this.listItemBuilder,
    this.hintBuilder,
    this.noResultFoundBuilder,
    this.noResultFoundText,
    this.overlayHeight,
    this.listItemHeight,
    this.listItemPadding,
    this.itemsListPadding,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.enabled = true,
    this.validateOnChange = true,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.closeDropDownOnClearFilterSearch = false,
    this.excludeSelected = false,
    this.enableHapticFeedback = false,
    this.enableKeyboardNavigation = false,
    this.highlightMatchedText = false,
    this.animationDuration,
    this.animationCurve,
    this.maxlines = 1,
    this.groupBy,
    this.groupHeaderBuilder,
    this.recentSelectionsMaxCount = 0,
    this.initialRecentItems,
    this.onRecentItemsChanged,
  })  : _variant = _AppDropdownVariant.search,
        initialItems = null,
        onListChanged = null,
        listValidator = null,
        futureRequest = null,
        futureRequestDelay = null,
        searchRequestLoadingIndicator = null,
        headerListBuilder = null,
        multiSelectController = null,
        showSelectAll = false,
        selectAllText = null,
        clearAllText = null;

  /// Searchable dropdown with async API request
  const AppDropdown.searchRequest({
    super.key,
    required this.futureRequest,
    this.futureRequestDelay,
    this.items,
    this.initialItem,
    this.onChanged,
    this.validator,
    this.hintText,
    this.labelText,
    this.searchHintText,
    this.prefixIcon,
    this.decoration,
    this.disabledDecoration,
    this.controller,
    this.overlayController,
    this.itemsScrollController,
    this.headerBuilder,
    this.listItemBuilder,
    this.hintBuilder,
    this.noResultFoundBuilder,
    this.noResultFoundText,
    this.searchRequestLoadingIndicator,
    this.overlayHeight,
    this.listItemHeight,
    this.listItemPadding,
    this.itemsListPadding,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.enabled = true,
    this.validateOnChange = true,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.enableHapticFeedback = false,
    this.enableKeyboardNavigation = false,
    this.animationDuration,
    this.animationCurve,
    this.maxlines = 1,
  })  : _variant = _AppDropdownVariant.searchRequest,
        initialItems = null,
        onListChanged = null,
        listValidator = null,
        headerListBuilder = null,
        multiSelectController = null,
        closeDropDownOnClearFilterSearch = false,
        excludeSelected = false,
        highlightMatchedText = false,
        showSelectAll = false,
        selectAllText = null,
        clearAllText = null,
        groupBy = null,
        groupHeaderBuilder = null,
        recentSelectionsMaxCount = 0,
        initialRecentItems = null,
        onRecentItemsChanged = null;

  /// Multi-select dropdown
  const AppDropdown.multiSelect({
    super.key,
    required this.items,
    this.initialItems,
    this.onListChanged,
    this.listValidator,
    this.multiSelectController,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.decoration,
    this.disabledDecoration,
    this.overlayController,
    this.itemsScrollController,
    this.headerListBuilder,
    this.listItemBuilder,
    this.hintBuilder,
    this.overlayHeight,
    this.listItemHeight,
    this.listItemPadding,
    this.itemsListPadding,
    this.closedHeaderPadding,
    this.expandedHeaderPadding,
    this.enabled = true,
    this.validateOnChange = true,
    this.canCloseOutsideBounds = true,
    this.hideSelectedFieldWhenExpanded = false,
    this.enableHapticFeedback = false,
    this.enableKeyboardNavigation = false,
    this.showSelectAll = false,
    this.selectAllText,
    this.clearAllText,
    this.animationDuration,
    this.animationCurve,
    this.maxlines = 1,
    this.groupBy,
    this.groupHeaderBuilder,
    this.recentSelectionsMaxCount = 0,
    this.initialRecentItems,
    this.onRecentItemsChanged,
  })  : _variant = _AppDropdownVariant.multiSelect,
        initialItem = null,
        onChanged = null,
        validator = null,
        controller = null,
        headerBuilder = null,
        searchHintText = null,
        futureRequest = null,
        futureRequestDelay = null,
        searchRequestLoadingIndicator = null,
        noResultFoundText = null,
        noResultFoundBuilder = null,
        closeDropDownOnClearFilterSearch = false,
        excludeSelected = false,
        highlightMatchedText = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveHint = hintText ?? labelText;
    final effectiveDecoration =
        decoration ?? AppDropdownDecoration.of(context, prefixIcon: prefixIcon);

    const defaultHeaderPadding = EdgeInsets.symmetric(
      vertical: 13.5,
      horizontal: 12,
    );
    const defaultListItemPadding = EdgeInsets.symmetric(
      vertical: 10,
      horizontal: 12,
    );

    final effectiveClosedHeaderPadding =
        closedHeaderPadding ?? defaultHeaderPadding;
    final effectiveExpandedHeaderPadding =
        expandedHeaderPadding ?? defaultHeaderPadding;
    final effectiveListItemPadding =
        listItemPadding ?? defaultListItemPadding;

    Widget dropdownChild;

    switch (_variant) {
      case _AppDropdownVariant.simple:
        dropdownChild = DropdownFlutter<T>(
          items: items,
          initialItem: initialItem,
          onChanged: onChanged,
          validator: validator,
          hintText: effectiveHint,
          decoration: effectiveDecoration,
          disabledDecoration: disabledDecoration,
          controller: controller,
          overlayController: overlayController,
          itemsScrollController: itemsScrollController,
          headerBuilder: headerBuilder,
          listItemBuilder: listItemBuilder,
          hintBuilder: hintBuilder,
          overlayHeight: overlayHeight,
          listItemHeight: listItemHeight,
          listItemPadding: effectiveListItemPadding,
          itemsListPadding: itemsListPadding,
          closedHeaderPadding: effectiveClosedHeaderPadding,
          expandedHeaderPadding: effectiveExpandedHeaderPadding,
          enabled: enabled,
          validateOnChange: validateOnChange,
          canCloseOutsideBounds: canCloseOutsideBounds,
          hideSelectedFieldWhenExpanded: hideSelectedFieldWhenExpanded,
          excludeSelected: excludeSelected,
          enableHapticFeedback: enableHapticFeedback,
          enableKeyboardNavigation: enableKeyboardNavigation,
          animationDuration: animationDuration,
          animationCurve: animationCurve,
          maxlines: maxlines,
          groupBy: groupBy,
          groupHeaderBuilder: groupHeaderBuilder,
          recentSelectionsMaxCount: recentSelectionsMaxCount,
          initialRecentItems: initialRecentItems,
          onRecentItemsChanged: onRecentItemsChanged,
        );

      case _AppDropdownVariant.search:
        dropdownChild = DropdownFlutter<T>.search(
          items: items,
          initialItem: initialItem,
          onChanged: onChanged,
          validator: validator,
          hintText: effectiveHint,
          searchHintText: searchHintText,
          decoration: effectiveDecoration,
          disabledDecoration: disabledDecoration,
          controller: controller,
          overlayController: overlayController,
          itemsScrollController: itemsScrollController,
          headerBuilder: headerBuilder,
          listItemBuilder: listItemBuilder,
          hintBuilder: hintBuilder,
          noResultFoundBuilder: noResultFoundBuilder,
          noResultFoundText: noResultFoundText,
          overlayHeight: overlayHeight,
          listItemHeight: listItemHeight,
          listItemPadding: effectiveListItemPadding,
          itemsListPadding: itemsListPadding,
          closedHeaderPadding: effectiveClosedHeaderPadding,
          expandedHeaderPadding: effectiveExpandedHeaderPadding,
          enabled: enabled,
          validateOnChange: validateOnChange,
          canCloseOutsideBounds: canCloseOutsideBounds,
          hideSelectedFieldWhenExpanded: hideSelectedFieldWhenExpanded,
          closeDropDownOnClearFilterSearch: closeDropDownOnClearFilterSearch,
          excludeSelected: excludeSelected,
          enableHapticFeedback: enableHapticFeedback,
          enableKeyboardNavigation: enableKeyboardNavigation,
          highlightMatchedText: highlightMatchedText,
          animationDuration: animationDuration,
          animationCurve: animationCurve,
          maxlines: maxlines,
          groupBy: groupBy,
          groupHeaderBuilder: groupHeaderBuilder,
          recentSelectionsMaxCount: recentSelectionsMaxCount,
          initialRecentItems: initialRecentItems,
          onRecentItemsChanged: onRecentItemsChanged,
        );

      case _AppDropdownVariant.searchRequest:
        dropdownChild = DropdownFlutter<T>.searchRequest(
          futureRequest: futureRequest!,
          futureRequestDelay: futureRequestDelay,
          items: items,
          initialItem: initialItem,
          onChanged: onChanged,
          validator: validator,
          hintText: effectiveHint,
          searchHintText: searchHintText,
          decoration: effectiveDecoration,
          disabledDecoration: disabledDecoration,
          controller: controller,
          overlayController: overlayController,
          itemsScrollController: itemsScrollController,
          headerBuilder: headerBuilder,
          listItemBuilder: listItemBuilder,
          hintBuilder: hintBuilder,
          noResultFoundBuilder: noResultFoundBuilder,
          noResultFoundText: noResultFoundText,
          searchRequestLoadingIndicator: searchRequestLoadingIndicator,
          overlayHeight: overlayHeight,
          listItemHeight: listItemHeight,
          listItemPadding: effectiveListItemPadding,
          itemsListPadding: itemsListPadding,
          closedHeaderPadding: effectiveClosedHeaderPadding,
          expandedHeaderPadding: effectiveExpandedHeaderPadding,
          enabled: enabled,
          validateOnChange: validateOnChange,
          canCloseOutsideBounds: canCloseOutsideBounds,
          hideSelectedFieldWhenExpanded: hideSelectedFieldWhenExpanded,
          enableHapticFeedback: enableHapticFeedback,
          enableKeyboardNavigation: enableKeyboardNavigation,
          animationDuration: animationDuration,
          animationCurve: animationCurve,
          maxlines: maxlines,
        );

      case _AppDropdownVariant.multiSelect:
        dropdownChild = DropdownFlutter<T>.multiSelect(
          items: items,
          initialItems: initialItems,
          onListChanged: onListChanged,
          listValidator: listValidator,
          multiSelectController: multiSelectController,
          hintText: effectiveHint,
          decoration: effectiveDecoration,
          disabledDecoration: disabledDecoration,
          overlayController: overlayController,
          itemsScrollController: itemsScrollController,
          headerListBuilder: headerListBuilder,
          listItemBuilder: listItemBuilder,
          hintBuilder: hintBuilder,
          overlayHeight: overlayHeight,
          listItemHeight: listItemHeight,
          listItemPadding: effectiveListItemPadding,
          itemsListPadding: itemsListPadding,
          closedHeaderPadding: effectiveClosedHeaderPadding,
          expandedHeaderPadding: effectiveExpandedHeaderPadding,
          enabled: enabled,
          validateOnChange: validateOnChange,
          canCloseOutsideBounds: canCloseOutsideBounds,
          hideSelectedFieldWhenExpanded: hideSelectedFieldWhenExpanded,
          enableHapticFeedback: enableHapticFeedback,
          enableKeyboardNavigation: enableKeyboardNavigation,
          showSelectAll: showSelectAll,
          selectAllText: selectAllText,
          clearAllText: clearAllText,
          animationDuration: animationDuration,
          animationCurve: animationCurve,
          maxlines: maxlines,
          groupBy: groupBy,
          groupHeaderBuilder: groupHeaderBuilder,
          recentSelectionsMaxCount: recentSelectionsMaxCount,
          initialRecentItems: initialRecentItems,
          onRecentItemsChanged: onRecentItemsChanged,
        );

      case _AppDropdownVariant.multiSelectSearch:
      case _AppDropdownVariant.multiSelectSearchRequest:
        dropdownChild = DropdownFlutter<T>(
          items: items,
          initialItem: initialItem,
          onChanged: onChanged,
          validator: validator,
          hintText: effectiveHint,
          decoration: effectiveDecoration,
          closedHeaderPadding: effectiveClosedHeaderPadding,
          expandedHeaderPadding: effectiveExpandedHeaderPadding,
          listItemPadding: effectiveListItemPadding,
        );
    }

    // Reset outer InputDecorationTheme borders to avoid duplicate/double borders
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      child: dropdownChild,
    );
  }
}
