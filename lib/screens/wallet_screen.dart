import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/safe_picker.dart';
import '../widgets/anim.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_sales_screen.dart';
import 'wallet_bank_details_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0;
  double _pendingAmount = 0;
  DateTime? _nextReleaseAt;
  List<dynamic> _transactions = [];
  bool _loading = true;
  bool _isGuest = false;
  String? _error;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _checkLoginThenLoad();
  }

  Future<void> _checkLoginThenLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!isLoggedIn) {
      setState(() {
        _isGuest = true;
        _loading = false;
      });
      return;
    }
    _load();
  }

  Future<bool> _ensureLoggedIn({String? reason}) async {
    if (!_isGuest) return true;
    final loggedIn = await requireLogin(context, reason: reason);
    if (loggedIn) {
      setState(() => _isGuest = false);
      _load();
    }
    return loggedIn;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final balance = await ApiService.getWalletBalance();
      final transactions = await ApiService.getTransactions();
      final sales = await ApiService.getMySales();

      double pending = 0;
      DateTime? earliestRelease;
      for (final s in sales) {
        if (s['status'] == 'escrow_held') {
          pending += (s['sellerPayout'] as num?)?.toDouble() ?? 0;
          if (s['escrowReleaseAt'] != null) {
            final releaseAt = DateTime.parse(s['escrowReleaseAt']).toLocal();
            if (earliestRelease == null || releaseAt.isBefore(earliestRelease)) {
              earliestRelease = releaseAt;
            }
          }
        }
      }

      setState(() {
        _balance = balance;
        _transactions = transactions;
        _pendingAmount = pending;
        _nextReleaseAt = earliestRelease;
        _loading = false;
      });
      _startCountdown();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    if (_nextReleaseAt == null) return;
    void tick() {
      final diff = _nextReleaseAt!.difference(DateTime.now());
      if (mounted) setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
    tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return 'Releasing soon';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('my_wallet'))),
          body: Container(
            color: AppColors.bg,
            width: double.infinity,
            height: double.infinity,
            child: _isGuest
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.t('available_colon'), style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                              const SizedBox(height: 6),
                              const Text('LKR --', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (await _ensureLoggedIn(reason: 'Login to top up your wallet')) _showTopUpSheet(context);
                                },
                                child: Text(AppLocalizations.t('top_up')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  if (await _ensureLoggedIn(reason: 'Login to withdraw funds')) _showWithdrawSheet(context, 0);
                                },
                                child: Text(AppLocalizations.t('withdraw')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              OutlinedButton(onPressed: _load, child: Text(AppLocalizations.t('retry'))),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF4A2FD6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.t('available_balance'), style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                                  const SizedBox(height: 6),
                                  CountUpText(value: _balance, prefix: 'LKR ', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),

                            if (_pendingAmount > 0) ...[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MySalesScreen()));
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.hourglass_top_outlined, color: Colors.orangeAccent, size: 28),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Pending: LKR ${_pendingAmount.toStringAsFixed(2)}',
                                                style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                                            const SizedBox(height: 2),
                                            if (_nextReleaseAt != null)
                                              Text('Next release in ${_formatDuration(_remaining)}',
                                                  style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: AppColors.hint),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showTopUpSheet(context),
                                    icon: const Icon(Icons.add_circle_outline),
                                    label: Text(AppLocalizations.t('top_up')),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showWithdrawSheet(context, _balance),
                                    icon: const Icon(Icons.arrow_circle_up_outlined),
                                    label: Text(AppLocalizations.t('withdraw')),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(AppLocalizations.t('transaction_history'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                            const SizedBox(height: 8),
                            if (_transactions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                child: Center(child: Text(AppLocalizations.t('no_transactions'), style: const TextStyle(color: AppColors.hint))),
                              )
                            else
                              ..._transactions.map((tx) => _TransactionTile(
                                    id: tx['id'],
                                    type: tx['type'] ?? 'unknown',
                                    amount: (tx['amount'] as num?)?.toDouble() ?? 0,
                                    status: tx['status'] ?? 'pending',
                                    createdAt: tx['createdAt'],
                                  )),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  void _showTopUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.t('top_up_wallet'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                title: const Text('Bank Transfer', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Upload a payment slip, reviewed by our team', style: TextStyle(color: AppColors.hint, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBankTopUpSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.currency_bitcoin, color: Colors.amber),
                title: const Text('Binance (USDT)', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Instant, converted at the current rate', style: TextStyle(color: AppColors.hint, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surface,
                    builder: (_) => _BinanceDepositSheet(onDone: _load),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankTopUpSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    final referenceCtrl = TextEditingController();
    XFile? slipFile;
    bool submitting = false;
    bool loadingMethods = true;
    List<dynamic> methods = [];
    Map<String, dynamic>? selectedMethod;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (loadingMethods) {
            ApiService.getDepositMethods().then((data) {
              setModalState(() {
                methods = data;
                loadingMethods = false;
              });
            }).catchError((e) {
              setModalState(() {
                sheetError = e.toString().replaceFirst('Exception: ', '');
                loadingMethods = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.t('top_up_wallet'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  if (loadingMethods)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary)))
                  else if (methods.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Text(
                        AppLocalizations.t('no_deposit_methods'),
                        style: TextStyle(color: AppColors.hint, fontSize: 13),
                      ),
                    )
                  else ...[
                    Text(AppLocalizations.t('select_deposit_method'), style: const TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: methods.map<Widget>((m) {
                        final selected = selectedMethod != null && selectedMethod!['id'] == m['id'];
                        return InkWell(
                          onTap: () => setModalState(() => selectedMethod = m),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.fieldFill,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: m['iconUrl'] != null ? NetworkImage(m['iconUrl']) : null,
                                  child: m['iconUrl'] == null ? const Icon(Icons.account_balance, size: 14, color: AppColors.hint) : null,
                                ),
                                const SizedBox(width: 6),
                                Text(m['displayName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (selectedMethod != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedMethod!['accountName'] != null && selectedMethod!['accountName'].toString().isNotEmpty)
                              Text("${AppLocalizations.t('account_name_colon')} ${selectedMethod!['accountName']}", style: const TextStyle(color: Colors.white, fontSize: 13)),
                            if (selectedMethod!['accountNumber'] != null && selectedMethod!['accountNumber'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text("${AppLocalizations.t('account_wallet_number_colon')} ${selectedMethod!['accountNumber']}", style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                            if (selectedMethod!['branch'] != null && selectedMethod!['branch'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text("${AppLocalizations.t('branch_colon')} ${selectedMethod!['branch']}", style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                            if (selectedMethod!['extraInfo'] != null && selectedMethod!['extraInfo'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('${selectedMethod!['extraInfo']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('amount_lkr')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: referenceCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('transaction_reference_number')),
                  ),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.t('upload_bank_slip'), style: const TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImageSafe(source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        setModalState(() => slipFile = picked);
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.fieldFill, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                      child: slipFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(slipFile!.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                  : Image.file(File(slipFile!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.upload_file_outlined, color: AppColors.hint, size: 28),
                                const SizedBox(height: 6),
                                Text(AppLocalizations.t('tap_upload_slip'), style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  if (sheetError != null) ...[
                    const SizedBox(height: 10),
                    Text(sheetError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: submitting || methods.isEmpty ? null : () async {
                        final amount = double.tryParse(amountCtrl.text.trim());
                        final referenceNumber = referenceCtrl.text.trim();
                        if (selectedMethod == null) {
                          setModalState(() => sheetError = 'Please select a deposit method');
                          return;
                        }
                        if (amount == null || amount <= 0) {
                          setModalState(() => sheetError = 'Enter a valid amount');
                          return;
                        }
                        if (referenceNumber.isEmpty) {
                          setModalState(() => sheetError = 'Enter the transaction reference number');
                          return;
                        }
                        if (slipFile == null) {
                          setModalState(() => sheetError = 'Please upload your payment slip');
                          return;
                        }
                        setModalState(() {
                          submitting = true;
                          sheetError = null;
                        });
                        try {
                          final slipUrl = await ApiService.uploadImage(slipFile!);
                          await ApiService.requestTopUp(amount, slipUrl, referenceNumber);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Top-up request submitted')));
                          _load();
                        } catch (e) {
                          setModalState(() {
                            submitting = false;
                            sheetError = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      },
                      child: submitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(AppLocalizations.t('submit_topup')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _showWithdrawSheet(BuildContext context, double balance) {
    final amountCtrl = TextEditingController();
    bool submitting = false;
    const withdrawalFee = 30.0;
    const minWithdrawal = 500.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.t('withdraw_to_bank'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('${AppLocalizations.t('available_colon')} ${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.hint)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: AppLocalizations.t('amount_lkr')),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  AppLocalizations.t('withdrawal_min_fee_note'),
                  style: TextStyle(fontSize: 12, color: AppColors.hint),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure your bank details are saved in Settings → Wallet & Bank Details before withdrawing. '
                'The amount will be deducted from your wallet immediately and refunded if the request is rejected.',
                style: TextStyle(fontSize: 12, color: AppColors.hint),
              ),
              if (balance < minWithdrawal + withdrawalFee) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                  ),
                  child: Text(
                    "${AppLocalizations.t('insufficient_balance')} ${AppLocalizations.t('you_need_at_least')} LKR ${(minWithdrawal + withdrawalFee).toStringAsFixed(2)} (LKR 500 minimum + LKR 30 fee) ${AppLocalizations.t('to_withdraw_current_balance')} LKR ${balance.toStringAsFixed(2)}.",
                    style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                      return;
                    }
                    if (amount < minWithdrawal) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Minimum withdrawal amount is LKR 500')));
                      return;
                    }
                    if (amount + withdrawalFee > balance) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Amount + LKR 30 fee (LKR ${(amount + withdrawalFee).toStringAsFixed(2)}) exceeds your available balance')));
                      return;
                    }
                    setModalState(() => submitting = true);
                    try {
                      final profile = await ApiService.getProfile();
                      final accountNumber = (profile['bankAccountNumber'] ?? '').toString().trim();
                      if (accountNumber.isEmpty) {
                        if (!ctx.mounted) return;
                        setModalState(() => submitting = false);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please add your bank account details first')),
                        );
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletBankDetailsScreen()));
                        if (mounted) _load();
                        return;
                      }

                      await ApiService.requestWithdrawal(amount);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted')));
                      _load();
                    } catch (e) {
                      setModalState(() => submitting = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                    }
                  },
                  child: submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(AppLocalizations.t('request_withdrawal')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TransactionTile extends StatelessWidget {
  final int? id;
  final String type;
  final double amount;
  final String status;
  final String? createdAt;

  const _TransactionTile({this.id, required this.type, required this.amount, required this.status, this.createdAt});

  Map<String, dynamic> get _display {
    switch (type) {
      case 'topup':
        return {'label': 'Wallet Top-Up', 'icon': Icons.add_circle_outline};
      case 'withdrawal':
        return {'label': 'Withdrawal', 'icon': Icons.arrow_circle_up_outlined};
      case 'sale_release':
        return {'label': 'Account Sale', 'icon': Icons.sell_outlined};
      case 'commission':
        return {'label': 'Platform Commission', 'icon': Icons.percent};
      case 'referral_bonus':
        return {'label': 'Referral Bonus', 'icon': Icons.card_giftcard};
      case 'purchase_hold':
        return {'label': 'Purchase (Escrow)', 'icon': Icons.lock_clock_outlined};
      case 'bid_hold':
        return {'label': 'Bid Held', 'icon': Icons.gavel_outlined};
      case 'bid_refund':
        return {'label': 'Bid Refunded', 'icon': Icons.replay_outlined};
      case 'installment_payment':
        return {
          'label': AppLocalizations.t('installment_payment_label'),
          'icon': Icons.calendar_month_outlined
        };
      default:
        return {'label': type, 'icon': Icons.receipt_long_outlined};
    }
  }

  Color _statusColor() {
    switch (status) {
      case 'completed': return Colors.greenAccent;
      case 'failed': return Colors.redAccent;
      default: return Colors.orangeAccent;
    }
  }

  String get _txCode {
    if (id == null) return 'MG-000000';
    return 'MG-${id.toString().padLeft(6, '0')}';
  }

  void _showDetails(BuildContext context) {
    final d = _display;
    String dateStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt!).toLocal();
        dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(d['label'] as String, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Transaction ID', _txCode),
            _detailRow('Amount', 'LKR ${amount.toStringAsFixed(2)}'),
            _detailRow('Status', status),
            if (dateStr.isNotEmpty) _detailRow('Date', dateStr),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.hint, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _display;
    final positive = amount >= 0;
    final color = positive ? Colors.greenAccent : Colors.redAccent;
    return ListTile(
      onTap: () => _showDetails(context),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(d['icon'] as IconData, color: color, size: 20),
      ),
      title: Text(d['label'] as String, style: const TextStyle(color: Colors.white)),
      subtitle: Text('$_txCode · $status', style: TextStyle(color: _statusColor(), fontSize: 12)),
      trailing: Text('${positive ? '+' : ''} LKR ${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    );
  }
}


// ======================= Binance (USDT) top up =======================

class _BinanceDepositSheet extends StatefulWidget {
  final VoidCallback onDone;
  const _BinanceDepositSheet({required this.onDone});

  @override
  State<_BinanceDepositSheet> createState() => _BinanceDepositSheetState();
}

class _BinanceDepositSheetState extends State<_BinanceDepositSheet> {
  final _usdtCtrl = TextEditingController();
  final _orderIdCtrl = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _loadError;
  String? _formError;
  Map<String, dynamic>? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usdtCtrl.dispose();
    _orderIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await ApiService.getBinanceDepositInfo();
      if (!mounted) return;
      setState(() {
        _info = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  double get _rate => double.tryParse('${_info?['rate'] ?? 0}') ?? 0;
  double get _feePercent => double.tryParse('${_info?['feePercent'] ?? 0}') ?? 0;

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<void> _submit() async {
    final orderId = _orderIdCtrl.text.trim();
    if (orderId.isEmpty) {
      setState(() => _formError = 'Enter the Order ID from Binance');
      return;
    }
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      final r = await ApiService.verifyBinanceDeposit(orderId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['message'] ?? 'Deposit confirmed'}')));
      widget.onDone();
    } catch (e) {
      setState(() {
        _submitting = false;
        _formError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top up with Binance (USDT)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_loadError != null)
              Text(_loadError!, style: const TextStyle(color: Colors.redAccent))
            else if (_info?['enabled'] != true)
              const Text('Binance deposits are not available right now. Please use Bank Transfer.', style: TextStyle(color: AppColors.hint))
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Send USDT to this Binance Pay ID', style: TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text('${_info!['binanceId']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.primary, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${_info!['binanceId']}'));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Binance ID copied')));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Rate: 1 USDT = LKR ${_fmt(_rate)}${_feePercent > 0 ? ' (fee ${_fmt(_feePercent)}%)' : ''}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    Text('Minimum: ${_info!['minUsdt']} USDT', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                    if ('${_info!['note'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('${_info!['note']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Estimate how much you will receive (optional)', style: TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _usdtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Amount you sent (USDT)'),
              ),
              if ((double.tryParse(_usdtCtrl.text.trim()) ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'You will receive about LKR ${_fmt((double.tryParse(_usdtCtrl.text.trim()) ?? 0) * _rate * (1 - _feePercent / 100))}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('2. After sending, enter the Order ID shown in Binance', style: TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _orderIdCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Binance Order ID'),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 10),
                Text(_formError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Continue'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
