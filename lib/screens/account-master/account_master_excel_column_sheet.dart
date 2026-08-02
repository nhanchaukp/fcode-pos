import 'package:fcode_pos/utils/account_master_excel_helper.dart';
import 'package:flutter/material.dart';

class AccountMasterExcelColumnSheet extends StatefulWidget {
  const AccountMasterExcelColumnSheet({
    super.key,
    this.initialSelectedColumns,
  });

  final Set<AccountMasterExcelColumn>? initialSelectedColumns;

  static Future<Set<AccountMasterExcelColumn>?> show(
    BuildContext context, {
    Set<AccountMasterExcelColumn>? initialSelectedColumns,
  }) {
    return showModalBottomSheet<Set<AccountMasterExcelColumn>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AccountMasterExcelColumnSheet(
        initialSelectedColumns: initialSelectedColumns,
      ),
    );
  }

  @override
  State<AccountMasterExcelColumnSheet> createState() =>
      _AccountMasterExcelColumnSheetState();
}

class _AccountMasterExcelColumnSheetState
    extends State<AccountMasterExcelColumnSheet> {
  late Set<AccountMasterExcelColumn> _selectedColumns;

  @override
  void initState() {
    super.initState();
    _selectedColumns = widget.initialSelectedColumns != null
        ? Set<AccountMasterExcelColumn>.from(widget.initialSelectedColumns!)
        : AccountMasterExcelColumn.values.toSet();
  }

  void _selectAll(bool select) {
    setState(() {
      if (select) {
        _selectedColumns = AccountMasterExcelColumn.values.toSet();
      } else {
        _selectedColumns.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAllSelected =
        _selectedColumns.length == AccountMasterExcelColumn.values.length;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chọn cột xuất Excel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectAll(!isAllSelected),
                    child: Text(isAllSelected ? 'Bỏ chọn hết' : 'Chọn tất cả'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Column options
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: AccountMasterExcelColumn.values.length,
                itemBuilder: (context, index) {
                  final col = AccountMasterExcelColumn.values[index];
                  final isChecked = _selectedColumns.contains(col);

                  return CheckboxListTile(
                    value: isChecked,
                    title: Text(
                      col.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Tên cột: ${col.header}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    dense: true,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedColumns.add(col);
                        } else {
                          _selectedColumns.remove(col);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Bottom action
            Padding(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _selectedColumns.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context, _selectedColumns);
                          },
                    icon: const Icon(Icons.file_download),
                    label: Text(
                      'Xuất Excel (${_selectedColumns.length} cột)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
