import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';
import 'add_listing_screen.dart';
import 'wallet_screen.dart';

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
    _PlaceholderTab(title: 'Chats'),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: 'Sell'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final categories = ['PUBG', 'Free Fire', 'CODM', 'MLBB'];
  String? _selectedGame;
  List<dynamic> _listings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await ApiService.getListings(game: _selectedGame);
      setState(() {
        _listings = listings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('MYGame Marketplace',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: const Icon(Icons.search, color: AppColors.hint),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: categories.map((c) {
                final selected = c == _selectedGame;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c, style: TextStyle(color: selected ? Colors.white : AppColors.hint)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedGame = selected ? null : c);
                      _loadListings();
                    },
                    backgroundColor: AppColors.fieldFill,
                    selectedColor: AppColors.primary.withOpacity(0.3),
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _listings.isEmpty
                        ? const Center(child: Text('No listings yet', style: TextStyle(color: AppColors.hint)))
                        : RefreshIndicator(
                            onRefresh: _loadListings,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _listings.length,
                              itemBuilder: (context, i) {
                                final l = _listings[i];
                                final screenshots = (l['screenshots'] as List?) ?? [];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(10),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: screenshots.isNotEmpty
                                          ? Image.network(screenshots[0], width: 56, height: 56, fit: BoxFit.cover)
                                          : Container(
                                              width: 56, height: 56, color: AppColors.fieldFill,
                                              child: const Icon(Icons.image_outlined, color: AppColors.hint),
                                            ),
                                    ),
                                    title: Text(l['title'] ?? '', style: const TextStyle(color: Colors.white)),
                                    subtitle: Text('${l['game'] ?? ''} · LKR ${l['price'] ?? 0}',
                                        style: const TextStyle(color: AppColors.hint, fontSize: 12)),
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

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$title screen — build next', style: const TextStyle(color: AppColors.hint)));
  }
}
