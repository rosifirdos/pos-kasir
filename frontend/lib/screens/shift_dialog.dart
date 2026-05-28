import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ShiftDialog {
  static Future<void> showOpenShift(BuildContext context, VoidCallback onSuccess) async {
    final controller = TextEditingController(text: '0');
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Buka Shift'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan modal awal kasir untuk shift ini:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Modal Awal (Rp)',
                    prefixText: 'Rp ',
                  ),
                ),
              ],
            ),
            actions: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    final val = double.tryParse(controller.text) ?? 0;
                    final api = ApiService();
                    final success = await api.openShift(val);
                    if (success) {
                      Navigator.pop(ctx);
                      onSuccess();
                    } else {
                      setState(() => isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal membuka shift.')),
                      );
                    }
                  },
                  child: const Text('Buka Shift'),
                ),
            ],
          );
        });
      },
    );
  }

  static Future<void> showCloseShift(BuildContext context, VoidCallback onSuccess) async {
    final controller = TextEditingController(text: '0');
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Tutup Shift'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan uang tunai yang ada di laci kasir saat ini:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kas Fisik (Rp)',
                    prefixText: 'Rp ',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    final val = double.tryParse(controller.text) ?? 0;
                    final api = ApiService();
                    final success = await api.closeShift(val);
                    if (success) {
                      Navigator.pop(ctx);
                      onSuccess();
                    } else {
                      setState(() => isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menutup shift.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Tutup Shift'),
                ),
            ],
          );
        });
      },
    );
  }
}
