import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'firebase_options.dart';
import 'core/services/gemini_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Eagerly initialize Gemini Service on launch to establish connection
  GeminiService.instance;

  bool firebaseInitialized = false;
  String? errorMessage;

  try {
    // Use DefaultFirebaseOptions for all platforms (required for firebase_core v3.x+)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    errorMessage = e.toString();
  }

  runApp(
    ProviderScope(
      child: firebaseInitialized
          ? const LocalSyncApp()
          : FirebaseErrorApp(error: errorMessage),
    ),
  );

  SemanticsBinding.instance.ensureSemantics();
}


class FirebaseErrorApp extends StatelessWidget {
  final String? error;
  const FirebaseErrorApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Firebase failed to initialize. This is usually due to a missing or invalid google-services.json file.\n\nError: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart or just exit
                  },
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LocalSyncApp extends ConsumerWidget {
  const LocalSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'LocalSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
