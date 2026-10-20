import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_keep/providers/notes_provider.dart';
import 'package:go_keep/screens/home_screen.dart';
import 'package:go_keep/screens/reminders_screen.dart';
import 'package:go_keep/services/notes_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

void main() {
  late NotesApi api;

  setUp(() {
    api = NotesApi(
      baseUri: Uri.parse('http://localhost:8000/api'),
      client: MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/notes') {
          return http.Response(jsonEncode({'data': []}), 200);
        }
        return http.Response('', 204);
      }),
    );
  });

  testWidgets('profile avatar opens backend status dialog', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NotesProvider(api: api),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('A'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('GoKeep'), findsOneWidget);
    expect(find.text('Periksa koneksi'), findsOneWidget);
  });

  testWidgets('reminders tab opens the reminders screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NotesProvider(api: api),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final reminderText = find.text('Pengingat').last;
    final tabButton = find.ancestor(
      of: reminderText,
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(tabButton).onPressed, isNotNull);
    tester.widget<TextButton>(tabButton).onPressed!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isTrue);

    expect(find.byType(RemindersScreen), findsOneWidget);
    expect(find.text('Belum ada pengingat'), findsOneWidget);
  });
}
