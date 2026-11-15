import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Privacy-safe phone number inspection. This screen validates formatting
/// locally and never uploads the entered number or attempts to identify a person.
class PhoneIntelligencePage extends StatefulWidget {
  const PhoneIntelligencePage({super.key, required this.hindi});

  final bool hindi;

  @override
  State<PhoneIntelligencePage> createState() => _PhoneIntelligencePageState();
}

class _PhoneIntelligencePageState extends State<PhoneIntelligencePage> {
  final TextEditingController _numberController = TextEditingController();
  bool _scanning = false;
  bool _scanned = false;
  String _country = '';
  String _international = '';
  String _status = '';
  int _digits = 0;
  final List<String> _logs = [];

  bool get hi => widget.hindi;

  static const Map<String, String> _callingCodes = {
    '91': 'India',
    '1': 'United States / Canada',
    '44': 'United Kingdom',
    '61': 'Australia',
    '971': 'United Arab Emirates',
    '49': 'Germany',
    '33': 'France',
    '81': 'Japan',
    '92': 'Pakistan',
    '977': 'Nepal',
    '880': 'Bangladesh',
    '94': 'Sri Lanka',
  };

  Future<void> _scan() async {
    if (_scanning) return;
    final raw = _numberController.text.trim();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) {
      _show(hi ? 'कृपया 7 से 15 अंकों का सही नंबर डालें।' : 'Enter a valid number with 7–15 digits.');
      return;
    }

    setState(() {
      _scanning = true;
      _scanned = false;
      _logs.clear();
    });

    final steps = hi
        ? ['इनपुट साफ किया जा रहा है...', 'कंट्री कोड जाँचा जा रहा है...', 'नंबर फॉर्मेट सत्यापित हो रहा है...', 'प्राइवेसी चेक पूरा।']
        : ['Normalizing input...', 'Checking calling code...', 'Validating number format...', 'Privacy checks complete.'];

    for (final step in steps) {
      if (!mounted) return;
      setState(() => _logs.add('> $step'));
      await Future.delayed(const Duration(milliseconds: 420));
    }

    String country = hi ? 'पहचाना नहीं गया' : 'Not identified';
    String international = '+$digits';
    if (raw.startsWith('+')) {
      for (final code in _callingCodes.keys.toList()..sort((a, b) => b.length.compareTo(a.length))) {
        if (digits.startsWith(code)) {
          country = _callingCodes[code]!;
          break;
        }
      }
    } else if (digits.length == 10) {
      country = 'India (संभावित; +91)';
      international = '+91 $digits';
    }

    final plausible = digits.length >= 10 && digits.length <= 13;
    setState(() {
      _digits = digits.length;
      _country = country;
      _international = international;
      _status = plausible
          ? (hi ? 'फॉर्मेट सामान्य दिखता है' : 'Format looks plausible')
          : (hi ? 'फॉर्मेट की पुष्टि नहीं हुई' : 'Format could not be confirmed');
      _scanned = true;
      _scanning = false;
      _logs.add(hi ? '> स्कैन पूरा — कोई निजी डेटा एक्सेस नहीं किया गया।' : '> Scan complete — no private data accessed.');
    });
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Widget _result(String label, String value, {IconData icon = Icons.info_outline}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF0D201C),
        border: Border.all(color: const Color(0xFF1C7659)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF55F2B2), size: 21),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF70BDA0), fontSize: 10, letterSpacing: 1.3)),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(color: Color(0xFFE1FFF2), fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF55F2B2);
    return Scaffold(
      backgroundColor: const Color(0xFF050B0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071410),
        foregroundColor: green,
        title: const Text('Z-SCAN // PHONE INTEL', style: TextStyle(fontSize: 16, letterSpacing: 1.1, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0B251C), Color(0xFF091311)]),
              border: Border.all(color: const Color(0xFF1C7659)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.radar, color: green, size: 30),
                SizedBox(width: 10),
                Text('PHONE INTELLIGENCE', style: TextStyle(color: green, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
              ]),
              const SizedBox(height: 8),
              Text(hi ? 'नंबर की सुरक्षित सार्वजनिक-स्तर जाँच' : 'Privacy-safe public-level number check',
                style: const TextStyle(color: Color(0xFFB6D9CA), fontSize: 12)),
              const SizedBox(height: 18),
              TextField(
                controller: _numberController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                decoration: InputDecoration(
                  hintText: '+91 98765 43210',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.phone_android, color: green),
                  filled: true,
                  fillColor: const Color(0xFF030807),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF28664F))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: green)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: const Color(0xFF04100B), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _scanning ? null : _scan,
                icon: Icon(_scanning ? Icons.sync : Icons.security),
                label: Text(_scanning ? (hi ? 'स्कैन हो रहा है...' : 'SCANNING...') : (hi ? 'सुरक्षित स्कैन शुरू करें' : 'START SAFE SCAN')),
              )),
            ]),
          ),
          const SizedBox(height: 16),
          if (_scanning) const LinearProgressIndicator(color: green, backgroundColor: Color(0xFF163329)),
          if (_logs.isNotEmpty) Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF020605), border: Border.all(color: const Color(0xFF194B39)), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('> SYSTEM TERMINAL', style: TextStyle(color: green, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              for (final log in _logs) Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(log, style: const TextStyle(color: Color(0xFF8DEFC2), fontFamily: 'monospace', fontSize: 12)),
              ),
            ]),
          ),
          if (_scanned) ...[
            const SizedBox(height: 18),
            const Text('SCAN REPORT', style: TextStyle(color: green, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            _result(hi ? 'देश / कंट्री कोड' : 'Country / calling code', _country, icon: Icons.public),
            _result(hi ? 'इंटरनेशनल फॉर्मेट' : 'International format', _international, icon: Icons.phone),
            _result(hi ? 'अंकों की संख्या' : 'Digit count', '$_digits', icon: Icons.numbers),
            _result(hi ? 'फॉर्मेट स्थिति' : 'Format status', _status, icon: Icons.verified_user),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: green, side: const BorderSide(color: green)),
              onPressed: () => Clipboard.setData(ClipboardData(text: '$_international\n$_country\n$_status')),
              icon: const Icon(Icons.copy),
              label: Text(hi ? 'रिपोर्ट कॉपी करें' : 'COPY REPORT'),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: const Color(0xFF211A0A), border: Border.all(color: const Color(0xFF80652A)), borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.privacy_tip_outlined, color: Color(0xFFFFD36B)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                hi
                    ? 'प्राइवेसी: नंबर आपके डिवाइस पर ही जाँचा जाता है। यह ऐप मालिक का नाम, घर का पता, लाइव लोकेशन, कॉल रिकॉर्ड या निजी अकाउंट नहीं निकालता।'
                    : 'Privacy: the number is checked on your device only. This app does not reveal an owner name, home address, live location, call records, or private accounts.',
                style: const TextStyle(color: Color(0xFFFFE7AD), fontSize: 12),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
