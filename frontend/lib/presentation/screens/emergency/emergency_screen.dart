import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/emergency_entity.dart';
import '../../../domain/entities/emergency_contact_entity.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/services/location_service.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> with TickerProviderStateMixin {
  bool _isSOSActive = false;
  GoogleMapController? _mapController;
  LatLng _myLocation = const LatLng(17.3850, 78.4867); // Hyderabad Default
  double _radarRadius = 100.0;
  Timer? _radarTimer;
  bool _disposed = false;

  late AnimationController _sosPulseController;
  Timer? _hapticTimer;
  double _holdProgress = 0.0;
  bool _isPressing = false;

  @override
  void initState() {
    super.initState();
    _startRadarPulse();
    _fetchCurrentLocation();

    _sosPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  void _startRadarPulse() {
    _radarTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_disposed) return;
      setState(() {
        _radarRadius += 12.0;
        if (_radarRadius > 600.0) {
          _radarRadius = 100.0;
        }
      });
    });
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentLocation();
      if (!_disposed) {
        setState(() {
          _myLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (e) {
      debugPrint('Could not fetch coordinates for tactical radar: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _radarTimer?.cancel();
    _hapticTimer?.cancel();
    _sosPulseController.dispose();
    super.dispose();
  }

  void _startHoldCountdown() {
    if (_isSOSActive) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isPressing = true;
      _holdProgress = 0.0;
    });

    int tick = 0;
    const totalTicks = 20; // 2 seconds (100ms interval)

    _hapticTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPressing || _disposed) {
        timer.cancel();
        return;
      }

      tick++;
      
      // Continuous tactile feedback loop with increasing intensity
      if (tick < 10) {
        HapticFeedback.lightImpact();
      } else if (tick < 17) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }

      setState(() {
        _holdProgress = tick / totalTicks;
      });

      if (tick >= totalTicks) {
        timer.cancel();
        _triggerSOS();
        _cancelHoldCountdown();
      }
    });
  }

  void _cancelHoldCountdown() {
    _hapticTimer?.cancel();
    setState(() {
      _isPressing = false;
      _holdProgress = 0.0;
    });
  }

  Future<void> _triggerSOS() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isSOSActive = true);

    try {
      final position =
          await ref.read(locationServiceProvider).getCurrentLocation();

      final alert = EmergencyAlertEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: user.id,
        senderName: user.name ?? 'Neighbor',
        message: 'EMERGENCY: SOS triggered! I need immediate assistance.',
        latitude: position.latitude,
        longitude: position.longitude,
        severity: AlertSeverity.critical,
        timestamp: DateTime.now(),
      );

      await ref.read(emergencyRepositoryProvider).triggerSOS(alert);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Alert Broadcasted to Neighbors!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to trigger SOS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSOSActive = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAlertsAsync = ref.watch(activeAlertsProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('EMERGENCY CENTER',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 110, 24, 24),
          child: Column(
            children: [
              _buildSOSButton(),
              const SizedBox(height: 32),
              WalkieTalkieWidget(accentColor: accentColor),
              const SizedBox(height: 32),
              _buildRadarMap(activeAlertsAsync, accentColor),
              const SizedBox(height: 32),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildRegionalHelplines(accentColor),
              const SizedBox(height: 32),
              _buildEmergencyContacts(ref, accentColor),
              const SizedBox(height: 32),
              _buildActiveAlerts(activeAlertsAsync, accentColor),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // pulsing concentric rings
          ...List.generate(3, (index) {
            final startDelay = index * 0.33;
            return AnimatedBuilder(
              animation: _sosPulseController,
              builder: (context, child) {
                double progress = _sosPulseController.value - startDelay;
                if (progress < 0) progress += 1.0;

                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final scale = 1.0 + progress * 0.8;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withOpacity(opacity * 0.4),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Progress indicator around the button
          SizedBox(
            width: 216,
            height: 216,
            child: CircularProgressIndicator(
              value: _holdProgress,
              strokeWidth: 4,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),

          GestureDetector(
            onTapDown: (_) => _startHoldCountdown(),
            onTapUp: (_) => _cancelHoldCountdown(),
            onTapCancel: () => _cancelHoldCountdown(),
            child: AnimatedScale(
              scale: _isPressing ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.sosGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: _isPressing ? 40 : 24,
                      spreadRadius: _isPressing ? 12 : 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSOSActive)
                      const CircularProgressIndicator(color: Colors.white)
                    else ...[
                      const Icon(Icons.warning_amber_rounded,
                          size: 64, color: Colors.white),
                      const SizedBox(height: 8),
                      const Text('SOS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1)),
                      Text(
                          _isPressing ? 'HOLDING...' : 'HOLD TO TRIGGER',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarMap(AsyncValue<List<EmergencyAlertEntity>> alertsAsync, Color accentColor) {
    return alertsAsync.when(
      data: (alerts) {
        final hasAlerts = alerts.isNotEmpty;
        final targetLatLng = hasAlerts
            ? LatLng(alerts.first.latitude, alerts.first.longitude)
            : _myLocation;

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: targetLatLng, zoom: hasAlerts ? 15 : 14),
          ),
        );

        final Set<Marker> markers = {};
        final Set<Circle> circles = {};
        final Set<Polyline> polylines = {};

        if (hasAlerts) {
          for (var alert in alerts) {
            markers.add(
              Marker(
                markerId: MarkerId('hazard_${alert.id}'),
                position: LatLng(alert.latitude, alert.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: alert.senderName, snippet: alert.message),
              ),
            );

            circles.add(
              Circle(
                circleId: CircleId('pulse_${alert.id}'),
                center: LatLng(alert.latitude, alert.longitude),
                radius: _radarRadius,
                fillColor: Colors.red.withOpacity(0.12),
                strokeColor: Colors.red.withOpacity(0.8),
                strokeWidth: 2,
              ),
            );

            circles.add(
              Circle(
                circleId: CircleId('bounds_${alert.id}'),
                center: LatLng(alert.latitude, alert.longitude),
                radius: 600.0,
                fillColor: Colors.red.withOpacity(0.03),
                strokeColor: Colors.red.withOpacity(0.2),
                strokeWidth: 1,
              ),
            );

            // Simulated active responders en route
            final r1 = LatLng(alert.latitude + 0.0022, alert.longitude - 0.0025);
            final r2 = LatLng(alert.latitude - 0.0016, alert.longitude + 0.0030);

            markers.add(
              Marker(
                markerId: MarkerId('responder1_${alert.id}'),
                position: r1,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Responder: Rahul', snippet: 'En route (2 min)'),
              ),
            );

            markers.add(
              Marker(
                markerId: MarkerId('responder2_${alert.id}'),
                position: r2,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Responder: Amit', snippet: 'En route (4 min)'),
              ),
            );

            polylines.add(
              Polyline(
                polylineId: PolylineId('path1_${alert.id}'),
                points: [r1, LatLng(alert.latitude, alert.longitude)],
                color: Colors.green,
                width: 3,
                patterns: [PatternItem.dash(10), PatternItem.gap(10)],
              ),
            );

            polylines.add(
              Polyline(
                polylineId: PolylineId('path2_${alert.id}'),
                points: [r2, LatLng(alert.latitude, alert.longitude)],
                color: Colors.green,
                width: 3,
                patterns: [PatternItem.dash(10), PatternItem.gap(10)],
              ),
            );
          }
        } else {
          markers.add(
            Marker(
              markerId: const MarkerId('my_position'),
              position: _myLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
              infoWindow: const InfoWindow(title: 'Your Location', snippet: 'Safety Perimeter Active'),
            ),
          );

          circles.add(
            Circle(
              circleId: const CircleId('perimeter'),
              center: _myLocation,
              radius: 300.0,
              fillColor: accentColor.withOpacity(0.1),
              strokeColor: accentColor.withOpacity(0.4),
              strokeWidth: 2,
            ),
          );
        }

        return Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: targetLatLng,
                zoom: hasAlerts ? 15 : 14,
              ),
              markers: markers,
              circles: circles,
              polylines: polylines,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              style: _darkRadarMapStyle,
            ),
          ),
        );
      },
      loading: () => SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator(color: accentColor)),
      ),
      error: (err, _) => const SizedBox(),
    );
  }

  Widget _buildRegionalHelplines(Color accentColor) {
    final helplines = [
      {'name': 'National Helpline', 'num': '112', 'icon': Icons.public},
      {'name': 'Women Helpline', 'num': '1091', 'icon': Icons.woman},
      {'name': 'Child Helpline', 'num': '1098', 'icon': Icons.child_care},
      {'name': 'Senior Citizen', 'num': '14567', 'icon': Icons.elderly},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Official Helplines',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          ),
          child: Column(
            children: helplines
                .map((h) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(h['icon'] as IconData,
                            color: accentColor, size: 20),
                      ),
                      title: Text(h['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)),
                      subtitle: Text(h['num'] as String,
                          style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12)),
                      trailing: IconButton(
                        onPressed: () =>
                            launchUrl(Uri.parse('tel:${h['num']}')),
                        icon: const Icon(Icons.call_rounded,
                            color: Colors.green, size: 20),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(Icons.local_police_outlined, 'Police', Colors.blue),
        _buildActionItem(
            Icons.medical_services_outlined, 'Ambulance', Colors.red),
        _buildActionItem(
            Icons.local_fire_department_outlined, 'Fire', Colors.orange),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildActiveAlerts(
      AsyncValue<List<EmergencyAlertEntity>> alertsAsync, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Neighborhood Alerts',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5)),
        const SizedBox(height: 16),
        alertsAsync.when(
          data: (alerts) => alerts.isEmpty
              ? const Center(
                  child: Text('No active emergencies nearby.',
                      style: TextStyle(color: Colors.white30)))
              : Column(
                  children:
                      alerts.map((alert) => _buildAlertCard(alert, accentColor)).toList(),
                ),
          loading: () => Center(child: CircularProgressIndicator(color: accentColor)),
          error: (err, _) => Center(
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Firestore Index Needed',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Please check your debug logs and click the Firestore link to create the required composite index.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
                Text('Error: $err',
                    style: const TextStyle(fontSize: 10, color: Colors.red)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContacts(WidgetRef ref, Color accentColor) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Emergency Contacts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            IconButton(
              onPressed: () => _showAddContactSheet(context, ref, user.id, accentColor),
              icon: Icon(Icons.add_circle_outline,
                  color: accentColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<EmergencyContactEntity>>(
          stream: ref
              .read(emergencyRepositoryProvider)
              .getEmergencyContacts(user.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.contact_phone_outlined,
                        color: Colors.white30, size: 32),
                    SizedBox(height: 12),
                    Text('No emergency contacts added yet.',
                        style: TextStyle(color: Colors.white30)),
                  ],
                ),
              );
            }
            return Column(
              children:
                  snapshot.data!.map((c) => _buildContactCard(c, accentColor)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactCard(EmergencyContactEntity contact, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withOpacity(0.15),
            child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
                style: TextStyle(
                    color: accentColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(contact.relation,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => launchUrl(Uri.parse('tel:${contact.phone}')),
            icon: const Icon(Icons.call_rounded, color: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showAddContactSheet(
      BuildContext context, WidgetRef ref, String userId, Color accentColor) {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final relC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withOpacity(0.95),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add Emergency Contact',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameC,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: const TextStyle(color: Colors.white54),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneC,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: const TextStyle(color: Colors.white54),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: relC,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Relation',
                      labelStyle: const TextStyle(color: Colors.white54),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameC.text.isEmpty || phoneC.text.isEmpty) return;
                      final contact = EmergencyContactEntity(
                        id: '',
                        name: nameC.text,
                        phone: phoneC.text,
                        relation: relC.text,
                      );
                      await ref
                          .read(emergencyRepositoryProvider)
                          .addEmergencyContact(userId, contact);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('SAVE CONTACT', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(EmergencyAlertEntity alert, Color accentColor) {
    final user = ref.read(authStateProvider).value;
    final isResponding = user != null && alert.responderIds.contains(user.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isResponding
                ? Colors.green
                : Colors.red.withOpacity(0.2),
            width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.emergency, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.senderName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(alert.message,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              if (alert.responderIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${alert.responderIds.length}',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isResponding
                ? null
                : () => ref
                    .read(emergencyRepositoryProvider)
                    .respondToAlert(alert.id, user!.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: isResponding ? Colors.green : Colors.red,
              disabledBackgroundColor: Colors.green.withOpacity(0.3),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isResponding ? 'HELP IS ON THE WAY' : 'RESPOND', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Dark Map Style JSON
  final String _darkRadarMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1e272c"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#1e272c"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1b2429"
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
        "color": "#2c3e50"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#212a37"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#34495e"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f2835"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2f3948"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#0f171e"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#0f171e"
      }
    ]
  }
]
''';
}

class WalkieTalkieWidget extends StatefulWidget {
  final Color accentColor;

  const WalkieTalkieWidget({super.key, required this.accentColor});

  @override
  State<WalkieTalkieWidget> createState() => _WalkieTalkieWidgetState();
}

class _WalkieTalkieWidgetState extends State<WalkieTalkieWidget> with SingleTickerProviderStateMixin {
  bool _isTalking = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTalkStart() {
    setState(() {
      _isTalking = true;
    });
    _animationController.repeat();
  }

  void _onTalkEnd() {
    setState(() {
      _isTalking = false;
    });
    _animationController.stop();
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isTalking ? widget.accentColor : Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isTalking ? widget.accentColor : Colors.green).withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isTalking ? 'DISPATCH LIVE' : 'CHANNEL ACTIVE',
                    style: TextStyle(
                      color: _isTalking ? widget.accentColor : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const Text(
                'CH-09 Mhz',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: WaveformPainter(
                animation: _animationController,
                isTalking: _isTalking,
                accentColor: widget.accentColor,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTapDown: (_) => _onTalkStart(),
            onTapUp: (_) => _onTalkEnd(),
            onTapCancel: () => _onTalkEnd(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isTalking)
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final progress = (_animationController.value + (index / 3)) % 1.0;
                        return Container(
                          width: 80 + (progress * 80),
                          height: 80 + (progress * 80),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.accentColor.withOpacity(1.0 - progress),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isTalking ? widget.accentColor : Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: _isTalking ? Colors.white : widget.accentColor.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isTalking ? widget.accentColor : Colors.transparent).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mic_none_rounded,
                    color: _isTalking ? AppColors.primaryNavy : widget.accentColor,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isTalking ? 'RELEASE TO TRANSMIT' : 'HOLD TO TALK',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isTalking;
  final Color accentColor;

  WaveformPainter({
    required this.animation,
    required this.isTalking,
    required this.accentColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final centerY = size.height / 2;
    final width = size.width;

    if (!isTalking) {
      paint.color = Colors.white24;
      canvas.drawLine(Offset(0, centerY), Offset(width, centerY), paint);
      return;
    }

    final waveCount = 3;
    final opacities = [0.8, 0.4, 0.15];
    final frequencies = [1.5, 2.5, 3.5];
    final phaseOffsets = [0.0, 1.2, 2.4];
    final heightScales = [1.0, 0.6, 0.3];

    for (int i = 0; i < waveCount; i++) {
      paint.color = accentColor.withOpacity(opacities[i]);
      final path = Path();
      path.moveTo(0, centerY);

      for (double x = 0; x <= width; x += 2) {
        final normalizedX = x / width;
        final envelope = math.sin(normalizedX * math.pi);
        
        final angle = (normalizedX * math.pi * 2 * frequencies[i]) - 
                      (animation.value * math.pi * 2) + 
                      phaseOffsets[i];
                      
        final y = centerY + math.sin(angle) * (size.height / 2.5) * envelope * heightScales[i];
        
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.animation != animation || 
           oldDelegate.isTalking != isTalking || 
           oldDelegate.accentColor != accentColor;
  }
}

class _WalkieTalkiePulseDot extends StatefulWidget {
  final Color color;
  final int delayMs;
  
  const _WalkieTalkiePulseDot({required this.color, required this.delayMs});
  
  @override
  State<_WalkieTalkiePulseDot> createState() => _WalkieTalkiePulseDotState();
}

class _WalkieTalkiePulseDotState extends State<_WalkieTalkiePulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
