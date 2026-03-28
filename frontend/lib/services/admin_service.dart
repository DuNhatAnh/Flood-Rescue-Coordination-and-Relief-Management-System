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
    final url = Uri.parse('$baseUrl/v1/admin/users${query != null ? '?query=$query' : ''}');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load users');
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/v1/admin/users');
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
    final url = Uri.parse('$baseUrl/v1/admin/users/$userId/status?status=$status');
    final headers = await _getAuthHeaders();
    final response = await http.put(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to update user status');
    }
  }

  Future<void> updateUserRole(String userId, String roleId) async {
    final url = Uri.parse('$baseUrl/v1/admin/users/$userId/role?roleId=$roleId');
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
    final url = Uri.parse('$baseUrl/admin/system/reports/general');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load system statistics');
  }

  Future<List<dynamic>> getRoles() async {
    final url = Uri.parse('$baseUrl/v1/admin/roles');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load roles');
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> roleData) async {
    final url = Uri.parse('$baseUrl/v1/admin/roles');
    final headers = await _getAuthHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(roleData),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to create role');
  }

  Future<Map<String, dynamic>> updateRole(String id, Map<String, dynamic> roleData) async {
    final url = Uri.parse('$baseUrl/v1/admin/roles/$id');
    final headers = await _getAuthHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(roleData),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to update role');
  }

  Future<void> deleteRole(String id) async {
    final url = Uri.parse('$baseUrl/v1/admin/roles/$id');
    final headers = await _getAuthHeaders();
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete role');
    }
  }

  // --- Warehouse Management ---
  Future<List<dynamic>> getWarehouses() async {
    final url = Uri.parse('$baseUrl/warehouses');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body; // The backend returns List directly or inside data
    }
    throw Exception('Failed to load warehouses');
  }

  Future<Map<String, dynamic>> createWarehouse(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/warehouses');
    final headers = await _getAuthHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create warehouse');
  }

  Future<Map<String, dynamic>> updateWarehouse(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/warehouses/$id');
    final headers = await _getAuthHeaders();
    final response = await http.put(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update warehouse');
  }

  Future<void> deleteWarehouse(String id) async {
    final url = Uri.parse('$baseUrl/warehouses/$id');
    final headers = await _getAuthHeaders();
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) throw Exception('Failed to delete warehouse');
  }

  // --- Team Management ---
  Future<List<dynamic>> getTeams() async {
    final headers = await _getAuthHeaders();
    
    // First try the standard team endpoint
    final teamUrl = Uri.parse('$baseUrl/v1/teams');
    final response = await http.get(teamUrl, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    
    // Fallback to available-teams if needed
    final fallbackUrl = Uri.parse('$baseUrl/v1/rescue-coordination/available-teams');
    final fallbackRes = await http.get(fallbackUrl, headers: headers);
    if (fallbackRes.statusCode == 200) {
      final body = jsonDecode(fallbackRes.body);
      return body['data'];
    }
    
    throw Exception('Failed to load teams');
  }
}

