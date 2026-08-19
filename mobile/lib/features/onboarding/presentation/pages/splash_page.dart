import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sip_sistem_absensi_mobile/core/services/app_settings_service.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_colors.dart';
import 'package:sip_sistem_absensi_mobile/core/theme/app_typography.dart';
import 'package:sip_sistem_absensi_mobile/features/auth/services/auth_state.dart';
import '../../services/onboarding_service.dart';

/// Halaman pembuka (Splash Screen) resmi yang menampilkan logo perusahaan
/// dan nama instansi dari tabel [settings] Supabase saat aplikasi dibuka.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _initializeAppAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeAppAndNavigate() async {
    final startTime = DateTime.now();

    // Inisialisasi service konfigurasi branding dan sesi login di background
    try {
      await Future.wait([
        AppSettingsService.instance.initialize(),
        AuthState.instance.initialize(),
      ]);
    } catch (e) {
      debugPrint('[SplashPage] Error during bootstrap: $e');
    }

    // Pastikan Splash Screen tampil minimal 1.6 detik agar visual logo dinikmati pengguna
    final elapsed = DateTime.now().difference(startTime);
    const minSplashDuration = Duration(milliseconds: 1600);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (!mounted) return;

    final onboardingCompleted = await OnboardingService.isCompleted();
    if (!mounted) return;

    if (AuthState.instance.isLoggedIn) {
      context.go('/attendance');
    } else if (onboardingCompleted) {
      context.go('/login');
    } else {
      context.go('/onboarding');
    }
  }

  Widget _buildLogo(String logoPath) {
    // 1. Jika berupa URL lengkap (HTTP / HTTPS)
    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      return Image.network(
        logoPath,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackLogo(),
      );
    }

    // 2. Jika berupa path Supabase Storage atau path relatif (misal: 'images/logo-sip.png')
    if (logoPath.isNotEmpty && !logoPath.startsWith('assets/')) {
      final storageUrl = '${SupabaseConfig.url}/storage/v1/object/public/$logoPath';
      return Image.network(
        storageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackLogo(),
      );
    }

    // 3. Jika berupa asset lokal yang valid
    if (logoPath.startsWith('assets/')) {
      return Image.asset(
        logoPath,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackLogo(),
      );
    }

    return _buildFallbackLogo();
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.corporate_fare_rounded,
        size: 58,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AppSettingsService.instance,
          builder: (context, _) {
            final settings = AppSettingsService.instance;

            return Stack(
              children: [
                // Background Soft Glow
                Positioned(
                  top: -80,
                  left: -80,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  right: -60,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // Center Content: Logo & Company Name
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 28,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: _buildLogo(settings.companyLogo),
                          ),
                          const SizedBox(height: 28),

                          // Company Name
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              settings.companyName,
                              textAlign: TextAlign.center,
                              style: AppTypography.textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tagline
                          Text(
                            'Sistem Informasi Presensi & Kehadiran',
                            textAlign: TextAlign.center,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Loader & Version
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Versi 1.0.0',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
