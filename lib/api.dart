import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/models/cart_item.dart';
import 'package:mobile_app/models/review.dart';

class AuthTokens {
  final String accessToken;
  final String? userName;

  AuthTokens({required this.accessToken, this.userName});
}

class ApiService {
  static const String baseUrl = 'https://cheekily-coherent-newfoundland.cloudpub.ru:8000';

  static String? _accessToken;

  static bool get isAuthorized =>
      _accessToken != null && _accessToken!.trim().isNotEmpty;

  static void setTokens({String? accessToken}) {
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

  static Future<http.Response> _publicGet(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    return await http.get(uri);
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

  static Future<http.Response> _authorizedPatch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final mergedHeaders = {
      ..._buildAuthHeaders(),
      if (headers != null) ...headers,
    };
    var response = await http.patch(uri, headers: mergedHeaders, body: body);
    if (response.statusCode == 401) {
      await _refreshTokensIfNeeded(response);
      response = await http.patch(uri, headers: mergedHeaders, body: body);
    }
    return response;
  }

  static Future<List<Product>> fetchProducts() async {
    final response = await _publicGet('/products/public');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final products = data
          .map((json) {
            if (json is Map<String, dynamic>) {
              final rawUrl = json['image_url'];
              if (rawUrl is String && rawUrl.isNotEmpty) {
                json = Map<String, dynamic>.from(json);
                json['image_url'] = _normalizeImageUrl(rawUrl);
              }
            }
            return Product.fromJson(json);
          })
          .toList()
          .cast<Product>();
      // лог в консоль
      // ignore: avoid_print
      print('Товары успешно получены: ${products.length}');
      return products;
    } else {
      throw Exception('Ошибка загрузки товаров');
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    final response = await _publicGet('/products/search?q=$query');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final products = data
          .map((json) {
            if (json is Map<String, dynamic>) {
              final rawUrl = json['image_url'];
              if (rawUrl is String && rawUrl.isNotEmpty) {
                json = Map<String, dynamic>.from(json);
                json['image_url'] = _normalizeImageUrl(rawUrl);
              }
            }
            return Product.fromJson(json);
          })
          .toList()
          .cast<Product>();
      return products;
    } else {
      throw Exception('Ошибка поиска товаров');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await _publicGet('/products/categories');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((raw) {
        final e = Map<String, dynamic>.from(raw as Map);
        if (e['id'] is num) {
          e['id'] = (e['id'] as num).toInt();
        }
        return e;
      }).toList();
    } else {
      throw Exception('Ошибка получения категорий');
    }
  }

