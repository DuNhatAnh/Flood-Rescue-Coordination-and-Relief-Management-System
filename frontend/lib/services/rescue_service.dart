import 'package:dio/dio.dart';
import 'package:flood_rescue_app/models/rescue_request.dart';
import 'package:flood_rescue_app/models/rescue_team.dart';
import 'package:flood_rescue_app/models/vehicle.dart';
import 'package:flood_rescue_app/models/assignment.dart';
import 'package:flood_rescue_app/models/safety_report.dart';

class RescueService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // Lấy danh sách yêu cầu chờ xử lý
  Future<List<RescueRequest>> getPendingRequests() async {
    try {
      final response = await _dio.get('/rescue-requests/pending');
      if (response.statusCode == 200) {
        // Handle ApiResponse wrapper
        final responseData = response.data;
        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((json) => RescueRequest.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching pending requests: $e');
      return [];
    }
  }

  // Cập nhật mức độ khẩn cấp
  Future<bool> updateUrgency(String id, String level) async {
    try {
      final response = await _dio.put('/rescue-requests/$id/urgency', data: level);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Xác minh yêu cầu
  Future<bool> verifyRequest(String id, String verifierName) async {
    try {
      final response = await _dio.put(
        '/rescue-requests/$id/verify', 
        queryParameters: {'verifiedBy': verifierName}
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Lấy đội rảnh
  Future<List<RescueTeam>> getAvailableTeams() async {
    try {
      final response = await _dio.get('/teams/available');
      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> data = (responseData is Map) ? responseData['data'] : responseData;
        return data.map((json) => RescueTeam.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Lấy phương tiện rảnh
  Future<List<Vehicle>> getAvailableVehicles() async {
    try {
      final response = await _dio.get('/vehicles/available');
      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> data = (responseData is Map) ? responseData['data'] : responseData;
        return data.map((json) => Vehicle.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // TẠO PHÂN CÔNG
  Future<bool> createAssignment(String requestId, String teamId, String vehicleId) async {
    try {
      final response = await _dio.post('/assignments', queryParameters: {
        'requestId': requestId,
        'teamId': teamId,
        'vehicleId': vehicleId,
        'assignedBy': 'Coordinator' // Should get from Auth
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Lấy nhiệm vụ của tôi
  Future<List<Assignment>> getMyTasks() async {
    try {
      final response = await _dio.get('/assignments/my-tasks');
      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> data = (responseData is Map) ? responseData['data'] : responseData;
        return data.map((json) => Assignment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Cập nhật trạng thái (Báo cáo)
  Future<bool> submitRescueReport({
    required String assignmentId,
    required int rescuedCount,
    required String note,
  }) async {
    try {
      final response = await _dio.put('/assignments/$assignmentId/status', data: {
        'rescuedCount': rescuedCount,
        'note': note,
        'status': 'COMPLETED'
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Gửi báo cáo an toàn
  Future<bool> submitSafetyReport(SafetyReport report) async {
    try {
      final response = await _dio.post('/safety-reports', data: report.toJson());
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Lấy danh sách báo cáo an toàn
  Future<List<SafetyReport>> getSafetyReports() async {
    try {
      final response = await _dio.get('/safety-reports');
      if (response.statusCode == 200) {
        final responseData = response.data;
        // SafetyReport currently returns raw list in SafetyReportController
        // Let's check SafetyReportController to be sure. 
        // Assuming we'll standardize it to ApiResponse as well.
        if (responseData is Map && responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((json) => SafetyReport.fromJson(json)).toList();
        } else if (responseData is List) {
          return responseData.map((json) => SafetyReport.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
