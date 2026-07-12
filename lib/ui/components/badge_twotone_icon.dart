import 'package:amazing_icons/twotone.dart';
import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models/icallme_voucher.dart';
import 'package:flutter/material.dart';

typedef TwotoneIconBuilder =
    Widget Function({double size, Color color, double opacity});

/// Resolves a twotone icon builder for [LabeledIconEnum] values used in badges.
TwotoneIconBuilder? twotoneIconFor(LabeledIconEnum? value) {
  if (value == null) return null;

  return switch (value) {
    OrderStatus.all => AmazingIconTwotone.category,
    OrderStatus.new_ => AmazingIconTwotone.addCircle,
    OrderStatus.paymentSuccess => AmazingIconTwotone.tickCircle,
    OrderStatus.processing => AmazingIconTwotone.refresh,
    OrderStatus.complete => AmazingIconTwotone.verify,
    OrderStatus.cancel => AmazingIconTwotone.closeCircle,
    OrderStatus.underWarranty => AmazingIconTwotone.shieldTick,
    OrderStatus.refund => AmazingIconTwotone.undo,

    RefundStatus.pending => AmazingIconTwotone.timer1,
    RefundStatus.approved => AmazingIconTwotone.tickCircle,
    RefundStatus.rejected => AmazingIconTwotone.closeCircle,
    RefundStatus.completed => AmazingIconTwotone.verify,

    RefundType.pending => AmazingIconTwotone.timer1,
    RefundType.partial => AmazingIconTwotone.chart,
    RefundType.full => AmazingIconTwotone.tickCircle,
    RefundType.item => AmazingIconTwotone.shoppingBag,
    RefundType.none => AmazingIconTwotone.forbidden,

    RefundReason.customerRequest => AmazingIconTwotone.profile,
    RefundReason.productDefect => AmazingIconTwotone.danger,
    RefundReason.deliveryIssue => AmazingIconTwotone.truck,
    RefundReason.accountExpired => AmazingIconTwotone.clock,
    RefundReason.serviceIssue => AmazingIconTwotone.setting,
    RefundReason.other => AmazingIconTwotone.more,

    InvoiceStatus.draft => AmazingIconTwotone.note,
    InvoiceStatus.issued => AmazingIconTwotone.tickCircle,
    InvoiceStatus.cancelled => AmazingIconTwotone.closeCircle,

    MailLogStatus.sent => AmazingIconTwotone.tickCircle,
    MailLogStatus.pending => AmazingIconTwotone.timer1,
    MailLogStatus.failed => AmazingIconTwotone.danger,

    IcallmeVoucherStatus.available => AmazingIconTwotone.tickCircle,
    IcallmeVoucherStatus.used => AmazingIconTwotone.verify,
    IcallmeVoucherStatus.revoked => AmazingIconTwotone.closeCircle,
    IcallmeVoucherStatus.expired => AmazingIconTwotone.timer1,
    IcallmeVoucherStatus.unknown => AmazingIconTwotone.infoCircle,

    _ => null,
  };
}
