import 'package:flutter/material.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({Key? key}) : super(key: key);

  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều phối cứu hộ'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Danh sách yêu cầu cứu hộ chờ xử lý & Bản đồ sẽ hiển thị ở đây'),
      ),
    );
  }
}
