import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/event_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../common_widgets/premium_widgets.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const EventDetailScreen({super.key, this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isUpdating = false;

  final List<String> _dummyAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=200',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
  ];

  Future<void> _toggleRsvp(EventEntity event, String userId, bool isAlreadyGoing) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('events').doc(event.id);
      if (isAlreadyGoing) {
        await docRef.update({
          'participants': FieldValue.arrayRemove([userId]),
        });
      } else {
        await docRef.update({
          'participants': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating RSVP: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (widget.eventId == null || widget.eventId!.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A121A),
        body: Center(
          child: Text('Invalid Event ID', style: GoogleFonts.inter(color: Colors.white70)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('events').doc(widget.eventId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A121A),
            body: Center(
              child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.white70)),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A121A),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A121A),
            body: Center(
              child: Text('Event not found', style: GoogleFonts.inter(color: Colors.white70)),
            ),
          );
        }

        final eventData = snapshot.data!.data() as Map<String, dynamic>;
        final event = EventEntity.fromMap(eventData, snapshot.data!.id);
        final isGoing = user != null && event.participants.contains(user.id);
        
        // Pick dynamic header image or fallback to localSync category matching
        final categoryLower = event.title.toLowerCase() + " " + event.description.toLowerCase();
        String headerImage = event.imageUrl ?? 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800';
        
        // Set fallback category name
        String eventCategory = 'COMMUNITY';
        if (categoryLower.contains('dance')) {
          eventCategory = 'DANCE';
        } else if (categoryLower.contains('walk') || categoryLower.contains('evening walk')) {
          eventCategory = 'WALK';
        } else if (categoryLower.contains('cook') || categoryLower.contains('food') || categoryLower.contains('baking')) {
          eventCategory = 'COOKING';
        } else if (categoryLower.contains('pet') || categoryLower.contains('dog')) {
          eventCategory = 'PETS';
        } else if (categoryLower.contains('sport') || categoryLower.contains('play') || categoryLower.contains('cricket')) {
          eventCategory = 'SPORTS';
        } else if (categoryLower.contains('clean') || categoryLower.contains('sweep') || categoryLower.contains('cleanup')) {
          eventCategory = 'CLEANUP';
        } else if (categoryLower.contains('work') || categoryLower.contains('meet')) {
          eventCategory = 'WORKSHOP';
        } else if (categoryLower.contains('fest') || categoryLower.contains('celebrat')) {
          eventCategory = 'FESTIVAL';
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A121A),
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Hero Image Banner
                    _buildHeroBanner(headerImage),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Category & Date Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.neonPurple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: AppColors.neonPurple.withOpacity(0.2)),
                                ),
                                child: Text(
                                  eventCategory,
                                  style: GoogleFonts.outfit(
                                    color: AppColors.neonPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('EEEE, MMM dd • HH:mm').format(event.eventDate),
                                style: GoogleFonts.inter(
                                  color: AppColors.neonCyan,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            event.title,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Organizer card
                          _buildOrganizerCard(event.creatorName),
                          const SizedBox(height: 24),
                          // Date / Time / Location metadata card
                          _buildDetailsCard(event),
                          const SizedBox(height: 28),
                          // Attendees / RSVPs row
                          _buildAttendeesSection(event.participants.length),
                          const SizedBox(height: 28),
                          // Description
                          Text(
                            'ABOUT THIS EVENT',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white54,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            event.description.isNotEmpty
                                ? event.description
                                : 'No description provided for this community event. Connect with neighbors and coordinate in the discussion room below!',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 36),
                          // RSVP button
                          ElevatedButton(
                            onPressed: user == null ? null : () => _toggleRsvp(event, user.id, isGoing),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isGoing ? Colors.greenAccent : AppColors.neonCyan,
                              foregroundColor: AppColors.primaryNavy,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _isUpdating
                                ? const CircularProgressIndicator(color: AppColors.primaryNavy)
                                : Text(
                                    isGoing ? '✓ GOING (Click to Cancel)' : 'RSVP FOR EVENT',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2),
                                  ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Header floating back button
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlassCard(
                      borderRadius: 14,
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    GlassCard(
                      borderRadius: 14,
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Event invitation link copied!', style: GoogleFonts.inter()),
                                backgroundColor: AppColors.surfaceNavy,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(String image) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          Image.network(
            image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.surfaceNavy,
                child: const Center(
                  child: Icon(Icons.event_note_rounded, color: AppColors.neonCyan, size: 48),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0A121A),
                  const Color(0xFF0A121A).withOpacity(0.0),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerCard(String name) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organized by $name',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Verified Resident • Neighbor',
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(EventEntity event) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.access_time_filled_rounded,
            color: Colors.orangeAccent,
            title: 'Event Date & Time',
            value: DateFormat('EEEE, MMM dd • hh:mm a').format(event.eventDate),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.pin_drop_rounded,
            color: AppColors.neonCyan,
            title: 'Venue Location',
            value: event.location,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeesSection(int count) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Overlapping avatars
          SizedBox(
            width: 100,
            height: 32,
            child: Stack(
              children: List.generate(_dummyAvatars.length, (index) {
                return Positioned(
                  left: index * 20.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondaryNavy, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(_dummyAvatars[index]),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 0
                  ? 'No neighbors attending yet'
                  : count == 1
                      ? '1 neighbor is attending'
                      : '$count neighbors are attending',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
