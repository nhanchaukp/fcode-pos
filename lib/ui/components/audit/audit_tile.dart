import 'dart:convert';

import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/ui/components/badge/audit_event_badge.dart';
import 'package:flutter/material.dart';

/// Timeline-style audit log tile with support for created/updated/deleted events.
class AuditTile extends StatefulWidget {
  const AuditTile({required this.audit, required this.isLast, super.key});

  final Auditable audit;
  final bool isLast;

  @override
  State<AuditTile> createState() => _AuditTileState();
}

class _AuditTileState extends State<AuditTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audit = widget.audit;
    final (eventColor, eventIcon, _) = eventMeta(audit.event, cs);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 56,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: eventColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(eventIcon, size: 16, color: eventColor),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),

          // Card content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: 16,
                top: 8,
                bottom: widget.isLast ? 8 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      AuditEventBadge(event: audit.event),
                      const Spacer(),
                      AuditTimeText(audit.createdAt),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // User row
                  if (audit.user != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: AuditUserChip(user: audit.user!),
                    ),

                  // Diff section (updated event)
                  if (audit.event == 'updated' &&
                      (audit.oldValues?.isNotEmpty == true ||
                          audit.newValues?.isNotEmpty == true))
                    AuditDiffCard(
                      oldValues: audit.oldValues ?? {},
                      newValues: audit.newValues ?? {},
                      expanded: _expanded,
                      onToggle: () => setState(() => _expanded = !_expanded),
                    )
                  else if (audit.event == 'created' &&
                      audit.newValues?.isNotEmpty == true)
                    AuditValuesCard(
                      values: audit.newValues!,
                      expanded: _expanded,
                      onToggle: () => setState(() => _expanded = !_expanded),
                      label: 'Giá trị khởi tạo',
                      color: Colors.green,
                    )
                  else if (audit.event == 'deleted' &&
                      audit.oldValues?.isNotEmpty == true)
                    AuditValuesCard(
                      values: audit.oldValues!,
                      expanded: _expanded,
                      onToggle: () => setState(() => _expanded = !_expanded),
                      label: 'Giá trị trước xóa',
                      color: Colors.red,
                    ),

                  // Extra meta (ip, url)
                  if (audit.ipAddress != null || audit.url != null) ...[
                    const SizedBox(height: 6),
                    AuditMetaRow(audit: audit),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Public sub-widgets (reusable if needed outside the list)
// ---------------------------------------------------------------------------

class AuditTimeText extends StatelessWidget {
  const AuditTimeText(this.rawDate, {super.key});

  final String? rawDate;

  @override
  Widget build(BuildContext context) {
    if (rawDate == null) return const SizedBox.shrink();
    DateTime dt;
    try {
      dt = DateTime.parse(rawDate!).toLocal();
    } catch (_) {
      return Text(
        rawDate!,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final relative = _relativeTime(dt);
    final absolute =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Tooltip(
      message: absolute,
      child: Text(
        relative,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }
}

class AuditUserChip extends StatelessWidget {
  const AuditUserChip({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: cs.primaryContainer,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          user.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class AuditMetaRow extends StatelessWidget {
  const AuditMetaRow({required this.audit});

  final Auditable audit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      children: [
        if (audit.ipAddress != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, size: 11, color: cs.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(
                audit.ipAddress!,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        if (audit.url != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link, size: 11, color: cs.onSurfaceVariant),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  audit.url!,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Diff card (updated events)
// ---------------------------------------------------------------------------

class AuditDiffCard extends StatelessWidget {
  const AuditDiffCard({
    required this.oldValues,
    required this.newValues,
    required this.expanded,
    required this.onToggle,
    super.key,
  });

  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final allKeys = {...oldValues.keys, ...newValues.keys}.toList();
    final changed = allKeys
        .where((k) => _str(oldValues[k]) != _str(newValues[k]))
        .toList();

    final preview = changed.take(2).toList();
    final shown = expanded ? changed : preview;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...shown.map(
              (key) => _DiffRow(
                fieldKey: key,
                oldVal: _str(oldValues[key]),
                newVal: _str(newValues[key]),
              ),
            ),
            if (changed.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  expanded
                      ? 'Thu gọn'
                      : '+ ${changed.length - 2} thay đổi nữa...',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _str(dynamic val) {
    if (val == null) return '—';
    if (val is Map || val is List) return jsonEncode(val);
    return val.toString();
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.fieldKey,
    required this.oldVal,
    required this.newVal,
    super.key,
  });

  final String fieldKey;
  final String oldVal;
  final String newVal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = fieldKey.replaceAll('_', ' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    oldVal,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, size: 12, color: cs.onSurfaceVariant),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    newVal,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic values card (created / deleted)
// ---------------------------------------------------------------------------

class AuditValuesCard extends StatelessWidget {
  const AuditValuesCard({
    required this.values,
    required this.expanded,
    required this.onToggle,
    required this.label,
    required this.color,
    super.key,
  });

  final Map<String, dynamic> values;
  final bool expanded;
  final VoidCallback onToggle;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = values.entries.toList();
    final preview = entries.take(3).toList();
    final shown = expanded ? entries : preview;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...shown.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        e.key.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _str(e.value),
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (entries.length > 3)
              Text(
                expanded ? 'Thu gọn' : '+ ${entries.length - 3} trường nữa...',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _str(dynamic val) {
    if (val == null) return '—';
    if (val is Map || val is List) return jsonEncode(val);
    return val.toString();
  }
}
