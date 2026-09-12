import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_sales_screen.dart';

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

  Future<void> _loginAndLoad() async {
    if (await requireLogin(context)) {
      setState(() => _isGuest = false);
      _load();
    }
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.hint, size: 48),
                          const SizedBox(height: 12),
                          Text(AppLocalizations.t('login_to_continue'), style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loginAndLoad, child: Text(AppLocalizations.t('login'))),
                        ],
                      ),
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
                                  Text('LKR ${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
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
                                    type: tx['type'] ?? 'unknown',
                                    amount: (tx['amount'] as num?)?.toDouble() ?? 0,
                                    status: tx['status'] ?? 'pending',
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
    final amountCtrl = TextEditingController();
    final referenceCtrl = TextEditingController();
    File? slipFile;
    bool submitting = false;
    bool loadingBankDetails = true;
    Map<String, dynamic>? bankDetails;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (loadingBankDetails) {
            ApiService.getAdminBankDetails().then((data) {
              setModalState(() {
                bankDetails = data;
                loadingBankDetails = false;
              });
            }).catchError((e) {
              setModalState(() {
                sheetError = e.toString().replaceFirst('Exception: ', '');
                loadingBankDetails = false;
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
                  if (loadingBankDetails)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary)))
                  else if (bankDetails != null) ...[
                    Text(AppLocalizations.t('deposit_to_account'), style: const TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bank: ${bankDetails!['bankName']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Account Name: ${bankDetails!['accountName']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Account Number: ${bankDetails!['accountNumber']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Branch: ${bankDetails!['branch']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
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
                    decoration: const InputDecoration(labelText: 'Bank Transfer Reference Number'),
                  ),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.t('upload_bank_slip'), style: const TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        setModalState(() => slipFile = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.fieldFill, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                      child: slipFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(slipFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
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
                      onPressed: submitting ? null : () async {
                        final amount = double.tryParse(amountCtrl.text.trim());
                        final referenceNumber = referenceCtrl.text.trim();
                        if (amount == null || amount <= 0) {
                          setModalState(() => sheetError = 'Enter a valid amount');
                          return;
                        }
                        if (referenceNumber.isEmpty) {
                          setModalState(() => sheetError = 'Enter the bank transfer reference number');
                          return;
                        }
                        if (slipFile == null) {
                          setModalState(() => sheetError = 'Please upload your bank slip');
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
              const SizedBox(height: 12),
              const Text(
                'Make sure your bank details are saved in Settings → Wallet & Bank Details before withdrawing. '
                'The amount will be deducted from your wallet immediately and refunded if the request is rejected.',
                style: TextStyle(fontSize: 12, color: AppColors.hint),
              ),
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
                    if (amount > balance) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Amount exceeds your available balance')));
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
                          const SnackBar(content: Text('Please add your bank account details first (Settings → Wallet & Bank Details)')),
                        );
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
  final String type;
  final double amount;
  final String status;

  const _TransactionTile({required this.type, required this.amount, required this.status});

  Map<String, dynamic> get _display {
    switch (type) {
      case 'topup': return {'label': 'Wallet Top-Up', 'icon': Icons.add_circle_outline};
      case 'withdrawal': return {'label': 'Withdrawal', 'icon': Icons.arrow_circle_up_outlined};
      case 'sale_release': return {'label': 'Account Sale', 'icon': Icons.sell_outlined};
      case 'commission': return {'label': 'Platform Commission', 'icon': Icons.percent};
      case 'referral_bonus': return {'label': 'Referral Bonus', 'icon': Icons.card_giftcard};
      case 'purchase_hold': return {'label': 'Purchase (Escrow)', 'icon': Icons.lock_clock_outlined};
      case 'bid_hold': return {'label': 'Bid Held', 'icon': Icons.gavel_outlined};
      case 'bid_refund': return {'label': 'Bid Refunded', 'icon': Icons.replay_outlined};
      default: return {'label': type, 'icon': Icons.receipt_long};
    }
  }

  Color _statusColor() {
    switch (status) {
      case 'completed': return Colors.greenAccent;
      case 'failed': return Colors.redAccent;
      default: return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _display;
    final positive = amount >= 0;
    final color = positive ? Colors.greenAccent : Colors.redAccent;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(d['icon'] as IconData, color: color, size: 20),
      ),
      title: Text(d['label'] as String, style: const TextStyle(color: Colors.white)),
      subtitle: Text(status, style: TextStyle(color: _statusColor(), fontSize: 12)),
      trailing: Text('${positive ? '+' : ''} LKR ${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    );
  }
}
