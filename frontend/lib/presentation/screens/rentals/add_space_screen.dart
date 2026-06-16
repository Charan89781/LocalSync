import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/space_entity.dart';
import '../../providers/space_provider.dart';
import '../../providers/auth_provider.dart';

class AddSpaceScreen extends ConsumerStatefulWidget {
  const AddSpaceScreen({super.key});

  @override
  ConsumerState<AddSpaceScreen> createState() => _AddSpaceScreenState();
}

class _AddSpaceScreenState extends ConsumerState<AddSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _amenityController = TextEditingController();
  final List<String> _amenities = ['Wifi', 'Parking'];
  final List<String> _rules = ['No loud music after 10 PM'];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _amenityController.dispose();
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
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
                          'LIST A SPACE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                  const SizedBox(height: 32),

                  _buildField(
                    controller: _nameController,
                    label: 'Space Name',
                    hint: 'e.g. Backyard Barbecue Deck / Loft Studio',
                    validator: (v) => v!.isEmpty ? 'Space name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _priceController,
                    label: 'Price per hour (₹)',
                    hint: 'e.g. 350',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Price is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _locationController,
                    label: 'Location / Block',
                    hint: 'e.g. Penthouse A, Block D',
                    validator: (v) => v!.isEmpty ? 'Location is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _descController,
                    label: 'Description',
                    hint: 'Details about access, seating capacity, and ideal events...',
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 24),

                  const Text('AMENITIES',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _amenities
                        .map((a) => Chip(
                              backgroundColor: AppColors.neonCyan.withOpacity(0.1),
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
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                          ),
                          child: TextField(
                            controller: _amenityController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                                hintText: 'Add amenity (e.g. Grill, Sound System)',
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
                              _amenities.add(_amenityController.text);
                              _amenityController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_circle_rounded, color: AppColors.neonCyan, size: 36),
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
                              final space = SpaceEntity(
                                id: '',
                                name: _nameController.text,
                                description: _descController.text,
                                pricePerHour: double.tryParse(_priceController.text) ?? 0.0,
                                location: _locationController.text,
                                imageUrl: '',
                                amenities: _amenities,
                                houseRules: _rules,
                                ownerId: user.id,
                              );

                              await ref.read(spaceRepositoryProvider).listSpace(space);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Space listed successfully!'),
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
                      shadowColor: AppColors.neonCyan.withOpacity(0.3),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: AppColors.primaryNavy)
                        : const Text(
                            'LIST SPACE NOW',
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
