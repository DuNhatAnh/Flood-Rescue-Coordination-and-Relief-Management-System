import 'package:flutter/material.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Kho cứu trợ'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Danh sách hàng hóa (Dev 4)'),
      ),
    );
  }
}
