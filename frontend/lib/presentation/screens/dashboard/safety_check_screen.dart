import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../data/repositories/safety_repository_impl.dart';

final safetyListProvider = StreamProvider<List<UserEntity>>((ref) {
  return SafetyRepository().getNeighborhoodSafetyList();
});

class SafetyCheckScreen extends ConsumerStatefulWidget {
  const SafetyCheckScreen({super.key});

  @override
  ConsumerState<SafetyCheckScreen> createState() => _SafetyCheckScreenState();
}

class _SafetyCheckScreenState extends ConsumerState<SafetyCheckScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();
  bool _isUpdating = false;
  String _tempStatus = 'Pending';
  bool _hasInitializedStatus = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Widget _glassContainer({required Widget child, double padding = 16, double borderRadius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _updateStatus(String userId, String status) async {
    setState(() {
      _isUpdating = true;
    });
    try {
      final message = status == 'Unsafe' ? _messageController.text.trim() : '';
      await SafetyRepository().updateSafetyStatus(userId, status, message: message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Safety status updated to: $status'),
          backgroundColor: status == 'Safe' ? Colors.green : Colors.redAccent,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating safety status: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No phone number listed for this neighbor'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not launch dialer'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final safetyListAsync = ref.watch(safetyListProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Please log in to access safety checks.')),
          );
        }

        if (!_hasInitializedStatus) {
          _hasInitializedStatus = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _tempStatus = user.safetyStatus ?? 'Pending';
                if (_tempStatus == 'Unsafe') {
                  _messageController.text = user.safetyMessage ?? '';
                }
              });
            }
          });
        }

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
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CRISIS CENTER',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.neonCyan,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Neighborhood Safety Registry',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white38,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // User Safety Status Control Panel
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: _glassContainer(
                        padding: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR STATUS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white38,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Safe Option Card
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _tempStatus = 'Safe';
                                      });
                                      _updateStatus(user.id, 'Safe');
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _tempStatus == 'Safe'
                                            ? Colors.green.withValues(alpha: 0.18)
                                            : Colors.white.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _tempStatus == 'Safe'
                                              ? Colors.green
                                              : Colors.white.withValues(alpha: 0.08),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: _tempStatus == 'Safe' ? Colors.green : Colors.white24,
                                            size: 26,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'I AM SAFE',
                                            style: GoogleFonts.inter(
                                              color: _tempStatus == 'Safe' ? Colors.green : Colors.white70,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Unsafe Option Card
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _tempStatus = 'Unsafe';
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _tempStatus == 'Unsafe'
                                            ? Colors.redAccent.withValues(alpha: 0.18)
                                            : Colors.white.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _tempStatus == 'Unsafe'
                                              ? Colors.redAccent
                                              : Colors.white.withValues(alpha: 0.08),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: _tempStatus == 'Unsafe' ? Colors.redAccent : Colors.white24,
                                            size: 26,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'NEED HELP',
                                            style: GoogleFonts.inter(
                                              color: _tempStatus == 'Unsafe' ? Colors.redAccent : Colors.white70,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_tempStatus == 'Unsafe') ...[
                              const SizedBox(height: 18),
                              Text(
                                'DESCRIBE YOUR EMERGENCY / NEED',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.redAccent.withValues(alpha: 0.8),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _messageController,
                                maxLines: 2,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black26,
                                  hintText: 'e.g. Basement waterlogged, need power bank or pump...',
                                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _isUpdating ? null : () => _updateStatus(user.id, 'Unsafe'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                child: _isUpdating
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text('BROADCAST DISTRESS ALERT', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Real-time List Tab Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEIGHBORHOOD STATUS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white38,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TabBar(
                            controller: _tabController,
                            labelColor: AppColors.neonCyan,
                            unselectedLabelColor: Colors.white38,
                            indicatorColor: AppColors.neonCyan,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                            tabs: const [
                              Tab(text: '🚨 HELP REQUIRED'),
                              Tab(text: '✅ SAFE'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Real-time List Data Stream
                  safetyListAsync.when(
                    data: (users) {
                      final unsafeUsers = users.where((u) => u.safetyStatus == 'Unsafe').toList();
                      final safeUsers = users.where((u) => u.safetyStatus == 'Safe').toList();

                      return SliverFillRemaining(
                        hasScrollBody: true,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Unsafe Users
                            unsafeUsers.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 48),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Everyone is safe!',
                                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'No active distress coordinates reported.',
                                            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    itemCount: unsafeUsers.length,
                                    itemBuilder: (context, idx) {
                                      final neighbor = unsafeUsers[idx];
                                      final checkTime = neighbor.lastSafetyCheck != null
                                          ? DateFormat('hh:mm a').format(neighbor.lastSafetyCheck!)
                                          : 'Just Now';

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: _glassContainer(
                                          padding: 16,
                                          borderRadius: 20,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent.withValues(alpha: 0.12),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            neighbor.name ?? 'Resident',
                                                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                                          ),
                                                        ),
                                                        Text(
                                                          checkTime,
                                                          style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w700),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      neighbor.address ?? 'No address listed',
                                                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                                    ),
                                                    if (neighbor.safetyMessage != null && neighbor.safetyMessage!.isNotEmpty) ...[
                                                      const SizedBox(height: 10),
                                                      Container(
                                                        padding: const EdgeInsets.all(10),
                                                        width: double.infinity,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black38,
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          neighbor.safetyMessage!,
                                                          style: GoogleFonts.inter(
                                                            color: Colors.white70,
                                                            fontSize: 12,
                                                            fontStyle: FontStyle.italic,
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              IconButton(
                                                icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.neonCyan),
                                                onPressed: () => _makeCall(neighbor.phoneNumber),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                            // Tab 2: Safe Users
                            safeUsers.isEmpty
                                ? Center(
                                    child: Text(
                                      'No check-ins yet.',
                                      style: GoogleFonts.inter(color: Colors.white38),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    itemCount: safeUsers.length,
                                    itemBuilder: (context, idx) {
                                      final neighbor = safeUsers[idx];
                                      final checkTime = neighbor.lastSafetyCheck != null
                                          ? DateFormat('hh:mm a').format(neighbor.lastSafetyCheck!)
                                          : 'Just Now';

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: _glassContainer(
                                          padding: 14,
                                          borderRadius: 18,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      neighbor.name ?? 'Resident',
                                                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      neighbor.address ?? 'No address listed',
                                                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                'Safe at $checkTime',
                                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
                    ),
                    error: (err, _) => SliverFillRemaining(
                      child: Center(child: Text('Error loading status: $err', style: const TextStyle(color: Colors.redAccent))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
