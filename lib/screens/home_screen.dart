import 'dart:ui' as ui;
import '../services/ui_prefs.dart';
import 'more_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/fancy_nav_bar.dart';
import '../widgets/anim.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../services/games_list.dart';
import 'settings_screen.dart';
import 'add_listing_screen.dart';
import 'wallet_screen.dart';
import 'listing_detail_screen.dart';
import 'notifications_screen.dart';
import 'banned_screen.dart';
import 'login_screen.dart';
import '../services/auth_helper.dart';
import '../services/update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _isLoggedIn = true;
  int _unreadCount = 0;

  final List<Widget> _pages = const [
    _HomeTab(),
    MoreScreen(),
    AddListingScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeIfPending());
    UiPrefs.load();
    if (kIsWeb) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        // if (mounted) _showDownloadAppPrompt();
      });
    }
    _checkLoginStatus();
    _loadUnreadCount();
    if (kIsWeb == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => UpdateService.checkForUpdate(context));
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  void _onTabSelected(int i) {
    setState(() => _tab = i);
    if (i == 3) {
      // opened Alerts — clear the badge, then re-check shortly after in case it wasn't fully read
      setState(() => _unreadCount = 0);
      Future.delayed(const Duration(seconds: 2), _loadUnreadCount);
    } else {
      _loadUnreadCount();
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    if (mounted) setState(() => _isLoggedIn = loggedIn);
  }

  Future<void> _showWelcomeIfPending() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('pending_welcome_name');
    if (name == null || name.isEmpty) return;
    final isNew = prefs.getBool('pending_welcome_is_new') ?? false;
    final viaGoogle = prefs.getBool('pending_welcome_via_google') ?? false;
    await prefs.remove('pending_welcome_name');
    await prefs.remove('pending_welcome_is_new');
    await prefs.remove('pending_welcome_via_google');
    if (!mounted) return;
    final message = isNew ? 'Welcome, $name!' : 'Welcome back, $name!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
    if (isNew && viaGoogle) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A password has been sent to your Gmail — you can use it to log in with email & password too.'),
            duration: Duration(seconds: 5),
          ),
        );
      });
    }
  }

  void _showDownloadAppPrompt() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Get the App', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Get a faster, smoother experience with the MYGame Marketplace Android app.',
          style: TextStyle(color: AppColors.hint, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Not now')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(
                Uri.parse('https://buysellgame.store/downloads/app-release.apk'),
                mode: LaunchMode.externalApplication,
                webOnlyWindowName: '_blank',
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: UiPrefs.glassNav,
          builder: (context, glass, _) => Scaffold(
          extendBody: glass,
          backgroundColor: AppColors.bg,
          body: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: KeyedSubtree(key: ValueKey<int>(_tab), child: _pages[_tab])),
          bottomNavigationBar: FancyNavBar(
            selectedIndex: _tab,
            onSelected: _onTabSelected,
            centerIndex: 2,
            items: [
              FancyNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: AppLocalizations.t('home')),
              FancyNavItem(icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: AppLocalizations.t('more')),
              FancyNavItem(icon: Icons.sell_outlined, selectedIcon: Icons.sell, label: AppLocalizations.t('sell')),
              FancyNavItem(icon: Icons.notifications_outlined, selectedIcon: Icons.notifications_rounded, label: AppLocalizations.t('alerts'), showBadge: _unreadCount > 0),
              FancyNavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: AppLocalizations.t('settings')),
            ],
          ),
        ));
      },
    );
  }
}

