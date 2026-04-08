import 'package:flutter/material.dart';
import '../utils/staff_theme.dart';

class MissionStepper extends StatelessWidget {
  final String currentStatus;

  const MissionStepper({Key? key, required this.currentStatus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'id': 'ASSIGNED', 'label': 'Đã gán'},
      {'id': 'PREPARING', 'label': 'Chuẩn bị'},
      {'id': 'MOVING', 'label': 'Di chuyển'},
      {'id': 'RESCUING', 'label': 'Tại chỗ'},
      {'id': 'RETURNING', 'label': 'Đang về'},
      {'id': 'COMPLETED', 'label': 'Xong'},
    ];

    int currentIndex = steps.indexWhere((s) => s['id'] == currentStatus.toUpperCase());
    if (currentIndex == -1) {
      String status = currentStatus.toUpperCase();
      if (status == 'IN_PROGRESS') {
        currentIndex = 1;
      } else if (status == 'REPORTED') currentIndex = 5; // Hoàn thành bước 'Đang về', đang chờ 'Xong'
      else currentIndex = 0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: StaffTheme.softShadow,
        border: Border.all(color: StaffTheme.border),
      ),
      child: Column(
        children: [
          const Text(
            'LỘ TRÌNH NHIỆM VỤ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: StaffTheme.textLight,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isEven) {
                int stepIndex = index ~/ 2;
                bool isCompleted = stepIndex < currentIndex;
                bool isActive = stepIndex == currentIndex;
                
                return _buildStepCircle(
                  steps[stepIndex]['label']!, 
                  isCompleted, 
                  isActive
                );
              } else {
                int lineIndex = index ~/ 2;
                bool isCompletedLine = lineIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompletedLine ? StaffTheme.successGreen : Colors.grey.shade200,
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(String label, bool isCompleted, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted 
                ? StaffTheme.successGreen 
                : (isActive ? StaffTheme.primaryBlue : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted 
                  ? StaffTheme.successGreen 
                  : (isActive ? StaffTheme.primaryBlue : Colors.grey.shade300),
              width: 2,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: StaffTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '', // Empty for isActive or pending
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isActive ? StaffTheme.primaryBlue : (isCompleted ? StaffTheme.successGreen : StaffTheme.textLight),
          ),
        ),
      ],
    );
  }
}
