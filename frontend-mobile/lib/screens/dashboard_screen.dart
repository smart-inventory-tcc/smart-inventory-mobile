import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
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
    ref.invalidate(categoriesProvider);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(itemsProvider);
              ref.invalidate(categoriesProvider);
            },
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

          // ── Filter Kategori ───────────────────────────────────────────────
          _CategoryFilterBar(
            categoriesAsync: ref.watch(categoriesProvider),
            selectedId: ref.watch(selectedCategoryProvider),
            onSelect: (id) =>
                ref.read(selectedCategoryProvider.notifier).state = id,
            cs: cs,
            tt: tt,
          ),

          // ── Judul daftar barang ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daftar Barang', style: tt.titleLarge),
                Builder(builder: (context) {
                  final filtered = ref.watch(filteredItemsProvider);
                  final count = filtered.value?.length;
                  if (count == null) return const SizedBox.shrink();
                  return Text('$count item', style: tt.bodyMedium);
                }),
              ],
            ),
          ),

          // ── List Barang (menggunakan filteredItemsProvider) ────────────────
          Expanded(
            child: ref.watch(filteredItemsProvider).when(
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
            // Gambar produk (dengan fallback ikon jika kosong/error)
            _ProductImage(url: item.imageUrl, isLow: isLow, cs: cs),

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
                      // ── Stok saat ini + badge Stok Menipis ─────────────
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Stok: ${item.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isLow
                                  ? const Color(0xFFFF8C00)
                                  : cs.onSurface,
                            ),
                          ),
                          if (isLow) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: cs.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: cs.error.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                'Stok Menipis',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: cs.error,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ],
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

// ── Product Image thumbnail ───────────────────────────────────────────────────
class _ProductImage extends StatelessWidget {
  final String? url;
  final bool isLow;
  final ColorScheme cs;

  const _ProductImage({required this.url, required this.isLow, required this.cs});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isLow ? const Color(0xFFFF8C00) : cs.primary.withValues(alpha: 0.3);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
            color: cs.surfaceContainerHighest,
          ),
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final src = url?.trim() ?? '';
    if (src.isEmpty) return _fallback();

    return Image.network(
      src,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
              color: cs.primary,
            ),
          ),
        );
      },
      errorBuilder: (ctx, err, stack) => _fallback(),
    );
  }

  Widget _fallback() => Icon(
        Icons.image_not_supported_outlined,
        size: 26,
        color: cs.onSurface.withValues(alpha: 0.3),
      );
}

// ── Category Filter Bar ───────────────────────────────────────────────────────
//
// Horizontal scrollable chip list.
// Menampilkan "Semua" + nama tiap kategori dari categoriesProvider.
// Chip yang aktif menggunakan warna primary dari tema.

class _CategoryFilterBar extends StatelessWidget {
  final AsyncValue<List<Category>> categoriesAsync;
  final int? selectedId;
  final ValueChanged<int?> onSelect;
  final ColorScheme cs;
  final TextTheme tt;

  const _CategoryFilterBar({
    required this.categoriesAsync,
    required this.selectedId,
    required this.onSelect,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    // Saat loading kategori, tampilkan shimmer placeholder minimal
    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      // Jika kategori gagal dimuat, sembunyikan bar (item list tetap muncul)
      error: (_, err) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 44,
          color: cs.surface,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            children: [
              // Chip "Semua Kategori"
              _buildChip(
                label: 'Semua',
                isSelected: selectedId == null,
                onTap: () => onSelect(null),
              ),
              const SizedBox(width: 8),
              // Chip per kategori
              ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildChip(
                      label: cat.categoryName,
                      isSelected: selectedId == cat.id,
                      onTap: () => onSelect(cat.id),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline,
            width: isSelected ? 0 : 0.9,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? cs.onPrimary : cs.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
