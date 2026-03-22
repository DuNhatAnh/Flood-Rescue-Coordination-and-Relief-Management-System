import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getUsers(query: _searchQuery);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'USER';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo tài khoản mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ tên')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              items: const [
                DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                DropdownMenuItem(value: 'COORDINATOR', child: Text('Coordinator')),
                DropdownMenuItem(value: 'USER', child: Text('User')),
              ],
              onChanged: (val) => selectedRole = val!,
              decoration: const InputDecoration(labelText: 'Vai trò'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.createUser({
                  'fullName': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'roleId': selectedRole,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadUsers();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateUserDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _loadUsers();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        title: Text(user['fullName'] ?? 'N/A'),
                        subtitle: Row(
                          children: [
                            Text('${user['email']} - '),
                            DropdownButton<String>(
                              value: user['roleId'] ?? 'USER',
                              items: const [
                                DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                                DropdownMenuItem(value: 'COORDINATOR', child: Text('Coordinator')),
                                DropdownMenuItem(value: 'USER', child: Text('User')),
                              ],
                              onChanged: (val) async {
                                if (val != null) {
                                  try {
                                    await _adminService.updateUserRole(user['id'], val);
                                    _loadUsers();
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: user['status'] == 'ACTIVE',
                          onChanged: (val) async {
                            final newStatus = val ? 'ACTIVE' : 'LOCKED';
                            await _adminService.updateUserStatus(user['id'], newStatus);
                            _loadUsers();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
