import 'package:flutter_test/flutter_test.dart';
import 'package:flutterpy/main.dart';

void main() {
  testWidgets('BioPython app renders app bar title', (tester) async {
    await tester.pumpWidget(const BioTechApp());
    expect(find.text('BioPython Sequence Analysis'), findsOneWidget);
  });

  testWidgets('BioPython screen shows idle status chip before processing', (
    tester,
  ) async {
    await tester.pumpWidget(const BioTechApp());
    expect(find.text('Idle'), findsOneWidget);
  });

  testWidgets('Protein analysis button is present', (tester) async {
    await tester.pumpWidget(const BioTechApp());
    expect(find.text('Analyze Protein'), findsOneWidget);
  });
}
