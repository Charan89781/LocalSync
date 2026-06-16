import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/theme/app_colors.dart';
import '../../../firebase_options.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const _kPrefKey = 'localsync_gemini_api_key';

// Model fallback chain: try newest first, fall back automatically
const List<String> _kModelChain = [
  'gemini-2.5-flash',
  'gemini-2.5-pro',
  'gemini-2.0-flash',
  'gemini-2.0-flash-lite',
  'gemini-flash-latest',
];

const _kSystemPrompt = """You are LocalSync AI — the official, premium smart assistant embedded inside the LocalSync3 community app.

IDENTITY & PERSONALITY:
- You are an expert neighborhood digital concierge AND a friendly, empathetic, human-like companion.
- Keep all responses naturally CONCISE, short, and engaging (typically 2-4 sentences max per turn). Avoid long paragraphs, articles, or walls of text unless the user explicitly requests an in-depth explanation or detailed guide.
- You are fully capable of chatting naturally about daily life, general topics, hobbies, philosophy, daily challenges, and personal advice (behaving like a real human friend).
- Be conversational, warm, and natural. DO NOT force LocalSync app references into general daily life chats unless the user explicitly asks about the app or it naturally fits the context.
- CRITICAL COMMAND: If the user says "stop", "enough", "hush", "shut up", "quit", "silence", or similar commands, immediately stop the current topic and respond with an extremely brief 1-sentence acknowledgment (e.g., "Understood, stopping here! Let me know what you'd like to do next.") and do not output any other content.
- You also know every detail about LocalSync3 features and guide users fluently when asked.
- Use emojis strategically to make answers engaging.
- Keep responses structured with bullet points when listing features.
- NEVER say you are Gemini, ChatGPT, or any other AI brand. You are LocalSync AI.

LOCALSYNC3 APP FEATURES (know these deeply):
1. 🤝 Help & Volunteering — Post help requests or toggle "Willing to Help" to aid neighbors
2. 🔄 Borrow Marketplace — List/borrow tools, ladders, appliances from verified neighbors
3. 🏢 Business Directory — Discover local stores with exclusive 20% verified-resident discounts at Urban Cafe
4. 🏠 Rental Spaces — List/book driveways, terraces, storage lofts by the hour
5. 🚨 SOS & Emergency — Broadcast live location, trigger emergency calls, access shelter points
6. 📅 Community Events — Host/join block parties, cleanups, drills with RSVP and map view
7. 🚗 RideSync Carpooling — Offer/find commute seats, earn eco points, reduce carbon footprint
8. ♻️ EcoSync Initiatives — Waste sorting guides, solar savings tracker, neighborhood leaderboards
9. 🗺️ AR Shelter Navigator — Augmented reality camera overlay guiding you to nearest shelter
10. 💬 Chats & Discussion — Verified-only DMs and group discussion rooms
11. 🎫 Complaint Tracker — File, upvote, and track civic issues (potholes, broken lights) in real-time
12. 👤 Resident Hub — Trust score, flip ID card, eco-points leaderboard, residency verification

EMERGENCY INFO:
- Primary Shelter: Community Hall B (behind the park) — has diesel generators, water, first-aid, blankets
- Security Desk Intercom: 9112
- Municipal Flood Control: 1913
- SOS tap broadcasts GPS coordinates to all nearby verified neighbors

MONSOON SEASON ACTIVE — remind users to: charge power banks, clear gate drains, avoid underpasses, secure balcony items.

Respond helpfully and naturally. When answering about features, always offer to explain more details.""";

// ─── Data Models ─────────────────────────────────────────────────────────────
enum _Role { user, assistant }

class _ChatMessage {
  final _Role role;
  final String text;
  final DateTime timestamp;
  final bool isStreaming;

