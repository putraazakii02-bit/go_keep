import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';
import '../services/notes_api.dart';

class NotesProvider extends ChangeNotifier {
  static const String _legacyStorageKey = 'go_keep_notes';

  NotesProvider({NotesApi? api}) : _api = api ?? NotesApi() {
    loadNotes();
  }

  final NotesApi _api;

  List<Note> _notes = [];
  bool _isGridView = true;
  bool _isLoading = false;
  String _searchQuery = '';
  List<String> _allLabels = [];
  String? _errorMessage;

  List<Note> get allNotes => _notes;
  bool get isGridView => _isGridView;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  List<String> get allLabels => _allLabels;
  String? get errorMessage => _errorMessage;
  List<Note> get reminderNotes => _notes
      .where((note) =>
          note.reminderAt != null && !note.isDeleted && !note.isArchived)
      .toList()
    ..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));

  List<Note> get activeNotes =>
      _notes.where((n) => !n.isArchived && !n.isDeleted).toList()..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

  List<Note> get pinnedNotes => activeNotes.where((n) => n.isPinned).toList();

  List<Note> get unpinnedNotes =>
      activeNotes.where((n) => !n.isPinned).toList();

  List<Note> get archivedNotes =>
      _notes.where((n) => n.isArchived && !n.isDeleted).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<Note> get deletedNotes =>
      _notes.where((n) => n.isDeleted).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _notes
        .where(
          (n) =>
              !n.isDeleted &&
              (n.title.toLowerCase().contains(q) ||
                  n.content.toLowerCase().contains(q) ||
                  n.labels.any((l) => l.toLowerCase().contains(q))),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Note> notesByLabel(String label) =>
      _notes
          .where(
            (n) => !n.isDeleted && !n.isArchived && n.labels.contains(label),
          )
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> loadNotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _notes = await _api.getNotes();
      _refreshLabels();
      try {
        await _migrateLocalNotes();
      } catch (error) {
        _errorMessage =
            'Catatan lokal belum berhasil dipindahkan ke server: $error';
      }
    } catch (error) {
      _errorMessage = 'Gagal memuat catatan dari server: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _migrateLocalNotes() async {
    final preferences = await SharedPreferences.getInstance();
    final storedNotes = preferences.getString(_legacyStorageKey);
    if (storedNotes == null) return;

    final notes = (jsonDecode(storedNotes) as List<dynamic>)
        .map((item) => Note.fromJson(item as Map<String, dynamic>))
        .toList();
    if (notes.isNotEmpty) {
      await _api.importNotes(notes);
      _notes = await _api.getNotes();
      _refreshLabels();
    }
    await preferences.remove(_legacyStorageKey);
  }

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      _errorMessage = null;
      return result;
    } catch (error) {
      _errorMessage = 'Gagal menyimpan perubahan ke server: $error';
      notifyListeners();
      rethrow;
    }
  }

  void _refreshLabels() {
    final Set<String> labels = {};
    for (final note in _notes) {
      labels.addAll(note.labels);
    }
    _allLabels = labels.toList()..sort();
  }

  Future<Note> addNote({
    String title = '',
    String content = '',
    String? color,
    List<String>? labels,
    DateTime? reminderAt,
    bool isPinned = false,
    bool isArchived = false,
  }) async {
    final note = Note(
      id: '',
      title: title,
      content: content,
      color: color,
      labels: labels ?? [],
      reminderAt: reminderAt,
      isPinned: isPinned,
      isArchived: isArchived,
    );
    final created = await _request(() => _api.createNote(note));
    _notes.insert(0, created);
    _refreshLabels();
    notifyListeners();
    return created;
  }

  Future<void> updateNote(Note updatedNote) async {
    final index = _notes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      final updated = updatedNote.copyWith(updatedAt: DateTime.now());
      _notes[index] = await _request(() => _api.updateNote(updated));
      _refreshLabels();
      notifyListeners();
    }
  }

  Future<void> deleteNotePermanently(String id) async {
    await _request(() => _api.deleteNote(id));
    _notes.removeWhere((n) => n.id == id);
    _refreshLabels();
    notifyListeners();
  }

  Future<void> moveToTrash(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = await _request(
        () => _api.patchNote(id, {
          'isDeleted': true,
          'isPinned': false,
          'isArchived': false,
        }),
      );
      notifyListeners();
    }
  }

  Future<void> restoreFromTrash(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = await _request(
        () => _api.patchNote(id, {'isDeleted': false}),
      );
      notifyListeners();
    }
  }

  Future<void> emptyTrash() async {
    await _request(() => _api.emptyTrash());
    _notes.removeWhere((n) => n.isDeleted);
    notifyListeners();
  }

  Future<void> setReminder(String id, DateTime? reminderAt) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return;

    final changes = <String, dynamic>{
      'reminderAt': reminderAt?.toIso8601String(),
    };
    _notes[index] = await _request(() => _api.patchNote(id, changes));
    notifyListeners();
  }

  Future<void> renameLabel(String oldName, String newName) async {
    _allLabels = await _request(() => _api.renameLabel(oldName, newName));
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].labels.contains(oldName)) {
        final labels = _notes[i].labels
            .map((label) => label == oldName ? newName : label)
            .toList();
        _notes[i] = _notes[i].copyWith(labels: labels);
      }
    }
    notifyListeners();
  }

  Future<void> deleteLabel(String name) async {
    await _request(() => _api.deleteLabel(name));
    _allLabels.remove(name);
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].labels.contains(name)) {
        _notes[i] = _notes[i].copyWith(
          labels: _notes[i].labels.where((label) => label != name).toList(),
        );
      }
    }
    notifyListeners();
  }

  Future<void> archiveNote(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = await _request(
        () => _api.patchNote(id, {'isArchived': true, 'isPinned': false}),
      );
      notifyListeners();
    }
  }

  Future<void> unarchiveNote(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = await _request(
        () => _api.patchNote(id, {'isArchived': false}),
      );
      notifyListeners();
    }
  }

  Future<void> togglePin(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = await _request(
        () => _api.patchNote(id, {'isPinned': !_notes[index].isPinned}),
      );
      notifyListeners();
    }
  }

  Future<void> changeColor(String id, String? colorHex) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index] = await _request(
        () => _api.patchNote(id, {'color': colorHex}),
      );
      notifyListeners();
    }
  }

  Future<void> addLabel(String id, String label) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1 && !_notes[index].labels.contains(label)) {
      final updatedLabels = List<String>.from(_notes[index].labels)..add(label);
      _notes[index] = await _request(
        () => _api.patchNote(id, {'labels': updatedLabels}),
      );
      _refreshLabels();
      notifyListeners();
    }
  }

  Future<void> removeLabel(String id, String label) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final updatedLabels = List<String>.from(_notes[index].labels)
        ..remove(label);
      _notes[index] = await _request(
        () => _api.patchNote(id, {'labels': updatedLabels}),
      );
      _refreshLabels();
      notifyListeners();
    }
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
