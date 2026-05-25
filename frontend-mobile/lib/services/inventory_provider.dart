import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/item.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'notification_service.dart';
import 'activity_logger.dart';

// ── FutureProvider: Daftar semua item ─────────────────────────────
final itemsProvider = FutureProvider<List<Item>>((ref) async {
  final api = ref.watch(apiServiceProvider);
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
      
      final userState = _ref.read(authProvider).value;
      if (userState != null) {
        ActivityLogger.logActivity(
          userId: userState.id,
          username: userState.username,
          role: userState.role,
          action: 'SCAN_BARCODE',
          metadata: {'barcode': barcode, 'itemName': item.name},
        );
      }
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
    state = ScanInitial();

    final userState = _ref.read(authProvider).value;
    if (userState != null) {
      ActivityLogger.logActivity(
        userId: userState.id,
        username: userState.username,
        role: userState.role,
        action: 'TRANSACTION_IN',
        metadata: {'itemId': itemId, 'qty': qty},
      );
    }

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
    final userState = _ref.read(authProvider).value;
    
    // Log ke temp_scan_sessions sebelum API call
    if (userState != null) {
      await ActivityLogger.logTempScanSession(
        sessionId: sessionId,
        userId: userState.id,
        barcode: itemName, // fallback info
        itemId: itemId,
        quantity: qty,
        lastAction: 'OUT',
        status: 'PROCESSING',
      );
    }

    final result = await _api.postTransactionOut(itemId, qty, sessionId);
    
    // Update temp_scan_sessions jadi PROCESSED
    if (userState != null) {
      await ActivityLogger.logTempScanSession(
        sessionId: sessionId,
        userId: userState.id,
        barcode: itemName,
        itemId: itemId,
        quantity: qty,
        lastAction: 'OUT',
        status: 'PROCESSED',
      );
      
      ActivityLogger.logActivity(
        userId: userState.id,
        username: userState.username,
        role: userState.role,
        action: 'TRANSACTION_OUT',
        metadata: {'itemId': itemId, 'qty': qty, 'sessionId': sessionId},
      );
    }

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

// ── FutureProvider: Daftar Kategori ───────────────────────────────────────────
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.watch(apiServiceProvider);
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

// ── StreamProvider: System Config (Real-time) ───────────────────────────────

final systemConfigProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('system_config')
      .snapshots()
      .map((snapshot) {
        final Map<String, dynamic> config = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['config_key'] != null) {
            config[data['config_key'] as String] = data['config_value'];
          }
        }
        return config;
      });
});

// ── StreamProvider: Notifications (Real-time) ───────────────────────────────

final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final stream = FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // Listen explicitly to docChanges to trigger Push Notifications for NEW documents only
  final sub = stream.listen((snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data();
        if (data != null && data['isRead'] == false) {
          final title = data['level'] == 'danger' ? 'Peringatan Kritis!' : 'Notifikasi Sistem';
          final message = data['message'] ?? 'Ada notifikasi baru.';
          
          NotificationService.showNotification(
            title: title,
            body: message.toString(),
          );
        }
      }
    }
  });

  ref.onDispose(() {
    sub.cancel();
  });

  return stream.map((snapshot) => snapshot.docs.map((doc) => {
    'id': doc.id,
    ...doc.data(),
  }).toList());
});
