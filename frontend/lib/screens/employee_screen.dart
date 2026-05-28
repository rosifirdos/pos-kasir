import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({Key? key}) : super(key: key);

  @override
  _EmployeeScreenState createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  List<dynamic> users = [];
  bool isLoading = true;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    
    if (token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('${ApiService.siteUrl}/api/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          users = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showUserForm({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final usernameCtrl = TextEditingController(text: isEdit ? user['username'] : '');
    final passwordCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: isEdit ? user['pin'] : '');
    String role = isEdit ? user['role'] : 'KASIR';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Pegawai' : 'Tambah Pegawai'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Password (kosongkan jika tidak diubah)' : 'Password',
                  ),
                  obscureText: true,
                ),
                TextField(
                  controller: pinCtrl,
                  decoration: const InputDecoration(labelText: 'PIN (untuk Void)'),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(value: 'KASIR', child: Text('KASIR')),
                  ],
                  onChanged: (val) {
                    if (val != null) role = val;
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final token = auth.token;
                  if (token == null) return;

                  final data = {
                    'username': usernameCtrl.text,
                    'role': role,
                    if (pinCtrl.text.isNotEmpty) 'pin': pinCtrl.text,
                    if (passwordCtrl.text.isNotEmpty) 'password': passwordCtrl.text,
                  };

                  http.Response response;
                  if (isEdit) {
                    response = await http.put(
                      Uri.parse('${ApiService.siteUrl}/api/users/${user['id']}'),
                      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                      body: jsonEncode(data),
                    );
                  } else {
                    response = await http.post(
                      Uri.parse('${ApiService.siteUrl}/api/users'),
                      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
                      body: jsonEncode(data),
                    );
                  }

                  Navigator.pop(ctx);
                  if (response.statusCode == 201 || response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil disimpan')));
                    _fetchUsers();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan')));
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        });
      },
    );
  }

  void _confirmDelete(int id, String username) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pegawai'),
        content: Text('Yakin ingin menghapus $username?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final response = await http.delete(
                Uri.parse('${ApiService.siteUrl}/api/users/$id'),
                headers: {'Authorization': 'Bearer ${auth.token}'},
              );
              if (response.statusCode == 200) {
                _fetchUsers();
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pegawai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showUserForm(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(u['username']),
                  subtitle: Text(u['role']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showUserForm(user: u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(u['id'], u['username']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
