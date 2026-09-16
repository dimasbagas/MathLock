import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../state/app_state.dart';
import '../services/supabase_service.dart';
import 'glow_container.dart';
import 'ambient_glow.dart';

class PremiumUpgradeSheet extends StatefulWidget {
  final AppState appState;

  const PremiumUpgradeSheet({super.key, required this.appState});

  @override
  State<PremiumUpgradeSheet> createState() => _PremiumUpgradeSheetState();
}

class _PremiumUpgradeSheetState extends State<PremiumUpgradeSheet> {
  int _selectedPackageIndex = 0; // 0 = 3 Bulan, 1 = 6 Bulan, 2 = 1 Tahun
  bool _isProcessing = false;
  String _processMessage = '';
  bool _isSuccess = false;

  // Google Play Billing variables
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _loadingProducts = true;

  final List<Map<String, dynamic>> _packages = [
    {
      'id': 'premium_3_months',
      'months': 3,
      'duration': '3 BULAN',
      'price': 'Rp 24.000',
      'priceSub': '/ 3 bulan',
      'popular': true,
      'discount': 'Rp 8.000 / bln • Hemat 30%',
    },
    {
      'id': 'premium_6_months',
      'months': 6,
      'duration': '6 BULAN',
      'price': 'Rp 45.000',
      'priceSub': '/ 6 bulan',
      'popular': false,
      'discount': 'Rp 7.500 / bln • Hemat 40%',
    },
    {
      'id': 'premium_1_year',
      'months': 12,
      'duration': '1 TAHUN',
      'price': 'Rp 87.000',
      'priceSub': '/ 1 tahun',
      'popular': false,
      'discount': 'Rp 7.250 / bln • Terbaik',
    },
  ];

  final List<String> _benefits = [
    'Mengunci aplikasi tanpa batasan jumlah (Unlimited)',
    '100% bebas dari semua iklan banner dan pop-up',
    'Akses penuh Analisis & Statistik performa matematika',
    'Riwayat unlock lengkap tanpa batasan log (Unlimited)',
  ];

