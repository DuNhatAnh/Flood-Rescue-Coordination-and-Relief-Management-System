import 'package:flutter/material.dart';
import '../../models/distribution.dart';
import '../../services/distribution_service.dart';
import '../../utils/staff_theme.dart';
import 'package:intl/intl.dart';

class DistributionHistoryScreen extends StatefulWidget {
  const DistributionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DistributionHistoryScreen> createState() => _DistributionHistoryScreenState();
}

class _DistributionHistoryScreenState extends State<DistributionHistoryScreen> {
  final DistributionService _service = DistributionService();
  late Future<List<Distribution>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _service.getHistory();
  }

  void _refresh() {
    setState(() {
      _historyFuture = _service.getHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffTheme.background,
      appBar: AppBar(
        title: Text('LỊCH SỬ PHÂN PHỐI', style: StaffTheme.titleLarge),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: StaffTheme.primaryGradient)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Distribution>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: StaffTheme.primaryBlue));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Lỗi khi tải lịch sử', style: StaffTheme.cardSubtitle));
          }

          final history = snapshot.data!;
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text('Chưa có bản ghi phân phối nào', style: StaffTheme.cardSubtitle),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(item.distributedAt);
                final bool isTransfer = item.type == 'TRANSFER';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: StaffTheme.border),
                    boxShadow: StaffTheme.softShadow,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isTransfer ? Colors.orange : StaffTheme.successGreen).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isTransfer ? Icons.swap_horiz_rounded : Icons.outbox_rounded, 
                          color: isTransfer ? Colors.orange : StaffTheme.successGreen
                        ),
                      ),
                      title: Text(
                        isTransfer ? 'Phiếu điều chuyển #${item.id?.substring(0, 6)}' : 'Phiếu cứu trợ #${item.id?.substring(0, 6)}', 
                        style: StaffTheme.cardTitle
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Ngày: $dateStr', style: StaffTheme.cardSubtitle),
                          if (!isTransfer) Text('Mã nhiệm vụ: ${item.requestId.length > 8 ? item.requestId.substring(0, 8) : item.requestId}', style: StaffTheme.cardSubtitle),
                        ],
                      ),
                      children: [
                        const Divider(height: 1),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: StaffTheme.background,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CHI TIẾT VẬT PHẨM MANG ĐI:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: StaffTheme.textLight)),
                              const SizedBox(height: 10),
                              ...item.items.map((goods) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(goods.itemName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text('x${goods.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )).toList(),
                              if (item.items.isEmpty)
                                const Text('Không có thông tin vật phẩm cụ thể', style: TextStyle(fontStyle: FontStyle.italic, color: StaffTheme.textLight, fontSize: 12)),
                              
                              if (!isTransfer) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Hệ thống sẽ tự động đối soát và cộng lại hàng dư vào kho sau khi đội cứu cứu hộ hoàn thành nhiệm vụ.',
                                          style: TextStyle(fontSize: 10, color: Colors.blue, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