Future<bool> handleBannedError(BuildContext context, Object error) async {
  final errorStr = error.toString();
  if (errorStr.contains('BANNED:')) {
    final reason = errorStr.split('BANNED:').last.replaceFirst('Exception: ', '');
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => BannedScreen(reason: reason)),
        (route) => false,
      );
    }
    return true;
  }
  return false;
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String? _selectedGame;
  String _sort = 'newest';
  List<dynamic> _listings = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;
  Map<String, dynamic>? _profile;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final Map<String, String> _sortLabels = {
    'newest': 'Newest',
    'price_low': 'Price: Low to High',
    'price_high': 'Price: High to Low',
  };

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadUnreadCount();
    _loadProfile();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) await handleBannedError(context, e);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadListings();
    });
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await ApiService.getListings(
        game: _selectedGame,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _sort,
      );
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final wasBanned = await handleBannedError(context, e);
      if (wasBanned) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sort By', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            ..._sortLabels.entries.map((e) => ListTile(
                  title: Text(e.value, style: const TextStyle(color: Colors.white)),
                  trailing: _sort == e.key ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() => _sort = e.key);
                    Navigator.pop(ctx);
                    _loadListings();
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showGameFilterSheet() {
    final searchCtrl = TextEditingController();
    List<String> filtered = List.from(GamesList.games);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                const Text('Filter by Game', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search games...',
                    prefixIcon: Icon(Icons.search, color: AppColors.hint),
                  ),
                  onChanged: (v) {
                    setModalState(() {
                      filtered = GamesList.games.where((g) => g.toLowerCase().contains(v.toLowerCase())).toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        title: const Text('All Games', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        trailing: _selectedGame == null ? const Icon(Icons.check, color: AppColors.primary) : null,
                        onTap: () {
                          setState(() => _selectedGame = null);
                          Navigator.pop(ctx);
                          _loadListings();
                        },
                      ),
                      const Divider(color: AppColors.border),
                      ...filtered.map((g) => ListTile(
                            title: Text(g, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            trailing: _selectedGame == g ? const Icon(Icons.check, color: AppColors.primary) : null,
                            onTap: () {
                              setState(() => _selectedGame = g);
                              Navigator.pop(ctx);
                              _loadListings();
                            },
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: const Text('Marketplace',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.t('search_accounts'),
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.hint),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: const Icon(Icons.search, color: AppColors.hint, size: 20),
                      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 36),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: AppColors.hint, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadListings();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showSortSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.65)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: _showGameFilterSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedGame != null ? AppColors.primary.withOpacity(0.15) : AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _selectedGame != null ? AppColors.primary : AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videogame_asset_outlined, size: 16, color: _selectedGame != null ? AppColors.primary : AppColors.hint),
                    const SizedBox(width: 6),
                    Text(
                      _selectedGame ?? 'All Games',
                      style: TextStyle(color: _selectedGame != null ? Colors.white : AppColors.hint, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 18, color: _selectedGame != null ? AppColors.primary : AppColors.hint),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _listings.isEmpty
                        ? const Center(child: Text('No listings yet', style: TextStyle(color: AppColors.hint)))
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _loadListings();
                              await _loadUnreadCount();
                            },
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _listings.length,
                              itemBuilder: (context, i) {
                                final l = _listings[i];
                                final screenshots = (l['screenshots'] as List?) ?? [];
                                final allowBidding = l['allowBidding'] == true;
                                final highestBid = l['highestBid'] != null ? (l['highestBid'] as num).toDouble() : null;
                                final displayPrice = highestBid ?? (l['price'] as num).toDouble();
                                final saleType = l['saleType'] ?? 'full';
                                final isBoosted = l['boosted'] == true;
                                final sellerName = l['sellerDisplayName'] ?? '';
                                final priceLine = saleType == 'rental'
                                    ? '${l['game'] ?? ''} · Rental · LKR ${(l['rentalPricePerUnit'] as num? ?? displayPrice).toStringAsFixed(0)}/${l['rentalUnit'] ?? 'day'}'
                                    : saleType == 'installment'
                                        ? '${l['game'] ?? ''} · Installment · LKR ${displayPrice.toStringAsFixed(0)} total'
                                        : '${l['game'] ?? ''} · LKR ${displayPrice.toStringAsFixed(0)}${allowBidding ? ' (bidding)' : ''}';
                                return FadeSlideIn(delay: staggerDelay(i), child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: isBoosted ? Colors.amber.withOpacity(0.5) : AppColors.border),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: l['id'])),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 10,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                screenshots.isNotEmpty
                                                    ? Image.network(
                                                        screenshots[0],
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => Container(
                                                          color: AppColors.fieldFill,
                                                          child: const Icon(Icons.broken_image_outlined, color: AppColors.hint, size: 36),
                                                        ),
                                                      )
                                                    : Container(
                                                        color: AppColors.fieldFill,
                                                        child: const Icon(Icons.image_outlined, color: AppColors.hint, size: 40),
                                                      ),
                                                if (isBoosted)
                                                  Positioned(
                                                    top: 8,
                                                    left: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.bolt, size: 12, color: Colors.black),
                                                          SizedBox(width: 2),
                                                          Text('Boosted', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                if (allowBidding)
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(5),
                                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                                      child: const Icon(Icons.gavel_outlined, size: 14, color: Colors.white),
                                                    ),
                                                  ),
                                                if (screenshots.length > 1)
                                                  Positioned(
                                                    bottom: 8,
                                                    right: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                                                          const SizedBox(width: 3),
                                                          Text('${screenshots.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l['title'] ?? '',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  priceLine,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: AppColors.hint, fontSize: 12),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person_outline, size: 11, color: AppColors.hint),
                                                    const SizedBox(width: 3),
                                                    Flexible(
                                                      child: Text('by $sellerName',
                                                          style: const TextStyle(color: AppColors.hint, fontSize: 11),
                                                          overflow: TextOverflow.ellipsis),
                                                    ),
                                                    if (l['sellerVerified'] == true) ...[
                                                      const SizedBox(width: 3),
                                                      const Icon(Icons.verified, size: 12, color: AppColors.primary),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ));
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class PromotionsTab extends StatefulWidget {
  const PromotionsTab();

  @override
  State<PromotionsTab> createState() => _PromotionsTabState();
}

class _PromotionsTabState extends State<PromotionsTab> {
  List<dynamic> _promotions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final promotions = await ApiService.getPromotions();
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(AppLocalizations.t('promotions_tab'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                        : _promotions.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(AppLocalizations.t('no_promotions'),
                                      textAlign: TextAlign.center, style: const TextStyle(color: AppColors.hint)),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _load,
                                color: AppColors.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _promotions.length,
                                  itemBuilder: (context, i) {
                                    final p = _promotions[i];
                                    return FadeSlideIn(delay: staggerDelay(i), child: InkWell(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PromotionDetailScreen(promotion: p))),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AspectRatio(
                                              aspectRatio: 16 / 9,
                                              child: Image.network(
                                                p['imageUrl'] ?? '',
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, stack) => Container(
                                                  color: AppColors.fieldFill,
                                                  child: const Icon(Icons.image_outlined, color: AppColors.hint, size: 40),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(p['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                  if ((p['description'] ?? '').toString().isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Text(p['description'], style: const TextStyle(color: AppColors.hint, fontSize: 13)),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ));
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PromotionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> promotion;
  const PromotionDetailScreen({super.key, required this.promotion});

  Future<void> _openLink(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = (promotion['linkUrl'] ?? '').toString().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Event')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                promotion['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: AppColors.fieldFill,
                  child: const Icon(Icons.image_outlined, color: AppColors.hint, size: 60),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promotion['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  if ((promotion['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(promotion['description'], style: const TextStyle(color: AppColors.hint, fontSize: 15, height: 1.5)),
                  ],
                  if (hasLink) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _openLink(context, promotion['linkUrl']),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('View More'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ---------- glass bottom bar + new Sell icon ----------
class _GlassNavBar extends StatelessWidget {
  final bool glass;
  final Widget child;
  const _GlassNavBar({required this.glass, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!glass) return child;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.06)],
            ),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.28), width: 1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SellIcon extends StatelessWidget {
  final bool selected;
  const _SellIcon({required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c, Color.lerp(c, Colors.pinkAccent, 0.6)!])
            : null,
        color: selected ? null : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? Colors.white.withValues(alpha: 0.5) : c.withValues(alpha: 0.7), width: 1.5),
        boxShadow: selected ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 12)] : null,
      ),
      child: Icon(Icons.sell_rounded, size: 19, color: selected ? Colors.white : c),
    );
  }
}
