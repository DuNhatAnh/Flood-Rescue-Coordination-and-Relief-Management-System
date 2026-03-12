import 'package:dio/dio.dart';
import '../models/relief_item.dart';

class ReliefItemService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<ReliefItem>> getAll() async {
    try {
      final response = await _dio.get('/relief-items');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => ReliefItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching relief items: $e');
      return [];
    }
  }

  Future<ReliefItem?> create(ReliefItem item) async {
    try {
      final response = await _dio.post(
        '/relief-items',
        data: item.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReliefItem.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error creating relief item: $e');
      return null;
    }
  }

  Future<ReliefItem?> update(String id, ReliefItem item) async {
    try {
      final response = await _dio.put(
        '/relief-items/$id',
        data: item.toJson(),
      );
      if (response.statusCode == 200) {
        return ReliefItem.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error updating relief item: $e');
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final response = await _dio.delete('/relief-items/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting relief item: $e');
      return false;
    }
  }
}
