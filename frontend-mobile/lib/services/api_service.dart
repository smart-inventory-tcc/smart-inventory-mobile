import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import '../models/user.dart';

class ApiService {
  // static const baseUrl = 'http://192.168.0.103:3000'; //ini hp
  static const baseUrl = 'http://localhost:3000'; //ini web laptop
  String? token;

  Map<String, String> get headers {
    final base = {'Content-Type': 'application/json'};
    if (token != null) {
      base['Authorization'] = 'Bearer $token';
    }
    return base;
  }

  void setToken(String value) {
    token = value;
  }

  Future<LoginResult> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LoginResult.success(User.fromJson(data['user']), data['token']);
    }
    return LoginResult.error(
      jsonDecode(response.body)['error'] ?? 'Login failed',
    );
  }

  Future<ApiResult<Map<String, dynamic>>> register(
    String username,
    String password,
    String role,
    String? name,
    String? email,
  ) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResult.success(data);
    }
    final err = response.body.isNotEmpty
        ? jsonDecode(response.body)['error'] ?? 'Registration failed'
        : 'Registration failed';
    return ApiResult.error(err);
  }

  Future<ApiResult<List<Item>>> fetchItems() async {
    final uri = Uri.parse('$baseUrl/items');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return ApiResult.success(
        data.map((item) => Item.fromJson(item)).toList(),
      );
    }
    return ApiResult.error('Failed to get items');
  }

  Future<ApiResult<Item>> fetchItemByCode(String code) async {
    final uri = Uri.parse('$baseUrl/items/$code');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return ApiResult.success(Item.fromJson(jsonDecode(response.body)));
    }
    return ApiResult.error(
      jsonDecode(response.body)['error'] ?? 'Item not found',
    );
  }

  Future<ApiResult<String>> recordTransaction(
    String type,
    int itemId,
    int quantity,
  ) async {
    final uri = Uri.parse('$baseUrl/transactions/$type');
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'item_id': itemId, 'quantity': quantity}),
    );
    if (response.statusCode == 200) {
      return ApiResult.success(jsonDecode(response.body)['message'] as String);
    }
    return ApiResult.error(
      jsonDecode(response.body)['error'] ?? 'Transaction failed',
    );
  }
}

class ApiResult<T> {
  final T? data;
  final String? error;

  ApiResult.success(this.data) : error = null;
  ApiResult.error(this.error) : data = null;

  bool get isSuccess => error == null;
}

class LoginResult {
  final User? user;
  final String? token;
  final String? error;

  LoginResult.success(this.user, this.token) : error = null;
  LoginResult.error(this.error) : user = null, token = null;
  bool get isSuccess => error == null;
}
