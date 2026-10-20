import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_keep/models/note.dart';
import 'package:go_keep/services/notes_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads notes from the configured API base path', () async {
    final api = NotesApi(
      baseUri: Uri.parse('http://localhost:8000/api/'),
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url, Uri.parse('http://localhost:8000/api/notes'));
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'note-id',
                'title': 'Belanja',
                'content': 'Kopi',
                'isPinned': false,
                'isArchived': true,
                'isDeleted': false,
                'labels': ['Rumah'],
                'createdAt': '2026-10-16T00:00:00.000000Z',
                'updatedAt': '2026-10-16T00:00:00.000000Z',
              },
            ],
          }),
          200,
        );
      }),
    );

    final notes = await api.getNotes();

    expect(notes, hasLength(1));
    expect(notes.single, isA<Note>());
    expect(notes.single.title, 'Belanja');
    expect(notes.single.isArchived, isTrue);
    expect(notes.single.labels, ['Rumah']);
  });

  test('surfaces API error status and message', () async {
    final api = NotesApi(
      baseUri: Uri.parse('http://localhost:8000/api'),
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({'message': 'Tidak ditemukan'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await expectLater(
      api.getNotes(),
      throwsA(
        isA<NotesApiException>()
            .having((error) => error.statusCode, 'statusCode', 404)
            .having((error) => error.message, 'message', 'Tidak ditemukan'),
      ),
    );
  });

  test('encodes label deletion query parameters correctly', () async {
    final api = NotesApi(
      baseUri: Uri.parse('http://localhost:8000/api'),
      client: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url,
          Uri.parse('http://localhost:8000/api/labels?name=Rumah+%26+Kebun'),
        );
        return http.Response('', 204);
      }),
    );

    await api.deleteLabel('Rumah & Kebun');
  });
}
