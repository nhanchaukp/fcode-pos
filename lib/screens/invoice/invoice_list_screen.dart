import 'package:fcode_pos/screens/invoice/invoice_documents_tab.dart';
import 'package:fcode_pos/screens/invoice/invoice_providers_tab.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrent() async {
    if (_tabController.index == 0) {
      await _documentsKey.currentState?.refreshAll();
    } else {
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
          tabs: const [
            Tab(
              text: 'Hóa đơn',
              icon: Icon(Icons.receipt_long_outlined, size: 20),
            ),
            Tab(
              text: 'Nhà cung cấp',
              icon: Icon(Icons.store_outlined, size: 20),
            ),
          ],
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
