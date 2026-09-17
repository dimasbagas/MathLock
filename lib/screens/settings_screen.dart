import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../state/app_state.dart';
import '../widgets/glow_container.dart';
import '../widgets/premium_upgrade_sheet.dart';
import '../services/supabase_service.dart';
import '../services/database_service.dart';
import 'auth_wrapper.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isSyncing = false;

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

      ),
      body: ListenableBuilder(
        listenable: widget.appState,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(context),
                if (AppConfig.enablePremiumRestrictions) ...[
                  const SizedBox(height: 24),
                  _buildPremiumStatusCard(context),
                ],
                const SizedBox(height: 24),
                _buildDifficultySection(context),
                const SizedBox(height: 24),
                _buildRelockSection(context),
                const SizedBox(height: 24),
                _buildGeneralSection(context),
                const SizedBox(height: 24),
                _buildAccountSection(context),
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
          );
        }
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
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
          builder: (context, _) => Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildDifficultyCard(context, 'LEVEL 01', 'SD',  'DASAR', theme.colorScheme.tertiary, 0.25, 0)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDifficultyCard(context, 'LEVEL 02', 'SMP', 'AKTIF', theme.colorScheme.primary, 0.50, 1)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDifficultyCard(context, 'LEVEL 03', 'SMA', 'LANJUT', theme.colorScheme.error, 0.75, 2)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDifficultyCard(context, 'LEVEL 04', 'PT',  'PAKAR', const Color(0xFFa855f7), 1.0, 3)),
                ],
              ),
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
          color: isActive ? theme.colorScheme.secondary : theme.cardColor,
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
              decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(2)),
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

  Widget _buildRelockSection(BuildContext context) {
    final theme = Theme.of(context);
    final intervals = [
      if (kDebugMode) {'minutes': 0, 'label': '⚡ 3 Detik', 'tag': 'Dev Test'},
      {'minutes': 5, 'label': '5 Menit', 'tag': 'Ketat'},
      {'minutes': 10, 'label': '10 Menit', 'tag': 'Protektif'},
      {'minutes': 15, 'label': '15 Menit', 'tag': 'Standar'},
      {'minutes': 30, 'label': '30 Menit', 'tag': 'Santai'},
      {'minutes': 60, 'label': '60 Menit', 'tag': 'Longgar'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DURASI RE-LOCK INTRA-SESI', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
            Icon(Icons.timer_outlined, color: theme.colorScheme.onSurfaceVariant, size: 16),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Interval penguncian ulang matematika saat aplikasi target terus digunakan.',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: widget.appState,
          builder: (context, _) {
            final currentMinutes = widget.appState.relockIntervalMinutes;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: intervals.map((item) {
                final mins = item['minutes'] as int;
                final label = item['label'] as String;
                final tag = item['tag'] as String;
                final isActive = currentMinutes == mins;

                return ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)),
                      Text(tag, style: TextStyle(fontSize: 9, color: isActive ? theme.colorScheme.onPrimary.withValues(alpha: 0.8) : theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  selected: isActive,
                  onSelected: (selected) {
                    if (selected) {
                      widget.appState.setRelockInterval(mins);
                    }
                  },
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.cardColor,
                  side: BorderSide(
                    color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    width: isActive ? 2 : 1,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  showCheckmark: false,
                );
              }).toList(),
            );
          },
        ),
      ],
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
            // Theme Mode Toggle card
            Expanded(
              child: ListenableBuilder(
                listenable: widget.appState,
                builder: (context, _) {
                  final isDark = widget.appState.isDarkTheme;
                  return InkWell(
                    onTap: () => widget.appState.toggleTheme(),
                    borderRadius: BorderRadius.circular(16),
                    child: GlowContainer(
                      glowType: isDark ? GlowType.tertiary : GlowType.primary,
                      backgroundColor: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: isDark ? theme.colorScheme.tertiary : theme.colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(isDark ? 'TEMA GELAP' : 'TEMA CERAH', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('AKTIF', style: theme.textTheme.labelSmall?.copyWith(color: isDark ? theme.colorScheme.tertiary : theme.colorScheme.primary, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }
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
                    color: theme.cardColor,
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
              color: theme.cardColor,
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
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 16),
                  Text('KEBIJAKAN PRIVASI', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurfaceVariant, size: 14),
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
        backgroundColor: theme.cardColor,
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
        backgroundColor: theme.cardColor,
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

  Widget _buildPremiumStatusCard(BuildContext context) {
    if (!AppConfig.enablePremiumRestrictions) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final appState = widget.appState;
    final isPremium = appState.isPremium;

    if (!isPremium) {
      return GlowContainer(
        glowType: GlowType.primary,
        backgroundColor: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'COBALT PREMIUM',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kunci aplikasi tak terbatas & nikmati pengalaman 100% bebas iklan.',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => PremiumUpgradeSheet(appState: appState),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('UPGRADE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // Tampilan jika premium aktif
    if (!appState.isPremium) {
      return const SizedBox.shrink();
    }
    String expiryText = 'Selamanya (Lifetime)';
    if (appState.premiumExpiry > 0) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(appState.premiumExpiry);
      expiryText = 'Aktif s/d ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
    }

    return GlowContainer(
      glowType: GlowType.tertiary,
      backgroundColor: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: theme.colorScheme.tertiary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'COBALT PREMIUM AKTIF 👑',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Terima kasih telah berlangganan premium. Semua fitur bebas kunci dan tanpa iklan aktif sepenuhnya.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                expiryText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              // Tombol pengembang untuk reset ke Free
              GestureDetector(
                onTap: () async {
                  await appState.cancelPremium();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status Premium dinonaktifkan (Mode Pengembang)'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RESET KE FREE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildAccountSection(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;
    final email = user?.email ?? 'Tidak terhubung';
    final fullName = user?.userMetadata?['full_name'] ?? 'Pengguna MathLock';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AKUN & SINKRONISASI',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    radius: 22,
                    child: Icon(Icons.person, color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _handleSync,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.sync, size: 16),
                      label: Text(
                        _isSyncing ? 'MENYINKRONKAN...' : 'SINKRONISASI SEKARANG',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text(
                        'KELUAR AKUN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final appState = widget.appState;
      final lockedPackages = appState.apps
          .where((a) => a.isLocked)
          .map((a) => a.packageName)
          .toList();

      // 1. Sync settings to Supabase
      await _authService.syncSettings(
        masterLockEnabled: appState.masterLockEnabled,
        difficultyLevel: appState.difficultyLevel,
        biometricEnabled: appState.biometricEnabled,
        isDarkTheme: appState.isDarkTheme,
        isPremium: appState.isPremium,
        premiumExpiry: appState.premiumExpiry,
        lockedPackages: lockedPackages,
      );

      // 2. Sync local SQLite database events (hanya data baru yang belum tersinkronisasi)
      final dbService = DatabaseService();
      final localEvents = await dbService.getUnsyncedEvents();
      if (localEvents.isNotEmpty) {
        await _authService.syncUnlockEvents(localEvents);
        final eventIds = localEvents.map((e) => e.id).whereType<int>().toList();
        await dbService.markEventsAsSynced(eventIds);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sinkronisasi data berhasil'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyinkronkan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil keluar akun.'),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AuthWrapper(appState: widget.appState)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar akun: $e'),
          ),
        );
      }
    }
  }
}
