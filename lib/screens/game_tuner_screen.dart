import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'ff_apply_settings_screen.dart';

// ======================= helpers =======================

String _err(Object e) => e.toString().replaceFirst('Exception: ', '');

String _tierLabel(String t) {
  switch (t) {
    case 'flagship':
      return 'Flagship';
    case 'high':
      return 'High-end';
    case 'mid':
      return 'Mid-range';
    default:
      return 'Entry-level';
  }
}

String _tierHint(String t) {
  switch (t) {
    case 'flagship':
      return 'Newest top models (Galaxy S / Ultra, iPhone Pro, gaming phones)';
    case 'high':
      return 'Strong phones from the last 3 to 4 years';
    case 'mid':
      return 'Everyday phones (Galaxy A, Redmi Note, Realme, vivo V)';
    default:
      return 'Budget or older phones that struggle with heavy games';
  }
}

Color _tierColor(String t) {
  switch (t) {
    case 'flagship':
      return Colors.amber.shade800;
    case 'high':
      return Colors.green;
    case 'mid':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

Widget _chip(String text, Color c) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    );

// ======================= 1. PICK A GAME =======================

class GameTunerScreen extends StatelessWidget {
  const GameTunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game DPI & Sensitivity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Select your game', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Get the best sensitivity, DPI and smooth-play settings for your phone.', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF8A00), Color(0xFFE52D27)]), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.sports_esports, color: Colors.white),
              ),
              title: const Text('Free Fire', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              subtitle: const Text('Sensitivity, DPI and graphics for any phone'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _PhoneSearchScreen(gameKey: 'freefire', gameTitle: 'Free Fire'))),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('More games coming soon', style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// ======================= 2. SEARCH YOUR PHONE =======================

class _PhoneSearchScreen extends StatefulWidget {
  final String gameKey;
  final String gameTitle;
  const _PhoneSearchScreen({required this.gameKey, required this.gameTitle});

  @override
  State<_PhoneSearchScreen> createState() => _PhoneSearchScreenState();
}

class _PhoneSearchScreenState extends State<_PhoneSearchScreen> {
  final _q = TextEditingController();
  List<Map> _phones = [];
  Map<String, Map> _presets = {};
  bool _loading = true;
  String? _error;
  String _platform = 'all';
  String? _brand;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await ApiService.getGameTunerConfig(widget.gameKey);
      final phones = ((d['phones'] as List?) ?? []).map((e) => e as Map).toList();
      final presets = <String, Map>{};
      for (final p in ((d['presets'] as List?) ?? [])) {
        final m = p as Map;
        presets['${m['platform']}_${m['tier']}'] = m;
      }
      if (!mounted) return;
      setState(() {
        _phones = phones;
        _presets = presets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _err(e);
        _loading = false;
      });
    }
  }

  List<String> get _brands {
    final count = <String, int>{};
    for (final p in _phones) {
      if (_platform != 'all' && p['platform'] != _platform) continue;
      final b = '${p['brand']}';
      count[b] = (count[b] ?? 0) + 1;
    }
    final keys = count.keys.toList();
    return keys;
  }

  List<Map> get _filtered {
    final tokens = _q.text.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    return _phones.where((p) {
      if (_platform != 'all' && p['platform'] != _platform) return false;
      if (_brand != null && p['brand'] != _brand) return false;
      final name = '${p['name']}'.toLowerCase();
      for (final t in tokens) {
        if (!name.contains(t)) return false;
      }
      return true;
    }).toList();
  }

  void _open(Map phone) {
    final preset = _presets['${phone['platform']}_${phone['tier']}'];
    if (preset == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhoneSettingsScreen(
          gameTitle: widget.gameTitle,
          title: '${phone['name']}',
          platform: '${phone['platform']}',
          tier: '${phone['tier']}',
          preset: preset,
          tested: phone['override'] as Map?,
          note: phone['note']?.toString(),
        ),
      ),
    );
  }

  Future<void> _pickClass() async {
    String platform = 'android';
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phone not listed?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Pick your phone type and how powerful it is.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'android', label: Text('Android'), icon: Icon(Icons.android)),
                  ButtonSegment(value: 'ios', label: Text('iPhone / iPad'), icon: Icon(Icons.apple)),
                ],
                selected: {platform},
                onSelectionChanged: (s) => setS(() => platform = s.first),
              ),
              const SizedBox(height: 8),
              ...['flagship', 'high', 'mid', 'low'].map((t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_tierLabel(t), style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(_tierHint(t), style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(ctx, [platform, t]),
                  )),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    final preset = _presets['${result[0]}_${result[1]}'];
    if (preset == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhoneSettingsScreen(
          gameTitle: widget.gameTitle,
          title: '${result[0] == 'ios' ? 'iPhone / iPad' : 'Android'} - ${_tierLabel(result[1])}',
          platform: result[0],
          tier: result[1],
          preset: preset,
          tested: null,
          note: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.gameTitle}: find your phone')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), TextButton(onPressed: _load, child: const Text('Retry'))]))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TextField(
                        controller: _q,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search your phone model (e.g. Galaxy A54, iPhone 13)',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _q.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _q.clear())),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final e in const [['all', 'All'], ['android', 'Android'], ['ios', 'iPhone / iPad']])
                            Padding(
                              padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                              child: ChoiceChip(
                                label: Text(e[1]),
                                selected: _platform == e[0],
                                onSelected: (_) => setState(() {
                                  _platform = e[0];
                                  _brand = null;
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                            child: ChoiceChip(label: const Text('All brands'), selected: _brand == null, onSelected: (_) => setState(() => _brand = null)),
                          ),
                          for (final b in _brands)
                            Padding(
                              padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                              child: ChoiceChip(label: Text(b), selected: _brand == b, onSelected: (_) => setState(() => _brand = _brand == b ? null : b)),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Align(alignment: Alignment.centerLeft, child: Text('${list.length} phone${list.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12))),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length + 1,
                        itemBuilder: (_, i) {
                          if (i == list.length) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: OutlinedButton.icon(
                                onPressed: _pickClass,
                                icon: const Icon(Icons.help_outline),
                                label: Text(list.isEmpty ? 'Phone not found? Choose your phone type' : 'Phone not listed? Choose your phone type'),
                              ),
                            );
                          }
                          final p = list[i];
                          final ios = p['platform'] == 'ios';
                          return ListTile(
                            leading: Icon(ios ? Icons.apple : Icons.android, color: ios ? null : Colors.green),
                            title: Text('${p['name']}'),
                            subtitle: Row(children: [_chip(_tierLabel('${p['tier']}'), _tierColor('${p['tier']}')), if (p['override'] != null) ...[const SizedBox(width: 6), _chip('Tested settings', Colors.teal)]]),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open(p),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ======================= 3. SETTINGS FOR YOUR PHONE =======================

class _PhoneSettingsScreen extends StatefulWidget {
  final String gameTitle;
  final String title;
  final String platform;
  final String tier;
  final Map preset;
  final Map? tested;
  final String? note;
  const _PhoneSettingsScreen({
    required this.gameTitle,
    required this.title,
    required this.platform,
    required this.tier,
    required this.preset,
    required this.tested,
    required this.note,
  });

  @override
  State<_PhoneSettingsScreen> createState() => _PhoneSettingsScreenState();
}

class _PhoneSettingsScreenState extends State<_PhoneSettingsScreen> {
  final _sw = TextEditingController();

  @override
  void dispose() {
    _sw.dispose();
    super.dispose();
  }

  int _val(String key) {
    final o = widget.tested;
    if (o != null && o[key] != null) return int.tryParse('${o[key]}') ?? 0;
    return int.tryParse('${widget.preset[key]}') ?? 0;
  }

  bool get _isFreeFire => widget.gameTitle.toLowerCase().contains('free fire');
  int get _maxSens => _isFreeFire ? 200 : 100;
  Map<String, int>? _customResult;

  void _detectCustomDpi(BuildContext context) {
    final mq = MediaQuery.of(context);
    final density = (mq.devicePixelRatio * 160).round();
    final currentSW = mq.size.shortestSide.round();

    double factor;
    if (currentSW > 420) {
      factor = 1.15;
    } else if (currentSW > 400) {
      factor = 1.08;
    } else {
      factor = 1.0;
    }
    var targetSW = (currentSW / factor).floor();
    if (targetSW < 320) targetSW = 320;

    final base = _maxSens == 200 ? 170 : 85;
    final general = (base + (factor - 1.0) * 100).round().clamp(0, _maxSens);
    final redDot = (general * 0.93).round().clamp(0, _maxSens);
    final scope2x = (redDot * 0.85).round().clamp(0, _maxSens);
    final scope4x = (redDot * 0.70).round().clamp(0, _maxSens);
    final awm = (redDot * 0.55).round().clamp(0, _maxSens);
    final freeLook = (_maxSens * 0.18).round().clamp(0, _maxSens);

    setState(() {
      _sw.text = '$currentSW';
      _customResult = {
        'density': density,
        'currentSW': currentSW,
        'targetSW': targetSW,
        'general': general,
        'redDot': redDot,
        'scope2x': scope2x,
        'scope4x': scope4x,
        'awm': awm,
        'freeLook': freeLook,
      };
    });
  }

  Widget _bar(String label, int v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 92, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: (v / _maxSens).clamp(0.0, 1.0), minHeight: 10),
            ),
          ),
          SizedBox(width: 44, child: Text('$v', textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w800))]),
      );

  Widget _dpiCard() {
    final factor = double.tryParse('${widget.preset['dpiFactor']}') ?? 1.0;
    if (widget.platform == 'ios') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('iPhone and iPad do not allow changing the screen DPI, so there is nothing to adjust. Use the sensitivity values above and the smooth-play tips below.'),
              const SizedBox(height: 12),
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.chat, color: Colors.green),
                  title: const Text('Accurate Sensi File එකක් ගන්නද?'),
                  subtitle: const Text('WhatsApp හරහා order කරන්න'),
                  onTap: () => launchUrl(
                    Uri.parse('https://wa.me/94713051219?text=Hi, mata iPhone sensi file eka ganna one'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final cur = int.tryParse(_sw.text.trim());
    Widget result;
    if (factor <= 1.001) {
      result = const Text('Keep your default DPI. No change is needed for this phone class.', style: TextStyle(fontWeight: FontWeight.w700));
    } else if (cur == null) {
      result = const Text('Enter your current Smallest width to get the new value.', style: TextStyle(fontSize: 12));
    } else if (cur < 300 || cur > 700) {
      result = const Text('Enter a value between 300 and 700.', style: TextStyle(color: Colors.orange));
    } else {
      var target = (cur / factor).floor();
      if (target < 320) target = 320;
      result = Text('Set Smallest width to $target  (now $cur)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.green));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(factor <= 1.001 ? 'Recommended: keep the default DPI.' : 'Recommended: raise DPI about ${((factor - 1) * 100).round()}% (this lowers the Smallest width).', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (factor > 1.001)
              TextField(
                controller: _sw,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Your current Smallest width (dp)', helperText: 'Settings > Developer options > Smallest width', border: OutlineInputBorder(), isDense: true),
              ),
            const SizedBox(height: 10),
            result,
            const Divider(height: 24),
            const Text('How to change it', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('1. Settings > About phone > tap Build number 7 times.\n2. Settings > Developer options > Smallest width.\n3. Type the new number and confirm. The screen size updates right away.\n4. Open Free Fire and test. To undo, type your original number again.'),
            const SizedBox(height: 8),
            const Text('Keep the change small and never go below 320. DPI mostly changes how big things look on screen, so treat it as fine-tuning.', style: TextStyle(fontSize: 12)),
            if (_isFreeFire) ...[
              const Divider(height: 24),
              const Text('Custom DPI (auto-detect)', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text("Reads your actual phone's screen right now and works out a Smallest width and Free Fire sensitivity to try, even if your phone is not in our list.", style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _detectCustomDpi(context),
                icon: const Icon(Icons.smartphone),
                label: const Text("Detect my phone's real settings"),
              ),
              if (_customResult != null) ...[
                const SizedBox(height: 12),
                _kv('Current Smallest width', '${_customResult!['currentSW']} dp'),
                _kv('Suggested Smallest width', '${_customResult!['targetSW']} dp'),
                const SizedBox(height: 8),
                _kv('General', '${_customResult!['general']}'),
                _kv('Red Dot', '${_customResult!['redDot']}'),
                _kv('2x Scope', '${_customResult!['scope2x']}'),
                _kv('4x Scope', '${_customResult!['scope4x']}'),
                _kv('AWM Scope', '${_customResult!['awm']}'),
                _kv('Free Look', '${_customResult!['freeLook']}'),
                const SizedBox(height: 6),
                const Text('These are calculated from your real screen, not a guess. Use them as a starting point and fine-tune in Training Grounds.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ] else ...[
              const SizedBox(height: 8),
              const Text('Custom DPI auto-detect: coming soon for this game.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ios = widget.platform == 'ios';
    final tips = ((widget.preset['tips'] as List?) ?? []).map((e) => '$e').toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(ios ? Icons.apple : Icons.android, size: 34, color: ios ? null : Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 6, children: [
                          _chip(widget.gameTitle, Colors.deepOrange),
                          _chip(_tierLabel(widget.tier), _tierColor(widget.tier)),
                          if (widget.tested != null) _chip('Tested settings', Colors.teal),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _sectionTitle('Sensitivity'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar('General', _val('general')),
                  _bar('Red Dot', _val('redDot')),
                  _bar('2x Scope', _val('scope2x')),
                  _bar('4x Scope', _val('scope4x')),
                  _bar('AWM Scope', _val('awm')),
                  _bar('Free Look', _val('freeLook')),
                  const SizedBox(height: 6),
                  const Text('Free Fire > Settings > Sensitivity. Drag each slider to the number shown.', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          _sectionTitle(ios ? 'DPI (iPhone / iPad)' : 'DPI (screen density)'),
          _dpiCard(),
          _sectionTitle('Smooth gameplay'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('Graphics', '${widget.preset['graphics'] ?? '-'}'),
                  _kv('Frame rate', '${widget.preset['fps'] ?? '-'}'),
                  _kv('Shadows', '${widget.preset['shadows'] ?? '-'}'),
                  const Text('Free Fire > Settings > Graphics. If your phone does not show an option, pick the closest lower one.', style: TextStyle(fontSize: 12)),
                  const Divider(height: 24),
                  ...tips.map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('\u2022  '), Expanded(child: Text(t))]),
                      )),
                ],
              ),
            ),
          ),
          if (widget.note != null && widget.note!.isNotEmpty) ...[
            _sectionTitle('Note'),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(widget.note!))),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 14, 8, 24),
            child: Text('These are recommended starting values, not guaranteed for every player. Test in the Training Ground and adjust each slider by 3 to 5 points until aiming feels right.', style: TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FfApplySettingsScreen())),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Settings Apply කරලා Free Fire Open කරමු'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
