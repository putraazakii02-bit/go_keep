import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../utils/note_colors.dart';
import '../widgets/api_error_banner.dart';
import '../widgets/note_color_picker.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final bool startAsChecklist;

  const NoteEditorScreen({
    super.key,
    this.note,
    this.startAsChecklist = false,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteSnapshot {
  const _NoteSnapshot(this.title, this.content);

  final String title;
  final String content;

  @override
  bool operator ==(Object other) =>
      other is _NoteSnapshot &&
      other.title == title &&
      other.content == content;

  @override
  int get hashCode => Object.hash(title, content);
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocus;
  String? _colorHex;
  bool _isPinned = false;
  bool _isArchived = false;
  List<String> _labels = [];
  bool _hasChanges = false;
  String? _noteId;
  bool _showColorPicker = false;
  DateTime? _reminderAt;
  final List<_NoteSnapshot> _undoHistory = [];
  final List<_NoteSnapshot> _redoHistory = [];
  late _NoteSnapshot _lastSnapshot;
  bool _applyingHistory = false;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(
      text: note?.content ?? (widget.startAsChecklist ? '- [ ] ' : ''),
    );
    _contentFocus = FocusNode();
    _colorHex = note?.color;
    _isPinned = note?.isPinned ?? false;
    _isArchived = note?.isArchived ?? false;
    _labels = List.from(note?.labels ?? []);
    _reminderAt = note?.reminderAt;
    _noteId = note?.id;
    _lastSnapshot = _currentSnapshot;

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    _titleController.addListener(_recordTextHistory);
    _contentController.addListener(_recordTextHistory);

    if (note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _contentFocus.requestFocus();
      });
    }
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  _NoteSnapshot get _currentSnapshot => _NoteSnapshot(
        _titleController.text,
        _contentController.text,
      );

  void _recordTextHistory() {
    if (_applyingHistory) return;
    final current = _currentSnapshot;
    if (current == _lastSnapshot) return;
    _undoHistory.add(_lastSnapshot);
    if (_undoHistory.length > 100) _undoHistory.removeAt(0);
    _redoHistory.clear();
    _lastSnapshot = current;
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _applySnapshot(_NoteSnapshot snapshot) {
    _applyingHistory = true;
    _titleController.value = TextEditingValue(
      text: snapshot.title,
      selection: TextSelection.collapsed(offset: snapshot.title.length),
    );
    _contentController.value = TextEditingValue(
      text: snapshot.content,
      selection: TextSelection.collapsed(offset: snapshot.content.length),
    );
    _applyingHistory = false;
    _lastSnapshot = snapshot;
    setState(() => _hasChanges = true);
  }

  void _undo() {
    if (_undoHistory.isEmpty) return;
    _redoHistory.add(_currentSnapshot);
    _applySnapshot(_undoHistory.removeLast());
  }

  void _redo() {
    if (_redoHistory.isEmpty) return;
    _undoHistory.add(_currentSnapshot);
    _applySnapshot(_redoHistory.removeLast());
  }

  void _insertChecklistItem() {
    final value = _contentController.value;
    final selection = value.selection;
    final start = selection.start < 0 ? value.text.length : selection.start;
    final end = selection.end < 0 ? start : selection.end;
    final prefix = start == 0 || value.text.substring(0, start).endsWith('\n')
        ? ''
        : '\n';
    final text = value.text.replaceRange(start, end, '$prefix- [ ] ');
    final cursor = start + prefix.length + 6;
    _contentController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
    _contentFocus.requestFocus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final provider = context.read<NotesProvider>();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      // If new note with no content, don't save
      if (_noteId == null) return;
    }

    if (_noteId != null) {
      // Update existing note
      final existing = provider.allNotes.firstWhere((n) => n.id == _noteId!);
      await provider.updateNote(
        existing.copyWith(
          title: title,
          content: content,
          color: _colorHex,
          clearColor: _colorHex == null,
          isPinned: _isPinned,
          isArchived: _isArchived,
          labels: _labels,
          reminderAt: _reminderAt,
          clearReminder: _reminderAt == null,
        ),
      );
    } else if (title.isNotEmpty || content.isNotEmpty) {
      // Create new note
      final newNote = await provider.addNote(
        title: title,
        content: content,
        color: _colorHex,
        labels: _labels,
        reminderAt: _reminderAt,
        isPinned: _isPinned,
        isArchived: _isArchived,
      );
      _noteId = newNote.id;
    }
  }

  Future<void> _onBack() async {
    await _saveNote();
    if (mounted) Navigator.pop(context);
  }

  Color get _bgColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NoteColors.cardColor(_colorHex, isDark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _bgColor;
    final textColor = isDark
        ? Colors.white
        : (bg == Colors.white ? Colors.black87 : Colors.black87);
    final hintColor = textColor.withOpacity(0.5);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _saveNote();
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: textColor,
            onPressed: _onBack,
          ),
          actions: [
            // Pin button
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: textColor,
              ),
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                  _hasChanges = true;
                });
              },
              tooltip: _isPinned ? 'Unpin' : 'Pin',
            ),
            // Archive button
            IconButton(
              icon: Icon(
                _isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                color: textColor,
              ),
              onPressed: () {
                setState(() {
                  _isArchived = !_isArchived;
                  _hasChanges = true;
                });
                _saveNote();
              },
              tooltip: _isArchived ? 'Unarchive' : 'Archive',
            ),
            IconButton(
              icon: Icon(
                _reminderAt == null
                    ? Icons.notifications_none_outlined
                    : Icons.notifications_active_outlined,
                color: textColor,
              ),
              onPressed: _chooseReminder,
              tooltip: 'Pengingat',
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textColor),
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteNote();
                    break;
                  case 'copy':
                    _copyNote();
                    break;
                  case 'label':
                    _showLabelDialog();
                    break;
                  case 'clearReminder':
                    _clearReminder();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 12),
                      Text('Hapus'),
                    ],
                  ),
                ),
                if (_reminderAt != null)
                  const PopupMenuItem(
                    value: 'clearReminder',
                    child: Row(
                      children: [
                        Icon(Icons.notifications_off_outlined),
                        SizedBox(width: 12),
                        Text('Hapus pengingat'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_outlined),
                      SizedBox(width: 12),
                      Text('Salin'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'label',
                  child: Row(
                    children: [
                      Icon(Icons.label_outline),
                      SizedBox(width: 12),
                      Text('Label'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            const ApiErrorBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Judul',
                        hintStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: hintColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _contentFocus.requestFocus(),
                    ),
                    // Content
                    TextField(
                      controller: _contentController,
                      focusNode: _contentFocus,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Catatan',
                        hintStyle: TextStyle(fontSize: 16, color: hintColor),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                    // Labels display
                    if (_labels.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _labels.map((label) {
                          return Chip(
                            label: Text(
                              label,
                              style: TextStyle(fontSize: 12, color: textColor),
                            ),
                            backgroundColor: textColor.withOpacity(0.1),
                            deleteIcon: Icon(
                              Icons.close,
                              size: 14,
                              color: textColor,
                            ),
                            onDeleted: () {
                              setState(() {
                                _labels.remove(label);
                                _hasChanges = true;
                              });
                            },
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Color picker
            if (_showColorPicker)
              Container(
                decoration: BoxDecoration(
                  color: bg,
                  border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                ),
                child: NoteColorPicker(
                  selectedColorHex: _colorHex,
                  onColorSelected: (hex) {
                    setState(() {
                      _colorHex = hex;
                      _hasChanges = true;
                    });
                  },
                ),
              ),
            // Bottom toolbar
            _buildBottomToolbar(context, textColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(
    BuildContext context,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3))),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 8,
      ),
      child: Row(
        children: [
          // Color button
          IconButton(
            icon: Icon(Icons.palette_outlined, color: textColor),
            onPressed: () {
              setState(() => _showColorPicker = !_showColorPicker);
            },
            tooltip: 'Warna catatan',
          ),
          // Add item button
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: textColor),
            onPressed: _insertChecklistItem,
            tooltip: 'Tambah item checklist',
          ),
          const Spacer(),
          // Edited text
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Diedit',
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5)),
            ),
          ),
          // Undo/redo
          IconButton(
            icon: Icon(Icons.undo, color: textColor.withOpacity(0.7)),
            onPressed: _undoHistory.isEmpty ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: Icon(Icons.redo, color: textColor.withOpacity(0.7)),
            onPressed: _redoHistory.isEmpty ? null : _redo,
            tooltip: 'Redo',
          ),
        ],
      ),
    );
  }

  Future<void> _chooseReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate:
          _reminderAt != null && _reminderAt!.isAfter(now) ? _reminderAt! : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _reminderAt == null
          ? TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)))
          : TimeOfDay.fromDateTime(_reminderAt!),
    );
    if (time == null || !mounted) return;

    final reminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!reminder.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu pengingat harus di masa depan.')),
      );
      return;
    }
    setState(() {
      _reminderAt = reminder;
      _hasChanges = true;
    });
    await _saveNote();
  }

  Future<void> _clearReminder() async {
    setState(() {
      _reminderAt = null;
      _hasChanges = true;
    });
    if (_noteId != null) {
      await context.read<NotesProvider>().setReminder(_noteId!, null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengingat dihapus')),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    final provider = context.read<NotesProvider>();
    if (_noteId != null) {
      await provider.moveToTrash(_noteId!);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Catatan dihapus'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (_noteId != null) provider.restoreFromTrash(_noteId!);
            },
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyNote() async {
    final provider = context.read<NotesProvider>();
    await provider.addNote(
      title: _titleController.text.isEmpty
          ? ''
          : '${_titleController.text} (copy)',
      content: _contentController.text,
      color: _colorHex,
      labels: List.from(_labels),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showLabelDialog() async {
    final TextEditingController labelController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah label'),
        content: TextField(
          controller: labelController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama label',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final label = labelController.text.trim();
              if (label.isNotEmpty && !_labels.contains(label)) {
                setState(() {
                  _labels.add(label);
                  _hasChanges = true;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    labelController.dispose();
  }
}
