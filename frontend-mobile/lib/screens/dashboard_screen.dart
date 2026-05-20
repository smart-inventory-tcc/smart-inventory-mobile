import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/inventory_provider.dart';
import 'login_screen.dart';
import 'scan_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final ApiService apiService;
  final User user;

  const DashboardScreen({
    super.key,
    required this.apiService,
    required this.user,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  String get _displayName =>
      (widget.user.name != null && widget.user.name!.trim().isNotEmpty)
          ? widget.user.name!.trim()
          : widget.user.username;

  @override
  void initState() {
    super.initState();
  }

  void _openScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanScreen(apiService: widget.apiService),
      ),
    );
    // Refresh data setelah kembali dari scanner
    ref.invalidate(itemsProvider);
  }

  /// Tampilkan dialog konfirmasi lalu logout
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final navigator = Navigator.of(context); // capture sebelum async
      await ref.read(authProvider.notifier).logout();
      navigator.pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (ctx, anim, secondAnim) => const LoginScreen(),
          transitionsBuilder: (ctx, a, secondAnim, c) =>
              FadeTransition(opacity: a, child: c),
        ),
        (route) => false, // hapus semua route sebelumnya
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(itemsProvider),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Keluar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan Barang'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header / Greeting ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.outline, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                // Avatar inisial
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primary.withValues(alpha: 0.18),
                  child: Text(
                    _displayName.isNotEmpty
                        ? _displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $_displayName',
                        style: tt.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.user.role,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Judul daftar barang ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daftar Barang', style: tt.titleLarge),
                if (!itemsAsync.isLoading)
                  Text(
                    '${itemsAsync.value?.length ?? 0} item',
                    style: tt.bodyMedium,
                  ),
              ],
            ),
          ),

          // ── List Barang ────────────────────────────────────────────────────
          Expanded(
            child: ref.watch(itemsProvider).when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: cs.primary)),
              error: (e, _) => _buildError(cs),
              data: (items) => items.isEmpty
                  ? _buildEmpty(cs)
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: items.length,
                      separatorBuilder: (ctx, i) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isLow = item.stock <= item.minStock;
                        return _ItemCard(
                            item: item, isLow: isLow, cs: cs, tt: tt);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text('Gagal memuat data barang', style: TextStyle(color: cs.error)),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () => ref.invalidate(itemsProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'Belum ada barang dalam sistem.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ── Item Card ────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final Item item;
  final bool isLow;
  final ColorScheme cs;
  final TextTheme tt;

  const _ItemCard({
    required this.item,
    required this.isLow,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Stok badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLow
                    ? const Color(0xFFFF8C00).withValues(alpha: 0.15)
                    : cs.primary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${item.stock}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isLow ? const Color(0xFFFF8C00) : cs.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info barang
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: tt.titleMedium?.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLow) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Stok Rendah',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFF8C00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Barcode: ${item.barcode}',
                    style: tt.bodyMedium?.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp ${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Min: ${item.minStock}',
                        style: tt.bodyMedium?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

