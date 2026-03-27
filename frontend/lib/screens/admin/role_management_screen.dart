import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({Key? key}) : super(key: key);

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _roles = [];
  bool _isLoading = true;

  final List<String> _availablePermissions = [
    'READ_USER', 'WRITE_USER', 'DELETE_USER',
    'READ_ROLE', 'WRITE_ROLE', 'DELETE_ROLE',
    'READ_SYSTEM', 'WRITE_SYSTEM',
    'MANAGE_RESCUE', 'MANAGE_INVENTORY'
  ];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    try {
      final roles = await _adminService.getRoles();
      setState(() {
        _roles = roles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách quyền: $e')),
      );
    }
  }

  void _showRoleDialog({Map<String, dynamic>? role}) {
    final isEditing = role != null;
    final nameController = TextEditingController(text: role?['name'] ?? '');
    final descriptionController = TextEditingController(text: role?['description'] ?? '');
    
    // Explicitly cast to List<String> to avoid type errors
    List<String> selectedPermissions = [];
    if (role != null && role['permissions'] != null) {
      selectedPermissions = List<String>.from(role['permissions']);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Sửa quyền' : 'Thêm quyền mới'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Tên Role (VD: ADMIN, USER)'),
                      enabled: !isEditing, // Prevent changing name if editing
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Mô tả chi tiết'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Danh sách Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._availablePermissions.map((perm) {
                      final hasPerm = selectedPermissions.contains(perm);
                      return CheckboxListTile(
                        title: Text(perm, style: const TextStyle(fontSize: 14)),
                        value: hasPerm,
                        dense: true,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedPermissions.add(perm);
                            } else {
                              selectedPermissions.remove(perm);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    try {
                      final payload = {
                        'name': nameController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'permissions': selectedPermissions,
                      };
                      if (isEditing) {
                        await _adminService.updateRole(role['id'], payload);
                      } else {
                        await _adminService.createRole(payload);
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                      _loadRoles();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa quyền "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _adminService.deleteRole(id);
                if (!mounted) return;
                Navigator.pop(context);
                _loadRoles();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình Phân Quyền (Roles)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRoleDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _roles.length,
              itemBuilder: (context, index) {
                final role = _roles[index];
                final permissions = role['permissions'] as List<dynamic>? ?? [];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      children: [
                        const Icon(Icons.security, color: Color(0xFF2555D4)),
                        const SizedBox(width: 8),
                        Text(
                          role['name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2555D4)),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(role['description'] ?? 'Không có mô tả', style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: permissions.map((p) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Text(p.toString(), style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                          )).toList(),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showRoleDialog(role: role),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(role['id'], role['name']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
