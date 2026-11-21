// The main screen after login: a bottom navigation bar whose tabs depend on
// the user's role. Farmers, buyers and the admin each see their own tabs.

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'buyer_demand_screen.dart';
import 'following_screen.dart';
import 'inbox_screen.dart';
import 'marketplace_screen.dart';
import 'my_crops_screen.dart';
import 'my_requests_screen.dart';
import 'price_list_screen.dart';
import 'profile_screen.dart';

/// One tab: its page and its button in the bottom bar.
class _Tab {
  const _Tab(this.label, this.icon, this.page);

  final String label;
  final IconData icon;
  final Widget page;
}

/// Bottom navigation with one tab per main feature of the user's role.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  /// Picks the tabs for the logged-in user's role.
  List<_Tab> _tabsForRole() {
    final user = AuthService.currentUser;
    if (user != null && user.isAdmin) {
      return const [
        _Tab('Prices', Icons.show_chart, PriceListScreen()),
        _Tab('Profile', Icons.person, ProfileScreen()),
      ];
    }
    if (user != null && user.isBuyer) {
      return const [
        _Tab('Market', Icons.storefront, MarketplaceScreen()),
        _Tab('Following', Icons.favorite, FollowingScreen()),
        _Tab('Requests', Icons.assignment, MyRequestsScreen()),
        _Tab('Messages', Icons.chat_bubble, InboxScreen()),
        _Tab('Profile', Icons.person, ProfileScreen()),
      ];
    }
    return const [
      _Tab('My Crops', Icons.grass, MyCropsScreen()),
      _Tab('Demand', Icons.assignment, BuyerDemandScreen()),
      _Tab('Prices', Icons.show_chart, PriceListScreen()),
      _Tab('Messages', Icons.chat_bubble, InboxScreen()),
      _Tab('Profile', Icons.person, ProfileScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabsForRole();
    return Scaffold(
      // IndexedStack keeps every tab alive, so switching tabs doesn't reload
      // the list or lose the scroll position.
      body: IndexedStack(
        index: _selectedIndex,
        children: [for (final tab in tabs) tab.page],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
