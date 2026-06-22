import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/post_entity.dart';
import '../../../domain/entities/comment_entity.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../../core/services/location_service.dart';

class NoticeBoardScreen extends ConsumerStatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  ConsumerState<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends ConsumerState<NoticeBoardScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, int> _localLikes = {};
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;

  bool _showNews = false;
  List<Map<String, String>> _newsItems = [];
  bool _loadingNews = false;
  String? _newsError;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
  }

  Future<void> _fetchNews(String city) async {
    if (_newsItems.isNotEmpty) return;
    setState(() {
      _loadingNews = true;
      _newsError = null;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://news.google.com/rss/search?q=$city&hl=en-IN&gl=IN&ceid=IN:en'));
      if (response.statusCode == 200) {
        final xml = response.body;
        final items = RegExp(r'<item>([\s\S]*?)</item>').allMatches(xml);
        final List<Map<String, String>> news = [];
        for (var item in items) {
          final content = item.group(1) ?? '';
          final title = RegExp(r'<title>([\s\S]*?)</title>')
                  .firstMatch(content)
                  ?.group(1) ??
              '';
          final link = RegExp(r'<link>([\s\S]*?)</link>')
                  .firstMatch(content)
                  ?.group(1) ??
              '';
          final pubDate = RegExp(r'<pubDate>([\s\S]*?)</pubDate>')
                  .firstMatch(content)
                  ?.group(1) ??
              '';
          final source = RegExp(r'<source[\s\S]*?>([\s\S]*?)</source>')
                  .firstMatch(content)
                  ?.group(1) ??
              'Local Updates';

          String cleanTitle = title;
          if (cleanTitle.contains(' - ')) {
            cleanTitle = cleanTitle.substring(0, cleanTitle.lastIndexOf(' - '));
          }

          news.add({
            'title': cleanTitle
                .replaceAll('&amp;', '&')
                .replaceAll('<![CDATA[', '')
                .replaceAll(']]>', ''),
            'link': link.trim(),
            'pubDate': pubDate,
            'source': source,
          });
          if (news.length >= 12) break;
        }

        if (mounted) {
          setState(() {
            _newsItems = news;
            _loadingNews = false;
          });
        }
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newsError = 'Unable to fetch local news for $city';
          _loadingNews = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  // Sticky-note palette — bold, fully opaque backgrounds
  static const List<Color> _noteBg = [
    Color(0xFFFFF176), // Warm Yellow
    Color(0xFFFFCDD2), // Soft Pink/Coral
    Color(0xFFB2EBF2), // Sky Cyan
    Color(0xFFE1BEE7), // Lavender Purple
    Color(0xFFC8E6C9), // Mint Green
    Color(0xFFFFE0B2), // Peach Orange
    Color(0xFFBBDEFB), // Baby Blue
    Color(0xFFF8BBD9), // Rose Pink
  ];

  // Matching pin/accent colours (darker shade of each)
  static const List<Color> _noteAccent = [
    Color(0xFFE65100), // Deep Orange
    Color(0xFFC62828), // Deep Red
    Color(0xFF00838F), // Teal
    Color(0xFF6A1B9A), // Purple
    Color(0xFF1B5E20), // Dark Green
    Color(0xFFBF360C), // Burnt Orange
    Color(0xFF0D47A1), // Navy Blue
    Color(0xFF880E4F), // Dark Rose
  ];

  @override
  Widget build(BuildContext context) {
    final cityName = ref.watch(cityNameProvider);
    final postsAsync = ref.watch(feedPostsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Corkboard-inspired dark warm gradient
          gradient: LinearGradient(
            colors: [Color(0xFF1A0A00), Color(0xFF0A121A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(context, cityName),
            if (!_showNews)
              postsAsync.when(
                data: (posts) {
                  final dbNotices =
                      posts.where((p) => p.type == PostType.announcement).toList();
                  if (dbNotices.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    );
                  }
                  final displayNotices = dbNotices;
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _buildStickyNote(i, displayNotices[i]),
                        childCount: displayNotices.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.neonCyan),
                        SizedBox(height: 16),
                        Text('Loading notices...', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        const Text('Offline — notices unavailable',
                            style: TextStyle(color: Colors.white54, fontSize: 15)),
                        const SizedBox(height: 8),
                        const Text('Connect to internet and pull down to refresh',
                            style: TextStyle(color: Colors.white30, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            else
              _buildNewsSection(),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notices/create'),
        backgroundColor: const Color(0xFFFFB300), // Sticky gold color
        icon: const Icon(Icons.push_pin_rounded, color: AppColors.primaryNavy),
        label: const Text(
          'POST NOTICE',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildHeader(BuildContext context, String cityName) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _headerFade,
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 16, 24, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF5D1A00).withValues(alpha: 0.9),
                const Color(0xFF8B2500).withValues(alpha: 0.7),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.push_pin_rounded, color: Colors.redAccent, size: 14),
                        SizedBox(width: 6),
                        Text('OFFICIAL', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('📌 $cityName Board',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(
                'Official hand-pinned updates for $cityName residents',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              // Segmented Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showNews = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_showNews ? const Color(0xFFFFB300) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'PIN BOARD',
                            style: TextStyle(
                              color: !_showNews ? AppColors.primaryNavy : Colors.white60,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _showNews = true);
                          _fetchNews(cityName);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _showNews ? AppColors.neonCyan : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'LOCAL PULSE',
                            style: TextStyle(
                              color: _showNews ? AppColors.primaryNavy : Colors.white60,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.push_pin_outlined, size: 56, color: Colors.white24),
          ),
          const SizedBox(height: 20),
          const Text('No announcements yet',
              style: TextStyle(color: Colors.white60, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Check back soon for community updates',
              style: TextStyle(color: Colors.white30, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStickyNote(int index, PostEntity notice) {
    final currentUser = ref.watch(authStateProvider).value;
    final isOwner = currentUser != null && notice.authorId == currentUser.id;
    final bg = _noteBg[index % _noteBg.length];
    final accent = _noteAccent[index % _noteAccent.length];
    // Slight rotation for cork-board feel
    final angle = (index.isEven ? 1 : -1) * (0.015 + (index % 3) * 0.008);
    final likesCount = notice.likes + (_localLikes[notice.id] ?? 0);

    return Transform.rotate(
      angle: angle,
      child: GestureDetector(
        onTap: () => _showThreadSheet(context, bg, accent, notice),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              // Main drop shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(3, 6),
              ),
              // Color glow from note color
              BoxShadow(
                color: bg.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Pin at top
              Positioned(
                top: -2,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.push_pin_rounded, color: Colors.white, size: 11),
                  ),
                ),
              ),
              // Sticky note fold corner (bottom-right)
              Positioned(
                bottom: 0, right: 0,
                child: CustomPaint(
                  size: const Size(22, 22),
                  painter: _FoldPainter(bg, accent),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 22, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date + category badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            DateFormat('MMM dd').format(notice.createdAt).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Main content — black text, fully readable
                    Expanded(
                      child: Text(
                        notice.content,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.82),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Georgia', // Handwritten-note feel
                        ),
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: isOwner
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("You cannot upvote your own sticky notice!"),
                                      backgroundColor: AppColors.errorRed,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              : () => setState(() {
                                  _localLikes[notice.id] = (_localLikes[notice.id] ?? 0) + 1;
                                }),
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                color: isOwner ? Colors.black26 : Colors.redAccent,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$likesCount',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: accent, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              'thread',
                              style: TextStyle(
                                color: accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThreadSheet(BuildContext context, Color bg, Color accent, PostEntity notice) {
    final replyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.82,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.95),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44, height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Note preview header
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(2, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
                            child: const Text('PINNED NOTICE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                          const Spacer(),
                          Text(DateFormat('MMM dd, yyyy').format(notice.createdAt),
                              style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(notice.content,
                          style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.85), height: 1.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('PULSE DISCUSSION',
                      style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.white10),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final commentsAsync = ref.watch(postCommentsProvider(notice.id));
                      return commentsAsync.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return Center(
                              child: Text(
                                'No comments in this pulse thread yet.',
                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (ctx, i) {
                              final r = comments[i];
                              final timeStr = DateFormat('hh:mm a').format(r.createdAt);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 13,
                                              backgroundColor: bg.withValues(alpha: 0.25),
                                              backgroundImage: r.authorProfileUrl != null
                                                  ? NetworkImage(r.authorProfileUrl!)
                                                  : null,
                                              child: r.authorProfileUrl == null
                                                  ? Text(r.authorName[0],
                                                      style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold))
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(r.authorName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                          ],
                                        ),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(color: Colors.white24, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(r.text,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
                        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white38))),
                      );
                    },
                  ),
                ),
                // Reply input
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryNavy,
                    border: const Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                          ),
                          child: TextField(
                            controller: replyCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Add to this pulse thread...',
                              hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                              filled: false,
                              fillColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          final text = replyCtrl.text.trim();
                          if (text.isNotEmpty) {
                            final user = ref.read(authStateProvider).value;
                            if (user == null) return;
                            
                            final comment = CommentEntity(
                              id: '',
                              authorId: user.id,
                              authorName: user.name ?? 'Neighbor',
                              authorProfileUrl: user.profileImageUrl,
                              text: text,
                              createdAt: DateTime.now(),
                            );
                            
                            await ref.read(postRepositoryProvider).addComment(notice.id, comment);
                            replyCtrl.clear();
                          }
                        },
                        child: Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.send_rounded, color: accent, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Fold corner painter for sticky note effect
class _FoldPainter extends CustomPainter {
  final Color bg;
  final Color accent;
  const _FoldPainter(this.bg, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final fold = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, fold);
  }

  @override
  bool shouldRepaint(_FoldPainter old) => old.bg != bg || old.accent != accent;
}

extension on _NoticeBoardScreenState {
  Widget _buildNewsSection() {
    if (_loadingNews) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.neonCyan),
        ),
      );
    }

    if (_newsError != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                Text(
                  _newsError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _newsItems[index];
            return _buildNewsCard(item);
          },
          childCount: _newsItems.length,
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final url = Uri.parse(item['link'] ?? '');
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Error launching url: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch browser: $e')),
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (item['source'] ?? 'Local Updates').toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.neonCyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item['pubDate'] != null && item['pubDate']!.length > 16
                            ? item['pubDate']!.substring(0, 16)
                            : (item['pubDate'] ?? ''),
                        style: const TextStyle(color: Colors.white30, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'READ ARTICLE',
                        style: TextStyle(
                          color: AppColors.neonCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_new_rounded, color: AppColors.neonCyan, size: 12),
                    ],
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
