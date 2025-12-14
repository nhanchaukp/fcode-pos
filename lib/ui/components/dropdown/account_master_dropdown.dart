import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/ui/components/debounced_search_input.dart';
import 'package:flutter/material.dart';

class AccountMasterDropdown extends StatefulWidget {
  final AccountMaster? selectedAccountMaster;
  final Function(AccountMaster?)? onChanged;
  final bool isRequired;
  final bool enabled;
  final String? Function(AccountMaster?)? validator;
  final String? labelText;

  const AccountMasterDropdown({
    this.selectedAccountMaster,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.labelText,
    super.key,
  });

  @override
  State<AccountMasterDropdown> createState() => _AccountMasterDropdownState();
}

class _AccountMasterDropdownState extends State<AccountMasterDropdown> {
  final _accountMasterService = AccountMasterService();
  List<AccountMaster> _accountMasters = [];
  bool _isLoading = false;
  AccountMaster? _selectedAccountMaster;

  @override
  void initState() {
    super.initState();
    _selectedAccountMaster = widget.selectedAccountMaster;
    _loadAccountMasters();
  }

  @override
  void didUpdateWidget(AccountMasterDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAccountMaster != oldWidget.selectedAccountMaster) {
      setState(() {
        _selectedAccountMaster = widget.selectedAccountMaster;
      });
    }
  }

  Future<void> _loadAccountMasters() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _accountMasterService.list(isActive: true);
      final items = response.data ?? [];
      if (!mounted) return;
      setState(() {
        _accountMasters = items;
        if (_selectedAccountMaster != null) {
          _selectedAccountMaster = _accountMasters.firstWhere(
            (am) => am.id == _selectedAccountMaster!.id,
            orElse: () => _selectedAccountMaster!,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading account masters: $e');
      if (!mounted) return;
      setState(() {
        _accountMasters = [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _buildAccountMasterDisplayName(AccountMaster accountMaster) {
    return '${accountMaster.serviceType}: ${accountMaster.username}';
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.labelText ?? 'Account Master';

    if (_isLoading) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: '$label${widget.isRequired ? ' *' : ''}',
          prefixIcon: const Icon(Icons.account_circle_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const SizedBox(
            width: 16,
            height: 16,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
        enabled: false,
      );
    }

    return TextFormField(
      controller: TextEditingController(
        text: _selectedAccountMaster != null
            ? _buildAccountMasterDisplayName(_selectedAccountMaster!)
            : '',
      ),
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: '$label${widget.isRequired ? ' *' : ''}',
        prefixIcon: const Icon(Icons.account_circle_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: _selectedAccountMaster != null && widget.enabled
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedAccountMaster = null;
                  });
                  widget.onChanged?.call(null);
                },
              )
            : null,
      ),
      onTap: widget.enabled
          ? () async {
              final selected = await showModalBottomSheet<AccountMaster>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return _AccountMasterSelectSheet(
                    accountMasters: _accountMasters,
                    selected: _selectedAccountMaster,
                  );
                },
              );
              if (selected != null) {
                setState(() {
                  _selectedAccountMaster = selected;
                });
                widget.onChanged?.call(selected);
              }
            }
          : null,
      validator: (value) {
        if (widget.validator != null) {
          return widget.validator!(_selectedAccountMaster);
        } else if (widget.isRequired && _selectedAccountMaster == null) {
          return 'Vui lòng chọn account master';
        }
        return null;
      },
    );
  }
}

class _AccountMasterSelectSheet extends StatefulWidget {
  final List<AccountMaster> accountMasters;
  final AccountMaster? selected;
  const _AccountMasterSelectSheet({
    required this.accountMasters,
    this.selected,
  });

  @override
  State<_AccountMasterSelectSheet> createState() =>
      _AccountMasterSelectSheetState();
}

class _AccountMasterSelectSheetState extends State<_AccountMasterSelectSheet> {
  late List<AccountMaster> _filtered;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = widget.accountMasters;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _buildAccountMasterDisplayName(AccountMaster accountMaster) {
    return '${accountMaster.serviceType}: ${accountMaster.username}';
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
              DebouncedSearchInput(
                controller: _searchController,
                autofocus: true,
                hintText: 'Tìm kiếm account master...',
                onChanged: (query) {
                  if (!mounted) return;
                  final q = query.toLowerCase();
                  setState(() {
                    _filtered = widget.accountMasters.where((am) {
                      final username = am.username.toLowerCase();
                      final serviceType = am.serviceType.toLowerCase();
                      final name = am.name.toLowerCase();
                      return username.contains(q) ||
                          serviceType.contains(q) ||
                          name.contains(q);
                    }).toList();
                  });
                },
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text('Không có account master phù hợp'),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final accountMaster = _filtered[index];
                          return ListTile(
                            title: Text(
                              _buildAccountMasterDisplayName(accountMaster),
                            ),
                            subtitle: Text(
                              accountMaster.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            trailing: widget.selected?.id == accountMaster.id
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(accountMaster);
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
