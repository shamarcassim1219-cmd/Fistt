import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import 'otp_verify_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isRegister) {
        await ApiService.register(_emailCtrl.text.trim(), _passCtrl.text.trim(), _displayNameCtrl.text.trim());
      } else {
        await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            email: _emailCtrl.text.trim(),
            purpose: _isRegister ? 'register' : 'login',
            referralCode: _isRegister ? _referralCtrl.text.trim() : null,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '354593690287-4snsdmlt1ij5q7a1grbadb28b5g5nm67.apps.googleusercontent.com' : null,
        serverClientId: kIsWeb ? null : '354593690287-4snsdmlt1ij5q7a1grbadb28b5g5nm67.apps.googleusercontent.com',
      );

      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _googleLoading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      await ApiService.googleSignIn(idToken);

      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) await ApiService.saveFcmToken(fcmToken);
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _comingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sign-in coming soon')),
    );
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _error = null;
      _emailCtrl.clear();
      _passCtrl.clear();
      _referralCtrl.clear();
      _displayNameCtrl.clear();
    });
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.hint, size: 20),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        initialValue: lang,
                        color: AppColors.surface,
                        onSelected: (choice) => AppLocalizations.setLanguage(choice),
                        itemBuilder: (ctx) => ['English', 'Sinhala', 'Tamil']
                            .map((l) => PopupMenuItem(
                                  value: l,
                                  child: Text(l, style: const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language, size: 16, color: AppColors.hint),
                              const SizedBox(width: 6),
                              Text(lang, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.hint),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) {
                        final offsetAnim = Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: offsetAnim, child: child),
                        );
                      },
                      child: Column(
                        key: ValueKey(_isRegister),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRegister ? AppLocalizations.t('create_account') : AppLocalizations.t('welcome_back'),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isRegister ? AppLocalizations.t('sign_up_to_get_started') : AppLocalizations.t('login_to_continue'),
                            style: const TextStyle(color: AppColors.hint, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isRegister
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: _displayNameCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldDecoration(hint: 'Display Name', icon: Icons.badge_outlined),
                                validator: (v) => _isRegister && (v == null || v.trim().isEmpty) ? 'Enter a display name' : null,
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration(hint: AppLocalizations.t('email'), icon: Icons.mail_outline),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration(
                        hint: AppLocalizations.t('password'),
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.hint, size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isRegister
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextFormField(
                                controller: _referralCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldDecoration(hint: 'Referral Code (optional)', icon: Icons.card_giftcard_outlined),
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: !_isRegister
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                                child: Text(AppLocalizations.t('forgot_password'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ],

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  _isRegister ? AppLocalizations.t('sign_up') : AppLocalizations.t('login'),
                                  key: ValueKey(_isRegister),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or continue with', style: TextStyle(color: AppColors.hint, fontSize: 13)),
                        ),
                        const Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _googleLoading ? null : _handleGoogleSignIn,
                        icon: _googleLoading
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        label: const Text('Continue with Google', style: TextStyle(color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 28),
                    Center(
                      child: TextButton(
                        onPressed: _toggleMode,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                          child: RichText(
                            key: ValueKey(_isRegister),
                            text: TextSpan(
                              style: const TextStyle(color: AppColors.hint, fontSize: 14),
                              children: [
                                TextSpan(text: _isRegister ? AppLocalizations.t('already_have_account') : AppLocalizations.t('dont_have_account')),
                                TextSpan(
                                  text: _isRegister ? AppLocalizations.t('login') : AppLocalizations.t('sign_up'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 28),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://buysellgame.store/downloads/app-release.apk'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.android, color: AppColors.primary),
                          label: const Text('Download Android App', style: TextStyle(color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
