import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../screens/labels_screen.dart';
import '../screens/archive_screen.dart';
import '../screens/trash_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/labels_management_screen.dart';
import '../widgets/app_info_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final labels = provider.allLabels;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAF9),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Keep',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Notes
                  _DrawerItem(
                    icon: Icons.lightbulb_outline,
                    label: 'Catatan',
                    iconColor: iconColor,
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_none_outlined,
                    label: 'Pengingat',
                    iconColor: iconColor,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RemindersScreen(),
                        ),
                      );
                    },
                  ),
                  // Labels section
                  if (labels.isNotEmpty) ...[
                    const Divider(height: 1),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Label',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                    ...labels.map(
                      (label) => _DrawerItem(
                        icon: Icons.label_outline,
                        label: label,
                        iconColor: iconColor,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LabelsScreen(label: label),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  // Edit labels
                  _DrawerItem(
                    icon: Icons.edit_outlined,
                    label: 'Edit label',
                    iconColor: iconColor,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LabelsManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  // Archive
                  _DrawerItem(
                    icon: Icons.archive_outlined,
                    label: 'Arsip',
                    iconColor: iconColor,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ArchiveScreen()),
                      );
                    },
                  ),
                  // Trash
                  _DrawerItem(
                    icon: Icons.delete_outline,
                    label: 'Sampah',
                    iconColor: iconColor,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TrashScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Pengaturan',
                    iconColor: iconColor,
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => const AppInfoDialog(),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    label: 'Bantuan & masukan',
                    iconColor: iconColor,
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Bantuan GoKeep'),
                          content: const Text(
                            'Buat catatan dengan tombol Catatan baru. '
                            'Gunakan ikon pin untuk menyematkan, arsip untuk '
                            'menyimpan catatan, label untuk mengelompokkan, '
                            'dan ikon lonceng untuk mengatur pengingat. '
                            'Catatan tersimpan ke backend yang dikonfigurasi.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Mengerti'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? const Color(0xDEFFFFFF) : const Color(0xDD000000),
        ),
      ),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 8,
    );
  }
}
