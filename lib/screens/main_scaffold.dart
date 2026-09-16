import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart';
import '../widgets/ambient_glow.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'app_list_screen.dart';
import '../state/app_state.dart';
import '../widgets/permission_wizard.dart';
import '../widgets/mock_ad_banner.dart';

class MainScaffold extends StatefulWidget {
  final AppState appState;
  const MainScaffold({super.key, required this.appState});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  AppState get _appState => widget.appState;

  // Permission state — null = not yet checked
  bool? _hasUsage;
  bool? _hasOverlay;
  bool  _wizardShown = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer permission check until the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
      // Sync current AppState to native on startup
      _appState.syncWithNative();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check permissions whenever the user returns to the app (e.g. after
  /// granting permission in Android Settings).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final usage   = await _appState.nativeService.checkUsagePermission();
    final overlay = await _appState.nativeService.checkOverlayPermission();
    if (!mounted) return;
    setState(() {
      _hasUsage   = usage;
      _hasOverlay = overlay;
    });
    // Auto-show wizard when master lock is on and permissions are missing
    if (_appState.masterLockEnabled && (!usage || !overlay) && !_wizardShown) {
      _wizardShown = true;
      _showPermissionWizard();
    }
  }

  void _showPermissionWizard() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, anim) => PermissionWizard(
        nativeService: _appState.nativeService,
        onComplete: () {
          Navigator.of(ctx).pop();
          setState(() {
            _hasUsage    = true;
            _hasOverlay  = true;
            _wizardShown = false;
          });
          _appState.syncWithNative();
        },
      ),
    );
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _goToAppList() => setState(() => _selectedIndex = 3);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        // ⚠ pages MUST be inside the builder so sub-widgets rebuild on notify
        final pages = [
          HomeScreen(appState: _appState, onManageVault: _goToAppList),
          HistoryScreen(appState: _appState),
          StatsScreen(appState: _appState),
          AppListScreen(appState: _appState),
          SettingsScreen(appState: _appState),
        ];

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              // ── Ambient glow blobs ─────────────────────────────────────────
              AmbientGlow.primary(
                top: MediaQuery.of(context).size.height * 0.25,
                left: -80,
                size: 384,
                context: context,
              ),
              AmbientGlow.tertiary(
                bottom: MediaQuery.of(context).size.height * 0.25,
                right: -80,
                size: 384,
                context: context,
              ),

              // ── Page content ───────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Permission banner (shown only when master lock is on but
                    // permissions are not yet granted)
                    if (_appState.masterLockEnabled &&
                        (_hasUsage == false || _hasOverlay == false))
                      _buildPermissionBanner(theme),

                    Expanded(child: pages[_selectedIndex]),

                    MockAdBanner(appState: _appState),
                    if (!_appState.isPremium)
                      const SizedBox(height: 90), // Spasi agar tidak tertutup bottom navigation bar
                  ],
                ),
              ),
            ],
          ),

          // ── Bottom nav ─────────────────────────────────────────────────────
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.85),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: BottomNavigationBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  type: BottomNavigationBarType.fixed,
                  showSelectedLabels:   true,
                  showUnselectedLabels: true,
                  selectedItemColor:   theme.colorScheme.primary,
                  unselectedItemColor: const Color(0xFF64748b),
                  selectedFontSize:   9,
                  unselectedFontSize: 9,
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  items: [
                    _buildNavItem(Icons.home_filled,    Icons.home_outlined,       'BERANDA',    0),
                    _buildNavItem(Icons.history,         Icons.history_outlined,     'RIWAYAT',    1),
                    _buildNavItem(Icons.bar_chart,       Icons.bar_chart_outlined,   'STATISTIK',  2),
                    _buildNavItem(Icons.apps_rounded,    Icons.apps_outlined,        'APLIKASI',   3),
                    _buildNavItem(Icons.settings,        Icons.settings_outlined,    'PENGATURAN', 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Permission banner ──────────────────────────────────────────────────────

  Widget _buildPermissionBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'IZIN DIPERLUKAN UNTUK APP LOCK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (_hasUsage == false)
            _buildPermissionRow(
              theme,
              icon: Icons.query_stats_rounded,
              label: 'Usage Access',
              desc: 'Diperlukan untuk mendeteksi app di foreground',
              onGrant: () => _appState.nativeService.requestUsagePermission(),
            ),
          if (_hasUsage == false && _hasOverlay == false)
            const SizedBox(height: 8),
          if (_hasOverlay == false)
            _buildPermissionRow(
              theme,
              icon: Icons.layers_rounded,
              label: 'Display Over Apps',
              desc: 'Diperlukan untuk menampilkan layar kunci',
              onGrant: () => _appState.nativeService.requestOverlayPermission(),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String desc,
    required VoidCallback onGrant,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold, fontSize: 11,
              )),
              Text(desc, style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 10,
              )),
            ],
          ),
        ),
        TextButton(
          onPressed: onGrant,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            backgroundColor: theme.colorScheme.error.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'IZINKAN',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Nav item builder ───────────────────────────────────────────────────────

  BottomNavigationBarItem _buildNavItem(
      IconData activeIcon, IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(isSelected ? activeIcon : icon, size: 22),
      ),
      label: label,
    );
  }
}
