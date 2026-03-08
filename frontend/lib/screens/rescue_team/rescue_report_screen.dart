import 'package:flutter/material.dart';

class RescueReportScreen extends StatelessWidget {
  const RescueReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo kết quả cứu hộ'),
      ),
      body: const Center(
        child: Text('Form nhập số người đã cứu, tình hình thực tế và ảnh'),
      ),
    );
  }
}
