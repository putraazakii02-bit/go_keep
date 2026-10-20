import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_keep/main.dart';
import 'package:go_keep/providers/notes_provider.dart';

void main() {
  testWidgets('GoKeep smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NotesProvider(),
        child: const GoKeepApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
