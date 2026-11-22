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
import '../services/listing_service.dart';
import '../services/request_service.dart';
import '../utils/theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/home_nav.dart';
import 'buyer_demand_screen.dart';
import 'buyer_home_screen.dart';
import 'farmer_home_screen.dart';
import 'following_screen.dart';
import 'inbox_screen.dart';
import 'marketplace_screen.dart';
import 'my_crops_screen.dart';
import 'my_requests_screen.dart';
import 'price_list_screen.dart';
import 'profile_screen.dart';

/// One tab: which one it is, its label, icons and page.
class _Tab {
  const _Tab(this.id, this.label, this.icon, this.selectedIcon, this.page);

  final HomeTab id;
  final String label;
  final IconData icon; // outline icon when the tab is not selected
  final IconData selectedIcon; // filled icon when it is selected
  final Widget page;
}

/// Tabs for each role, with Profile and Log out in the sidebar or top bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  /// Small numbers next to some tabs (e.g. open buyer requests).
  final Map<HomeTab, int> _counts = {};

  late final List<_Tab> _tabs = _tabsForRole(AuthService.currentUser);

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

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
          BuyerHomeScreen(),
        ),
        _Tab(
          HomeTab.market,
          'Market',
          Icons.storefront_outlined,
          Icons.storefront,
          MarketplaceScreen(),
        ),
        _Tab(
          HomeTab.requests,
          'Requests',
          Icons.assignment_outlined,
          Icons.assignment,
          MyRequestsScreen(),
        ),
        _Tab(
          HomeTab.following,
          'Following',
          Icons.favorite_border,
          Icons.favorite,
          FollowingScreen(),
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
        FarmerHomeScreen(),
      ),
      _Tab(
        HomeTab.prices,
        'Prices',
        Icons.trending_up,
        Icons.trending_up,
        PriceListScreen(),
      ),
      _Tab(
        HomeTab.myCrops,
        'My Crops',
        Icons.grass_outlined,
        Icons.grass,
        MyCropsScreen(),
      ),
      _Tab(
        HomeTab.demand,
        'Demand',
        Icons.campaign_outlined,
        Icons.campaign,
        BuyerDemandScreen(),
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

  /// Counts for the tab badges. If loading fails, the badges just stay
  /// hidden; the pages themselves show their own errors.
  Future<void> _loadCounts() async {
    final me = AuthService.currentUser;
    if (me == null) return;
    try {
      if (me.isFarmer) {
        final results = await Future.wait([
          ListingService().fetchByFarmer(me.id),
          RequestService().fetchOpen(),
        ]);
        final myCrops = {
          for (final l in results[0] as List)
            if (l.isActive as bool) l.crop,
        };
        final demand = (results[1] as List)
            .where((r) => myCrops.contains(r.crop))
            .length;
        if (mounted) setState(() => _counts[HomeTab.demand] = demand);
      } else if (me.isBuyer) {
        final mine = await RequestService().fetchByBuyer(me.id);
        final open = mine.where((r) => !r.isClosed).length;
        if (mounted) setState(() => _counts[HomeTab.requests] = open);
      }
    } catch (_) {}
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
    _loadCounts(); // keep the badges fresh
  }

  /// Opens [tab] if this role has it (used by HomeNav).
  void _openTab(HomeTab tab) {
    final index = _tabs.indexWhere((t) => t.id == tab);
    if (index >= 0) _select(index);
  }

  void _openProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
                    count: _counts[tab.id],
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
                    icon: _withBadge(tab, Icon(tab.icon)),
                    selectedIcon: _withBadge(tab, Icon(tab.selectedIcon)),
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
            for (final tab in _tabs)
              NavigationDestination(
                icon: _withBadge(tab, Icon(tab.icon)),
                selectedIcon: _withBadge(tab, Icon(tab.selectedIcon)),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }

  /// Adds the orange count to a tab icon when there is one.
  Widget _withBadge(_Tab tab, Widget icon) {
    final count = _counts[tab.id] ?? 0;
    if (count == 0) return icon;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.accent,
      textColor: AppColors.accentInk,
      child: icon,
    );
  }
}
