import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/item.dart';
import '../models/user.dart';

// ── Base URLs ────────────────────────────────────────────────────────────────
const _identityBaseUrl =
    'https://identity-service-805566040091.asia-southeast2.run.app';

const _inventoryBaseUrl =
    'https://inventory-service-805566040091.asia-southeast2.run.app';

// Ganti dengan IP WiFi laptop saat testing di HP fisik
const _localBaseUrl = 'http://10.200.121.211:3000';

const _tokenKey = 'smart_inv_jwt';

// ── ApiService ───────────────────────────────────────────────────────────────
class ApiService {
  final FlutterSecureStorage _storage;
  late final Dio _identityDio;
  late final Dio _inventoryDio; // Inventory Service (cloud)
  late final Dio _localDio;

  ApiService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    _identityDio = _buildIdentityDio();
    _inventoryDio = _buildInventoryDio();
    _localDio = Dio(
      BaseOptions(
        baseUrl: _localBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  // ── Identity Dio dengan QueuedInterceptorsWrapper ─────────────────────────

  Dio _buildIdentityDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _identityBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // QueuedInterceptorsWrapper agar request antre saat token sedang dibaca
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) => handler.next(e),
      ),
    );

    return dio;
  }

  // ── Token Management ──────────────────────────────────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  

  // ── Auth — Identity Service ───────────────────────────────────────────────

  /// Login — Response: { data: { token, user: { id, username, role } } }
  /// Returns token string. Throws String error message on failure.
  Future<String> login(String username, String password) async {
    try {
      final res = await _identityDio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      final token =
          (res.data as Map<String, dynamic>)['data']?['token'] as String?;
      if (token == null) throw 'Token tidak ditemukan dalam response';

      await saveToken(token);
      return token;
    } catch (e) {
      if (e is DioException) {
        throw (e.response?.data as Map?)?['message'] ?? 'Login gagal';
      }
      rethrow;
    }
  }

  /// Register — Response: { data: { id, username, role } }
  /// Throws String error message on failure.
  Future<void> register(String username, String password, String role) async {
    try {
      await _identityDio.post(
        '/auth/register',
        data: {'username': username, 'password': password, 'role': role},
      );
    } catch (e) {
      if (e is DioException) {
        throw (e.response?.data as Map?)?['message'] ?? 'Pendaftaran gagal';
      }
      rethrow;
    }
  }

  /// Get Profile — Response: { data: { id, username, role, createdAt } }
  /// Throws String error message on failure.
  Future<User> getProfile() async {
    try {
      final res = await _identityDio.get('/auth/profile');
      return User.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException) {
        throw (e.response?.data as Map?)?['message'] ?? 'Gagal memuat profil';
      }
      rethrow;
    }
  }

  // ── Suppliers — Identity Service ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final res = await _identityDio.get('/suppliers');
      return (res.data['data'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (e is DioException) {
        throw (e.response?.data as Map?)?['message'] ?? 'Gagal memuat supplier';
      }
      rethrow;
    }
  }

  // ── Inventory Dio — sama dengan Identity, beda base URL ──────────────────

  Dio _buildInventoryDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _inventoryBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    // Reuse interceptor yang sama: auto-inject JWT
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) => handler.next(e),
      ),
    );
    return dio;
  }

  // ── Items — Inventory Service ─────────────────────────────────────────────

  /// GET /items → { success, data: [ Item ] }
  /// Throws String on failure.
  Future<List<Item>> getItems() async {
    try {
      final res = await _inventoryDio.get('/items');
      final list = (res.data['data'] as List)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      if (e is DioException) {
        throw (e.response?.data as Map?)?['message'] ?? 'Gagal memuat barang';
      }
      rethrow;
    }
  }

  /// GET /items/barcode/{barcode} → { success, data: Item }
  /// Throws String "Barang tidak ditemukan" khusus untuk 404.
  Future<Item> getItemByBarcode(String barcode) async {
    try {
      final res = await _inventoryDio.get('/items/barcode/$barcode');
      return Item.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          throw 'Barang tidak ditemukan';
        }
        throw (e.response?.data as Map?)?['message'] ?? 'Gagal memuat barang';
      }
      rethrow;
    }
  }

  /// POST /transactions/in → Body: { itemId, quantity }
  Future<StockTransactionResponse> postTransactionIn(
    int itemId,
    int qty,
  ) async {
    try {
      final res = await _inventoryDio.post(
        '/transactions/in',
        data: {'itemId': itemId, 'quantity': qty},
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      return StockTransactionResponse(
        newStock: (data['currentStock'] as num?)?.toInt(),
        alert: (data['lowStockTriggered'] as bool?) ?? false,
      );
    } catch (e) {
      if (e is DioException) {
        throw (e.response?.data as Map?)?['message'] ?? 'Transaksi masuk gagal';
      }
      rethrow;
    }
  }

  /// POST /transactions/out → Body: { itemId, quantity, scanSessionId }
  Future<StockTransactionResponse> postTransactionOut(
    int itemId,
    int qty,
    String sessionId,
  ) async {
    try {
      final res = await _inventoryDio.post(
        '/transactions/out',
        data: {'itemId': itemId, 'quantity': qty, 'scanSessionId': sessionId},
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      return StockTransactionResponse(
        newStock: (data['currentStock'] as num?)?.toInt(),
        alert: (data['lowStockTriggered'] as bool?) ?? false,
      );
    } catch (e) {
      if (e is DioException) {
        throw (e.response?.data as Map?)?['message'] ??
            'Transaksi keluar gagal';
      }
      rethrow;
    }
  }

  // ── Items — Local Backend ─────────────────────────────────────────────────

  Future<ApiResult<List<Item>>> fetchItems() async {
    try {
      await _syncLocalToken();
      final res = await _localDio.get('/items');
      final list = (res.data as List)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } on DioException catch (e) {
      return ApiResult.error(
        (e.response?.data as Map?)?['error']?.toString() ??
            'Gagal memuat barang',
      );
    }
  }

  Future<ApiResult<Item>> fetchItemByCode(String code) async {
    try {
      await _syncLocalToken();
      final res = await _localDio.get('/items/$code');
      return ApiResult.success(Item.fromJson(res.data as Map<String, dynamic>));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return ApiResult.error('Barang tidak ditemukan');
      }
      return ApiResult.error(
        (e.response?.data as Map?)?['error']?.toString() ??
            'Gagal memuat barang',
      );
    }
  }

  Future<ApiResult<String>> recordTransaction(
    String type,
    int itemId,
    int quantity,
  ) async {
    try {
      await _syncLocalToken();
      final res = await _localDio.post(
        '/transactions/$type',
        data: {'item_id': itemId, 'quantity': quantity},
      );
      return ApiResult.success(
        (res.data as Map<String, dynamic>)['message'] as String,
      );
    } on DioException catch (e) {
      return ApiResult.error(
        (e.response?.data as Map?)?['error']?.toString() ?? 'Transaksi gagal',
      );
    }
  }

  Future<void> _syncLocalToken() async {
    final token = await readToken();
    if (token != null && token.isNotEmpty) {
      _localDio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}

class StockTransactionResponse {
  final int? newStock;
  final bool alert;

  StockTransactionResponse({this.newStock, required this.alert});
}

// ── Result Wrapper (untuk local backend) ─────────────────────────────────────

class ApiResult<T> {
  final T? data;
  final String? error;

  ApiResult.success(this.data) : error = null;
  ApiResult.error(this.error) : data = null;

  bool get isSuccess => error == null;
}
