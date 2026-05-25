import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/app_lock_native_service.dart';

/// Full-screen permission wizard shown on first launch.
/// Guides the user step-by-step through granting Usage Access and
/// Display-Over-Apps permissions, and automatically advances when each
/// permission is detected after the user returns from Android Settings.
class PermissionWizard extends StatefulWidget {
  final AppLockNativeService nativeService;
  final VoidCallback onComplete;

  const PermissionWizard({
    super.key,
    required this.nativeService,
    required this.onComplete,
  });

  @override
  State<PermissionWizard> createState() => _PermissionWizardState();
}

class _PermissionWizardState extends State<PermissionWizard>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int  _step         = 0; // 0 = usage access, 1 = overlay, 2 = done
  bool _isChecking     = false;

  late AnimationController _anim;
  late Animation<double>   _fade;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();

    _checkAndAdvance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _anim.dispose();
    super.dispose();
  }

  /// Re-check permissions every time the user returns from Android Settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAndAdvance();
  }

  Future<void> _checkAndAdvance() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final usage   = await widget.nativeService.checkUsagePermission();
    final overlay = await widget.nativeService.checkOverlayPermission();

    if (!mounted) return;
    setState(() {
      _isChecking = false;
      if (usage && overlay) {
        _step = 2;
      } else if (usage && !overlay) {
        _step = 1;
      } else {
        _step = 0;
      }
    });

    if (usage && overlay) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) widget.onComplete();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size  = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: const Color(0xFF060C17).withValues(alpha: 0.95)),
            ),
          ),

          // Ambient glow
          Positioned(
            top: -size.height * 0.1, left: -80,
            child: _glow(theme.colorScheme.primary.withValues(alpha: 0.2), 300),
          ),
          Positioned(
            bottom: -size.height * 0.1, right: -80,
            child: _glow(theme.colorScheme.tertiary.withValues(alpha: 0.1), 280),
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(theme),
                    const SizedBox(height: 40),
                    _buildStepIndicators(theme),
                    const SizedBox(height: 40),
                    Expanded(child: _buildCurrentStep(theme)),
                    const SizedBox(height: 24),
                    _buildActionButton(theme),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Izin ini diperlukan agar Cobalt Fortress dapat bekerja.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _glow(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.security, color: theme.colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          'COBALT FORTRESS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w900,
          ),
        ),
      ]),
      const SizedBox(height: 20),
      Text(
        'Pengaturan\nIzin Akses',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900, height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 10),
      Text(
        'Cobalt Fortress membutuhkan 2 izin khusus\nuntuk dapat mengunci aplikasi.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant, height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    ]);
  }

  Widget _buildStepIndicators(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot(theme, 0, 'Usage\nAccess',  Icons.query_stats_rounded),
        _stepConnector(theme, 0),
        _stepDot(theme, 1, 'Display\nOver Apps', Icons.layers_rounded),
        _stepConnector(theme, 1),
        _stepDot(theme, 2, 'Selesai', Icons.check_circle_rounded),
      ],
    );
  }

  Widget _stepDot(ThemeData theme, int index, String label, IconData icon) {
    final isDone   = _step > index;
    final isActive = _step == index;
    final color = isDone
        ? theme.colorScheme.tertiary
        : isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant;

    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48, height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: isActive ? 0.15 : isDone ? 0.1 : 0.05),
          border: Border.all(color: color, width: isActive ? 2 : 1.5),
          boxShadow: isActive
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)]
              : null,
        ),
        child: Icon(
          isDone ? Icons.check_rounded : icon,
          color: color, size: 22,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color, fontSize: 9, fontWeight: FontWeight.bold,
          letterSpacing: 0.5, height: 1.3,
        ),
        textAlign: TextAlign.center,
      ),
    ]);
  }

  Widget _stepConnector(ThemeData theme, int afterIndex) {
    final filled = _step > afterIndex;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 2,
        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
        decoration: BoxDecoration(
          color: filled
              ? theme.colorScheme.tertiary
              : theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme) {
    switch (_step) {
      case 0:
        return _buildPermissionCard(
          theme,
          icon: Icons.query_stats_rounded,
          iconColor: theme.colorScheme.primary,
          title: 'Usage Access',
          subtitle: 'Izin Langkah 1 dari 2',
          description:
              'Izin ini memungkinkan Cobalt Fortress mendeteksi aplikasi mana yang sedang dibuka, '
              'sehingga layar kunci matematika dapat ditampilkan tepat waktu.',
          steps: const [
            'Ketuk tombol di bawah untuk membuka Settings',
            'Cari "mathlockv2" dalam daftar',
            'Aktifkan tombol "Permit usage access"',
            'Kembali ke aplikasi ini',
          ],
        );
      case 1:
        return _buildPermissionCard(
          theme,
          icon: Icons.layers_rounded,
          iconColor: theme.colorScheme.tertiary,
          title: 'Display Over Apps',
          subtitle: 'Izin Langkah 2 dari 2',
          description:
              'Izin ini diperlukan agar layar kunci dapat tampil di atas aplikasi lain '
              'ketika aplikasi yang dikunci sedang dibuka oleh pengguna.',
          steps: const [
            'Ketuk tombol di bawah untuk membuka Settings',
            'Aktifkan "Allow display over other apps"',
            'Kembali ke aplikasi ini',
          ],
        );
      default: // step == 2: all granted
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  border: Border.all(color: theme.colorScheme.tertiary, width: 2),
                  boxShadow: [BoxShadow(color: theme.colorScheme.tertiary.withValues(alpha: 0.3), blurRadius: 30)],
                ),
                child: Icon(Icons.shield_rounded, size: 50, color: theme.colorScheme.tertiary),
              ),
              const SizedBox(height: 24),
              Text('Semua Izin Aktif!',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Cobalt Fortress siap melindungi aplikasi Anda.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        );
    }
  }

  Widget _buildPermissionCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required List<String> steps,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(
                color: iconColor, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 2),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ]),
          ]),
          const SizedBox(height: 16),
          Text(description, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant, height: 1.5,
          )),
          const SizedBox(height: 20),
          Text('CARA MENGAKTIFKAN:', style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.1),
                  border: Border.all(color: iconColor.withValues(alpha: 0.4)),
                ),
                child: Center(child: Text(
                  '${e.key + 1}',
                  style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.bold),
                )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value, style: theme.textTheme.bodySmall?.copyWith(height: 1.5))),
            ]),
          )),
        ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    if (_step == 2) return const SizedBox.shrink();

    final isUsageStep = _step == 0;
    final color = isUsageStep ? theme.colorScheme.primary : theme.colorScheme.tertiary;

    return GestureDetector(
      onTap: _isChecking
          ? null
          : () async {
              if (isUsageStep) {
                await widget.nativeService.requestUsagePermission();
              } else {
                await widget.nativeService.requestOverlayPermission();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_isChecking)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2,
            ))
          else ...[
            const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              isUsageStep ? 'BUKA PENGATURAN USAGE ACCESS' : 'BUKA PENGATURAN DISPLAY OVER APPS',
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900,
                fontSize: 12, letterSpacing: 1.5,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
