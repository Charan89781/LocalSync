import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';

class NeighborhoodFilterBar extends ConsumerWidget {
  final String title;

  const NeighborhoodFilterBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cityName = ref.watch(cityNameProvider);
    final activeRadius = ref.watch(neighborhoodRadiusKmProvider);

    final radiusOptions = <double, String>{
      3.0: '3 KM (Immediate Block)',
      5.0: '5 KM (Neighborhood)',
      10.0: '10 KM (Local Area)',
      25.0: '25 KM (City Suburbs)',
      0.0: 'Show All (Unrestricted)',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: AppColors.neonCyan,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cityName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.neonGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activeRadius == 0 ? 'Global Scope' : 'Isolated Locality (${activeRadius.toStringAsFixed(0)} KM)',
                      style: GoogleFonts.inter(
                        color: AppColors.neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<double>(
            initialValue: activeRadius,
            tooltip: 'Filter by Locality Radius',
            onSelected: (radius) {
              ref.read(neighborhoodRadiusKmProvider.notifier).state = radius;
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: const Color(0xFF15202B),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeRadius == 0 ? 'All' : '${activeRadius.toStringAsFixed(0)} KM',
                    style: GoogleFonts.inter(
                      color: AppColors.neonCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.neonCyan,
                    size: 18,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) {
              return radiusOptions.entries.map((entry) {
                final isSelected = entry.key == activeRadius;
                return PopupMenuItem<double>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isSelected ? AppColors.neonCyan : Colors.white38,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value,
                        style: GoogleFonts.inter(
                          color: isSelected ? AppColors.neonCyan : Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}
