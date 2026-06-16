import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OfferRideScreen extends ConsumerStatefulWidget {
  const OfferRideScreen({super.key});

  @override
  ConsumerState<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends ConsumerState<OfferRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _timeController = TextEditingController();
  final _seatsController = TextEditingController();
  final _costController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
                          'OFFER A RIDE',
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
                    controller: _destinationController,
                    label: 'Destination Point',
                    hint: 'e.g. Metro Tech Station / Airport Term 2',
                    validator: (v) => v!.isEmpty ? 'Destination required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _timeController,
                    label: 'Departure Time',
                    hint: 'e.g. 08:30 AM',
                    validator: (v) => v!.isEmpty ? 'Departure time is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _seatsController,
                    label: 'Available Seats',
                    hint: 'e.g. 4',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Seats count is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _costController,
                    label: 'Requested Contribution (₹)',
                    hint: 'e.g. 50',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Contribution price is required' : null,
                  ),
                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _isSubmitting = true);

                            await Future.delayed(const Duration(milliseconds: 800));

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Carpool offered successfully!'),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                              context.pop();
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
                            'CREATE CARPOOL RIDE',
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
