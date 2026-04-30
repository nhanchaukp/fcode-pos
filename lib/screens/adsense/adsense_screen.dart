import 'dart:async';

import 'package:fcode_pos/models/adsense_models.dart';
import 'package:fcode_pos/services/adsense_service.dart';
import 'package:fcode_pos/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class AdsenseScreen extends StatefulWidget {
  const AdsenseScreen({super.key});

  @override
  State<AdsenseScreen> createState() => _AdsenseScreenState();
}

class _AdsenseScreenState extends State<AdsenseScreen> {
  final _service = AdsenseService();

  // Auth
  bool _initializingGsi = true;
  String? _initError;
  GoogleSignInAccount? _googleAccount;
  bool _signingIn = false;

  // Accounts
  List<AdsenseAccount> _accounts = [];
  AdsenseAccount? _selectedAccount;
  String _currency = 'USD';

  // Thu nhập ước tính (4 periods)
  AdsenseEarningsOverview? _overview;
  bool _loadingOverview = false;

  // Hiệu suất — bộ lọc riêng
  AdsenseDateRange _performanceFilter = AdsenseDateRange.today;
  AdsensePerformanceData? _performance;
  bool _loadingPerformance = false;

  // Theo Quốc gia — bộ lọc riêng
  AdsenseDateRange _countryFilter = AdsenseDateRange.today;
  AdsenseReport? _countryReport;
  bool _loadingCountry = false;
  String? _countryError;

  // Theo trang web — bộ lọc riêng, OWNED_SITE_DOMAIN_NAME với fallback AD_UNIT_NAME
  AdsenseDateRange _siteFilter = AdsenseDateRange.today;
  AdsenseReport? _siteReport;
  bool _loadingSite = false;
  String? _siteError;

  late StreamSubscription<GoogleSignInAuthenticationEvent> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = _service.authenticationEvents.listen(_onAuthEvent);
    _initGsi();
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  void _onAuthEvent(GoogleSignInAuthenticationEvent event) {
    if (!mounted) return;
    if (event is GoogleSignInAuthenticationEventSignIn) {
      setState(() => _googleAccount = event.user);
      _loadAccounts(event.user);
    } else if (event is GoogleSignInAuthenticationEventSignOut) {
      setState(() {
        _googleAccount = null;
        _accounts = [];
        _selectedAccount = null;
        _overview = null;
        _performance = null;
        _countryReport = null;
        _countryError = null;
        _siteReport = null;
        _siteError = null;
      });
    }
  }

  Future<void> _initGsi() async {
    if (mounted) setState(() => _initializingGsi = false);
    await _trySilentSignIn();
  }

  Future<void> _trySilentSignIn() async {
    try {
      final account = await _service.attemptSilentSignIn();
      if (account != null && mounted) {
        setState(() => _googleAccount = account);
        await _loadAccounts(account);
      }
    } catch (_) {}
  }

