import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/api_error_banner.dart';
import 'note_editor_screen.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<NotesProvider>();
    final archived = provider.archivedNotes;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFFAFAF9),
      appBar: AppBar(
        title: const Text('Arsip'),
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFFAFAF9),
        elevation: 0,
      ),
      body: Column(
        children: [
          const ApiErrorBanner(),
          Expanded(
            child: archived.isEmpty
                ? _EmptyArchive(isDark: isDark)
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      itemCount: archived.length,
                      itemBuilder: (context, index) {
                        final note = archived[index];
                        return NoteCard(
                          note: note,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteEditorScreen(note: note),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  final bool isDark;

  const _EmptyArchive({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'Catatan arsip kamu\nakan muncul di sini',
            textAlign: TextAlign.center,
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
