import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';

class RideSyncScreen extends ConsumerStatefulWidget {
  const RideSyncScreen({super.key});

  @override
  ConsumerState<RideSyncScreen> createState() => _RideSyncScreenState();
}

class _RideSyncScreenState extends ConsumerState<RideSyncScreen> {
  final List<Map<String, dynamic>> _mockCarpools = [
    {
      'id': '1',
      'driver': 'Arjun Mehta',
      'destination': 'Metro Tech Station',
      'time': '08:30 AM',
      'seats': 4,
      'filled': 2,
      'cost': 45.0,
      'isBooked': false,
    },
    {
      'id': '2',
      'driver': 'Sonia Sen',
      'destination': 'Downtown Business Hub',
      'time': '09:00 AM',
      'seats': 3,
      'filled': 2,
      'cost': 60.0,
      'isBooked': false,
    },
  ];

  Widget _glassContainer({required Widget child, double padding = 16, double borderRadius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            AppBar(
              title: const Text('RIDESYNC',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  _buildMapMock(accentColor),
                  _buildCarpoolOverlay(accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildMapMock(Color accentColor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.2),
      child: CustomPaint(
        painter: _RoutePainter(accentColor),
      ),
    );
  }

  Widget _buildCarpoolOverlay(Color accentColor) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 320,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACTIVE CARPOOLS NEARBY',
                style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: _mockCarpools.length,
                itemBuilder: (context, index) {
                  final carpool = _mockCarpools[index];
                  final availableSeats = carpool['seats'] - carpool['filled'];
                  final isBooked = carpool['isBooked'] as bool;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _glassContainer(
                      padding: 16,
                      borderRadius: 20,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.directions_car_rounded, color: accentColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(carpool['destination'] as String,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text('Driver: ${carpool['driver']}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, color: accentColor, size: 12),
                                    const SizedBox(width: 4),
                                    Text(carpool['time'] as String,
                                        style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.people_outline_rounded, color: Colors.white38, size: 12),
                                    const SizedBox(width: 4),
                                    Text('$availableSeats seats left',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (isBooked) {
                                  carpool['filled'] = carpool['filled'] - 1;
                                  carpool['isBooked'] = false;
                                } else {
                                  if (availableSeats > 0) {
                                    carpool['filled'] = carpool['filled'] + 1;
                                    carpool['isBooked'] = true;
                                  }
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBooked ? Colors.greenAccent : accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              isBooked ? 'BOOKED' : '₹${(carpool['cost'] as double).toInt()}',
                              style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
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
}

class _RoutePainter extends CustomPainter {
  final Color routeColor;
  _RoutePainter(this.routeColor);

  @override
  void paint(Canvas canvas, Size size) {
    // Background roads visual grid
    final paintRoad = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final pathRoad1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.2);

    final pathRoad2 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.8, size.height);

    canvas.drawPath(pathRoad1, paintRoad);
    canvas.drawPath(pathRoad2, paintRoad);

    // Glowing carpool polyline path
    final paintRouteGlow = Paint()
      ..color = routeColor.withValues(alpha: 0.25)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintRoute = Paint()
      ..color = routeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pathRoute = Path()
      ..moveTo(size.width * 0.3, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.4, size.width * 0.5, size.height * 0.7);

    canvas.drawPath(pathRoute, paintRouteGlow);
    canvas.drawPath(pathRoute, paintRoute);

    // Active pins representation
    final paintPinOuter = Paint()..color = routeColor.withValues(alpha: 0.25);
    final paintPinInner = Paint()..color = routeColor;

    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.1), 16, paintPinOuter);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.1), 6, paintPinInner);

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 20, paintPinOuter);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 8, paintPinInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
