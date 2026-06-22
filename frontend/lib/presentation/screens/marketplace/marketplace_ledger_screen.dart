import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/listing_entity.dart';
import '../../../domain/entities/borrow_request_entity.dart';
import '../../../domain/entities/chat_entity.dart';
import 'package:localsync/domain/entities/user_entity.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../common_widgets/premium_widgets.dart';

class MarketplaceLedgerScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const MarketplaceLedgerScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<MarketplaceLedgerScreen> createState() => _MarketplaceLedgerScreenState();
}

class _MarketplaceLedgerScreenState extends ConsumerState<MarketplaceLedgerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(borrowRequestsProvider);
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A121A),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A121A), Color(0xFF15202B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: authStateAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(child: Text('Please log in to view the ledger', style: TextStyle(color: Colors.white70)));
              }

              if ((listingsAsync.isLoading && !listingsAsync.hasValue) ||
                  (incomingAsync.isLoading && !incomingAsync.hasValue) ||
                  (outgoingAsync.isLoading && !outgoingAsync.hasValue)) {
                return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
              }

              if (listingsAsync.hasError) {
                return Center(child: Text('Error loading listings: ${listingsAsync.error}', style: const TextStyle(color: Colors.red)));
              }
              if (incomingAsync.hasError) {
                return Center(child: Text('Error loading incoming requests: ${incomingAsync.error}', style: const TextStyle(color: Colors.red)));
              }
              if (outgoingAsync.hasError) {
                return Center(child: Text('Error loading borrow requests: ${outgoingAsync.error}', style: const TextStyle(color: Colors.red)));
              }

              final listings = listingsAsync.value ?? [];
              final incoming = incomingAsync.value ?? [];
              final outgoing = outgoingAsync.value ?? [];
              
              // Listings owned by the user
              final ownedListings = listings.where((l) => l.ownerId == user.id).toList();
              
              // Listings borrowed by the user (accepted requests)
              final borrowedListingIds = outgoing
                  .where((r) => r.status == RequestStatus.accepted)
                  .map((r) => r.listingId)
                  .toSet();
              final borrowedListings = listings.where((l) => borrowedListingIds.contains(l.id)).toList();
              
              // Combined list: owned + borrowed
              final myListings = [...ownedListings, ...borrowedListings];

              print('DEBUG: MarketplaceLedgerScreen - Current user.id: ${user.id}');
              print('DEBUG: MarketplaceLedgerScreen - Total listings fetched: ${listings.length}');
              for (var l in listings) {
                print('DEBUG: Listing: id="${l.id}", title="${l.title}", ownerId="${l.ownerId}", match=${l.ownerId == user.id}');
              }

              return Column(
                children: [
                  _buildHeader(context),
                  _buildSummaryCard(incoming, outgoing),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMyPostingsTab(myListings, incoming, user.id),
                        _buildBorrowedTab(outgoing, listings, user),
                        _buildLedgerTab(incoming, outgoing, user.id, listings),
                        _buildRequestsTab(incoming, outgoing),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
            error: (err, _) => Center(child: Text('Auth error: $err', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToDirectChat(BuildContext context, WidgetRef ref, String targetUserId, String templateMessage) async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;
    if (currentUser.id == targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot chat with yourself!"), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
    );

    try {
      final db = FirebaseFirestore.instance;
      final chatRoomsSnap = await db
          .collection('chatRooms')
          .where('isGroup', isEqualTo: false)
          .where('isChannel', isEqualTo: false)
          .where('participants', arrayContains: currentUser.id)
          .get();

      String? roomId;
      for (var doc in chatRoomsSnap.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(targetUserId)) {
          roomId = doc.id;
          break;
        }
      }

      if (roomId == null) {
        roomId = await ref.read(chatRepositoryProvider).createChatRoom(
          [currentUser.id, targetUserId],
          name: 'Private Chat',
        );
        
        final message = MessageEntity(
          id: '',
          senderId: currentUser.id,
          senderName: currentUser.name ?? 'Neighbor',
          text: templateMessage,
          timestamp: DateTime.now(),
        );
        await ref.read(chatRepositoryProvider).sendMessage(roomId, message);
      }

      if (context.mounted) {
        Navigator.pop(context);
        context.push('/chat/$roomId');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chat: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'LEND & BORROW LEDGER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<BorrowRequestEntity> incoming, List<BorrowRequestEntity> outgoing) {
    final acceptedIncoming = incoming.where((r) => r.status == RequestStatus.accepted).toList();
    final acceptedOutgoing = outgoing.where((r) => r.status == RequestStatus.accepted).toList();

    final activeLentCount = acceptedIncoming.length;
    final activeBorrowedCount = acceptedOutgoing.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LENT OUT ITEMS',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, color: AppColors.neonCyan, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$activeLentCount Active',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1.5, height: 40, color: Colors.white10),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BORROWED ITEMS',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, color: Colors.purpleAccent, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$activeBorrowedCount Active',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.neonCyan,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        labelColor: AppColors.primaryNavy,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
        tabs: const [
          Tab(text: 'MY POSTINGS'),
          Tab(text: 'BORROWED'),
          Tab(text: 'FINANCIAL LEDGER'),
          Tab(text: 'REQUESTS'),
        ],
      ),
    );
  }

  Widget _buildMyPostingsTab(List<ListingEntity> myListings, List<BorrowRequestEntity> incomingRequests, String currentUserId) {
    if (myListings.isEmpty) {
      return _buildEmptyState(Icons.inventory_2_outlined, 'No items posted yet', 'Post an item to lend or sell in the community.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: myListings.length,
      itemBuilder: (context, index) {
        final item = myListings[index];
        final activeBorrow = incomingRequests.firstWhere(
          (r) => r.listingId == item.id && r.status == RequestStatus.accepted,
          orElse: () => BorrowRequestEntity(
            id: '',
            listingId: '',
            requesterId: '',
            requesterName: '',
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );

        final isCurrentlyLent = activeBorrow.id.isNotEmpty;

        return GlassCard(
          borderRadius: 20,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: item.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrls.first,
                              fit: BoxFit.cover,
                            )
                          : Container(color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.price > 0 ? '₹${item.price.toInt()}/day' : 'FREE Mutual Aid',
                          style: GoogleFonts.inter(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.ownerId != currentUserId
                                ? Colors.purple.withValues(alpha: 0.12)
                                : (isCurrentlyLent ? AppColors.errorRed.withValues(alpha: 0.12) : AppColors.successGreen.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.ownerId != currentUserId
                                  ? Colors.purple.withValues(alpha: 0.3)
                                  : (isCurrentlyLent ? AppColors.errorRed.withValues(alpha: 0.3) : AppColors.successGreen.withValues(alpha: 0.3)),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.ownerId != currentUserId
                                ? '🟣 Borrowed from ${item.ownerName}'
                                : (isCurrentlyLent
                                    ? '🔴 Lent out to ${activeBorrow.requesterName}'
                                    : '🟢 Available'),
                            style: GoogleFonts.inter(
                              color: item.ownerId != currentUserId
                                  ? Colors.purpleAccent
                                  : (isCurrentlyLent ? AppColors.errorRed : AppColors.successGreen),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/marketplace/${item.id}'),
                    icon: const Icon(Icons.visibility_rounded, size: 14),
                    label: const Text('View', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                  const SizedBox(width: 8),
                  if (item.ownerId == currentUserId)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await _showDeleteConfirmation(item);
                        if (confirm == true) {
                          await ref.read(listingRepositoryProvider).deleteListing(item.id);
                          ref.invalidate(listingsProvider);
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                      label: const Text('Delete', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed.withValues(alpha: 0.15),
                        foregroundColor: AppColors.errorRed,
                        elevation: 0,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        final templateMsg = "Hi! I am returning/contacting you about the item \"${item.title}\" I borrowed.";
                        await _navigateToDirectChat(context, ref, item.ownerId, templateMsg);
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                      label: const Text('Contact Owner', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan.withValues(alpha: 0.15),
                        foregroundColor: AppColors.neonCyan,
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBorrowedTab(List<BorrowRequestEntity> outgoingRequests, List<ListingEntity> listings, UserEntity user) {
    final activeBorrows = outgoingRequests.where((r) => r.status == RequestStatus.accepted).toList();

    if (activeBorrows.isEmpty) {
      return _buildEmptyState(Icons.swap_horizontal_circle_outlined, 'No active borrowed items', 'When you request to borrow an item and the owner approves, it will show up here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: activeBorrows.length,
      itemBuilder: (context, index) {
        final req = activeBorrows[index];
        final matchedListing = listings.firstWhere(
          (l) => l.id == req.listingId,
          orElse: () => ListingEntity(
            id: '',
            ownerId: req.ownerId,
            ownerName: 'Neighbor',
            title: req.listingTitle,
            description: '',
            price: 0,
            type: ListingType.resource,
            category: '',
            createdAt: DateTime.now(),
          ),
        );

        return GlassCard(
          borderRadius: 20,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req.listingTitle,
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                    ),
                    child: const Text('ACTIVE BORROW', style: TextStyle(color: AppColors.successGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Text('Lender: ${matchedListing.ownerName}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Duration: ${DateFormat('MMM dd').format(req.startDate)} - ${DateFormat('MMM dd').format(req.endDate)}',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.push('/marketplace/${req.listingId}'),
                    icon: const Icon(Icons.info_outline_rounded, size: 14),
                    label: const Text('Item Details', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(100, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final templateMsg = "Hi! I am a neighbor interested in your item \"${req.listingTitle}\". My name is ${user.name ?? 'Neighbor'} and my phone number is ${user.phoneNumber ?? 'not provided'}.";
                      await _navigateToDirectChat(context, ref, req.ownerId, templateMsg);
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: const Text('Contact Owner', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: AppColors.primaryNavy,
                      minimumSize: const Size(100, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerTab(List<BorrowRequestEntity> incoming, List<BorrowRequestEntity> outgoing, String? currentUserId, List<ListingEntity> listings) {
    final acceptedIncoming = incoming.where((r) => r.status == RequestStatus.accepted || r.status == RequestStatus.completed).toList();
    final acceptedOutgoing = outgoing.where((r) => r.status == RequestStatus.accepted || r.status == RequestStatus.completed).toList();

    final allTx = [...acceptedIncoming, ...acceptedOutgoing];
    allTx.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (allTx.isEmpty) {
      return _buildEmptyState(Icons.receipt_long_rounded, 'No ledger transactions yet', 'Accepted lending and borrowing transactions will post here.');
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D1FF).withValues(alpha: 0.1),
                const Color(0xFF007BFF).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                'NET COMMUNITY CONTRIBUTION',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                '${acceptedIncoming.length} items lent  •  ${acceptedOutgoing.length} items borrowed',
                style: GoogleFonts.inter(color: AppColors.neonCyan, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Mutual Aid Score: +${(acceptedIncoming.length * 15) + (acceptedOutgoing.length * 5)} Pts',
                style: GoogleFonts.inter(color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: allTx.length,
            itemBuilder: (context, index) {
              final tx = allTx[index];
              final isLent = acceptedIncoming.contains(tx);

              final matchedListing = listings.firstWhere(
                (l) => l.id == tx.listingId,
                orElse: () => ListingEntity(
                  id: '',
                  ownerId: '',
                  title: '',
                  description: '',
                  price: 0.0,
                  type: ListingType.resource,
                  category: '',
                  createdAt: DateTime.now(),
                ),
              );
              final price = tx.price > 0 ? tx.price : matchedListing.price;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLent ? AppColors.neonCyan.withValues(alpha: 0.15) : Colors.purpleAccent.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLent ? AppColors.neonCyan.withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isLent ? AppColors.neonCyan : Colors.purpleAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.listingTitle,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isLent ? 'Lent to: ${tx.requesterName}' : 'Borrowed from: ${matchedListing.ownerName.isNotEmpty ? matchedListing.ownerName : 'Neighbor'}',
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isLent ? 'LENT' : 'BORROWED',
                          style: GoogleFonts.inter(
                            color: isLent ? AppColors.neonCyan : Colors.purpleAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              price > 0 ? Icons.currency_rupee_rounded : Icons.handshake_rounded,
                              color: price > 0 ? AppColors.neonCyan : Colors.greenAccent,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              price > 0 ? '₹${price.toInt()}/day' : 'Free Aid',
                              style: GoogleFonts.inter(
                                color: price > 0 ? AppColors.neonCyan : Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(List<BorrowRequestEntity> incoming, List<BorrowRequestEntity> outgoing) {
    final pendingIncoming = incoming.where((r) => r.status == RequestStatus.pending).toList();
    final sortedOutgoing = List<BorrowRequestEntity>.from(outgoing)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (pendingIncoming.isEmpty && sortedOutgoing.isEmpty) {
      return _buildEmptyState(Icons.hourglass_empty_rounded, 'No pending requests', 'You do not have any incoming lend requests or outgoing borrow requests.');
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        if (pendingIncoming.isNotEmpty) ...[
          _buildSectionHeader('INCOMING REQUESTS TO APPROVE (${pendingIncoming.length})', AppColors.neonCyan),
          ...pendingIncoming.map((req) => _buildIncomingRequestCard(req)),
        ],
        if (sortedOutgoing.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionHeader('YOUR SENT BORROW REQUESTS (${sortedOutgoing.length})', Colors.purpleAccent),
          ...sortedOutgoing.map((req) => _buildOutgoingRequestCard(req)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildIncomingRequestCard(BorrowRequestEntity req) {
    return GlassCard(
      borderRadius: 20,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.listingTitle.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.neonCyan, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('PENDING ACTION', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Requester: ${req.requesterName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Dates: ${DateFormat('MMM dd').format(req.startDate)} - ${DateFormat('MMM dd').format(req.endDate)}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await ref.read(listingRepositoryProvider).updateRequestStatus(req.id, RequestStatus.rejected);
                    ref.invalidate(incomingRequestsProvider);
                  },
                  icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                  label: const Text('DECLINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed.withValues(alpha: 0.15),
                    foregroundColor: AppColors.errorRed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await ref.read(listingRepositoryProvider).updateRequestStatus(req.id, RequestStatus.accepted);
                    ref.invalidate(incomingRequestsProvider);
                    ref.invalidate(listingsProvider);
                  },
                  icon: const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryNavy),
                  label: const Text('APPROVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    foregroundColor: AppColors.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingRequestCard(BorrowRequestEntity req) {
    Color statusColor;
    String statusText;
    switch (req.status) {
      case RequestStatus.pending:
        statusColor = Colors.amber;
        statusText = 'AWAITING LENDER';
        break;
      case RequestStatus.accepted:
        statusColor = AppColors.neonGreen;
        statusText = 'APPROVED';
        break;
      case RequestStatus.rejected:
        statusColor = AppColors.errorRed;
        statusText = 'REJECTED';
        break;
      case RequestStatus.completed:
        statusColor = Colors.blueAccent;
        statusText = 'COMPLETED';
        break;
    }

    return GlassCard(
      borderRadius: 16,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.listingTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Requested: ${DateFormat('MMM dd').format(req.startDate)} - ${DateFormat('MMM dd').format(req.endDate)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String desc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.5),
              ),
              child: Icon(icon, size: 48, color: Colors.white24),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(ListingEntity item) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: Text('Delete Listing?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${item.title}" permanently?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
