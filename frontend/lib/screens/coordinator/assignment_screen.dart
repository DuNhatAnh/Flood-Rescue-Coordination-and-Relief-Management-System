import 'package:flutter/material.dart';
import 'package:flood_rescue_app/models/rescue_request.dart';
import 'package:flood_rescue_app/models/rescue_team.dart';
import 'package:flood_rescue_app/models/vehicle.dart';
import 'package:flood_rescue_app/models/inventory.dart';
import 'package:flood_rescue_app/services/rescue_service.dart';
import 'package:flood_rescue_app/services/inventory_service.dart';
import 'package:flood_rescue_app/services/warehouse_service.dart';
import 'package:flood_rescue_app/models/warehouse.dart';
import 'dart:math';


class AssignmentScreen extends StatefulWidget {
  final RescueRequest request;

  const AssignmentScreen({Key? key, required this.request}) : super(key: key);

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final RescueService _rescueService = RescueService();
  final InventoryService _inventoryService = InventoryService();
  final WarehouseService _warehouseService = WarehouseService();

  
  RescueTeam? _selectedTeam;
  List<String> _selectedVehicleIds = [];
  Map<String, int> _itemQuantities = {}; // itemId -> quantity
  
  List<RescueTeam> _availableTeams = [];
  List<Vehicle> _availableVehicles = [];
  List<Vehicle> _filteredVehicles = [];
  List<Inventory> _warehouseInventory = [];
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingWarehouse = false;
  String? _currentWarehouseName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final teams = await _rescueService.getAvailableTeams();
      final vehicles = await _rescueService.getAvailableVehicles();
      final List<Warehouse> warehouses = await _warehouseService.getAll();
      
      // Map warehouseId to Warehouse for quick lookup
      final warehouseMap = {for (var w in warehouses) w.id: w};

      // Calculate distance for each team
      for (var team in teams) {
        if (team.warehouseId != null && warehouseMap.containsKey(team.warehouseId)) {
          final warehouse = warehouseMap[team.warehouseId]!;
          if (warehouse.latitude != null && warehouse.longitude != null) {
            team.distance = _calculateDistance(
              widget.request.lat, 
              widget.request.lng, 
              warehouse.latitude!, 
              warehouse.longitude!
            );
          }
        }
      }

