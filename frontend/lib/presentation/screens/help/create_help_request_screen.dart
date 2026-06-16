import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/post_entity.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';

class CreateHelpRequestScreen extends ConsumerStatefulWidget {
  const CreateHelpRequestScreen({super.key});

  @override
  ConsumerState<CreateHelpRequestScreen> createState() =>
      _CreateHelpRequestScreenState();
}

class _CreateHelpRequestScreenState
    extends ConsumerState<CreateHelpRequestScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedCategory = 'Repairs';
  String _selectedUrgency = 'Normal';
  bool _isSubmitting = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Repairs', 'icon': Icons.build_rounded, 'color': Color(0xFFFF9500)},
    {'name': 'Medical', 'icon': Icons.medical_services_rounded, 'color': Color(0xFFFF3B30)},
    {'name': 'Groceries', 'icon': Icons.shopping_basket_rounded, 'color': Color(0xFF34C759)},
    {'name': 'Transport', 'icon': Icons.directions_car_rounded, 'color': Color(0xFF007BFF)},
    {'name': 'Cooking', 'icon': Icons.restaurant_rounded, 'color': Color(0xFFFF6B35)},
    {'name': 'Tech Help', 'icon': Icons.computer_rounded, 'color': Color(0xFF5856D6)},
    {'name': 'Pets', 'icon': Icons.pets_rounded, 'color': Color(0xFF32ADE6)},
    {'name': 'Elderly', 'icon': Icons.elderly_rounded, 'color': Color(0xFFAF52DE)},
  ];

  final List<Map<String, dynamic>> _urgencyLevels = [
    {'label': 'Flexible', 'icon': Icons.schedule_rounded, 'color': Color(0xFF34C759)},
    {'label': 'Normal', 'icon': Icons.notifications_rounded, 'color': Color(0xFF007BFF)},
    {'label': 'Urgent', 'icon': Icons.priority_high_rounded, 'color': Color(0xFFFF9500)},
    {'label': 'Emergency', 'icon': Icons.warning_amber_rounded, 'color': Color(0xFFFF3B30)},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Ask for Help',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero banner
                          _buildHeroBanner(),
                          const SizedBox(height: 28),
                          // Category picker
                          _buildSectionLabel('WHAT DO YOU NEED?'),
                          const SizedBox(height: 14),
                          _buildCategoryGrid(),
                          const SizedBox(height: 24),
                          // Urgency
                          _buildSectionLabel('URGENCY LEVEL'),
                          const SizedBox(height: 14),
                          _buildUrgencyRow(),
                          const SizedBox(height: 24),
                          // Title
                          _buildSectionLabel('REQUEST TITLE'),
                          const SizedBox(height: 10),
                          _buildInputField(
                            controller: _titleController,
                            hint: 'e.g. Need help fixing leaking pipe',
                            maxLines: 1,
                            validator: (v) => v!.trim().isEmpty ? 'Please add a title' : null,
                          ),
                          const SizedBox(height: 20),
                          // Description
                          _buildSectionLabel('DESCRIBE YOUR NEED'),
                          const SizedBox(height: 10),
                          _buildInputField(
                            controller: _contentController,
                            hint: 'Be specific so neighbors can help better...\ne.g. The kitchen tap is dripping constantly, need someone with plumbing experience for about 30 mins.',
                            maxLines: 5,
                            validator: (v) => v!.trim().isEmpty ? 'Please describe your need' : null,
                          ),
                          const SizedBox(height: 32),
                          // Submit button
                          _buildSubmitButton(),
                          const SizedBox(height: 40),
                        ],
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

  Widget _buildHeroBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF9500).withOpacity(0.12),
                const Color(0xFFFF6B35).withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF9500).withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: Color(0xFFFF9500), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your neighbors are here to help',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '230+ volunteers in your community',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: Colors.white60,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['name']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? (cat['color'] as Color).withOpacity(0.18)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? (cat['color'] as Color).withOpacity(0.6)
                    : Colors.white.withOpacity(0.08),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat['icon'] as IconData,
                    color: isSelected
                        ? cat['color'] as Color
                        : Colors.white38,
                    size: 24),
                const SizedBox(height: 6),
                Text(
                  cat['name'],
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUrgencyRow() {
    return Row(
      children: _urgencyLevels.map((level) {
        final isSelected = _selectedUrgency == level['label'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedUrgency = level['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (level['color'] as Color).withOpacity(0.18)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (level['color'] as Color)
                      : Colors.white.withOpacity(0.08),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(level['icon'] as IconData,
                      color: isSelected ? level['color'] as Color : Colors.white30,
                      size: 18),
                  const SizedBox(height: 4),
                  Text(
                    level['label'],
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.white30,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9500), Color(0xFFFF6B35)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9500).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isSubmitting
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.volunteer_activism_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'POST HELP REQUEST',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _isSubmitting = true);

    try {
      final newPost = PostEntity(
        id: '',
        authorId: user.id,
        authorName: user.name ?? 'Neighbor',
        content: _contentController.text.trim(),
        type: PostType.help,
        category: _selectedCategory,
        subCategory: _selectedUrgency,
        createdAt: DateTime.now(),
        willingToHelp: [],
        commentsCount: 0,
        likedBy: [],
        helpStatus: HelpStatus.open,
      );

      await ref.read(postRepositoryProvider).createPost(newPost);
      ref.invalidate(feedPostsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text('Help request posted! Neighbors notified.',
                    style: GoogleFonts.inter(color: Colors.white)),
              ],
            ),
            backgroundColor: const Color(0xFF34C759),
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
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
