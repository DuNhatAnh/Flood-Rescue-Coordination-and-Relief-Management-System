import 'package:dio/dio.dart';
import '../models/warehouse.dart';

class WarehouseService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<Warehouse>> getAll() async {
    try {
      final response = await _dio.get('/warehouses');
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((json) => Warehouse.fromJson(json)).toList();
        }
        List<dynamic> data = responseData;
        return data.map((json) => Warehouse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching warehouses: $e');
      return [];
    }
  }

  Future<Warehouse?> getByManagerId(String managerId) async {
    try {
      final response = await _dio.get('/warehouses/manager/$managerId');
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return Warehouse.fromJson(responseData['data']);
        }
        return Warehouse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      print('Error fetching warehouse by manager: $e');
      return null;
    }
  }

  Future<Warehouse?> create(Warehouse warehouse) async {
    try {
      final response = await _dio.post(
        '/warehouses',
        data: warehouse.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return Warehouse.fromJson(responseData['data']);
        }
        return Warehouse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      print('Error creating warehouse: $e');
      return null;
    }
  }

  Future<Warehouse?> update(String id, Warehouse warehouse) async {
    try {
      final response = await _dio.put(
        '/warehouses/$id',
        data: warehouse.toJson(),
      );
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return Warehouse.fromJson(responseData['data']);
        }
        return Warehouse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      print('Error updating warehouse: $e');
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final response = await _dio.delete('/warehouses/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting warehouse: $e');
      return false;
    }
  }
}
