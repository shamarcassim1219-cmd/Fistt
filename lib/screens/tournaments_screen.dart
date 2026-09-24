import 'dart:async';
import 'package:flutter/material.dart';
import '../services/safe_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';
import 'login_screen.dart';

// ======================= helpers =======================

String _two(int n) => n.toString().padLeft(2, '0');

String _fmt(dynamic ms) {
  final v = int.tryParse('${ms ?? ''}');
  if (v == null || v == 0) return '-';
  final d = DateTime.fromMillisecondsSinceEpoch(v);
  return '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
}

String _money(dynamic v) {
  final n = double.tryParse('${v ?? 0}') ?? 0;
  return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
}

int _ms(dynamic v) => int.tryParse('${v ?? ''}') ?? 0;

String _err(Object e) => e.toString().replaceFirst('Exception: ', '');

String _countdown(int ms) {
  if (ms <= 0) return '0s';
  final s = ms ~/ 1000;
  final d = s ~/ 86400;
  final h = (s % 86400) ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  if (d > 0) return '${d}d ${h}h ${m}m';
  if (h > 0) return '${h}h ${m}m ${sec}s';
  return '${m}m ${sec}s';
}

// Phase is recalculated on the phone with the server clock offset, so countdowns stay correct.
String _phaseNow(Map t, int now) {
  final p = '${t['phase']}';
  if (p == 'cancelled' || p == 'finished') return p;
  final open = _ms(t['regOpenAt']);
  final close = _ms(t['regCloseAt']);
  final start = _ms(t['startAt']);
  final end = _ms(t['endAt']);
  if (open != 0 && now < open) return 'upcoming';
  if (now < close) return 'registration';
  if (now < start) return 'closed';
  if (end != 0 && now >= end) return 'ended';
  return 'live';
}

String _countdownLine(Map t, int now) {
  switch (_phaseNow(t, now)) {
    case 'upcoming':
      return 'Registration opens in ${_countdown(_ms(t['regOpenAt']) - now)}';
    case 'registration':
      return 'Registration closes in ${_countdown(_ms(t['regCloseAt']) - now)}';
    case 'closed':
      return 'Starts in ${_countdown(_ms(t['startAt']) - now)}';
    case 'live':
      return 'LIVE NOW';
    case 'ended':
      return 'Ended - results coming soon';
    case 'finished':
      return 'Finished';
    default:
      return 'Cancelled';
  }
}

String _phaseLabel(String p) {
  switch (p) {
    case 'upcoming':
      return 'Upcoming';
    case 'registration':
      return 'Registration open';
    case 'closed':
      return 'Registration closed';
    case 'live':
      return 'LIVE';
    case 'ended':
      return 'Ended';
    case 'finished':
      return 'Finished';
    default:
      return 'Cancelled';
  }
}

Color _phaseColor(String p) {
  switch (p) {
    case 'registration':
      return Colors.green;
    case 'live':
      return Colors.red;
    case 'upcoming':
      return Colors.blue;
    case 'closed':
      return Colors.orange;
    case 'ended':
      return Colors.purple;
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

Widget _thumb(String? url, {double size = 48, bool round = false, IconData icon = Icons.emoji_events}) {
  final radius = BorderRadius.circular(round ? size / 2 : 10);
  final ph = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.25), borderRadius: radius),
    child: Icon(icon, size: size * 0.5, color: Colors.grey),
  );
  if (url == null || url.isEmpty) return ph;
  return ClipRRect(
    borderRadius: radius,
    child: Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ph),
  );
}

Widget _banner(String? url, {double height = 160}) {
  final ph = Container(
    height: height,
    width: double.infinity,
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)])),
    child: const Center(child: Icon(Icons.emoji_events, size: 56, color: Colors.white70)),
  );
  if (url == null || url.isEmpty) return ph;
  return Image.network(url, height: height, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ph);
}

