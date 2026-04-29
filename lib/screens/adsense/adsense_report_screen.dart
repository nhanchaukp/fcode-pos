import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/models/adsense_models.dart';
import 'package:fcode_pos/services/adsense_service.dart';
import 'package:fcode_pos/storage/adsense_credential_storage.dart';
import 'package:fcode_pos/ui/components/section_header.dart';
import 'package:fcode_pos/ui/dashboard/dashboard_components.dart';
import 'package:fcode_pos/ui/theme/tokens.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class AdsenseReportScreen extends StatefulWidget {
  const AdsenseReportScreen({super.key});

  @override
  State<AdsenseReportScreen> createState() => _AdsenseReportScreenState();
}

class _AdsenseReportScreenState extends State<AdsenseReportScreen> {
  static const int _minReportYear = 2020;
  static const int _reportRowLimit = 50;

  late final AdsenseService _adsenseService;
  final TextEditingController _filterController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  GoogleSignInAccount? _googleAccount;
  AdsenseCredential? _cachedCredential;
  List<AdsenseAccount> _adsenseAccounts = const [];
  AdsenseAccount? _selectedAccount;
  AdsenseReport? _report;

  bool _isAuthLoading = false;
  bool _isAccountsLoading = false;
  bool _isReportLoading = false;
  String? _authError;
  String? _reportError;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  String _selectedDimension = _dimensionOptions.first.value;
  final Set<String> _selectedMetrics = {
    'ESTIMATED_EARNINGS',
    'PAGE_VIEWS',
    'CLICKS',
    'IMPRESSIONS',
  };

