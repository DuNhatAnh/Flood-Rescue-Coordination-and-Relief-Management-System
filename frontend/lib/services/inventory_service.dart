import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/inventory.dart';

class InventoryService {
  static const String baseUrl = 'http://localhost:8080/api/inventory';

  Future<List<Inventory>> getWarehouseInventory(String warehouseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/warehouse/$warehouseId'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['success'] == true) {
          List<dynamic> data = body['data'];
          return data.map((dynamic item) => Inventory.fromJson(item)).toList();
        } else if (body is List) {
           return body.map((dynamic item) => Inventory.fromJson(item)).toList();
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to load inventory');
      }
    } catch (e) {
      throw Exception('Error fetching inventory: $e');
    }
  }

  Future<Inventory> importStock(String warehouseId, String itemId, int quantity, {String? userId, String? source, String? referenceNumber, DateTime? expiryDate, String? condition}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/import?userId=${userId ?? ''}'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'warehouseId': warehouseId,
          'itemId': itemId,
          'quantity': quantity,
          'source': source,
          'referenceNumber': referenceNumber,
          'expiryDate': expiryDate?.toIso8601String(),
          'condition': condition,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['success'] == true) {
          return Inventory.fromJson(body['data']);
        }
        return Inventory.fromJson(body);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Failed to import stock');
      }
    } catch (e) {
      throw Exception('Error importing stock: $e');
    }
  }
}
