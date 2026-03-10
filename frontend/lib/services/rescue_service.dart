import 'package:dio/dio.dart';
import '../models/rescue_request.dart';
import '../models/rescue_team.dart';
import '../models/vehicle.dart';
import '../models/assignment.dart';

class RescueService {
  // final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'));

  // Lấy danh sách yêu cầu chờ xử lý
  Future<List<RescueRequest>> getPendingRequests() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return [
        RescueRequest(
          id: '1',
          citizenName: 'Nguyễn Văn A',
          phone: '0901234567',
          lat: 16.0471,
          lng: 108.2062,
          address: '123 Hùng Vương, Đà Nẵng',
          description: 'Nước dâng cao đến mái nhà.',
          urgency: UrgencyLevel.high,
          numberOfPeople: 3,
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        RescueRequest(
          id: '2',
          citizenName: 'Trần Thị B',
          phone: '0912345678',
          lat: 16.0544,
          lng: 108.2022,
          address: '456 Lê Duẩn, Đà Nẵng',
          description: 'Cần lương thực gấp.',
          urgency: UrgencyLevel.medium,
          numberOfPeople: 2,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  // Lấy đội rảnh
  Future<List<RescueTeam>> getAvailableTeams() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      RescueTeam(id: 1, teamName: 'Đội Cứu Hộ Hải Châu 1', status: 'AVAILABLE', leaderId: 3),
      RescueTeam(id: 2, teamName: 'Đội Phản Ứng Nhanh Thanh Khê', status: 'AVAILABLE', leaderId: 4),
    ];
  }

  // Lấy phương tiện rảnh
  Future<List<Vehicle>> getAvailableVehicles() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Vehicle(id: 1, vehicleType: 'Xuồng Máy', licensePlate: 'DN-001', status: 'AVAILABLE'),
      Vehicle(id: 2, vehicleType: 'Xe Lội Nước', licensePlate: 'DN-002', status: 'AVAILABLE'),
    ];
  }

  // TẠO PHÂN CÔNG (Restore)
  Future<bool> createAssignment(String requestId, int teamId, int vehicleId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Lấy nhiệm vụ của tôi
  Future<List<Assignment>> getMyTasks() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Assignment(
        id: 'A1',
        requestId: '1',
        teamId: '1',
        teamName: 'Đội Cứu Hộ Hải Châu 1',
        vehicleId: '1',
        assignedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        status: 'IN_PROGRESS',
      ),
    ];
  }

  // Cập nhật trạng thái (Báo cáo)
  Future<bool> submitRescueReport({
    required String assignmentId,
    required int rescuedCount,
    required String note,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }
}
