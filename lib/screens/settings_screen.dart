import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/glow_container.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            color: const Color(0xFFf1f5f9),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(context),
            const SizedBox(height: 32),
            _buildDifficultySection(context),
            const SizedBox(height: 32),
            _buildGeneralSection(context),
            const SizedBox(height: 48),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    Container(height: 1, width: 48, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text('SECURED BY COBALT ENGINEERING', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 3.0, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24, top: -24,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.1), blurRadius: 80)],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STATUS SISTEM', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('PENGATURAN', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Konfigurasi protokol keamanan dan parameter matematis unit pertahanan Anda.', style: theme.textTheme.bodySmall?.copyWith(fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDifficultySection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TINGKAT KESULITAN MATEMATIKA', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
            Icon(Icons.functions, color: theme.colorScheme.onSurfaceVariant, size: 16),
          ],
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: widget.appState,
          builder: (context, _) => Row(
            children: [
              Expanded(child: _buildDifficultyCard(context, 'LEVEL 01', 'SD',  'DASAR', theme.colorScheme.tertiary, 0.33, 0)),
              const SizedBox(width: 16),
              Expanded(child: _buildDifficultyCard(context, 'LEVEL 02', 'SMP', 'AKTIF', theme.colorScheme.primary, 0.66, 1)),
              const SizedBox(width: 16),
              Expanded(child: _buildDifficultyCard(context, 'LEVEL 03', 'SMA', 'LANJUT', theme.colorScheme.error, 1.0, 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(BuildContext context, String level, String grade, String status, Color mainColor, double progress, int cardIndex) {
    final theme = Theme.of(context);
    final isActive = widget.appState.difficultyLevel == cardIndex;
    return GestureDetector(
      onTap: () => widget.appState.setDifficulty(cardIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.secondary : const Color(0xFF0f172a),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? mainColor : theme.colorScheme.outlineVariant, width: isActive ? 2 : 1),
          boxShadow: isActive ? [BoxShadow(color: mainColor.withValues(alpha: 0.15), spreadRadius: 2, blurRadius: 12)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(level, style: theme.textTheme.labelSmall?.copyWith(color: isActive ? mainColor : theme.colorScheme.onSurfaceVariant, fontSize: 9, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (isActive) Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Icon(Icons.check_circle, color: mainColor, size: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(grade, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(width: 4),
                  Text(status, style: theme.textTheme.labelSmall?.copyWith(color: mainColor, fontSize: 9, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(2)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: mainColor.withValues(alpha: 0.3), blurRadius: 10)],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SISTEM & UMUM', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            // Dark Mode card (cosmetic — always on)
            Expanded(
              child: GlowContainer(
                glowType: GlowType.tertiary,
                backgroundColor: const Color(0xFF0f172a),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.dark_mode, color: theme.colorScheme.tertiary),
                    const SizedBox(height: 16),
                    Text('TEMA GELAP', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('AKTIF', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // About card
            Expanded(
              child: InkWell(
                onTap: () => _showAboutDialog(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0f172a),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('TENTANG', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('VERSION 2.4.0-COBALT', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _showBantuanDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0f172a),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.help_center_outlined, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 16),
                  Text('BANTUAN & DUKUNGAN', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                Icon(Icons.arrow_outward, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Dialogs ───────────────────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0f172a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: theme.colorScheme.outlineVariant)),
        title: Row(children: [
          Icon(Icons.security, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Text('COBALT FORTRESS', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2.0)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.shield, size: 56, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            _aboutRow(context, 'Versi', '2.4.0-COBALT'),
            const SizedBox(height: 8),
            _aboutRow(context, 'Build', 'Release 2026.04.04'),
            const SizedBox(height: 8),
            _aboutRow(context, 'Platform', 'Android / iOS'),
            const SizedBox(height: 8),
            _aboutRow(context, 'Engine', 'Flutter 3.x'),
            const SizedBox(height: 16),
            Text('Cobalt Fortress mengamankan aplikasi Anda menggunakan soal matematika dinamis. Tidak ada kecurangan.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('TUTUP', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
        Text(value, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10, color: theme.colorScheme.primary)),
      ],
    );
  }

  void _showBantuanDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0f172a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: theme.colorScheme.outlineVariant)),
        title: Row(children: [
          Icon(Icons.support_agent_rounded, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Text('BANTUAN & DUKUNGAN', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selamat datang di pusat dukungan Cobalt Fortress.', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('Jika kamu mengalami kendala, berikut langkah yang bisa dicoba:', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            _tipRow(context, '1.', 'Pastikan Master Lock dalam kondisi aktif agar semua proteksi berfungsi.'),
            const SizedBox(height: 8),
            _tipRow(context, '2.', 'Jika lupa jawaban, gunakan Metode Cadangan (PIN) yang telah dikonfigurasi.'),
            const SizedBox(height: 8),
            _tipRow(context, '3.', 'Untuk reset, hapus data aplikasi melalui pengaturan perangkat Anda.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.mail_outline_rounded, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('support@danibaret014.com', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600))),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('TUTUP', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _tipRow(BuildContext context, String num, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(num, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      ],
    );
  }
}
