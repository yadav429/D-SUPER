import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

/// Local-first, permission-safe cybersecurity utilities.
/// URL checks are heuristic and do not contact or attack the target.
class CyberSecurityLabPage extends StatefulWidget {
  const CyberSecurityLabPage({super.key, required this.hindi});
  final bool hindi;
  @override
  State<CyberSecurityLabPage> createState() => _CyberSecurityLabPageState();
}

class _CyberSecurityLabPageState extends State<CyberSecurityLabPage> {
  static const Color _bg = Color(0xFF050B08);
  static const Color _panel = Color(0xFF0A1711);
  static const Color _green = Color(0xFF57F2A5);
  static const Color _muted = Color(0xFF9AB9A7);
  final TextEditingController _url = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _hashInput = TextEditingController();
  String _urlReport = '';
  String _passwordReport = '';
  String _hash = '';
  bool _showPassword = false;
  bool get _hi => widget.hindi;

  void _checkUrl() {
    final raw = _url.text.trim();
    if (raw.isEmpty) {
      _message(_hi ? 'पहले URL डालें।' : 'Enter a URL first.');
      return;
    }
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (uri == null || uri.host.isEmpty || !['http', 'https'].contains(uri.scheme)) {
      setState(() => _urlReport = _hi ? 'URL format सही नहीं है।' : 'The URL format is invalid.');
      return;
    }
    final host = uri.host.toLowerCase();
    final warnings = <String>[];
    if (uri.scheme != 'https') warnings.add(_hi ? 'HTTPS नहीं है' : 'HTTPS is not enabled');
    if (uri.userInfo.isNotEmpty) warnings.add(_hi ? 'URL में embedded login details हैं' : 'URL contains embedded credentials');
    if (InternetAddress.tryParse(host) != null) warnings.add(_hi ? 'Domain की जगह IP address है' : 'Uses an IP address instead of a domain');
    if (host.contains('xn--')) warnings.add(_hi ? 'Internationalized domain — ध्यान से जाँचें' : 'Internationalized domain — inspect carefully');
    if (host.split('.').length > 5) warnings.add(_hi ? 'बहुत सारे subdomains' : 'Unusually many subdomains');
    if (host.length > 55) warnings.add(_hi ? 'लंबा domain name' : 'Unusually long hostname');
    if (RegExp(r'@|%40').hasMatch(raw)) warnings.add(_hi ? 'भ्रामक @ character मिला' : 'Potentially deceptive @ character');
    if (RegExp(r'(login|verify|secure|account|wallet|update|free|gift)', caseSensitive: false).hasMatch(host)) {
      warnings.add(_hi ? 'संवेदनशील शब्द domain में हैं' : 'Sensitive bait words appear in hostname');
    }
    final result = warnings.isEmpty
        ? (_hi ? 'कोई सामान्य red flag नहीं मिला। यह सुरक्षित होने की गारंटी नहीं है।' : 'No common red flags detected. This does not guarantee the site is safe.')
        : '${_hi ? 'चेतावनी' : 'Warnings'}:\n• ${warnings.join('\n• ')}\n\n${_hi ? 'लिंक खोलने से पहले domain verify करें।' : 'Verify the domain independently before opening it.'}';
    setState(() => _urlReport = result);
  }

  void _checkPassword() {
    final value = _password.text;
    if (value.isEmpty) {
      _message(_hi ? 'Password डालें।' : 'Enter a password.');
      return;
    }
    var score = 0;
    if (value.length >= 12) score++;
    if (value.length >= 16) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    const weak = {'password', '12345678', 'qwerty123', 'admin123', 'letmein'};
    if (weak.contains(value.toLowerCase())) score = 0;
    final label = score <= 2 ? (_hi ? 'कमज़ोर' : 'Weak') : score <= 4 ? (_hi ? 'मध्यम' : 'Moderate') : (_hi ? 'मज़बूत' : 'Strong');
    setState(() {
      _passwordReport = '$label  •  $score/6\n${_hi ? 'लंबा और unique passphrase रखें। यह जाँच केवल इस device पर होती है।' : 'Use a long, unique passphrase. This check runs locally on this device.'}';
    });
  }

