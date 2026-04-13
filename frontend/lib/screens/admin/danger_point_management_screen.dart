import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/geocoding_service.dart';
import '../../models/danger_point.dart';
import '../../services/auth_service.dart';

class DangerPointManagementScreen extends StatefulWidget {
  const DangerPointManagementScreen({Key? key}) : super(key: key);

  @override
  State<DangerPointManagementScreen> createState() => _DangerPointManagementScreenState();
}

class _DangerPointManagementScreenState extends State<DangerPointManagementScreen> {
  final AdminService _adminService = AdminService();
  List<DangerPoint> _points = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    setState(() => _isLoading = true);
    try {
      final data = await _adminService.getDangerPoints();
      setState(() {
        _points = data.map((json) => DangerPoint.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePoint(String id) async {
    try {
      await _adminService.deleteDangerPoint(id);
      _loadPoints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa điểm nguy hiểm'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    double depth = 1.0;
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm điểm nguy hiểm mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên khu vực', hintText: 'VD: Cầu sông Hàn'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Địa chỉ', hintText: 'Nhập địa chỉ cụ thể'),
                      ),
                    ),
                    IconButton(
                      icon: isSearching 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search, color: Colors.blue),
                      onPressed: isSearching ? null : () async {
                        if (addressController.text.isEmpty) return;
                        setDialogState(() => isSearching = true);
                        final coords = await GeocodingService.searchAddress(addressController.text);
                        setDialogState(() {
                          isSearching = false;
                          if (coords != null) {
                            latController.text = coords['lat']!.toString();
                            lngController.text = coords['lng']!.toString();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Không tìm thấy tọa độ cho địa chỉ này')),
                            );
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        decoration: const InputDecoration(labelText: 'Vĩ độ (Lat)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        decoration: const InputDecoration(labelText: 'Kinh độ (Lng)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Độ sâu nước ước tính: ${depth.toStringAsFixed(1)}m', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: _getRiskColor(depth))),
                Slider(
                  value: depth,
                  min: 0,
                  max: 15,
                  divisions: 150,
                  activeColor: _getRiskColor(depth),
                  onChanged: (val) => setDialogState(() => depth = val),
                ),
                _buildRiskLegend(depth),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final lat = double.tryParse(latController.text);
                final lng = double.tryParse(lngController.text);

                if (lat == null || lat < -90 || lat > 90) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vĩ độ (Lat) không hợp lệ (phải từ -90 đến 90)')));
                  return;
                }
                if (lng == null || lng < -180 || lng > 180) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kinh độ (Lng) không hợp lệ (phải từ -180 đến 180)')));
                  return;
                }

                final user = AuthService.currentUser;
                final newPoint = DangerPoint(
                  name: nameController.text,
                  address: addressController.text,
                  latitude: lat,
                  longitude: lng,
                  depth: depth,
                  createdBy: user?.id,
                );
                
                try {
                  await _adminService.createDangerPoint(newPoint.toJson());
                  if (mounted) {
                    Navigator.pop(context);
                    _loadPoints();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm điểm nguy hiểm thành công'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Thêm mới'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(double depth) {
    if (depth < 0.5) return Colors.green;
    if (depth <= 2.0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRiskLegend(double depth) {
    String text = "";
    if (depth < 0.5) text = "Mức thấp: An toàn cho phương tiện lớn.";
    else if (depth <= 2.0) text = "Cảnh báo: Nguy hiểm cho xe máy/ô tô con.";
    else text = "Khẩn cấp: Ngập sâu, cần cứu hộ chuyên nghiệp.";
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic), textAlign: TextAlign.center),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý điểm nguy hiểm'),
        backgroundColor: const Color(0xFF2555D4),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _points.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Chưa có điểm nguy hiểm nào', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _points.length,
                  itemBuilder: (context, index) {
                    final p = _points[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getRiskColor(p.depth),
                            boxShadow: [
                              BoxShadow(color: _getRiskColor(p.depth).withOpacity(0.5), blurRadius: 4, spreadRadius: 2),
                            ],
                          ),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.address}\nĐộ sâu: ${p.depth}m', style: const TextStyle(fontSize: 12)),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _showDeleteConfirm(p),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('Tạo điểm mới'),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: const Color(0xFF2555D4),
      ),
    );
  }

  void _showDeleteConfirm(DangerPoint p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa điểm nguy hiểm tại "${p.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePoint(p.id!);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
