import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillbridge_ai/main.dart';

void main() {
  testWidgets('SkillBridgeApp builds without throwing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SkillBridgeApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
