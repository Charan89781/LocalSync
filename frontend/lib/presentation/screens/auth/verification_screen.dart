import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/premium_widgets.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  XFile? _documentImage;
  final _houseController = TextEditingController();
  bool _isSubmitting = false;
  bool _houseFocused = false;
  final _focusNodeHouse = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNodeHouse.addListener(() => setState(() => _houseFocused = _focusNodeHouse.hasFocus));
  }

  @override
  void dispose() {
    _houseController.dispose();
    _focusNodeHouse.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _documentImage = img);
    }
  }

  Future<void> _submitVerification() async {
    if (_documentImage == null || _houseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide all details and a document photo')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    // Mock upload/submit delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification submitted! Admin will review shortly.'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Verification',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background subtle ambient lights
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withOpacity(0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verification Shield Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.02),
                            border: Border.all(
                              color: AppColors.neonCyan.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            size: 60,
                            color: AppColors.neonCyan,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Get Verified Tick',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Verified residents get a blue checkmark, access to community tools, and full marketplace capabilities.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFCAC4D0),
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Form Card
                  GlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'RESIDENT DETAILS',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // House Number / Apt ID
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _houseFocused ? AppColors.neonCyan : Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _houseController,
                            focusNode: _focusNodeHouse,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.home_rounded,
                                color: _houseFocused ? AppColors.neonCyan : Colors.white38,
                              ),
                              hintText: 'House / Apartment Number',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'UPLOAD SOCIETY ID / UTILITY BILL',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Picker Area
                        GestureDetector(
                          onTap: _pickDocument,
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceNavy,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _documentImage != null
                                    ? AppColors.neonCyan.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.08),
                                width: 1.5,
                              ),
                            ),
                            child: _documentImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.file(
                                      File(_documentImage!.path),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 40,
                                        color: AppColors.neonCyan,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Choose Document Image',
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'JPG, PNG or PDF up to 5MB',
                                        style: GoogleFonts.inter(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Submit Button
                        _isSubmitting
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : GradientButton(
                                label: 'Submit Verification',
                                onPressed: _submitVerification,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

