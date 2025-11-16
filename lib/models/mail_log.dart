part of '../models.dart';

/// Mail Log
class MailLog implements Model {
  /// Mail log ID.
  final int id;

  /// Mail status (e.g., "sent", "pending", "failed").
  final String status;

  /// Recipient email addresses (Map format: email => name).
  final Map<String, String> to;

  /// Mail subject.
  final String subject;

  /// Mail body content.
  final String? body;

  /// Mail CC recipients.
  final Map<String, String>? cc;

  /// Mail BCC recipients.
  final Map<String, String>? bcc;

  /// Mail from address.
  final String? from;

  /// Error message if failed.
  final String? error;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  /// Sent date.
  final DateTime? sentAt;

  final String? html;

  MailLog({
    required this.id,
    required this.status,
    required this.to,
    required this.subject,
    this.body,
    this.cc,
    this.bcc,
    this.from,
    this.error,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.sentAt,
    this.html,
  });

  factory MailLog.fromJson(Map<String, dynamic> map) {
    return MailLog(
      id: asInt(map['id']),
      status: map['status']?.toString() ?? '',
      to: _parseEmailMap(map['to']),
      subject: map['subject']?.toString() ?? '',
      body: map['body']?.toString(),
      cc: map['cc'] != null ? _parseEmailMap(map['cc']) : null,
      bcc: map['bcc'] != null ? _parseEmailMap(map['bcc']) : null,
      from: map['from']?.toString(),
      error: map['error']?.toString(),
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      sentAt: map['sent_at'] != null
          ? DateTime.parse(map['sent_at'].toString())
          : null,
      html: map['html']?.toString(),
    );
  }

  /// Parse email map from JSON (handles both Map and other formats)
  static Map<String, String> _parseEmailMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    }
    return {};
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'to': to,
      'subject': subject,
      'body': body,
      'cc': cc,
      'bcc': bcc,
      'from': from,
      'error': error,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'html': html,
    };
  }

  /// Get the first recipient email
  String get firstRecipient {
    if (to.isEmpty) return '';
    return to.keys.first;
  }

  /// Get all recipient emails as a comma-separated string
  String get recipientsString {
    return to.keys.join(', ');
  }

  /// Check if mail was sent successfully
  bool get isSent => status.toLowerCase() == 'sent';

  /// Check if mail is pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if mail failed
  bool get isFailed => status.toLowerCase() == 'failed';
}
