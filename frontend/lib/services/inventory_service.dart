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
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) => Inventory.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load inventory');
      }
    } catch (e) {
      throw Exception('Error fetching inventory: $e');
    }
  }

  Future<Inventory> importStock(String warehouseId, String itemId, int quantity, {String? source, String? referenceNumber, DateTime? expiryDate, String? condition}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/import'),
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
        return Inventory.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Failed to import stock');
      }
    } catch (e) {
      throw Exception('Error importing stock: $e');
    }
  }
}
