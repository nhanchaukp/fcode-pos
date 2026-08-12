import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/audit/audit_log_list.dart';
import 'package:flutter/material.dart';

/// Full-screen audit log viewer.
///
/// For embedding the list inside tabs or other widgets (without an AppBar),
/// prefer using [AuditLogList] directly.
class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({required this.title, required this.fetcher, super.key});

  final String title;
  final AuditFetcher fetcher;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Audit Log',
      subtitle: title,
      body: (context, scrollController) => AuditLogList(
        fetcher: fetcher,
      ),
    );
  }
}
