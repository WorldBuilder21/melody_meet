import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/auth/api/auth_repository.dart';
import 'package:melody_meets/auth/providers/account_provider.dart';
import 'package:melody_meets/auth/schemas/account.dart';
import 'package:melody_meets/auth/view/login/login_field.dart';
import 'package:melody_meets/auth/view/signup/signup_walkthrough.dart';
import 'package:melody_meets/home/home.dart';
import 'package:melody_meets/layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import screens and services (You'll need to create these files)
import 'config/theme.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Auth state provider - using autoDispose to prevent memory leaks
final authStateProvider = StreamProvider.autoDispose<AuthState>((ref) {
  debugPrint('Initializing authStateProvider');
  return ref.watch(authRepositoryProvider).authState;
});

// User profile provider with auto-dispose
final userProfileProvider = FutureProvider.autoDispose<Account?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);

  if (authState.session != null) {
    debugPrint(
      'UserProfileProvider: User is logged in with ID: ${authState.session!.user.id}',
    );
    try {
      final userProfile = await ref
          .read(authRepositoryProvider)
          .getAccount(authState.session!.user.id);

      debugPrint(
        'UserProfileProvider: Profile loaded successfully with ID: ${userProfile.id}',
      );

      ref.read(currentAccount.notifier).state = userProfile;

      return userProfile;
    } catch (e) {
      debugPrint('UserProfileProvider: Error loading profile: $e');
      rethrow;
    }
  } else {
    debugPrint(
      'UserProfileProvider: No active session, returning null profile',
    );
    return null;
  }
});

// User data provider - simplified and with auto-dispose
final userDataProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  debugPrint('UserDataProvider: Starting to load user data');
  final userProfile = await ref.watch(userProfileProvider.future);

  if (userProfile == null) {
    debugPrint('UserDataProvider: No profile available');
    return null;
  }

  debugPrint('UserDataProvider: Profile loaded with ID: ${userProfile.id}');
  return userProfile;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('App starting...');

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: '.env');
  debugPrint('Environment variables loaded');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );
  debugPrint('Supabase initialized');

  // Clear keyboard state
  ServicesBinding.instance.keyboard.clearState();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Run the app with provider scope
  runApp(const ProviderScope(child: MelodyMeetApp()));
  debugPrint('App started');
}

class MelodyMeetApp extends ConsumerWidget {
  const MelodyMeetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Building MelodyMeetApp');

    // Watch auth state
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Melody Meet',
      theme: AppTheme.darkTheme,
      home: authState.when(
        loading: () => const SplashScreen(),
        error: (_, __) => const LoginField(),
        data: (state) {
          if (state.session != null) {
            return ref
                .watch(userDataProvider)
                .when(
                  loading: () => const SplashScreen(),
                  error: (_, __) => const LoginField(),
                  data: (userData) {
                    if (userData == null) {
                      return const LoginField();
                    } else {
                      return const Layout();
                    }
                  },
                );
          }
          return const LoginField();
        },
      ),
      routes: {
        LoginField.routeName: (context) => const LoginField(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        SignupWalkthrough.routeName: (context) => const SignupWalkthrough(),
        // Add more routes as needed
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Melody Meet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
