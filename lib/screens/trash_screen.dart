import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/api_error_banner.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<NotesProvider>();
    final deleted = provider.deletedNotes;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF9),
      appBar: AppBar(
        title: const Text('Sampah'),
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF9),
        elevation: 0,
        actions: [
          if (deleted.isNotEmpty)
            TextButton(
              onPressed: () => _confirmEmptyTrash(context, provider),
              child: Text(
                'Kosongkan sampah',
                style: TextStyle(
                  color: isDark ? Colors.red[300] : Colors.red,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const ApiErrorBanner(),
          Expanded(
            child: deleted.isEmpty
                ? _EmptyTrash(isDark: isDark)
                : Column(
                    children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Catatan di sampah akan dihapus otomatis setelah 7 hari',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                          ],
                        ),
          ),
        ],
      ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      itemCount: deleted.length,
                      itemBuilder: (context, index) {
                        final note = deleted[index];
                        return _TrashNoteCard(note: note, isDark: isDark);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan sampah?'),
        content: const Text(
            'Semua catatan di sampah akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.emptyTrash();
            },
            child: Text(
              'Kosongkan',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashNoteCard extends StatelessWidget {
  final Note note;
  final bool isDark;

  const _TrashNoteCard({required this.note, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotesProvider>();

    return Stack(
      children: [
        NoteCard(
          note: note,
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('Pulihkan'),
                      onTap: () {
                        Navigator.pop(context);
                        provider.restoreFromTrash(note.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Catatan dipulihkan'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_outlined),
                      title: const Text('Hapus permanen'),
                      onTap: () {
                        Navigator.pop(context);
                        provider.deleteNotePermanently(note.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyTrash extends StatelessWidget {
  final bool isDark;

  const _EmptyTrash({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada catatan di sampah',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
