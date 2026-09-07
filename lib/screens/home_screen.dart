import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../services/games_list.dart';
import 'settings_screen.dart';
import 'add_listing_screen.dart';
import 'wallet_screen.dart';
import 'listing_detail_screen.dart';
import 'chat_conversation_screen.dart';
import 'notifications_screen.dart';
import 'banned_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final List<Widget> _pages = const [
    _HomeTab(),
    WalletScreen(),
    AddListingScreen(),
    _ChatsTab(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: _pages[_tab],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: AppLocalizations.t('home')),
              NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet), label: AppLocalizations.t('wallet')),
              NavigationDestination(icon: const Icon(Icons.add_box_outlined), selectedIcon: const Icon(Icons.add_box), label: AppLocalizations.t('sell')),
              NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: AppLocalizations.t('chats')),
              NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: AppLocalizations.t('settings')),
            ],
          ),
        );
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
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: _profile?['profilePhotoUrl'] != null ? NetworkImage(_profile!['profilePhotoUrl']) : null,
                  child: _profile?['profilePhotoUrl'] == null
                      ? const Icon(Icons.person, size: 18, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(AppLocalizations.t('app_name'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                        _loadUnreadCount();
                      },
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
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
                      prefixIcon: const Icon(Icons.search, color: AppColors.hint),
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
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.sort, color: AppColors.hint, size: 22),
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
                                final isBoosted = l['boosted'] == true;
                                final sellerName = l['sellerDisplayName'] ?? '';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isBoosted ? Colors.amber.withOpacity(0.5) : AppColors.border),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(10),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: l['id'])),
                                      );
                                    },
                                    leading: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: screenshots.isNotEmpty
                                              ? Image.network(screenshots[0], width: 56, height: 56, fit: BoxFit.cover)
                                              : Container(
                                                  width: 56, height: 56, color: AppColors.fieldFill,
                                                  child: const Icon(Icons.image_outlined, color: AppColors.hint),
                                                ),
                                        ),
                                        if (isBoosted)
                                          Positioned(
                                            top: -4, left: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                                              child: const Icon(Icons.bolt, size: 10, color: Colors.black),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(child: Text(l['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                        if (isBoosted) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.bolt, size: 14, color: Colors.amber),
                                        ],
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
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
                                        const SizedBox(height: 2),
                                        Text('${l['game'] ?? ''} · LKR ${displayPrice.toStringAsFixed(0)}${allowBidding ? ' (bidding)' : ''}',
                                            style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                      ],
                                    ),
                                    trailing: allowBidding
                                        ? const Icon(Icons.gavel_outlined, color: AppColors.primary, size: 18)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ChatsTab extends StatefulWidget {
  const _ChatsTab();

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final conversations = await ApiService.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
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

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.parse(isoString).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(AppLocalizations.t('chats'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _conversations.isEmpty
                        ? const Center(child: Text('No conversations yet.\nChats appear after you buy or sell an account.',
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.primary,
                            child: ListView.builder(
                              itemCount: _conversations.length,
                              itemBuilder: (context, i) {
                                final c = _conversations[i];
                                final unread = (c['unreadCount'] as num?)?.toInt() ?? 0;
                                return ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatConversationScreen(
                                          conversationId: c['id'],
                                          otherPartyEmail: c['otherPartyEmail'] ?? '',
                                          listingTitle: c['listingTitle'] ?? '',
                                        ),
                                      ),
                                    ).then((_) => _load());
                                  },
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: c['listingImage'] != null
                                        ? Image.network(c['listingImage'], width: 48, height: 48, fit: BoxFit.cover)
                                        : Container(width: 48, height: 48, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                                  ),
                                  title: Text(c['otherPartyEmail'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(
                                    c['lastMessage'] ?? c['listingTitle'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: unread > 0 ? Colors.white : AppColors.hint, fontSize: 12),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(_timeAgo(c['lastMessageAt']), style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                                      if (unread > 0) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                          child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
