import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _summary;
  List<dynamic>? _topProducts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _apiService.getDailySummary();
      final topProducts = await _apiService.getTopProducts();
      setState(() {
        _summary = summary;
        _topProducts = topProducts;
        _isLoading = false;
      });
    } catch (e) {
      print('Dashboard error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Bisnis'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Hari Ini',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Transaksi',
                        _summary?['transactionCount'].toString() ?? '0',
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Pendapatan',
                        currencyFormatter.format(_summary?['totalRevenue'] ?? 0),
                        Icons.payments,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Margin/Laba',
                        currencyFormatter.format(_summary?['totalMargin'] ?? 0),
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '5 Produk Terlaris',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_topProducts == null || _topProducts!.isEmpty)
                    const Center(child: Text('Belum ada data penjualan.'))
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _topProducts!.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final p = _topProducts![index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo[100],
                              child: Text('${index + 1}'),
                            ),
                            title: Text(p['name']),
                            trailing: Text(
                              '${p['totalSold']} Terjual',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
