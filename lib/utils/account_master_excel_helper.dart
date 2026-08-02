import 'dart:io';
import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum AccountMasterExcelColumn {
  id('ID', 'ID tài khoản'),
  username('Username', 'Tên đăng nhập / Username'),
  serviceType('Loại dịch vụ', 'Loại dịch vụ'),
  supply('Nhà cung cấp', 'Nhà cung cấp'),
  maxSlots('Max Slot', 'Số slot tối đa'),
  usedSlots('Slot đã dùng', 'Số slot đã dùng'),
  status('Trạng thái', 'Trạng thái hoạt động'),
  paymentDate('Ngày trả phí', 'Ngày trả phí'),
  monthlyCost('Chi phí hàng tháng (VNĐ)', 'Chi phí hàng tháng'),
  hasExpenseThisMonth('CP tháng này', 'Đã có chi phí tháng này'),
  notes('Ghi chú', 'Ghi chú tài khoản'),
  costNotes('Ghi chú chi phí', 'Ghi chú chi phí'),
  createdAt('Ngày tạo', 'Ngày tạo'),
  updatedAt('Ngày cập nhật', 'Ngày cập nhật');

  final String header;
  final String label;

  const AccountMasterExcelColumn(this.header, this.label);
}

class AccountMasterExcelHelper {
  static Future<String?> exportToExcel(
    List<AccountMaster> accounts, {
    Set<AccountMasterExcelColumn>? selectedColumns,
  }) async {
    final columnsToExport =
        (selectedColumns == null || selectedColumns.isEmpty)
            ? AccountMasterExcelColumn.values.toSet()
            : selectedColumns;

    final buffer = StringBuffer();

    // UTF-8 BOM byte order mark so Excel opens with proper Vietnamese diacritics automatically
    buffer.write('\uFEFF');

    final headers = AccountMasterExcelColumn.values
        .where(columnsToExport.contains)
        .map((col) => col.header)
        .toList();

    buffer.writeln(headers.map(_escapeCsvCell).join(','));

    for (final account in accounts) {
      final serviceEnum =
          enums.AccountMasterServiceType.fromValue(account.serviceType);
      final serviceLabel = serviceEnum?.label ?? account.serviceType;
      final usedSlots = account.slotsCount ?? account.slots?.length ?? 0;

      final row = <String>[];
      for (final col in AccountMasterExcelColumn.values) {
        if (!columnsToExport.contains(col)) continue;
        switch (col) {
          case AccountMasterExcelColumn.id:
            row.add(account.id.toString());
            break;
          case AccountMasterExcelColumn.username:
            row.add(account.username);
            break;
          case AccountMasterExcelColumn.serviceType:
            row.add(serviceLabel);
            break;
          case AccountMasterExcelColumn.supply:
            row.add(account.supply?.name ?? '');
            break;
          case AccountMasterExcelColumn.maxSlots:
            row.add(account.maxSlots.toString());
            break;
          case AccountMasterExcelColumn.usedSlots:
            row.add(usedSlots.toString());
            break;
          case AccountMasterExcelColumn.status:
            row.add(account.isActive ? 'Hoạt động' : 'Ngưng hoạt động');
            break;
          case AccountMasterExcelColumn.paymentDate:
            row.add(DateHelper.formatDate(account.paymentDate));
            break;
          case AccountMasterExcelColumn.monthlyCost:
            row.add(
              account.monthlyCost != null
                  ? CurrencyHelper.formatCurrency(account.monthlyCost!)
                  : '',
            );
            break;
          case AccountMasterExcelColumn.hasExpenseThisMonth:
            row.add(
              account.hasExpenseThisMonth == true
                  ? 'Đã phát sinh'
                  : (account.hasExpenseThisMonth == false
                      ? 'Chưa phát sinh'
                      : '-'),
            );
            break;
          case AccountMasterExcelColumn.notes:
            row.add(account.notes ?? '');
            break;
          case AccountMasterExcelColumn.costNotes:
            row.add(account.costNotes ?? '');
            break;
          case AccountMasterExcelColumn.createdAt:
            row.add(DateHelper.formatDateTime(account.createdAt));
            break;
          case AccountMasterExcelColumn.updatedAt:
            row.add(DateHelper.formatDateTime(account.updatedAt));
            break;
        }
      }

      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final nowStr = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/account_master_stats_$nowStr.csv';
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Thống kê Kho Tài Khoản Master',
    );

    return filePath;
  }

  static String _escapeCsvCell(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}
