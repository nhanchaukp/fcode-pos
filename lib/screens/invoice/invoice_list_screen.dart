import 'package:fcode_pos/screens/invoice/invoice_documents_tab.dart';
import 'package:fcode_pos/screens/invoice/invoice_providers_tab.dart';
import 'package:flutter/material.dart';

enum _InvoiceListTab {
  documents('Hóa đơn', Icons.receipt_long_outlined),
  providers('Nhà cung cấp', Icons.store_outlined);

  const _InvoiceListTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<InvoiceDocumentsTabState> _documentsKey =
      GlobalKey<InvoiceDocumentsTabState>();
  final GlobalKey<InvoiceProvidersTabState> _providersKey =
      GlobalKey<InvoiceProvidersTabState>();

  static const List<_InvoiceListTab> _tabs = _InvoiceListTab.values;

  _InvoiceListTab get _currentTab => _tabs[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrent() async {
    switch (_currentTab) {
      case _InvoiceListTab.documents:
        await _documentsKey.currentState?.refreshAll();
      case _InvoiceListTab.providers:
        await _providersKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn điện tử'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs
              .map(
                (tab) => Tab(text: tab.label, icon: Icon(tab.icon, size: 20)),
              )
              .toList(growable: false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Làm mới',
            onPressed: _refreshCurrent,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          InvoiceDocumentsTab(key: _documentsKey),
          InvoiceProvidersTab(key: _providersKey),
        ],
      ),
    );
  }
}
