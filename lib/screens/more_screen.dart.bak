import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tournaments_screen.dart';
import 'ff_dpi_sensi_screen.dart';
import '../services/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart' show PromotionsTab;

const List<Map<String, dynamic>> _defaultTools = [
  {'key': 'ff_info', 'title': 'Free Fire Info Check', 'subtitle': 'Check any account by UID', 'icon': 'sports_esports'},
  {'key': 'tournaments', 'title': 'Tournaments', 'subtitle': 'Compete and win prizes', 'icon': 'emoji_events'},
  {'key': 'ff_dpi_sensi', 'title': 'Free Fire DPI & Sensi', 'subtitle': 'Best settings for your phone', 'icon': 'tune'},
  {'key': 'events', 'title': 'Events', 'subtitle': 'Promotions and offers', 'icon': 'campaign'},
];

const Map<String, dynamic> _eventsTool = {'key': 'events', 'title': 'Events', 'subtitle': 'Promotions and offers', 'icon': 'campaign'};


const String _ffImage = 'assets/images/ff_info.jpg';
const String _tourneyImage = 'assets/images/tournaments.jpg';
const String _eventsImage = 'assets/images/events.jpg';

const Map<String, String> _toolImages = {
  'ff_info': _ffImage,
  'tournaments': _tourneyImage,
  'events': _eventsImage,
};

Widget _ffBanner({double? height, String asset = _ffImage}) {
  return Image.asset(
    asset,
    fit: BoxFit.cover,
    height: height,
    width: double.infinity,
    errorBuilder: (_, __, ___) => Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)]),
      ),
      child: const Center(child: Icon(Icons.sports_esports, size: 56, color: Colors.white70)),
    ),
  );
}

Widget _photoOverlay(String title, String caption, {String asset = _ffImage}) {
  return Stack(
    fit: StackFit.expand,
    children: [
      _ffBanner(asset: asset),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xCC000000)],
          ),
        ),
      ),
      Positioned(
        left: 12,
        right: 12,
        bottom: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            Text(caption, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    ],
  );
}

IconData _iconFor(String? name) {
  switch (name) {
    case 'sports_esports':
      return Icons.sports_esports;
    case 'diamond':
      return Icons.diamond;
    case 'search':
      return Icons.search;
    case 'emoji_events':
      return Icons.emoji_events;
    case 'tune':
      return Icons.tune;
    case 'shield':
      return Icons.shield;
    case 'star':
      return Icons.star;
    case 'campaign':
      return Icons.campaign;
    default:
      return Icons.apps;
  }
}

List<Color> _gradientFor(String? key) {
  switch (key) {
    case 'ff_info':
      return const [Color(0xFF7B2FF7), Color(0xFFF107A3)];
    case 'tournaments':
      return const [Color(0xFFFFB300), Color(0xFFE65100)];
    case 'ff_dpi_sensi':
      return const [Color(0xFF00C6FF), Color(0xFF0072FF)];
    case 'events':
      return const [Color(0xFF6C4CF1), Color(0xFFF107A3)];
    default:
      return const [Color(0xFF3A3A55), Color(0xFF1E1E30)];
  }
}

Widget _toolBox({
  required String title,
  required String subtitle,
  required IconData icon,
  required List<Color> gradient,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
            ),
          ),
          Positioned(right: -10, top: -10, child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.12))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, size: 28, color: Colors.white),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _photoToolBox({
  required String title,
  required String subtitle,
  required IconData icon,
  required String asset,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ffBanner(asset: asset),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  List<dynamic> _tools = _defaultTools;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getMoreTools();
      // the Events box is always shown, even when the server list does not include it
      final tools = List<dynamic>.from(list);
      if (!tools.any((t) => t is Map && t['key'] == 'events')) tools.add(_eventsTool);
      if (mounted) setState(() => _tools = tools);
    } catch (_) {
      // backend route not ready or offline: show default tools
      if (mounted) setState(() => _tools = _defaultTools);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Map t) {
    final link = '${t['linkUrl'] ?? ''}';
    if (link.isNotEmpty) {
      launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } else if (t['key'] == 'ff_dpi_sensi') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FfDpiSensiScreen()));
    } else if (t['key'] == 'tournaments') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsScreen()));
    } else if (t['key'] == 'ff_info') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FfInfoScreen()));
    } else if (t['key'] == 'events') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tools.isEmpty
              ? const Center(child: Text('No tools available'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ValueListenableBuilder<String>(
                    valueListenable: AppLocalizations.currentLanguage,
                    builder: (context, lang, _) => GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: _tools.length,
                    itemBuilder: (_, i) {
                      final t = _tools[i] as Map;
                      final key = t['key']?.toString();

                      final subtitle = key == 'ff_dpi_sensi'
                          ? AppLocalizations.t('ff_dpi_sensi_subtitle')
                          : (t['subtitle'] ?? '').toString().isNotEmpty
                              ? '${t['subtitle']}'
                              : key == 'tournaments'
                                  ? 'Compete and win prizes'
                                  : key == 'ff_info'
                                          ? 'Get your information'
                                          : key == 'events'
                                              ? 'Promotions and offers'
                                              : '';

                      final title = key == 'ff_dpi_sensi'
                          ? AppLocalizations.t('ff_dpi_sensi_title')
                          : '${t['title'] ?? ''}';

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 350 + (i * 80)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 20),
                            child: child,
                          ),
                        ),
                        child: _toolImages.containsKey(key)
                            ? _photoToolBox(
                                title: title,
                                subtitle: subtitle,
                                icon: _iconFor(t['icon']?.toString()),
                                asset: _toolImages[key]!,
                                onTap: () => _open(t),
                              )
                            : _toolBox(
                                title: title,
                                subtitle: subtitle,
                                icon: _iconFor(t['icon']?.toString()),
                                gradient: _gradientFor(key),
                                onTap: () => _open(t),
                              ),
                      );
                    },
                  ),
                  ),
                ),
    );
  }
}

