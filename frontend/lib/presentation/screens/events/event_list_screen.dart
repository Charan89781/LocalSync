import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/event_entity.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../../core/services/location_service.dart';
import '../../common_widgets/premium_widgets.dart';

/// Forward-geocodes an address string → lat/lon via OpenStreetMap Nominatim.
/// Returns null if address cannot be resolved.
Future<Map<String, double>?> _forwardGeocode(String address) async {
  try {
    final encoded = Uri.encodeComponent(address);
    final url = 'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept-Language': 'en', 'User-Agent': 'LocalSyncApp/1.0'},
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final list = json.decode(response.body) as List<dynamic>;
      if (list.isNotEmpty) {
        final item = list.first as Map<String, dynamic>;
        return {
          'lat': double.parse(item['lat'] as String),
          'lon': double.parse(item['lon'] as String),
        };
      }
    }
  } catch (_) {}
  return null;
}

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  String _selectedCategory = 'All';
  bool _isMapView = false;
  GoogleMapController? _mapController;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPageIndex = 0;

  final Map<String, String> _categoryImages = {
    'Weekend Meet':
        'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800',
    'Evening Walk':
        'https://images.unsplash.com/photo-1502126324834-38f8e02d7160?w=800',
    'Sports':
        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800',
    'Cleanup':
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=800',
    'Dance':
        'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=800',
    'Cooking':
        'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
    'Pets':
        'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800',
    'Festival':
        'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800',
    'Workshop':
        'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800',
    'Other':
        'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800',
  };

  void _showCreateEventSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locController = TextEditingController();
    String category = 'Weekend Meet';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Theme(
        data: AppTheme.lightTheme,
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Community Event',
                        style:
                            TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: _categoryImages.keys
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: const TextStyle(color: Colors.black87)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => category = v!),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.black54),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        labelStyle: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Location / Address',
                        labelStyle: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.black87),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Event Date', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      subtitle:
                          Text(DateFormat('EEEE, MMM dd').format(selectedDate), style: const TextStyle(color: Colors.black54)),
                      trailing: const Icon(Icons.calendar_today,
                          color: AppColors.primaryBlue),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setSheetState(() => selectedDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () async {
                        final user = ref.read(authStateProvider).value;
                        if (user == null || titleController.text.isEmpty || locController.text.isEmpty) return;
  
                        // Show loading dialog while geocoding
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
  
                        double? lat;
                        double? lon;
  
                        // Use Nominatim HTTP forward geocoding (works on web)
                        final coords = await _forwardGeocode(locController.text);
                        if (coords != null) {
                          lat = coords['lat'];
                          lon = coords['lon'];
                        } else {
                          // Fallback to user GPS
                          try {
                            final pos = await ref.read(locationServiceProvider).getCurrentLocation();
                            lat = pos.latitude;
                            lon = pos.longitude;
                          } catch (_) {
                            lat = 17.3850;
                            lon = 78.4867;
                          }
                        }
  
                        // Dismiss geocoding loading
                        if (context.mounted) Navigator.pop(context);
  
                        final event = EventEntity(
                          id: '',
                          creatorId: user.id,
                          title: titleController.text,
                          description: descController.text,
                          eventDate: selectedDate,
                          location: locController.text,
                          imageUrl: _categoryImages[category],
                          participants: [user.id],
                          latitude: lat,
                          longitude: lon,
                        );
  
                        await ref
                            .read(eventRepositoryProvider)
                            .createEvent(event);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('POST EVENT'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('COMMUNITY EVENTS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.format_list_bulleted_rounded : Icons.map_rounded),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          final filtered = events
              .where((e) =>
                  _selectedCategory == 'All' ||
                  (e.imageUrl != null &&
                      _categoryImages.entries.any((entry) =>
                          entry.value == e.imageUrl &&
                          entry.key == _selectedCategory)))
              .toList();

          if (_isMapView) {
            return _buildMapViewContent(filtered, user?.id);
          } else {
            return _buildListViewContent(filtered, user?.id);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              const Text('Could not load events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              const Text('Check your internet and pull down to refresh', style: TextStyle(color: AppColors.textGray, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(upcomingEventsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventSheet,
        backgroundColor: AppColors.primaryBlue,
        label: const Text('NEW EVENT',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildListViewContent(List<EventEntity> filtered, String? userId) {
    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(upcomingEventsProvider),
            child: filtered.isEmpty
                ? const Center(child: Text('No events in this category.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _buildEventCard(filtered[index], userId),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapViewContent(List<EventEntity> events, String? userId) {
    final markers = events.map((e) {
      final lat = e.latitude ?? 17.3850;
      final lon = e.longitude ?? 78.4867;
      return Marker(
        markerId: MarkerId(e.id),
        position: LatLng(lat, lon),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        onTap: () {
          final index = events.indexOf(e);
          if (index != -1) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
      );
    }).toSet();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: events.isNotEmpty
                ? LatLng(events.first.latitude ?? 17.3850, events.first.longitude ?? 78.4867)
                : const LatLng(17.3850, 78.4867),
            zoom: 13,
          ),
          markers: markers,
          onMapCreated: (controller) {
            _mapController = controller;
            if (events.isNotEmpty) {
              final e = events.first;
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: LatLng(e.latitude ?? 17.3850, e.longitude ?? 78.4867), zoom: 14),
                ),
              );
            }
          },
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          style: _darkMapStyle,
        ),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.transparent,
            child: _buildCategoryFilter(),
          ),
        ),
        if (events.isEmpty)
          const Positioned(
            bottom: 120,
            left: 24,
            right: 24,
            child: GlassCard(
              borderRadius: 20,
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No events in this category.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        else
          _buildMapSwiper(events, userId),
      ],
    );
  }

  Widget _buildMapSwiper(List<EventEntity> events, String? userId) {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: events.length,
        onPageChanged: (index) {
          setState(() => _currentPageIndex = index);
          final e = events[index];
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(e.latitude ?? 17.3850, e.longitude ?? 78.4867), zoom: 15),
            ),
          );
        },
        itemBuilder: (context, index) {
          final event = events[index];
          final isRSVPed = userId != null && event.participants.contains(userId);
          
          return AnimatedScale(
            scale: _currentPageIndex == index ? 1.0 : 0.95,
            duration: const Duration(milliseconds: 250),
            child: GestureDetector(
              onTap: () => _showEventDetail(context, event, userId),
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        event.imageUrl ?? _categoryImages['Other']!,
                        width: 100,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('MMM dd').format(event.eventDate).toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              if (isRSVPed)
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                            ],
                          ),
                          const SizedBox(height: 6),
                           Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primaryBlue),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  event.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textGray, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    HapticFeedback.selectionClick();
                                    final repo = ref.read(eventRepositoryProvider);
                                    if (isRSVPed) {
                                      await FirebaseFirestore.instance.collection('events').doc(event.id).update({
                                        'participants': FieldValue.arrayRemove([userId]),
                                      });
                                    } else {
                                      await repo.rsvpToEvent(event.id, userId!);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRSVPed ? Colors.green : AppColors.primaryBlue,
                                    minimumSize: const Size(double.infinity, 38),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    isRSVPed ? 'GOING' : 'JOIN',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final cats = ['All', ..._categoryImages.keys];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: cats.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : AppColors.textLight,
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: AppColors.primaryBlue.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
                  ] : [],
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventCard(EventEntity event, String? userId) {
    final isRSVPed = userId != null && event.participants.contains(userId);

    return GestureDetector(
      onTap: () => _showEventDetail(context, event, userId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  Image.network(
                    event.imageUrl ?? _categoryImages['Other']!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                          DateFormat('MMM dd')
                              .format(event.eventDate)
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 4),
                      Text(event.location,
                          style: const TextStyle(
                              color: AppColors.textGray, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final repo = ref.read(eventRepositoryProvider);
                      if (isRSVPed) {
                        await FirebaseFirestore.instance.collection('events').doc(event.id).update({
                          'participants': FieldValue.arrayRemove([userId]),
                        });
                      } else {
                        await repo.rsvpToEvent(event.id, userId!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isRSVPed ? Colors.green : AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(isRSVPed ? 'GOING (TAP TO CANCEL)' : 'JOIN EVENT',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetail(
      BuildContext context, EventEntity event, String? userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(40))),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(40)),
                    child: Image.network(
                        event.imageUrl ?? _categoryImages['Other']!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                          _categoryImages.entries
                              .firstWhere((e) => e.value == event.imageUrl,
                                  orElse: () => const MapEntry('Other', ''))
                              .key
                              .toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(height: 16),
                    Text(event.title,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 12),
                        Text(
                            DateFormat('EEEE, MMM dd • hh:mm a')
                                .format(event.eventDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(event.location,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                  fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('About Event',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87)),
                    const SizedBox(height: 12),
                    Text(
                        event.description.isEmpty
                            ? 'No description provided.'
                            : event.description,
                        style: const TextStyle(
                            color: Colors.black54,
                            height: 1.6,
                            fontSize: 15)),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('BACK TO LIST'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dark Map Style JSON
  final String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#242f3e"
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
        "color": "#242f3e"
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
        "color": "#263c3f"
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
        "color": "#38414e"
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
        "color": "#746855"
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
        "color": "#17263c"
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
        "color": "#17263c"
      }
    ]
  }
]
''';
}
