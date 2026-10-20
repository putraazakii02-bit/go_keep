import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/note.dart';

class NotesApiException implements Exception {
  final int statusCode;
  final String message;

  const NotesApiException(this.statusCode, this.message);

  @override
  String toString() => 'HTTP $statusCode: $message';
}

class NotesApi {
  NotesApi({http.BaseClient? client, Uri? baseUri})
    : _client = client ?? _ClientAdapter(http.Client()),
      _baseUri =
          baseUri ??
          Uri.parse(
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000/api',
            ),
          );

  static const _timeout = Duration(seconds: 15);

  final http.BaseClient _client;
  final Uri _baseUri;

  Future<List<Note>> getNotes() async {
    final payload = await _request('GET', 'notes');
    final data = _data(payload);
    if (data is! List<dynamic>) {
      throw const FormatException('API tidak mengembalikan daftar catatan.');
    }

    return data.map((item) => Note.fromJson(_noteMap(item))).toList();
  }

  Future<Note> createNote(Note note) async {
    final payload = await _request('POST', 'notes', _writePayload(note));
    return Note.fromJson(_noteMap(_data(payload)));
  }

  Future<void> importNotes(List<Note> notes) async {
    await _request('POST', 'notes/import', {
      'notes': notes
          .map((note) => _writePayload(note)..['id'] = note.id)
          .toList(),
    });
  }

  Future<Note> updateNote(Note note) async {
    final payload = await _request(
      'PUT',
      'notes/${note.id}',
      _writePayload(note),
    );
    return Note.fromJson(_noteMap(_data(payload)));
  }

  Future<Note> patchNote(String id, Map<String, dynamic> changes) async {
    final payload = await _request('PATCH', 'notes/$id', changes);
    return Note.fromJson(_noteMap(_data(payload)));
  }

  Future<void> deleteNote(String id) async {
    await _request('DELETE', 'notes/$id');
  }

  Future<void> emptyTrash() async {
    await _request('DELETE', 'notes/trash');
  }

  Future<List<String>> getLabels() async {
    final data = _data(await _request('GET', 'labels'));
    if (data is! List<dynamic>) {
      throw const FormatException('API tidak mengembalikan daftar label.');
    }
    return data.cast<String>();
  }

  Future<List<String>> renameLabel(String oldName, String newName) async {
    final data = _data(await _request('PATCH', 'labels', {
      'oldName': oldName,
      'newName': newName,
    }));
    if (data is! List<dynamic>) {
      throw const FormatException('API tidak mengembalikan daftar label.');
    }
    return data.cast<String>();
  }

  Future<void> deleteLabel(String name) async {
    await _request('DELETE', 'labels?name=${Uri.encodeQueryComponent(name)}');
  }

  Future<dynamic> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final basePath = _baseUri.path.replaceFirst(RegExp(r'/+$'), '');
    final endpoint = Uri.parse(path);
    final uri = endpoint.hasQuery
        ? _baseUri.replace(
            path: '$basePath/${endpoint.path}',
            queryParameters: endpoint.queryParameters,
          )
        : _baseUri.replace(path: '$basePath/${endpoint.path}');
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamed).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = response.body.trim();
      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        final errorPayload = jsonDecode(response.body);
        if (errorPayload is Map<String, dynamic> &&
            errorPayload['message'] is String) {
          message = errorPayload['message'] as String;
        }
      }
      throw NotesApiException(response.statusCode, message);
    }

    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  dynamic _data(dynamic payload) {
    if (payload is! Map<String, dynamic> || !payload.containsKey('data')) {
      throw const FormatException('Format respons API tidak valid.');
    }
    return payload['data'];
  }

  Map<String, dynamic> _noteMap(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'API tidak mengembalikan catatan yang valid.',
      );
    }
    return value;
  }

  Map<String, dynamic> _writePayload(Note note) => {
    'title': note.title,
    'content': note.content,
    'color': note.color,
    'isPinned': note.isPinned,
    'isArchived': note.isArchived,
    'isDeleted': note.isDeleted,
    'labels': note.labels,
    'reminderAt': note.reminderAt?.toIso8601String(),
  };
}

class _ClientAdapter extends http.BaseClient {
  _ClientAdapter(this._client);

  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _client.send(request);

  @override
  void close() => _client.close();
}
