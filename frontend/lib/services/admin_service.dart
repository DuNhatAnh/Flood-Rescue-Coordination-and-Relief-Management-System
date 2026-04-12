import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class AdminService {
  final String baseUrl = Constants.apiBaseUrl;

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
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return (body is Map && body['success'] == true) ? (body['data'] ?? []) : (body is List ? body : []);
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
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return (body is Map && body['success'] == true) ? (body['data'] ?? body) : body;
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
    final url = Uri.parse('$baseUrl/v1/notifications');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['data'];
    }
    throw Exception('Failed to load notifications');
  }

  Future<void> sendNotification(Map<String, dynamic> notificationData) async {
    final url = Uri.parse('$baseUrl/v1/notifications');
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
    final url = Uri.parse('$baseUrl/v1/admin/system/logs');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load system logs');
  }

  Future<Map<String, dynamic>> fetchSystemStats() async {
    final url = Uri.parse('$baseUrl/v1/admin/system/reports/general');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load system statistics');
  }

  Future<Map<String, dynamic>> fetchDetailedAnalytics() async {
    final url = Uri.parse('$baseUrl/v1/reports/analytics');
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        }
      }
      return {}; // return empty map if failed
    } catch (e) {
      print('Error fetching analytics: $e');
      return {};
    }
  }

  Future<List<dynamic>> getRoles() async {
    final url = Uri.parse('$baseUrl/v1/admin/roles');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return (body is Map && body['success'] == true) ? (body['data'] ?? []) : (body is List ? body : []);
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
    final url = Uri.parse('$baseUrl/v1/warehouses');
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['success'] == true) {
          final data = body['data'];
          if (data is List) return data;
        }
        if (body is List) return body;
        if (body is Map && body['data'] is List) return body['data'];
        return [];
      }
      throw Exception('Failed to load warehouses: ${response.statusCode}');
    } catch (e) {
      print('Error in getWarehouses: $e');
      rethrow;
    }
  }


  Future<Map<String, dynamic>> createWarehouse(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/v1/warehouses');
    final headers = await _getAuthHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return (body is Map && body['success'] == true) ? body['data'] : body;
    }
    throw Exception('Failed to create warehouse');
  }

  Future<Map<String, dynamic>> updateWarehouse(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/v1/warehouses/$id');
    final headers = await _getAuthHeaders();
    final response = await http.put(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return (body is Map && body['success'] == true) ? body['data'] : body;
    }
    throw Exception('Failed to update warehouse');
  }

  Future<void> deleteWarehouse(String id) async {
    final url = Uri.parse('$baseUrl/v1/warehouses/$id');
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

  Future<void> updateTeam(String teamId, String newName) async {
    final url = Uri.parse('$baseUrl/v1/teams/$teamId');
    final headers = await _getAuthHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({'teamName': newName}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update team name');
    }
  }

  // --- Danger Point Management ---
  Future<List<dynamic>> getDangerPoints() async {
    final url = Uri.parse('$baseUrl/v1/danger-points');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['data'];
    }
    throw Exception('Failed to load danger points');
  }

  Future<Map<String, dynamic>> createDangerPoint(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/v1/danger-points');
    final headers = await _getAuthHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['data'];
    }
    throw Exception('Failed to create danger point');
  }

  Future<void> deleteDangerPoint(String id) async {
    final url = Uri.parse('$baseUrl/v1/danger-points/$id');
    final headers = await _getAuthHeaders();
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) throw Exception('Failed to delete danger point');
  }

  // --- System Configuration ---
  Future<void> updateSystemConfig(String key, String value, String adminId) async {
    final url = Uri.parse('$baseUrl/v1/admin/system/config?key=$key&value=$value&adminId=$adminId');
    final headers = await _getAuthHeaders();
    final response = await http.put(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to update system config');
    }
  }

  Future<List<dynamic>> getSystemConfigs() async {
    final url = Uri.parse('$baseUrl/v1/admin/system/config'); // Giả định endpoint này tồn tại
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['data'];
    }
    return [];
  }
}