// ======================= FREE FIRE INFO CHECK =======================

class FfInfoScreen extends StatefulWidget {
  const FfInfoScreen({super.key});

  @override
  State<FfInfoScreen> createState() => _FfInfoScreenState();
}

class _FfInfoScreenState extends State<FfInfoScreen> {
  static const _regions = ['sg', 'ind', 'bd', 'pk', 'id', 'th', 'vn', 'br', 'me', 'na', 'sac', 'tw', 'cis'];

  final _uidCtrl = TextEditingController();
  final _cardKey = GlobalKey();
  String _region = 'sg';
  bool _loading = false;
  bool _saving = false;
  String? _error;
  Map? _info;
  int? _remaining;

  @override
  void dispose() {
    _uidCtrl.dispose();
    super.dispose();
  }

  Future<void> _askLogin() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login required'),
        content: const Text('Please login to use this tool.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Login')),
        ],
      ),
    );
    if (go == true && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('is_logged_in') ?? false)) {
      await _askLogin();
      return;
    }
    final uid = _uidCtrl.text.trim();
    if (!RegExp(r'^\d{5,15}$').hasMatch(uid)) {
      setState(() => _error = 'Enter a valid Free Fire UID (numbers only)');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.ffInfoCheck(uid, _region);
      if (!mounted) return;
      setState(() {
        _info = data['info'] as Map?;
        _remaining = int.tryParse('${data['remaining'] ?? ''}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _info = null;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download is available in the mobile app')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bd = await image.toByteData(format: ui.ImageByteFormat.png);
      await Gal.putImageBytes(bd!.buffer.asUint8List());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _date(dynamic v) {
    final s = int.tryParse('${v ?? ''}');
    if (s == null || s == 0) return '-';
    final d = DateTime.fromMillisecondsSinceEpoch(s * 1000);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget _row(String k, dynamic v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Color(0xFF9AA0B4), fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text('${v ?? '-'}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _card() {
    final info = _info!;
    final b = (info['basicInfo'] as Map?) ?? {};
    final clan = (info['clanBasicInfo'] as Map?) ?? {};
    final pet = (info['petInfo'] as Map?) ?? {};
    final credit = (info['creditScoreInfo'] as Map?) ?? {};
    final social = (info['socialInfo'] as Map?) ?? {};
    final prime = (b['primePrivilegeDetail'] as Map?) ?? {};
    final sig = '${social['signature'] ?? ''}'.replaceAll(RegExp(r'\[[^\]]*\]'), '').trim();

    return RepaintBoundary(
      key: _cardKey,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF14172B),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${b['nickname'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('UID ${b['accountId'] ?? ''}  |  ${b['region'] ?? ''}', style: const TextStyle(color: Color(0xFF9AA0B4), fontSize: 12)),
            if (sig.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(sig, style: const TextStyle(color: Color(0xFFFFBA00), fontSize: 13)),
            ],
            const Divider(color: Color(0xFF2A2E48), height: 24),
            _row('Level', b['level']),
            _row('EXP', b['exp']),
            _row('Likes', b['liked']),
            _row('BR rank points', b['rankingPoints']),
            _row('CS rank points', b['csRankingPoints']),
            _row('Badges', b['badgeCnt']),
            _row('Prime level', prime['primeLevel']),
            _row('Credit score', credit['creditScore']),
            _row('Account created', _date(b['createAt'])),
            _row('Last login', _date(b['lastLoginAt'])),
            _row('Game version', b['releaseVersion']),
            if (clan.isNotEmpty) ...[
              const Divider(color: Color(0xFF2A2E48), height: 24),
              _row('Guild', clan['clanName']),
              _row('Guild level', clan['clanLevel']),
              _row('Members', '${clan['memberNum'] ?? '-'} / ${clan['capacity'] ?? '-'}'),
            ],
            if (pet.isNotEmpty) ...[
              const Divider(color: Color(0xFF2A2E48), height: 24),
              _row('Pet level', pet['level']),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Free Fire Info Check')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(aspectRatio: 2, child: _photoOverlay('Free Fire Info Check', 'Get your information')),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _uidCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Free Fire UID', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _region,
            decoration: const InputDecoration(labelText: 'Region', border: OutlineInputBorder()),
            items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _region = v ?? 'sg'),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loading ? null : _check,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
            label: Text(_loading ? 'Checking...' : 'Check'),
          ),
          if (_remaining != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Checks left today: $_remaining', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          if (_info != null) ...[
            const SizedBox(height: 18),
            _card(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _download,
              icon: const Icon(Icons.download),
              label: Text(_saving ? 'Saving...' : 'Download'),
            ),
          ],
        ],
      ),
    );
  }
}

// ======================= EVENTS (moved from the bottom bar) =======================

Widget _eventsBox(VoidCallback onTap) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: const [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C4CF1), Color(0xFFF107A3)],
              ),
            ),
          ),
          Center(child: Icon(Icons.campaign, size: 64, color: Colors.white24)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Events', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                SizedBox(height: 2),
                Text('Promotions and offers', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: const PromotionsTab());
  }
}
