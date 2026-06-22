import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/premium_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../../domain/entities/complaint_entity.dart';
import '../../../domain/entities/user_entity.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  final String? complaintId;
  const ComplaintDetailScreen({super.key, this.complaintId});

  @override
  ConsumerState<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleUpvote(ComplaintEntity complaint, String userId) async {
    HapticFeedback.lightImpact();
    await ref.read(complaintRepositoryProvider).supportComplaint(complaint.id, userId);
  }

  Future<void> _addComment(ComplaintEntity complaint, String userId, String userName) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaint.id)
        .collection('comments')
        .add({
      'senderId': userId,
      'senderName': userName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }



  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (widget.complaintId == null || user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A121A),
        body: Center(child: Text('Invalid complaint information.', style: TextStyle(color: Colors.white))),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').doc(widget.complaintId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A121A),
            body: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A121A),
            body: Center(child: Text('Complaint not found.', style: TextStyle(color: Colors.white))),
          );
        }

        final complaint = ComplaintEntity.fromMap(
          snapshot.data!.data() as Map<String, dynamic>,
          snapshot.data!.id,
        );

        final isSupporting = complaint.supportUserIds.contains(user.id);
        final isOwner = complaint.userId == user.id;
        final isAdmin = user.role == UserRole.admin || user.role == UserRole.moderator;

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
              'Track Complaint',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          body: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.errorRed.withValues(alpha: 0.03),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Title Card
                            _buildHeaderCard(complaint, isSupporting, user.id, isOwner),
                            const SizedBox(height: 24),

                            // Dynamic Timeline Status Tracker
                            Text(
                              'RESOLUTION STATUS TIMELINE',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white54,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTimelineProgress(complaint),
                            const SizedBox(height: 28),

                            // Dynamic Evidence Photo Grid
                            if (complaint.evidenceUrls.isNotEmpty) ...[
                              Text(
                                'EVIDENCE PHOTOS',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white54,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildEvidenceGrid(complaint.evidenceUrls),
                              const SizedBox(height: 28),
                            ],

                            // Authority response highlight card
                            if (complaint.assignedAuthority != null) ...[
                              _buildAuthorityCard(complaint),
                              const SizedBox(height: 28),
                            ],

                            // Admin Status Control Panel (Visible only to administrators)
                            if (isAdmin && complaint.status != ComplaintStatus.resolved) ...[
                              _buildAdminControlPanel(complaint),
                              const SizedBox(height: 32),
                            ],

                            // Dynamic Live Comments Section
                            Text(
                              'RESIDENTS DISCUSSION',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white54,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCommentsList(complaint.id),
                            const SizedBox(height: 16),
                            _buildAddCommentInput(complaint, user.id, user.name ?? 'Resident Neighbor'),
                            const SizedBox(height: 40),
                          ],
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

  Widget _buildHeaderCard(ComplaintEntity complaint, bool isSupporting, String userId, bool isOwner) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      complaint.category.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: AppColors.neonCyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (isOwner) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'YOUR TICKET (REPORTER)',
                        style: GoogleFonts.inter(
                          color: Colors.orangeAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isSupporting ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isOwner
                          ? Colors.white10
                          : (isSupporting ? Colors.redAccent : Colors.white60),
                      size: 20,
                    ),
                    onPressed: isOwner ? null : () => _toggleUpvote(complaint, userId),
                  ),
                  Text(
                    '${complaint.supportUserIds.length} supports',
                    style: GoogleFonts.inter(
                      color: isSupporting ? Colors.redAccent : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            complaint.title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineProgress(ComplaintEntity complaint) {
    final timeline = complaint.timeline;
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: timeline.isEmpty
          ? Center(child: Text('No status updates posted yet.', style: GoogleFonts.inter(color: Colors.white38)))
          : Column(
              children: List.generate(timeline.length, (i) {
                final update = timeline[i];
                final isFirst = i == 0;
                final isLast = i == timeline.length - 1;
                return _buildTimelineItem(
                  title: update.status,
                  date: DateFormat('MMM dd, yyyy • hh:mm a').format(update.timestamp),
                  message: update.message,
                  isFirst: isFirst,
                  isLast: isLast,
                  isCompleted: true,
                  isActive: isLast,
                );
              }),
            ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String date,
    required String message,
    bool isFirst = false,
    bool isLast = false,
    bool isCompleted = false,
    bool isActive = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? (isActive ? AppColors.neonCyan : Colors.greenAccent)
                      : Colors.white10,
                  border: Border.all(
                    color: isCompleted ? Colors.transparent : Colors.white30,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isCompleted && !isActive
                    ? const Icon(Icons.check, color: Colors.black, size: 10)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.greenAccent : Colors.white10,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: isCompleted ? Colors.white : Colors.white30,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: GoogleFonts.inter(
                          color: isCompleted ? Colors.white30 : Colors.white24,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      color: isCompleted ? Colors.white70 : Colors.white24,
                      fontSize: 12,
                      height: 1.4,
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

  Widget _buildEvidenceGrid(List<String> urls) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                urls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthorityCard(ComplaintEntity complaint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OFFICIAL RESPONSE',
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Assigned Authority: ${complaint.assignedAuthority ?? "Utility Supervisor"}. Active operations are underway to resolve the issue as reported.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(String complaintId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
        }
        final comments = snapshot.data!.docs;
        if (comments.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No comments yet. Start the neighborly discussion!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: comments.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final sender = data['senderName'] ?? 'Resident';
            final text = data['text'] ?? '';
            final dynamic timeRaw = data['timestamp'];
            DateTime time = DateTime.now();
            if (timeRaw is Timestamp) {
              time = timeRaw.toDate();
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
                              backgroundColor: AppColors.neonCyan.withValues(alpha: 0.12),
                              child: Text(
                                sender.isNotEmpty ? sender[0].toUpperCase() : 'N',
                                style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
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
          }).toList(),
        );
      },
    );
  }

  Widget _buildAddCommentInput(ComplaintEntity complaint, String userId, String userName) {
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
                hintText: 'Share update or support neighbors...',
                hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (_) => _addComment(complaint, userId, userName),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.neonCyan, size: 20),
            onPressed: () => _addComment(complaint, userId, userName),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminControlPanel(ComplaintEntity complaint) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: AppColors.neonCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'ADMIN CONSOLE CONTROLS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neonCyan,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Change resolution status and update resident timeline:',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAdminActionButton(
                label: 'IN PROGRESS',
                icon: Icons.rotate_right_rounded,
                color: AppColors.neonCyan,
                onPressed: () => _showStatusUpdateDialog(complaint, ComplaintStatus.inProgress),
              ),
              _buildAdminActionButton(
                label: 'RESOLVE',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.greenAccent,
                onPressed: () => _showStatusUpdateDialog(complaint, ComplaintStatus.resolved),
              ),
              _buildAdminActionButton(
                label: 'REJECT',
                icon: Icons.cancel_outlined,
                color: Colors.redAccent,
                onPressed: () => _showStatusUpdateDialog(complaint, ComplaintStatus.rejected),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(icon, color: color, size: 16),
        label: Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Future<void> _showStatusUpdateDialog(ComplaintEntity complaint, ComplaintStatus status) async {
    final statusStr = status == ComplaintStatus.inProgress
        ? 'In Progress'
        : (status == ComplaintStatus.resolved ? 'Resolved' : 'Rejected');
    
    final defaultMsg = status == ComplaintStatus.inProgress
        ? 'Issue marked in progress. Authority team assigned.'
        : (status == ComplaintStatus.resolved 
            ? 'Issue marked resolved & closed by the Administrator.' 
            : 'Issue rejected by Administrator.');

    final messageController = TextEditingController(text: defaultMsg);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Update Status to ${statusStr.toUpperCase()}?', 
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a timeline update message to notify residents:',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: messageController,
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type resolution message...',
                  hintStyle: TextStyle(color: Colors.white30),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white30)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == ComplaintStatus.resolved
                  ? Colors.greenAccent
                  : (status == ComplaintStatus.rejected ? Colors.redAccent : AppColors.neonCyan),
              foregroundColor: AppColors.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      HapticFeedback.mediumImpact();
      final finalMsg = messageController.text.trim().isEmpty 
          ? defaultMsg 
          : messageController.text.trim();

      await ref.read(complaintRepositoryProvider).updateComplaintStatus(
            complaint.id,
            status,
            finalMsg,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status successfully updated to $statusStr!'),
            backgroundColor: status == ComplaintStatus.resolved
                ? Colors.green
                : (status == ComplaintStatus.rejected ? Colors.red : AppColors.primaryBlue),
          ),
        );
      }
    }
    messageController.dispose();
  }
}
