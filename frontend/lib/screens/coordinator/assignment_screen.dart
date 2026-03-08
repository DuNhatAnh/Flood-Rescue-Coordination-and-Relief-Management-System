import 'package:flutter/material.dart';

class AssignmentScreen extends StatelessWidget {
  const AssignmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân công đội cứu hộ'),
      ),
      body: const Center(
        child: Text('Chọn đội cứu hộ và phương tiện cho yêu cầu'),
      ),
    );
  }
}
