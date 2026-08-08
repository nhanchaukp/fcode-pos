import 'dart:convert';
import 'package:flutter/material.dart';

/// Ultra-compact Key-Value Form & JSON Editor Widget
class KeyValueEditor extends StatefulWidget {
  final Map<String, dynamic>? initialValue;
  final ValueChanged<Map<String, dynamic>?>? onChanged;
  final String keyHeader;
  final String valueHeader;

  const KeyValueEditor({
    super.key,
    this.initialValue,
    this.onChanged,
    this.keyHeader = 'Khóa (Key)',
    this.valueHeader = 'Giá trị (Value)',
  });

  @override
  State<KeyValueEditor> createState() => KeyValueEditorState();
}

class _KeyValueRow {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _KeyValueRow({String key = '', String value = ''})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class KeyValueEditorState extends State<KeyValueEditor> {
  final List<_KeyValueRow> _rows = [];
  late TextEditingController _rawJsonController;
  bool _isRawMode = false;
  String? _jsonError;

  @override
  void initState() {
    super.initState();
    _rawJsonController = TextEditingController();
    _populateFromMap(widget.initialValue);
  }

  void _populateFromMap(Map<String, dynamic>? map) {
    _clearRows();
    if (map != null && map.isNotEmpty) {
      for (final entry in map.entries) {
        final val = entry.value is Map || entry.value is List
            ? jsonEncode(entry.value)
            : entry.value?.toString() ?? '';
        _rows.add(_KeyValueRow(key: entry.key, value: val));
      }
      try {
        _rawJsonController.text =
            const JsonEncoder.withIndent('  ').convert(map);
      } catch (_) {
        _rawJsonController.text = jsonEncode(map);
      }
    } else {
      _rawJsonController.text = '';
    }
  }

  void _clearRows() {
    for (final row in _rows) {
      row.dispose();
    }
    _rows.clear();
  }

  @override
  void dispose() {
    _clearRows();
    _rawJsonController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_KeyValueRow());
    });
    _notifyChanged();
  }

  void _removeRow(int index) {
    setState(() {
      final removed = _rows.removeAt(index);
      removed.dispose();
    });
    _notifyChanged();
  }

  Map<String, dynamic>? getValueMap() {
    if (_isRawMode) {
      final text = _rawJsonController.text.trim();
      if (text.isEmpty) return null;
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
      return null;
    }

    final result = <String, dynamic>{};
    for (final row in _rows) {
      final k = row.keyController.text.trim();
      final v = row.valueController.text.trim();
      if (k.isNotEmpty) {
        if (v == 'true') {
          result[k] = true;
        } else if (v == 'false') {
          result[k] = false;
        } else if (int.tryParse(v) != null) {
          result[k] = int.parse(v);
        } else if (double.tryParse(v) != null) {
          result[k] = double.parse(v);
        } else {
          result[k] = v;
        }
      }
    }
    return result.isEmpty ? null : result;
  }

  void _notifyChanged() {
    widget.onChanged?.call(getValueMap());
  }

  void _toggleMode() {
    if (!_isRawMode) {
      final map = getValueMap();
      if (map != null && map.isNotEmpty) {
        _rawJsonController.text =
            const JsonEncoder.withIndent('  ').convert(map);
      } else {
        _rawJsonController.text = '';
      }
      setState(() {
        _isRawMode = true;
        _jsonError = null;
      });
    } else {
      final text = _rawJsonController.text.trim();
      if (text.isNotEmpty) {
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map<String, dynamic>) {
            setState(() {
              _populateFromMap(decoded);
              _isRawMode = false;
              _jsonError = null;
            });
            _notifyChanged();
            return;
          } else {
            setState(() => _jsonError = 'JSON phải là object (vd: {"key":"val"})');
            return;
          }
        } catch (e) {
          setState(() => _jsonError = 'Cú pháp JSON không hợp lệ: $e');
          return;
        }
      }
      setState(() {
        _clearRows();
        _isRawMode = false;
        _jsonError = null;
      });
      _notifyChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isRawMode ? 'Mã JSON' : 'Tham số (${_rows.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              InkWell(
                onTap: _toggleMode,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        _isRawMode ? Icons.table_rows_outlined : Icons.code,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isRawMode ? 'Dạng bảng' : 'JSON',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (_isRawMode)
            TextFormField(
              controller: _rawJsonController,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: '{\n  "key": "value"\n}',
                isDense: true,
                contentPadding: const EdgeInsets.all(8),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: colorScheme.surface,
                errorText: _jsonError,
              ),
              onChanged: (_) => _notifyChanged(),
            )
          else ...[
            if (_rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Chưa có tham số. Bấm "+ Thêm" để tạo dòng mới.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int index = 0; index < _rows.length; index++) ...[
                    if (index > 0) const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: _rows[index].keyController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: widget.keyHeader,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                            onChanged: (_) => _notifyChanged(),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: _rows[index].valueController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: widget.valueHeader,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                            onChanged: (_) => _notifyChanged(),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.close, size: 14),
                          color: colorScheme.error,
                          tooltip: 'Xóa dòng này',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 22,
                            height: 22,
                          ),
                          onPressed: () => _removeRow(index),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 2),
            InkWell(
              onTap: _addRow,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 13, color: colorScheme.primary),
                    const SizedBox(width: 3),
                    Text(
                      'Thêm tham số',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
