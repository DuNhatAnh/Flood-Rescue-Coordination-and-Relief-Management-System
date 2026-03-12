import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart'; // Removed as we use Nominatim
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class RescueRequestScreen extends StatefulWidget {
  const RescueRequestScreen({super.key});

  @override
  State<RescueRequestScreen> createState() => _RescueRequestScreenState();
}

class _RescueRequestScreenState extends State<RescueRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _peopleController =
      TextEditingController(text: '1');
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _coordinatesController = TextEditingController();

  LatLng? _currentLocation;
  List<dynamic> _suggestions = [];
  Timer? _debounce;
  String _urgencyLevel = "MEDIUM";
  final List<XFile> _images = [];
  bool _isLoading = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _coordinatesController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _addressController.text = "Dịch vụ định vị bị tắt");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(
            () => _addressController.text = "Quyền truy cập vị trí bị từ chối");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    _updateAddress(LatLng(position.latitude, position.longitude));

    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    setState(() {
      _currentLocation = position;
      _addressController.text = "Đang xác định địa chỉ...";
      _coordinatesController.text =
          "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
    });

    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _addressController.text = data['display_name'] ??
                "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressController.text =
              "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        });
      }
    }
  }

  Future<void> _onAddressChanged(String query) async {
    // Khi người dùng gõ mới, ta xóa tọa độ cũ để đảm bảo tính đồng bộ
    setState(() {
      _currentLocation = null;
      _coordinatesController.text = "";
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _suggestions = []);
        return;
      }

      try {
        final url =
            'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5&addressdetails=1&countrycodes=vn';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          setState(() {
            _suggestions = jsonDecode(response.body);
          });
        }
      } catch (e) {
        // Lỗi autocomplete
      }
    });
  }

  void _selectAddress(dynamic suggestion) {
    final lat = double.tryParse(suggestion['lat']);
    final lon = double.tryParse(suggestion['lon']);
    final address = suggestion['display_name'];

    if (lat != null && lon != null) {
      final position = LatLng(lat, lon);
      setState(() {
        _currentLocation = position;
        _addressController.text = address;
        _coordinatesController.text =
            "${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
        _suggestions = [];
      });
      _mapController.move(position, 15);
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> selectedImages = await picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _images.addAll(selectedImages);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng điền đủ thông tin và định vị vị trí')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/v1/rescue-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'citizenName': _nameController.text,
          'citizenPhone': _phoneController.text,
          'locationLat': _currentLocation!.latitude,
          'locationLng': _currentLocation!.longitude,
          'addressText': _addressController.text,
          'description': _descriptionController.text,
          'urgencyLevel': _urgencyLevel,
          'numberOfPeople': int.tryParse(_peopleController.text) ?? 1,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final requestId = responseData['data']['requestId'];

        for (var image in _images) {
          var uploadRequest = http.MultipartRequest(
            'POST',
            Uri.parse('http://localhost:8080/api/v1/attachments/upload'),
          );
          uploadRequest.fields['requestId'] = requestId.toString();

          final bytes = await image.readAsBytes();
          uploadRequest.files.add(http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: image.name,
          ));

          await uploadRequest.send();
        }

        if (!mounted) return;
        _showSuccessDialog(requestId.toString());
      } else {
        throw Exception('Gửi yêu cầu thất bại');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text("Gửi yêu cầu thành công!",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Yêu cầu của bạn đã được ghi nhận. Vui lòng lưu lại Mã yêu cầu dưới đây để theo dõi tiến trình cứu hộ:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('MÃ THEO DÕI CỦA BẠN',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueAccent,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        requestId,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF01579B),
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              size: 20, color: Colors.blue),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Đã sao chép mã yêu cầu')),
                            );
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Lưu ý: Bạn có thể nhập mã này tại mục 'Theo dõi cứu hộ' trên trang chủ.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to HomeScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("VỀ TRANG CHỦ",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gửi yêu cầu cứu hỗ",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: const Text("SOS",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(Icons.person, "Thông tin người gửi"),
              const SizedBox(height: 10),
              _buildTextField(
                  _nameController, "Họ tên *", "Nhập họ và tên đầy đủ"),
              const SizedBox(height: 10),
              _buildTextField(
                  _phoneController, "Số điện thoại *", "Số điện thoại liên lạc",
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              _buildSectionTitle(Icons.location_on, "Vị trí hiện tại"),
              const SizedBox(height: 10),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          _currentLocation ?? const LatLng(16.047, 108.206),
                      initialZoom: 13,
                      onTap: (tapPosition, point) => _updateAddress(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      if (_currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation!,
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Lấy vị trí hiện tại"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text("Địa chỉ chi tiết (nhập hoặc nhấn vào bản đồ):",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Stack(
                children: [
                  _buildTextField(
                    _addressController,
                    null,
                    "Nhập địa chỉ hoặc chọn trên bản đồ",
                    onChanged: _onAddressChanged,
                  ),
                  if (_suggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              title: Text(suggestion['display_name'],
                                  style: const TextStyle(fontSize: 13)),
                              onTap: () => _selectAddress(suggestion),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Tọa độ (Latitude, Longitude):",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildTextField(
                _coordinatesController,
                null,
                "Chưa có tọa độ",
                readOnly: true,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(Icons.description, "Mô tả tình trạng"),
              const SizedBox(height: 10),
              _buildTextField(_descriptionController, null,
                  "Mô tả tình trạng hiện tại: có bao nhiêu người, có trẻ em/người già không, nước sâu bao nhiêu...",
                  maxLines: 4),
              const SizedBox(height: 24),
              _buildSectionTitle(Icons.group, "Số người đang mắc kẹt"),
              const SizedBox(height: 10),
              _buildTextField(_peopleController, null, "1",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              _buildSectionTitle(Icons.priority_high, "Mức độ khẩn cấp",
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    onPressed: () => _showUrgencyInfo(),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )),
              _buildUrgencyOptions(),
              const SizedBox(height: 24),
              _buildSectionTitle(Icons.camera_alt, "Hình ảnh hiện trường"),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.map((img) => _buildImagePreview(img)),
                  _buildAddImageButton(),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitRequest,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text("GỬI YÊU CẦU CỨU HỘ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                  child: Text(
                      "Thông tin của bạn sẽ được gửi trực tiếp đến trung tâm điều phối cứu nạn.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrgencyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chú thích mức độ khẩn cấp"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUrgencyInfoItem(
                "CAO",
                "Nguy hiểm tính mạng, nước dâng cao nhanh, có người già/trẻ em, không có lương thực.",
                Colors.red),
            const SizedBox(width: 12),
            _buildUrgencyInfoItem(
                "TRUNG BÌNH",
                "Nhà bị ngập nhưng chưa nguy cơ cao, có lương thực ít, cần di dời sớm.",
                Colors.orange),
            const SizedBox(height: 12),
            _buildUrgencyInfoItem(
                "THẤP",
                "Khu vực lân cận ngập, giao thông chia cắt, cần hỗ trợ nhu yếu phẩm.",
                Colors.blue),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"))
        ],
      ),
    );
  }

  Widget _buildUrgencyInfoItem(String title, String desc, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(desc, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String? label, String placeholder,
      {TextInputType? keyboardType,
      int maxLines = 1,
      Function(String)? onChanged,
      bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(label, style: const TextStyle(fontSize: 12))),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Thông tin này là bắt buộc'
              : null,
        ),
      ],
    );
  }

  // Loại bỏ _buildInfoContainer vì không còn dùng

  Widget _buildUrgencyOptions() {
    return Column(
      children: [
        _urgencyTile("Cao (Nguy hiểm tính mạng)", "HIGH"),
        _urgencyTile("Trung bình", "MEDIUM"),
        _urgencyTile("Thấp", "LOW"),
      ],
    );
  }

  Widget _urgencyTile(String title, String value) {
    return RadioListTile<String>(
      title: Text(title,
          style: TextStyle(
              color: value == "HIGH" ? Colors.red : Colors.black,
              fontWeight:
                  value == "HIGH" ? FontWeight.bold : FontWeight.normal)),
      value: value,
      groupValue: _urgencyLevel,
      onChanged: (val) => setState(() => _urgencyLevel = val!),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildImagePreview(XFile image) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Uint8List>(
              future: image.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: GestureDetector(
            onTap: () => setState(() => _images.remove(image)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add_a_photo, color: Colors.grey),
      ),
    );
  }
}