Future<String?> _pickAndUpload() async {
  final picker = ImagePicker();
  final file = await picker.pickImageSafe(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
  if (file == null) return null;
  return await ApiService.uploadImage(file);
}

// ======================= LIST =======================

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  int _offset = 0;
  Timer? _tick;
  Timer? _poll;

  int get _now => DateTime.now().millisecondsSinceEpoch + _offset;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final d = await ApiService.getTournaments();
      if (!mounted) return;
      final sn = int.tryParse('${d['serverNow'] ?? ''}');
      setState(() {
        _items = (d['tournaments'] as List?) ?? [];
        _loading = false;
        _error = null;
        if (sn != null) _offset = sn - DateTime.now().millisecondsSinceEpoch;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent || _items.isEmpty) setState(() {
        _loading = false;
        _error = _err(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournaments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), const SizedBox(height: 8), TextButton(onPressed: _load, child: const Text('Retry'))]))
              : _items.isEmpty
                  ? const Center(child: Text('No tournaments right now. Check back soon!'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _card(_items[i] as Map),
                      ),
                    ),
    );
  }

  Widget _card(Map t) {
    final phase = _phaseNow(t, _now);
    final free = t['isFree'] == true;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(id: int.parse('${t['id']}'))));
          _load(silent: true);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _banner(t['imageUrl']?.toString(), height: 150),
                Positioned(right: 10, top: 10, child: _chip(_phaseLabel(phase), _phaseColor(phase))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t['title']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${t['game']} | ${t['mode']}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _chip('Prize LKR ${_money(t['prizePool'])}', Colors.amber.shade800),
                      _chip(free ? 'FREE entry' : 'Entry LKR ${_money(t['entryFee'])}', free ? Colors.green : Colors.blue),
                      _chip('Teams ${t['teamsCount'] ?? 0}/${t['maxTeams']}', Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_countdownLine(t, _now), style: TextStyle(fontWeight: FontWeight.w700, color: _phaseColor(phase))),
                  if (phase == 'finished' && '${t['winnerGuildName'] ?? ''}'.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(children: [const Icon(Icons.emoji_events, size: 16, color: Colors.amber), const SizedBox(width: 4), Text('Winner: ${t['winnerGuildName']}')]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= DETAIL =======================

class TournamentDetailScreen extends StatefulWidget {
  final int id;
  const TournamentDetailScreen({super.key, required this.id});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  Map<String, dynamic>? _d;
  bool _loading = true;
  String? _error;
  int _offset = 0;
  String? _lastPhase;
  Timer? _tick;
  Timer? _poll;
  IO.Socket? _socket;

  int get _now => DateTime.now().millisecondsSinceEpoch + _offset;
  Map get _t => (_d!['tournament'] as Map);
  Map get _me => (_d!['me'] as Map);

  @override
  void initState() {
    super.initState();
    _load();
    _connectSocket();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_d != null && _lastPhase != null) {
        final p = _phaseNow(_t, _now);
        if (p != _lastPhase) {
          _lastPhase = p;
          _load(silent: true);
        }
      }
    });
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    try {
      _socket?.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _connectSocket() async {
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) return; // guests use the 20s refresh
      final s = IO.io(
        ApiService.baseUrl,
        IO.OptionBuilder().setTransports(['polling', 'websocket']).setAuth({'token': token}).disableAutoConnect().build(),
      );
      s.onConnect((_) => s.emit('join', 'tournament:${widget.id}'));
      s.on('tournament:update', (_) {
        if (mounted) _load(silent: true);
      });
      s.connect();
      _socket = s;
    } catch (_) {}
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final d = await ApiService.getTournament(widget.id);
      if (!mounted) return;
      final sn = int.tryParse('${d['serverNow'] ?? ''}');
      setState(() {
        _d = d;
        _loading = false;
        _error = null;
        if (sn != null) _offset = sn - DateTime.now().millisecondsSinceEpoch;
        _lastPhase = '${(d['tournament'] as Map)['phase']}';
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent || _d == null) setState(() {
        _loading = false;
        _error = _err(e);
      });
    }
  }

  Future<void> _act(Future<String?> Function() fn) async {
    try {
      final m = await fn();
      if (m != null) _msg(m);
      await _load(silent: true);
    } catch (e) {
      _msg(_err(e));
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    return ok == true;
  }

  Future<List<String>?> _askGame(String title) async {
    final idC = TextEditingController();
    final nameC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Your Game ID (UID)')),
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Your Game Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Join')),
        ],
      ),
    );
    if (ok != true) return null;
    if (idC.text.trim().isEmpty || nameC.text.trim().isEmpty) {
      _msg('Enter both Game ID and Game Name');
      return null;
    }
    return [idC.text.trim(), nameC.text.trim()];
  }

  // ---------- actions ----------

  Future<void> _login() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    _load(silent: true);
  }

  Future<void> _register() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _RegisterScreen(tournament: Map<String, dynamic>.from(_t))));
    if (ok == true) _load(silent: true);
  }

  Future<void> _accept(Map inv) async {
    final r = await _askGame('Join "${inv['guildName']}"');
    if (r == null) return;
    await _act(() async {
      await ApiService.acceptTournamentInvite(int.parse('${inv['memberId']}'), r[0], r[1]);
      return 'You joined the team';
    });
  }

  Future<void> _reject(Map inv) async {
    await _act(() async {
      await ApiService.rejectTournamentInvite(int.parse('${inv['memberId']}'));
      return 'Invite rejected';
    });
  }

  Future<void> _removeMember(Map team, Map m) async {
    final pending = m['status'] == 'pending';
    if (!await _confirm(pending ? 'Cancel invite?' : 'Remove player?', '${m['displayName']}')) return;
    await _act(() async {
      await ApiService.removeTournamentMember(int.parse('${team['teamId']}'), int.parse('${m['memberId']}'));
      return pending ? 'Invite cancelled' : 'Player removed';
    });
  }

  Future<void> _leave(Map team) async {
    if (!await _confirm('Leave team?', 'You will leave "${team['guildName']}".')) return;
    await _act(() async {
      await ApiService.leaveTournamentTeam(int.parse('${team['teamId']}'));
      return 'You left the team';
    });
  }

  Future<void> _dissolve(Map team) async {
    final free = _t['isFree'] == true;
    if (!await _confirm('Dissolve team?', free ? 'Your team will be removed from the tournament.' : 'Your team will be removed and the entry fee (LKR ${_money(_t['entryFee'])}) refunded to your wallet.')) return;
    await _act(() => ApiService.dissolveTournamentTeam(int.parse('${team['teamId']}')));
  }

  Future<void> _editGuild(Map team) async {
    final nameC = TextEditingController(text: '${team['guildName']}');
    String? img = team['guildImageUrl']?.toString();
    bool up = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Edit guild'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: up
                    ? null
                    : () async {
                        setD(() => up = true);
                        try {
                          final u = await _pickAndUpload();
                          if (u != null) img = u;
                        } catch (e) {
                          _msg(_err(e));
                        }
                        setD(() => up = false);
                      },
                child: up ? const SizedBox(width: 80, height: 80, child: Center(child: CircularProgressIndicator())) : _thumb(img, size: 80, round: true, icon: Icons.add_a_photo_outlined),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Guild name')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _act(() async {
      await ApiService.updateTournamentTeam(int.parse('${team['teamId']}'), guildName: nameC.text.trim(), guildImageUrl: img ?? '');
      return 'Guild updated';
    });
  }

  void _openInvite(Map team) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InviteSheet(teamId: int.parse('${team['teamId']}'), onInvited: () => _load(silent: true)),
    );
  }

  // ---------- sections ----------

  Widget _countdownCard() {
    final phase = _phaseNow(_t, _now);
    final c = _phaseColor(phase);
    return Card(
      color: c.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(_countdownLine(_t, _now), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c)),
            const SizedBox(height: 4),
            Text('Starts: ${_fmt(_t['startAt'])}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow() {
    final free = _t['isFree'] == true;
    Widget box(IconData i, String top, String bottom) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(children: [Icon(i, size: 22), const SizedBox(height: 4), Text(top, style: const TextStyle(fontWeight: FontWeight.w800), textAlign: TextAlign.center), Text(bottom, style: const TextStyle(fontSize: 11))]),
            ),
          ),
        );
    return Row(
      children: [
        box(Icons.emoji_events_outlined, 'LKR ${_money(_t['prizePool'])}', 'Prize pool'),
        box(Icons.confirmation_number_outlined, free ? 'FREE' : 'LKR ${_money(_t['entryFee'])}', free ? 'Entry' : 'Entry per team'),
        box(Icons.groups_outlined, '${_t['teamsCount'] ?? 0}/${_t['maxTeams']}', 'Teams'),
      ],
    );
  }

  Widget _invitesSection() {
    final invites = (_me['invites'] as List?) ?? [];
    if (invites.isEmpty) return const SizedBox.shrink();
    final phase = _phaseNow(_t, _now);
    return Column(
      children: invites.map((i) {
        final inv = i as Map;
        return Card(
          color: Colors.blue.withValues(alpha: 0.10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _thumb(inv['guildImageUrl']?.toString(), size: 40, round: true, icon: Icons.groups),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${inv['leaderName']} invited you to join "${inv['guildName']}"', style: const TextStyle(fontWeight: FontWeight.w600))),
                ]),
                if (phase == 'registration')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => _reject(inv), child: const Text('Reject')),
                      const SizedBox(width: 8),
                      FilledButton(onPressed: () => _accept(inv), child: const Text('Accept')),
                    ],
                  )
                else
                  const Padding(padding: EdgeInsets.only(top: 6), child: Text('Registration is closed.', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _myTeamSection() {
    final team = _me['team'] as Map?;
    final phase = _phaseNow(_t, _now);
    final loggedIn = _me['loggedIn'] == true;

    if (team == null) {
      if (!loggedIn) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const Text('Login to register your team or accept invites.'),
              const SizedBox(height: 8),
              FilledButton(onPressed: _login, child: const Text('Login')),
            ]),
          ),
        );
      }
      if (phase == 'registration') {
        final free = _t['isFree'] == true;
        final full = (int.tryParse('${_t['teamsCount']}') ?? 0) >= (int.tryParse('${_t['maxTeams']}') ?? 0);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Text(free ? 'Free entry. You become the team leader when you register.' : 'Entry fee LKR ${_money(_t['entryFee'])} per team, paid by the team leader (you) from your wallet. Your teammates join free.', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: full ? null : _register, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(full ? 'Tournament is full' : 'Register your team')))),
            ]),
          ),
        );
      }
      if (phase == 'upcoming') {
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Center(child: Text('Registration opens ${_fmt(_t['regOpenAt'])}'))));
      }
      return const SizedBox.shrink();
    }

    final members = (team['members'] as List?) ?? [];
    final accepted = members.where((m) => (m as Map)['status'] == 'accepted').length;
    final pending = members.where((m) => (m as Map)['status'] == 'pending').length;
    final teamSize = int.tryParse('${_t['teamSize']}') ?? 4;
    final isLeader = _me['isLeader'] == true;
    final editable = phase == 'registration';
    final suspended = '${team['status']}' == 'suspended';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _thumb(team['guildImageUrl']?.toString(), size: 46, round: true, icon: Icons.groups),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${team['guildName']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(isLeader ? 'Your team (you are the leader)' : 'Your team', style: const TextStyle(fontSize: 12)),
                ]),
              ),
              if (suspended) _chip('Suspended', Colors.red) else _chip('Registered', Colors.green),
            ]),
            if (suspended && '${team['suspendReason'] ?? ''}'.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text('Removed from the tournament: ${team['suspendReason']}', style: const TextStyle(color: Colors.red))),
            const Divider(height: 22),
            Text('Players: $accepted / $teamSize${pending > 0 ? '  ($pending invited)' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ...members.map((m) {
              final mm = m as Map;
              final st = '${mm['status']}';
              Color sc = Colors.green;
              if (st == 'pending') sc = Colors.orange;
              if (st == 'rejected') sc = Colors.red;
              final gid = '${mm['gameId'] ?? ''}';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: _thumb(mm['photoUrl']?.toString(), size: 34, round: true, icon: Icons.person),
                title: Text('${mm['displayName']}${mm['role'] == 'leader' ? '  (leader)' : ''}'),
                subtitle: Text(gid.isEmpty ? (st == 'pending' ? 'Waiting for reply' : st) : '${mm['gameName']} | ID $gid'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  _chip(st, sc),
                  if (isLeader && editable && mm['role'] != 'leader') IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _removeMember(team, mm)),
                ]),
              );
            }),
            if (isLeader && editable && !suspended) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                if (accepted + pending < teamSize) OutlinedButton.icon(onPressed: () => _openInvite(team), icon: const Icon(Icons.person_add_alt_1, size: 18), label: const Text('Invite player')),
                OutlinedButton.icon(onPressed: () => _editGuild(team), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Edit guild')),
              ]),
            ],
            if (isLeader && !suspended && (phase == 'registration' || phase == 'closed'))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(onPressed: () => _dissolve(team), icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), label: const Text('Dissolve team', style: TextStyle(color: Colors.red))),
              ),
            if (!isLeader && editable && !suspended)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => _leave(team), child: const Text('Leave team', style: TextStyle(color: Colors.red))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roomSection() {
    final room = _me['room'] as Map?;
    final isLeader = _me['isLeader'] == true;
    if (room == null) {
      if (isLeader && _me['team'] != null && '${(_me['team'] as Map)['status']}' == 'active') {
        return const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Room ID and password will appear here before the match (team leaders only).')));
      }
      return const SizedBox.shrink();
    }
    Widget row(String label, String value) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontSize: 12)),
          subtitle: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          trailing: IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              _msg('$label copied');
            },
          ),
        );
    return Card(
      color: Colors.amber.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Room details (leaders only)', style: TextStyle(fontWeight: FontWeight.w800)),
            row('Room ID', '${room['roomId']}'),
            row('Password', '${room['roomPassword']}'),
            const Text('Share these with your teammates.', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 6), child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)));

  Widget _teamsSection() {
    final teams = (_d!['teams'] as List?) ?? [];
    final myId = (_me['team'] as Map?)?['teamId'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Registered teams (${teams.length})'),
        if (teams.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('No teams yet. Be the first!')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: teams.map((x) {
            final tm = x as Map;
            final mine = myId != null && '${tm['teamId']}' == '$myId';
            return Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: (mine ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _thumb(tm['guildImageUrl']?.toString(), size: 28, round: true, icon: Icons.groups),
                const SizedBox(width: 8),
                Text('${tm['guildName']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _leaderboardSection() {
    final lb = (_d!['leaderboard'] as List?) ?? [];
    final matches = (_d!['matches'] as List?) ?? [];
    if (matches.isEmpty) return const SizedBox.shrink();
    final myId = (_me['team'] as Map?)?['teamId'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Leaderboard (${matches.length} match${matches.length == 1 ? '' : 'es'})'),
        Card(
          child: Column(
            children: lb.map((x) {
              final r = x as Map;
              final mine = myId != null && '${r['teamId']}' == '$myId';
              return Container(
                color: mine ? Colors.green.withValues(alpha: 0.12) : null,
                child: ListTile(
                  dense: true,
                  leading: SizedBox(
                    width: 64,
                    child: Row(children: [
                      SizedBox(width: 24, child: Text('${r['rank']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                      _thumb(r['guildImageUrl']?.toString(), size: 30, round: true, icon: Icons.groups),
                    ]),
                  ),
                  title: Text('${r['guildName']}'),
                  trailing: Text('${r['totalPoints']} pts', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _winnerSection() {
    final w = _d!['winner'] as Map?;
    if (w == null) return const SizedBox.shrink();
    final img = w['imageUrl']?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Winner'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (img != null && img.isNotEmpty) Image.network(img, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 0)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                    const SizedBox(width: 10),
                    _thumb(w['guildImageUrl']?.toString(), size: 34, round: true, icon: Icons.groups),
                    const SizedBox(width: 10),
                    Flexible(child: Text('${w['guildName']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _d == null) {
      return Scaffold(appBar: AppBar(title: const Text('Tournament')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_d == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tournament')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error ?? 'Could not load'), TextButton(onPressed: _load, child: const Text('Retry'))])),
      );
    }
    final rules = '${_t['rules'] ?? ''}'.trim();
    return Scaffold(
      appBar: AppBar(title: Text('${_t['title']}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(14), child: _banner(_t['imageUrl']?.toString(), height: 170)),
            const SizedBox(height: 10),
            Text('${_t['title']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${_t['game']} | ${_t['mode']} | ${_t['teamSize']} per team', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            _countdownCard(),
            _infoRow(),
            _invitesSection(),
            _myTeamSection(),
            _roomSection(),
            if (rules.isNotEmpty)
              Card(child: ExpansionTile(title: const Text('Rules', style: TextStyle(fontWeight: FontWeight.w800)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), expandedCrossAxisAlignment: CrossAxisAlignment.start, children: [Text(rules)])),
            _teamsSection(),
            _leaderboardSection(),
            _winnerSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ======================= REGISTER (leader) =======================

class _RegisterScreen extends StatefulWidget {
  final Map<String, dynamic> tournament;
  const _RegisterScreen({required this.tournament});

  @override
  State<_RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<_RegisterScreen> {
  final _guild = TextEditingController();
  final _gameId = TextEditingController();
  final _gameName = TextEditingController();
  String? _img;
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _guild.dispose();
    _gameId.dispose();
    _gameName.dispose();
    super.dispose();
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pick() async {
    setState(() => _uploading = true);
    try {
      final u = await _pickAndUpload();
      if (u != null) setState(() => _img = u);
    } catch (e) {
      _msg(_err(e));
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _submit() async {
    final g = _guild.text.trim();
    if (g.length < 2) return _msg('Enter your guild name');
    if (_gameId.text.trim().isEmpty || _gameName.text.trim().isEmpty) return _msg('Enter your Game ID and Game Name');
    final free = widget.tournament['isFree'] == true;
    if (!free) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pay entry fee?'),
          content: Text('LKR ${_money(widget.tournament['entryFee'])} will be deducted from your wallet. Your teammates join free.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pay and register')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = true);
    try {
      final m = await ApiService.registerTournament(
        int.parse('${widget.tournament['id']}'),
        guildName: g,
        guildImageUrl: _img,
        gameId: _gameId.text.trim(),
        gameName: _gameName.text.trim(),
      );
      _msg(m);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _msg(_err(e));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final free = widget.tournament['isFree'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Register your team')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploading ? null : _pick,
              child: Column(
                children: [
                  _uploading ? const SizedBox(width: 96, height: 96, child: Center(child: CircularProgressIndicator())) : _thumb(_img, size: 96, round: true, icon: Icons.add_a_photo_outlined),
                  const SizedBox(height: 6),
                  const Text('Guild image (optional)', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _guild, maxLength: 40, decoration: const InputDecoration(labelText: 'Guild name', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          const Text('Your in-game details', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _gameId, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Game ID (UID)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _gameName, decoration: const InputDecoration(labelText: 'Game Name', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          Text(
            free ? 'This tournament is free. You will be the team leader and can invite players after registering.' : 'Entry fee: LKR ${_money(widget.tournament['entryFee'])} (paid once by you, the leader). Teammates join free.',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_saving ? 'Registering...' : 'Register')),
          ),
        ],
      ),
    );
  }
}

// ======================= INVITE PLAYERS (leader) =======================

class _InviteSheet extends StatefulWidget {
  final int teamId;
  final VoidCallback onInvited;
  const _InviteSheet({required this.teamId, required this.onInvited});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _q = TextEditingController();
  List<dynamic> _results = [];
  final Set<int> _invited = {};
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final r = await ApiService.searchTournamentUsers(q);
      if (mounted) setState(() => _results = r);
    } catch (e) {
      _msg(_err(e));
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _invite(Map u) async {
    final id = int.parse('${u['id']}');
    try {
      await ApiService.inviteTournamentPlayer(widget.teamId, id);
      setState(() => _invited.add(id));
      widget.onInvited();
      _msg('Invite sent to ${u['displayName']}');
    } catch (e) {
      _msg(_err(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _q,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  labelText: 'Search player by name (or exact email)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))) : const Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? Center(child: Text(_q.text.trim().length < 2 ? 'Type at least 2 letters' : 'No players found'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final u = _results[i] as Map;
                        final id = int.parse('${u['id']}');
                        final done = _invited.contains(id);
                        return ListTile(
                          leading: _thumb(u['photoUrl']?.toString(), size: 38, round: true, icon: Icons.person),
                          title: Text('${u['displayName']}'),
                          trailing: done ? const Text('Invited') : FilledButton(onPressed: () => _invite(u), child: const Text('Invite')),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
