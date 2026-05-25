import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../services/inventory_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final ApiService apiService;
  const ScanScreen({super.key, required this.apiService});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _qtyController = TextEditingController(text: '1');
  final _manualController = TextEditingController();
  bool _cameraLocked = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  // ── Picu pencarian barcode via provider ───────────────────────────────────

  Future<void> _scan(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty || _cameraLocked) return;
    setState(() => _cameraLocked = true);
    await ref.read(scanActionProvider.notifier).scan(code);
    setState(() => _cameraLocked = false);
  }

  // ── Langsung jalankan transaksi tanpa dialog popup ────────────────────────

  Future<void> _doTransactionIn(Item item) async {
    final q = int.tryParse(_qtyController.text) ?? 1;
    try {
      await ref
          .read(scanActionProvider.notifier)
          .transactionIn(item.name, item.id, q);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Barang masuk berhasil dicatat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _doTransactionOut(Item item) async {
    final q = int.tryParse(_qtyController.text) ?? 1;
    final sessionId = const Uuid().v4();
    try {
      await ref
          .read(scanActionProvider.notifier)
          .transactionOut(item.name, item.id, q, sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Barang keluar berhasil dicatat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ── Listen perubahan ScanState ──────────────────────────────────────────
    ref.listen<ScanState>(scanActionProvider, (previous, next) {
      if (!mounted) return;
      if (next is ScanNotFound) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Barang dengan barcode "${next.barcode}" belum terdaftar di sistem',
              ),
              backgroundColor: cs.error,
            ),
          );
        ref.read(scanActionProvider.notifier).reset();
      } else if (next is ScanError) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.message)));
        ref.read(scanActionProvider.notifier).reset();
      }
    });

    final scanState = ref.watch(scanActionProvider);
    final isLoading = scanState is ScanLoading || _cameraLocked;

    String? statusText;
    bool isError = false;
    if (scanState is ScanSuccess) {
      statusText = 'Barang ditemukan: ${scanState.item.name}';
    } else if (scanState is ScanNotFound) {
      statusText = 'Barang tidak ditemukan';
      isError = true;
    } else if (scanState is ScanError) {
      statusText = scanState.message;
      isError = true;
    }

    final item = scanState is ScanSuccess ? scanState.item : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Barcode'),
        actions: [
          if (scanState is! ScanInitial)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(scanActionProvider.notifier).reset(),
              tooltip: 'Reset',
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Kamera Scanner ──────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    if (isLoading) return;
                    final barcode = capture.barcodes.first.rawValue;
                    if (barcode != null) _scan(barcode);
                  },
                ),
                Positioned.fill(
                  child: CustomPaint(painter: _ScannerFramePainter(cs.primary)),
                ),
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isLoading
                            ? 'Memuat data barang...'
                            : 'Arahkan kamera ke barcode',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    ),
                  ),
              ],
            ),
          ),

          // ── Panel bawah ─────────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              color: cs.surface,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input manual
                    TextField(
                      controller: _manualController,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Masukkan barcode manual',
                        prefixIcon: const Icon(Icons.barcode_reader),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search_rounded),
                          onPressed: () => _scan(_manualController.text),
                        ),
                      ),
                      onSubmitted: _scan,
                      textInputAction: TextInputAction.search,
                    ),
                    const SizedBox(height: 14),

                    // Status bar
                    if (statusText != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isError
                              ? cs.error.withValues(alpha: 0.12)
                              : cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isError
                                ? cs.error.withValues(alpha: 0.4)
                                : cs.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isError
                                  ? Icons.error_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 18,
                              color: isError ? cs.error : cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: isError ? cs.error : cs.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Detail barang + tombol transaksi langsung
                    if (item != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gambar produk
                            _buildProductImage(item.imageUrl, cs),
                            if (item.imageUrl?.isNotEmpty == true)
                              const SizedBox(height: 10),
                            Text(item.name, style: tt.titleMedium),
                            const SizedBox(height: 8),
                            _infoRow('Barcode', item.barcode, cs),
                            _infoRow(
                              'Harga',
                              'Rp ${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                              cs,
                            ),
                            _infoRow(
                              'Stok saat ini',
                              '${item.stock}',
                              cs,
                              valueColor: item.stock <= item.minStock
                                  ? const Color(0xFFFF8C00)
                                  : cs.secondary,
                            ),
                            _infoRow('Min. stok', '${item.minStock}', cs),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Input jumlah
                      TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: cs.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Jumlah transaksi',
                          prefixIcon: Icon(Icons.numbers_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tombol transaksi — langsung tanpa popup
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => _doTransactionIn(item),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Barang Masuk'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => _doTransactionOut(item),
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Barang Keluar'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFFF8C00,
                                ).withValues(alpha: 0.85),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget gambar produk untuk panel scan ─────────────────────────────────

  Widget _buildProductImage(String? url, ColorScheme cs) {
    final src = url?.trim() ?? '';
    if (src.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Image.network(
          src,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: cs.surfaceContainerHighest,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (ctx, err, stack) => Container(
            color: cs.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 36,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    ColorScheme cs, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scanner frame overlay painter ─────────────────────────────────────────────
class _ScannerFramePainter extends CustomPainter {
  final Color cornerColor;
  _ScannerFramePainter(this.cornerColor);

  @override
  void paint(Canvas canvas, Size size) {
    const cornerLen = 28.0;
    const cornerW = 3.5;
    final paint = Paint()
      ..color = cornerColor
      ..strokeWidth = cornerW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final boxW = size.width * 0.65;
    final boxH = boxW * 0.65;
    final left = (size.width - boxW) / 2;
    final top = (size.height - boxH) / 2;
    final right = left + boxW;
    final bottom = top + boxH;

    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), overlayPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, bottom, size.width, size.height - bottom),
      overlayPaint,
    );
    canvas.drawRect(Rect.fromLTWH(0, top, left, boxH), overlayPaint);
    canvas.drawRect(
      Rect.fromLTWH(right, top, size.width - right, boxH),
      overlayPaint,
    );

    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * cornerLen, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * cornerLen), paint);
    }

    corner(left, top, 1, 1);
    corner(right, top, -1, 1);
    corner(left, bottom, 1, -1);
    corner(right, bottom, -1, -1);
  }

  @override
  bool shouldRepaint(_ScannerFramePainter old) =>
      old.cornerColor != cornerColor;
}