      // Sort teams by distance (null distances go to the end)
      teams.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });

      setState(() {
        _availableTeams = teams;
        _availableVehicles = vehicles;
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 + 
        cos(lat1 * p) * cos(lat2 * p) * 
        (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<void> _onTeamSelected(RescueTeam team) async {
    setState(() {
      _selectedTeam = team;
      _selectedVehicleIds = [];
      _itemQuantities = {};
      _warehouseInventory = [];
      _isLoadingWarehouse = true;
      _currentWarehouseName = null;
      
      // Initial filter by teamId or warehouseId if available
      _filteredVehicles = _availableVehicles.where((v) => 
        (team.warehouseId != null && v.warehouseId == team.warehouseId) || v.teamId == team.id
      ).toList();
    });

    try {
      print('DEBUG: Selecting team ${team.teamName}, warehouseId: ${team.warehouseId}, leaderId: ${team.leaderId}');
      Map<String, dynamic>? warehouse;
      if (team.warehouseId != null && team.warehouseId!.isNotEmpty && team.warehouseId != 'null') {
        print('DEBUG: Fetching warehouse by ID: ${team.warehouseId}');
        warehouse = await _rescueService.getWarehouseById(team.warehouseId!);
      } else {
        print('DEBUG: Fetching warehouse by manager: ${team.leaderId}');
        warehouse = await _rescueService.getWarehouseByManager(team.leaderId);
      }

      print('DEBUG: Received warehouse data: $warehouse');

      if (warehouse != null && (warehouse['id'] != null || warehouse['_id'] != null)) {
        final warehouseId = (warehouse['id'] ?? warehouse['_id']).toString();
        print('DEBUG: Definite warehouseId: $warehouseId');
        
        // Fetch inventory and vehicles in parallel
        final results = await Future.wait([
          _inventoryService.getWarehouseInventory(warehouseId),
          _rescueService.getVehiclesByWarehouse(warehouseId),
        ]);
        
        final inventory = results[0] as List<Inventory>;
        final warehouseVehicles = results[1] as List<Vehicle>;

        setState(() {
          _warehouseInventory = inventory;
          _currentWarehouseName = warehouse?['warehouseName'] ?? warehouse?['warehouse_name'] ?? 'Kho không tên';
          _isLoadingWarehouse = false;
          
          // Ưu tiên dùng danh sách xe lấy trực tiếp từ kho, nếu không có thì lọc từ danh sách available
          _filteredVehicles = warehouseVehicles.isNotEmpty 
              ? warehouseVehicles 
              : _availableVehicles.where((v) => v.warehouseId == warehouseId || v.teamId == team.id).toList();
          
          print('DEBUG: Filtered vehicles count: ${_filteredVehicles.length}');
        });
      } else {
        print('DEBUG: Warehouse not found or invalid');
        setState(() => _isLoadingWarehouse = false);
      }
    } catch (e) {
      print('DEBUG: Error in _onTeamSelected: $e');
      setState(() => _isLoadingWarehouse = false);
    }
  }

  Future<void> _submitAssignment() async {
    if (_selectedTeam == null || _selectedVehicleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Đội và ít nhất một Phương tiện')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Convert _itemQuantities to list of MissionItem maps
    List<Map<String, dynamic>> missionItems = [];
    _itemQuantities.forEach((itemId, quantity) {
      if (quantity > 0) {
        final item = _warehouseInventory.firstWhere((i) => i.itemId == itemId);
        missionItems.add({
          'itemId': itemId,
          'itemName': item.itemName,
          'unit': item.unit,
          'quantity': quantity,
        });
      }
    });
    
    final success = await _rescueService.createAssignment(
      widget.request.id,
      _selectedTeam!.id,
      _selectedVehicleIds,
      missionItems,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phân công thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Phân Công Nhiệm Vụ', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0288D1), Color(0xFF03A9F4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(color: Colors.grey[50]),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Tóm tắt Yêu cầu', Icons.description_outlined),
                    _buildRequestSummary(),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader('1. Chọn Đội Cứu Hộ', Icons.group_outlined),
                    _buildTeamSelector(),
                    const SizedBox(height: 24),
                    
                    if (_selectedTeam != null) ...[
                      _buildSectionHeader(
                        '2. Phân phối Hàng hóa ${_currentWarehouseName != null ? "($_currentWarehouseName)" : ""}', 
                        Icons.inventory_2_outlined
                      ),
                      _buildInventorySelector(),
                      const SizedBox(height: 24),
                      
                      _buildSectionHeader(
                        '3. Chọn Phương tiện ${_currentWarehouseName != null ? "($_currentWarehouseName)" : ""}', 
                        Icons.directions_boat_outlined
                      ),
                      _buildVehicleSelector(),
                      const SizedBox(height: 40),
                    ],
                    
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0288D1)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.emergency, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.citizenName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Text(
                      'Mã yêu cầu: #${widget.request.id.substring(widget.request.id.length - 4).toUpperCase()}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.request.urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.request.urgencyLabel.toUpperCase(),
                  style: TextStyle(color: widget.request.urgencyColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.location_on_outlined, widget.request.address),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.info_outline, widget.request.description),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 14))),
      ],
    );
  }

  Widget _buildTeamSelector() {
    return Column(
      children: _availableTeams.map((team) {
        final isSelected = _selectedTeam?.id == team.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _onTeamSelected(team),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.blue : Colors.transparent),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected ? Colors.blue : Colors.grey[100],
                    child: Icon(Icons.group, color: isSelected ? Colors.white : Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  team.distance != null 
                                    ? '${team.distance!.toStringAsFixed(1)} km' 
                                    : 'N/A', 
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12)
                                ),
                                const SizedBox(width: 8),
                                Text('•', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                const SizedBox(width: 8),
                                Text('Sẵn sàng', style: TextStyle(color: Colors.green[600], fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (team.distance != null && team.id == _availableTeams.first.id && _availableTeams.first.distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('GẦN NHẤT', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                  if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInventorySelector() {
    if (_isLoadingWarehouse) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (_warehouseInventory.isEmpty) {
      return _buildEmptyState('Đội này chưa có hàng hóa trong kho', Icons.inventory_2_outlined);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: _warehouseInventory.map((item) {
          int currentQty = _itemQuantities[item.itemId] ?? 0;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(_getItemIcon(item.itemName), color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Trong kho: ${item.quantity} ${item.unit}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    _buildQuantityControls(item, currentQty),
                  ],
                ),
              ),
              if (item != _warehouseInventory.last) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuantityControls(Inventory item, int currentQty) {
    return Row(
      children: [
        _buildQtyBtn(Icons.remove, () {
          if (currentQty > 0) {
            setState(() => _itemQuantities[item.itemId] = currentQty - 1);
          }
        }),
        Container(
          width: 50,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            controller: TextEditingController(text: currentQty.toString())..selection = TextSelection.fromPosition(TextPosition(offset: currentQty.toString().length)),
            onChanged: (val) {
              int? newQty = int.tryParse(val);
              if (newQty != null) {
                if (newQty > item.quantity) newQty = item.quantity;
                if (newQty < 0) newQty = 0;
                setState(() => _itemQuantities[item.itemId] = newQty!);
              }
            },
          ),
        ),
        _buildQtyBtn(Icons.add, () {
          if (currentQty < item.quantity) {
            setState(() => _itemQuantities[item.itemId] = currentQty + 1);
          }
        }),
      ],
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    if (_filteredVehicles.isEmpty) {
      return _buildEmptyState('Không có phương tiện sẵn sàng', Icons.directions_boat_outlined);
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _filteredVehicles.map((vehicle) {
        final isSelected = _selectedVehicleIds.contains(vehicle.id);
        return InkWell(
          onTap: () {
            if (vehicle.status != 'AVAILABLE' && !isSelected) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Phương tiện này đang ${vehicle.status}. Bạn vẫn muốn chọn?')),
              );
            }
            setState(() {
              if (isSelected) {
                _selectedVehicleIds.remove(vehicle.id);
              } else {
                _selectedVehicleIds.add(vehicle.id);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 52) / 2,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Icon(
                      vehicle.vehicleType.contains('Xuồng') || vehicle.vehicleType.contains('Cano') 
                        ? Icons.directions_boat 
                        : Icons.local_shipping,
                      color: isSelected ? Colors.blue : (vehicle.status == 'AVAILABLE' ? Colors.grey[400] : Colors.orange[300]),
                      size: 40,
                    ),
                    if (isSelected) const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                    if (vehicle.status != 'AVAILABLE' && !isSelected) 
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.warning, color: Colors.orange[400], size: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(vehicle.vehicleType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1),
                Text(vehicle.licensePlate, style: TextStyle(fontSize: 11, color: Colors.grey[600], letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getVehicleStatusColor(vehicle.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getVehicleStatusLabel(vehicle.status),
                    style: TextStyle(fontSize: 9, color: _getVehicleStatusColor(vehicle.status), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitAssignment,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: const Color(0xFF0288D1).withOpacity(0.4),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0288D1), Color(0xFF01579B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text(
                    'XÁC NHẬN PHÂN CÔNG',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                  ),
          ),
        ),
      ),
    );
  }

  IconData _getItemIcon(String name) {
    if (name.contains('Gạo')) return Icons.eco_outlined;
    if (name.contains('Nước')) return Icons.water_drop_outlined;
    if (name.contains('Mì')) return Icons.fastfood_outlined;
    if (name.contains('Áo phao')) return Icons.emergency_outlined;
    return Icons.category_outlined;
  }

  Color _getVehicleStatusColor(String status) {
    switch (status) {
      case 'AVAILABLE': return Colors.green;
      case 'IN_USE': return Colors.blue;
      case 'BUSY': return Colors.orange;
      case 'MAINTENANCE': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getVehicleStatusLabel(String status) {
    switch (status) {
      case 'AVAILABLE': return 'SẴN SÀNG';
      case 'IN_USE': return 'ĐANG ĐI';
      case 'BUSY': return 'ĐANG BẬN';
      case 'MAINTENANCE': return 'BẢO TRÌ';
      default: return status;
    }
  }
}
