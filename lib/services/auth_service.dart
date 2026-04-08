import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/api.dart';

class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _userNameKey = 'user_name';

  static String? currentUserName;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    currentUserName = prefs.getString(_userNameKey);
    ApiService.setTokens(
      accessToken: accessToken,
    );
  }

  static Future<void> saveTokens({
    required String accessToken,
    String? userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (userName != null) {
      await prefs.setString(_userNameKey, userName);
      currentUserName = userName;
    }
    ApiService.setTokens(
      accessToken: accessToken,
    );
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_userNameKey);
    currentUserName = null;
    ApiService.setTokens(accessToken: null);
  }

  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    currentUserName = name;
  }
}