  Future<void> _handleSignIn() async {
    setState(() => _signingIn = true);
    try {
      final account = await _service.signIn();
      if (mounted) setState(() => _googleAccount = account);
      await _loadAccounts(account);
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        _showError('Đăng nhập thất bại: ${e.description ?? e.code.name}');
      }
    } catch (e) {
      if (mounted) _showError('Đăng nhập thất bại: $e');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _handleSignOut() => _service.signOut();

  // ── Data loading ─────────────────────────────────────────────────────────────

  Future<void> _loadAccounts(GoogleSignInAccount account) async {
    try {
      final accounts = await _service.getAccounts(account);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _selectedAccount = accounts.isNotEmpty ? accounts.first : null;
      });
      if (_selectedAccount != null) {
        await Future.wait([
          _loadOverview(),
          _loadAllFilteredData(),
        ]);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _loadOverview() async {
    final account = _selectedAccount;
    final ga = _googleAccount;
    if (account == null || ga == null) return;
    setState(() => _loadingOverview = true);
    try {
      final ov = await _service.getEarningsOverview(
        account: ga,
        accountName: account.name,
      );
      if (!mounted) return;
      setState(() {
        _overview = ov;
        _loadingOverview = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOverview = false);
    }
  }

  /// Load cả 3 section độc lập cùng lúc khi khởi tạo.
  Future<void> _loadAllFilteredData() => Future.wait([
        _loadPerformance(),
        _loadCountry(),
        _loadSite(),
      ]);

  Future<void> _loadPerformance() async {
    final account = _selectedAccount;
    final ga = _googleAccount;
    if (account == null || ga == null) return;
    setState(() => _loadingPerformance = true);
    try {
      final data = await _service.getPerformanceMetrics(
        account: ga,
        accountName: account.name,
        dateRange: _performanceFilter,
      );
      if (!mounted) return;
      setState(() {
        _performance = data;
        _loadingPerformance = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPerformance = false);
    }
  }

  Future<void> _loadCountry() async {
    final account = _selectedAccount;
    final ga = _googleAccount;
    if (account == null || ga == null) return;
    setState(() { _loadingCountry = true; _countryError = null; });
    try {
      final report = await _service.generateReport(
        account: ga,
        accountName: account.name,
        dateRange: _countryFilter,
        dimension: AdsenseDimension.country,
      );
      if (!mounted) return;
      setState(() {
        _countryReport = report;
        _loadingCountry = false;
        if (report.currencyCode.isNotEmpty) _currency = report.currencyCode;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCountry = false;
          _countryError = e.toString();
        });
      }
    }
  }

  /// Thử OWNED_SITE_DOMAIN_NAME trước, fallback sang AD_UNIT_NAME.
  Future<void> _loadSite() async {
    final account = _selectedAccount;
    final ga = _googleAccount;
    if (account == null || ga == null) return;
    setState(() { _loadingSite = true; _siteError = null; });
    try {
      AdsenseReport report;
      try {
        report = await _service.generateReport(
          account: ga,
          accountName: account.name,
          dateRange: _siteFilter,
          dimension: AdsenseDimension.ownedSiteDomain,
        );
      } catch (_) {
        report = await _service.generateReport(
          account: ga,
          accountName: account.name,
          dateRange: _siteFilter,
          dimension: AdsenseDimension.adUnit,
        );
      }
      if (!mounted) return;
      setState(() {
        _siteReport = report;
        _loadingSite = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSite = false;
          _siteError = e.toString();
        });
      }
    }
  }

  Future<void> _refreshAll() => Future.wait([
        _loadOverview(),
        _loadAllFilteredData(),
      ]);

  Future<void> _retrySite() => _loadSite();
  Future<void> _retryCountry() => _loadCountry();

  void _onPerformanceFilterChanged(AdsenseDateRange range) {
    setState(() => _performanceFilter = range);
    _loadPerformance();
  }

  void _onCountryFilterChanged(AdsenseDateRange range) {
    setState(() => _countryFilter = range);
    _loadCountry();
  }

  void _onSiteFilterChanged(AdsenseDateRange range) {
    setState(() => _siteFilter = range);
    _loadSite();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google AdSense'),
        actions: [
          if (_googleAccount != null)
            _AccountAvatar(account: _googleAccount!, onSignOut: _handleSignOut),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_initializingGsi) return const Center(child: CircularProgressIndicator());
    if (_initError != null) return _ErrorView(message: _initError!, onRetry: _initGsi);
    if (_googleAccount == null) {
      return _SignInView(isLoading: _signingIn, onSignIn: _handleSignIn);
    }
    return _buildDashboard();
  }

  Widget _buildDashboard() {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Account selector
          if (_accounts.length > 1)
            SliverToBoxAdapter(
              child: _AccountSelector(
                accounts: _accounts,
                selected: _selectedAccount,
                onChanged: (a) {
                  setState(() {
                    _selectedAccount = a;
                    _overview = null;
                    _performance = null;
                    _countryReport = null;
                    _countryError = null;
                    _siteReport = null;
                    _siteError = null;
                  });
                  _refreshAll();
                },
              ),
            ),

          // No account message
          if (_accounts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_circle_outlined, size: 56, color: colorScheme.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy tài khoản AdSense',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

          if (_accounts.isNotEmpty) ...[
            // ── Card 1: Thu nhập ước tính ──────────────────────────────────
            SliverToBoxAdapter(
              child: _EarningsOverviewCard(
                overview: _overview,
                isLoading: _loadingOverview,
                currencyCode: _currency,
              ),
            ),

            // ── Card 2: Hiệu suất (bộ lọc riêng) ─────────────────────────
            SliverToBoxAdapter(
              child: _PerformanceCard(
                data: _performance,
                isLoading: _loadingPerformance,
                dateRange: _performanceFilter,
                currencyCode: _currency,
                onDateRangeChanged: _onPerformanceFilterChanged,
              ),
            ),

            // ── Section: Theo Quốc gia (bộ lọc riêng) ─────────────────────
            SliverToBoxAdapter(
              child: _BreakdownSection(
                title: 'Theo Quốc gia',
                icon: Icons.public_outlined,
                report: _countryReport,
                isLoading: _loadingCountry,
                currencyCode: _currency,
                dateRange: _countryFilter,
                onDateRangeChanged: _onCountryFilterChanged,
                error: _countryError,
                onRetry: _retryCountry,
              ),
            ),

            // ── Section: Theo trang web (bộ lọc riêng) ────────────────────
            SliverToBoxAdapter(
              child: _BreakdownSection(
                title: 'Theo trang web',
                icon: Icons.web_outlined,
                report: _siteReport,
                isLoading: _loadingSite,
                currencyCode: _currency,
                dateRange: _siteFilter,
                onDateRangeChanged: _onSiteFilterChanged,
                error: _siteError,
                onRetry: _retrySite,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Sign-in view ──────────────────────────────────────────────────────────────

class _SignInView extends StatelessWidget {
  const _SignInView({required this.isLoading, required this.onSignIn});
  final bool isLoading;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.bar_chart_rounded, size: 44, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text('Google AdSense',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Đăng nhập bằng tài khoản Google để xem báo cáo AdSense của bạn',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: isLoading ? null : onSignIn,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login),
              label: Text(isLoading ? 'Đang đăng nhập...' : 'Đăng nhập với Google'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Account avatar ────────────────────────────────────────────────────────────

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.account, required this.onSignOut});
  final GoogleSignInAccount account;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 48),
        child: CircleAvatar(
          radius: 16,
          backgroundImage: account.photoUrl != null ? NetworkImage(account.photoUrl!) : null,
          child: account.photoUrl == null
              ? Text((account.displayName ?? account.email).substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 14))
              : null,
        ),
        itemBuilder: (_) => [
          PopupMenuItem(
            enabled: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(account.displayName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(account.email,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
        ],
        onSelected: (v) { if (v == 'logout') onSignOut(); },
      ),
    );
  }
}

// ── Account selector ──────────────────────────────────────────────────────────

class _AccountSelector extends StatelessWidget {
  const _AccountSelector({required this.accounts, required this.selected, required this.onChanged});
  final List<AdsenseAccount> accounts;
  final AdsenseAccount? selected;
  final ValueChanged<AdsenseAccount> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tài khoản AdSense',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AdsenseAccount>(
            value: selected,
            isDense: true,
            isExpanded: true,
            items: accounts
                .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text('${a.displayName} (${a.publisherId})', overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (a) { if (a != null) onChanged(a); },
          ),
        ),
      ),
    );
  }
}

// ── Card 1: Thu nhập ước tính ─────────────────────────────────────────────────

class _EarningsOverviewCard extends StatelessWidget {
  const _EarningsOverviewCard({
    required this.overview, required this.isLoading, required this.currencyCode,
  });
  final AdsenseEarningsOverview? overview;
  final bool isLoading;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(symbol: currencyCode == 'USD' ? '\$' : currencyCode, decimalDigits: 2);
    String val(double v) => isLoading ? '–' : fmt.format(v);

    final items = [
      ('Đầu ngày đến giờ', val(overview?.today ?? 0)),
      ('Hôm qua', val(overview?.yesterday ?? 0)),
      ('7 ngày qua', val(overview?.last7Days ?? 0)),
      ('Tháng này', val(overview?.thisMonth ?? 0)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(children: [
                Text('Thu nhập ước tính',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.onPrimary, fontWeight: FontWeight.w700)),
                if (isLoading) ...[
                  const SizedBox(width: 8),
                  SizedBox(width: 12, height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.onPrimary.applyOpacity(0.6))),
                ],
              ]),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: items.map((item) {
                final (label, value) = item;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.onPrimary.applyOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label,
                          style: TextStyle(fontSize: 11, color: cs.onPrimary.applyOpacity(0.75)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(value,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card 2: Hiệu suất (bộ lọc riêng) ────────────────────────────────────────

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.data,
    required this.isLoading,
    required this.dateRange,
    required this.currencyCode,
    required this.onDateRangeChanged,
  });

  final AdsensePerformanceData? data;
  final bool isLoading;
  final AdsenseDateRange dateRange;
  final String currencyCode;
  final ValueChanged<AdsenseDateRange> onDateRangeChanged;

  static const _filterOptions = [
    AdsenseDateRange.today,
    AdsenseDateRange.yesterday,
    AdsenseDateRange.last7Days,
    AdsenseDateRange.last30Days,
    AdsenseDateRange.monthToDate,
    AdsenseDateRange.yearToDate,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sym = currencyCode == 'USD' ? '\$' : currencyCode;
    final cFmt = NumberFormat.currency(symbol: sym, decimalDigits: 2);
    final nFmt = NumberFormat.compact(locale: 'vi');
    final pFmt = NumberFormat.percentPattern()
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;

    final d = data ?? AdsensePerformanceData.empty;
    String c(double v) => isLoading ? '–' : cFmt.format(v);
    String n(int v) => isLoading ? '–' : nFmt.format(v);
    String p(double v) => isLoading ? '–' : pFmt.format(v);

    final metrics = [
      ('Số lượt xem trang', n(d.pageViews)),
      ('RPM của Trang', c(d.pageRpm)),
      ('Lượt hiển thị', n(d.impressions)),
      ('Số lượt nhấp chuột', n(d.clicks)),
      ('CPC', c(d.cpc)),
      ('CTR của Trang', p(d.ctr)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant.applyOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Hiệu suất',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (isLoading)
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<AdsenseDateRange>(
                    value: dateRange,
                    isDense: true,
                    items: _filterOptions
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.label,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500, color: cs.primary)),
                            ))
                        .toList(),
                    onChanged: (r) { if (r != null) onDateRangeChanged(r); },
                    icon: Icon(Icons.keyboard_arrow_down, size: 18, color: cs.primary),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                children: metrics.asMap().entries.map((e) {
                  final col = e.key % 3;
                  final row = e.key ~/ 3;
                  final (label, value) = e.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: col < 2
                            ? BorderSide(color: cs.outlineVariant.applyOpacity(0.3))
                            : BorderSide.none,
                        bottom: row < 1
                            ? BorderSide(color: cs.outlineVariant.applyOpacity(0.3))
                            : BorderSide.none,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant, fontSize: 10),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(value,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Breakdown section (Quốc gia / Trang web) ──────────────────────────────────

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.title,
    required this.icon,
    required this.report,
    required this.isLoading,
    required this.currencyCode,
    required this.dateRange,
    required this.onDateRangeChanged,
    this.error,
    required this.onRetry,
  });

  final String title;
  final IconData icon;
  final AdsenseReport? report;
  final bool isLoading;
  final String currencyCode;
  final AdsenseDateRange dateRange;
  final ValueChanged<AdsenseDateRange> onDateRangeChanged;
  final String? error;
  final VoidCallback onRetry;

  static const _filterOptions = [
    AdsenseDateRange.today,
    AdsenseDateRange.yesterday,
    AdsenseDateRange.last7Days,
    AdsenseDateRange.last30Days,
    AdsenseDateRange.monthToDate,
    AdsenseDateRange.yearToDate,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sym = currencyCode == 'USD' ? '\$' : currencyCode;
    final cFmt = NumberFormat.currency(symbol: sym, decimalDigits: 2);
    final nFmt = NumberFormat.compact(locale: 'vi');
    final pFmt = NumberFormat.percentPattern()
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;

    // Sort by earnings desc, top 10
    final rows = [...?report?.rows]
      ..sort((a, b) => b.estimatedEarnings.compareTo(a.estimatedEarnings));
    final topRows = rows.take(10).toList();
    final totals = report?.totals;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant.applyOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với filter dropdown riêng
              Row(children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
                  ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<AdsenseDateRange>(
                    value: dateRange,
                    isDense: true,
                    items: _filterOptions
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.label,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500, color: cs.primary)),
                            ))
                        .toList(),
                    onChanged: (r) { if (r != null) onDateRangeChanged(r); },
                    icon: Icon(Icons.keyboard_arrow_down, size: 18, color: cs.primary),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Error state
              if (error != null && !isLoading)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.applyOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, size: 16, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
                          maxLines: 3),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                ),

              // Loading placeholder
              if (isLoading && topRows.isEmpty && error == null)
                Column(
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 36, decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  )),
                ),

              // Empty state (chỉ show khi không có lỗi)
              if (!isLoading && topRows.isEmpty && error == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Không có dữ liệu cho kỳ này',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                ),

              // Column headers
              if (topRows.isNotEmpty) ...[
                Row(children: [
                  Expanded(child: Text('Tên',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
                  SizedBox(width: 76, child: Text('Doanh thu',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
                  SizedBox(width: 52, child: Text('Nhấp',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
                  SizedBox(width: 58, child: Text('CTR',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))),
                ]),
                const Divider(height: 10),

                // Data rows
                ...topRows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  return Container(
                    color: i.isOdd ? cs.surfaceContainerLow.applyOpacity(0.5) : null,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      // Rank badge
                      Container(
                        width: 20, height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: i == 0 ? cs.primary : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: i == 0 ? cs.onPrimary : cs.onSurfaceVariant,
                              )),
                        ),
                      ),
                      Expanded(
                        child: Text(row.dimensionValue,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: 76,
                        child: Text(cFmt.format(row.estimatedEarnings),
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(nFmt.format(row.clicks),
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1),
                      ),
                      SizedBox(
                        width: 58,
                        child: Text(pFmt.format(row.ctr),
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1),
                      ),
                    ]),
                  );
                }),

                // Totals
                if (totals != null) ...[
                  const Divider(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const SizedBox(width: 28),
                      Expanded(child: Text('Tổng',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700))),
                      SizedBox(width: 76,
                          child: Text(cFmt.format(totals.estimatedEarnings),
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1)),
                      SizedBox(width: 52,
                          child: Text(nFmt.format(totals.clicks),
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1)),
                      SizedBox(width: 58,
                          child: Text(pFmt.format(totals.ctr),
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1)),
                    ]),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
        ]),
      ),
    );
  }
}

