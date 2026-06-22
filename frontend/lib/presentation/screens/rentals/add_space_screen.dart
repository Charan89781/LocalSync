import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/space_entity.dart';
import '../../providers/space_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/storage_service.dart';

class AddSpaceScreen extends ConsumerStatefulWidget {
  final SpaceEntity? space;
  const AddSpaceScreen({super.key, this.space});

  @override
  ConsumerState<AddSpaceScreen> createState() => _AddSpaceScreenState();
}

class _AddSpaceScreenState extends ConsumerState<AddSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _locationController = TextEditingController();
  final _amenityController = TextEditingController();
  final _ruleController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _totalFloorsController = TextEditingController();

  final List<String> _amenities = ['Wifi', 'Parking'];
  final List<String> _rules = ['No loud music after 10 PM'];
  
  bool _isSubmitting = false;
  XFile? _coverImageFile;
  String? _coverImageUrl;

  // New multi-image selectors
  final List<XFile> _additionalImageFiles = [];
  List<String> _existingPhotos = [];

  // Extended fields state
  String _spaceType = 'Flat';
  String _bhkType = 'N/A';
  String _furnishingStatus = 'Unfurnished';
  String _preferredTenants = 'Any';
  bool _isMonthly = false;
  DateTime _availableFrom = DateTime.now();
  String _facing = 'East';

  final List<String> _spaceTypes = ['Flat', 'PG', 'Hostel', 'Room', 'Office', 'Parking', 'Storage'];
  final List<String> _bhkTypes = ['N/A', 'Studio', '1 BHK', '2 BHK', '3 BHK', '4 BHK'];
  final List<String> _furnishingOptions = ['Fully Furnished', 'Semi-Furnished', 'Unfurnished'];
  final List<String> _tenantPreferences = ['Any', 'Bachelors', 'Family'];
  final List<String> _facings = ['East', 'West', 'North', 'South', 'North-East', 'North-West', 'South-East', 'South-West'];

  @override
  void initState() {
    super.initState();
    if (widget.space != null) {
      _nameController.text = widget.space!.name;
      _descController.text = widget.space!.description;
      _priceController.text = widget.space!.pricePerHour.toString();
      _depositController.text = widget.space!.depositAmount.toString();
      _monthlyRentController.text = widget.space!.monthlyRent.toString();
      _locationController.text = widget.space!.location;
      _floorNumberController.text = widget.space!.floorNumber.toString();
      _totalFloorsController.text = widget.space!.totalFloors.toString();

      _amenities.clear();
      _amenities.addAll(widget.space!.amenities);
      _rules.clear();
      _rules.addAll(widget.space!.houseRules);
      _coverImageUrl = widget.space!.imageUrl;

      _existingPhotos = List<String>.from(widget.space!.photos);
      _spaceType = widget.space!.spaceType;
      _bhkType = widget.space!.bhkType;
      _furnishingStatus = widget.space!.furnishingStatus;
      _preferredTenants = widget.space!.preferredTenants;
      _isMonthly = widget.space!.isMonthly;
      _availableFrom = widget.space!.availableFrom;
      _facing = widget.space!.facing;
    } else {
      _depositController.text = '0';
      _monthlyRentController.text = '0';
      _floorNumberController.text = '0';
      _totalFloorsController.text = '0';
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _coverImageFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking cover image: $e');
    }
  }

  Future<void> _pickAdditionalImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _additionalImageFiles.add(pickedFile);
        });
      }
    } catch (e) {
      debugPrint('Error picking additional image: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _monthlyRentController.dispose();
    _locationController.dispose();
    _amenityController.dispose();
    _ruleController.dispose();
    _floorNumberController.dispose();
    _totalFloorsController.dispose();
    super.dispose();
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.primaryNavy,
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.neonCyan),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          widget.space != null ? 'EDIT PROPERTY' : 'POST A PROPERTY',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cover Image Picker
                  const Text('COVER IMAGE',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickCoverImage,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                        image: _coverImageFile != null
                            ? (kIsWeb
                                ? DecorationImage(image: NetworkImage(_coverImageFile!.path), fit: BoxFit.cover)
                                : DecorationImage(image: FileImage(File(_coverImageFile!.path)), fit: BoxFit.cover))
                            : (_coverImageUrl != null && _coverImageUrl!.isNotEmpty)
                                ? DecorationImage(image: NetworkImage(_coverImageUrl!), fit: BoxFit.cover)
                                : null,
                      ),
                      child: _coverImageFile == null && (_coverImageUrl == null || _coverImageUrl!.isEmpty)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_rounded, color: AppColors.neonCyan, size: 36),
                                const SizedBox(height: 8),
                                const Text(
                                  'ADD MAIN COVER PHOTO',
                                  style: TextStyle(
                                    color: AppColors.neonCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Additional Photos Gallery
                  const Text('ADDITIONAL INTERIOR/EXTERIOR PHOTOS',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Edit Mode Existing urls
                        ..._existingPhotos.map((url) => Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _existingPhotos.remove(url)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        // Newly Picked Local Files
                        ..._additionalImageFiles.map((file) => Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                                image: kIsWeb
                                    ? DecorationImage(image: NetworkImage(file.path), fit: BoxFit.cover)
                                    : DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _additionalImageFiles.remove(file)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        // Add Button
                        GestureDetector(
                          onTap: _pickAdditionalImage,
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                            ),
                            child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.neonCyan),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildField(
                    controller: _nameController,
                    label: 'Property Title',
                    hint: 'e.g. Spacious 2BHK in Gachibowli / Premium Parking Slot',
                    validator: (v) => v!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Space & BHK Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Space Type',
                          value: _spaceType,
                          items: _spaceTypes,
                          onChanged: (val) => setState(() => _spaceType = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          label: 'BHK Type',
                          value: _bhkType,
                          items: _bhkTypes,
                          onChanged: (val) => setState(() => _bhkType = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Furnishing & Tenants Preferred
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Furnishing Status',
                          value: _furnishingStatus,
                          items: _furnishingOptions,
                          onChanged: (val) => setState(() => _furnishingStatus = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Tenant Preference',
                          value: _preferredTenants,
                          items: _tenantPreferences,
                          onChanged: (val) => setState(() => _preferredTenants = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lease Model Toggle (Hourly vs Monthly Lease)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MONTHLY LEASE MODEL',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Toggle off for hourly booking listings',
                              style: TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isMonthly,
                        activeColor: AppColors.neonCyan,
                        onChanged: (val) => setState(() => _isMonthly = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dynamic Pricing fields based on Monthly vs Hourly
                  if (_isMonthly) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _monthlyRentController,
                            label: 'Monthly Rent (₹)',
                            hint: 'e.g. 15000',
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty || double.tryParse(v) == null
                                ? 'Enter valid monthly rent'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildField(
                            controller: _depositController,
                            label: 'Security Deposit (₹)',
                            hint: 'e.g. 45000',
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty || double.tryParse(v) == null
                                ? 'Enter valid deposit amount'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildField(
                      controller: _priceController,
                      label: 'Price per hour (₹)',
                      hint: 'e.g. 250',
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty || double.tryParse(v) == null
                          ? 'Enter valid hourly rate'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Location and Floor details
                  _buildField(
                    controller: _locationController,
                    label: 'Property Address / Location',
                    hint: 'e.g. Flat 301, Block B, Premium Residency',
                    validator: (v) => v!.isEmpty ? 'Location is required' : null,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _floorNumberController,
                          label: 'Floor Number',
                          hint: 'e.g. 3',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _totalFloorsController,
                          label: 'Total Floors',
                          hint: 'e.g. 5',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Facing',
                          value: _facing,
                          items: _facings,
                          onChanged: (val) => setState(() => _facing = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Available From Date Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AVAILABLE FROM',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _availableFrom,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (ctx, child) {
                              return Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppColors.neonCyan,
                                    onPrimary: AppColors.primaryNavy,
                                    surface: AppColors.secondaryNavy,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _availableFrom = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM dd, yyyy').format(_availableFrom),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const Icon(Icons.calendar_month_rounded, color: AppColors.neonCyan),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Amenities list
                  const Text('AMENITIES',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _amenities
                        .map((a) => Chip(
                              backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
                              side: const BorderSide(color: AppColors.neonCyan),
                              label: Text(a,
                                  style: const TextStyle(fontSize: 11, color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                              onDeleted: () => setState(() => _amenities.remove(a)),
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
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                          ),
                          child: TextField(
                            controller: _amenityController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                                hintText: 'Add amenity (e.g. Wifi, AC, Gym, Lift)',
                                hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                                border: InputBorder.none,
                                filled: false),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          if (_amenityController.text.isNotEmpty) {
                            setState(() {
                              _amenities.add(_amenityController.text.trim());
                              _amenityController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_circle_rounded, color: AppColors.neonCyan, size: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // House rules builder UI
                  const Text('HOUSE RULES',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _rules
                        .map((r) => Chip(
                              backgroundColor: Colors.orange.withValues(alpha: 0.1),
                              side: const BorderSide(color: Colors.orange),
                              label: Text(r,
                                  style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                              onDeleted: () => setState(() => _rules.remove(r)),
                              deleteIconColor: Colors.orange,
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
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                          ),
                          child: TextField(
                            controller: _ruleController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                                hintText: 'Add house rule (e.g. No Pets, No smoking)',
                                hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                                border: InputBorder.none,
                                filled: false),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          if (_ruleController.text.isNotEmpty) {
                            setState(() {
                              _rules.add(_ruleController.text.trim());
                              _ruleController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_circle_rounded, color: Colors.orange, size: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final user = ref.read(authStateProvider).value;
                            if (user == null) return;
                            setState(() => _isSubmitting = true);

                            try {
                              // Upload Cover Photo
                              String uploadCoverUrl = _coverImageUrl ?? '';
                              if (_coverImageFile != null) {
                                final path = 'spaces/${user.id}/${DateTime.now().millisecondsSinceEpoch}_cover.jpg';
                                uploadCoverUrl = await ref.read(storageServiceProvider).uploadFile(path, _coverImageFile!);
                              }

                              // Upload Additional Photos
                              final List<String> uploadedPhotos = List.from(_existingPhotos);
                              for (var i = 0; i < _additionalImageFiles.length; i++) {
                                final file = _additionalImageFiles[i];
                                final path = 'spaces/${user.id}/${DateTime.now().millisecondsSinceEpoch}_photo_$i.jpg';
                                final url = await ref.read(storageServiceProvider).uploadFile(path, file);
                                uploadedPhotos.add(url);
                              }

                              // Fallback photos list
                              final finalPhotosList = uploadedPhotos.isNotEmpty
                                  ? uploadedPhotos
                                  : [uploadCoverUrl];

                              final space = SpaceEntity(
                                id: widget.space?.id ?? '',
                                name: _nameController.text.trim(),
                                location: _locationController.text.trim(),
                                description: _descController.text.trim(),
                                pricePerHour: double.tryParse(_priceController.text) ?? (_isMonthly ? (double.tryParse(_monthlyRentController.text) ?? 0.0) / 720.0 : 0.0),
                                imageUrl: uploadCoverUrl,
                                amenities: _amenities,
                                houseRules: _rules,
                                ownerId: widget.space?.ownerId ?? user.id,
                                isAvailable: widget.space?.isAvailable ?? true,
                                spaceType: _spaceType,
                                bhkType: _bhkType,
                                furnishingStatus: _furnishingStatus,
                                preferredTenants: _preferredTenants,
                                depositAmount: double.tryParse(_depositController.text) ?? 0.0,
                                monthlyRent: double.tryParse(_monthlyRentController.text) ?? 0.0,
                                isMonthly: _isMonthly,
                                availableFrom: _availableFrom,
                                photos: finalPhotosList,
                                floorNumber: int.tryParse(_floorNumberController.text) ?? 0,
                                totalFloors: int.tryParse(_totalFloorsController.text) ?? 0,
                                facing: _facing,
                                avgRating: widget.space?.avgRating ?? 0.0,
                                reviewCount: widget.space?.reviewCount ?? 0,
                                viewCount: widget.space?.viewCount ?? 0,
                                isVerified: widget.space?.isVerified ?? true, // Set to true by default or keep previous
                              );

                              if (widget.space != null) {
                                await ref.read(spaceRepositoryProvider).updateSpace(space);
                              } else {
                                await ref.read(spaceRepositoryProvider).listSpace(space);
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(widget.space != null
                                        ? 'Listing updated successfully!'
                                        : 'Listing posted successfully!'),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                                context.pop();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error uploading files / saving: $e'),
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isSubmitting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: AppColors.neonCyan.withValues(alpha: 0.3),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: AppColors.primaryNavy)
                        : Text(
                            widget.space != null ? 'SAVE PROPERTY' : 'POST PROPERTY NOW',
                            style: const TextStyle(
                              color: AppColors.primaryNavy,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

