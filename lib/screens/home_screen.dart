import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/api_error_banner.dart';
import '../screens/note_editor_screen.dart';
import '../screens/search_screen.dart';
import '../screens/archive_screen.dart';
import '../screens/reminders_screen.dart';
import '../widgets/app_info_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final pinnedNotes = provider.pinnedNotes;
    final unpinnedNotes = provider.unpinnedNotes;
    final isGrid = provider.isGridView;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFFAFAF9),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context, provider, isDark),
            const ApiErrorBanner(),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildNotesList(
                      context,
                      pinnedNotes,
                      unpinnedNotes,
                      isGrid,
                      isDark,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _GoKeepFAB(
        onNewNote: () => _openEditor(context, null),
        onNewChecklist: () => _openEditor(context, null, isChecklist: true),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    NotesProvider provider,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Menu',
            ),
            Expanded(
              child: Text(
                'Cari catatan kamu',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                provider.isGridView
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view,
              ),
              onPressed: provider.toggleViewMode,
              tooltip: provider.isGridView ? 'List view' : 'Grid view',
            ),
            const _AccountAvatar(),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList(
    BuildContext context,
    List<Note> pinned,
    List<Note> unpinned,
    bool isGrid,
    bool isDark,
  ) {
    if (pinned.isEmpty && unpinned.isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    return CustomScrollView(
      slivers: [
        if (pinned.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'DISEMATKAN', isDark: isDark),
          ),
          _buildNotesSliver(context, pinned, isGrid),
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'LAINNYA', isDark: isDark),
          ),
        ],
        _buildNotesSliver(context, unpinned, isGrid),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  SliverToBoxAdapter _buildNotesSliver(
    BuildContext context,
    List<Note> notes,
    bool isGrid,
  ) {
    if (isGrid) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            itemBuilder: (context, index) =>
                _buildNoteCard(context, notes[index]),
          ),
        ),
      );
    } else {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: notes
                .map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildNoteCard(context, n),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    return NoteCard(
      note: note,
      onTap: () => _openEditor(context, note),
      onLongPress: () => _openEditor(context, note),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return BottomAppBar(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          _BottomNavItem(
            icon: Icons.lightbulb_outline,
            label: 'Catatan',
            isSelected: true,
            isDark: isDark,
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
          _BottomNavItem(
            icon: Icons.notifications_none_outlined,
            label: 'Pengingat',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
          ),
          _BottomNavItem(
            icon: Icons.archive_outlined,
            label: 'Arsip',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchiveScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    Note? note, {
    bool isChecklist = false,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NoteEditorScreen(note: note, startAsChecklist: isChecklist),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8AB00),
        shape: BoxShape.circle,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => const AppInfoDialog(),
        ),
        child: const Center(
          child: Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'Catatan yang kamu tambahkan\nakan muncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoKeepFAB extends StatefulWidget {
  final VoidCallback onNewNote;
  final VoidCallback onNewChecklist;

  const _GoKeepFAB({required this.onNewNote, required this.onNewChecklist});

  @override
  State<_GoKeepFAB> createState() => _GoKeepFABState();
}

class _GoKeepFABState extends State<_GoKeepFAB>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fabBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final fabFg = isDark ? Colors.white : Colors.black87;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sub-FABs
        FadeTransition(
          opacity: _expandAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SubFAB(
                icon: Icons.check_box_outlined,
                label: 'Daftar baru',
                bgColor: fabBg,
                fgColor: fabFg,
                onTap: () {
                  _toggle();
                  widget.onNewChecklist();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // Main FAB
        FloatingActionButton.extended(
          onPressed: _isExpanded ? _toggle : widget.onNewNote,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isExpanded ? Icons.close : Icons.edit_outlined,
              key: ValueKey(_isExpanded),
            ),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _isExpanded ? 'Tutup' : 'Catatan baru',
              key: ValueKey(_isExpanded),
            ),
          ),
          backgroundColor: fabBg,
          foregroundColor: fabFg,
          elevation: 3,
        ),
      ],
    );
  }
}

class _SubFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  const _SubFAB({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: fgColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 2,
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white54 : Colors.black45);

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
