class OrderUpdateData {
  final int? userId;
  final int? total;
  final String? status;
  final String? type;
  final String? note;
  final String? utmSource;
  final int? discount;
  final int? refundAmount;

  const OrderUpdateData({
    this.userId,
    this.total,
    this.status,
    this.type,
    this.note,
    this.utmSource,
    this.discount,
    this.refundAmount,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (userId != null) data['user_id'] = userId;
    if (total != null) data['total'] = total;
    if (status != null) data['status'] = status;
    if (type != null) data['type'] = type;
    if (note != null) data['note'] = note;
    if (utmSource != null) data['utm_source'] = utmSource;
    if (discount != null) data['discount'] = discount;
    if (refundAmount != null) data['refund_amount'] = refundAmount;
    return data;
  }
}
