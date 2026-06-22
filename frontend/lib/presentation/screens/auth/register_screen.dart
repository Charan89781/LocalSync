import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/premium_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedSociety = 'Block A';
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  final _focusNodeName = FocusNode();
  final _focusNodeEmail = FocusNode();
  final _focusNodePassword = FocusNode();

  final List<String> _societies = [
    'Block A',
    'Block B',
    'Block C',
    'Tower 1',
    'Tower 2',
    'Oak Ridge Residency',
    'Pine Crest Society',
  ];

  @override
  void initState() {
    super.initState();
    _focusNodeName.addListener(() => setState(() => _nameFocused = _focusNodeName.hasFocus));
    _focusNodeEmail.addListener(() => setState(() => _emailFocused = _focusNodeEmail.hasFocus));
    _focusNodePassword.addListener(() => setState(() => _passwordFocused = _focusNodePassword.hasFocus));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _focusNodeName.dispose();
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            email,
            password,
            name,
          );
      // Wait a moment and navigate to location verification screen or dashboard
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      ),
      body: Stack(
        children: [
          // Background subtle glows
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.06),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withValues(alpha: 0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Image.asset(
                            'assets/images/app_symbol.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Create Account',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'BUILDING STRONGER COMMUNITY CONNECTIONS',
                      style: GoogleFonts.inter(
                        color: AppColors.neonCyan.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Main Form in a GlassCard
                    GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'REGISTER',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Full Name
                          _buildInputWrapper(
                            focused: _nameFocused,
                            child: TextField(
                              controller: _nameController,
                              focusNode: _focusNodeName,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: _nameFocused ? AppColors.neonCyan : Colors.white38,
                                ),
                                hintText: 'Full Name',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Email Address
                          _buildInputWrapper(
                            focused: _emailFocused,
                            child: TextField(
                              controller: _emailController,
                              focusNode: _focusNodeEmail,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  color: _emailFocused ? AppColors.neonCyan : Colors.white38,
                                ),
                                hintText: 'Email address',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password
                          _buildInputWrapper(
                            focused: _passwordFocused,
                            child: TextField(
                              controller: _passwordController,
                              focusNode: _focusNodePassword,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: _passwordFocused ? AppColors.neonCyan : Colors.white38,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                hintText: 'Password',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Society Dropdown Select
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceNavy,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSociety,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  prefixIcon: Icon(
                                    Icons.apartment_rounded,
                                    color: Colors.white38,
                                  ),
                                ),
                                dropdownColor: AppColors.secondaryNavy,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                items: _societies.map((society) {
                                  return DropdownMenuItem<String>(
                                    value: society,
                                    child: Text(society),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedSociety = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Register Button
                          _isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : GradientButton(
                                  label: 'Create Account',
                                  onPressed: _handleRegister,
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Back to login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.inter(
                              color: AppColors.neonCyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputWrapper({required bool focused, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

