class AdsenseAccount {
  AdsenseAccount({
    required this.name,
    required this.displayName,
  });

  final String name;
  final String displayName;

  String get accountId => name.split('/').last;

  factory AdsenseAccount.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final displayName =
        json['displayName'] as String? ?? json['name'] as String? ?? name;
    return AdsenseAccount(name: name, displayName: displayName);
  }
}

class AdsenseReportHeader {
  AdsenseReportHeader({required this.name, required this.type});

  final String name;
  final String type;

  factory AdsenseReportHeader.fromJson(Map<String, dynamic> json) {
    return AdsenseReportHeader(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

class AdsenseReportRow {
  AdsenseReportRow({required this.values});

  final List<String> values;

  factory AdsenseReportRow.fromJson(Map<String, dynamic> json) {
    final rawCells = json['cells'] as List? ?? const [];
    final values = rawCells.map((cell) {
      if (cell is Map<String, dynamic>) {
        final value = cell['value'];
        return value?.toString() ?? '';
      }
      return cell?.toString() ?? '';
    }).toList(growable: false);
    return AdsenseReportRow(values: values);
  }
}

class AdsenseReport {
  AdsenseReport({
    required this.headers,
    required this.rows,
    required this.totals,
    required this.averages,
    this.currencyCode,
  });

  final List<AdsenseReportHeader> headers;
  final List<AdsenseReportRow> rows;
  final List<AdsenseReportRow> totals;
  final List<AdsenseReportRow> averages;
  final String? currencyCode;

  Map<String, String> totalsByHeader() {
    if (totals.isEmpty) return {};
    final totalRow = totals.first;
    final totalsByHeader = <String, String>{};
    for (var i = 0; i < headers.length && i < totalRow.values.length; i++) {
      totalsByHeader[headers[i].name] = totalRow.values[i];
    }
    return totalsByHeader;
  }

  factory AdsenseReport.fromJson(Map<String, dynamic> json) {
    final headers =
        (json['headers'] as List? ?? const [])
            .map(
              (item) => AdsenseReportHeader.fromJson(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false);
    return AdsenseReport(
      headers: headers,
      rows: _parseRows(json['rows']),
      totals: _parseRows(json['totals']),
      averages: _parseRows(json['averages']),
      currencyCode: json['currencyCode'] as String?,
    );
  }

  static List<AdsenseReportRow> _parseRows(dynamic raw) {
    if (raw is List) {
      return raw
          .map(
            (item) => AdsenseReportRow.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    }
    if (raw is Map<String, dynamic>) {
      return [AdsenseReportRow.fromJson(raw)];
    }
    if (raw is Map) {
      return [AdsenseReportRow.fromJson(Map<String, dynamic>.from(raw))];
    }
    return const [];
  }
}
