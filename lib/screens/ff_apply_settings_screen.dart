import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';

/// Free Fire package names (update if they change).
const _freeFirePackage = 'com.dts.freefireth';
const _freeFireMaxPackage = 'com.dts.freefiremax';

/// Shown after the user has seen their recommended sensitivity/DPI/graphics
/// settings (from GameTunerScreen's _PhoneSettingsScreen) and is ready to
/// go apply them in-game. Walks: optimize network -> close background apps
/// -> confirm -> auto-launch Free Fire / Free Fire Max.
class FfApplySettingsScreen extends StatefulWidget {
  const FfApplySettingsScreen({super.key});

  @override
  State<FfApplySettingsScreen> createState() => _FfApplySettingsScreenState();
}

class _FfApplySettingsScreenState extends State<FfApplySettingsScreen> {
  int _step = 0;
  bool _networkOptimized = false;
  bool _appsClosed = false;

  Future<void> _optimizeNetwork() async {
    // TODO: hook this up to your existing network-optimize logic if you have one.
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _networkOptimized = true;
      _step = 1;
    });
  }

  Future<void> _closeBackgroundApps() async {
    // TODO: hook this up to your existing "close background apps" logic if you have one.
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _appsClosed = true;
      _step = 2;
    });
  }

  Future<void> _confirmAndLaunch() async {
    final ready = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settings Apply කරලා ඉවරද?'),
        content: const Text(
          'Free Fire settings වලට ගිහින් recommended values දාලා ඉවර නම් "ඔව්" ගහන්න.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('නෑ, තව ටිකක් ඕන'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ඔව්, Ready'),
          ),
        ],
      ),
    );
    if (ready == true) {
      await _launchFreeFire();
    }
  }

  Future<void> _launchFreeFire() async {
    for (final pkg in [_freeFireMaxPackage, _freeFirePackage]) {
      try {
        final intent = AndroidIntent(
          action: 'action_main',
          package: pkg,
          componentName: '$pkg.MainActivity',
          flags: <int>[0x10000000], // FLAG_ACTIVITY_NEW_TASK
        );
        await intent.launch();
        return;
      } catch (_) {
        continue;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Free Fire install වෙලා නෑ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Settings')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_step == 0) ...[
                const Icon(Icons.wifi_tethering, size: 48),
                const SizedBox(height: 16),
                const Text('Network Optimize කරමු'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _optimizeNetwork,
                  child: const Text('Optimize Network'),
                ),
              ] else if (_step == 1) ...[
                const Icon(Icons.close_fullscreen, size: 48),
                const SizedBox(height: 16),
                const Text('Background Apps Close කරමු'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _closeBackgroundApps,
                  child: const Text('Close Background Apps'),
                ),
              ] else ...[
                const Icon(Icons.sports_esports, size: 48),
                const SizedBox(height: 16),
                const Text('ඉවරයි! Free Fire Open කරමු'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _confirmAndLaunch,
                  child: const Text('Free Fire Open කරමු'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
