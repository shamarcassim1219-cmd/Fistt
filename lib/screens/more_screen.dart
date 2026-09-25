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

class _MoreItem {
  final String key;
  final String emoji;
  final List<Color> colors;
  final bool soon;
  const _MoreItem(this.key, this.emoji, this.colors, {this.soon = false});
}

const List<_MoreItem> _moreItems = [
  _MoreItem('tournaments', '🏆', [Color(0xFF3A2BB8), Color(0xFF1B1447)]),
  _MoreItem('ff_dpi_sensi', '🎯', [Color(0xFFA3245F), Color(0xFF2A1240)]),
  _MoreItem('game_tools', '🛠️', [Color(0xFF2A3F9E), Color(0xFF101A45)], soon: true),
  _MoreItem('ff_info', '🪪', [Color(0xFF0F8F86), Color(0xFF08262E)]),
  _MoreItem('top_up', '👛', [Color(0xFF9A5A1A), Color(0xFF2B1A12)], soon: true),
  _MoreItem('rewards', '🎁', [Color(0xFF8A2BB0), Color(0xFF22103A)], soon: true),
  _MoreItem('events', '📣', [Color(0xFF6C4CF1), Color(0xFF3A1A6B)]),
];

const Map<String, Map<String, List<String>>> _moreText = {
  'en': {
    'header': ['More', '🎮 Your gaming tools & resources'],
    'soon': ['Coming soon', 'is coming soon!'],
    'tournaments': ['Tournaments', 'Join & win amazing prizes'],
    'ff_dpi_sensi': ['Free Fire DPI & Sensitivity', 'Best settings for better gameplay'],
    'game_tools': ['Game Tools', 'Useful tools for all games'],
    'ff_info': ['UID Checker', 'Check player info instantly'],
    'top_up': ['Top Up', 'Fast & secure top ups'],
    'rewards': ['Rewards', 'Claim your daily rewards'],
    'events': ['Events', 'Promotions and offers'],
  },
  'si': {
    'header': ['තව', '🎮 ඔබේ ගේමින් මෙවලම් සහ සම්පත්'],
    'soon': ['ඉක්මනින් එයි', 'ඉක්මනින් එනවා!'],
    'tournaments': ['තරඟාවලි', 'එකතු වී ත්‍යාග දිනන්න'],
    'ff_dpi_sensi': ['Free Fire DPI සහ සංවේදීතාව', 'වඩා හොඳ ගේම් එකකට හොඳම සැකසුම්'],
    'game_tools': ['ගේම් මෙවලම්', 'සියලු ගේම් සඳහා ප්‍රයෝජනවත් මෙවලම්'],
    'ff_info': ['UID පරීක්ෂකය', 'ක්‍රීඩක තොරතුරු ක්ෂණිකව බලන්න'],
    'top_up': ['ටොප් අප්', 'වේගවත් සහ සුරක්ෂිත ටොප් අප්'],
    'rewards': ['ත්‍යාග', 'ඔබේ දෛනික ත්‍යාග ලබාගන්න'],
    'events': ['සිදුවීම්', 'ප්‍රවර්ධන සහ දීමනා'],
  },
  'ta': {
    'header': ['மேலும்', '🎮 உங்கள் கேமிங் கருவிகள் & வளங்கள்'],
    'soon': ['விரைவில் வருகிறது', 'விரைவில் வருகிறது!'],
    'tournaments': ['போட்டிகள்', 'சேர்ந்து அருமையான பரிசுகளை வெல்லுங்கள்'],
    'ff_dpi_sensi': ['Free Fire DPI & உணர்திறன்', 'சிறந்த விளையாட்டுக்கான அமைப்புகள்'],
    'game_tools': ['கேம் கருவிகள்', 'அனைத்து கேம்களுக்கும் பயனுள்ள கருவிகள்'],
    'ff_info': ['UID சரிபார்ப்பு', 'வீரர் தகவலை உடனே பாருங்கள்'],
    'top_up': ['டாப் அப்', 'வேகமான, பாதுகாப்பான டாப் அப்'],
    'rewards': ['வெகுமதிகள்', 'தினசரி வெகுமதிகளைப் பெறுங்கள்'],
    'events': ['நிகழ்வுகள்', 'விளம்பரங்கள் & சலுகைகள்'],
  },
};

