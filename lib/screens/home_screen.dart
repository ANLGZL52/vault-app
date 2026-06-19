import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/auth_error.dart';
import '../core/services/revenuecat_service.dart';
import '../core/services/subscription_service.dart';
import '../features/vaults/screens/vaults_screen.dart';
import '../pages/home_page.dart';
import '../services/auth_service.dart';
import '../widgets/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.authService, required this.user, super.key});

  final AuthService authService;
  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      try {
        await RevenueCatService.instance.logout();
      } catch (_) {
        // Firebase sign-out should still proceed even if RevenueCat logout fails.
      }
      SubscriptionService.instance.reset();
      await widget.authService.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(user: widget.user, onOpenVaults: () => _onTabSelected(1)),
      const VaultsScreen(),
      ProfileTab(
        user: widget.user,
        isLoggingOut: _isLoggingOut,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: const Color(0xFF080C16),
        indicatorColor: const Color(0x22FFC857),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Kasalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
