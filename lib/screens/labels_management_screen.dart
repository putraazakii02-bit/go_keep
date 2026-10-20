import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notes_provider.dart';
import '../widgets/api_error_banner.dart';

class LabelsManagementScreen extends StatelessWidget {
  const LabelsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = context.watch<NotesProvider>().allLabels;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit label')),
      body: Column(
        children: [
          const ApiErrorBanner(),
          Expanded(
            child: labels.isEmpty
                ? const Center(child: Text('Belum ada label untuk diedit'))
                : ListView(
                    children: labels
                        .map(
                          (label) => ListTile(
                            leading: const Icon(Icons.label_outline),
                            title: Text(label),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'rename') {
                                  _rename(context, label);
                                } else {
                                  _delete(context, label);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text('Ganti nama'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus label'),
                                ),
                              ],
                            ),
                            onTap: () => _rename(context, label),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, String oldName) async {
    final provider = context.read<NotesProvider>();
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ganti nama label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Nama label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || newName == oldName) return;
    try {
      await provider.renameLabel(oldName, newName);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _delete(BuildContext context, String label) async {
    final provider = context.read<NotesProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus label?'),
        content: Text('Label "$label" akan dihapus dari semua catatan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await provider.deleteLabel(label);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Gagal memperbarui label: $error')));
  }
}