String _langCode(String l) {
  final s = l.toLowerCase();
  if (s.startsWith('si') || l.contains('සිං')) return 'si';
  if (s.startsWith('ta') || l.contains('தம')) return 'ta';
  return 'en';
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  List<Map> _extras = []; // tools added from the server that are not built in
  static const _bg = Color(0xFF070918);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getMoreTools();
      final known = _moreItems.map((e) => e.key).toSet();
      final extras = list
          .whereType<Map>()
          .where((t) => !known.contains(t['key']?.toString()) && '${t['linkUrl'] ?? ''}'.isNotEmpty)
          .toList();
      if (mounted) setState(() => _extras = extras);
    } catch (_) {}
  }

  void _open(String key, String title, String soonMsg, bool soon, {String link = ''}) {
    if (link.isNotEmpty) {
      launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } else if (soon) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title $soonMsg')));
    } else if (key == 'ff_dpi_sensi') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FfDpiSensiScreen()));
    } else if (key == 'tournaments') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsScreen()));
    } else if (key == 'ff_info') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FfInfoScreen()));
    } else if (key == 'events') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsPage()));
    }
  }

  Widget _tile({
    required String emoji,
    required String title,
    required String sub,
    required List<Color> colors,
    required bool soon,
    required String badge,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(22);
    return Opacity(
      opacity: soon ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            borderRadius: radius,
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 34)),
                      const Spacer(),
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, height: 1.35)),
                      const SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.only(right: soon ? 0 : 18),
                        child: Text(sub,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.45)),
                      ),
                    ],
                  ),
                ),
                if (soon)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  const Positioned(right: 10, bottom: 10, child: Icon(Icons.chevron_right, color: Colors.white70, size: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        final L = _moreText[_langCode(lang)]!;
        final tiles = <Widget>[
          for (final it in _moreItems)
            _tile(
              emoji: it.emoji,
              title: L[it.key]![0],
              sub: L[it.key]![1],
              colors: it.colors,
              soon: it.soon,
              badge: L['soon']![0],
              onTap: () => _open(it.key, L[it.key]![0], L['soon']![1], it.soon),
            ),
          for (final t in _extras)
            _tile(
              emoji: '✨',
              title: '${t['title'] ?? ''}',
              sub: '${t['subtitle'] ?? ''}',
              colors: const [Color(0xFF3A3A55), Color(0xFF1E1E30)],
              soon: false,
              badge: '',
              onTap: () => _open('${t['key']}', '', '', false, link: '${t['linkUrl']}'),
            ),
        ];
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(L['header']![0], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26)),
          ),
          body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(L['header']![1], style: const TextStyle(color: Color(0xFFA9A6C8), fontSize: 14, height: 1.5)),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.88,
                  children: tiles,
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9AA0B4)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13))),
      ],
    );
  }

  Widget _corner() {
    return const SizedBox(width: 22, height: 22, child: CustomPaint(painter: _CornerPainter()));
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

    final createdTs = int.tryParse('${b['createAt'] ?? ''}');
    int ageYears = 0;
    int ageDays = 0;
    if (createdTs != null && createdTs > 0) {
      final createdDate = DateTime.fromMillisecondsSinceEpoch(createdTs * 1000);
      final diff = DateTime.now().difference(createdDate);
      ageYears = (diff.inDays / 365).floor();
      ageDays = diff.inDays - (ageYears * 365);
    }

    return RepaintBoundary(
      key: _cardKey,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1730), Color(0xFF10131F)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC9A24B), width: 1.2),
        ),
        child: Stack(
          children: [
            const Positioned(top: 0, left: 0, child: _CornerMark(angle: 0)),
            const Positioned(top: 0, right: 0, child: _CornerMark(angle: 1.5707963267948966)),
            const Positioned(bottom: 0, left: 0, child: _CornerMark(angle: -1.5707963267948966)),
            const Positioned(bottom: 0, right: 0, child: _CornerMark(angle: 3.141592653589793)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFF7A7A), Color(0xFFFFC46B)]).createShader(r),
                      child: const Text('MYGame', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, fontStyle: FontStyle.italic)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFC9A24B)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('FREE FIRE PROFILE', style: TextStyle(color: Color(0xFFC9A24B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        height: 72,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0F1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A2E48)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const Icon(Icons.sports_esports, color: Color(0xFFC9A24B), size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${b['nickname'] ?? 'Unknown'}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                                  Text('Lv.${b['level'] ?? '-'}', style: const TextStyle(color: Color(0xFF9AA0B4), fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC9A24B), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text('$ageYears', style: const TextStyle(color: Color(0xFFC9A24B), fontSize: 22, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 2),
                        const Text('YEARS', style: TextStyle(color: Color(0xFF9AA0B4), fontSize: 9, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Align(alignment: Alignment.centerRight, child: Text('ACCOUNT AGE', style: TextStyle(color: Color(0xFF9AA0B4), fontSize: 9))),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Lv.${b['level'] ?? '-'}', const Color(0xFFC9A24B)),
                    _chip('ID: ${b['accountId'] ?? '-'}', const Color(0xFF6C7A94)),
                    _chip('Region: ${'${b['region'] ?? '-'}'.toUpperCase()}', const Color(0xFF3B8FD6)),
                    _chip('\u2764 ${b['liked'] ?? '-'}', const Color(0xFF7A3B6B)),
                    _chip('$ageYears Years Old', const Color(0xFF3B7A5B)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0F1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2E48)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine(Icons.calendar_today, 'Account created on ${_date(b['createAt'])}'),
                      const SizedBox(height: 8),
                      _infoLine(Icons.calendar_month, '$ageYears years and $ageDays days old'),
                      const SizedBox(height: 8),
                      _infoLine(Icons.access_time, 'Last login ${_date(b['lastLoginAt'])}'),
                    ],
                  ),
                ),
                if (sig.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0F1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2E48)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BIO', style: TextStyle(color: Color(0xFF9AA0B4), fontSize: 10, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(sig, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(color: Color(0xFF2A2E48), height: 1),
                const SizedBox(height: 10),
                _row('EXP', b['exp']),
                _row('BR rank points', b['rankingPoints']),
                _row('CS rank points', b['csRankingPoints']),
                _row('Badges', b['badgeCnt']),
                _row('Prime level', prime['primeLevel']),
                _row('Credit score', credit['creditScore']),
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
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('MYGame Marketplace', style: TextStyle(color: Color(0xFF6C7A94), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
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

class _CornerMark extends StatelessWidget {
  final double angle;
  const _CornerMark({required this.angle});
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: const SizedBox(width: 22, height: 22, child: CustomPaint(painter: _CornerPainter())),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9A24B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 6), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(14, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
