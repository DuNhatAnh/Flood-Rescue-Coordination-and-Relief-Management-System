import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  LatLng? _currentLocation;
  String _addressText = "Đang lấy vị trí...";
  String _urgencyLevel = "MEDIUM";
  final List<XFile> _images = [];
  bool _isLoading = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _addressText = "Dịch vụ định vị bị tắt");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _addressText = "Quyền truy cập vị trí bị từ chối");
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
      _addressText = "Đang xác định địa chỉ...";
    });

    String address =
        "Vị trí: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    try {
      // Lưu ý: Geocoding trên Web có thể cần API Key nếu chạy native.
      // Nhưng ta vẫn giữ logic để dự phòng hoặc khi chạy trên Mobile/Emulator.
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address =
            "${place.street}, ${place.subAdministrativeArea}, ${place.administrativeArea}";
      }
    } catch (e) {
      // Fallback nếu geocoding lỗi
    }

    setState(() {
      _addressText = address;
    });
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
          'addressText': _addressText,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi yêu cầu thành công!')),
        );
        Navigator.pop(context);
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
              const Text("Địa chỉ chi tiết (nhấn vào bản đồ để chọn):",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _buildInfoContainer(_addressText),
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
      {TextInputType? keyboardType, int maxLines = 1}) {
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
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.grey[50],
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

  Widget _buildInfoContainer(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50]?.withAlpha(76), // 0.3 * 255 approx 76
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

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
