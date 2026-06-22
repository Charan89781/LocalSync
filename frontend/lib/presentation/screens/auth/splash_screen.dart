import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  
  late Animation<double> _mainScale;
  late Animation<double> _mainOpacity;
  late Animation<Offset> _mainSlide;
  
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      SemanticsBinding.instance.ensureSemantics();
    }

    // Main Instagram-style Zoom, Fade & Slide animation (1600ms)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Elegant smooth scale-up zoom from 1.0 to 1.12 (no zoom-out/shrinking!)
    _mainScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Smooth fade in
    _mainOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    // Completely locked vertically to prevent any downward pop
    _mainSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Pulse animation around the logo (running continuously)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    _mainController.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Go directly into the app after a premium 1.0-second brand hold!
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    if (authState.value != null) {
      context.go('/dashboard');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      body: Stack(
        children: [
          // Background subtle ambient lights
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withValues(alpha: 0.08),
                backgroundBlendMode: BlendMode.screen,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                backgroundBlendMode: BlendMode.screen,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // Centered high-resolution branding unit zooming and floating smoothly
          Center(
            child: ScaleTransition(
              scale: _mainScale,
              child: SlideTransition(
                position: _mainSlide,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Card (Perfect Square white card with emblem logo)
                    Container(
                      width: 180,
                      height: 180,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 28,
                            spreadRadius: 4,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.25),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/app_symbol.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Brand Name "LOCALSync"
                    Text(
                      'LOCALSync',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.4),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Official Tagline
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'BUILDING STRONGER COMMUNITY CONNECTIONS',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9DECFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: AppColors.neonCyan.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // Subtle spinning active loader
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.neonCyan.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Hexagon custom painter for premium look
class HexagonPainter extends CustomPainter {
  final Color color;
  final Color strokeColor;

  HexagonPainter({required this.color, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.2),
          AppColors.primaryNavy.withValues(alpha: 0.8),
        ],
        radius: 0.8,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.neonCyan,
          AppColors.primaryBlue,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
