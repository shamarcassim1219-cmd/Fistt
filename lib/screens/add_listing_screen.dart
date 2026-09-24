import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/safe_picker.dart';
import '../widgets/anim.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../services/api_service.dart';
import '../services/auth_helper.dart';
import '../services/app_localizations.dart';
import '../services/games_list.dart';
import 'verification_screen.dart';

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

  final List<XFile> _screenshots = [];
  bool _submitting = false;
  bool _allowBidding = false;
  String _saleType = 'full';
  String? _rentalUnit;
  final _rentalPriceCtrl = TextEditingController();
  final _installmentCountCtrl = TextEditingController();
  String? _installmentFrequency;
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

  void _showCoverPreview() {
    if (_screenshots.isEmpty) return;
    final cover = _screenshots.first;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('This is how your listing card will look on Home',
                  style: TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
            ),
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: kIsWeb
                        ? Image.network(cover.path, fit: BoxFit.cover, width: double.infinity)
                        : Image.file(File(cover.path), fit: BoxFit.cover, width: double.infinity),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleCtrl.text.trim().isEmpty ? 'Your listing title' : _titleCtrl.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text('LKR --', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickScreenshots() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImageSafe(imageQuality: 80);
      if (picked.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _screenshots.addAll(picked);
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
        _saleType = 'full';
        _rentalUnit = null;
        _rentalPriceCtrl.clear();
        _installmentCountCtrl.clear();
        _installmentFrequency = null;
        _selectedGame = null;
        _selectedPlatform = 'Google';
        _statControllers.clear();
        _customStatKeys.clear();
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!await requireLogin(context, reason: 'Login to list your account for sale')) return;
    if (!mounted) return;
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
        price: _saleType == 'rental' ? double.parse(_rentalPriceCtrl.text.trim()) : double.parse(_priceCtrl.text.trim()),
        screenshots: screenshotUrls,
        stats: stats,
        vaultPlatform: _selectedPlatform,
        vaultEmail: _vaultEmailCtrl.text.trim(),
        vaultPassword: _vaultPasswordCtrl.text.trim(),
        vaultRecoveryCodes: _vaultRecoveryCtrl.text.trim(),
        allowBidding: _allowBidding,
        saleType: _saleType,
        rentalUnit: _saleType == 'rental' ? _rentalUnit : null,
        rentalPricePerUnit: _saleType == 'rental' && _rentalPriceCtrl.text.trim().isNotEmpty ? double.tryParse(_rentalPriceCtrl.text.trim()) : null,
        installmentCount: _saleType == 'installment' && _installmentCountCtrl.text.trim().isNotEmpty ? int.tryParse(_installmentCountCtrl.text.trim()) : null,
        installmentFrequency: _saleType == 'installment' ? _installmentFrequency : null,
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
                          : 'Only verified sellers can post listings. Verify your account to start selling.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.hint, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!await requireLogin(context, reason: 'Login to verify your account')) return;
                          if (!context.mounted) return;
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen()));
                          if (mounted) _checkVerification();
                        },
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(_verifiedStatus == 'pending'
                            ? 'View verification status'
                            : _verifiedStatus == 'rejected'
                                ? 'Re-upload documents'
                                : 'Go to Verification Center'),
                      ),
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
                  if (_saleType != 'rental')
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: _saleType == 'installment'
                            ? 'Total Price (LKR)'
                            : '${AppLocalizations.t('price')} (LKR)',
                        prefixText: 'LKR ',
                      ),
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
                  const Text('Sale Type', style: TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Full Sale'),
                          selected: _saleType == 'full',
                          onSelected: (_) => setState(() => _saleType = 'full'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (['PUBG Mobile', 'Free Fire', 'Garena Free Fire'].contains(_selectedGame))
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Rental'),
                          selected: _saleType == 'rental',
                          onSelected: (_) => setState(() => _saleType = 'rental'),
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(duration: const Duration(milliseconds: 250), curve: Curves.easeOut, alignment: Alignment.topCenter, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
if (_saleType == 'rental') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _rentalUnit,
                            decoration: const InputDecoration(labelText: 'Rental Unit'),
                            dropdownColor: AppColors.surface,
                            items: const [
                              DropdownMenuItem(value: 'hour', child: Text('Per Hour', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'day', child: Text('Per Day', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'week', child: Text('Per Week', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'month', child: Text('Per Month', style: TextStyle(color: Colors.white))),
                            ],
                            onChanged: (v) => setState(() => _rentalUnit = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _rentalPriceCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Price per unit (LKR)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Buyer picks how many units to rent for. After time expires, you\'ll get a reminder to change the account password.',
                      style: TextStyle(color: AppColors.hint, fontSize: 11),
                    ),
                  ]
])),

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
                      return PopIn(key: ValueKey(_screenshots[i].path), child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (i == 0) return;
                              setState(() {
                                final item = _screenshots.removeAt(i);
                                _screenshots.insert(0, item);
                              });
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(_screenshots[i].path, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                                  : Image.file(File(_screenshots[i].path), width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                            ),
                          ),
                          if (i == 0)
                            Positioned(
                              left: 4, bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('COVER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
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
                      ));
                    },
                  ),
                  if (_screenshots.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Tap a photo to make it the cover photo shown on Home.',
                      style: const TextStyle(color: AppColors.hint, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showCoverPreview,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Preview how it looks on Home'),
                    ),
                  ],

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
                    decoration: InputDecoration(labelText: _saleType == 'rental' ? 'Secondary Email' : '$_selectedPlatform Email / Username'),
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
