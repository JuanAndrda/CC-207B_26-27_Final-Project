// The main screen after login. Like the website: a green top bar with the
// logo, and tabs that depend on the user's role. On a phone the tabs are at
// the bottom; on a wide screen (tablet, laptop) they become a side menu.

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/responsive_body.dart';
import 'buyer_demand_screen.dart';
import 'following_screen.dart';
import 'inbox_screen.dart';
import 'marketplace_screen.dart';
import 'my_crops_screen.dart';
import 'my_requests_screen.dart';
import 'price_list_screen.dart';
import 'profile_screen.dart';

/// One tab: its label, icons and page.
class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.page);

  final String label;
  final IconData icon; // outline icon when the tab is not selected
  final IconData selectedIcon; // filled icon when it is selected
  final Widget page;
}

/// Tabs for each role, with the profile behind the top-right button.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  /// Picks the tabs for the logged-in user's role (same order as the website).
  List<_Tab> _tabsForRole() {
    final user = AuthService.currentUser;
    if (user != null && user.isAdmin) {
      return const [
        _Tab('Prices', Icons.trending_up, Icons.trending_up, PriceListScreen()),
      ];
    }
    if (user != null && user.isBuyer) {
      return const [
        _Tab(
          'Market',
          Icons.storefront_outlined,
          Icons.storefront,
          MarketplaceScreen(),
        ),
        _Tab(
          'Requests',
          Icons.assignment_outlined,
          Icons.assignment,
          MyRequestsScreen(),
        ),
        _Tab(
          'Following',
          Icons.favorite_border,
          Icons.favorite,
          FollowingScreen(),
        ),
        _Tab(
          'Messages',
          Icons.chat_bubble_outline,
          Icons.chat_bubble,
          InboxScreen(),
        ),
      ];
    }
    return const [
      _Tab('Prices', Icons.trending_up, Icons.trending_up, PriceListScreen()),
      _Tab('My Crops', Icons.grass_outlined, Icons.grass, MyCropsScreen()),
      _Tab(
        'Demand',
        Icons.campaign_outlined,
        Icons.campaign,
        BuyerDemandScreen(),
      ),
      _Tab(
        'Messages',
        Icons.chat_bubble_outline,
        Icons.chat_bubble,
        InboxScreen(),
      ),
    ];
  }

  void _openProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final tabs = _tabsForRole();
    final appBar = BrandAppBar(
      actions: [
        IconButton(
          tooltip: 'Profile',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: _openProfile,
        ),
      ],
    );
    // IndexedStack keeps every tab alive, so switching tabs doesn't reload
    // the list or lose the scroll position.
    final pages = IndexedStack(
      index: _selectedIndex,
      children: [for (final tab in tabs) tab.page],
    );

    // The admin has only one tab, so no tab bar is needed.
    if (tabs.length < 2) return Scaffold(appBar: appBar, body: pages);

    if (isWideScreen(context)) {
      // Very wide screens show the labels next to the icons.
      final extended = MediaQuery.sizeOf(context).width >= 1000;
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              extended: extended,
              minExtendedWidth: 220,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final tab in tabs)
                  NavigationRailDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: Text(tab.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: pages,
      bottomNavigationBar: DecoratedBox(
        // Thin line above the tabs, like the website.
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final tab in tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