  @override
  void initState() {
    super.initState();
    _adsenseService = AdsenseService();
    _loadCachedCredential();
    _restoreSession();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  bool get _isSignedIn => _googleAccount != null;

  Future<void> _loadCachedCredential() async {
    final credential = await AdsenseCredentialStorage.readCredential();
    if (!mounted) return;
    setState(() {
      _cachedCredential = credential;
    });
  }

  Future<void> _restoreSession() async {
    setState(() {
      _isAuthLoading = true;
      _authError = null;
    });

    try {
      final account = await _adsenseService.signInSilently();
      if (account != null) {
        await _applyAccount(account);
      }
    } catch (e) {
      _authError = _readableError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isAuthLoading = false;
        });
      }
    }
  }

  Future<void> _applyAccount(GoogleSignInAccount account) async {
    if (!mounted) return;
    setState(() {
      _googleAccount = account;
      _authError = null;
    });
    await _loadAccounts();
    if (_selectedAccount != null) {
      await _loadReport();
    }
    await _saveCredential(account, accountName: _selectedAccount?.name);
  }

  Future<void> _saveCredential(
    GoogleSignInAccount account, {
    String? accountName,
  }) async {
    try {
      final auth = await account.authentication;
      final credential = AdsenseCredential(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: auth.accessToken,
        idToken: auth.idToken,
        accountName: accountName,
      );
      await AdsenseCredentialStorage.saveCredential(credential);
      if (mounted) {
        setState(() {
          _cachedCredential = credential;
        });
      }
    } catch (e) {
      debugPrint(
        'Non-fatal: failed to cache AdSense credentials; user must sign in again on next launch. $e',
      );
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isAuthLoading = true;
      _authError = null;
    });
    try {
      final account = await _adsenseService.signIn();
      if (account == null) {
        return;
      }
      await _applyAccount(account);
    } catch (e) {
      _authError = _readableError(e);
      Toastr.error(_authError ?? 'Không thể đăng nhập Google.');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isAuthLoading = true;
    });
    try {
      await _adsenseService.signOut();
      await AdsenseCredentialStorage.clear();
      if (!mounted) return;
      setState(() {
        _googleAccount = null;
        _adsenseAccounts = const [];
        _selectedAccount = null;
        _report = null;
        _reportError = null;
      });
    } catch (e) {
      Toastr.error(_readableError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isAuthLoading = false;
        });
      }
    }
  }

  Future<void> _loadAccounts() async {
    if (_googleAccount == null) return;
    setState(() {
      _isAccountsLoading = true;
    });
    try {
      final accounts = await _adsenseService.listAccounts(_googleAccount!);
      if (!mounted) return;
      final cachedAccountName = _cachedCredential?.accountName;
      final selectedAccount = accounts.isEmpty
          ? null
          : accounts.firstWhere(
              (account) => account.name == cachedAccountName,
              orElse: () => accounts.first,
            );
      setState(() {
        _adsenseAccounts = accounts;
        _selectedAccount = selectedAccount;
        _isAccountsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAccountsLoading = false;
      });
      Toastr.error(_readableError(e));
    }
  }

  Future<void> _loadReport() async {
    if (_googleAccount == null || _selectedAccount == null) return;
    if (_selectedMetrics.isEmpty) {
      Toastr.show('Chọn ít nhất một chỉ số để xem báo cáo.');
      return;
    }
    setState(() {
      _isReportLoading = true;
      _reportError = null;
    });

    try {
      final report = await _adsenseService.generateReport(
        account: _googleAccount!,
        accountName: _selectedAccount!.name,
        startDate: _fromDate,
        endDate: _toDate,
        metrics: _selectedMetrics.toList(growable: false),
        dimensions:
            _selectedDimension.isEmpty ? const [] : [_selectedDimension],
        filters: _activeFilters(),
        limit: _reportRowLimit,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _isReportLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reportError = _readableError(e);
        _isReportLoading = false;
      });
    }
  }

  List<String> _activeFilters() {
    final raw = _filterController.text.trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[\n,]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _selectDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(_minReportYear, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (result != null && mounted) {
      setState(() {
        _fromDate = result.start;
        _toDate = result.end;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _fromDate = DateTime.now().subtract(const Duration(days: 7));
      _toDate = DateTime.now();
      _selectedDimension = _dimensionOptions.first.value;
      _selectedMetrics
        ..clear()
        ..addAll(
          const [
            'ESTIMATED_EARNINGS',
            'PAGE_VIEWS',
            'CLICKS',
            'IMPRESSIONS',
          ],
        );
      _filterController.clear();
    });
  }

  String _formatDateRange() {
    return 'Từ ${_dateFormatter.format(_fromDate)} đến ${_dateFormatter.format(_toDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo Google AdSense'),
        actions: [
          if (_isSignedIn)
            IconButton(
              tooltip: 'Làm mới',
              icon: const Icon(Icons.refresh),
              onPressed: _isReportLoading ? null : _loadReport,
            ),
          if (_isSignedIn)
            IconButton(
              tooltip: 'Đăng xuất Google',
              icon: const Icon(Icons.logout),
              onPressed: _isAuthLoading ? null : _signOut,
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (_isSignedIn) {
              await _loadAccounts();
              await _loadReport();
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.m,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAccountCard(theme, colorScheme),
                const SizedBox(height: AppSpacing.l),
                _buildFilterSection(theme, colorScheme),
                const SizedBox(height: AppSpacing.l),
                _buildReportSection(theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: Icons.account_circle_outlined,
              title: 'Kết nối AdSense',
              action: _isAuthLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.s),
            if (_googleAccount == null)
              Text(
                'Đăng nhập Google để lấy báo cáo AdSense chính thức.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Text(
                'Đã kết nối với Google AdSense.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpacing.m),
            if (_googleAccount == null)
              FilledButton.icon(
                onPressed: _isAuthLoading ? null : _signIn,
                icon: const Icon(Icons.login),
                label: const Text('Đăng nhập Google'),
              )
            else
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundImage: _googleAccount!.photoUrl != null
                        ? NetworkImage(_googleAccount!.photoUrl!)
                        : null,
                    child: _googleAccount!.photoUrl == null
                        ? Text(
                            _googleAccount!.displayName?.isNotEmpty == true
                                ? _googleAccount!.displayName!
                                    .substring(0, 1)
                                    .toUpperCase()
                                : _googleAccount!.email
                                    .substring(0, 1)
                                    .toUpperCase(),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _googleAccount!.displayName ?? 'Tài khoản Google',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _googleAccount!.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (_cachedCredential != null && _googleAccount == null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                'Lần đăng nhập gần nhất: ${_cachedCredential!.email}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_authError != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                'Lỗi đăng nhập: $_authError',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: Icons.tune, title: 'Bộ lọc báo cáo'),
        const SizedBox(height: AppSpacing.s),
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: AppRadius.m,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _isSignedIn ? _selectDateRange : null,
                borderRadius: AppRadius.m,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s,
                    horizontal: AppSpacing.s,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          _formatDateRange(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              if (_isAccountsLoading)
                const LinearProgressIndicator(minHeight: 2)
              else
                DropdownButtonFormField<String>(
                  value: _selectedAccount?.name,
                  decoration: const InputDecoration(
                    labelText: 'Tài khoản AdSense',
                  ),
                  items: _adsenseAccounts
                      .map(
                        (account) => DropdownMenuItem<String>(
                          value: account.name,
                          child: Text(
                            '${account.displayName} (${account.accountId})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: !_isSignedIn
                      ? null
                      : (value) {
                          final account = _adsenseAccounts.firstWhere(
                            (item) => item.name == value,
                            orElse: () => _adsenseAccounts.first,
                          );
                          setState(() {
                            _selectedAccount = account;
                          });
                          if (_googleAccount != null) {
                            _saveCredential(
                              _googleAccount!,
                              accountName: account.name,
                            );
                          }
                        },
                ),
              const SizedBox(height: AppSpacing.m),
              DropdownButtonFormField<String>(
                value: _selectedDimension,
                decoration: const InputDecoration(labelText: 'Phân tích theo'),
                items: _dimensionOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: !_isSignedIn
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedDimension = value;
                        });
                      },
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Chỉ số báo cáo',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: _metricOptions
                    .map(
                      (option) => FilterChip(
                        label: Text(option.label),
                        selected: _selectedMetrics.contains(option.value),
                        onSelected: !_isSignedIn
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedMetrics.add(option.value);
                                  } else {
                                    _selectedMetrics.remove(option.value);
                                  }
                                });
                              },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: _filterController,
                enabled: _isSignedIn,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Bộ lọc (tuỳ chọn)',
                  hintText: 'Ví dụ: COUNTRY_NAME==Vietnam',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _isSignedIn ? _resetFilters : null,
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSignedIn ? _loadReport : null,
                      child: const Text('Tải báo cáo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: Icons.bar_chart_outlined, title: 'Kết quả báo cáo'),
        const SizedBox(height: AppSpacing.s),
        if (!_isSignedIn)
          const _InfoCard(
            icon: Icons.login,
            message: 'Vui lòng đăng nhập Google để xem báo cáo.',
          )
        else if (_isReportLoading)
          const _LoadingCard()
        else if (_reportError != null)
          _ErrorCard(message: _reportError!, onRetry: _loadReport)
        else if (_report == null || _report!.rows.isEmpty)
          const _InfoCard(
            icon: Icons.query_stats_outlined,
            message: 'Chưa có dữ liệu báo cáo trong khoảng thời gian này.',
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(theme, colorScheme),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Chi tiết (${_report!.rows.length} dòng)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              ..._buildReportRows(theme, colorScheme),
            ],
          ),
      ],
    );
  }

  Widget _buildSummaryCards(ThemeData theme, ColorScheme colorScheme) {
    final report = _report;
    if (report == null) return const SizedBox.shrink();
    final totals = report.totalsByHeader();
    final summaryOptions = _metricOptions
        .where((option) => totals.containsKey(option.value))
        .where((option) => _selectedMetrics.contains(option.value))
        .toList(growable: false);

    if (summaryOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.s,
        crossAxisSpacing: AppSpacing.s,
        childAspectRatio: 1.6,
      ),
      itemCount: summaryOptions.length,
      itemBuilder: (context, index) {
        final option = summaryOptions[index];
        final value = totals[option.value] ?? '--';
        return DashboardStatCard(
          icon: option.icon,
          title: option.label,
          value: _formatMetricValue(
            value,
            option.value,
            report.currencyCode,
          ),
          subtitle: 'Tổng cộng',
          color: colorScheme.primary,
        );
      },
    );
  }

  List<Widget> _buildReportRows(ThemeData theme, ColorScheme colorScheme) {
    final report = _report;
    if (report == null) return const [];
    final headers = report.headers;
    return report.rows.take(_reportRowLimit).map((row) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(headers.length, (index) {
              final header = headers[index].name;
              final value = index < row.values.length ? row.values[index] : '--';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _headerLabels[header] ?? _formatHeader(header),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      _formatCellValue(header, value, report.currencyCode),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      );
    }).toList(growable: false);
  }

  String _formatHeader(String raw) {
    final label = raw.replaceAll('_', ' ').toLowerCase();
    return label
        .split(' ')
        .map((part) {
          if (part.isEmpty) return part;
          if (part.length == 1) return part.toUpperCase();
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
  }

  String _formatCellValue(String header, String value, String? currencyCode) {
    if (header == 'DATE') {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return _dateFormatter.format(parsed);
      }
    }
    if (_metricKeys.contains(header)) {
      return _formatMetricValue(value, header, currencyCode);
    }
    return value;
  }

  String _formatMetricValue(
    String value,
    String metric,
    String? currencyCode,
  ) {
    final sanitized = value.replaceAll(',', '').trim();
    final number = double.tryParse(sanitized);
    if (number == null) return value;
    final formatter = NumberFormat('#,##0.##', 'vi_VN');
    if (metric == 'CTR') {
      final percentValue = number <= 1 ? number * 100 : number;
      return '${formatter.format(percentValue)}%';
    }
    if ((metric == 'ESTIMATED_EARNINGS' || metric == 'CPC') &&
        currencyCode != null &&
        currencyCode.isNotEmpty) {
      return '${formatter.format(number)} $currencyCode';
    }
    return formatter.format(number);
  }

  String _readableError(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }
}

class _MetricOption {
  const _MetricOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class _DimensionOption {
  const _DimensionOption({required this.value, required this.label});

  final String value;
  final String label;
}

const List<_MetricOption> _metricOptions = [
  _MetricOption(
    value: 'ESTIMATED_EARNINGS',
    label: 'Doanh thu ước tính',
    icon: Icons.payments_outlined,
  ),
  _MetricOption(
    value: 'PAGE_VIEWS',
    label: 'Lượt xem trang',
    icon: Icons.visibility_outlined,
  ),
  _MetricOption(
    value: 'CLICKS',
    label: 'Lượt nhấp',
    icon: Icons.ads_click,
  ),
  _MetricOption(
    value: 'IMPRESSIONS',
    label: 'Hiển thị',
    icon: Icons.auto_graph,
  ),
  _MetricOption(
    value: 'CTR',
    label: 'CTR',
    icon: Icons.trending_up,
  ),
  _MetricOption(
    value: 'CPC',
    label: 'CPC',
    icon: Icons.attach_money_outlined,
  ),
];

const List<_DimensionOption> _dimensionOptions = [
  _DimensionOption(value: '', label: 'Tổng quan'),
  _DimensionOption(value: 'DATE', label: 'Theo ngày'),
  _DimensionOption(value: 'COUNTRY_NAME', label: 'Theo quốc gia'),
];

const Map<String, String> _headerLabels = {
  'DATE': 'Ngày',
  'COUNTRY_NAME': 'Quốc gia',
  'ESTIMATED_EARNINGS': 'Doanh thu ước tính',
  'PAGE_VIEWS': 'Lượt xem trang',
  'CLICKS': 'Lượt nhấp',
  'IMPRESSIONS': 'Hiển thị',
  'CTR': 'CTR',
  'CPC': 'CPC',
};

const Set<String> _metricKeys = {
  'ESTIMATED_EARNINGS',
  'PAGE_VIEWS',
  'CLICKS',
  'IMPRESSIONS',
  'CTR',
  'CPC',
};

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.m),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    'Không thể tải báo cáo',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
