// The main screen after login. It shows the tabs of the user's role and
// adapts to the screen size:
// - phone (under 600 px): green top bar with the logo, tabs at the bottom
// - tablet (600-999 px): a narrow menu on the left with icons and labels
// - laptop (1000 px and up): a full sidebar with the logo, labeled tabs
//   with counts, and the user's name with Profile and Log out
// Pages can switch tabs through HomeNav (e.g. a dashboard's "See all").

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/home_nav.dart';
import 'following_screen.dart';
import 'inbox_screen.dart';
import 'marketplace_screen.dart';
import 'my_crops_screen.dart';
import 'orders_screen.dart';
import 'price_list_screen.dart';
import 'profile_screen.dart';

/// One tab: which one it is, its label, icons and page.
class _Tab {
  const _Tab(
    this.id,
    this.label,
    this.icon,
    this.selectedIcon,
    this.page, {
    this.onPhoneBar = true,
  });

  final HomeTab id;
  final String label;
  final IconData icon; // outline icon when the tab is not selected
  final IconData selectedIcon; // filled icon when it is selected
  final Widget page;

  /// False for a tab left out of the phone's bottom bar (it holds at most
  /// 5). It is still opened from a Home tile or link.
  final bool onPhoneBar;
}

/// Tabs for each role, with Profile and Log out in the sidebar or top bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<_Tab> _tabs = _tabsForRole(AuthService.currentUser);

  /// Picks the tabs for the logged-in user's role (same order as the website).
  static List<_Tab> _tabsForRole(AppUser? user) {
    if (user != null && user.isAdmin) {
      return const [
        _Tab(
          HomeTab.prices,
          'Prices',
          Icons.trending_up,
          Icons.trending_up,
          PriceListScreen(),
        ),
      ];
    }
    if (user != null && user.isBuyer) {
      return const [
        _Tab(
          HomeTab.home,
          'Home',
          Icons.home_outlined,
          Icons.home,
          _EmptyTab('Home'),
        ),
        _Tab(
          HomeTab.market,
          'Market',
          Icons.storefront_outlined,
          Icons.storefront,
          MarketplaceScreen(),
        ),
        // On phones it is opened from Home ("All prices"), so the bottom bar
        // keeps 5 tabs.
        _Tab(
          HomeTab.prices,
          'Prices',
          Icons.trending_up,
          Icons.trending_up,
          PriceListScreen(),
          onPhoneBar: false,
        ),
        _Tab(
          HomeTab.requests,
          'Requests',
          Icons.assignment_outlined,
          Icons.assignment,
          _EmptyTab('Requests'),
        ),
        _Tab(
          HomeTab.orders,
          'Orders',
          Icons.receipt_long_outlined,
          Icons.receipt_long,
          OrdersScreen(),
        ),
        // On phones it is opened from the Home tile "Crops and farmers you
        // follow", so the bottom bar keeps 5 tabs.
        _Tab(
          HomeTab.following,
          'Following',
          Icons.favorite_border,
          Icons.favorite,
          FollowingScreen(),
          onPhoneBar: false,
        ),
        _Tab(
          HomeTab.messages,
          'Messages',
          Icons.chat_bubble_outline,
          Icons.chat_bubble,
          InboxScreen(),
        ),
      ];
    }
    return const [
      _Tab(
        HomeTab.home,
        'Home',
        Icons.home_outlined,
        Icons.home,
        _EmptyTab('Home'),
      ),
      // On phones it is opened from Home ("All prices"), so the bottom bar
      // keeps 5 tabs.
      _Tab(
        HomeTab.prices,
        'Prices',
        Icons.trending_up,
        Icons.trending_up,
        PriceListScreen(),
        onPhoneBar: false,
      ),
      _Tab(
        HomeTab.myCrops,
        'My Crops',
        Icons.grass_outlined,
        Icons.grass,
        MyCropsScreen(),
      ),
      _Tab(
        HomeTab.orders,
        'Orders',
        Icons.receipt_long_outlined,
        Icons.receipt_long,
        OrdersScreen(),
      ),
      _Tab(
        HomeTab.demand,
        'Demand',
        Icons.campaign_outlined,
        Icons.campaign,
        _EmptyTab('Demand'),
      ),
      _Tab(
        HomeTab.messages,
        'Messages',
        Icons.chat_bubble_outline,
        Icons.chat_bubble,
        InboxScreen(),
      ),
    ];
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
  }

  /// Opens [tab] if this role has it (used by HomeNav).
  void _openTab(HomeTab tab) {
    final index = _tabs.indexWhere((t) => t.id == tab);
    if (index >= 0) _select(index);
  }

  /// Opens the profile; redraws afterwards so the sidebar shows any new
  /// name or town right away.
  Future<void> _openProfile() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;
    final width = MediaQuery.sizeOf(context).width;
    // IndexedStack keeps every tab alive, so switching tabs doesn't reload
    // the list or lose the scroll position.
    final pages = HomeNav(
      open: _openTab,
      child: IndexedStack(
        index: _selectedIndex,
        children: [for (final tab in _tabs) tab.page],
      ),
    );

    if (width >= AppSizes.desktopBreakpoint) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(
              items: [
                for (final tab in _tabs)
                  SidebarItem(
                    label: tab.label,
                    icon: tab.icon,
                    selectedIcon: tab.selectedIcon,
                  ),
              ],
              selectedIndex: _selectedIndex,
              onSelect: _select,
              user: user,
              onProfile: _openProfile,
              onLogOut: () => confirmAndLogOut(context),
            ),
            Expanded(child: pages),
          ],
        ),
      );
    }

    final appBar = BrandAppBar(
      actions: [
        IconButton(
          tooltip: 'Profile',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: _openProfile,
        ),
      ],
    );

    // The admin has only one tab, so no tab bar is needed.
    if (_tabs.length < 2) return Scaffold(appBar: appBar, body: pages);

    if (width >= AppSizes.wideBreakpoint) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final tab in _tabs)
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

    // The phone's bottom bar shows at most 5 tabs; a tab that is not on it
    // (e.g. Prices, opened from Home) keeps Home highlighted.
    final barTabs = _tabs.where((t) => t.onPhoneBar).toList();
    final barIndex = barTabs.indexOf(_tabs[_selectedIndex]);
    return Scaffold(
      appBar: appBar,
      body: pages,
      bottomNavigationBar: DecoratedBox(
        // Thin line above the tabs, like the website.
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: barIndex < 0 ? 0 : barIndex,
          onDestinationSelected: (i) => _select(_tabs.indexOf(barTabs[i])),
          destinations: [
            for (final tab in barTabs)
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

/// A tab whose page is not built yet: a construction icon and its name.
/// Each progress stage swaps one of these for the real screen.
class _EmptyTab extends StatelessWidget {
  const _EmptyTab(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.construction_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          const Text('Coming soon', style: AppTextStyles.meta),
        ],
      ),
    );
  }
}
