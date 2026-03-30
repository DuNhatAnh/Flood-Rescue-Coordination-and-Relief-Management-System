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
  List<dynamic> _roles = [];
  List<dynamic> _teams = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final roles = await _adminService.getRoles();
      final teams = await _adminService.getTeams();
      setState(() {
        _roles = roles;
        _teams = teams;
      });
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _adminService.getUsers(query: _searchQuery);
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải Users: $e')),
      );
    }
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedRole = _roles.isNotEmpty ? _roles.first['id'] : null;
    String? selectedTeam;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo tài khoản mới'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ tên')),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: _roles.map((role) => DropdownMenuItem<String>(
                      value: role['id'],
                      child: Text(role['name'] ?? ''),
                    )).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedRole = val);
                    },
                    decoration: const InputDecoration(labelText: 'Vai trò'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedTeam,
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Không thuộc đội nào')),
                      ..._teams.map((team) => DropdownMenuItem<String>(
                        value: team['id'],
                        child: Text(team['teamName'] ?? ''),
                      )).toList(),
                    ],
                    onChanged: (val) {
                      setDialogState(() => selectedTeam = val);
                    },
                    decoration: const InputDecoration(labelText: 'Đội cứu hộ (Tùy chọn)'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedRole == null) return;
                    try {
                      await _adminService.createUser({
                        'fullName': nameController.text,
                        'email': emailController.text,
                        'phone': phoneController.text,
                        'roleId': selectedRole,
                        'teamId': selectedTeam,
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
            );
          }
        );
      },
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
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isActive = user['status'] == 'ACTIVE';
                      
                      String? currentRole = user['roleId'];
                      if (!_roles.any((r) => r['id'] == currentRole)) {
                        currentRole = null;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF2555D4).withValues(alpha: 0.1),
                                child: Text(
                                  (user['fullName'] ?? 'U').substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2555D4)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['fullName'] ?? 'N/A',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user['email'] ?? 'No email',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: isActive ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5)),
                                          ),
                                          child: Text(
                                            isActive ? 'Hoạt động' : 'Đã khóa',
                                            style: TextStyle(
                                              color: isActive ? Colors.green : Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isDense: true,
                                              value: currentRole,
                                              hint: const Text('Chọn Role', style: TextStyle(fontSize: 12)),
                                              style: const TextStyle(color: Color(0xFF2555D4), fontWeight: FontWeight.bold, fontSize: 14),
                                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2555D4)),
                                              items: _roles.map((role) => DropdownMenuItem<String>(
                                                value: role['id'],
                                                child: Text(role['name'] ?? ''),
                                              )).toList(),
                                              onChanged: (val) async {
                                                if (val != null) {
                                                  try {
                                                    await _adminService.updateUserRole(user['id'], val);
                                                    if (!mounted) return;
                                                    _loadUsers();
                                                  } catch (e) {
                                                    if (!mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi cập nhật quyền: $e')));
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isActive,
                                activeColor: Colors.green,
                                  onChanged: (val) async {
                                    final newStatus = val ? 'ACTIVE' : 'LOCKED';
                                    try {
                                      await _adminService.updateUserStatus(user['id'], newStatus);
                                      if (!mounted) return;
                                      _loadUsers();
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                                    }
                                  },
                              ),
                            ],
                          ),
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
