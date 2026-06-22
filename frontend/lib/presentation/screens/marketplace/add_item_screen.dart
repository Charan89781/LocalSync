import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/listing_entity.dart';
import '../../../core/services/storage_service.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final List<XFile> _localImages = [];
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'Electronics';
  String _selectedCondition = 'Like New';
  String _selectedDuration = '1 week';
  bool _isSubmitting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _categories = [
    'Electronics', 'Furniture', 'Clothes', 'Books', 'Kitchen', 'Tools', 'Others'
  ];
  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair'];
  final List<String> _durations = ['1 day', '3 days', '1 week', '2 weeks'];

  final Map<String, IconData> _categoryIcons = {
    'Electronics': Icons.devices_rounded,
    'Furniture': Icons.chair_rounded,
    'Clothes': Icons.checkroom_rounded,
    'Books': Icons.menu_book_rounded,
    'Kitchen': Icons.kitchen_rounded,
    'Tools': Icons.construction_rounded,
    'Others': Icons.category_rounded,
  };

  final Map<String, Color> _conditionColors = {
    'New': Colors.greenAccent,
    'Like New': const Color(0xFF00D1FF),
    'Good': Colors.orangeAccent,
    'Fair': Colors.redAccent,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_localImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 5 images allowed', style: GoogleFonts.inter()),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    if (imgs.isNotEmpty) {
      final remaining = 5 - _localImages.length;
      setState(() => _localImages.addAll(imgs.take(remaining)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A121A), Color(0xFF15202B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      _buildImageSection(),
                      _buildFormSections(),
                      _buildSubmitButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF007BFF).withValues(alpha: 0.8),
            const Color(0xFF00D1FF).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share with Community',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Post New Item',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_rounded, color: Color(0xFF00D1FF), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Item Photos',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_localImages.length}/5',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  ..._localImages.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 95,
                          height: 95,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? Image.network(
                                    entry.value.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(entry.value.path),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _localImages.removeAt(entry.key)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                        if (entry.key == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007BFF).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Cover',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  if (_localImages.length < 5)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00D1FF).withValues(alpha: 0.4),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_rounded,
                                color: Color(0xFF00D1FF), size: 28),
                            const SizedBox(height: 6),
                            Text(
                              'Add Photo',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF00D1FF),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildFormSections() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Item Details', Icons.info_outline_rounded),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'e.g. Bosch Power Drill (Cordless)',
                  validator: (v) => v!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _priceController,
                  label: 'Price per Day (₹) — 0 for Free',
                  hint: 'e.g. 150',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee_rounded,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _descController,
                  label: 'Description',
                  hint: 'Describe the item, its condition, and any usage notes...',
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? 'Description is required' : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Category', Icons.category_rounded),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF007BFF), Color(0xFF00D1FF)],
                                )
                              : null,
                          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF007BFF).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryIcons[cat] ?? Icons.category_rounded,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: GoogleFonts.inter(
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Condition', Icons.verified_outlined),
                const SizedBox(height: 16),
                Row(
                  children: _conditions.map((cond) {
                    final isSelected = _selectedCondition == cond;
                    final color = _conditionColors[cond] ?? Colors.white;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCondition = cond),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cond,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: isSelected ? color : Colors.white.withValues(alpha: 0.4),
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Lending Duration', Icons.access_time_rounded),
                const SizedBox(height: 16),
                Row(
                  children: _durations.map((dur) {
                    final isSelected = _selectedDuration == dur;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDuration = dur),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF007BFF), Color(0xFF00D1FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF007BFF).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            dur,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF007BFF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF007BFF).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007BFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Color(0xFF00D1FF), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Auto-filled from your profile',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.greenAccent.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: _isSubmitting ? null : _submitItem,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 60,
          decoration: BoxDecoration(
            gradient: _isSubmitting
                ? LinearGradient(
                    colors: [
                      const Color(0xFF007BFF).withValues(alpha: 0.4),
                      const Color(0xFF00D1FF).withValues(alpha: 0.4),
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF00D1FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isSubmitting
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF007BFF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Posting Item...',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Post Item to Marketplace',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final List<String> imageUrls = [];
      final storage = ref.read(storageServiceProvider);
      
      for (final image in _localImages) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final storagePath = 'listings/${user.id}/$fileName';
        final url = await storage.uploadFile(storagePath, image);
        imageUrls.add(url);
      }

      final newListing = ListingEntity(
        id: '',
        ownerId: user.id,
        ownerName: user.name ?? 'Neighbor',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        type: ListingType.resource,
        category: _selectedCategory,
        createdAt: DateTime.now(),
        imageUrls: imageUrls,
        rules: [_selectedCondition, _selectedDuration],
      );

      print('DEBUG: AddItemScreen - Submitting new listing: ownerId=${user.id}, title=${newListing.title}, price=${newListing.price}, category=${newListing.category}');
      await ref.read(listingRepositoryProvider).createListing(newListing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Item posted successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D1FF), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: const Color(0xFF00D1FF).withValues(alpha: 0.6), size: 18)
                  : null,
              filled: false,
            ),
          ),
        ),
      ],
    );
  }
}
