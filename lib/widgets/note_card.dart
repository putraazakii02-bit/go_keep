import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../utils/note_colors.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = NoteColors.cardColor(note.color, isDark);
    final hasColor = note.color != null;
    final textColor = isDark || !hasColor
        ? Theme.of(context).colorScheme.onSurface
        : Colors.black87;
    final subTextColor = textColor.withOpacity(0.7);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasColor
                ? Colors.transparent
                : (isDark
                    ? Colors.white24
                    : Colors.black12),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pin indicator
              if (note.isPinned) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.push_pin, size: 16, color: subTextColor),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              // Title
              if (note.title.isNotEmpty) ...[
                Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
                  ),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.content.isNotEmpty) const SizedBox(height: 4),
              ],
              // Content
              if (note.content.isNotEmpty)
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: subTextColor,
                    height: 1.4,
                  ),
                  maxLines: 12,
                  overflow: TextOverflow.ellipsis,
                ),
              // Labels
              if (note.labels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: note.labels.map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // Bottom action row
              const SizedBox(height: 4),
              _NoteCardActions(note: note, textColor: subTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCardActions extends StatelessWidget {
  final Note note;
  final Color textColor;

  const _NoteCardActions({required this.note, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotesProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _ActionIcon(
          icon: note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          color: textColor,
          onTap: () => provider.togglePin(note.id),
          tooltip: note.isPinned ? 'Unpin' : 'Pin',
        ),
        _ActionIcon(
          icon: note.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          color: textColor,
          onTap: () {
            if (note.isArchived) {
              provider.unarchiveNote(note.id);
            } else {
              provider.archiveNote(note.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Note archived'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => provider.unarchiveNote(note.id),
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          tooltip: note.isArchived ? 'Unarchive' : 'Archive',
        ),
        _ActionIcon(
          icon: Icons.more_vert,
          color: textColor,
          onTap: () => _showMoreOptions(context, provider),
          tooltip: 'More',
        ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context, NotesProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete note'),
                onTap: () {
                  Navigator.pop(context);
                  provider.moveToTrash(note.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Note moved to trash'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => provider.restoreFromTrash(note.id),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Make a copy'),
                onTap: () {
                  Navigator.pop(context);
                  provider.addNote(
                    title: note.title.isEmpty ? '' : '${note.title} (copy)',
                    content: note.content,
                    color: note.color,
                    labels: List.from(note.labels),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
