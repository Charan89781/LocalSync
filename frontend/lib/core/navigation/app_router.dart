import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/chat/chat_list_screen.dart';
import '../../presentation/screens/chat/chat_room_screen.dart';
import '../../presentation/screens/chat/ai_assistant_screen.dart';
import '../../presentation/screens/emergency/emergency_screen.dart';
import '../../presentation/screens/complaints/complaint_list_screen.dart';
import '../../presentation/screens/complaints/create_complaint_screen.dart';
import '../../presentation/screens/events/event_list_screen.dart';
import '../../presentation/screens/marketplace/marketplace_screen.dart';
import '../../presentation/screens/business/business_directory_screen.dart';
import '../../presentation/screens/notice_board/notice_board_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/verification_requests_screen.dart';
import '../../presentation/screens/help/community_feed_screen.dart';
import '../../presentation/screens/help/help_request_screen.dart';
import '../../presentation/screens/rentals/rental_spaces_screen.dart';
import '../../presentation/screens/auth/location_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/verification_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/support_screen.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/dashboard/weather_screen.dart';
import '../../presentation/screens/dashboard/weather_alerts_screen.dart';
import '../../presentation/screens/events/ridesync_screen.dart';
import '../../presentation/screens/dashboard/ecosync_screen.dart';
import '../../presentation/screens/dashboard/ar_screen.dart';
import '../../presentation/screens/profile/leaderboard_screen.dart';
import '../../presentation/screens/marketplace/add_item_screen.dart';
import '../../presentation/screens/marketplace/my_listings_screen.dart';
import '../../presentation/screens/marketplace/marketplace_requests_screen.dart';
import '../../presentation/screens/marketplace/marketplace_history_screen.dart';
import '../../presentation/screens/rentals/add_space_screen.dart';
import '../../presentation/screens/rentals/my_spaces_screen.dart';
import '../../presentation/screens/rentals/space_bookings_screen.dart';
import '../../presentation/screens/events/offer_ride_screen.dart';
import '../../presentation/screens/events/my_rides_screen.dart';
import '../../presentation/screens/events/ridesync_history_screen.dart';
import '../../presentation/screens/dashboard/recycle_guide_screen.dart';
import '../../presentation/screens/dashboard/solar_analytics_screen.dart';
import '../../presentation/screens/help/create_help_request_screen.dart';
import '../../presentation/screens/help/volunteer_history_screen.dart';
import '../../presentation/screens/notice_board/create_notice_screen.dart';
import '../../presentation/screens/complaints/my_complaints_screen.dart';
import '../../presentation/screens/business/register_business_screen.dart';
import '../../presentation/screens/profile/badge_details_screen.dart';
import '../../presentation/screens/profile/trust_score_breakdown_screen.dart';
import '../../presentation/screens/dashboard/notification_center_screen.dart';
import '../../presentation/screens/profile/settings_screen.dart';
import '../../presentation/screens/marketplace/item_detail_screen.dart';
import '../../presentation/screens/events/event_detail_screen.dart';
import '../../presentation/screens/business/business_detail_screen.dart';
import '../../presentation/screens/complaints/complaint_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/location',
        builder: (context, state) => const LocationScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/weather',
        builder: (context, state) => const WeatherScreen(),
      ),
      GoRoute(
        path: '/weather-alerts',
        builder: (context, state) => const WeatherAlertsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'support',
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: 'badges',
            builder: (context, state) => const BadgeDetailsScreen(),
          ),
          GoRoute(
            path: 'trust-breakdown',
            builder: (context, state) => const TrustScoreBreakdownScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),

      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return ChatRoomScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/emergency',
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpRequestScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateHelpRequestScreen(),
          ),
          GoRoute(
            path: 'volunteer-history',
            builder: (context, state) => const VolunteerHistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/community',
        builder: (context, state) => const CommunityFeedScreen(),
      ),
      GoRoute(
        path: '/rentals',
        builder: (context, state) => const RentalSpacesScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddSpaceScreen(),
          ),
          GoRoute(
            path: 'my-spaces',
            builder: (context, state) => const MySpacesScreen(),
          ),
          GoRoute(
            path: 'bookings',
            builder: (context, state) => const SpaceBookingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/complaints',
        builder: (context, state) => const ComplaintListScreen(),
        routes: [
          GoRoute(
            path: 'my',
            builder: (context, state) => const MyComplaintsScreen(),
          ),
          GoRoute(
            path: ':complaintId',
            builder: (context, state) {
              final complaintId = state.pathParameters['complaintId'];
              return ComplaintDetailScreen(complaintId: complaintId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/complaints/new',
        builder: (context, state) => const CreateComplaintScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventListScreen(),
        routes: [
          GoRoute(
            path: ':eventId',
            builder: (context, state) {
              final eventId = state.pathParameters['eventId'];
              return EventDetailScreen(eventId: eventId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const MarketplaceScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddItemScreen(),
          ),
          GoRoute(
            path: 'my-listings',
            builder: (context, state) => const MyListingsScreen(),
          ),
          GoRoute(
            path: 'requests',
            builder: (context, state) => const MarketplaceRequestsScreen(),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const MarketplaceHistoryScreen(),
          ),
          GoRoute(
            path: ':itemId',
            builder: (context, state) {
              final itemId = state.pathParameters['itemId'];
              return ItemDetailScreen(itemId: itemId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/business',
        builder: (context, state) => const BusinessDirectoryScreen(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegisterBusinessScreen(),
          ),
          GoRoute(
            path: ':businessId',
            builder: (context, state) {
              final businessId = state.pathParameters['businessId'];
              return BusinessDetailScreen(businessId: businessId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/notices',
        builder: (context, state) => const NoticeBoardScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateNoticeScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ridesync',
        builder: (context, state) => const RideSyncScreen(),
        routes: [
          GoRoute(
            path: 'offer',
            builder: (context, state) => const OfferRideScreen(),
          ),
          GoRoute(
            path: 'my-rides',
            builder: (context, state) => const MyRidesScreen(),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const RideSyncHistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ecosync',
        builder: (context, state) => const EcoSyncScreen(),
        routes: [
          GoRoute(
            path: 'recycle-guide',
            builder: (context, state) => const RecycleGuideScreen(),
          ),
          GoRoute(
            path: 'solar-analytics',
            builder: (context, state) => const SolarAnalyticsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ar',
        builder: (context, state) => const ArScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'verify-requests',
            builder: (context, state) => const VerificationRequestsScreen(),
          ),
        ],
      ),

    ],
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      
      // Allow the splash screen to render its premium branding animation first!
      if (state.matchedLocation == '/splash') return null;

      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';

      return null;
    },
  );
});
