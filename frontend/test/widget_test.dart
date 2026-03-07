// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flood_rescue_app/main.dart';

void main() {
  testWidgets('Flood Rescue App initial screen test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FloodRescueApp());

    // Verify that our welcome text is present.
    expect(
        find.text(
            'Welcome to Flood Rescue Coordination and Relief Management System'),
        findsOneWidget);

    // Verify that the buttons are present.
    expect(find.text('Gửi yêu cầu cứu hộ'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP (Cho Cán bộ)'), findsOneWidget);
  });
}