  _ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.isStreaming = false,
  });

  _ChatMessage copyWith({String? text, bool? isStreaming}) => _ChatMessage(
        role: role,
        text: text ?? this.text,
        timestamp: timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with TickerProviderStateMixin {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _isThinking = false;
  // Inbuilt default key + any user-saved key from Settings
  String _geminiKey = 'AQ.Ab8RN6L1ROXgp_mTR29HzKH_71IwThA_VXl9Ojw2nN6GP4a74g';

  late AnimationController _dotController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Quick suggestion chips
  final List<Map<String, String>> _suggestions = [
    {'icon': '🚀', 'label': 'About the app'},
    {'icon': '🚨', 'label': 'Emergency info'},
    {'icon': '🔄', 'label': 'How to borrow'},
    {'icon': '🚗', 'label': 'RideSync'},
    {'icon': '♻️', 'label': 'EcoSync tips'},
    {'icon': '🗺️', 'label': 'Find shelter'},
    {'icon': '🎫', 'label': 'File complaint'},
    {'icon': '⛈️', 'label': 'Monsoon prep'},
  ];

  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadApiKey();
    _addWelcome();
  }

  Future<void> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefKey) ?? '';
      // Prefer user-saved key if non-empty, else keep inbuilt default
      if (saved.isNotEmpty && mounted) {
        setState(() => _geminiKey = saved);
      }
    } catch (_) {
      // Keep inbuilt default key on any error
    }
  }

  void _addWelcome() {
    _messages.add(_ChatMessage(
      role: _Role.assistant,
      text: "Welcome! I'm **LocalSync AI** 🤖✨\n\n"
          "Your personal neighborhood intelligence hub. I'm online and ready to help with:\n\n"
          "• **Feature guides** — Borrow items, plan carpools, earn eco-points\n"
          "• **Emergency info** — Active shelters, SOS broadcasts, hotlines\n"
          "• **Community rules** — Verification, notices, complaint tracker\n"
          "• **Monsoon alerts** — Safety tips for active heavy-rain season\n\n"
          "Ask me anything about LocalSync3, or tap a suggestion below! 👇",
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _dotController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Send Message ────────────────────────────────────────────────────────
  Future<void> _send([String? override]) async {
    final text = (override ?? _msgController.text).trim();
    if (text.isEmpty || _isThinking) return;

    if (override == null) _msgController.clear();

    final userMsg = _ChatMessage(
      role: _Role.user,
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isThinking = true;
    });
    _scrollToBottom();

    // Small delay so UI shows user bubble first
    await Future.delayed(const Duration(milliseconds: 300));

    String reply = await _callGemini(text);

    if (!mounted) return;

    // Add streaming placeholder
    final streamMsg = _ChatMessage(
      role: _Role.assistant,
      text: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    setState(() {
      _messages.add(streamMsg);
      _isThinking = false;
    });
    _scrollToBottom();

    // Simulate streaming character-by-character
    String displayed = '';
    for (int i = 0; i < reply.length; i++) {
      await Future.delayed(const Duration(milliseconds: 8));
      if (!mounted) break;
      displayed += reply[i];
      setState(() {
        _messages[_messages.length - 1] =
            _messages.last.copyWith(text: displayed, isStreaming: true);
      });
      // Scroll every 20 chars
      if (i % 20 == 0) _scrollToBottom();
    }

    // Mark streaming done
    if (mounted) {
      setState(() {
        _messages[_messages.length - 1] =
            _messages.last.copyWith(isStreaming: false);
      });
      _scrollToBottom();
    }
  }

  // ─── Gemini API Call ─────────────────────────────────────────────────────
  Future<String> _callGemini(String userQuery) async {
    // Build conversation history for multi-turn context
    final historyContents = <Content>[];

    // Add previous messages (last 10 turns for context window efficiency)
    final history = _messages.skip(_messages.length > 10 ? _messages.length - 10 : 0).toList();
    // Remove the last message from history if it is the current user message to avoid duplicate consecutive user roles
    if (history.isNotEmpty && history.last.text == userQuery && history.last.role == _Role.user) {
      history.removeLast();
    }

    for (final msg in history) {
      if (msg.text.isEmpty) continue;
      if (msg.role == _Role.user) {
        historyContents.add(Content.text(msg.text));
      } else {
        // Skip leading model messages to ensure the history sent to Gemini always starts with a user turn (API requirement)
        if (historyContents.isEmpty) continue;
        historyContents.add(Content.model([TextPart(msg.text)]));
      }
    }

    final errors = <String>[];

    // Try each model in the fallback chain using the official SDK!
    for (final modelName in _kModelChain) {
      try {
        debugPrint('[LocalSync AI] Official SDK trying model: $modelName');
        final requestOptions = (modelName.contains('2.0') || modelName.contains('2.5') || modelName.contains('3.'))
            ? const RequestOptions(apiVersion: 'v1beta')
            : const RequestOptions(apiVersion: 'v1');

        final model = GenerativeModel(
          model: modelName,
          apiKey: _geminiKey,
          requestOptions: requestOptions,
          systemInstruction: Content.system(_kSystemPrompt),
        );

        final chat = model.startChat(history: historyContents);
        final response = await chat.sendMessage(Content.text(userQuery)).timeout(const Duration(seconds: 20));
        
        final text = response.text ?? '';
        if (text.isNotEmpty) {
          debugPrint('[LocalSync AI] Official SDK success: $modelName');
          return text;
        }
      } catch (e) {
        debugPrint('[LocalSync AI] Official SDK error on $modelName: $e');
        errors.add('$modelName: ${e.toString().split('\n').first}');
        continue; // Try next model
      }
    }

    // All models failed — fall back to local intelligence
    return _localResponse(userQuery);
  }

  // ─── Local Smart Fallback ────────────────────────────────────────────────
  String _localResponse(String query) {
    final q = query.toLowerCase().trim();

    bool has(List<String> words) {
      final queryWords = q.split(RegExp(r'[^a-zA-Z0-9]+'));
      for (final w in words) {
        if (w.length < 4) {
          if (queryWords.contains(w)) return true;
        } else {
          if (q.contains(w)) return true;
        }
      }
      return false;
    }

    // Greetings
    if (has(['hi', 'hello', 'hey', 'yo', 'sup', 'greet'])) {
      return "Hello! 👋 I'm **LocalSync AI**, your neighborhood smart assistant!\n\n"
          "I'm here 24/7 to help you navigate all of LocalSync3's features — from borrowing a ladder "
          "to finding emergency shelters during monsoon season. What would you like to know?";
    }

    // Travel & Places / Tirupati
    if (has(['tirupati', 'temple', 'place', 'visit', 'travel', 'tourist', 'trip'])) {
      return "Tirupati is a magnificent spiritual and historical destination! 🌴✨\n\n"
          "The most famous place is the **Tirumala Venkateswara Temple** on the hills. Other beautiful spots include **Kapila Theertham water falls** and the historic **Chandragiri Fort**.\n\n"
          "🚗 **LocalSync3 Tip:** Planning a trip there? Go to **Events → RideSync tab** to see if any neighbors are carpooling to Tirupati this weekend! Also, check out **Urban Cafe** in our **Business Directory** to get a cup of authentic South Indian filter coffee before your trip! ☕";
    }

    // Food & Dining / Hungry
    if (has(['food', 'eat', 'drink', 'restaurant', 'cafe', 'hungry', 'dinner', 'lunch'])) {
      return "Looking for a great bite? 🍔☕\n\n"
          "Check out the **Business Directory** inside LocalSync3! Our community favorite is **Urban Cafe**, which offers a **20% exclusive discount** to all verified LocalSync residents! Just show your Resident ID pass (Profile ➔ tap to flip ID card) at the counter.\n\n"
          "You can also browse other local shops and reviews under the Business Directory module!";
    }

    // Connect / Network
    if (has(['connect', 'internet', 'online', 'wifi', 'network', 'offline', 'work'])) {
      return "I have a built-in cloud AI connection! 📱☁️\n\n"
          "I will automatically use the live AI engine whenever your phone has active mobile data or WiFi. If I ever respond with local info, your internet may be temporarily unavailable.";
    }

    // Wait / Simple acknowledgement
    if (has(['wait', 'hold', 'sec', 'minute'])) {
      return "Sure thing! Take your time. ⌛ I'll be right here whenever you're ready to ask a question!";
    }

    // Identity
    if ((has(['who', 'what', 'are']) && has(['you', 'your', 'name'])) || has(['creator', 'made', 'built'])) {
      return "I'm **LocalSync AI** 🤖 — a custom-built neighborhood intelligence assistant for the **LocalSync3** app!\n\n"
          "I was designed specifically to help residents:\n"
          "• Navigate all 12 app features instantly\n"
          "• Access emergency info during monsoon season\n"
          "• Find shelters, hotlines, and civic tools\n\n"
          "I'm always connected to the cloud AI engine whenever your device has internet. Ask me anything! 🚀";
    }

    // Wellbeing
    if (q.contains('how are you') || q.contains('how r u') || q.contains('how are u')) {
      return "Running at peak performance! 🤖✨\n\nAll my neighborhood knowledge modules are fully loaded. "
          "How's everything in your sector today? Let me know how I can help!";
    }

    // Thanks
    if (has(['thanks', 'thank', 'awesome', 'great', 'perfect', 'nice', 'cool'])) {
      return "Always happy to help! 😊 Our community is stronger when we're all connected. "
          "Feel free to ask anything else about LocalSync3 or your neighborhood!";
    }

    // Goodbye
    if (has(['bye', 'goodbye', 'cya', 'adios', 'see you'])) {
      return "Goodbye! 👋 Stay safe, look out for your neighbors, and have a wonderful day! "
          "Come back anytime — LocalSync AI is always online for you! 🤖";
    }

    // App overview
    if (has(['app', 'localsync', 'features', 'overview', 'all', 'everything', 'what can'])) {
      return "🚀 **LocalSync3 — Full Feature Guide**\n\n"
          "Your community super-app with **12 powerful modules:**\n\n"
          "🤝 **Help & Volunteering** — Request aid or mark yourself as 'Willing to Help'\n"
          "🔄 **Borrow Marketplace** — Share tools, appliances with verified neighbors\n"
          "🏢 **Business Directory** — Local shops + **20% off at Urban Cafe** for residents!\n"
          "🏠 **Rental Spaces** — Book driveways, terraces, storage rooms hourly\n"
          "🚨 **SOS & Emergency** — Live GPS broadcast + instant emergency hotline calls\n"
          "📅 **Community Events** — RSVP, host, volunteer for neighborhood events\n"
          "🚗 **RideSync** — Carpooling system for daily commutes, save fuel + earn eco points\n"
          "♻️ **EcoSync** — Recycling guides, solar savings, green leaderboards\n"
          "🗺️ **AR Navigator** — Augmented reality shelter guidance through your camera\n"
          "💬 **Chats** — Spam-free verified-only DMs and group discussion rooms\n"
          "🎫 **Complaint Tracker** — File, upvote, and track civic issues to resolution\n"
          "👤 **Resident Hub** — Trust score, ID card, eco-points, residency verification\n\n"
          "Which feature would you like to explore in detail?";
    }

    // Borrow / Marketplace
    if (has(['borrow', 'lend', 'marketplace', 'item', 'items', 'tool', 'tools', 'share', 'ladder'])) {
      return "🔄 **Borrow & Share Marketplace**\n\n"
          "Reduce waste and save money by sharing with neighbors!\n\n"
          "• **Browse items** — Search by category (Tools, Books, Gadgets, Others)\n"
          "• **Borrow** — Send a request with your dates; owner approves via in-app chat\n"
          "• **Lend** — List your items with photos, price (₹/day), and borrowing rules\n"
          "• **Trust Shield** — Only residency-verified users can access listings\n\n"
          "Popular items lent in your community: Power drills, folding tables, camping gear, books!";
    }

    // RideSync
    if (has(['ride', 'ridesync', 'carpool', 'carpooling', 'commute', 'car', 'fuel', 'travel', 'seat'])) {
      return "🚗 **RideSync Carpooling**\n\n"
          "Commute smart, save money, go green together!\n\n"
          "• **Offer a ride** — Post your route, timing, and available seats\n"
          "• **Find a ride** — Search by destination, match with trusted neighbors\n"
          "• **Eco Impact** — Each shared trip earns **carbon offset points** toward your green badge\n"
          "• **Cost sharing** — Split fuel costs automatically via the app\n\n"
          "Go to **Events → RideSync tab** in your bottom nav to get started!";
    }

    // EcoSync
    if (has(['eco', 'ecosync', 'recycle', 'recycling', 'green', 'solar', 'waste', 'points', 'badge', 'leaderboard'])) {
      return "♻️ **EcoSync & Green Leaderboards**\n\n"
          "Gamify your sustainable living!\n\n"
          "• **Waste Sorting Guide** — Detailed local recycling instructions (wet/dry/e-waste)\n"
          "• **Solar Savings** — View community solar panel output and energy savings\n"
          "• **Rainwater harvesting** tips for monsoon season\n"
          "• **Eco Points** — Earn badges for carpooling, volunteering, clean-ups\n"
          "• **Leaderboard** — Compete with neighbors for top green score!\n\n"
          "Badges: 🏆 *Green Commuter*, ⭐ *Active Volunteer*, 🌱 *Clean Block Champion*";
    }

    // AR / Navigation
    if (has(['ar', 'augmented', 'camera', 'compass', 'navigate', 'navigation', 'hud', 'reality'])) {
      return "🗺️ **AR Shelter Navigator**\n\n"
          "When heavy rain strikes and visibility drops — activate AR guidance!\n\n"
          "• **How to use:** Tap the 🗺️ icon on your Dashboard\n"
          "• **Point your camera** at the street — digital markers appear showing direction + distance to nearest shelter\n"
          "• **Real-time overlay** — Updates as you walk toward Community Hall B\n"
          "• **Works offline** — Pre-loaded shelter coordinates don't need internet\n\n"
          "Primary shelter: **Community Hall B** (behind the park, Block C)";
    }

    // Emergency / SOS
    if (has(['emergency', 'sos', 'help', 'danger', 'alert', 'shelter', 'flood', 'evacuate', 'contact', 'hotline', 'number'])) {
      return "🚨 **Emergency & SOS Hub**\n\n"
          "**Immediate Actions:**\n"
          "• Tap **SOS** button → broadcasts your GPS to ALL nearby verified neighbors\n"
          "• Tap **Call** buttons for instant dial:\n"
          "  - 🔐 Security Desk: **Intercom 9112**\n"
          "  - 🌊 Municipal Flood Control: **1913**\n"
          "  - 🚑 Local Ambulance: **108**\n\n"
          "**Active Shelter:**\n"
          "📍 **Community Hall B** (behind Central Park)\n"
          "✅ Diesel generator | ✅ Drinking water | ✅ First-aid | ✅ Blankets\n\n"
          "**Monsoon Status:** ⚠️ Heavy Rain Alert Active — avoid underpasses!";
    }

    // Complaints
    if (has(['complaint', 'complaints', 'issue', 'ticket', 'broken', 'pothole', 'light', 'water', 'resolve', 'report', 'tracker'])) {
      return "🎫 **Complaint & Resolution Tracker**\n\n"
          "Fix civic problems together!\n\n"
          "• **File a ticket** — Upload photos of potholes, broken lights, waterlogging\n"
          "• **Community upvoting** — Neighbors upvote critical issues to escalate priority\n"
          "• **Live status** — Track from *Pending → In Progress → Resolved* with push notifications\n"
          "• **Admin escalation** — High-upvote tickets auto-escalate to admin panel\n\n"
          "Tap **'Tracker'** on the dashboard module grid to raise a new issue!";
    }

    // Business
    if (has(['business', 'store', 'cafe', 'shop', 'discount', 'urban', 'directory'])) {
      return "🏢 **Local Business Directory**\n\n"
          "Support local, save money!\n\n"
          "• **Urban Cafe** — ☕ **20% exclusive discount** for all verified LocalSync residents!\n"
          "• Browse all partner businesses in your area\n"
          "• Read and write verified resident reviews\n"
          "• Find delivery options from local shops\n\n"
          "Show your **Resident Pass** (Profile → flip your ID card) at Urban Cafe to claim your discount!";
    }

    // Rentals
    if (has(['rental', 'rentals', 'parking', 'terrace', 'driveway', 'room', 'space', 'storage', 'loft'])) {
      return "🏠 **Rental Spaces**\n\n"
          "Unlock the unused potential of your community!\n\n"
          "• **List your space** — Driveway, terrace, storage loft, guest room\n"
          "• **Set your rate** — Hourly or daily pricing, your rules\n"
          "• **Book instantly** — Reserve slots from verified neighbors only\n"
          "• **No platform fees** — Direct neighbor-to-neighbor transaction\n\n"
          "Tap **Rentals** on your dashboard to browse available spaces right now!";
    }

    // Chat / Messaging
    if (has(['chat', 'message', 'dm', 'inbox', 'messaging', 'talk', 'discuss', 'room'])) {
      return "💬 **Chats & Community Messaging**\n\n"
          "Safe, spam-free communication for verified residents!\n\n"
          "• **Direct DMs** — Message any verified neighbor privately\n"
          "• **Discussion Rooms** — Topic-based group chats (Events, Monsoon Prep, EcoSync)\n"
          "• **Notice Board** — Pinned official announcements with like & comment threads\n"
          "• **Spam Shield** — Strict admin verification blocks all unverified accounts\n\n"
          "Tap **Chat** (💬) in the bottom navigation bar to open your inbox!";
    }

    // Events
    if (has(['event', 'events', 'cleanup', 'party', 'block', 'volunteer', 'drill', 'meet'])) {
      return "📅 **Community Events**\n\n"
          "Stay connected with what's happening in your block!\n\n"
          "• **Browse events** — Weekend meetups, evening walks, sports, cleanups\n"
          "• **Map view** — See event locations plotted on an interactive map\n"
          "• **RSVP** — Join events with one tap and get reminder notifications\n"
          "• **Host an event** — Create your own community event with date, location, description\n\n"
          "Upcoming: 🧹 *Block Cleanup Drive* this Saturday at 7 AM, Central Park!";
    }

    // Monsoon
    if (has(['monsoon', 'rain', 'flood', 'storm', 'weather', 'prep', 'safety'])) {
      return "⛈️ **Monsoon Safety Protocol — ACTIVE**\n\n"
          "Heavy rain advisory is live for your area. Follow these steps:\n\n"
          "1. 🔋 **Power Bank** — Fully charge all devices immediately\n"
          "2. 🌿 **Secure balcony** — Move potted plants and loose items inside\n"
          "3. 🚗 **Avoid underpasses** — Never drive through flooded roads\n"
          "4. 🚰 **Clear gate drains** — Remove leaves to prevent local flooding\n"
          "5. 🏠 **Know your shelter** — Community Hall B is equipped and ready\n"
          "6. 📱 **SOS ready** — Keep the app open, SOS button is one tap away\n\n"
          "Report local waterlogging through **Complaint Tracker** so admins can dispatch fast!";
    }

    // Profile / Verification / Trust
    if (has(['profile', 'verify', 'verification', 'trust', 'score', 'id', 'pass', 'badge', 'resident'])) {
      return "👤 **Resident Hub & Verification**\n\n"
          "Your digital neighborhood identity!\n\n"
          "• **Flip your ID card** — Tap the card on Profile screen to reveal QR verification pass\n"
          "• **Trust Score** — Built from successful helps, trades, and community contributions\n"
          "• **Residency Verification** — Upload utility bill photo to get the ✅ Verified badge\n"
          "• **Eco Points** — Earned from carpooling, volunteering, recycling activities\n"
          "• **Leaderboard** — See your rank among the community's top contributors\n\n"
          "Verified residents get access to ALL marketplace features and exclusive business discounts!";
    }

    // Jokes / Humor
    if (has(['joke', 'jokes', 'funny', 'laugh', 'humor'])) {
      return "Here's a neighborhood joke for you! 😂\n\n"
          "**Why did the tomato blush?**\n"
          "Because it saw the salad dressing! 🥗\n\n"
          "Ask me for more jokes, stories, or riddles whenever you like! 😄";
    }

    // Social / Friendships / General Advice
    if (has(['friend', 'friends', 'relationship', 'people', 'lonely', 'socialize', 'social'])) {
      return "Building relationships and making friends is all about sharing experiences! 🤝❤️\n\n"
          "Here are 3 great ways to connect with people around you:\n"
          "1. **Listen actively** — Show genuine interest in their stories and hobbies.\n"
          "2. **Find common ground** — Join group activities or shared tasks.\n"
          "3. **Be supportive** — Helping someone out is the fastest way to build lasting trust.\n\n"
          "🏠 **LocalSync3 Tip:** Go to **Events** in the bottom nav to see upcoming block cleanups, drills, or block parties, or post a help request in **Help & Volunteering**! Supporting your neighbors is a beautiful way to make real-life friends! 😊";
    }

    // Life / Motivation / Emotions
    if (has(['sad', 'happy', 'tired', 'bored', 'depressed', 'lonely', 'mood', 'feeling', 'feel'])) {
      return "I hear you! Our moods and feelings change just like the seasons. 🌤️🍂\n\n"
          "If you are feeling a bit down, tired, or bored today, here are a few simple ways to lift your spirits:\n"
          "• **Take a walk** — Getting some fresh air in the neighborhood park can work wonders.\n"
          "• **Stay hydrated** — Grab a fresh glass of water or a warm cup of coffee.\n"
          "• **Connect** — Send a quick text or check in on a neighbor.\n\n"
          "Take it easy today! You are doing great, and your community is always here for you. 💙";
    }

    // Hobbies / Interests (General)
    if (has(['hobby', 'hobbies', 'game', 'play', 'movie', 'book', 'read', 'music', 'song'])) {
      return "Having hobbies and interests keeps life exciting! 🎨📚🎵\n\n"
          "Whether you love reading a good book, watching movies, or listening to music, dedicating time to what you love is wonderful for your well-being.\n\n"
          "🔄 **LocalSync3 Tip:** Did you know you can check the **Borrow Marketplace** to borrow board games, novels, or instruments from your neighbors? It is a great way to try new hobbies for free! 🎲🎸";
    }

    // World Locations & Geography (Highly engaging custom chatbot fallback)
    if (has(['world', 'location', 'locations', 'country', 'city', 'cities', 'geography', 'place', 'places', 'india', 'delhi', 'mumbai', 'hyderabad', 'bangalore', 'america', 'europe', 'london', 'paris', 'tokyo'])) {
      return "The world is full of magnificent wonders, diverse cultures, and stunning locations! 🗺️✈️\n\n"
          "From the historic streets of London and Paris to the vibrant technology hubs of Bangalore and San Francisco, every location has its own beautiful story.\n\n"
          "Ask me about any city, country, or travel destination and I'll give you detailed info! 🌍";
    }

    // Sports & Athletics (Highly engaging custom chatbot fallback)
    if (has(['sports', 'sport', 'cricket', 'football', 'soccer', 'basketball', 'tennis', 'badminton', 'match', 'ipl', 'dhoni', 'kohli', 'messi', 'ronaldo'])) {
      return "Sports have an incredible way of bringing people together and keeping us active! 🏆⚽🏏\n\n"
          "Whether you are tracking live cricket scores, cheering for your favorite football club, or playing badminton in the backyard, sports build great teamwork and health.\n\n"
          "Ask me for match predictions, player stats, or sports history — I'm here to help! 🏅";
    }

    // Default fallback (Empathetic custom chatbot fallback)
    return "I'm here to help! 🌐✨\n\n"
        "As your **LocalSync AI Companion**, I'm powered by built-in cloud AI and can answer questions on neighborhood features, safety, travel, community guidelines, and much more.\n\n"
        "Try asking me something more specific and I'll do my best to help! 🚀";
  }

  // (Settings Dialog removed)

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.primaryNavy,
        colorScheme: ColorScheme.dark(
          primary: AppColors.neonCyan,
          surface: AppColors.surfaceNavy,
          onSurface: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryNavy,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_isThinking) _buildThinkingBubble(),
            _buildSuggestions(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A121A),
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.neonCyan, AppColors.neonPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFF0A121A),
                    child: Icon(Icons.psychology_rounded, color: AppColors.neonCyan, size: 22),
                  ),
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 11, height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryNavy, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Official AI Assistant',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Smart AI • Live',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.length > 2)
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white38, size: 22),
            tooltip: 'Clear chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Clear Chat?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  content: const Text('This will remove all messages.', style: TextStyle(color: Colors.white60)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _messages.clear();
                          _addWelcome();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('CLEAR', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == _Role.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: msg.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message copied!'),
              duration: Duration(seconds: 1),
              backgroundColor: AppColors.neonCyan,
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          margin: EdgeInsets.only(
            bottom: 12,
            left: isUser ? 40 : 0,
            right: isUser ? 0 : 40,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: [AppColors.neonCyan, Color(0xFF00A8D4)],
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
                : Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
            boxShadow: isUser
                ? [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _buildRichText(msg.text, isUser),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmtTime(msg.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? AppColors.primaryNavy.withValues(alpha: 0.5)
                          : Colors.white24,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (msg.isStreaming) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.neonCyan.withValues(alpha: 0.6),
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

  Widget _buildRichText(String text, bool isUser) {
    final textColor = isUser ? AppColors.primaryNavy : Colors.white;
    final boldColor = isUser ? AppColors.primaryNavy : AppColors.neonCyan;
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
              Text('• ', style: TextStyle(color: boldColor, fontWeight: FontWeight.bold, fontSize: 14)),
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
              Text('${m.group(1)} ', style: TextStyle(color: boldColor, fontWeight: FontWeight.bold, fontSize: 14)),
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
          style: TextStyle(color: textColor, fontSize: 13.5, height: 1.45),
        ));
      }
      parts.add(TextSpan(
        text: m.group(1),
        style: TextStyle(color: boldColor, fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.45),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      parts.add(TextSpan(
        text: text.substring(cursor),
        style: TextStyle(color: textColor, fontSize: 13.5, height: 1.45),
      ));
    }
    return RichText(text: TextSpan(children: parts));
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 60, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF151F2E),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(3, (i) => AnimatedBuilder(
              animation: _dotController,
              builder: (_, __) {
                final delay = i * 0.25;
                final val = (_dotController.value + delay) % 1.0;
                final offset = -4.0 * (0.5 - (val - 0.5).abs());
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            )),
            const SizedBox(width: 10),
            const Text('thinking...', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _suggestions.length,
        itemBuilder: (context, i) {
          final s = _suggestions[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _send('${s['icon']} ${s['label']}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF151F2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  '${s['icon']}  ${s['label']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A121A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151F2E),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (_) => _send(),
                maxLines: null,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.neonCyan, Color(0xFF0093B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: AppColors.primaryNavy, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
