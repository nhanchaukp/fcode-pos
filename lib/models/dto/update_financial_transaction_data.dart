import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/utils/date_helper.dart';

class UpdateFinancialTransactionData {
  const UpdateFinancialTransactionData({
    this.type,
    this.category,
    this.status,
    this.amount,
    this.fee,
    this.description,
    this.notes,
    this.processedAt,
    this.completedAt,
  });

  final enums.FinancialTransactionType? type;
  final enums.FinancialTransactionCategory? category;
  final enums.FinancialTransactionStatus? status;
  final double? amount;
  final double? fee;
  final String? description;
  final String? notes;
  final DateTime? processedAt;
  final DateTime? completedAt;

  Map<String, dynamic> toDirtyPayload(FinancialTransaction original) {
    final payload = <String, dynamic>{};

    if (type != null && type!.value != original.type) {
      payload['type'] = type!.value;
    }
    if (category != null && category!.value != original.category) {
      payload['category'] = category!.value;
    }
    if (status != null && status!.value != original.status) {
      payload['status'] = status!.value;
    }
    if (amount != null && amount != original.amount) {
      payload['amount'] = amount;
    }
    if (fee != null && fee != original.fee) {
      payload['fee'] = fee;
    }

    final normalizedDescription = _nullableText(description);
    if (normalizedDescription != original.description) {
      payload['description'] = normalizedDescription;
    }

    final normalizedNotes = _nullableText(notes);
    if (normalizedNotes != original.notes) {
      payload['notes'] = normalizedNotes;
    }

    if (!_sameInstant(processedAt, original.processedAt)) {
      payload['processed_at'] = _formatDateTime(processedAt);
    }
    if (!_sameInstant(completedAt, original.completedAt)) {
      payload['completed_at'] = _formatDateTime(completedAt);
    }

    return payload;
  }

  String? _nullableText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _formatDateTime(DateTime? value) {
    if (value == null) return null;
    return DateHelper.formatApiDateTime(value);
  }

  bool _sameInstant(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.toUtc() == b.toUtc();
  }
}