  bool get _isStoreActive => _isAvailable && _products.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // 1. Subscribe to purchase stream
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      debugPrint('Purchase stream error: $error');
    });

    // 2. Initialize store info
    _initStoreInfo();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initStoreInfo() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        setState(() {
          _isAvailable = false;
          _loadingProducts = false;
        });
        return;
      }

      final Set<String> ids = _packages.map((e) => e['id'] as String).toSet();
      final ProductDetailsResponse productDetailResponse =
          await _inAppPurchase.queryProductDetails(ids);

      if (productDetailResponse.error != null) {
        debugPrint('Product details query error: ${productDetailResponse.error}');
        setState(() {
          _isAvailable = false;
          _loadingProducts = false;
        });
        return;
      }

      // Sort products to match the expected index (3 months, 6 months, 12 months)
      final sortedProducts = List<ProductDetails>.from(productDetailResponse.productDetails);
      sortedProducts.sort((a, b) {
        final monthsA = _packages.firstWhere((p) => p['id'] == a.id)['months'] as int;
        final monthsB = _packages.firstWhere((p) => p['id'] == b.id)['months'] as int;
        return monthsA.compareTo(monthsB);
      });

      setState(() {
        _isAvailable = true;
        _products = sortedProducts;
        _loadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error initializing store info: $e');
      setState(() {
        _isAvailable = false;
        _loadingProducts = false;
      });
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          _isProcessing = true;
          _processMessage = 'Menunggu konfirmasi Google Play...';
        });
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          setState(() {
            _isProcessing = false;
            _processMessage = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pembelian Gagal: ${purchaseDetails.error?.message ?? "Terjadi kesalahan"}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          setState(() {
            _isProcessing = false;
            _processMessage = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembelian dibatalkan oleh pengguna.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          final selectedPkg = _packages.firstWhere((p) => p['id'] == purchaseDetails.productID);
          final months = selectedPkg['months'] as int;

          // Deliver premium subscription
          await widget.appState.upgradeToPremium(months);

          // Sync premium state to Supabase as well
          final authService = AuthService();
          if (authService.currentUser != null) {
            try {
              final lockedPackages = widget.appState.apps
                  .where((a) => a.isLocked)
                  .map((a) => a.packageName)
                  .toList();
              await authService.syncSettings(
                masterLockEnabled: widget.appState.masterLockEnabled,
                difficultyLevel: widget.appState.difficultyLevel,
                biometricEnabled: widget.appState.biometricEnabled,
                isDarkTheme: widget.appState.isDarkTheme,
                isPremium: true,
                premiumExpiry: widget.appState.premiumExpiry,
                lockedPackages: lockedPackages,
              );
            } catch (e) {
              debugPrint('Error syncing settings to Supabase after purchase: $e');
            }
          }

          setState(() {
            _isProcessing = false;
            _isSuccess = true;
          });

          await Future.delayed(const Duration(milliseconds: 1800));
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF10B981),
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selamat! Akun Cobalt Premium Anda telah aktif.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error triggering purchase: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memulai proses pembayaran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startMockPayment() async {
    setState(() {
      _isProcessing = true;
      _processMessage = 'Menghubungkan ke Merchant Pembayaran...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      _processMessage = 'Memproses Transaksi Aman (Uji Coba)...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      _processMessage = 'Memverifikasi Lisensi Cobalt Fortress...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final selectedPkg = _packages[_selectedPackageIndex];
    final months = selectedPkg['months'] as int;

    // Aktifkan premium di global state
    await widget.appState.upgradeToPremium(months);

    // Sync premium state to Supabase as well
    final authService = AuthService();
    if (authService.currentUser != null) {
      try {
        final lockedPackages = widget.appState.apps
            .where((a) => a.isLocked)
            .map((a) => a.packageName)
            .toList();
        await authService.syncSettings(
          masterLockEnabled: widget.appState.masterLockEnabled,
          difficultyLevel: widget.appState.difficultyLevel,
          biometricEnabled: widget.appState.biometricEnabled,
          isDarkTheme: widget.appState.isDarkTheme,
          isPremium: true,
          premiumExpiry: widget.appState.premiumExpiry,
          lockedPackages: lockedPackages,
        );
      } catch (e) {
        debugPrint('Error syncing settings to Supabase after mock purchase: $e');
      }
    }

    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });

    // Tunggu sebentar untuk memperlihatkan layar sukses ke pengguna
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Selamat! Akun Cobalt Premium Anda telah aktif (Simulasi).',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpgradePress() {
    if (_isStoreActive) {
      final selectedPkg = _packages[_selectedPackageIndex];
      final productId = selectedPkg['id'] as String;
      final storeProduct = _products.firstWhere((p) => p.id == productId, orElse: () => _products[_selectedPackageIndex]);
      _buyProduct(storeProduct);
    } else {
      if (kDebugMode) {
        _startMockPayment();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Play Billing tidak tersedia saat ini. Silakan coba lagi nanti.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPrice(int index) {
    if (_isStoreActive && index < _products.length) {
      return _products[index].price;
    }
    return _packages[index]['price'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            AmbientGlow.primary(
              top: -size.height * 0.05,
              right: -size.width * 0.1,
              size: size.width * 0.5,
              sigmaX: 80,
              sigmaY: 80,
              alpha: 0.15,
              context: context,
            ),
            AmbientGlow.tertiary(
              bottom: -size.height * 0.1,
              left: -size.width * 0.1,
              size: size.width * 0.5,
              sigmaX: 80,
              sigmaY: 80,
              alpha: 0.1,
              context: context,
            ),

            if (_isProcessing)
              _buildProcessingScreen(theme)
            else if (_isSuccess)
              _buildSuccessScreen(theme)
            else
              _buildMainUpgradeScreen(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMainUpgradeScreen(ThemeData theme) {
    final bool showSimulationButton = !_isStoreActive && kDebugMode;
    final bool showOfflineWarning = !_isStoreActive && !kDebugMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header Title
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'COBALT PREMIUM',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Promotion Text Card
                GlowContainer(
                  glowType: GlowType.primary,
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Unlock Kebebasan Maksimal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Proteksi tanpa batas untuk seluruh aplikasi penting Anda dengan satu langkah mudah.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (showOfflineWarning) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Layanan Google Play Store tidak terdeteksi atau belum siap. Pembelian tidak dapat dilakukan saat ini.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else if (_loadingProducts && _isAvailable) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Benefits List
                Text(
                  'KEUNTUNGAN PREMIUM:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ..._benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline, color: theme.colorScheme.tertiary, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit,
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 24),

                // Package choices
                Text(
                  'PILIH PAKET ANDA:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_packages.length, (index) {
                  final pkg = _packages[index];
                  final isSelected = _selectedPackageIndex == index;
                  final borderCol = isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedPackageIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: borderCol,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      pkg['duration'] as String,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (pkg['popular'] as bool) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'POPULER',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pkg['discount'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _getPrice(index),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                pkg['priceSub'] as String,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Purchase Button Action
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: (showOfflineWarning) ? null : _handleUpgradePress,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: showOfflineWarning
                        ? theme.colorScheme.outlineVariant
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: showOfflineWarning
                        ? null
                        : [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    showSimulationButton
                        ? 'MULAI SIMULASI UPGRADE'
                        : 'PROSES UPGRADE SEKARANG',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: showOfflineWarning
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                showOfflineWarning
                    ? 'Gagal memuat produk dari Google Play.'
                    : showSimulationButton
                        ? 'Mode Debug: Simulasi lokal aktif. Tidak menggunakan uang asli.'
                        : 'Transaksi diproses secara aman oleh Google Play Billing.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: showOfflineWarning ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: showOfflineWarning ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingScreen(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'PEMBELIAN SEDANG DIPROSES',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _processMessage,
              key: ValueKey<String>(_processMessage),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Celebratory Shield
            GlowContainer(
              glowType: GlowType.tertiary,
              backgroundColor: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: theme.colorScheme.tertiary, width: 2),
              padding: const EdgeInsets.all(28),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 64,
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'UPGRADE BERHASIL!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Terima kasih atas pembelian Anda. Akun Anda kini memiliki akses tak terbatas ke semua fitur premium.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
