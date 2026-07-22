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
import 'package:google_fonts/google_fonts.dart';
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
  bool _showCompletedEvents = false; // false = Upcoming, true = Completed/Past Events
  GoogleMapController? _mapController;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPageIndex = 0;
  String _searchQuery = '';
  String _sortBy = 'Date';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

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
    final priceController = TextEditingController(text: '0');
    final requirementsController = TextEditingController();
    String category = 'Weekend Meet';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int maxParticipants = 20;
    int durationHours = 2;
    bool isTicketed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.secondaryNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create Community Event',
                      style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: AppColors.surfaceNavy,
                    items: _categoryImages.keys
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (v) => setSheetState(() => category = v!),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonCyan),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonCyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Location / Address',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonCyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonCyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Capacity (Slots)', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.neonCyan),
                            onPressed: () => setSheetState(() { if (maxParticipants > 2) maxParticipants--; }),
                          ),
                          Text('$maxParticipants', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.neonCyan),
                            onPressed: () => setSheetState(() { if (maxParticipants < 100) maxParticipants++; }),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Paid Event (Ticketing)', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                      Switch(
                        value: isTicketed,
                        activeColor: AppColors.neonCyan,
                        onChanged: (val) => setSheetState(() => isTicketed = val),
                      ),
                    ],
                  ),
                  if (isTicketed) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Entry Price (₹)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonCyan)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Duration', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [1, 2, 3, 4, 6].map((hrs) {
                      final isSel = durationHours == hrs;
                      return ChoiceChip(
                        label: Text("$hrs hr${hrs > 1 ? 's' : ''}"),
                        selected: isSel,
                        selectedColor: AppColors.neonCyan,
                        backgroundColor: AppColors.surfaceNavy,
                        labelStyle: TextStyle(color: isSel ? AppColors.primaryNavy : Colors.white70, fontWeight: FontWeight.bold),
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() => durationHours = hrs);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: requirementsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Squad Guidelines / Gear (comma separated)',
                      hintText: 'e.g. Bring own racket, Wear sports shoes',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonCyan)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Event Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle:
                        Text(DateFormat('EEEE, MMM dd').format(selectedDate), style: const TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.calendar_today,
                        color: AppColors.neonCyan),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.neonCyan,
                                onPrimary: AppColors.primaryNavy,
                                surface: AppColors.secondaryNavy,
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: AppColors.secondaryNavy,
                            ),
                            child: child!,
                          );
                        },
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

                      final price = double.tryParse(priceController.text) ?? 0.0;
                      final reqs = requirementsController.text.isNotEmpty
                          ? requirementsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
                          : <String>[];

                      final event = EventEntity(
                        id: '',
                        creatorId: user.id,
                        title: titleController.text,
                        description: descController.text,
                        eventDate: selectedDate,
                        location: locController.text,
                        imageUrl: _categoryImages[category],
                        participants: [user.id],
                        maxParticipants: maxParticipants,
                        isTicketed: isTicketed,
                        price: price,
                        latitude: lat,
                        longitude: lon,
                        durationHours: durationHours,
                        requirements: reqs,
                      );

                      await ref
                          .read(eventRepositoryProvider)
                          .createEvent(event);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: AppColors.primaryNavy,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('POST EVENT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
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
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('COMMUNITY EVENTS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.format_list_bulleted_rounded : Icons.map_rounded, color: Colors.white),
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
          final now = DateTime.now().subtract(const Duration(hours: 4));
          var filtered = events.where((e) {
            final matchTab = _showCompletedEvents ? e.eventDate.isBefore(now) : e.eventDate.isAfter(now);
            final matchCategory = _selectedCategory == 'All' ||
                (e.imageUrl != null &&
                    _categoryImages.entries.any((entry) =>
                        entry.value == e.imageUrl &&
                        entry.key == _selectedCategory));
            return matchTab && matchCategory;
          }).toList();

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            filtered = filtered.where((e) =>
                e.title.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q) ||
                e.location.toLowerCase().contains(q)).toList();
          }

          if (_sortBy == 'Date') {
            filtered.sort((a, b) => a.eventDate.compareTo(b.eventDate));
          } else if (_sortBy == 'Slots') {
            filtered.sort((a, b) {
              final remA = a.maxParticipants - a.participants.length;
              final remB = b.maxParticipants - b.participants.length;
              return remB.compareTo(remA);
            });
          } else if (_sortBy == 'Popularity') {
            filtered.sort((a, b) => b.participants.length.compareTo(a.participants.length));
          }

          if (_isMapView) {
            return _buildMapViewContent(filtered, user?.id);
          } else {
            return _buildListViewContent(filtered, user?.id);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              const Text('Could not load events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Check your internet and pull down to refresh', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(upcomingEventsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventSheet,
        backgroundColor: AppColors.neonCyan,
        label: const Text('NEW EVENT',
            style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: AppColors.primaryNavy),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // 2-Way Tab Bar: Upcoming Events vs Completed Events
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showCompletedEvents = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_showCompletedEvents ? AppColors.neonCyan : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'UPCOMING EVENTS',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: !_showCompletedEvents ? AppColors.primaryNavy : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showCompletedEvents = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _showCompletedEvents ? AppColors.successGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'COMPLETED EVENTS',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _showCompletedEvents ? AppColors.primaryNavy : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.secondaryNavy,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search meetups, venues, sports...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Sort by:', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Date', 'Slots', 'Popularity'].map((opt) {
                      final isSel = _sortBy == opt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            opt == 'Slots' ? 'Slots Available' : opt,
                            style: TextStyle(
                              color: isSel ? AppColors.primaryNavy : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.neonCyan,
                          backgroundColor: AppColors.secondaryNavy,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _sortBy = opt);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListViewContent(List<EventEntity> filtered, String? userId) {
    return Column(
      children: [
        _buildCategoryFilter(),
        _buildSearchAndSortBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(upcomingEventsProvider),
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No events match your criteria.',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
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
          final isPending = userId != null && event.maybeParticipants.contains(userId);
          
          return AnimatedScale(
            scale: _currentPageIndex == index ? 1.0 : 0.95,
            duration: const Duration(milliseconds: 250),
            child: GestureDetector(
              onTap: () => context.push('/events/${event.id}'),
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonCyan.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      DateFormat('MMM dd').format(event.eventDate).toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.neonCyan,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: event.isTicketed 
                                          ? AppColors.neonPurple.withValues(alpha: 0.15)
                                          : Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      event.isTicketed ? '₹${event.price?.toInt() ?? 0}' : 'FREE',
                                      style: TextStyle(
                                        color: event.isTicketed ? AppColors.neonPurple : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isRSVPed)
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16)
                              else if (isPending)
                                const Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 16),
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
                              const Icon(Icons.location_on_rounded, size: 12, color: AppColors.neonCyan),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  event.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 12, color: AppColors.neonCyan),
                              const SizedBox(width: 4),
                              Text(
                                event.participants.isEmpty
                                    ? 'No participants • ${event.durationHours}h'
                                    : '${event.participants.length}/${event.maxParticipants} going • ${event.durationHours}h',
                                style: const TextStyle(
                                  color: AppColors.neonCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    HapticFeedback.selectionClick();
                                    if (userId == null) return;
                                    if (event.creatorId == userId) {
                                      context.push('/events/${event.id}');
                                    } else {
                                      final repo = ref.read(eventRepositoryProvider);
                                      if (isRSVPed || isPending) {
                                        await repo.cancelRsvpToEvent(event.id, userId);
                                      } else {
                                        await repo.rsvpToEvent(event.id, userId, isMaybe: true);
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: event.creatorId == userId
                                        ? AppColors.neonPurple
                                        : isRSVPed
                                            ? Colors.green
                                            : isPending
                                                ? AppColors.warningOrange
                                                : AppColors.primaryBlue,
                                    minimumSize: const Size(double.infinity, 38),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    event.creatorId == userId
                                        ? 'MANAGE'
                                        : isRSVPed
                                            ? 'GOING'
                                            : isPending
                                                ? 'PENDING'
                                                : 'JOIN',
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
                  color: isSelected ? AppColors.primaryBlue : AppColors.secondaryNavy,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                  ] : [],
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
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
    final isPending = userId != null && event.maybeParticipants.contains(userId);
    final slotsFilled = event.participants.length;
    final maxSlots = event.maxParticipants;
    final fillPercent = (slotsFilled / maxSlots).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: event.isTicketed 
                            ? AppColors.neonPurple.withOpacity(0.85)
                            : Colors.green.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        event.isTicketed ? '₹${event.price?.toInt() ?? 0}' : 'FREE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
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
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.neonCyan, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "${event.durationHours} hr${event.durationHours > 1 ? 's' : ''}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
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
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppColors.neonCyan),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Squad Occupancy',
                            style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$slotsFilled / $maxSlots Slots',
                            style: const TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: fillPercent,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            fillPercent >= 1.0 ? Colors.redAccent : AppColors.neonCyan,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_alt_rounded,
                                size: 14, color: AppColors.neonCyan),
                            const SizedBox(width: 6),
                            Text(
                              event.participants.isEmpty
                                  ? 'Be the first to join!'
                                  : '${event.participants.length} going',
                              style: const TextStyle(
                                color: AppColors.neonCyan,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isRSVPed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('You\'re going',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ] else if (isPending) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pending_actions_rounded,
                                  size: 14, color: Colors.orange),
                              SizedBox(width: 4),
                              Text('Request pending',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      if (userId == null) return;
                      if (event.creatorId == userId) {
                        context.push('/events/${event.id}');
                      } else {
                        final repo = ref.read(eventRepositoryProvider);
                        if (isRSVPed || isPending) {
                          await repo.cancelRsvpToEvent(event.id, userId);
                        } else {
                          await repo.rsvpToEvent(event.id, userId, isMaybe: true);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: event.creatorId == userId
                          ? AppColors.neonPurple
                          : isRSVPed
                              ? Colors.green
                              : isPending
                                  ? AppColors.warningOrange
                                  : AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                        event.creatorId == userId
                            ? 'MANAGE EVENT'
                            : isRSVPed
                                ? 'GOING (TAP TO LEAVE)'
                                : isPending
                                    ? '✓ REQUEST PENDING (CANCEL)'
                                    : 'REQUEST TO JOIN',
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
