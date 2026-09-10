import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../services/games_list.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedGame;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _uidCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final Map<String, TextEditingController> _statControllers = {};
  final List<String> _customStatKeys = [];

  static const List<String> _platforms = [
    'iCloud', 'Facebook', 'Google', 'Twitter', 'Other',
  ];
  String _selectedPlatform = 'Google';

  final _vaultEmailCtrl = TextEditingController();
  final _vaultPasswordCtrl = TextEditingController();
  final _vaultRecoveryCtrl = TextEditingController();

  final List<File> _screenshots = [];
  bool _submitting = false;
  bool _allowBidding = false;
  String? _error;

  bool _loadingVerification = true;
  String _verifiedStatus = 'not_verified';

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  @override
  void dispose() {
    for (final c in _statControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkVerification() async {
    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _verifiedStatus = profile['verifiedStatus'] ?? 'not_verified';
        _loadingVerification = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingVerification = false);
    }
  }

  void _onGameSelected(String game) {
    setState(() {
      _selectedGame = game;
      for (final c in _statControllers.values) {
        c.dispose();
      }
      _statControllers.clear();
      _customStatKeys.clear();
    });
  }

  void _addStatField(String key) {
    if (_statControllers.containsKey(key)) return;
    setState(() {
      _statControllers[key] = TextEditingController();
      if (!GamesList.suggestedStatsFor(_selectedGame ?? '').contains(key)) {
        _customStatKeys.add(key);
      }
    });
  }

  void _removeStatField(String key) {
    setState(() {
      _statControllers[key]?.dispose();
      _statControllers.remove(key);
      _customStatKeys.remove(key);
    });
  }

  void _showAddCustomStatDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(AppLocalizations.t('custom_stat'), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'e.g. Prestige Level'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                _addStatField(ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickScreenshots() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _screenshots.addAll(picked.map((x) => File(x.path)));
        if (_screenshots.length > 6) {
          _screenshots.removeRange(6, _screenshots.length);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  Future<List<String>> _uploadScreenshots() async {
    final urls = <String>[];
    for (final file in _screenshots) {
      final url = await ApiService.uploadImage(file);
      urls.add(url);
    }
    return urls;
  }

  Future<void> _resetForm() async {
    _titleCtrl.clear();
    _descCtrl.clear();
    _uidCtrl.clear();
    _priceCtrl.clear();
    _vaultEmailCtrl.clear();
    _vaultPasswordCtrl.clear();
    _vaultRecoveryCtrl.clear();
    for (final c in _statControllers.values) {
      c.dispose();
    }
    if (mounted) {
      setState(() {
        _screenshots.clear();
        _allowBidding = false;
        _selectedGame = null;
        _selectedPlatform = 'Google';
        _statControllers.clear();
        _customStatKeys.clear();
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGame == null) {
      setState(() => _error = 'Please select a game');
      return;
    }
    if (_screenshots.isEmpty) {
      setState(() => _error = 'Add at least one screenshot');
      return;
    }
    if (_vaultEmailCtrl.text.trim().isEmpty || _vaultPasswordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Account email & password are required for the vault');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final screenshotUrls = await _uploadScreenshots();

      final stats = <String, String>{};
      _statControllers.forEach((key, ctrl) {
        if (ctrl.text.trim().isNotEmpty) stats[key] = ctrl.text.trim();
      });

      await ApiService.createListing(
        game: _selectedGame!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        inGameUID: _uidCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        screenshots: screenshotUrls,
        stats: stats,
        vaultPlatform: _selectedPlatform,
        vaultEmail: _vaultEmailCtrl.text.trim(),
        vaultPassword: _vaultPasswordCtrl.text.trim(),
        vaultRecoveryCodes: _vaultRecoveryCtrl.text.trim(),
        allowBidding: _allowBidding,
      );

      if (!mounted) return;

      await _resetForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing posted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showGameSelector() {
    final searchCtrl = TextEditingController();
    List<String> filtered = List.from(GamesList.games);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                const Text('Select Game', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search games...',
                    prefixIcon: Icon(Icons.search, color: AppColors.hint),
                  ),
                  onChanged: (v) {
                    setModalState(() {
                      filtered = GamesList.games.where((g) => g.toLowerCase().contains(v.toLowerCase())).toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final g = filtered[i];
                      return ListTile(
                        title: Text(g, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: _selectedGame == g ? const Icon(Icons.check, color: AppColors.primary) : null,
                        onTap: () {
                          _onGameSelected(g);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
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
        if (_loadingVerification) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (_verifiedStatus != 'verified') {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(title: Text(AppLocalizations.t('sell_an_account'))),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_outlined, color: AppColors.hint, size: 64),
                    const SizedBox(height: 20),
                    Text(AppLocalizations.t('verification_required'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      _verifiedStatus == 'pending'
                          ? 'Your verification is under review. You can post listings once approved.'
                          : 'Only verified sellers can post listings. Go to Settings to get verified.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.hint, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final suggestedStats = _selectedGame != null ? GamesList.suggestedStatsFor(_selectedGame!) : <String>[];
        final availableSuggestions = suggestedStats.where((s) => !_statControllers.containsKey(s)).toList();

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('sell_an_account'))),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionLabel(AppLocalizations.t('game')),
                  InkWell(
                    onTap: _showGameSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedGame ?? 'Tap to select a game',
                              style: TextStyle(color: _selectedGame != null ? Colors.white : AppColors.hint, fontSize: 14),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.hint),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _SectionLabel(AppLocalizations.t('listing_details')),
                  TextFormField(
                    controller: _titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('title_field'), hintText: 'e.g. Conqueror Rank Account'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('description'), hintText: 'Additional details, region, etc...'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _uidCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('in_game_uid')),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: '${AppLocalizations.t('price')} (LKR)', prefixText: 'LKR '),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),

                  if (_selectedGame != null) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(AppLocalizations.t('account_stats')),
                    Text(AppLocalizations.t('stats_hint'), style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                    const SizedBox(height: 10),

                    if (_statControllers.isNotEmpty) ...[
                      ..._statControllers.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: e.value,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(labelText: e.key, isDense: true),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: AppColors.hint),
                                  onPressed: () => _removeStatField(e.key),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 4),
                    ],

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...availableSuggestions.map((s) => ActionChip(
                              avatar: const Icon(Icons.add, size: 14, color: AppColors.primary),
                              label: Text(s, style: const TextStyle(fontSize: 12)),
                              backgroundColor: AppColors.fieldFill,
                              side: const BorderSide(color: AppColors.border),
                              onPressed: () => _addStatField(s),
                            )),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14, color: AppColors.hint),
                          label: Text(AppLocalizations.t('custom_stat'), style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppColors.fieldFill,
                          side: const BorderSide(color: AppColors.border),
                          onPressed: _showAddCustomStatDialog,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _allowBidding,
                      onChanged: (v) => setState(() => _allowBidding = v),
                      title: Text(AppLocalizations.t('allow_bidding'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                        'Buyers can bid above your price. Once the first bid comes in, bidding runs for 12 hours.',
                        style: TextStyle(color: AppColors.hint, fontSize: 11),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _SectionLabel(AppLocalizations.t('screenshots_max6')),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    ),
                    itemCount: _screenshots.length + 1,
                    itemBuilder: (context, i) {
                      if (i == _screenshots.length) {
                        return InkWell(
                          onTap: _screenshots.length >= 6 ? null : _pickScreenshots,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.fieldFill,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: AppColors.hint),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_screenshots[i], width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2, right: 2,
                            child: GestureDetector(
                              onTap: () => setState(() => _screenshots.removeAt(i)),
                              child: const CircleAvatar(
                                radius: 10, backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  _SectionLabel(AppLocalizations.t('account_vault')),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'These details are stored securely and shown to the buyer immediately after payment.',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(AppLocalizations.t('account_platform'), style: const TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPlatform,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    items: _platforms
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPlatform = v!),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _vaultEmailCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: '$_selectedPlatform Email / Username'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vaultPasswordCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('account_password')),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vaultRecoveryCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: AppLocalizations.t('recovery_codes')),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(AppLocalizations.t('post_listing'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
    );
  }
}
