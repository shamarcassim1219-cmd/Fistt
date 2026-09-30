import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../services/auth_helper.dart';
import 'wallet_screen.dart';

// A small fade + slide entrance used for every tile/card on this screen, so
// content appears progressively instead of popping in all at once.
class _RevealIn extends StatelessWidget {
  final int index;
  final Widget child;
  const _RevealIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 70).clamp(0, 600)),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: child),
      ),
      child: child,
    );
  }
}

// ======================= 1. GAME GRID =======================

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  List<dynamic> _games = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final games = await ApiService.getTopupGames();
      if (mounted) setState(() => _games = games);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('top_up'))),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: AppColors.hint), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(onPressed: _load, child: Text(AppLocalizations.t('retry'))),
                          ],
                        ),
                      ),
                    )
                  : _games.isEmpty
                      ? Center(child: Text(AppLocalizations.t('no_games_available'), style: const TextStyle(color: AppColors.hint)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: _games.length,
                            itemBuilder: (_, i) {
                              final g = _games[i] as Map;
                              return _RevealIn(
                                index: i,
                                child: _GameTile(
                                  name: '${g['name'] ?? ''}',
                                  iconUrl: '${g['icon_url'] ?? ''}',
                                  onTap: () async {
                                    if (!await requireLogin(context, reason: AppLocalizations.t('login_to_top_up'))) return;
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TopUpGameScreen(
                                          gameId: g['id'] as int,
                                          gameName: '${g['name'] ?? ''}',
                                          iconUrl: '${g['icon_url'] ?? ''}',
                                          requiresZoneId: g['requires_zone_id'] == true || g['requires_zone_id'] == 1,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
        );
      },
    );
  }
}

class _GameTile extends StatelessWidget {
  final String name;
  final String iconUrl;
  final VoidCallback onTap;
  const _GameTile({required this.name, required this.iconUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: iconUrl.isEmpty
                      ? Container(
                          color: AppColors.fieldFill,
                          child: const Center(child: Icon(Icons.videogame_asset_outlined, color: AppColors.hint, size: 36)),
                        )
                      : Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.fieldFill,
                            child: const Center(child: Icon(Icons.videogame_asset_outlined, color: AppColors.hint, size: 36)),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= 2. PACKAGES + VERIFY =======================

class TopUpGameScreen extends StatefulWidget {
  final int gameId;
  final String gameName;
  final String iconUrl;
  final bool requiresZoneId;
  const TopUpGameScreen({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.iconUrl,
    required this.requiresZoneId,
  });

  @override
  State<TopUpGameScreen> createState() => _TopUpGameScreenState();
}

class _TopUpGameScreenState extends State<TopUpGameScreen> {
  final _playerIdCtrl = TextEditingController();
  final _zoneIdCtrl = TextEditingController();

  List<dynamic> _packages = [];
  bool _loadingPackages = true;
  int? _selectedPackageId;

  bool _verifying = false;
  bool _verified = false;
  bool _verificationSkipped = false; // game has no LioGames mapping yet - allow continuing without a name
  String? _verifiedName;
  String? _verifyError;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _playerIdCtrl.dispose();
    _zoneIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    try {
      final list = await ApiService.getTopupPackages(widget.gameId);
      if (mounted) setState(() => _packages = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPackages = false);
    }
  }

  void _resetVerification() {
    setState(() {
      _verified = false;
      _verificationSkipped = false;
      _verifiedName = null;
      _verifyError = null;
    });
  }

  Future<void> _verify() async {
    final playerId = _playerIdCtrl.text.trim();
    if (playerId.isEmpty) {
      setState(() => _verifyError = AppLocalizations.t('enter_player_id'));
      return;
    }
    if (widget.requiresZoneId && _zoneIdCtrl.text.trim().isEmpty) {
      setState(() => _verifyError = AppLocalizations.t('enter_zone_id'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _verifyError = null;
    });
    try {
      final data = await ApiService.verifyTopupPlayer(
        gameId: widget.gameId,
        playerId: playerId,
        zoneId: widget.requiresZoneId ? _zoneIdCtrl.text.trim() : null,
      );
      if (!mounted) return;
      setState(() {
        if (data['manual'] == true) {
          _verificationSkipped = true;
          _verified = false;
          _verifiedName = null;
        } else {
          _verified = true;
          _verifiedName = data['displayName'] as String?;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _verifyError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  bool get _canContinue => _selectedPackageId != null && (_verified || _verificationSkipped);

  Future<void> _openPayment() async {
    final pkg = _packages.firstWhere((p) => p['id'] == _selectedPackageId) as Map;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(
        gameId: widget.gameId,
        packageId: pkg['id'] as int,
        packageName: '${pkg['name'] ?? ''}',
        price: (pkg['price'] as num).toDouble(),
        playerId: _playerIdCtrl.text.trim(),
        zoneId: widget.requiresZoneId ? _zoneIdCtrl.text.trim() : null,
      ),
    );
    if (result == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(widget.gameName)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RevealIn(
                index: 0,
                child: TextField(
                  controller: _playerIdCtrl,
                  onChanged: (_) => _resetVerification(),
                  decoration: InputDecoration(labelText: AppLocalizations.t('player_id'), border: const OutlineInputBorder()),
                ),
              ),
              if (widget.requiresZoneId) ...[
                const SizedBox(height: 12),
                _RevealIn(
                  index: 1,
                  child: TextField(
                    controller: _zoneIdCtrl,
                    onChanged: (_) => _resetVerification(),
                    decoration: InputDecoration(labelText: AppLocalizations.t('zone_id'), border: const OutlineInputBorder()),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _RevealIn(
                index: 2,
                child: OutlinedButton.icon(
                  onPressed: _verifying ? null : _verify,
                  icon: _verifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.verified_user_outlined),
                  label: Text(_verifying ? AppLocalizations.t('verifying') : AppLocalizations.t('verify_id')),
                ),
              ),
              if (_verifyError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_verifyError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              if (_verified && _verifiedName != null)
                AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${AppLocalizations.t('account_found')}: $_verifiedName',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              Text(AppLocalizations.t('select_package'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              if (_loadingPackages)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_packages.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(AppLocalizations.t('no_packages_available'), style: const TextStyle(color: AppColors.hint)),
                )
              else
                ...List.generate(_packages.length, (i) {
                  final p = _packages[i] as Map;
                  final selected = _selectedPackageId == p['id'];
                  return _RevealIn(
                    index: 3 + i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selectedPackageId = p['id'] as int),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: selected ? AppColors.primary : AppColors.hint, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('${p['name'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                ),
                                Text('LKR ${(p['price'] as num).toStringAsFixed(2)}',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _canContinue ? _openPayment : null,
                child: Text(AppLocalizations.t('continue_to_payment')),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================= 3. PAYMENT SHEET =======================

class _PaymentSheet extends StatefulWidget {
  final int gameId;
  final int packageId;
  final String packageName;
  final double price;
  final String playerId;
  final String? zoneId;

  const _PaymentSheet({
    required this.gameId,
    required this.packageId,
    required this.packageName,
    required this.price,
    required this.playerId,
    required this.zoneId,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  double? _walletBalance;
  bool _loadingBalance = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final b = await ApiService.getWalletBalance();
      if (mounted) setState(() => _walletBalance = b);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingBalance = false);
    }
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('payment_method_coming_soon'))));
  }

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await ApiService.submitTopupOrder(
        gameId: widget.gameId,
        packageId: widget.packageId,
        playerId: widget.playerId,
        zoneId: widget.zoneId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('topup_order_placed'))));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!mounted) return;
      if (msg.toLowerCase().contains('insufficient')) {
        Navigator.pop(context, false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(AppLocalizations.t('insufficient_balance_title'), style: const TextStyle(color: Colors.white)),
            content: Text(AppLocalizations.t('insufficient_balance_message'), style: const TextStyle(color: AppColors.hint)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'))),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                },
                child: Text(AppLocalizations.t('top_up_wallet')),
              ),
            ],
          ),
        );
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enough = _walletBalance != null && _walletBalance! >= widget.price;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.t('payment_method'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 4),
            Text('${widget.packageName} · LKR ${widget.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.hint, fontSize: 13)),
            const SizedBox(height: 18),
            _PayMethodTile(
              icon: Icons.account_balance_wallet_outlined,
              title: AppLocalizations.t('wallet'),
              subtitle: _loadingBalance
                  ? AppLocalizations.t('loading')
                  : 'LKR ${(_walletBalance ?? 0).toStringAsFixed(2)}',
              enabled: true,
              warn: !_loadingBalance && !enough,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _PayMethodTile(
              icon: Icons.credit_card_outlined,
              title: AppLocalizations.t('card_payment'),
              subtitle: AppLocalizations.t('coming_soon'),
              enabled: false,
              warn: false,
              onTap: _comingSoon,
            ),
            const SizedBox(height: 10),
            _PayMethodTile(
              icon: Icons.qr_code_scanner_outlined,
              title: AppLocalizations.t('other_payment'),
              subtitle: AppLocalizations.t('coming_soon'),
              enabled: false,
              warn: false,
              onTap: _comingSoon,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: (_paying || _loadingBalance) ? null : _pay,
              child: _paying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.t('pay_now')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool warn;
  final VoidCallback onTap;
  const _PayMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.warn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: warn ? Colors.orangeAccent.withOpacity(0.6) : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: enabled ? AppColors.primary : AppColors.hint, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(subtitle, style: TextStyle(color: warn ? Colors.orangeAccent : AppColors.hint, fontSize: 12)),
                    ],
                  ),
                ),
                if (enabled) const Icon(Icons.chevron_right, color: AppColors.hint, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
