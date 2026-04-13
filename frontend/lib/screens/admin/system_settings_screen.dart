import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/geocoding_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  
  // Các controller và giá trị cấu hình
  final hotspotNumberController = TextEditingController(text: '086.777.9427');
  final hotspotEmailController = TextEditingController(text: 'support@rescue.vn');
  final mapAddressController = TextEditingController(text: 'Đà Nẵng, Việt Nam');
  final mapLatController = TextEditingController(text: '15.6');
  final mapLngController = TextEditingController(text: '108.5');
  final mapZoomController = TextEditingController(text: '11.0');
  bool _isMaintenanceMode = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
cấp    _fetchConfigs();
  }

  Future<void> _fetchConfigs() async {
    setState(() => _isLoading = true);
    try {
      final configs = await _adminService.getSystemConfigs();
      for (var config in configs) {
        final String key = config['key'];
        final String value = config['value'];
        
        switch (key) {
          case 'HOTLINE_NUMBER':
            hotspotNumberController.text = value;
            break;
          case 'SUPPORT_EMAIL':
            hotspotEmailController.text = value;
            break;
          case 'MAP_CENTER_LAT':
            mapLatController.text = value;
            break;
          case 'MAP_CENTER_LNG':
            mapLngController.text = value;
            break;
          case 'MAP_DEFAULT_ZOOM':
            mapZoomController.text = value;
            break;
          case 'MAINTENANCE_MODE':
            _isMaintenanceMode = value == 'true';
            break;
        }
      }
    } catch (e) {
      debugPrint('Error fetching system configs: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateConfig(String key, String value) async {
    final admin = AuthService.currentUser;
    if (admin == null) return;

    setState(() => _isLoading = true);
    try {
      await _adminService.updateSystemConfig(key, value, admin.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật $key thành công'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật $key: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        backgroundColor: const Color(0xFF2555D4),
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Thông tin liên hệ khẩn cấp'),
                _buildSettingCard([
                  _buildTextFieldSetting('Hotline cứu hộ', hotspotNumberController, 'HOTLINE_NUMBER'),
                  const Divider(),
                  _buildTextFieldSetting('Email hỗ trợ', hotspotEmailController, 'SUPPORT_EMAIL'),
                ]),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Cấu hình mặc định bản đồ'),
                _buildSettingCard([
                  ListTile(
                    title: const Text('Tìm vị trí theo địa chỉ', style: TextStyle(fontSize: 14)),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: mapAddressController,
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Nhập địa chỉ (VD: Huế)...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: _isSearching 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.search, color: Colors.blue, size: 20),
                          onPressed: _isSearching ? null : _searchMapLocation,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildTextFieldSetting('Kinh độ trung tâm (Lat)', mapLatController, 'MAP_CENTER_LAT'),
                  const Divider(),
                  _buildTextFieldSetting('Vĩ độ trung tâm (Lng)', mapLngController, 'MAP_CENTER_LNG'),
                  const Divider(),
                  _buildTextFieldSetting('Mức zoom mặc định', mapZoomController, 'MAP_DEFAULT_ZOOM'),
                ]),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Trạng thái hệ thống'),
                _buildSettingCard([
                  ListTile(
                    leading: const Icon(Icons.build_circle_outlined, color: Colors.orange),
                    title: const Text('Chế độ bảo trì'),
                    subtitle: const Text('Khi bật, người dân sẽ không thể gửi yêu cầu SOS'),
                    trailing: Switch(
                      value: _isMaintenanceMode,
                      activeColor: Colors.orange,
                      onChanged: (val) {
                        setState(() => _isMaintenanceMode = val);
                        _updateConfig('MAINTENANCE_MODE', val.toString());
                      },
                    ),
                  ),
                ]),
                
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Lưu ý: Các thay đổi sẽ có hiệu lực ngay lập tức trên ứng dụng của người dùng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
    );
  }

  Future<void> _searchMapLocation() async {
    if (mapAddressController.text.isEmpty) return;
    
    setState(() => _isSearching = true);
    final coords = await GeocodingService.searchAddress(mapAddressController.text);
    
    setState(() {
      _isSearching = false;
      if (coords != null) {
        mapLatController.text = coords['lat']!.toString();
        mapLngController.text = coords['lng']!.toString();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy tọa độ cho địa chỉ này')),
        );
      }
    });
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextFieldSetting(String label, TextEditingController controller, String configKey) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: TextField(
        controller: controller,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
          hintText: 'Nhập giá trị...',
        ),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: TextButton(
        onPressed: () => _updateConfig(configKey, controller.text),
        child: const Text('Lưu'),
      ),
    );
  }
}
