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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audit Log', style: TextStyle(fontSize: 16)),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: AuditLogList(fetcher: fetcher),
    );
  }
}
