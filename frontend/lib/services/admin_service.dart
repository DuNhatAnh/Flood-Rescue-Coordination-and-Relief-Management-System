import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminService {
  final String baseUrl = 'http://localhost:8080/api';

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getUsers({String? query}) async {
    final url = Uri.parse('$baseUrl/admin/users${query != null ? '?query=$query' : ''}');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load users');
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/admin/users');
    final headers = await _getAuthHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(userData),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to create user');
  }

  Future<void> updateUserStatus(String userId, String status) async {
    final url = Uri.parse('$baseUrl/admin/users/$userId/status?status=$status');
    final headers = await _getAuthHeaders();
    final response = await http.put(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to update user status');
    }
  }

  Future<void> updateUserRole(String userId, String roleId) async {
    final url = Uri.parse('$baseUrl/admin/users/$userId/role?roleId=$roleId');
    final headers = await _getAuthHeaders();
    final response = await http.put(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to update user role');
    }
  }

  Future<List<dynamic>> fetchAllNotifications() async {
    final url = Uri.parse('$baseUrl/notifications');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load notifications');
  }

  Future<void> sendNotification(Map<String, dynamic> notificationData) async {
    final url = Uri.parse('$baseUrl/notifications');
    final headers = await _getAuthHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(notificationData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send notification');
    }
  }

  Future<List<dynamic>> fetchSystemLogs() async {
    final url = Uri.parse('$baseUrl/admin/system/logs');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load system logs');
  }

  Future<Map<String, dynamic>> fetchSystemStats() async {
    final url = Uri.parse('$baseUrl/admin/system/reports');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load system statistics');
  }
}

