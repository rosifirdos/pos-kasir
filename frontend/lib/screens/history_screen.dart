import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> activities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final data = await apiService.getActivityLogs();
      setState(() {
        activities = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
    }
  }

  IconData _getIconForAction(String action) {
    if (action.startsWith('ADD')) return Icons.add_circle;
    if (action.startsWith('UPDATE')) return Icons.edit;
    if (action.startsWith('DELETE')) return Icons.delete;
    if (action == 'TRANSACTION') return Icons.receipt;
    if (action == 'STOCK_IN') return Icons.arrow_downward;
    if (action == 'STOCK_OUT') return Icons.arrow_upward;
    return Icons.history;
  }

  Color _getColorForAction(String action) {
    if (action.startsWith('ADD')) return Colors.green;
    if (action.startsWith('UPDATE')) return Colors.blue;
    if (action.startsWith('DELETE')) return Colors.red;
    if (action == 'TRANSACTION') return Colors.purple;
    if (action == 'VOID_TRANSACTION') return Colors.redAccent;
    if (action == 'STOCK_IN') return Colors.teal;
    if (action == 'STOCK_OUT') return Colors.orange;
    return Colors.grey;
  }

  Future<void> _voidTransaction(int transactionId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    String pin = '';

    if (!auth.isAdmin) {
      bool? hasPin = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final pinController = TextEditingController();
          return AlertDialog(
            title: const Text('Otorisasi Admin'),
            content: TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN Admin'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  pin = pinController.text;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Otorisasi'),
              )
            ],
          );
        }
      );
      if (hasPin != true) return;
    }

    try {
      final success = await apiService.voidTransaction(transactionId, pin);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi berhasil dibatalkan.')));
        _fetchActivities();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membatalkan transaksi.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchActivities,
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : activities.isEmpty
              ? Center(child: Text('No activity logs found.'))
              : ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final action = activity['action'] ?? 'UNKNOWN';
                    final date = DateTime.parse(activity['createdAt']).toLocal();
                    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForAction(action).withOpacity(0.2),
                          child: Icon(_getIconForAction(action), color: _getColorForAction(action)),
                        ),
                        title: Text(activity['details'] ?? '$action on ${activity['entityType']}'),
                        subtitle: Text(formattedDate),
                        trailing: action == 'TRANSACTION'
                            ? TextButton.icon(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                label: const Text('VOID', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  if (activity['entityId'] != null) {
                                    _voidTransaction(activity['entityId']);
                                  }
                                },
                              )
                            : Text(
                                activity['entityType'] ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
