import 'package:flutter_test/flutter_test.dart';

import 'package:dormigo/main.dart';

void main() {
  testWidgets('shows the Dormigo splash screen', (tester) async {
    await tester.pumpWidget(const DormigoApp());

    expect(find.text('Dormigo'), findsOneWidget);
    expect(find.text('Cook Smart. Waste Less.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
