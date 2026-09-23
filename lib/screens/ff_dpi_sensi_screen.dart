import 'package:flutter/material.dart';

class FfDpiSensiScreen extends StatefulWidget {
  const FfDpiSensiScreen({super.key});

  @override
  State<FfDpiSensiScreen> createState() => _FfDpiSensiScreenState();
}

class _FfDpiSensiScreenState extends State<FfDpiSensiScreen> {
  // 0 = platform select, 1 = ios not available, 2 = how to turn dpi on,
  // 3 = enter dpi, 4 = recommended settings, 5 = rating
  int _step = 0;
  final _dpiController = TextEditingController();
  int? _dpi;
  int _ratingStars = 0;
  bool _ratingSubmitted = false;

  @override
  void dispose() {
    _dpiController.dispose();
    super.dispose();
  }

  // ---------- sensitivity math ----------
  int _clamp200(num v) => v.round().clamp(0, 200);

  Map<String, int> get _sensitivity {
    final dpi = _dpi ?? 400;
    const referenceDpi = 400;
    const referenceGeneral = 50;
    final general = _clamp200(referenceGeneral * (referenceDpi / dpi));
    return {
      'General': general,
      'Red Dot': _clamp200(general * 1.0),
      '2x Scope': _clamp200(general * 1.1),
      '4x Scope': _clamp200(general * 1.15),
      'Sniper Scope': _clamp200(general * 1.2),
      'Free Look': _clamp200(general * 1.05),
    };
  }

  // ---------- graphics heuristic ----------
  // Higher screen DPI is usually paired with newer / more powerful hardware,
  // so we use it as a rough proxy for what the phone can comfortably handle.
  // This is an approximation, not a guarantee — powerful low-DPI phones or
  // weak high-DPI ones exist, but it's a reasonable starting point.
  Map<String, String> get _graphics {
    final dpi = _dpi ?? 400;
    if (dpi < 300) {
      return {'Graphics': 'Smooth', 'Frame Rate': 'Medium', 'Shadows': 'Off'};
    } else if (dpi <= 450) {
      return {'Graphics': 'High Definition', 'Frame Rate': 'High', 'Shadows': 'Off'};
    } else {
      return {'Graphics': 'Ultra HD', 'Frame Rate': 'Ultra', 'Shadows': 'Enabled'};
    }
  }

  void _confirmApply() async {
    final ready = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settings Apply කරලා ඉවරද?'),
        content: const Text(
          'Free Fire settings වලට ගිහින් උඩින් පෙන්නපු values ටික දාලා ඉවර නම් "ඔව්" ගහන්න.',
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
    if (ready == true && mounted) {
      setState(() => _step = 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Free Fire DPI & Sensi')),
      body: switch (_step) {
        0 => _platformSelect(),
        1 => _iosNotAvailable(),
        2 => _dpiOnInstructions(),
        3 => _enterDpi(),
        4 => _recommendedSettings(),
        5 => _ratingScreen(),
        _ => const SizedBox(),
      },
    );
  }

  Widget _platformSelect() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android, size: 48),
            const SizedBox(height: 16),
            const Text('ඔයාගේ Phone එක මොකක්ද?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.android),
                label: const Text('Android'),
                onPressed: () => setState(() => _step = 2),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.apple),
                label: const Text('iPhone / iPad'),
                onPressed: () => setState(() => _step = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iosNotAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'iPhone / iPad සඳහා මේ feature එක Not available right now.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('ආපහු යන්න'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dpiOnInstructions() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('DPI එක On කරන්නේ කොහොමද', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        _stepTile('1', 'Settings > About phone වලට යන්න'),
        _stepTile('2', '"Build number" එක 7 වතාවක් tap කරන්න (Developer options unlock වෙනවා)'),
        _stepTile('3', 'Settings > Developer options > "Smallest width" වලට යන්න'),
        _stepTile('4', 'මෙතන තමයි DPI (screen density) එක actual ව control වෙන්නේ - දැනට තියෙන number එක මතක තියාගන්න'),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => setState(() => _step = 3),
          child: const Text('ඊළඟට → DPI එක Enter කරමු'),
        ),
      ],
    );
  }

  Widget _stepTile(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, child: Text(num, style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _enterDpi() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ඔයාගේ DPI Number එක Enter කරන්න', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('(කලින් screen එකේ "Smallest width" හෝ device specs එකේ තියෙන DPI අගය)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _dpiController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'DPI',
              border: OutlineInputBorder(),
              hintText: 'e.g. 440',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(_dpiController.text.trim());
              if (v == null || v < 100 || v > 900) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('100 - 900 අතර DPI value එකක් දාන්න')),
                );
                return;
              }
              setState(() {
                _dpi = v;
                _step = 4;
              });
            },
            child: const Text('Recommended Settings බලමු'),
          ),
        ],
      ),
    );
  }

  Widget _recommendedSettings() {
    final sens = _sensitivity;
    final gfx = _graphics;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('DPI ${_dpi ?? '-'} සඳහා Recommended Settings', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),

        const Text('Sensitivity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sens.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text(e.key), Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800))],
                      ),
                    )),
                const Divider(height: 20),
                const Text(
                  'ඇයි මේ values ද: ඔයාගේ DPI වැඩි වෙන කොට, ඇඟිල්ලේ කුඩා movement එකකට screen එකේ cursor එක වැඩිය travel වෙනවා. ඒ නිසා DPI වැඩි වෙනකොට Sensitivity අඩු කරන්න ඕන - නැත්නම් aim එක අධික ලෙස වේගවත් වෙලා control කරගන්න අමාරු වෙනවා. Zoom scopes (2x, 4x, Sniper) වලට ටිකක් වැඩිය sensitivity දෙන්නේ zoom කරාට පස්සේ fine-aim කරන්න පහසු වෙන්න.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Text('Graphics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...gfx.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text(e.key), Text(e.value, style: const TextStyle(fontWeight: FontWeight.w800))],
                      ),
                    )),
                const Divider(height: 20),
                const Text(
                  'ඇයි මේ values ද: ඉහල DPI screen එකක් තියෙන phone සාමාන්‍යයෙන් අලුත් / powerful hardware එකක් තියෙන phone එකක් වෙන්න ඉඩ වැඩියි, ඒ නිසා graphics quality සහ frame rate ටිකක් වැඩිය දෙන්න පුළුවන්. අඩු DPI phone එකක නම් smooth gameplay එකට graphics අඩු කරලා, lag නොවී play කරගන්න පුළුවන් විදිහට recommend කරනවා. මේ ඔයාගේ phone එකේ actual performance එක නොදන්නා නිසා approximate guide එකක් විතරයි - ලැග් වෙනවා නම් graphics තව අඩු කරන්න.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Settings Apply කරලා ඉවරයි'),
          onPressed: _confirmApply,
        ),
      ],
    );
  }

  Widget _ratingScreen() {
    if (_ratingSubmitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 48, color: Colors.pink),
              const SizedBox(height: 16),
              const Text('Thank You! 🙏', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('ඔයාගේ feedback එකට ස්තූතියි.', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('ඉවරයි'),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Service එක හොදද?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Rate කරන්න', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _ratingStars;
                return IconButton(
                  iconSize: 34,
                  icon: Icon(filled ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: () => setState(() => _ratingStars = i + 1),
                );
              }),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _ratingStars == 0 ? null : () => setState(() => _ratingSubmitted = true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
