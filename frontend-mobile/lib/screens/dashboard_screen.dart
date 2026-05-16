import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;
  final User user;

  const DashboardScreen({
    super.key,
    required this.apiService,
    required this.user,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<Item> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.apiService.fetchItems();
    if (result.isSuccess && result.data != null) {
      setState(() {
        _items = result.data!;
      });
    } else {
      setState(() {
        _error = result.error ?? 'Tidak dapat memuat barang';
      });
    }
    setState(() => _loading = false);
  }

  void _openScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanScreen(apiService: widget.apiService),
      ),
    );
    await _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pegawai'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Barang'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${widget.user.username}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${widget.user.role}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            const Text(
              'Daftar Barang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _items.isEmpty
                  ? const Center(child: Text('Belum ada barang dalam sistem.'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(item.stock.toString()),
                            ),
                            title: Text(item.name),
                            subtitle: Text(
                              'Barcode: ${item.barcode}\nHarga: Rp ${item.price.toStringAsFixed(0)}',
                            ),
                            trailing: item.stock <= item.minStock
                                ? const Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                  )
                                : null,
                            isThreeLine: true,
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
}
