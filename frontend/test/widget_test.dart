import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('SignBoard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SignBoardApp());

    // Verify that SignBoard title renders on splash
    expect(find.text('SignBoard'), findsOneWidget);
  });
}
