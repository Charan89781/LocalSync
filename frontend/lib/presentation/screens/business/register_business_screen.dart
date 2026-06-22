import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/business_entity.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';

class RegisterBusinessScreen extends ConsumerStatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  ConsumerState<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends ConsumerState<RegisterBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCategory = 'Food & Dining';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Food & Dining',
    'Salon & Wellness',
    'Groceries & Retail',
    'Home Services',
    'Laundry',
    'Others',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
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
                color: Colors.white,
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
                      const Expanded(
                        child: Text(
                          'REGISTER A BUSINESS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildField(
                    controller: _nameController,
                    label: 'Business Name',
                    hint: 'e.g. Organic Baker & Cafe',
                    validator: (v) => v!.isEmpty ? 'Business name required' : null,
                  ),
                  const SizedBox(height: 20),

                  const Text('BUSINESS CATEGORY',
                      style: TextStyle(
                          color: Colors.white,
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
                        dropdownColor: AppColors.secondaryNavy,
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.neonCyan),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: _categories
                            .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat, style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _contactController,
                    label: 'Contact Number',
                    hint: 'e.g. +91 98765 43210',
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Contact details required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _addressController,
                    label: 'Shop Address / Block Location',
                    hint: 'e.g. Ground Floor, Block B, Main Market',
                    validator: (v) => v!.isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _descController,
                    label: 'Offerings & Details',
                    hint: 'Describe what you sell, timings, delivery policy...',
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Description required' : null,
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
                              final biz = BusinessEntity(
                                id: '',
                                name: _nameController.text.trim(),
                                description: _descController.text.trim(),
                                category: _selectedCategory,
                                address: _addressController.text.trim(),
                                phoneNumber: _contactController.text.trim(),
                                imageUrl: '',
                                rating: 5.0,
                                ownerId: user.id,
                                isVerified: false,
                              );

                              await ref.read(businessRepositoryProvider).addBusiness(biz);
                              ref.invalidate(businessesProvider);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Business registered! Admin verification is pending.'),
                                    backgroundColor: AppColors.successGreen,
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
                        : const Text(
                            'SUBMIT REGISTRATION',
                            style: TextStyle(
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
