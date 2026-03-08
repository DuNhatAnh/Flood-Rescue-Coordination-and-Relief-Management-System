import 'package:flutter/material.dart';

class TeamTasksScreen extends StatefulWidget {
  const TeamTasksScreen({Key? key}) : super(key: key);

  @override
  State<TeamTasksScreen> createState() => _TeamTasksScreenState();
}

class _TeamTasksScreenState extends State<TeamTasksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhiệm vụ của đội'),
        backgroundColor: const Color(0xFF66BB6A),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Danh sách các nhiệm vụ đã được phân công cho đội'),
      ),
    );
  }
}
