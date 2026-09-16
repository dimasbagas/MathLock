import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' show pi;
import 'dart:ui' show ImageFilter;
import '../services/database_service.dart';
import '../state/app_state.dart';
import '../widgets/premium_upgrade_sheet.dart';
import '../widgets/glow_container.dart';

class StatsScreen extends StatefulWidget {
  final AppState appState;
  const StatsScreen({super.key, required this.appState});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseService _db = DatabaseService();

  // Data stats
  int                    _totalSolves   = 0;
  double                 _avgDurationSec = 0;
  double                 _accuracy      = 0;
  List<DailyStat>        _weeklyStats   = [];
  List<Map<String, dynamic>> _topApps  = [];
  bool                   _isLoading     = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final totalSolves    = await _db.getTotalSolves();
      final avgDuration    = await _db.getAvgDurationSec();
      final accuracy       = await _db.getAccuracy();
      final weeklyStats    = await _db.getWeeklyStats();
      final topApps        = await _db.getTopApps(limit: 4);
      if (mounted) {
        setState(() {
          _totalSolves    = totalSolves;
          _avgDurationSec = avgDuration;
          _accuracy       = accuracy;
          _weeklyStats    = weeklyStats;
          _topApps        = topApps;
          _isLoading      = false;
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
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PERFORMA SISTEM', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 2.0, fontSize: 10)),
                            const SizedBox(height: 4),
                            Text('STATISTIK', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 32)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildChartSection(context),
                        const SizedBox(height: 16),
                        _buildAccuracySection(context),
                        if (_topApps.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('INTELIJEN PENGGUNAAN', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.colorScheme.primary, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('APLIKASI TERKUNCI\nPALING SERING', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => _showAllApps(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor: theme.colorScheme.onSurface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: Text('LIHAT SEMUA', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._topApps.asMap().entries.map((e) {
                            final app   = e.value;
                            final cnt   = (app['cnt'] as int?) ?? 0;
                            final maxCnt = (_topApps.first['cnt'] as int?) ?? 1;
                            final pct   = cnt / maxCnt;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildAppStatRow(context, app['appName'] as String, '$cnt KALI', Icons.apps_rounded, pct),
                            );
                          }),
                        ],
                        if (_totalSolves > 0) ...[
                          const SizedBox(height: 32),
                          _buildAchievement(context),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
          if (!widget.appState.isPremium) _buildLockedOverlay(context),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    final theme = Theme.of(context);

    // Normalise bar heights
    final maxAvg = _weeklyStats.fold(0.0, (m, s) => s.avgDurationSec > m ? s.avgDurationSec : m);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        gradient: RadialGradient(
          colors: [theme.colorScheme.primary.withValues(alpha: 0.15), Colors.transparent],
          center: Alignment.center,
          radius: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL PROBLEM DISELESAIKAN', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _totalSolves > 0 ? '$_totalSolves' : '—',
                style: GoogleFonts.jetBrainsMono(
                  textStyle: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_totalSolves > 0) ...[
                const SizedBox(width: 8),
                Text(
                  'AVG ${_avgDurationSec.toStringAsFixed(1)}s',
                  style: GoogleFonts.jetBrainsMono(
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          Text('RATA-RATA WAKTU PENYELESAIAN (DETIK)', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: _weeklyStats.isEmpty
                ? Center(child: Text('Belum ada data', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _weeklyStats.map((s) {
                      final pct = maxAvg > 0 ? (s.avgDurationSec / maxAvg).clamp(0.05, 1.0) : 0.05;
                      return _buildBar(context, s.dayLabel, pct);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, String label, double percentage) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: percentage,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 15)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAccuracySection(BuildContext context) {
    final theme      = Theme.of(context);
    final accuracyPct = _accuracy * 100;
    final label       = _accuracy == 0 ? '—' : '${accuracyPct.toStringAsFixed(0)}%';
    final statusText  = _accuracy >= 0.8 ? 'OPTIMAL' : _accuracy >= 0.5 ? 'CUKUP' : 'PERLU LATIHAN';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('TINGKAT AKURASI', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _AccuracyRingPainter(
                    percentage: _accuracy.clamp(0.0, 1.0),
                    color: theme.colorScheme.tertiary,
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.jetBrainsMono(
                          textStyle: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(statusText, style: theme.textTheme.labelSmall?.copyWith(fontSize: 8, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.2)),
            ),
            child: Text('STATUS: $statusText', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppStatRow(BuildContext context, String name, String count, IconData icon, double percentage) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    Text(
                      count,
                      style: GoogleFonts.jetBrainsMono(
                        textStyle: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(2)),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: percentage,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -60, bottom: -60,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.1), blurRadius: 60, spreadRadius: 20)],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PENCAPAIAN', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                    const SizedBox(height: 8),
                    Text(
                      '$_totalSolves SOAL SELESAI',
                      style: GoogleFonts.jetBrainsMono(
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Akurasi ${(_accuracy * 100).toStringAsFixed(0)}% dengan rata-rata waktu penyelesaian ${_avgDurationSec.toStringAsFixed(1)} detik.',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Icon(Icons.military_tech, size: 48, color: theme.colorScheme.tertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAllApps(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SEMUA APLIKASI TERKUNCI', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  Text(
                    '${_topApps.length} APP',
                    style: GoogleFonts.jetBrainsMono(
                      textStyle: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: theme.colorScheme.outlineVariant, height: 1),
            Expanded(
              child: _topApps.isEmpty
                  ? Center(child: Text('Belum ada data', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _topApps.length,
                      separatorBuilder: (_, ignored) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final app = _topApps[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.apps_rounded, color: theme.colorScheme.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Text(app['appName'] as String, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                              Text(
                                '${app['cnt']} kali',
                                style: GoogleFonts.jetBrainsMono(
                                  textStyle: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedOverlay(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.75),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlowContainer(
                  glowType: GlowType.primary,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.colorScheme.primary, width: 2),
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'STATISTIK PENUH TERKUNCI',
                  style: GoogleFonts.orbitron(
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Dapatkan intelijen analisis penuh, akurasi pemecahan soal matematika, grafik mingguan, pencapaian, dan data terperinci lainnya.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => PremiumUpgradeSheet(appState: widget.appState),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 8,
                      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      'BUKA COBALT PREMIUM',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccuracyRingPainter extends CustomPainter {
  final double percentage;
  final Color  color;
  final Color  backgroundColor;

  _AccuracyRingPainter({required this.percentage, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color       = backgroundColor
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color       = color
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round
      ..style       = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percentage,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
