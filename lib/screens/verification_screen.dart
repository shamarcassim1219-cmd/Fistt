import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/api_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _loadingStatus = true;
  String _verifiedStatus = 'not_verified';
  String? _documentType;
  String? _statusLoadError;
  String? _authToken;
  bool _webViewLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await ApiService.getVerificationStatusFull();
      final token = await ApiService.getToken();
      setState(() {
        _verifiedStatus = data['verifiedStatus'] ?? 'not_verified';
        _documentType = data['documentType'];
        _authToken = token;
        _loadingStatus = false;
        _statusLoadError = null;
      });
    } catch (e) {
      setState(() {
        _loadingStatus = false;
        _statusLoadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _docTypeLabel(String? docType) {
    switch (docType) {
      case 'driving_license':
        return 'driving license';
      case 'passport':
        return 'passport';
      default:
        return 'NIC';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Get Verified')),
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_statusLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load verification status', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_statusLoadError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  setState(() => _loadingStatus = true);
                  _loadStatus();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_verifiedStatus == 'pending') {
      return _StatusMessage(
        icon: Icons.hourglass_top_outlined,
        color: Colors.orangeAccent,
        title: 'Verification Pending',
        message: 'Your ${_docTypeLabel(_documentType)} verification is under review. '
            'This usually takes 1-2 business days.',
      );
    }

    if (_verifiedStatus == 'verified') {
      return _StatusMessage(
        icon: Icons.verified,
        color: AppColors.primary,
        title: 'Verified Seller',
        message: 'Your account is verified. You now have the blue checkmark badge.',
      );
    }

    if (_authToken == null) {
      return const Center(
        child: Text('Please log in again to continue', style: TextStyle(color: Colors.redAccent)),
      );
    }

    final verifyUrl = 'https://buysellgame.store/verify/?token=$_authToken';

    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.primary, size: 56),
              const SizedBox(height: 20),
              const Text('Complete Verification', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Verification opens in a new tab so we can access your camera. Once you submit, come back here and tap Refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.hint, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(verifyUrl), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Verification'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _loadingStatus = true);
                    _loadStatus();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Status'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _webViewLoading = false);
          },
        ),
      )
      ..addJavaScriptChannel(
        'VerificationChannel',
        onMessageReceived: (message) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification submitted')),
            );
          }
        },
      )
      ..loadRequest(Uri.parse(verifyUrl));

    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_webViewLoading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _StatusMessage({required this.icon, required this.color, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 64),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.hint, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
