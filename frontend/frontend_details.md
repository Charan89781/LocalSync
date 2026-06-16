# LocalSync3 — Frontend Details

This document provides a comprehensive overview of the frontend architecture, code structure, navigation routing, state management, and UI design of the **LocalSync3** Flutter Web and Mobile application.

---

## 🛠️ Core Technology Stack
- **Framework**: Flutter (v3.22+ / Channel Stable)
- **Programming Language**: Dart 3
- **State Management**: Flutter Riverpod (`ConsumerStatefulWidget` & `ConsumerWidget`)
- **Navigation Routing**: GoRouter (declarative router supporting deep-linking)
- **Typography & Aesthetics**: Google Fonts (`Inter` & `Outfit`), Material 3 design tokens
- **Build Targets**: Android (API 21 to 34), Web (HTML5 Canvas SPA)

---

## 📂 Codebase & Folder Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart       # Theme colors (Navy 0xFF0A121A, Cyan 0xFF00D1FF)
│   │   └── app_theme.dart        # Material 3 typography, button gradients, inputs
│   └── navigation/
│       └── app_router.dart       # Declarative GoRouter mappings & auth redirects
├── data/
│   ├── models/                   # Local models: User, Complaint, MarketplaceItem
│   └── repositories/             # Firebase repository abstraction layers
├── presentation/
│   ├── common_widgets/
│   │   ├── app_bottom_nav.dart   # Floating pill bottom navigation bar
│   │   └── premium_widgets.dart  # GlassCard, GradientButton, Shimmer placeholders
│   ├── providers/
│   │   ├── auth_provider.dart    # Riverpod FirebaseAuth watcher
│   │   ├── weather_provider.dart # OpenWeather APIs watcher
│   │   └── location_provider.dart# GPS & Nominatim geolocator controllers
│   └── screens/
│       ├── auth/
│       │   ├── splash_screen.dart     # Instagram-style smooth logo zoom entrance
│       │   ├── onboarding_screen.dart # 3-slide welcoming slider
│       │   ├── login_screen.dart      # Glassmorphism inputs & Google sign-in
│       │   └── register_screen.dart   # Society/Apartment selector form
│       ├── dashboard/
│       │   ├── dashboard_screen.dart  # Main neighborhood navigation hub
│       │   ├── weather_screen.dart    # Temperature charts & active warnings
│       │   ├── ecosync_screen.dart    # Circular progress score & carbon metrics
│       │   ├── recycle_guide_screen.dart # Expandable category cards & collection search
│       │   └── ar_screen.dart         # Hyperlocal shop finder camera overlay
│       ├── complaints/
│       │   ├── complaint_list_screen.dart # Civic tickets list & sorting
│       │   └── complaint_detail_screen.dart # Real-time comments stream & upvote toggler
│       └── profile/
│           ├── profile_screen.dart    # Trust score gauge & achievements
│           ├── leaderboard_screen.dart# Podium ranking of local neighbors
│           └── settings_screen.dart   # Persistent SharedPreferences & auth controls
```

---

## 🧭 Navigation & Declarative Routing (`app_router.dart`)
We use GoRouter to coordinate deep-linking across the application:
- **Redirection Guard**: Checks `authProvider` on every route change. If the user is unauthenticated, they are redirected to `/login`, unless navigating to onboarding.
- **Dynamic Routing**:
  - `/dashboard`: Main landing hub.
  - `/login` / `/register`: Auth gates.
  - `/notices` / `/notices/new`: Announcement boards.
  - `/complaints/:complaintId`: Detail view showing ticket status and local chats.
  - `/profile` / `/settings`: User dashboard and credentials management.

---

## ⚡ State Management Architecture (Riverpod)
The application relies on a decoupled reactive state architecture:
1. **`authProvider`**: Listens directly to `authStateChanges()` on the Firebase Auth repository. Yields the active user object or `null`.
2. **`locationProvider`**: Acquires high-accuracy GPS positions via a fallback queue: tries `LocationAccuracy.best` for 8s, falls back to native cached coordinates, then runs IP-based reverse-lookup if GPS permission is denied.
3. **`cityNameProvider`**: Reverse-geocodes coordinate values to specific society/street strings (e.g. `"Vesavi Nagar, Tirupati"`) using native Android/iOS geolocation services or OpenStreetMap Nominatim APIs.
4. **`weatherProvider`**: Queries the OpenWeatherMap API using coordinates. Returns current metrics (temperature, UV index, humidity, wind) and matches full-screen background gradients.

---

## 🎨 Premium Aesthetics & UX Design
- **Cold-Start Optimization**: Centered native Android drawable icons (`splash_icon_center.xml`) match the Flutter splash screen. This eliminates cold-start visual flashes on mobile devices.
- **Glassmorphic UI Elements**: Custom `GlassCard` widgets apply backdrop filters (`BackdropFilter`) with slight white borders to present cards hovering over deep navy gradients.
- **Haptic Touch Controls**: Feedback triggers (`HapticFeedback.lightImpact()`) occur on suggestion chips, bottom navbar items, and button clicks.

---

## 🧪 Testing Suite Mapped to UI Features
- **Selenium Web (Silicon)**: Automates headless browser checks on `http://localhost:8095` to verify canvas rendering, routing redirects, blank email submission warnings, and invalid username formats.
- **Appium Mobile**: Automates the debug APK on connected devices to verify splash loading, onboarding pagination, skip routing buttons, password validation borders, and credentials submission.
