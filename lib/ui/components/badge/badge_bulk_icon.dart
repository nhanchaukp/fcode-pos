import 'package:amazing_icons/bulk.dart';
import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models/icallme_voucher.dart';
import 'package:flutter/material.dart';

typedef BulkIconBuilder =
    Widget Function({double size, Color color, double opacity});

/// Resolves a bulk icon builder for [LabeledIconEnum] values used in badges.
BulkIconBuilder? bulkIconFor(LabeledIconEnum? value) {
  if (value == null) return null;

  return switch (value) {
    OrderStatus.all => AmazingIconBulk.category,
    OrderStatus.new_ => AmazingIconBulk.addCircle,
    OrderStatus.paymentSuccess => AmazingIconBulk.tickCircle,
    OrderStatus.processing => AmazingIconBulk.refresh,
    OrderStatus.complete => AmazingIconBulk.verify,
    OrderStatus.cancel => AmazingIconBulk.closeCircle,
    OrderStatus.underWarranty => AmazingIconBulk.shieldTick,
    OrderStatus.refund => AmazingIconBulk.undo,

    RefundStatus.pending => AmazingIconBulk.timer1,
    RefundStatus.approved => AmazingIconBulk.tickCircle,
    RefundStatus.rejected => AmazingIconBulk.closeCircle,
    RefundStatus.completed => AmazingIconBulk.verify,

    RefundType.pending => AmazingIconBulk.timer1,
    RefundType.partial => AmazingIconBulk.chart,
    RefundType.full => AmazingIconBulk.tickCircle,
    RefundType.item => AmazingIconBulk.shoppingBag,
    RefundType.none => AmazingIconBulk.forbidden,

    RefundReason.customerRequest => AmazingIconBulk.profile,
    RefundReason.productDefect => AmazingIconBulk.danger,
    RefundReason.deliveryIssue => AmazingIconBulk.truck,
    RefundReason.accountExpired => AmazingIconBulk.clock,
    RefundReason.serviceIssue => AmazingIconBulk.setting,
    RefundReason.other => AmazingIconBulk.more,

    InvoiceStatus.draft => AmazingIconBulk.note,
    InvoiceStatus.issued => AmazingIconBulk.tickCircle,
    InvoiceStatus.cancelled => AmazingIconBulk.closeCircle,

    MailLogStatus.sent => AmazingIconBulk.tickCircle,
    MailLogStatus.pending => AmazingIconBulk.timer1,
    MailLogStatus.failed => AmazingIconBulk.danger,

    IcallmeVoucherStatus.available => AmazingIconBulk.tickCircle,
    IcallmeVoucherStatus.used => AmazingIconBulk.verify,
    IcallmeVoucherStatus.revoked => AmazingIconBulk.closeCircle,
    IcallmeVoucherStatus.expired => AmazingIconBulk.timer1,
    IcallmeVoucherStatus.unknown => AmazingIconBulk.infoCircle,

    _ => null,
  };
}
