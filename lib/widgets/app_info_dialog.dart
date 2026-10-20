import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notes_provider.dart';

class AppInfoDialog extends StatelessWidget {
  const AppInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    return AlertDialog(
      title: const Text('GoKeep'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fitur akun dan login belum tersedia. Saat ini semua catatan '
            'tersimpan di backend bersama dan belum dipisahkan berdasarkan '
            'pengguna.',
          ),
          const SizedBox(height: 12),
          Text('Jumlah catatan: ${provider.allNotes.length}'),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: provider.isLoading ? null : provider.loadNotes,
          child: const Text('Periksa koneksi'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
