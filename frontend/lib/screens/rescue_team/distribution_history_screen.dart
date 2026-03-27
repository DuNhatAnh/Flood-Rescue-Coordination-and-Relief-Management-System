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
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: StaffTheme.border),
                    boxShadow: StaffTheme.softShadow,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: StaffTheme.successGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.outbox_rounded, color: StaffTheme.successGreen),
                    ),
                    title: Text('Phiếu xuất #${item.id?.substring(0, 6) ?? "N/A"}', style: StaffTheme.cardTitle),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Nhiệm vụ: ${item.requestId}', style: StaffTheme.cardSubtitle),
                        Text('Ngày: $dateStr', style: StaffTheme.cardSubtitle),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: StaffTheme.textLight),
                    onTap: () {},
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
