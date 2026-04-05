import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/relief_item.dart';

class ReliefItemService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<ReliefItem>> getAll() async {
    try {
      final response = await _dio.get('/relief-items');
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((json) => ReliefItem.fromJson(json)).toList();
        }
        List<dynamic> data = responseData;
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
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return ReliefItem.fromJson(responseData['data']);
        }
        return ReliefItem.fromJson(responseData);
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
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return ReliefItem.fromJson(responseData['data']);
        }
        return ReliefItem.fromJson(responseData);
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
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map) return responseData['success'] == true;
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting relief item: $e');
      return false;
    }
  }

  Future<String?> uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      });

      // Use a separate Dio instance or the full URL because the endpoint is /api/upload/image
      // while _dio.baseUrl is likely http://localhost:8080/api
      final response = await _dio.post(
        '/upload/image',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
