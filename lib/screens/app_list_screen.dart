import 'package:flutter/material.dart';
import '../state/app_state.dart';

class AppListScreen extends StatefulWidget {
  final AppState appState;

  const AppListScreen({super.key, required this.appState});

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'name';

  List<AppItem> get _filteredApps {
    List<AppItem> list = widget.appState.apps.where((app) {
      return app.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (_sortMode == 'name') {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else {
      list.sort((a, b) => (b.isLocked ? 1 : 0) - (a.isLocked ? 1 : 0));
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredApps;
    final appState = widget.appState;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'COBALT FORTRESS',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 2.0,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFf1f5f9),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary Row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                Expanded(child: _buildSummaryCard(context, 'TERKUNCI', '${appState.lockedCount}', theme.colorScheme.primary)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard(context, 'TIDAK TERKUNCI', '${appState.unlockedCount}', theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Master lock status banner
          if (!appState.masterLockEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Master Lock sedang NONAKTIF. Semua proteksi dimatikan.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Cari nama aplikasi...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant, size: 18),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        }),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0f172a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'APPLICATION CONTROL',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w900),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _sortMode = _sortMode == 'name' ? 'status' : 'name';
                  }),
                  child: Text(
                    _sortMode == 'name' ? 'URUTKAN: NAMA' : 'URUTKAN: STATUS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // App List
          Expanded(
            child: appState.isLoadingApps
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text('Tidak ada aplikasi ditemukan',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildAppCard(context, filtered[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, String count, Color valueColor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Text(
            count,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: valueColor, fontSize: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 1.0, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, AppItem app) {
    final theme = Theme.of(context);
    final bool effectiveLocked = widget.appState.masterLockEnabled && app.isLocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveLocked
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
          width: effectiveLocked ? 1.5 : 1.0,
        ),
        boxShadow: effectiveLocked
            ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: app.iconBytes != null
                  ? Image.memory(app.iconBytes!, fit: BoxFit.cover)
                  : Icon(Icons.android_rounded, color: theme.colorScheme.onSurfaceVariant, size: 24),
            ),
            const SizedBox(width: 16),
            // Name & status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: effectiveLocked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      effectiveLocked ? 'Math Lock Aktif' : 'Proteksi Dinonaktifkan',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: effectiveLocked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            // Toggle — disabled (greyed out) when master lock is OFF
            GestureDetector(
              onTap: widget.appState.masterLockEnabled
                  ? () => widget.appState.toggleApp(app)
                  : null,
              child: Opacity(
                opacity: widget.appState.masterLockEnabled ? 1.0 : 0.4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 48,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: effectiveLocked ? theme.colorScheme.primary : const Color(0xFF334155),
                    boxShadow: effectiveLocked
                        ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: effectiveLocked ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
