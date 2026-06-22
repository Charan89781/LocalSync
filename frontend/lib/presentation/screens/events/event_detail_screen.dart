import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final TextEditingController _commentController = TextEditingController();

  final List<String> _dummyAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=200',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _requestRsvp(EventEntity event, String userId) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ref.read(eventRepositoryProvider).rsvpToEvent(event.id, userId, isMaybe: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancelRsvp(EventEntity event, String userId) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ref.read(eventRepositoryProvider).cancelRsvpToEvent(event.id, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error canceling RSVP: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _approveRsvp(EventEntity event, String userId) async {
    try {
      await ref.read(eventRepositoryProvider).rsvpToEvent(event.id, userId, isMaybe: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RSVP request approved!'), backgroundColor: AppColors.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving request: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Future<void> _rejectRsvp(EventEntity event, String userId) async {
    try {
      await ref.read(eventRepositoryProvider).cancelRsvpToEvent(event.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RSVP request declined.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining request: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Future<void> _removeAttendee(EventEntity event, String userId) async {
    try {
      await ref.read(eventRepositoryProvider).cancelRsvpToEvent(event.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendee removed from event.'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing attendee: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await ref.read(eventRepositoryProvider).deleteEvent(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event successfully deleted.'), backgroundColor: Colors.redAccent),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Future<void> _addComment(String eventId, String userId, String userName) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    try {
      await ref.read(eventRepositoryProvider).addEventDiscussion(eventId, userId, userName, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  void _showDeleteConfirmation(String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Event?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete this event and its official chat room. This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(eventId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('DELETE', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                                  color: AppColors.neonPurple.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.2)),
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
                          _buildOrganizerCard(event.creatorName, user?.id == event.creatorId),
                          const SizedBox(height: 24),
                          // Date / Time / Location metadata card
                          _buildDetailsCard(event),
                          _buildRequirementsCard(event),
                          _buildMiniMapCard(event),
                          const SizedBox(height: 24),
                          // Attendees / RSVPs row
                          _buildAttendeesSection(event),
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
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 36),
                          // RSVP / Organizer panels
                          if (user?.id == event.creatorId) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.neonCyan.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.25), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.neonCyan, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'YOUR EVENT (ORGANIZER)',
                                    style: GoogleFonts.inter(
                                      color: AppColors.neonCyan,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (event.maybeParticipants.isNotEmpty)
                              _buildPendingRequestsSection(event),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _showDeleteConfirmation(event.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.5),
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                              label: Text(
                                'DELETE EVENT',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2),
                              ),
                            ),
                          ] else ...[
                            Builder(
                              builder: (context) {
                                final isPending = user != null && event.maybeParticipants.contains(user.id);
                                return ElevatedButton(
                                  onPressed: user == null ? null : () => isGoing ? _cancelRsvp(event, user.id) : isPending ? _cancelRsvp(event, user.id) : _requestRsvp(event, user.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isGoing
                                        ? Colors.greenAccent
                                        : isPending
                                            ? AppColors.warningOrange
                                            : AppColors.neonCyan,
                                    foregroundColor: isPending ? Colors.white : AppColors.primaryNavy,
                                    minimumSize: const Size(double.infinity, 60),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: _isUpdating
                                      ? CircularProgressIndicator(color: isPending ? Colors.white : AppColors.primaryNavy)
                                      : Text(
                                          isGoing
                                              ? '✓ GOING (Click to Cancel)'
                                              : isPending
                                                  ? '✓ REQUEST PENDING (Cancel)'
                                                  : 'REQUEST TO JOIN EVENT',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2),
                                        ),
                                );
                              }
                            ),
                          ],
                          if (isGoing && event.chatRoomId != null && event.chatRoomId!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/chat/${event.chatRoomId}'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.neonPurple.withValues(alpha: 0.12),
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: AppColors.neonPurple.withValues(alpha: 0.4), width: 1.5),
                                  minimumSize: const Size(double.infinity, 60),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.neonPurple),
                              label: Text(
                                'CHAT WITH ATTENDEES',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2),
                              ),
                            ),
                          ],
                          _buildEventSquadSection(event, user?.id),
                          const SizedBox(height: 36),
                          Text(
                            'RESIDENTS DISCUSSION',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white54,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDiscussionsList(event.id),
                          const SizedBox(height: 16),
                          _buildAddDiscussionInput(event, user?.id ?? '', user?.name ?? 'Neighbor'),
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
                  const Color(0xFF0A121A).withValues(alpha: 0.0),
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

  Widget _buildOrganizerCard(String name, bool isCreator) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Organized by $name',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isCreator) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Text(
                          'ORGANIZER',
                          style: GoogleFonts.inter(
                            color: AppColors.neonCyan,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isCreator ? 'You are the event organizer' : 'Verified Resident • Neighbor',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(EventEntity event) {
    final slotsFilled = event.participants.length;
    final maxSlots = event.maxParticipants;
    final fillPercent = (slotsFilled / maxSlots).clamp(0.0, 1.0);

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            icon: Icons.access_time_filled_rounded,
            color: Colors.orangeAccent,
            title: 'Date & Time',
            value: DateFormat('EEEE, MMM dd • hh:mm a').format(event.eventDate),
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildDetailRow(
            icon: Icons.pin_drop_rounded,
            color: AppColors.neonCyan,
            title: 'Venue Location',
            value: event.location,
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildDetailRow(
            icon: Icons.timer_rounded,
            color: Colors.greenAccent,
            title: 'Event Duration',
            value: '${event.durationHours} Hour${event.durationHours > 1 ? 's' : ''}',
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildDetailRow(
            icon: Icons.payments_rounded,
            color: AppColors.neonPurple,
            title: 'Ticketing / Price',
            value: event.isTicketed ? 'Paid Entry: ₹${event.price?.toInt() ?? 0}' : 'Free Community Event',
          ),
          const Divider(height: 24, color: Colors.white10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Squad Capacity',
                    style: GoogleFonts.inter(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$slotsFilled / $maxSlots Slots Taken',
                    style: GoogleFonts.inter(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: fillPercent,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    fillPercent >= 1.0 ? Colors.redAccent : AppColors.neonCyan,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard(EventEntity event) {
    final list = event.requirements;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded, color: AppColors.neonCyan, size: 20),
                const SizedBox(width: 10),
                Text(
                  'SQUAD GUIDELINES & GEAR',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Text(
                '• Open to all skill levels. Bring positive vibes!\n• Respect neighborhood noise guidelines.\n• Arrive 10 minutes prior to the start time.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5, height: 1.6),
              )
            else
              Column(
                children: list.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_rounded, color: AppColors.neonCyan, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          req,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMapCard(EventEntity event) {
    if (event.latitude == null || event.longitude == null) {
      return const SizedBox.shrink();
    }

    final latLng = LatLng(event.latitude!, event.longitude!);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.map_rounded, color: AppColors.neonCyan, size: 20),
                const SizedBox(width: 10),
                Text(
                  'VENUE LOCATION MAP',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: latLng, zoom: 15),
                  markers: {
                    Marker(
                      markerId: MarkerId(event.id),
                      position: latLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                    ),
                  },
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${event.latitude},${event.longitude}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open map navigation')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.directions_rounded, color: AppColors.primaryNavy, size: 18),
              label: Text(
                'GET DIRECTIONS',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryNavy),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
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
            color: color.withValues(alpha: 0.08),
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
                  color: Colors.white.withValues(alpha: 0.85),
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

  Widget _buildAttendeesSection(EventEntity event) {
    final confirmedIds = event.participants;
    if (confirmedIds.isEmpty) {
      return GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_rounded, color: Colors.white38, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No neighbors attending yet',
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

    final previewIds = confirmedIds.take(4).toList();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: previewIds)
          .get(),
      builder: (context, snapshot) {
        final List<String> avatars = [];
        final List<String> initials = [];
        
        if (snapshot.hasData && snapshot.data != null) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              final imgUrl = data['profileImageUrl'] as String?;
              final name = data['name'] as String? ?? '';
              if (imgUrl != null && imgUrl.isNotEmpty) {
                avatars.add(imgUrl);
              } else {
                initials.add(name.isNotEmpty ? name[0].toUpperCase() : 'N');
              }
            }
          }
        }

        final displayCount = confirmedIds.length;
        
        return GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (avatars.isEmpty && initials.isEmpty)
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: (avatars.length + initials.length) * 20.0 + 12.0,
                  height: 32,
                  child: Stack(
                    children: [
                      ...List.generate(avatars.length, (index) {
                        return Positioned(
                          left: index * 20.0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.secondaryNavy, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(avatars[index]),
                            ),
                          ),
                        );
                      }),
                      ...List.generate(initials.length, (index) {
                        final leftPos = (avatars.length + index) * 20.0;
                        return Positioned(
                          left: leftPos,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.secondaryNavy, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.neonPurple.withValues(alpha: 0.8),
                              child: Text(
                                initials[index],
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayCount == 1
                      ? '1 neighbor is attending'
                      : '$displayCount neighbors are attending',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsSection(EventEntity event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'PENDING RSVP REQUESTS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white54,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: event.maybeParticipants)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const SizedBox.shrink();
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final uDoc = docs[index];
                final data = uDoc.data() as Map<String, dynamic>;
                final name = data['name'] as String? ?? 'Neighbor';
                final avatarUrl = data['profileImageUrl'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null || avatarUrl.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 28),
                          onPressed: () => _approveRsvp(event, uDoc.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: AppColors.errorRed, size: 28),
                          onPressed: () => _rejectRsvp(event, uDoc.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventSquadSection(EventEntity event, String? currentUserId) {
    final confirmedIds = event.participants;
    if (confirmedIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EVENT SQUAD (${confirmedIds.length} / ${event.maxParticipants})',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white54,
                letterSpacing: 1.5,
              ),
            ),
            if (event.chatRoomId != null && event.chatRoomId!.isNotEmpty && confirmedIds.contains(currentUserId))
              GestureDetector(
                onTap: () => context.push('/chat/${event.chatRoomId}'),
                child: Row(
                  children: [
                    const Icon(Icons.forum_rounded, color: AppColors.neonCyan, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Squad Chat',
                      style: GoogleFonts.inter(
                        color: AppColors.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: confirmedIds.take(30).toList())
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Text(
                'Could not load squad details',
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
              );
            }

            final docs = snapshot.data!.docs;
            final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
              ..sort((a, b) {
                if (a.id == event.creatorId) return -1;
                if (b.id == event.creatorId) return 1;
                return 0;
              });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedDocs.length,
              itemBuilder: (context, index) {
                final uDoc = sortedDocs[index];
                final data = uDoc.data() as Map<String, dynamic>;
                final name = data['name'] as String? ?? 'Neighbor';
                final avatarUrl = data['profileImageUrl'] as String?;
                final isHost = uDoc.id == event.creatorId;
                final isMe = uDoc.id == currentUserId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isHost 
                          ? AppColors.neonCyan.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isHost 
                            ? AppColors.neonCyan.withValues(alpha: 0.15) 
                            : Colors.white.withValues(alpha: 0.04),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isHost ? AppColors.neonCyan.withValues(alpha: 0.1) : AppColors.neonPurple.withValues(alpha: 0.1),
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Icon(
                                  isHost ? Icons.workspace_premium_rounded : Icons.person_rounded,
                                  color: isHost ? AppColors.neonCyan : AppColors.neonPurple,
                                  size: 18,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isHost)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 8),
                                          const SizedBox(width: 2),
                                          Text(
                                            'HOST',
                                            style: GoogleFonts.inter(
                                              color: Colors.amber,
                                              fontSize: 7,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (isMe)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonCyan.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1),
                                      ),
                                      child: Text(
                                        'YOU',
                                        style: GoogleFonts.inter(
                                          color: AppColors.neonCyan,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isHost 
                                    ? 'Event Organizer' 
                                    : 'Confirmed Attendee',
                                style: GoogleFonts.inter(
                                  color: isHost ? AppColors.neonCyan.withValues(alpha: 0.7) : Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (currentUserId == event.creatorId && !isHost)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.errorRed, size: 20),
                            tooltip: 'Remove Attendee',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.secondaryNavy,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: Text('Remove Attendee?', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                  content: Text(
                                    'Are you sure you want to remove $name from this event squad?',
                                    style: GoogleFonts.inter(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.bold)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _removeAttendee(event, uDoc.id);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.errorRed,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('REMOVE', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiscussionsList(String eventId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.read(eventRepositoryProvider).getEventDiscussions(eventId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
        }
        final comments = snapshot.data!;
        if (comments.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No comments yet. Start the event discussion!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final data = comments[index];
            final sender = data['userName'] ?? 'Neighbor';
            final text = data['message'] ?? '';
            final dynamic timeRaw = data['timestamp'];
            DateTime time = DateTime.now();
            if (timeRaw is Timestamp) {
              time = timeRaw.toDate();
            } else if (timeRaw is String) {
              time = DateTime.tryParse(timeRaw) ?? DateTime.now();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.neonPurple.withValues(alpha: 0.12),
                              child: Text(
                                sender.isNotEmpty ? sender[0].toUpperCase() : 'N',
                                style: GoogleFonts.outfit(color: AppColors.neonPurple, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              sender,
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('hh:mm a').format(time),
                          style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5, height: 1.45),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddDiscussionInput(EventEntity event, String userId, String userName) {
    if (userId.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add to the discussion...',
                hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (_) => _addComment(event.id, userId, userName),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.neonCyan, size: 20),
            onPressed: () => _addComment(event.id, userId, userName),
          ),
        ],
      ),
    );
  }
}
