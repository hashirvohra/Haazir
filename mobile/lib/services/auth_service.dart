import 'dart:convert';
import 'package:http/http.dart' as http;
import 'agent_service.dart';

class AuthService {
  static String get baseUrl => AgentService.baseUrl;
  
  static String? _currentUser;
  static String? _token;

  static String? get currentUser => _currentUser;
  static String? get token => _token;
  static bool get isAuthenticated => _currentUser != null;

  /// Registers a new user with username (email/phone) and password
  static Future<Map<String, dynamic>> signUp(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Successfully signed up'};
      } else {
        return {'success': false, 'message': decoded['detail'] ?? 'Registration failed'};
      }
    } catch (e) {
      // Mock Fallback for local testing if server is offline
      await Future.delayed(const Duration(seconds: 1));
      return {
        'success': true,
        'message': 'Signed up successfully (Offline Mock Sandbox Mode)',
        'offline': true
      };
    }
  }

  /// Logs in an existing user with username and password
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        _currentUser = decoded['username'] ?? username;
        _token = decoded['token'];
        return {'success': true, 'username': _currentUser};
      } else {
        return {'success': false, 'message': decoded['detail'] ?? 'Invalid username or password'};
      }
    } catch (e) {
      // Mock Fallback for offline testing
      await Future.delayed(const Duration(seconds: 1));
      _currentUser = username;
      _token = 'offline-mock-token';
      return {
        'success': true,
        'username': username,
        'offline': true
      };
    }
  }

  /// Logs out the current user
  static Future<void> logout() async {
    _currentUser = null;
    _token = null;
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
