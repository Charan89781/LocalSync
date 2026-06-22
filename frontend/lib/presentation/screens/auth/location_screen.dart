import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../common_widgets/premium_widgets.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(17.3850, 78.4867); // Hyderabad Default
  bool _isLoading = false;

  Future<void> _getUserLocation() async {
    setState(() => _isLoading = true);
    try {
      final position =
          await ref.read(locationServiceProvider).getCurrentLocation();
      final newPos = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPos;
        _isLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPos, zoom: 15),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      body: Stack(
        children: [
          // Real Google Map
          Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: _currentPosition, zoom: 12),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: {
                      Marker(
                        markerId: const MarkerId('current'),
                        position: _currentPosition,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueCyan,
                        ),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    style: _mapStyle, // Dark mode map
                  ),
                ),
              ),
              _buildBottomContent(),
            ],
          ),

          // Back Button in a floating glass pill
          Positioned(
            top: 50,
            left: 20,
            child: GlassCard(
              borderRadius: 14,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A121A),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirm locality',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'LocalSync establishes a localized community portal within a 2km radius of your neighborhood.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // Auto detect button
          ElevatedButton.icon(
            onPressed: _getUserLocation,
            icon: const Icon(Icons.gps_fixed_rounded, size: 18),
            label: Text(
              'AUTO-DETECT LOCATION',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonCyan.withValues(alpha: 0.08),
              foregroundColor: AppColors.neonCyan,
              elevation: 0,
              side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.4), width: 1.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Confirm button
          GradientButton(
            label: 'Confirm & Continue',
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Dark Map Style JSON
  final String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#18222c"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#18222c"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#00d1ff"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#00d1ff"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#143038"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#24313d"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1a2530"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8a97a7"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2d4455"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1e2a35"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#202e3b"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#0c1520"
      }
    ]
  }
]
''';
}

