import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glow_container.dart';
import '../services/database_service.dart';
import '../state/app_state.dart';
import '../widgets/premium_upgrade_sheet.dart';

class HistoryScreen extends StatefulWidget {
  final AppState appState;
  const HistoryScreen({super.key, required this.appState});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();

  int _expandedIndex = -1;

  // Data dari DB
  List<UnlockEvent> _events      = [];
  int               _totalAccess = 0;
  int               _totalBlocked = 0;
  double            _successRate  = 0.0;
  bool              _isLoading    = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final isPremium    = widget.appState.isPremium;
      final events       = await _db.getRecentEvents(limit: isPremium ? 30 : 5);
      final totalAccess  = await _db.getTotalEvents();
      final totalBlocked = await _db.getTotalBlocked();
      final accuracy     = await _db.getAccuracy();
      if (mounted) {
        setState(() {
          _events       = events;
          _totalAccess  = totalAccess;
          _totalBlocked = totalBlocked;
          _successRate  = accuracy * 100;
          _isLoading    = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'COBALT FORTRESS',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurfaceVariant),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInsightHero(context),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 3,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('LOG AKTIVITAS', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text('${_events.length} ENTRI TERBARU', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Event list
                    if (_events.isEmpty)
                      _buildEmptyState(theme)
                    else ...[
                      ...List.generate(_events.length, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildLogEntry(context, index: i, event: _events[i]),
                      )),
                      if (!widget.appState.isPremium) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.workspace_premium_rounded, color: theme.colorScheme.primary, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'BATAS RIWAYAT FREE TERCAPAI',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Hanya menampilkan 5 log terakhir. Upgrade untuk riwayat tanpa batas.',
                                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => PremiumUpgradeSheet(appState: widget.appState),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text(
                                    'UPGRADE PREMIUM',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: _buildDetailsCard(context, 'TOTAL AKSES', _totalAccess > 0 ? '$_totalAccess' : '—', theme.colorScheme.primary)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDetailsCard(context, 'DIBLOKIR', _totalBlocked > 0 ? '$_totalBlocked' : '—', theme.colorScheme.error)),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat unlock akan muncul\nsetelah membuka app yang dikunci.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightHero(BuildContext context) {
    final theme = Theme.of(context);
    final rateStr = _successRate > 0 ? '${_successRate.toStringAsFixed(0)}%' : '—';

    return GlowContainer(
      glowType: GlowType.primary,
      backgroundColor: theme.colorScheme.secondary,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: theme.colorScheme.outlineVariant),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SECURITY INSIGHT', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5, color: theme.colorScheme.tertiary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_successRate >= 75 ? 'Integritas Sistem Optimal' : 'Perlu Perhatian', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(2)),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _successRate / 100,
                              child: GlowContainer(
                                glowType: GlowType.tertiary,
                                backgroundColor: theme.colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(2),
                                child: const SizedBox(height: 4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('TINGKAT KEBERHASILAN: $rateStr', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: theme.colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: theme.colorScheme.tertiary, size: 14),
                        const SizedBox(width: 4),
                        Text('AMAN', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.colorScheme.tertiary, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.shield_outlined, size: 160, color: Colors.white.withValues(alpha: 0.05)),
          )
        ],
      ),
    );
  }

  Widget _buildLogEntry(BuildContext context, {required int index, required UnlockEvent event}) {
    final theme = Theme.of(context);
    final isSuccess       = event.success;
    final isExpanded      = _expandedIndex == index;
    final statusText      = isSuccess ? 'Selesai' : 'Gagal';
    final statusColor     = isSuccess ? theme.colorScheme.tertiaryContainer : theme.colorScheme.error;

    final dt = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} • ${dt.day}/${dt.month}/${dt.year}';
    final durationStr = '${(event.durationMs / 1000).toStringAsFixed(1)} det';

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
            width: isExpanded ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.apps_rounded, color: theme.colorScheme.onSurface, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.appName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(timeStr, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 0.5, color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GlowContainer(
                  glowType: isSuccess ? GlowType.tertiary : GlowType.error,
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: isSuccess ? theme.colorScheme.tertiary : Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                ),
              ],
            ),
            // Formula row
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MATEMATIKA', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 1.0, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(text: '${event.formula} = '),
                          TextSpan(
                            text: '${event.answer}',
                            style: TextStyle(
                              color: isSuccess ? theme.colorScheme.primary : const Color(0xFFFF5252),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Expanded detail
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DETAIL SESI', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 1.5, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _detailRow(context, 'Percobaan', '${event.attempts} kali'),
                            const SizedBox(height: 6),
                            _detailRow(context, 'Waktu Penyelesaian', durationStr),
                            const SizedBox(height: 6),
                            _detailRow(context, 'Metode', 'Matematika Manual'),
                            const SizedBox(height: 6),
                            _detailRow(context, 'Hasil', isSuccess ? '✓ BERHASIL DIBUKA' : '✗ AKSES DITOLAK'),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 9)),
        Text(value,  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 9)),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context, String title, String value, Color valueColor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(title, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: valueColor, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
