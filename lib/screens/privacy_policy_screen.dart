import 'package:flutter/material.dart';
import '../widgets/ambient_glow.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'PRIVACY POLICY',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Glows for premium futuristic UI
          AmbientGlow.primary(
            top: 50,
            left: -80,
            size: 300,
            context: context,
          ),
          AmbientGlow.tertiary(
            bottom: 100,
            right: -80,
            size: 300,
            context: context,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIntroCard(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'IZIN SENSITIF (CRITICAL PERMISSIONS)', Icons.security_rounded),
                  const SizedBox(height: 12),
                  _buildPermissionCard(
                    context,
                    title: 'Usage Access (Akses Penggunaan)',
                    permissionCode: 'PACKAGE_USAGE_STATS',
                    purpose: 'Mendeteksi aplikasi yang sedang dibuka di latar depan (foreground) secara real-time.',
                    justification: 'Izin ini sangat penting bagi MathLock untuk mendeteksi kapan aplikasi yang Anda kunci sedang diluncurkan, sehingga sistem pengunci kami dapat segera aktif dan melindunginya.',
                    icon: Icons.query_stats_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionCard(
                    context,
                    title: 'Display Over Other Apps (Tampilkan di Atas Aplikasi Lain)',
                    permissionCode: 'SYSTEM_ALERT_WINDOW',
                    purpose: 'Menampilkan layar tantangan matematika di atas aplikasi lain yang sedang dikunci.',
                    justification: 'Izin ini digunakan untuk menampilkan dialog tantangan matematika MathLock secara instan di atas aplikasi yang dilindungi, mencegah akses tanpa izin sebelum tantangan diselesaikan dengan benar.',
                    icon: Icons.layers_rounded,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'PENGUMPULAN & PENYIMPANAN DATA', Icons.dns_rounded),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    title: 'Penyimpanan Lokal (SQLite)',
                    content: 'MathLock menyimpan data lokal pada perangkat Anda seperti pengaturan proteksi, daftar aplikasi yang dikunci, dan riwayat tantangan matematika. Data ini sepenuhnya berada di bawah kendali Anda dan dapat dihapus kapan saja dengan membersihkan data aplikasi.',
                    icon: Icons.storage_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: 'Sinkronisasi Cloud (Supabase)',
                    content: 'Jika Anda menggunakan fitur Akun, MathLock menyinkronkan data konfigurasi kunci dan statistik performa (riwayat tantangan benar/salah) ke server Supabase kami. Sinkronisasi ini bertujuan untuk mengamankan data Anda agar tidak hilang saat berganti perangkat dan untuk menyajikan grafik statistik analisis belajar Anda.',
                    icon: Icons.cloud_sync_rounded,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'LAYANAN PIHAK KETIGA', Icons.share_rounded),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    title: 'Google Mobile Ads (AdMob)',
                    content: 'Kami menampilkan iklan untuk mendukung pengembangan aplikasi gratis ini. Google AdMob dapat mengumpulkan pengenal perangkat iklan (Advertising ID), alamat IP, serta statistik interaksi iklan guna menyajikan iklan yang relevan atau dipersonalisasi.',
                    icon: Icons.ads_click_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: 'Google Play Billing API',
                    content: 'Untuk pembelian fitur Premium, transaksi Anda diproses secara aman oleh Google Play Billing. MathLock tidak pernah mengumpulkan atau menyimpan informasi kartu kredit, detail bank, atau data metode pembayaran Anda.',
                    icon: Icons.payment_rounded,
                  ),
                  const SizedBox(height: 24),
                  _buildContactCard(context),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    final theme = Theme.of(context);
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.privacy_tip_rounded, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'KEBIJAKAN PRIVASI',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Selamat datang di Kebijakan Privasi MathLock (Cobalt Fortress). Kami sangat menghargai privasi Anda. Dokumen ini menjelaskan bagaimana kami mengelola izin perangkat, penyimpanan data lokal/cloud, dan integrasi iklan dalam aplikasi untuk memberikan pengalaman belajar & penguncian yang aman.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context, {
    required String title,
    required String permissionCode,
    required String purpose,
    required String justification,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        permissionCode,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.5,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            'Tujuan Akses:',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            purpose,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mengapa ini Dibutuhkan (Justifikasi):',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            justification,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.tertiary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.mail_outline_rounded, color: theme.colorScheme.primary, size: 32),
          const SizedBox(height: 16),
          Text(
            'HUBUNGI DUKUNGAN PRIVASI',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jika Anda memiliki pertanyaan tentang kebijakan privasi ini atau penggunaan data Anda, silakan hubungi kami melalui surel di bawah ini:',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: SelectionArea(
              child: Text(
                'support@danibaret014.com',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