  static Future<List<Product>> fetchFilteredProducts({
    String? sortBy,
    bool? popular,
    bool? highRating,
    bool? bigDiscount,
    bool? isNew,
    int? categoryId,
  }) async {
    final queryParams = <String, String>{};

    if (sortBy != null && sortBy.isNotEmpty) queryParams['sort'] = sortBy;
    if (popular == true) queryParams['popular'] = 'true';
    if (highRating == true) queryParams['high_rating'] = 'true';
    if (bigDiscount == true) queryParams['big_discount'] = 'true';
    if (isNew == true) queryParams['is_new'] = 'true';
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final response = await _publicGet('/products/filter$queryString');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final products = data
          .map((json) {
            if (json is Map<String, dynamic>) {
              final rawUrl = json['image_url'];
              if (rawUrl is String && rawUrl.isNotEmpty) {
                json = Map<String, dynamic>.from(json);
                json['image_url'] = _normalizeImageUrl(rawUrl);
              }
            }
            return Product.fromJson(json);
          })
          .toList()
          .cast<Product>();
      return products;
    } else {
      throw Exception('Ошибка фильтрации товаров (${response.statusCode})');
    }
  }

  static Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
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
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final userName = data['name'] as String?;

      if (accessToken == null) {
        throw Exception('Некорректный ответ сервера');
      }

      return AuthTokens(accessToken: accessToken, userName: userName);
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
      body: jsonEncode({'product_id': productId, 'quantity': 1}),
    );

    if (response.statusCode == 200) {
      // ignore: avoid_print
      print('Товар $productId успешно добавлен в корзину');
      return;
    }
    if (response.statusCode == 401) {
      throw Exception('Для работы корзины необходимо войти в профиль');
    }
    String? detail;
    try {
      final body = jsonDecode(response.body);
      detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;
    } catch (_) {
      detail = response.body;
    }
    throw Exception(
      detail ?? 'Ошибка добавления в корзину (${response.statusCode})',
    );
  }

  static Future<List<CartItem>> fetchCartItems() async {
    final response = await _authorizedGet('/cart/');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => CartItem.fromJson(json)).toList();
    }

    if (response.statusCode == 401) {
      return [];
    }

    throw Exception('Ошибка загрузки корзины (${response.statusCode})');
  }

  static Future<void> setCartItemQuantity({
    required int productId,
    required int quantity,
  }) async {
    final response = await _authorizedPost(
      '/cart/set_quantity',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    if (response.statusCode == 200) return;
    if (response.statusCode == 401) {
      throw Exception('Для работы корзины необходимо войти в профиль');
    }
    String? detail;
    try {
      final body = jsonDecode(response.body);
      detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;
    } catch (_) {
      detail = response.body;
    }
    throw Exception(
      detail ?? 'Ошибка обновления корзины (${response.statusCode})',
    );
  }

  static Future<void> removeFromCart({required int productId}) async {
    final response = await _authorizedPost(
      '/cart/remove',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'product_id': productId, 'quantity': 1}),
    );
    if (response.statusCode == 200) return;
    if (response.statusCode == 401) {
      throw Exception('Для работы корзины необходимо войти в профиль');
    }
    String? detail;
    try {
      final body = jsonDecode(response.body);
      detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;
    } catch (_) {
      detail = response.body;
    }
    throw Exception(
      detail ?? 'Ошибка удаления из корзины (${response.statusCode})',
    );
  }

  static Future<void> clearCart() async {
    final response = await _authorizedPost(
      '/cart/clear',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    if (response.statusCode == 200) return;
    if (response.statusCode == 401) {
      throw Exception('Для работы корзины необходимо войти в профиль');
    }
    String? detail;
    try {
      final body = jsonDecode(response.body);
      detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;
    } catch (_) {
      detail = response.body;
    }
    throw Exception(
      detail ?? 'Ошибка очистки корзины (${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> checkoutOrder({
    required int deliveryTypeId,
    required String shippingAddress,
    required String phone,
    int? pickupPointId,
    int? cityId,
    List<int>? productIds,
    required String paymentMethod,
    String? cardPan,
  }) async {
    final response = await _authorizedPost(
      '/orders/checkout',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'delivery_type_id': deliveryTypeId,
        'city_id': cityId,
        'shipping_address': shippingAddress,
        'phone': phone,
        'pickup_point_id': pickupPointId,
        'product_ids': productIds,
        'payment_method': paymentMethod,
        if (paymentMethod == 'card' && cardPan != null && cardPan.isNotEmpty)
          'card_pan': cardPan,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    }

    if (response.statusCode == 400) {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Ошибка оформления заказа');
    }

    if (response.statusCode == 401) {
      throw Exception('Для оформления заказа необходимо войти в профиль');
    }

    throw Exception('Ошибка оформления заказа (${response.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> fetchDeliveryTypes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/meta/delivery_types'),
      headers: _buildAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (response.statusCode == 401) {
      _accessToken = null;
      return [];
    }
    throw Exception('Ошибка получения delivery types (${response.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> fetchCities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/meta/cities'),
      headers: _buildAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (response.statusCode == 401) {
      _accessToken = null;
      return [];
    }
    throw Exception('Ошибка получения городов (${response.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> fetchPickupPoints({
    required int cityId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/meta/pickup_points?city_id=$cityId'),
      headers: _buildAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (response.statusCode == 401) {
      _accessToken = null;
      return [];
    }
    throw Exception('Ошибка получения ПВЗ (${response.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> fetchMyOrders() async {
    final response = await _authorizedGet('/orders/me');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (response.statusCode == 401) {
      _accessToken = null;
      return [];
    }
    throw Exception('Ошибка получения заказов (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> fetchOrderDetail(int orderId) async {
    final response = await _authorizedGet('/orders/$orderId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      _accessToken = null;
      return {};
    }
    throw Exception('Ошибка получения заказа (${response.statusCode})');
  }

  static Future<void> cancelOrder(int orderId) async {
    final response = await _authorizedPost('/orders/$orderId/cancel');
    if (response.statusCode == 200) {
      return;
    }
    if (response.statusCode == 400 || response.statusCode == 403) {
      final body = jsonDecode(response.body);
      final detail = body is Map<String, dynamic> ? body['detail'] : body;
      if (detail is String) {
        throw Exception(detail);
      }
      throw Exception(detail?.toString() ?? 'Не удалось отменить заказ');
    }
    if (response.statusCode == 401) {
      _accessToken = null;
      throw Exception('Войдите в профиль');
    }
    throw Exception('Ошибка отмены заказа (${response.statusCode})');
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

    throw Exception('Ошибка изменения избранного (${response.statusCode})');
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
      _accessToken = null;
      return [];
    }

    throw Exception('Ошибка загрузки избранного (${response.statusCode})');
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

  static Future<Product> fetchProductDetails(int productId) async {
    final response = await _authorizedGet('/products/$productId/details');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      // Нормализовать URL изображений
      if (json['image_url'] is String) {
        json['image_url'] = _normalizeImageUrl(json['image_url']);
      }
      if (json['fabricator'] is Map<String, dynamic>) {
        final fabricator = json['fabricator'] as Map<String, dynamic>;
        if (fabricator['image_url'] is String) {
          fabricator['image_url'] = _normalizeImageUrl(fabricator['image_url']);
        }
      }
      return Product.fromJson(json);
    }

    throw Exception('Ошибка загрузки деталей товара (${response.statusCode})');
  }

  static Future<List<Review>> fetchProductReviews(
    int productId, {
    int limit = 3,
  }) async {
    final response = await _authorizedGet(
      '/products/$productId/reviews?limit=$limit',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Review.fromJson(json)).toList();
    }

    throw Exception('Ошибка загрузки отзывов (${response.statusCode})');
  }

  static Future<List<Review>> fetchAllProductReviews(int productId) async {
    final response = await _authorizedGet(
      '/products/$productId/reviews?limit=0',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Review.fromJson(json)).toList();
    }

    throw Exception('Ошибка загрузки отзывов (${response.statusCode})');
  }

  static Future<Review> createProductReview({
    required int productId,
    required double rating,
    String? comment,
  }) async {
    final response = await _authorizedPost(
      '/products/$productId/reviews',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Review.fromJson(data);
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Только авторизованные пользователи могут оставлять отзывы',
      );
    }

    String? detail;
    try {
      final body = jsonDecode(response.body);
      detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;
    } catch (_) {
      detail = response.body;
    }
    throw Exception(
      detail ?? 'Ошибка отправки отзыва (${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> fetchCurrentUser() async {
    final response = await _authorizedGet('/auth/me');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception(
        'Для загрузки профиля необходимо войти в профиль',
      );
    }
    throw Exception('Профиль (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> updateCurrentUser({
    String? name,
    String? phone,
  }) async {
    final response = await _authorizedPatch(
      '/auth/me',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': ?name,
        'phone': ?phone,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('Нужна авторизация');
    }
    String? detail;
    try {
      final body = jsonDecode(response.body);
      detail = body is Map<String, dynamic> ? body['detail']?.toString() : null;
    } catch (_) {
      detail = response.body;
    }
    throw Exception(detail ?? 'Ошибка сохранения (${response.statusCode})');
  }

  static Future<List<Product>> fetchSimilarProducts(
    int productId, {
    int limit = 4,
  }) async {
    final response = await _authorizedGet(
      '/products/$productId/similar?limit=$limit',
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final products = data
          .map((json) {
            if (json is Map<String, dynamic>) {
              final rawUrl = json['image_url'];
              if (rawUrl is String && rawUrl.isNotEmpty) {
                json = Map<String, dynamic>.from(json);
                json['image_url'] = _normalizeImageUrl(rawUrl);
              }
            }
            return Product.fromJson(json);
          })
          .toList()
          .cast<Product>();
      return products;
    }

    throw Exception('Ошибка загрузки похожих товаров (${response.statusCode})');
  }
}

String _normalizeImageUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return trimmed;

  // Если сервер отдаёт относительный путь.
  if (trimmed.startsWith('/')) {
    return '${ApiService.baseUrl}$trimmed';
  }

  // Если в БД/ответе захардкожен localhost/127.0.0.1 (на эмуляторе это не работает).
  if (trimmed.startsWith('http://127.0.0.1:8000')) {
    return trimmed.replaceFirst('http://127.0.0.1:8000', ApiService.baseUrl);
  }
  if (trimmed.startsWith('http://localhost:8000')) {
    return trimmed.replaceFirst('http://localhost:8000', ApiService.baseUrl);
  }

  return trimmed;
}
