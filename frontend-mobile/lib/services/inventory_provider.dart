import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'notification_service.dart';

// ── FutureProvider: Daftar semua item ─────────────────────────────────────────
//
// Di-refresh ulang dengan ref.invalidate(itemsProvider) setelah transaksi.

final itemsProvider = FutureProvider<List<Item>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getItems();
});

// ── Scan Action State ─────────────────────────────────────────────────────────

sealed class ScanState {}

class ScanInitial extends ScanState {}

class ScanLoading extends ScanState {}

class ScanSuccess extends ScanState {
  final Item item;
  ScanSuccess(this.item);
}

class ScanNotFound extends ScanState {
  final String barcode;
  ScanNotFound(this.barcode);
}

class ScanError extends ScanState {
  final String message;
  ScanError(this.message);
}

// ── ScanActionNotifier ────────────────────────────────────────────────────────

class ScanActionNotifier extends StateNotifier<ScanState> {
  final ApiService _api;
  final Ref _ref;

  ScanActionNotifier(this._api, this._ref) : super(ScanInitial());

  /// Cari barang berdasarkan barcode via Inventory Service
  Future<void> scan(String barcode) async {
    if (state is ScanLoading) return; // cegah double-call
    state = ScanLoading();
    try {
      final item = await _api.getItemByBarcode(barcode);
      state = ScanSuccess(item);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('tidak ditemukan') || msg.contains('404')) {
        state = ScanNotFound(barcode);
      } else {
        state = ScanError(msg);
      }
    }
  }

  /// Barang Masuk — POST /transactions/in
  Future<void> transactionIn(String itemName, int itemId, int qty) async {
    final result = await _api.postTransactionIn(itemId, qty);
    _ref.invalidate(itemsProvider);
    state = ScanInitial();

    final stockText = result.newStock != null
        ? ' Stok sekarang ${result.newStock}.'
        : '';

    await NotificationService.showNotification(
      title: 'Stok bertambah',
      body: '$itemName ditambah $qty unit.$stockText',
    );
  }

  /// Barang Keluar — POST /transactions/out
  Future<void> transactionOut(
    String itemName,
    int itemId,
    int qty,
    String sessionId,
  ) async {
    final result = await _api.postTransactionOut(itemId, qty, sessionId);
    _ref.invalidate(itemsProvider);
    state = ScanInitial();

    final stockText = result.newStock != null
        ? ' Stok sekarang ${result.newStock}.'
        : '';

    await NotificationService.showNotification(
      title: 'Stok berkurang',
      body: '$itemName dikurangi $qty unit.$stockText',
    );

    if (result.alert) {
      await NotificationService.showNotification(
        title: 'Stok rendah',
        body:
            '$itemName mencapai batas minimum. Segera tambahkan stok agar tidak habis.',
      );
    }
  }

  void reset() => state = ScanInitial();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final scanActionProvider = StateNotifierProvider<ScanActionNotifier, ScanState>(
  (ref) {
    return ScanActionNotifier(ref.read(apiServiceProvider), ref);
  },
);

// ── FutureProvider: Daftar Kategori ──────────────────────────────────────────
//
// Dipanggil satu kali saat dashboard terbuka. Data kategori relatif statis
// sehingga tidak perlu di-invalidate setelah transaksi.

final categoriesProvider = FutureProvider((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getCategories();
});

// ── StateProvider: Kategori yang Dipilih ─────────────────────────────────────
//
// null  → tampilkan semua barang ("Semua Kategori")
// int   → filter berdasarkan categoryId yang dipilih

final selectedCategoryProvider = StateProvider<int?>((ref) => null);

// ── Computed Provider: Daftar Barang Ter-filter ───────────────────────────────
//
// Menggabungkan itemsProvider + selectedCategoryProvider.
// Filter dilakukan di sisi klien agar tidak perlu network request tambahan.

final filteredItemsProvider = Provider<AsyncValue<List<Item>>>((ref) {
  final itemsAsync = ref.watch(itemsProvider);
  final selectedCategoryId = ref.watch(selectedCategoryProvider);

  return itemsAsync.whenData((items) {
    if (selectedCategoryId == null) return items;
    return items
        .where((item) => item.categoryId == selectedCategoryId)
        .toList();
  });
});
