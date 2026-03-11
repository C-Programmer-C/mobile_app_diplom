import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/models/product.dart';

class AuthTokens {
  final String accessToken;
  final String? userName;

  AuthTokens({
    required this.accessToken,
    this.userName,
  });
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static String? _accessToken;

  static void setTokens({
    String? accessToken,
  }) {
    _accessToken = accessToken;
  }

  static Map<String, String> _buildAuthHeaders() {
    final headers = <String, String>{};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  static Future<void> _refreshTokensIfNeeded(http.Response response) async {
    if (response.statusCode != 401) return;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['detail'] == 'token expired') {
        await _refreshTokens();
      }
    } catch (_) {
      // игнорируем проблемы с парсингом тела
    }
  }

  static Future<void> _refreshTokens() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      _accessToken = null;
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'access_token': _accessToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccess = data['access_token'] as String?;

      if (newAccess != null) {
        _accessToken = newAccess;
      }
    } else {
      _accessToken = null;
    }
  }

  static Future<http.Response> _authorizedGet(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    var response = await http.get(uri, headers: _buildAuthHeaders());
    if (response.statusCode == 401) {
      await _refreshTokensIfNeeded(response);
      response = await http.get(uri, headers: _buildAuthHeaders());
    }
    return response;
  }

  static Future<http.Response> _authorizedPost(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final mergedHeaders = {
      ..._buildAuthHeaders(),
      if (headers != null) ...headers,
    };
    var response = await http.post(uri, headers: mergedHeaders, body: body);
    if (response.statusCode == 401) {
      await _refreshTokensIfNeeded(response);
      response = await http.post(uri, headers: mergedHeaders, body: body);
    }
    return response;
  }

  static Future<List<Product>> fetchProducts() async {
    final response = await _authorizedGet('/products/');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final products =
          data.map((json) => Product.fromJson(json)).toList().cast<Product>();
      // лог в консоль
      // ignore: avoid_print
      print('Товары успешно получены: ${products.length}');
      return products;
    } else {
      throw Exception('Ошибка загрузки товаров');
    }
  }

  static Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    if (response.statusCode == 201) {
      return;
    }

    if (response.statusCode == 409) {
      throw Exception('Пользователь с таким email уже существует');
    }

    throw Exception('Ошибка регистрации (${response.statusCode})');
  }

  static Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final userName = data['name'] as String?;

      if (accessToken == null) {
        throw Exception('Некорректный ответ сервера');
      }

      return AuthTokens(
        accessToken: accessToken,
        userName: userName,
      );
    }

    if (response.statusCode == 400) {
      throw Exception('Неверный email или пароль');
    }

    throw Exception('Ошибка входа (${response.statusCode})');
  }

  static Future<void> addToCart(int productId) async {
    final response = await _authorizedPost(
      '/cart/add',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'product_id': productId}),
    );

    if (response.statusCode == 200) {
      // ignore: avoid_print
      print('Товар $productId успешно добавлен в корзину');
      return;
    }
    throw Exception('Ошибка добавления в корзину');
  }

  static Future<bool> toggleFavorite(int productId) async {
    final response = await _authorizedPost(
      '/favorites/toggle',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'product_id': productId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final isFavorite = data['is_favorite'] as bool? ?? false;
      // ignore: avoid_print
      print(
        'Товар $productId был добавлен/убран из избранного успешно. is_favorite=$isFavorite',
      );
      return isFavorite;
    }

    if (response.statusCode == 401) {
      // неавторизованный пользователь пытается изменить избранное
      throw Exception('Для добавления в избранное необходимо войти в профиль');
    }

    throw Exception(
      'Ошибка изменения избранного (${response.statusCode})',
    );
  }

  static Future<List<int>> fetchFavoriteIds() async {
    final response = await _authorizedGet('/favorites/');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => e as int).toList();
      }
      throw Exception('Некорректный ответ сервера (избранное)');
    }

    if (response.statusCode == 401) {
      throw Exception('Для работы избранного необходимо войти в профиль');
    }

    throw Exception(
      'Ошибка загрузки избранного (${response.statusCode})',
    );
  }

  static Future<List<Product>> fetchFavoriteProducts() async {
    final favoritesIds = await fetchFavoriteIds();
    if (favoritesIds.isEmpty) {
      return [];
    }
    final allProducts = await fetchProducts();
    return allProducts
        .where((p) => favoritesIds.contains(p.id))
        .toList(growable: false);
  }
}

