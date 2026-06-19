import 'package:flutter/material.dart';

import '../core/services/revenuecat_service.dart';
import '../core/services/subscription_service.dart';
import '../features/personality_test/screens/personality_test_screen.dart';
import '../features/personality_test/services/personality_test_service.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authService, this.firebaseAvailable = true});

  final AuthService? authService;
  final bool firebaseAvailable;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  PersonalityTestService? _personalityTestService;
  Future<void>? _revenueCatReadyFuture;
  String? _revenueCatUserId;
  int _completionRefreshKey = 0;

  PersonalityTestService get _testService {
    return _personalityTestService ??= PersonalityTestService();
  }

  void _refreshCompletionStatus() {
    setState(() => _completionRefreshKey++);
  }

  Future<void> _ensureRevenueCatReady(String userId) {
    if (_revenueCatUserId == userId && _revenueCatReadyFuture != null) {
      return _revenueCatReadyFuture!;
    }

    _revenueCatUserId = userId;
    _revenueCatReadyFuture = _loginRevenueCat(userId);
    return _revenueCatReadyFuture!;
  }

  Future<void> _loginRevenueCat(String userId) async {
    try {
      await RevenueCatService.instance.initialize(userId);
      await SubscriptionService.instance.start();
    } catch (error) {
      debugPrint('RevenueCat startup failed: $error');
      SubscriptionService.instance.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseAvailable) {
      return const _UnsupportedFirebaseAuthScreen();
    }

    final service = widget.authService ?? AuthService();

    return StreamBuilder(
      stream: service.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLogoScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          SubscriptionService.instance.reset();
          _revenueCatUserId = null;
          _revenueCatReadyFuture = null;
          return LoginScreen(authService: service);
        }

        return FutureBuilder<void>(
          key: ValueKey('revenuecat-${user.uid}'),
          future: _ensureRevenueCatReady(user.uid),
          builder: (context, revenueCatSnapshot) {
            if (revenueCatSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashLogoScreen();
            }

            if (revenueCatSnapshot.hasError) {
              return _StartupErrorScreen(
                title: 'Abonelik durumu hazırlanamadı',
                error: revenueCatSnapshot.error,
                onRetry: () {
                  setState(() {
                    _revenueCatUserId = null;
                    _revenueCatReadyFuture = null;
                  });
                },
              );
            }

            return FutureBuilder<bool>(
              key: ValueKey('${user.uid}-$_completionRefreshKey'),
              future: _testService.hasCompletedTest(user.uid),
              builder: (context, completionSnapshot) {
                if (completionSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _SplashLogoScreen();
                }

                if (completionSnapshot.hasError) {
                  return _TestStatusErrorScreen(
                    onRetry: _refreshCompletionStatus,
                    error: completionSnapshot.error,
                  );
                }

                final completed = completionSnapshot.data == true;
                if (!completed) {
                  return PersonalityTestScreen(
                    service: _testService,
                    onCompleted: _refreshCompletionStatus,
                  );
                }

                return HomeScreen(authService: service, user: user);
              },
            );
          },
        );
      },
    );
  }
}

class _SplashLogoScreen extends StatelessWidget {
  const _SplashLogoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: Center(
        child: Image.asset(
          'logo/logo.png',
          width: 132,
          height: 132,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final String title;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFF6C85F),
                  size: 48,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFA5A8B3),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TestStatusErrorScreen extends StatelessWidget {
  const _TestStatusErrorScreen({required this.onRetry, required this.error});

  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFFF6C85F),
                  size: 48,
                ),
                const SizedBox(height: 18),
                Text(
                  'Test durumu kontrol edilemedi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFA5A8B3),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnsupportedFirebaseAuthScreen extends StatelessWidget {
  const _UnsupportedFirebaseAuthScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC857).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0x44FFC857)),
                    ),
                    child: const Icon(
                      Icons.desktop_access_disabled_rounded,
                      color: Color(0xFFFFC857),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Firebase Auth is not available on Linux desktop',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Run Vault on Chrome, Android, iOS, macOS, or Windows to use the Firebase Authentication flow.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFADB3C2),
                      height: 1.45,
                    ),
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
