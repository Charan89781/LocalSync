import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/premium_widgets.dart';
import '../../common_widgets/app_bottom_nav.dart';

class ArScreen extends ConsumerStatefulWidget {
  const ArScreen({super.key});

  @override
  ConsumerState<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends ConsumerState<ArScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  bool _hasPermission = false;
  bool _isRequesting = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _hasPermission = true;
        _isRequesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      body: Stack(
        children: [
          // Camera stream mock background
          _hasPermission ? _buildCameraMock() : _buildPermissionScreen(),

          // Radar scan line (only if permission granted)
          if (_hasPermission) ...[
            _buildRadarSweep(),
            _buildArOverlayCards(),
            _buildArCategorySelector(),
          ],

          // App Header
          _buildHeader(),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildCameraMock() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.15,
          child: Image.network(
            'https://picsum.photos/1080/1920',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0A121A)),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionScreen() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      alignment: Alignment.center,
      child: GlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withOpacity(0.08),
              ),
              child: const Icon(
                Icons.camera_outlined,
                size: 64,
                color: AppColors.neonCyan,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'LocalSync AR HUD overlay requires camera access to overlay neighborhood details on your actual surroundings.',
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _isRequesting
                ? const Center(child: CircularProgressIndicator())
                : GradientButton(
                    label: 'Grant Camera Access',
                    onPressed: _requestPermission,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarSweep() {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        return CustomPaint(
          painter: RadarSweepPainter(
            sweepVal: _radarController.value,
            color: AppColors.neonCyan,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildArOverlayCards() {
    // Generate filtered options
    final List<Widget> cards = [];

    if (_selectedCategory == 'All' || _selectedCategory == 'Shops') {
      cards.add(
        Positioned(
          top: 180,
          left: 40,
          child: _buildFloatingARCard(
            category: 'NEAREST SHOP',
            title: 'Daily Basket Grocers',
            subtitle: 'Distance: 140m • Open now',
            icon: Icons.storefront_rounded,
            color: AppColors.neonCyan,
          ),
        ),
      );
    }

    if (_selectedCategory == 'All' || _selectedCategory == 'ATMs') {
      cards.add(
        Positioned(
          top: 320,
          right: 30,
          child: _buildFloatingARCard(
            category: 'ATM DISPENSARY',
            title: 'HDFC Bank ATM',
            subtitle: 'Distance: 320m • Cash Available',
            icon: Icons.atm_rounded,
            color: Colors.greenAccent,
          ),
        ),
      );
    }

    if (_selectedCategory == 'All' || _selectedCategory == 'Transit') {
      cards.add(
        Positioned(
          bottom: 220,
          left: 30,
          child: _buildFloatingARCard(
            category: 'BUS STOP ETA',
            title: 'Route 104 - City Central',
            subtitle: 'Distance: 450m • Departs in 8 mins',
            icon: Icons.directions_bus_filled_outlined,
            color: Colors.amberAccent,
          ),
        ),
      );
    }

    if (_selectedCategory == 'All' || _selectedCategory == 'Clinics') {
      cards.add(
        Positioned(
          top: 480,
          left: 80,
          child: _buildFloatingARCard(
            category: 'HEALTH CLINIC',
            title: 'CareFirst Pediatric',
            subtitle: 'Distance: 210m • 3 doctors active',
            icon: Icons.medical_services_outlined,
            color: AppColors.errorRed,
          ),
        ),
      );
    }

    return Stack(children: cards);
  }

  Widget _buildFloatingARCard({
    required String category,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SizedBox(
        width: 230,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArCategorySelector() {
    final categories = ['All', 'Shops', 'ATMs', 'Transit', 'Clinics'];

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = _selectedCategory == cat;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neonCyan.withOpacity(0.16) : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.neonCyan : Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlassCard(
            borderRadius: 14,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          Text(
            'AR Live HUD',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 44), // balance spacing
        ],
      ),
    );
  }
}

class RadarSweepPainter extends CustomPainter {
  final double sweepVal;
  final Color color;

  RadarSweepPainter({required this.sweepVal, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    final paintRings = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, maxRadius * 0.33, paintRings);
    canvas.drawCircle(center, maxRadius * 0.66, paintRings);
    canvas.drawCircle(center, maxRadius, paintRings);

    // Radar sweep arc
    final sweepAngle = sweepVal * 2 * math.pi;

    final paintSweep = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius),
      sweepAngle,
      math.pi / 4,
      true,
      paintSweep,
    );

    // Active sweep line
    final paintSweepLine = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double sweepEndX = center.dx + maxRadius * math.cos(sweepAngle);
    final double sweepEndY = center.dy + maxRadius * math.sin(sweepAngle);
    canvas.drawLine(center, Offset(sweepEndX, sweepEndY), paintSweepLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

