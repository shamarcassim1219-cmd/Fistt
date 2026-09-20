import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/sl_locations.dart';
import 'liveness_screen.dart';

enum _Kind { details, docSelect, capture, liveness, review }

class _Step {
  final _Kind kind;
  final String side; // 'front' | 'back'
  const _Step(this.kind, [this.side = 'front']);
}

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // ----- status -----
  bool _loadingStatus = true;
  String _status = 'not_verified';
  String? _statusDocType;
  String? _rejectReason;
  String? _statusLoadError;

  // ----- flow -----
  bool _inFlow = false;
  bool _isReupload = false;
  bool _submitting = false;
  int _stepIndex = 0;
  List<_Step> _steps = const [_Step(_Kind.details), _Step(_Kind.docSelect)];

  // ----- form data -----
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  DateTime? _dob;
  String? _province;
  String? _district;
  String? _docType; // nic | driving_license | passport
  bool _checkingNic = false;

  // keys: front, back, selfie_front, selfie_back
  final Map<String, String> _files = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _nicCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await ApiService.getVerificationStatusFull();
      if (!mounted) return;
      setState(() {
        _status = data['verifiedStatus'] ?? 'not_verified';
        _statusDocType = data['documentType'];
        _rejectReason = data['rejectionReason']?.toString();
        _loadingStatus = false;
        _statusLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStatus = false;
        _statusLoadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ---------------------------------------------------------------- flow

  // Copy a photo into the app's own storage (the phone may delete cache files at any time)
  Future<String> _persist(String srcPath, String key) async {
    final base = await getApplicationSupportDirectory();
    final folder = Directory('${base.path}/verification');
    if (!await folder.exists()) await folder.create(recursive: true);
    final dest = '${folder.path}/${key}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(srcPath).copy(dest);
    return dest;
  }

  Future<void> _clearSaved() async {
    try {
      final base = await getApplicationSupportDirectory();
      final folder = Directory('${base.path}/verification');
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (_) {}
  }

  void _startFlow({bool reupload = false}) {
    setState(() {
      _inFlow = true;
      _isReupload = reupload;
      _stepIndex = 0;
      _files.clear();
      _docType = null;
      _steps = const [_Step(_Kind.details), _Step(_Kind.docSelect)];
    });
  }

  void _buildStepsForDoc() {
    final list = <_Step>[
      const _Step(_Kind.details),
      const _Step(_Kind.docSelect),
      const _Step(_Kind.capture, 'front'),
    ];
    if (_docType == 'nic') {
      list.add(const _Step(_Kind.capture, 'back'));
    }
    list.add(const _Step(_Kind.liveness, 'front'));
    list.add(const _Step(_Kind.review));
    _steps = list;
  }

  void _next() {
    if (_stepIndex < _steps.length - 1) setState(() => _stepIndex++);
  }

  void _back() {
    if (_stepIndex > 0) {
      setState(() => _stepIndex--);
    } else {
      setState(() => _inFlow = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------- steps logic

  static final _nicRegex = RegExp(r'^(\d{9}[vVxX]|\d{12})$');

  Future<void> _submitDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dob == null) {
      _snack('Please select your birthday');
      return;
    }
    if (_province == null || _district == null) {
      _snack('Please select province and district');
      return;
    }
    if (!_isReupload) {
      setState(() => _checkingNic = true);
      try {
        final exists = await ApiService.checkNicExists(_nicCtrl.text.trim());
        if (exists) {
          _snack('This NIC number is already used by another account');
          return;
        }
      } catch (_) {
        // if the check fails the server will validate again on submit
      } finally {
        if (mounted) setState(() => _checkingNic = false);
      }
    }
    _next();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Select your birthday',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _takeDocPhoto(String side) async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (img != null) {
        final saved = await _persist(img.path, side);
        if (!mounted) return;
        setState(() => _files[side] = saved);
      }
    } catch (e) {
      _snack('Could not open the camera');
    }
  }

  Future<void> _runLiveness(String side) async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => LivenessScreen(
          title: side == 'front' ? 'Face Liveness (Front)' : 'Face Liveness (Back)',
        ),
      ),
    );
    if (path != null) {
      try {
        final saved = await _persist(path, 'selfie_$side');
        if (!mounted) return;
        setState(() => _files['selfie_$side'] = saved);
      } catch (_) {
        _snack('Could not save the photo. Please try again.');
      }
    }
  }

  Future<void> _submitAll() async {
    // make sure every photo is still on the phone
    final need = ['front', 'selfie_front', if (_docType == 'nic') ...['back', 'selfie_back']];
    final bad = need.where((k) => _files[k] == null || !File(_files[k]!).existsSync()).toList();
    if (bad.isNotEmpty) {
      for (final k in bad) {
        _files.remove(k);
      }
      final idx = _steps.indexWhere((st) =>
          (st.kind == _Kind.capture && bad.contains(st.side)) ||
          (st.kind == _Kind.liveness && bad.contains('selfie_${st.side}')));
      setState(() {
        if (idx >= 0) _stepIndex = idx;
      });
      _snack('A photo was removed by your phone. Please take it again.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final d = _dob!;
      final fields = <String, String>{
        'fullName': _nameCtrl.text.trim(),
        'birthday':
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'address': _addressCtrl.text.trim(),
        'nicNumber': _nicCtrl.text.trim().toUpperCase(),
        'province': _province!,
        'district': _district!,
        'documentType': _docType!,
      };
      final files = <String, String>{
        'front': _files['front']!,
        'selfie_front': _files['selfie_front']!,
        if (_docType == 'nic') 'back': _files['back']!,
      };
      final data =
          await ApiService.submitVerificationFiles(fields: fields, filePaths: files);
      if (!mounted) return;
      _clearSaved();
      final st = (data['verifiedStatus'] ?? 'pending').toString();
      setState(() {
        _submitting = false;
        _inFlow = false;
        _status = st;
        _statusDocType = _docType;
        _rejectReason = data['rejectionReason']?.toString();
        _isReupload = st == 'rejected';
      });
      if (st == 'verified') {
        _snack('You are verified!');
      } else if (st == 'rejected') {
        _snack('Verification was not approved');
      } else {
        _snack('Verification submitted');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_inFlow || _submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Get Verified'),
          leading: _inFlow
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _submitting ? null : _back,
                )
              : null,
        ),
        body: _loadingStatus
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SafeArea(child: _inFlow ? _buildFlow() : _buildStatus()),
      ),
    );
  }

  // ---------------------------------------------------------------- status views

  String _docLabel(String? t) {
    switch (t) {
      case 'driving_license':
        return 'driving license';
      case 'passport':
        return 'passport';
      default:
        return 'NIC';
    }
  }

  Widget _buildStatus() {
    if (_statusLoadError != null) {
      return _centered(
        icon: Icons.error_outline,
        color: Colors.redAccent,
        title: 'Failed to load verification status',
        message: _statusLoadError!,
        action: OutlinedButton(
          onPressed: () {
            setState(() => _loadingStatus = true);
            _loadStatus();
          },
          child: const Text('Retry'),
        ),
      );
    }
    switch (_status) {
      case 'pending':
        return _centered(
          icon: Icons.hourglass_top_outlined,
          color: Colors.orangeAccent,
          title: 'Verification Pending',
          message:
              'Your ${_docLabel(_statusDocType)} verification needs a manual check by our team. This usually takes 1-2 business days.',
          action: OutlinedButton.icon(
            onPressed: () {
              setState(() => _loadingStatus = true);
              _loadStatus();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Status'),
          ),
        );
      case 'verified':
        return _centered(
          icon: Icons.verified,
          color: AppColors.primary,
          title: 'Verified Seller',
          message: 'Your account is verified. You now have the blue checkmark badge.',
        );
      case 'rejected':
        return _centered(
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
          title: 'Verification Rejected',
          message: (_rejectReason != null && _rejectReason!.isNotEmpty)
              ? 'Reason: $_rejectReason\n\nYour previous photos were removed. Please upload them again.'
              : 'Your previous photos were removed. Please upload them again.',
          action: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _startFlow(reupload: true),
              icon: const Icon(Icons.upload),
              label: const Text('Re-upload'),
            ),
          ),
        );
      default:
        return _centered(
          icon: Icons.verified_outlined,
          color: AppColors.primary,
          title: 'Get Verified',
          message:
              'Verify your identity to become a trusted seller. You will need your ID document and a quick face check.',
          action: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _startFlow(),
              child: const Text('Start Verification'),
            ),
          ),
        );
    }
  }

  Widget _centered({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 64),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.hint, fontSize: 14)),
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- flow views

  Widget _buildFlow() {
    final step = _steps[_stepIndex];
    Widget body;
    switch (step.kind) {
      case _Kind.details:
        body = _detailsPage();
        break;
      case _Kind.docSelect:
        body = _docSelectPage();
        break;
      case _Kind.capture:
        body = _capturePage(step.side);
        break;
      case _Kind.liveness:
        body = _livenessPage(step.side);
        break;
      case _Kind.review:
        body = _reviewPage();
        break;
    }
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_stepIndex + 1) / _steps.length,
          minHeight: 3,
          backgroundColor: AppColors.border,
          color: AppColors.primary,
        ),
        Expanded(child: body),
      ],
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.fieldFill,
        labelStyle: const TextStyle(color: AppColors.hint),
        hintStyle: const TextStyle(color: AppColors.hint),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary)),
      );

  Widget _pageScaffold({
    required String title,
    String? subtitle,
    required Widget child,
    required Widget bottom,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.hint, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(width: double.infinity, height: 52, child: bottom),
        ),
      ],
    );
  }

  // 1) personal details
  Widget _detailsPage() {
    final dobText = _dob == null
        ? 'Select birthday'
        : '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}';
    return _pageScaffold(
      title: 'Personal details',
      subtitle: 'Enter your details exactly as they appear on your ID.',
      bottom: ElevatedButton(
        onPressed: _checkingNic ? null : _submitDetails,
        child: _checkingNic
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Continue'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: _dec('Full name'),
              validator: (v) =>
                  (v == null || v.trim().split(RegExp(r'\s+')).length < 2)
                      ? 'Enter your full name'
                      : null,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDob,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _dec('Birthday'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(dobText,
                          style: TextStyle(
                              color: _dob == null ? AppColors.hint : Colors.white)),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.hint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _dec('Address'),
              validator: (v) =>
                  (v == null || v.trim().length < 8) ? 'Enter your full address' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nicCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9vVxX]')),
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: _dec('NIC number', hint: '199012345678 or 901234567V'),
              validator: (v) => (v == null || !_nicRegex.hasMatch(v.trim()))
                  ? 'Enter a valid NIC number'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _province,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Province'),
              items: slProvinceDistricts.keys
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() {
                _province = v;
                _district = null;
              }),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey(_province),
              value: _district,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('District'),
              items: (_province == null ? <String>[] : slProvinceDistricts[_province]!)
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: _province == null ? null : (v) => setState(() => _district = v),
            ),
          ],
        ),
      ),
    );
  }

  // 2) document select
  Widget _docSelectPage() {
    Widget tile(String value, String label, IconData icon) {
      final selected = _docType == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => setState(() => _docType = value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? AppColors.primary : AppColors.hint),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(color: Colors.white, fontSize: 16))),
                if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        ),
      );
    }

    return _pageScaffold(
      title: 'Select document',
      subtitle: 'Choose the document you want to verify with.',
      bottom: ElevatedButton(
        onPressed: _docType == null
            ? null
            : () {
                _files.clear();
                _buildStepsForDoc();
                _stepIndex = 1;
                _next();
              },
        child: const Text('Continue'),
      ),
      child: Column(
        children: [
          tile('nic', 'National Identity Card (NIC)', Icons.badge_outlined),
          tile('driving_license', 'Driving License', Icons.directions_car_outlined),
          tile('passport', 'Passport', Icons.menu_book_outlined),
        ],
      ),
    );
  }

  // 3) document photo
  Widget _capturePage(String side) {
    final docName = _docType == 'nic'
        ? 'NIC'
        : _docType == 'passport'
            ? 'passport'
            : 'driving license';
    String title;
    String subtitle;
    if (_docType == 'passport') {
      title = 'Passport photo page';
      subtitle = 'Take a clear photo of the page with your photo and details.';
    } else {
      title = side == 'front' ? 'Front of your $docName' : 'Back of your $docName';
      subtitle = 'Place the card on a flat surface. All corners and text must be readable.';
    }
    final path = _files[side];
    return _pageScaffold(
      title: title,
      subtitle: subtitle,
      bottom: ElevatedButton(
        onPressed: path == null ? null : _next,
        child: const Text('Continue'),
      ),
      child: _photoBox(
        path: path,
        placeholderIcon: Icons.credit_card,
        buttonLabel: path == null ? 'Take photo' : 'Retake',
        onTap: () => _takeDocPhoto(side),
      ),
    );
  }

  // 4) liveness
  Widget _livenessPage(String side) {
    final path = _files['selfie_$side'];
    return _pageScaffold(
      title: 'Face liveness check',
      subtitle:
          'We will ask you to do a few simple actions with your face (blink, smile, turn your head) to confirm that it is really you.',
      bottom: ElevatedButton(
        onPressed: path == null ? null : _next,
        child: const Text('Continue'),
      ),
      child: _photoBox(
        path: path,
        placeholderIcon: Icons.face_retouching_natural,
        buttonLabel: path == null ? 'Start liveness check' : 'Redo liveness check',
        onTap: () => _runLiveness(side),
        circle: true,
      ),
    );
  }

  Widget _photoBox({
    required String? path,
    required IconData placeholderIcon,
    required String buttonLabel,
    required VoidCallback onTap,
    bool circle = false,
  }) {
    final img = path == null
        ? Center(child: Icon(placeholderIcon, size: 64, color: AppColors.hint))
        : Image.file(File(path), fit: BoxFit.cover, width: double.infinity);
    return Column(
      children: [
        Container(
          height: circle ? 260 : 220,
          width: circle ? 260 : double.infinity,
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle ? null : BorderRadius.circular(12),
            border: Border.all(
                color: path == null ? AppColors.border : Colors.greenAccent, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: img,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(path == null ? Icons.camera_alt_outlined : Icons.refresh),
            label: Text(buttonLabel),
          ),
        ),
      ],
    );
  }

  // 5) review + submit
  Widget _reviewPage() {
    final d = _dob!;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 100,
                  child: Text(k, style: const TextStyle(color: AppColors.hint))),
              Expanded(child: Text(v, style: const TextStyle(color: Colors.white))),
            ],
          ),
        );

    Widget thumb(String label, String key) {
      final p = _files[key];
      return Expanded(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: p == null
                    ? Container(color: AppColors.fieldFill)
                    : Image.file(File(p), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: AppColors.hint, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final thumbs = <Widget>[
      thumb('Document front', 'front'),
      thumb('Face (front)', 'selfie_front'),
      if (_docType == 'nic') thumb('Document back', 'back'),
      if (_docType == 'nic') thumb('Face (back)', 'selfie_back'),
    ];

    return _pageScaffold(
      title: 'Review & submit',
      subtitle: 'Check everything is correct. We check your documents automatically, it takes a few seconds.',
      bottom: ElevatedButton(
        onPressed: _submitting ? null : _submitAll,
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Continue'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('Full name', _nameCtrl.text.trim()),
          row('Birthday',
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'),
          row('Address', _addressCtrl.text.trim()),
          row('NIC number', _nicCtrl.text.trim().toUpperCase()),
          row('Province', _province ?? ''),
          row('District', _district ?? ''),
          row('Document', _docLabel(_docType)),
          const SizedBox(height: 16),
          Row(children: [
            thumbs[0],
            const SizedBox(width: 10),
            thumbs[1],
          ]),
          if (thumbs.length > 2) ...[
            const SizedBox(height: 10),
            Row(children: [
              thumbs[2],
              const SizedBox(width: 10),
              thumbs[3],
            ]),
          ],
        ],
      ),
    );
  }
}
