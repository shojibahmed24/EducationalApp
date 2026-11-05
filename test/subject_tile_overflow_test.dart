// Widget tests for Batch 2, item 2: the home subject grid must
// never paint text outside a card, even with the longest real
// Bangla subject names at 320px width and at a larger font scale.
// The grid row pattern (IntrinsicHeight + stretch) is pumped here
// exactly as HomeSubjectGrid builds it; any overflow surfaces as
// a FlutterError via takeException.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/home/widgets/home_subject_tile.dart';

Widget rowOfTiles() => const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: HomeSubjectTile(
              name: 'বাংলাদেশ ও বিশ্বপরিচয়',
              chaptersLabel: '১১টি অধ্যায়',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: HomeSubjectTile(
              name: 'তথ্য ও যোগাযোগ প্রযুক্তি',
              chaptersLabel: '৫টি অধ্যায়',
            ),
          ),
        ],
      ),
    );

void main() {
  testWidgets('longest subject names do not overflow at 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: rowOfTiles())),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('বাংলাদেশ ও বিশ্বপরিচয়'), findsOneWidget);
    expect(find.text('তথ্য ও যোগাযোগ প্রযুক্তি'), findsOneWidget);
    expect(find.text('১১টি অধ্যায়'), findsOneWidget);
    expect(find.text('৫টি অধ্যায়'), findsOneWidget);
  });

  testWidgets('longest subject names do not overflow at 1.3x font scale',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: rowOfTiles(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('১১টি অধ্যায়'), findsOneWidget);
    expect(find.text('৫টি অধ্যায়'), findsOneWidget);
  });
}
