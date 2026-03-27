import 'package:flutter/material.dart';
import 'package:flood_rescue_app/models/rescue_request.dart';
import 'package:flood_rescue_app/models/rescue_team.dart';
import 'package:flood_rescue_app/models/vehicle.dart';
import 'package:flood_rescue_app/services/rescue_service.dart';

class AssignmentScreen extends StatefulWidget {
  final RescueRequest request;

  const AssignmentScreen({Key? key, required this.request}) : super(key: key);

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final RescueService _rescueService = RescueService();
  
  RescueTeam? _selectedTeam;
  Vehicle? _selectedVehicle;
  Map<String, dynamic>? _managedWarehouse;
  
  List<RescueTeam> _availableTeams = [];
  List<Vehicle> _availableVehicles = [];
  List<Vehicle> _filteredVehicles = [];
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingWarehouse = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final teams = await _rescueService.getAvailableTeams();
      final vehicles = await _rescueService.getAvailableVehicles();
      
      setState(() {
        _availableTeams = teams;
        _availableVehicles = vehicles;
        _filteredVehicles = vehicles; // Ban đầu hiện tất cả hoặc rỗng tùy logic, ở đây hiện tất cả
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onTeamSelected(RescueTeam team) async {
    setState(() {
      _selectedTeam = team;
      _selectedVehicle = null;
      _managedWarehouse = null;
      _isLoadingWarehouse = true;
      // Lọc xe ngay lập tức
      _filteredVehicles = _availableVehicles.where((v) => v.teamId == team.id).toList();
    });

    try {
      final warehouse = await _rescueService.getWarehouseByManager(team.leaderId);
      setState(() {
        _managedWarehouse = warehouse;
        _isLoadingWarehouse = false;
      });
    } catch (e) {
      setState(() => _isLoadingWarehouse = false);
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedTeam == null || _selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ Đội và Phương tiện')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    final success = await _rescueService.createAssignment(
      widget.request.id,
      _selectedTeam!.id,
      _selectedVehicle!.id,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phân công thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Trả về true để Dashboard tải lại dữ liệu
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phân công thất bại. Vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân Công Nhiệm Vụ'),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequestSummary(),
                  const SizedBox(height: 24),
                  const Text('1. Chọn Đội Cứu Hộ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTeamSelector(),
                  const SizedBox(height: 24),
                  if (_selectedTeam != null) ...[
                    const Text('Kho Tiếp Tế Của Đội',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildWarehouseCard(),
                    const SizedBox(height: 24),
                  ],
                  const Text('2. Chọn Phương Tiện',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildVehicleSelector(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('XÁC NHẬN PHÂN CÔNG',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRequestSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Yêu cầu: ${widget.request.citizenName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Địa chỉ: ${widget.request.address}', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text('Tình trạng: ${widget.request.description}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTeamSelector() {
    return Column(
      children: _availableTeams.map((team) {
        final isSelected = _selectedTeam?.id == team.id;
        return Card(
          elevation: isSelected ? 4 : 0,
          color: isSelected ? Colors.blue[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isSelected ? Colors.blue : Colors.grey[300]!),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
              child: Icon(Icons.group, color: isSelected ? Colors.white : Colors.grey),
            ),
            title: Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Trạng thái: ${team.status == 'AVAILABLE' ? 'Sẵn sàng' : 'Đang bận'}'),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
            onTap: () => _onTeamSelected(team),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWarehouseCard() {
    if (_isLoadingWarehouse) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(strokeWidth: 2),
      ));
    }

    if (_managedWarehouse == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text('Đội này chưa được gán quản lý kho nào', style: TextStyle(color: Colors.orange)),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE1F5FE),
              child: Icon(Icons.warehouse, color: Color(0xFF0288D1)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _managedWarehouse?['warehouseName'] ?? 'Tên kho',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _managedWarehouse?['location'] ?? 'Vị trí kho',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Text('ĐANG QUẢN LÝ', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    if (_filteredVehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            _selectedTeam == null 
              ? 'Vui lòng chọn đội để xem phương tiện' 
              : 'Đội này hiện không có phương tiện sẵn sàng',
            style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _filteredVehicles.map((vehicle) {
        final isSelected = _selectedVehicle?.id == vehicle.id;
        return InkWell(
          onTap: () => setState(() => _selectedVehicle = vehicle),
          child: Container(
            width: (MediaQuery.of(context).size.width - 52) / 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  vehicle.vehicleType == 'Xuồng Máy' ? Icons.directions_boat : Icons.local_shipping,
                  color: isSelected ? Colors.blue : Colors.grey,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(vehicle.vehicleType, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(vehicle.licensePlate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
