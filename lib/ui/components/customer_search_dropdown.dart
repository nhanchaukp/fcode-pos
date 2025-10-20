import 'dart:async';

import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/customer_service.dart';
import 'package:flutter/material.dart';

class CustomerSearchDropdown extends StatefulWidget {
  final User? selectedUser;
  final Function(User) onUserSelected;
  final VoidCallback onUserCleared;

  const CustomerSearchDropdown({
    this.selectedUser,
    required this.onUserSelected,
    required this.onUserCleared,
    super.key,
  });

  @override
  State<CustomerSearchDropdown> createState() => _CustomerSearchDropdownState();
}

class _CustomerSearchDropdownState extends State<CustomerSearchDropdown> {
  late TextEditingController _searchController;
  final _customerService = CustomerService();
  List<User> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  User? _currentSelectedUser;

  @override
  void initState() {
    super.initState();
    _currentSelectedUser = widget.selectedUser;
    _searchController =
        TextEditingController(text: widget.selectedUser?.name ?? '');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchCustomers(_searchController.text);
    });
  }

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) {
      // Clear results when search is cleared
      if (!mounted) return;
      setState(() => _searchResults = []);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _customerService.list(
        search: query,
        page: 1,
        perPage: 20,
      );
      if (!mounted) return;
      setState(() => _searchResults = result.data);
    } catch (e) {
      debugPrint('Error searching customers: $e');
      if (!mounted) return;
      setState(() => _searchResults = []);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<User>(
      controller: _searchController,
      enableSearch: true,
      requestFocusOnTap: true,
      onSelected: (User? user) {
        if (user != null) {
          widget.onUserSelected(user);
          setState(() {
            _currentSelectedUser = user;
            _searchController.text = user.name;
          });
        }
      },
      expandedInsets: EdgeInsets.zero,
      menuHeight: 300,
      dropdownMenuEntries: _buildDropdownEntries(),
      hintText: widget.selectedUser?.name ?? 'Tìm khách hàng',
      label: const Text('Khách hàng'),
      leadingIcon: const Icon(Icons.person_search_sharp),
      trailingIcon: _currentSelectedUser != null
          ? GestureDetector(
              onTap: () {
                _searchController.clear();
                widget.onUserCleared();
                setState(() {
                  _currentSelectedUser = null;
                  _searchResults = [];
                });
              },
              child: const Icon(Icons.close),
            )
          : null,
    );
  }

  List<DropdownMenuEntry<User>> _buildDropdownEntries() {
    if (_isLoading) {
      return [
        DropdownMenuEntry<User>(
          value: User(
            id: 0,
            username: '',
            balance: 0,
            name: 'Đang tải...',
            email: '',
          ),
          label: 'Đang tải...',
          enabled: false,
        )
      ];
    }

    if (_searchResults.isEmpty) {
      return [];
    }

    return _searchResults
        .map((user) => DropdownMenuEntry<User>(
              value: user,
              label: user.name,
              leadingIcon: const Icon(Icons.person),
              labelWidget: _buildUserLabel(user),
            ))
        .toList();
  }

  Widget _buildUserLabel(User user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          user.email,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