  Future<void> _makeHash() async {
    final value = _hashInput.text;
    if (value.isEmpty) {
      _message(_hi ? 'Text डालें।' : 'Enter text to hash.');
      return;
    }
    final digest = await Sha256().hash(utf8.encode(value));
    if (!mounted) return;
    setState(() => _hash = digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Widget _section(String title, IconData icon, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _panel, border: Border.all(color: const Color(0xFF1B6845)), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: _green), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(color: _green, fontWeight: FontWeight.bold, letterSpacing: 1.0)))]),
      const SizedBox(height: 14), child,
    ]),
  );

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: _bg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF28533B))),
  );

  @override
  void dispose() {
    _url.dispose(); _password.dispose(); _hashInput.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(backgroundColor: _panel, foregroundColor: _green, title: const Text('D-SUPER // CYBER LAB', style: TextStyle(fontSize: 16, letterSpacing: 1.1))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF103D29), Color(0xFF07120D)]), border: Border.all(color: _green.withValues(alpha: 0.65)), borderRadius: BorderRadius.circular(14)),
        child: Text(_hi ? 'LOCAL SECURITY CONSOLE\nये tools आपके device पर काम करते हैं। किसी दूसरे system को scan या access नहीं करते।' : 'LOCAL SECURITY CONSOLE\nThese tools run on-device and do not scan or access anyone else’s system.', style: const TextStyle(color: _green, height: 1.5, fontFamily: 'monospace')),
      ),
      const SizedBox(height: 14),
      _section('URL SAFETY CHECK', Icons.link, Column(children: [
        TextField(controller: _url, keyboardType: TextInputType.url, style: const TextStyle(color: Colors.white), decoration: _input('https://example.com')),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: _green, foregroundColor: _bg), onPressed: _checkUrl, icon: const Icon(Icons.radar), label: Text(_hi ? 'URL जाँचें' : 'CHECK URL'))),
        if (_urlReport.isNotEmpty) _report(_urlReport),
      ])),
      _section('PASSWORD STRENGTH', Icons.password, Column(children: [
        TextField(controller: _password, obscureText: !_showPassword, style: const TextStyle(color: Colors.white), decoration: _input(_hi ? 'Password (local check)' : 'Password (checked locally)').copyWith(suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: _green)))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: _green, side: const BorderSide(color: _green)), onPressed: _checkPassword, icon: const Icon(Icons.shield), label: Text(_hi ? 'मज़बूती जाँचें' : 'CHECK STRENGTH'))),
        if (_passwordReport.isNotEmpty) _report(_passwordReport),
      ])),
      _section('SHA-256 TEXT HASH', Icons.fingerprint, Column(children: [
        TextField(controller: _hashInput, minLines: 1, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: _input(_hi ? 'Hash बनाने के लिए text' : 'Text to hash')),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: _green, side: const BorderSide(color: _green)), onPressed: _makeHash, icon: const Icon(Icons.tag), label: Text(_hi ? 'SHA-256 बनाएँ' : 'GENERATE SHA-256'))),
        if (_hash.isNotEmpty) _report(_hash),
      ])),
      _section(_hi ? 'AUTHORIZED SECURITY PRACTICE' : 'AUTHORIZED SECURITY PRACTICE', Icons.school, Text(
        _hi ? 'सीखने के लिए: OWASP Top 10, सुरक्षित Wi-Fi configuration, 2FA, updates, backups और अपने lab में penetration testing.' : 'Learn: OWASP Top 10, secure Wi-Fi configuration, 2FA, updates, backups, and penetration testing inside your own lab.',
        style: const TextStyle(color: _muted, height: 1.5),
      )),
    ]),
  );

  Widget _report(String value) => Container(
    width: double.infinity, margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF28533B))),
    child: SelectableText(value, style: const TextStyle(color: _green, height: 1.5, fontFamily: 'monospace', fontSize: 12)),
  );
}
