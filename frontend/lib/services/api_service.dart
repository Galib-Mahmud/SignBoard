import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user';

  String? _authToken;
  UserModel? _currentUser;

  String? get authToken => _authToken;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  static const String _customBaseUrlKey = 'custom_base_url';
  String? _customBaseUrl;

  static const String defaultLiveUrl = 'https://signboard-backend.onrender.com/api';

  // Base URL auto-resolution:
  // Defaults to live production Render cloud backend, and ignores stale localhost/emulator entries
  String get baseUrl {
    if (_customBaseUrl != null &&
        _customBaseUrl!.isNotEmpty &&
        !_customBaseUrl!.contains('10.0.2.2') &&
        !_customBaseUrl!.contains('127.0.0.1')) {
      return _customBaseUrl!;
    }
    return defaultLiveUrl;
  }

  Future<void> setCustomBaseUrl(String url) async {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customBaseUrlKey, _customBaseUrl!);
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Token $_authToken';
    }
    return headers;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    final savedUrl = prefs.getString(_customBaseUrlKey);
    if (savedUrl != null &&
        !savedUrl.contains('10.0.2.2') &&
        !savedUrl.contains('127.0.0.1') &&
        savedUrl.startsWith('https://')) {
      _customBaseUrl = savedUrl;
    } else {
      _customBaseUrl = defaultLiveUrl;
      await prefs.setString(_customBaseUrlKey, defaultLiveUrl);
    }
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
  }


  Future<UserModel> googleSignIn({
    String? email,
    String? name,
    String? googleId,
    String? avatarUrl,
  }) async {
    final url = Uri.parse('$baseUrl/auth/google/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email ?? 'maya.j@example.com',
        'name': name ?? 'Maya Johnson',
        'google_id': googleId ?? 'google_signboard_demo',
        'avatar_url': avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['token'];
      _currentUser = UserModel.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _authToken!);
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      return _currentUser!;
    } else {
      throw Exception('Failed to sign in: ${response.body}');
    }
  }

  Future<void> logout() async {
    _authToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse('$baseUrl/categories/');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<Map<String, dynamic>> getPosts({
    String? category,
    String? search,
    double? latitude,
    double? longitude,
    String sort = 'recent', // 'recent' or 'distance'
    double? maxDistance,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'sort': sort,
    };
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }
    if (maxDistance != null && maxDistance > 0) {
      queryParams['max_distance'] = maxDistance.toString();
    }

    final url = Uri.parse('$baseUrl/posts/').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      final posts = results.map((j) => PostModel.fromJson(j)).toList();
      return {
        'count': data['count'] ?? posts.length,
        'next': data['next'],
        'previous': data['previous'],
        'posts': posts,
      };
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  Future<PostModel> createPost({
    required String categoryId,
    required String title,
    required String description,
    required String contactWhatsapp,
    required Map<String, dynamic> structuredData,
    required double latitude,
    required double longitude,
    required String address,
    required String city,
  }) async {
    final url = Uri.parse('$baseUrl/posts/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'category': categoryId,
        'title': title,
        'description': description,
        'contact_whatsapp': contactWhatsapp,
        'structured_data': structuredData,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
      }),
    );

    if (response.statusCode == 201) {
      return PostModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create post: ${response.body}');
    }
  }

  Future<bool> toggleSavePost(String postId) async {
    final url = Uri.parse('$baseUrl/posts/$postId/save/');
    final response = await http.post(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['saved'] == true;
    } else {
      throw Exception('Failed to toggle save');
    }
  }

  Future<List<PostModel>> getSavedPosts({int page = 1}) async {
    final url = Uri.parse('$baseUrl/posts/saved/?page=$page');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      return results.map((item) => PostModel.fromJson(item['post'])).toList();
    } else {
      throw Exception('Failed to load saved posts');
    }
  }

  Future<List<PostModel>> getMyPosts({int page = 1}) async {
    final url = Uri.parse('$baseUrl/posts/my/?page=$page');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      return results.map((item) => PostModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load user posts');
    }
  }

  Future<bool> deletePost(String postId) async {
    final url = Uri.parse('$baseUrl/posts/$postId/');
    final response = await http.delete(url, headers: _headers);
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  Future<int> deleteAllMyPosts() async {
    final url = Uri.parse('$baseUrl/posts/my/delete-all/');
    final response = await http.delete(url, headers: _headers);
    if (response.statusCode == 200 || response.statusCode == 204) {
      try {
        final data = jsonDecode(response.body);
        return (data['deleted_count'] as num?)?.toInt() ?? 1;
      } catch (_) {
        return 1;
      }
    } else {
      throw Exception('Failed to delete all posts: ${response.body}');
    }
  }
}

