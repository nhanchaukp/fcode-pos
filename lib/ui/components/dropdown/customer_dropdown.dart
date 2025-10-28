import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/customer/customer_create_screen.dart';
import 'package:fcode_pos/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/ui/components/debounced_search_input.dart';

class CustomerSearchDropdown extends StatefulWidget {
  final User? selectedUser;
  final Function(User?)? onChanged;
  final bool isRequired;
  final bool enabled;
  final String? Function(User?)? validator;
  final String? labelText;

  const CustomerSearchDropdown({
    this.selectedUser,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.labelText,
    super.key,
  });

  @override
  State<CustomerSearchDropdown> createState() => _CustomerSearchDropdownState();
}

class _CustomerSearchDropdownState extends State<CustomerSearchDropdown> {
  final _textController = TextEditingController();
  User? _selectedUser;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.selectedUser;
    if (_selectedUser != null) {
      _textController.text = _selectedUser!.name;
    }
  }

  @override
  void didUpdateWidget(CustomerSearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedUser != oldWidget.selectedUser) {
      setState(() {
        _selectedUser = widget.selectedUser;
        _textController.text = widget.selectedUser?.name ?? '';
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelText =
        widget.labelText ?? 'Khách hàng${widget.isRequired ? ' *' : ''}';

    return TextFormField(
      controller: _textController,
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.person_search_sharp),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        errorText: _errorText,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedUser != null && widget.enabled)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _textController.clear();
                  setState(() {
                    _selectedUser = null;
                    _errorText = null;
                  });
                  widget.onChanged?.call(null);
                },
              ),
            if (widget.enabled)
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'Thêm khách hàng',
                onPressed: () async {
                  final newCustomer = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CustomerCreateScreen(),
                    ),
                  );
                  if (newCustomer is User) {
                    setState(() {
                      _selectedUser = newCustomer;
                      _textController.text = newCustomer.name;
                      _errorText = null;
                    });
                    widget.onChanged?.call(newCustomer);
                  }
                },
              ),
          ],
        ),
      ),
      onTap: widget.enabled
          ? () async {
              final selected = await showModalBottomSheet<User>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return _CustomerSelectSheet(selected: _selectedUser);
                },
              );
              if (selected != null) {
                setState(() {
                  _selectedUser = selected;
                  _textController.text = selected.name;
                  _errorText = null;
                });
                widget.onChanged?.call(selected);
              }
            }
          : null,
      validator: (value) {
        if (widget.validator != null) {
          return widget.validator!(_selectedUser);
        } else if (widget.isRequired && _selectedUser == null) {
          return 'Vui lòng chọn khách hàng';
        }
        return null;
      },
    );
  }
}

class _CustomerSelectSheet extends StatefulWidget {
  final User? selected;
  const _CustomerSelectSheet({this.selected});

  @override
  State<_CustomerSelectSheet> createState() => _CustomerSelectSheetState();
}

class _CustomerSelectSheetState extends State<_CustomerSelectSheet> {
  late TextEditingController _searchController;
  List<User> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final result = await CustomerService().list(
        search: query,
        page: 1,
        perPage: 20,
      );
      if (!mounted) return;
      setState(() {
        _results = result.data?.items ?? [];
      });
    } catch (e) {
      debugPrint('Error searching customers: $e');
      if (!mounted) return;
      setState(() {
        _results = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              DebouncedSearchInput(
                controller: _searchController,
                autofocus: true,
                hintText: 'Tìm kiếm khách hàng...',
                onChanged: (query) {
                  if (!mounted) return;
                  if (query.trim().isEmpty) {
                    setState(() {
                      _results = [];
                      _hasSearched = false;
                    });
                    return;
                  }
                  _searchCustomers(query.trim());
                },
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty && _hasSearched
                    ? const Center(child: Text('Không có khách hàng phù hợp'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          return ListTile(
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: widget.selected?.id == user.id
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(user);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
