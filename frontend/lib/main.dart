import 'package:flutter/material.dart';

void main() {
  runApp(const FloodRescueApp());
}

class FloodRescueApp extends StatelessWidget {
  const FloodRescueApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flood Rescue System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const InitialPage(),
    );
  }
}

class InitialPage extends StatelessWidget {
  const InitialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flood Rescue System')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Flood Rescue Coordination and Relief Management System'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to Rescue Request Form
              },
              child: const Text('Gửi yêu cầu cứu hộ'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // TODO: Navigate to Login Form
              },
              child: const Text('ĐĂNG NHẬP (Cho Cán bộ)'),
            )
          ],
        ),
      ),
    );
  }
}
