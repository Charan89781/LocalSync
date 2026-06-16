import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/space_entity.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../providers/space_provider.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';

class RentalSpacesScreen extends ConsumerWidget {
  const RentalSpacesScreen({super.key});

  Widget _glassContainer({required Widget child, double padding = 16, double borderRadius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(spacesProvider);

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
              title: const Text('LOCAL RENTALS',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
              ),
            ),
            // Top Quick Nav Panels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickNavCard(
                      context: context,
                      title: 'Explore',
                      icon: Icons.search_rounded,
                      isActive: true,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickNavCard(
                      context: context,
                      title: 'My Spaces',
                      icon: Icons.roofing_rounded,
                      isActive: false,
                      onTap: () => context.push('/rentals/my-spaces'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickNavCard(
                      context: context,
                      title: 'Bookings',
                      icon: Icons.receipt_long_rounded,
                      isActive: false,
                      onTap: () => context.push('/rentals/bookings'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: spacesAsync.when(
                data: (spaces) => spaces.isEmpty
                    ? _buildEmptyState(context, ref)
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: spaces.length,
                        itemBuilder: (context, index) =>
                            _buildSpaceCard(context, ref, spaces[index]),
                      ),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text('Could not load spaces',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Check your internet connection',
                            style: TextStyle(color: Colors.white38, fontSize: 13)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref.refresh(spacesProvider),
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNavy, size: 18),
                          label: const Text('Retry', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonCyan,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/rentals/add'),
        backgroundColor: AppColors.neonCyan,
        icon: const Icon(Icons.add, color: AppColors.primaryNavy),
        label: const Text('LIST SPACE',
            style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef widgetRef) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_work_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No rental spaces available yet.',
              style: TextStyle(color: AppColors.textLight, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddRentalSheet(context, widgetRef),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              backgroundColor: AppColors.neonCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('BE THE FIRST TO LIST', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showAddRentalSheet(BuildContext context, WidgetRef widgetRef) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final locationController = TextEditingController();
    final amenityController = TextEditingController();
    List<String> amenities = ['Wifi', 'Parking'];
    List<String> rules = ['No loud music after 10 PM'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
                color: AppColors.primaryNavy.withOpacity(0.92),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('List Your Space',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 24),
                    _buildSheetField(nameController, 'Space Name', hint: 'e.g. Garden Clubhouse'),
                    const SizedBox(height: 16),
                    _buildSheetField(priceController, 'Price per hour (₹)', hint: 'e.g. 500', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildSheetField(locationController, 'Location / Block', hint: 'e.g. Block C, East Side'),
                    const SizedBox(height: 16),
                    _buildSheetField(descController, 'Description', hint: 'Provide details about setup, capacity...', maxLines: 3),
                    const SizedBox(height: 24),
                    const Text('AMENITIES', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    StatefulBuilder(
                      builder: (context, setSheetState) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: amenities
                                .map((a) => Chip(
                                      backgroundColor: AppColors.neonCyan.withOpacity(0.1),
                                      side: const BorderSide(color: AppColors.neonCyan),
                                      label: Text(a,
                                          style: const TextStyle(fontSize: 10, color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                                      onDeleted: () =>
                                          setSheetState(() => amenities.remove(a)),
                                      deleteIconColor: AppColors.neonCyan,
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                                  ),
                                  child: TextField(
                                    controller: amenityController,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: const InputDecoration(
                                        hintText: 'Add amenity (e.g. AC, Projector)',
                                        hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                                        border: InputBorder.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () {
                                  if (amenityController.text.isNotEmpty) {
                                    setSheetState(() {
                                      amenities.add(amenityController.text);
                                      amenityController.clear();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add_circle_rounded, color: AppColors.neonCyan, size: 36),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () async {
                        final user = widgetRef.read(authStateProvider).value;
                        if (user == null) return;

                        final space = SpaceEntity(
                          id: '',
                          name: nameController.text,
                          description: descController.text,
                          pricePerHour:
                              double.tryParse(priceController.text) ?? 0.0,
                          location: locationController.text,
                          imageUrl: '',
                          amenities: amenities,
                          houseRules: rules,
                          ownerId: user.id,
                        );

                        await widgetRef
                            .read(spaceRepositoryProvider)
                            .listSpace(space);

                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('LIST SPACE',
                          style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField(TextEditingController controller, String label, {String? hint, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpaceCard(
      BuildContext context, WidgetRef widgetRef, SpaceEntity space) {
    return GestureDetector(
      onTap: () => _showSpaceDetail(context, widgetRef, space),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: _glassContainer(
          padding: 0,
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: space.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Image.network(space.imageUrl, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.home_work_rounded,
                        size: 60, color: AppColors.neonCyan),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(space.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                        Text('₹${space.pricePerHour.toInt()}/hr',
                            style: const TextStyle(
                                color: AppColors.neonCyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(space.location,
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: space.amenities
                          .take(3)
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                                ),
                                child: Text(a,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.neonCyan)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpaceDetail(
      BuildContext context, WidgetRef widgetRef, SpaceEntity space) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int startTime = 10;
    int duration = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: StatefulBuilder(
            builder: (context, setDetailState) => Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withOpacity(0.92),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('spaceId', isEqualTo: space.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  final List<BookingEntity> activeBookings = [];
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      activeBookings.add(BookingEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id));
                    }
                  }

                  bool isHourOccupied(int hour, DateTime date) {
                    for (var b in activeBookings) {
                      if (b.date.year == date.year &&
                          b.date.month == date.month &&
                          b.date.day == date.day &&
                          b.status != BookingStatus.canceled) {
                        final endHour = b.startTime + b.duration;
                        if (hour >= b.startTime && hour < endHour) {
                          return true;
                        }
                      }
                    }
                    return false;
                  }

                  bool isSlotOverlapping(int start, int dur, DateTime date) {
                    final end = start + dur;
                    for (var b in activeBookings) {
                      if (b.date.year == date.year &&
                          b.date.month == date.month &&
                          b.date.day == date.day &&
                          b.status != BookingStatus.canceled) {
                        final bEnd = b.startTime + b.duration;
                        if (start < bEnd && end > b.startTime) {
                          return true;
                        }
                      }
                    }
                    return false;
                  }

                  // Find first available hour if current selected hour is occupied
                  if (isHourOccupied(startTime, selectedDate)) {
                    for (int h = 0; h < 24; h++) {
                      if (!isHourOccupied(h, selectedDate)) {
                        startTime = h;
                        break;
                      }
                    }
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
                          child: space.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                                  child: Image.network(space.imageUrl, fit: BoxFit.cover))
                              : const Icon(Icons.home_work_rounded,
                                  size: 100, color: AppColors.neonCyan),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(space.name,
                                        style: const TextStyle(
                                            fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                                  ),
                                  Text('₹${space.pricePerHour.toInt()}/hr',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.neonCyan)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 18, color: Colors.white38),
                                  const SizedBox(width: 8),
                                  Text(space.location,
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 32),
                              const Text('Description',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                              const SizedBox(height: 12),
                              Text(space.description,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 15,
                                      height: 1.6)),
                              const SizedBox(height: 32),
                              const Text('Amenities',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: space.amenities
                                    .map((a) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)),
                                          child: Text(a,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                              ),
                              if (space.houseRules.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                const Text('House Rules',
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                                const SizedBox(height: 12),
                                ...space.houseRules.map((rule) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.rule_rounded,
                                              size: 16, color: Colors.orangeAccent),
                                          const SizedBox(width: 12),
                                          Text(rule,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    )),
                              ],
                              const SizedBox(height: 32),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 32),
                              const Text('Book Your Session',
                                  style: TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                              const SizedBox(height: 24),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  title: const Text('Select Date',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  subtitle: Text(
                                      DateFormat('EEEE, MMM dd').format(selectedDate),
                                      style: const TextStyle(color: Colors.white54)),
                                  trailing: const Icon(Icons.calendar_today_rounded,
                                      color: AppColors.neonCyan),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate:
                                          DateTime.now().add(const Duration(days: 60)),
                                    );
                                    if (d != null) setDetailState(() => selectedDate = d);
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('START TIME',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              dropdownColor: AppColors.secondaryNavy,
                                              value: startTime,
                                              isExpanded: true,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              items: List.generate(24, (i) => i)
                                                  .map((i) {
                                                    final isOccupied = isHourOccupied(i, selectedDate);
                                                    return DropdownMenuItem(
                                                      value: i,
                                                      enabled: !isOccupied,
                                                      child: Text(
                                                        isOccupied ? '$i:00 (Booked)' : '$i:00',
                                                        style: TextStyle(
                                                          color: isOccupied ? Colors.white30 : Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                              onChanged: (v) =>
                                                  setDetailState(() => startTime = v!),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('DURATION (HRS)',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              dropdownColor: AppColors.secondaryNavy,
                                              value: duration,
                                              isExpanded: true,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              items: List.generate(8, (i) => i + 1)
                                                  .map((i) => DropdownMenuItem(
                                                      value: i, child: Text('$i hrs', style: const TextStyle(color: Colors.white))))
                                                  .toList(),
                                              onChanged: (v) =>
                                                  setDetailState(() => duration = v!),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),
                              ElevatedButton(
                                onPressed: () async {
                                  final user = widgetRef.read(authStateProvider).value;
                                  if (user == null) return;

                                  // Overlap checks
                                  if (isSlotOverlapping(startTime, duration, selectedDate)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Selected slot overlaps with a booked session! Please choose another time.'),
                                        backgroundColor: AppColors.errorRed,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  final booking = BookingEntity(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    spaceId: space.id,
                                    spaceName: space.name,
                                    userId: user.id,
                                    date: selectedDate,
                                    startTime: startTime,
                                    duration: duration,
                                    totalPrice: space.pricePerHour * duration,
                                    status: BookingStatus.confirmed,
                                  );

                                  await widgetRef
                                      .read(spaceRepositoryProvider)
                                      .bookSpace(booking);

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(
                                          'Booking for ${space.name} confirmed successfully!'),
                                      backgroundColor: Colors.green));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.neonCyan,
                                  minimumSize: const Size(double.infinity, 64),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Text(
                                    'CONFIRM BOOKING (₹${(space.pricePerHour * duration).toInt()})',
                                    style: const TextStyle(
                                        color: AppColors.primaryNavy,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNavCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.neonCyan.withOpacity(0.12)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppColors.neonCyan.withOpacity(0.4)
                    : Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.neonCyan : Colors.white60,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
