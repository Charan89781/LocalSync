import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../domain/entities/business_entity.dart';
import '../../../domain/entities/inquiry_entity.dart';
import '../../../firebase_options.dart';

class BusinessDirectoryScreen extends ConsumerWidget {
  const BusinessDirectoryScreen({super.key});

  Widget _glassContainer({required Widget child, double padding = 16, double borderRadius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
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
    final businessesAsync = ref.watch(businessesProvider);
    final accentColor = ref.watch(accentColorProvider);

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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildBusinessHeader(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(accentColor),
                    const SizedBox(height: 32),
                    const Text('Top Rated Nearby',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    businessesAsync.when(
                      data: (businesses) => businesses.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text('No businesses listed yet.',
                                    style: TextStyle(color: Colors.white38, fontSize: 15)),
                              ),
                            )
                          : _buildBusinessGrid(businesses, ref, accentColor),
                      loading: () =>
                          Center(child: CircularProgressIndicator(color: accentColor)),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            const Text('Could not load businesses',
                                style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => ref.refresh(businessesProvider),
                              icon: const Icon(Icons.refresh_rounded, color: AppColors.neonCyan, size: 16),
                              label: const Text('Retry', style: TextStyle(color: AppColors.neonCyan)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Explore Categories',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    _buildCategoryChips(),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBusinessSheet(context, ref),
        backgroundColor: accentColor,
        icon: const Icon(Icons.add, color: AppColors.primaryNavy),
        label: const Text('ADD BUSINESS',
            style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBusinessHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue.withOpacity(0.85), AppColors.secondaryBlue.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
            const SizedBox(height: 12),
            const Text('Local Business',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Discover and support your neighborhood stores',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search services, food, retail...',
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: accentColor),
        ),
      ),
    );
  }

  void _showAddBusinessSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final addrController = TextEditingController();
    final phoneController = TextEditingController();
    final hoursController = TextEditingController();
    final webController = TextEditingController();
    String category = 'Food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
                color: AppColors.primaryNavy.withOpacity(0.92),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Add Your Business',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 24),
                    _buildSheetField(nameController, 'Business Name'),
                    const SizedBox(height: 16),
                    _buildDropdownCategory((val) => category = val),
                    const SizedBox(height: 16),
                    _buildSheetField(hoursController, 'Business Hours', hint: '9 AM - 9 PM'),
                    const SizedBox(height: 16),
                    _buildSheetField(webController, 'Website (Optional)', hint: 'www.yoursite.com'),
                    const SizedBox(height: 16),
                    _buildSheetField(descController, 'Description', maxLines: 2),
                    const SizedBox(height: 16),
                    _buildSheetField(addrController, 'Address'),
                    const SizedBox(height: 16),
                    _buildSheetField(phoneController, 'Phone Number', keyboardType: TextInputType.phone),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () async {
                        final user = ref.read(authStateProvider).value;
                        if (user == null) return;

                        final biz = BusinessEntity(
                          id: '',
                          name: nameController.text,
                          category: category,
                          description: descController.text,
                          address: addrController.text,
                          phoneNumber: phoneController.text,
                          ownerId: user.id,
                          businessHours: hoursController.text,
                          website: webController.text,
                          isVerified: false,
                        );

                        await ref.read(businessRepositoryProvider).addBusiness(biz);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ref.read(accentColorProvider),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('SUBMIT FOR VERIFICATION',
                          style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField(TextEditingController controller, String label, {String? hint, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownCategory(Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CATEGORY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          ),
          child: DropdownButtonFormField<String>(
            dropdownColor: AppColors.secondaryNavy,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            value: 'Food',
            items: ['Food', 'Services', 'Retail', 'Health', 'Home', 'Other']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => onChanged(v!),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessGrid(List<BusinessEntity> businesses, WidgetRef ref, Color accentColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemCount: businesses.length,
      itemBuilder: (context, index) {
        final biz = businesses[index];
        return GestureDetector(
          onTap: () => _showBusinessProfile(context, ref, biz),
          child: _glassContainer(
            padding: 16,
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.storefront_rounded,
                          color: accentColor, size: 20),
                    ),
                    if (biz.isVerified)
                      Icon(Icons.verified_rounded,
                          color: accentColor, size: 18),
                  ],
                ),
                const Spacer(),
                Text(biz.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(biz.category,
                    style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBusinessProfile(
      BuildContext context, WidgetRef ref, BusinessEntity biz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BusinessProfileSheet(business: biz),
    );
  }

  Widget _buildCategoryChips() {
    final cats = [
      'Restaurant',
      'Medical',
      'Hardware',
      'Salon',
      'Plumbing',
      'Grocery'
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cats
          .map((c) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                ),
                child: Text(c,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white)),
              ))
          .toList(),
    );
  }
}

class _BusinessProfileSheet extends ConsumerStatefulWidget {
  final BusinessEntity business;

  const _BusinessProfileSheet({required this.business});

  @override
  ConsumerState<_BusinessProfileSheet> createState() => _BusinessProfileSheetState();
}

class _BusinessProfileSheetState extends ConsumerState<_BusinessProfileSheet> {
  int _activeTab = 0; // 0 for Info, 1 for AI Chat
  final _inquiryC = TextEditingController();
  final _chatC = TextEditingController();
  final _scrollC = ScrollController();
  
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _isTyping = false;
  String _geminiKey = '';
  bool _keyLoaded = false;

  final List<Map<String, String>> _suggestions = [
    {'icon': '⏰', 'label': 'Opening hours'},
    {'icon': '📍', 'label': 'Location & Map'},
    {'icon': '🏷️', 'label': 'Active deals'},
    {'icon': '📞', 'label': 'Contact info'},
    {'icon': '💼', 'label': 'Services offered'},
  ];

  // Model fallback chain: try newest first, fall back automatically
  final List<String> _kModelChain = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
    'gemini-2.5-flash',
  ];

  @override
  void initState() {
    super.initState();
    _chatHistory.add({
      'sender': 'ai',
      'message': 'Hi! I\'m the Official AI Assistant for ${widget.business.name}. How can I assist you today? You can ask me about our hours, location, active deals, or services! 🤖✨',
      'isStreaming': false,
    });
    _loadKey();
  }

  Future<void> _loadKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('localsync_gemini_api_key') ?? '';
      if (mounted) {
        setState(() {
          _geminiKey = saved.isNotEmpty ? saved : 'AQ.Ab8RN6L1ROXgp_mTR29HzKH_71IwThA_VXl9Ojw2nN6GP4a74g';
          _keyLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _geminiKey = 'AQ.Ab8RN6L1ROXgp_mTR29HzKH_71IwThA_VXl9Ojw2nN6GP4a74g';
          _keyLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _inquiryC.dispose();
    _chatC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(
          _scrollC.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? override]) async {
    final text = (override ?? _chatC.text).trim();
    if (text.isEmpty || _isTyping) return;
    
    if (override == null) _chatC.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _chatHistory.add({
        'sender': 'user',
        'message': text,
        'isStreaming': false,
      });
      _isTyping = true;
    });
    
    _scrollToBottom();
    
    // Call Gemini or fallback offline engine
    String reply;
    if (_geminiKey.isNotEmpty) {
      reply = await _callGemini(text);
    } else {
      reply = _generateAIResponse(text);
    }
    
    if (!mounted) return;
    
    setState(() {
      _chatHistory.add({
        'sender': 'ai',
        'message': '',
        'isStreaming': true,
      });
      _isTyping = false;
    });
    _scrollToBottom();

    // Simulated character-by-character text streaming
    String displayed = '';
    for (int i = 0; i < reply.length; i++) {
      await Future.delayed(const Duration(milliseconds: 8));
      if (!mounted) break;
      displayed += reply[i];
      setState(() {
        _chatHistory[_chatHistory.length - 1]['message'] = displayed;
      });
      if (i % 20 == 0) _scrollToBottom();
    }

    if (mounted) {
      setState(() {
        _chatHistory[_chatHistory.length - 1]['isStreaming'] = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _callGemini(String userQuery) async {
    final biz = widget.business;
    final systemPrompt = """You are the official, premium AI Assistant for the local business: "${biz.name}" inside the LocalSync3 community app.
Your task is to assist customers with queries specifically about this business.

BUSINESS PROFILE DETAILS:
- Name: ${biz.name}
- Category: ${biz.category}
- Description: ${biz.description}
- Address: ${biz.address}
- Hours: ${biz.businessHours ?? 'Not specified'}
- Phone: ${biz.phoneNumber ?? 'Not specified'}
- Website: ${biz.website ?? 'Not specified'}
- Rating: ${biz.rating} stars

PROMOTION OFFERS:
- Promo Ticket: Verified residents receive 20% OFF using the scan code "NEIGHBOR20" (redeemable in the app or store).

INSTRUCTIONS:
- Keep your answers friendly, polite, and CONCISE (2-3 sentences max).
- Answer questions regarding operating hours, address, services, products, menu, pricing, discounts, and contact info.
- If the user asks general questions unrelated to this business or the app, politely guide them back to asking about "${biz.name}".
- Use emojis strategically and keep a professional customer service tone.
- Do not make up facts. If information is not available, ask the user to submit an official inquiry in the Overview tab.
""";

    final historyContents = <Content>[];
    // Add history for context (last 6 messages to prevent overflow)
    final history = _chatHistory.skip(_chatHistory.length > 6 ? _chatHistory.length - 6 : 0).toList();
    if (history.isNotEmpty && history.last['message'] == userQuery && history.last['sender'] == 'user') {
      history.removeLast();
    }

    for (final msg in history) {
      final text = msg['message'] as String;
      if (text.isEmpty) continue;
      if (msg['sender'] == 'user') {
        historyContents.add(Content.text(text));
      } else {
        if (historyContents.isEmpty) continue;
        historyContents.add(Content.model([TextPart(text)]));
      }
    }

    for (final modelName in _kModelChain) {
      try {
        final useV1Beta = modelName.contains('2.0') || modelName.contains('2.5') || modelName.contains('3.');
        final requestOptions = useV1Beta
            ? const RequestOptions(apiVersion: 'v1beta')
            : const RequestOptions(apiVersion: 'v1');

        final model = GenerativeModel(
          model: modelName,
          apiKey: _geminiKey,
          requestOptions: requestOptions,
          systemInstruction: Content.system(systemPrompt),
        );

        final chat = model.startChat(history: historyContents);
        final response = await chat.sendMessage(Content.text(userQuery)).timeout(const Duration(seconds: 15));
        final text = response.text ?? '';
        if (text.isNotEmpty) {
          debugPrint('[BusinessAI] Success with model: $modelName');
          return text;
        }
      } catch (e) {
        debugPrint('[BusinessAI] $modelName failed: $e');
        continue; // Try next model silently
      }
    }

    // All models failed — silently use smart local response
    return _generateAIResponse(userQuery);
  }

  String _generateAIResponse(String query) {
    final lc = query.toLowerCase();
    final biz = widget.business;
    
    if (lc.contains('hour') || lc.contains('time') || lc.contains('open') || lc.contains('close')) {
      return 'We are open: ${biz.businessHours ?? "Contact for hours"}.';
    } else if (lc.contains('address') || lc.contains('location') || lc.contains('where') || lc.contains('map')) {
      return 'You can find us at: ${biz.address}.';
    } else if (lc.contains('phone') || lc.contains('contact') || lc.contains('call') || lc.contains('number')) {
      return 'You can reach us directly at ${biz.phoneNumber}.';
    } else if (lc.contains('discount') || lc.contains('promo') || lc.contains('deal') || lc.contains('coupon') || lc.contains('code') || lc.contains('offer')) {
      return 'We have an active promo: use code **NEIGHBOR20** for **20% off** verified resident orders!';
    } else if (lc.contains('service') || lc.contains('price') || lc.contains('cost') || lc.contains('menu')) {
      return 'Our services and rates are tailored to the community. You can drop us an official inquiry in the "Overview" tab, or call us at ${biz.phoneNumber}!';
    } else {
      switch (biz.category.toLowerCase()) {
        case 'food':
          return 'That sounds delicious! For dining options, bookings, or menu specials, let me know. Or visit us in person at ${biz.address}!';
        case 'services':
          return 'We strive to provide top-notch service in our community. What kind of scheduling or service details did you need?';
        case 'health':
          return 'Your wellness is our top priority. Let me know if you need to check booking options or general consultation hours.';
        case 'retail':
          return 'We have an exciting collection in stock! Come down to check it out or let me know what you are looking for.';
        default:
          return 'Excellent question! We\'d love to help you with that. Feel free to visit us or send a direct inquiry to the owner!';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);
    final biz = widget.business;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withOpacity(0.95),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.storefront_rounded,
                      color: accentColor, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(biz.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          if (biz.isVerified) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.verified_rounded,
                                color: accentColor, size: 20),
                          ],
                        ],
                      ),
                      Text(biz.category,
                          style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 0),
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _activeTab == 0 ? accentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                           child: Text(
                            'Overview',
                            style: TextStyle(
                              color: _activeTab == 0 ? AppColors.primaryNavy : Colors.white70,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 1),
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _activeTab == 1 ? accentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            'AI Assistant',
                            style: TextStyle(
                              color: _activeTab == 1 ? AppColors.primaryNavy : Colors.white70,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: _activeTab == 0 
                ? _buildOverviewTab(accentColor)
                : _buildAIChatTab(accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Color accentColor) {
    final biz = widget.business;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.access_time_rounded, biz.businessHours ?? 'Contact for hours', accentColor),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, biz.address, accentColor),
          if (biz.website != null && biz.website!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.language_rounded, biz.website!, accentColor),
          ],
          const SizedBox(height: 24),
          const Text('About',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(biz.description,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5)),
          const SizedBox(height: 24),
          _buildPromoTicketCard(),
          const SizedBox(height: 24),
          const Text('Send a Direct Inquiry to Owner',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _inquiryC,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Ask the owner about services, prices, or availability...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(authStateProvider).value;
              if (user == null) return;

              final inq = InquiryEntity(
                id: '',
                businessId: biz.id,
                businessName: biz.name,
                requesterId: user.id,
                requesterName: user.name ?? 'Neighbor',
                message: _inquiryC.text,
                createdAt: DateTime.now(),
              );

              await ref.read(businessRepositoryProvider).submitInquiry(inq);

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Inquiry sent to business owner!'),
                  backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('SEND DIRECT INQUIRY',
                style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, Color accentColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildPromoTicketCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.confirmation_num_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VERIFIED RESIDENT PROMO',
                          style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      SizedBox(height: 4),
                      Text('Get 20% OFF Your Total Order',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.amber.withOpacity(0.25),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SCAN AT CHECKOUT',
                        style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('CODE: NEIGHBOR20',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_2_rounded, color: Colors.black, size: 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(Color accentColor) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _suggestions.length,
        itemBuilder: (context, i) {
          final s = _suggestions[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _sendMessage('${s['icon']} ${s['label']}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF151F2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s['icon']!, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      s['label']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAIChatTab(Color accentColor) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollC,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            itemCount: _chatHistory.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _chatHistory.length) {
                return _buildTypingIndicator(accentColor);
              }
              final msg = _chatHistory[index];
              final isUser = msg['sender'] == 'user';
              return _buildChatMessage(msg, isUser, accentColor);
            },
          ),
        ),
        _buildSuggestions(accentColor),
        Container(
          padding: EdgeInsets.fromLTRB(24, 10, 24, 28 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: AppColors.secondaryNavy.withOpacity(0.5),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                  ),
                  child: TextField(
                    controller: _chatC,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Ask the AI Assistant...',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _sendMessage(),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: AppColors.primaryNavy,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> msg, bool isUser, Color accentColor) {
    final text = msg['message'] ?? '';
    final isStreaming = msg['isStreaming'] ?? false;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message copied!'),
              duration: Duration(seconds: 1),
              backgroundColor: AppColors.neonCyan,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            gradient: isUser
                ? LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUser ? null : const Color(0xFF151F2E),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 20),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
            boxShadow: isUser
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _buildRichText(text, isUser, accentColor),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(DateTime.now()),
                    style: TextStyle(
                      color: isUser ? AppColors.primaryNavy.withOpacity(0.5) : Colors.white24,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isStreaming) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 10, height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: isUser ? AppColors.primaryNavy.withOpacity(0.6) : accentColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichText(String text, bool isUser, Color accentColor) {
    final textColor = isUser ? AppColors.primaryNavy : Colors.white.withOpacity(0.95);
    final boldColor = isUser ? AppColors.primaryNavy : accentColor;
    final lines = text.split('\n');
    final List<Widget> children = [];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 5));
        continue;
      }

      final isBullet = line.trim().startsWith('•') || line.trim().startsWith('- ');
      final isNumbered = RegExp(r'^\d+\.').hasMatch(line.trim());

      if (isBullet) {
        final content = line.trim().replaceFirst(RegExp(r'^[•\-]\s*'), '');
        children.add(Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: boldColor, fontWeight: FontWeight.bold, fontSize: 13)),
              Expanded(child: _parseInline(content, textColor, boldColor)),
            ],
          ),
        ));
      } else if (isNumbered) {
        final m = RegExp(r'^(\d+\.)(.*)').firstMatch(line.trim())!;
        children.add(Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${m.group(1)} ', style: TextStyle(color: boldColor, fontWeight: FontWeight.bold, fontSize: 13)),
              Expanded(child: _parseInline(m.group(2)!.trim(), textColor, boldColor)),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: _parseInline(line, textColor, boldColor),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _parseInline(String text, Color textColor, Color boldColor) {
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int cursor = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > cursor) {
        parts.add(TextSpan(
          text: text.substring(cursor, m.start),
          style: GoogleFonts.inter(color: textColor, fontSize: 13.5, height: 1.45),
        ));
      }
      parts.add(TextSpan(
        text: m.group(1),
        style: GoogleFonts.inter(color: boldColor, fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.45),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      parts.add(TextSpan(
        text: text.substring(cursor),
        style: GoogleFonts.inter(color: textColor, fontSize: 13.5, height: 1.45),
      ));
    }
    return RichText(text: TextSpan(children: parts));
  }

  Widget _buildTypingIndicator(Color accentColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedPulseDot(color: accentColor, delayMs: 0),
            const SizedBox(width: 4),
            _AnimatedPulseDot(color: accentColor, delayMs: 200),
            const SizedBox(width: 4),
            _AnimatedPulseDot(color: accentColor, delayMs: 400),
          ],
        ),
      ),
    );
  }
}

class _AnimatedPulseDot extends StatefulWidget {
  final Color color;
  final int delayMs;
  
  const _AnimatedPulseDot({required this.color, required this.delayMs});
  
  @override
  State<_AnimatedPulseDot> createState() => _AnimatedPulseDotState();
}

class _AnimatedPulseDotState extends State<_AnimatedPulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
