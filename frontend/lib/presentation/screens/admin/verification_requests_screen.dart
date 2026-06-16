import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

class VerificationRequestsScreen extends ConsumerWidget {
  const VerificationRequestsScreen({super.key});

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
    // Mock requests derived matching UI state
    final mockRequests = [
      {
        'id': '1',
        'name': 'Rahul Sharma',
        'house': 'A-402',
        'doc': 'https://picsum.photos/400/300'
      },
      {
        'id': '2',
        'name': 'Sneha Patil',
        'house': 'B-105',
        'doc': 'https://picsum.photos/400/301'
      },
    ];

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
              title: const Text('RESIDENT REQUESTS',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                itemCount: mockRequests.length,
                itemBuilder: (context, index) {
                  final req = mockRequests[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: _glassContainer(
                      padding: 20,
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.neonCyan.withOpacity(0.2),
                                foregroundColor: AppColors.neonCyan,
                                child: Text(req['name']![0]),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(req['name']!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text('House: ${req['house']}',
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(req['doc']!,
                                height: 160, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Request for ${req['name']} rejected.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    minimumSize: const Size(0, 48),
                                  ),
                                  child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${req['name']} verified successfully!'),
                                        backgroundColor: Colors.greenAccent,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    minimumSize: const Size(0, 48),
                                  ),
                                  child: const Text('APPROVE',
                                      style: TextStyle(
                                          color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
