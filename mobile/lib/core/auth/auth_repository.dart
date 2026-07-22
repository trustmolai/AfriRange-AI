import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/env.dart';
import 'models/user_model.dart';

class AuthRepository {
  final _storage = const FlutterSecureStorage();
  final _client = http.Client();

  static const String _tokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _userKey = 'cached_user_profile';

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<UserModel?> getCachedUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> checkAuthStatus() async {
    final token = await getAccessToken();
    if (token == null) return null;
    
    // Return cached user immediately for offline support
    return await getCachedUser();
  }

  Future<UserModel> login(String email, String password) async {
    final res = await _client.post(
      Uri.parse('${EnvConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      await _storage.write(key: _tokenKey, value: data['accessToken']);
      await _storage.write(key: _refreshTokenKey, value: data['refreshToken']);
      final user = UserModel.fromJson(data['user']);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      return user;
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  Future<UserModel> register(String email, String password, String fullName) async {
    final res = await _client.post(
      Uri.parse('${EnvConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'fullName': fullName}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 201) {
      await _storage.write(key: _tokenKey, value: data['accessToken']);
      await _storage.write(key: _refreshTokenKey, value: data['refreshToken']);
      final user = UserModel.fromJson(data['user']);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      return user;
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    final token = await getAccessToken();
    if (token != null) {
      try {
        await _client.post(
          Uri.parse('${EnvConfig.baseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {}
    }
    await _storage.deleteAll();
  }

  Future<void> deleteAccount() async {
    final token = await getAccessToken();
    if (token != null) {
      final res = await _client.delete(
        Uri.parse('${EnvConfig.baseUrl}/auth/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode != 200) {
        final data = jsonDecode(res.body);
        throw Exception(data['message'] ?? 'Account deletion failed');
      }
    }
    await _storage.deleteAll();
  }
}
