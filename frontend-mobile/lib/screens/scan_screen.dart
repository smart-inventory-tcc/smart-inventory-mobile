import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class ScanScreen extends StatefulWidget {
  final ApiService apiService;

  const ScanScreen({super.key, required this.apiService});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Item? _item;
  bool _loading = false;
  String? _status;
  final _qtyController = TextEditingController(text: '1');
  bool _scanned = false;

  Future<void> _fetchItem(String barcode) async {
    setState(() {
      _loading = true;
      _status = null;
    });
    final result = await widget.apiService.fetchItemByCode(barcode);
    setState(() {
      _loading = false;
      if (result.isSuccess && result.data != null) {
        _item = result.data;
        _status = 'Barang ditemukan: ${_item!.name}';
      } else {
        _status = result.error;
      }
    });
  }

  Future<void> _performTransaction(String type) async {
    if (_item == null) return;
    final quantity = int.tryParse(_qtyController.text) ?? 1;
    final result = await widget.apiService.recordTransaction(
      type,
      _item!.id,
      quantity,
    );
    if (result.isSuccess) {
      setState(() {
        _status = '${type.toUpperCase()} berhasil: ${result.data}';
      });
      await _fetchItem(_item!.barcode);
    } else {
      setState(() {
        _status = result.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner Barcode')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    if (_scanned) return;
                    final barcode = capture.barcodes.first.rawValue;
                    if (barcode != null) {
                      _scanned = true;
                      _fetchItem(barcode).then((_) {
                        _scanned = false;
                      });
                    }
                  },
                ),
                Container(
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'Arahkan kamera ke barcode. Jika tidak tersedia, masukkan secara manual.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_status != null)
                    Text(
                      _status!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Masukkan barcode manual',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _fetchItem,
                  ),
                  const SizedBox(height: 12),
                  if (_item != null) ...[
                    Text(
                      'Nama: ${_item!.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Stok: ${_item!.stock}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Min stok: ${_item!.minStock}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah transaksi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () => _performTransaction('in'),
                            child: const Text('Barang Masuk'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () => _performTransaction('out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Barang Keluar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
