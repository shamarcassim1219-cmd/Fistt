import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'spin_wheel_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _loading = true;
  String? _error;
  int _points = 0;
  List<dynamic> _rewards = [];
  List<dynamic> _coupons = [];
  int? _redeemingId;

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
      final results = await Future.wait([
        ApiService.getReferralPoints(),
        ApiService.getRewards(),
        ApiService.getMyCoupons(),
      ]);
      if (!mounted) return;
      setState(() {
        _points = results[0] as int;
        _rewards = results[1] as List<dynamic>;
        _coupons = results[2] as List<dynamic>;
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

  Future<void> _redeem(Map<String, dynamic> reward) async {
    final id = reward['id'] as int;
    setState(() => _redeemingId = id);
    try {
      final result = await ApiService.redeemReward(id);
      if (!mounted) return;
      String msg;
      if (result['type'] == 'discount_coupon') {
        msg = 'Coupon code ${result['code']} added to My Coupons.';
      } else {
        msg = 'Rs ${result['cashbackAmount']} added to your wallet.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _redeemingId = null);
    }
  }

  void _copyCoupon(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon code: $code')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Rewards'), backgroundColor: AppColors.bg),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF3A1A6B)]),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Your Points', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('$_points', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          icon: const Text('🎡', style: TextStyle(fontSize: 18)),
                          label: const Text('Spin the Wheel', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const SpinWheelScreen()));
                            _load();
                          },
                        ),
                      ),
                      if (_coupons.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('My Coupons', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ..._coupons.map((c) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${c['discount_percent']}% OFF',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('Code: ${c['code']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: AppColors.hint, size: 18),
                                    onPressed: () => _copyCoupon(c['code'].toString()),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 24),
                      const Text('Redeem with Points', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (_rewards.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No rewards available right now. Check back soon!', style: TextStyle(color: AppColors.hint)),
                        )
                      else
                        ..._rewards.map((r) {
                          final cost = r['points_cost'] as int;
                          final canAfford = _points >= cost;
                          final isDiscount = r['type'] == 'discount_coupon';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r['title'].toString(),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(
                                        isDiscount
                                            ? '${r['discount_percent']}% off a purchase'
                                            : 'Rs ${r['cashback_amount']} cashback',
                                        style: const TextStyle(color: AppColors.hint, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canAfford ? AppColors.primary : AppColors.fieldFill,
                                  ),
                                  onPressed: (canAfford && _redeemingId == null) ? () => _redeem(r) : null,
                                  child: _redeemingId == r['id']
                                      ? const SizedBox(
                                          height: 16, width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Text('$cost pts'),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
