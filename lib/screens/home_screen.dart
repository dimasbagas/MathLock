import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glow_container.dart';
import '../state/app_state.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onManageVault;

  const HomeScreen({
    super.key,
    required this.appState,
    required this.onManageVault,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();

  double            _avgSolveSec = 0;
  List<UnlockEvent> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final avg    = await _db.getAvgDurationSec();
    final recent = await _db.getRecentEvents(limit: 3);
    if (mounted) {
      setState(() {
        _avgSolveSec  = avg;
        _recentEvents = recent;
      });
    }
  }

  AppState get appState => widget.appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.cardColor.withValues(alpha: 0.8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.security, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'COBALT FORTRESS',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 2.0,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroStatus(context),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildAvgSolveCard(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildComplexityCard(context)),
              ],
            ),
            const SizedBox(height: 24),
            _buildRecentlyUnlockedHeader(context),
            const SizedBox(height: 16),
            if (_recentEvents.isEmpty)
              _buildEmptyRecent(context)
            else
              ..._recentEvents.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: e.key < _recentEvents.length - 1 ? 12 : 0),
                child: _buildRecentItem(context, e.value),
              )),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatus(BuildContext context) {
    final theme = Theme.of(context);
    final bool isActive = appState.masterLockEnabled;
    final int lockedCount = appState.lockedCount;

    return GlowContainer(
      glowType: isActive ? GlowType.primary : GlowType.none,
      backgroundColor: theme.colorScheme.secondary,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.3)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT PROTOCOL',
                      style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.0),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isActive ? 'ACTIVE' : 'PAUSED',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.tertiaryContainer
                      : theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? theme.colorScheme.tertiary : theme.colorScheme.error)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? theme.colorScheme.tertiary : theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'SYSTEM SECURE' : 'SYSTEM PAUSED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isActive ? theme.colorScheme.tertiary : theme.colorScheme.error,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Bottom row: count + button | toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          '$lockedCount',
                          style: GoogleFonts.jetBrainsMono(
                            textStyle: theme.textTheme.headlineLarge?.copyWith(
                              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              fontSize: 36,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            'LOCKED\nAPPLICATIONS',
                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.onManageVault,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: Text(
                        'MANAGE VAULT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Master Lock Toggle
              Column(
                children: [
                  Text(
                    'MASTER LOCK',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => appState.setMasterLock(!isActive),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: 56,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isActive ? theme.colorScheme.primary : const Color(0xFF334155),
                        boxShadow: isActive
                            ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 12)]
                            : null,
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvgSolveCard(BuildContext context) {
    final theme   = Theme.of(context);
    final avgStr  = _avgSolveSec > 0 ? _avgSolveSec.toStringAsFixed(1) : '—';
    // Normalize ke progress bar — anggap 10 detik = 100%
    final barFactor = (_avgSolveSec / 10).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.timer, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text('AVG SOLVE TIME', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                avgStr,
                style: GoogleFonts.jetBrainsMono(
                  textStyle: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 36,
                  ),
                ),
              ),
              if (_avgSolveSec > 0) ...[const SizedBox(width: 4), Text('SEC', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold))],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(2)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _avgSolveSec > 0 ? barFactor : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.5), blurRadius: 10)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplexityCard(BuildContext context) {
    final theme = Theme.of(context);
    final lvl = appState.difficultyLevel;
    final label = AppState.complexityLabels[lvl];
    final subtitle = AppState.complexitySubtitles[lvl];
    final progress = AppState.complexityProgress[lvl];
    final color = [theme.colorScheme.tertiary, theme.colorScheme.primary, theme.colorScheme.error, const Color(0xFFa855f7)][lvl];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.terminal, color: color),
          const SizedBox(height: 8),
          Text('COMPLEXITY', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(label, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 36)),
          Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (i) {
              final filled = (i + 1) / 4 <= progress;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? color : theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildRecentlyUnlockedHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'RECENTLY UNLOCKED',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        Icon(Icons.history, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
      ],
    );
  }

  Widget _buildEmptyRecent(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_clock_rounded, size: 36, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat unlock',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(BuildContext context, UnlockEvent event) {
    final theme = Theme.of(context);
    final dt = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);
    final String timeLabel;
    if (diff.inMinutes < 1) {
      timeLabel = 'BARU SAJA';
    } else if (diff.inHours < 1) {
      timeLabel = '${diff.inMinutes} MENIT LALU';
    } else if (diff.inDays < 1) {
      timeLabel = '${diff.inHours} JAM LALU';
    } else {
      timeLabel = '${diff.inDays} HARI LALU';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.apps_rounded, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.appName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: GoogleFonts.jetBrainsMono(
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ]),
          Icon(
            event.success ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: event.success ? theme.colorScheme.tertiary : theme.colorScheme.error,
            size: 20,
          ),
        ],
      ),
    );
  }
}
