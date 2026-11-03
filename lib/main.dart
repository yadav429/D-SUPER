
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:local_auth/local_auth.dart';

import 'screens/voice_assistant.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DSuperApp());
}

class DSuperApp extends StatefulWidget {
  const DSuperApp({super.key});

  @override
  State<DSuperApp> createState() => _DSuperAppState();
}

class _DSuperAppState extends State<DSuperApp> {
  final storage = const FlutterSecureStorage();
  final auth = LocalAuthentication();

  ThemeMode themeMode = ThemeMode.dark;
  bool hindi = true;
  bool loading = true;
  bool unlocked = false;
  bool biometricAvailable = false;

  String? savedSalt;
  String? savedHash;
  String? firstPin;

  final pinController = TextEditingController();

  final algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  final List<Map<String, dynamic>> modules = [
    {'icon': Icons.photo, 'en': 'Photo Analyzer', 'hi': 'फोटो विश्लेषण'},
    {'icon': Icons.phone, 'en': 'Phone Checker', 'hi': 'फोन चेकर'},
    {'icon': Icons.smart_toy, 'en': 'AI Assistant', 'hi': 'AI सहायक'},
    {'icon': Icons.qr_code, 'en': 'QR & Barcode', 'hi': 'QR और बारकोड'},
    {'icon': Icons.folder, 'en': 'Document Manager', 'hi': 'डॉक्यूमेंट मैनेजर'},
    {'icon': Icons.calculate, 'en': 'Calculator', 'hi': 'कैलकुलेटर'},
    {'icon': Icons.image, 'en': 'Image Editor', 'hi': 'इमेज एडिटर'},
    {'icon': Icons.picture_as_pdf, 'en': 'PDF Manager', 'hi': 'PDF मैनेजर'},
    {'icon': Icons.mic, 'en': 'Voice Recorder', 'hi': 'वॉइस रिकॉर्डर'},
    {'icon': Icons.swap_horiz, 'en': 'Unit Converter', 'hi': 'यूनिट कन्वर्टर'},
    {'icon': Icons.calendar_month, 'en': 'Calendar', 'hi': 'कैलेंडर'},
    {'icon': Icons.folder_open, 'en': 'File Manager', 'hi': 'फाइल मैनेजर'},
  ];

  @override
  void initState() {
    super.initState();
    loadSecurity();
  }

  Future<void> loadSecurity() async {
    try {
      savedSalt = await storage.read(key: 'pin_salt');
      savedHash = await storage.read(key: 'pin_hash');

      try {
        biometricAvailable =
            await auth.isDeviceSupported() &&
            await auth.canCheckBiometrics;
      } catch (_) {
        biometricAvailable = false;
      }
    } catch (_) {
      biometricAvailable = false;
    }

    if (mounted) setState(() => loading = false);
  }

  Future<String> makeHash(String pin, String salt) async {
    final key = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: base64Decode(salt),
    );

    return base64Encode(await key.extractBytes());
  }

  bool sameHash(String a, String b) {
    final x = base64Decode(a);
    final y = base64Decode(b);

    if (x.length != y.length) return false;

    int difference = 0;

    for (int i = 0; i < x.length; i++) {
      difference |= x[i] ^ y[i];
    }

    return difference == 0;
  }

  Future<void> submitPin() async {
    final pin = pinController.text.trim();
    pinController.clear();

    if (pin.length < 4 ||
        pin.length > 8 ||
        int.tryParse(pin) == null) {
      showMessage(hindi
          ? '4 से 8 अंकों का PIN डालें'
          : 'Enter a 4 to 8 digit PIN');
      return;
    }

    if (savedSalt == null || savedHash == null) {
      if (firstPin == null) {
        firstPin = pin;
        showMessage(hindi
            ? 'अब अपना PIN दोबारा डालकर Confirm करें'
            : 'Enter your PIN again to confirm');
        setState(() {});
        return;
      }

      if (firstPin != pin) {
        firstPin = null;
        showMessage(hindi
            ? 'PIN मेल नहीं हुआ। दोबारा शुरू करें।'
            : 'PINs do not match. Start again.');
        setState(() {});
        return;
      }

      final random = Random.secure();
      final saltBytes =
          List<int>.generate(16, (_) => random.nextInt(256));

      final salt = base64Encode(saltBytes);
      final hash = await makeHash(pin, salt);

      await storage.write(key: 'pin_salt', value: salt);
      await storage.write(key: 'pin_hash', value: hash);

      savedSalt = salt;
      savedHash = hash;
      firstPin = null;

      if (mounted) setState(() => unlocked = true);
      return;
    }

    final hash = await makeHash(pin, savedSalt!);

    if (sameHash(hash, savedHash!)) {
      if (mounted) setState(() => unlocked = true);
    } else {
      showMessage(hindi
          ? 'गलत PIN। फिर कोशिश करें।'
          : 'Incorrect PIN. Try again.');
    }
  }

  Future<void> biometricLogin() async {
    try {
      final success = await auth.authenticate(
        localizedReason: hindi
            ? 'D-SUPER खोलने के लिए Fingerprint लगाएँ'
            : 'Authenticate to open D-SUPER',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (success && mounted) {
        setState(() => unlocked = true);
      }
    } on PlatformException catch (e) {
      showMessage(
        '${hindi ? "Fingerprint error" : "Authentication error"}: ${e.message ?? "Unavailable"}',
      );
    } catch (_) {
      showMessage(hindi
          ? 'Fingerprint Login उपलब्ध नहीं है'
          : 'Fingerprint login is unavailable');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Open modules from dashboard or voice commands.
  Future<void> openVoiceModule(String name) async {
    if (name == 'Calculator') {
      openCalculator();
      return;
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModulePlaceholderPage(
          title: name,
          hindi: hindi,
        ),
      ),
    );
  }

  void openVoiceAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceAssistant(
          hindi: hindi,
          onOpenModule: openVoiceModule,
        ),
      ),
    );
  }

  void openCalculator() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CalculatorPage(hindi: hindi),
      ),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'D-SUPER',
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: loading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : unlocked
              ? dashboard()
              : pinScreen(),
    );
  }

  Widget pinScreen() {
    final setup = savedSalt == null || savedHash == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('D-SUPER Security'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 75),
              const SizedBox(height: 20),
              Text(
                setup
                    ? (firstPin == null
                        ? (hindi ? 'अपना PIN बनाएँ' : 'Create your PIN')
                        : (hindi ? 'PIN Confirm करें' : 'Confirm your PIN'))
                    : (hindi ? 'अपना PIN डालें' : 'Enter your PIN'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: hindi ? '4-8 अंकों का PIN' : '4-8 digit PIN',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 260,
                child: FilledButton(
                  onPressed: submitPin,
                  child: Text(hindi ? 'जारी रखें' : 'Continue'),
                ),
              ),
              if (!setup && biometricAvailable) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: biometricLogin,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(
                    hindi ? 'Fingerprint से Login' : 'Login with Fingerprint',
                  ),
                ),
              ],
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => setState(() => hindi = !hindi),
                child: Text(hindi ? 'English' : 'हिन्दी'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'D-SUPER',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Voice Assistant',
            icon: const Icon(Icons.mic),
            onPressed: openVoiceAssistant,
          ),
          IconButton(
            tooltip: 'Language',
            icon: const Icon(Icons.translate),
            onPressed: () => setState(() => hindi = !hindi),
          ),
          IconButton(
            tooltip: 'Theme',
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => setState(() {
              themeMode = themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            }),
          ),
          IconButton(
            tooltip: 'Lock',
            icon: const Icon(Icons.lock_outline),
            onPressed: () => setState(() => unlocked = false),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hindi
                  ? 'आपका Personal Dashboard'
                  : 'Your Personal Dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              hindi
                  ? 'आपके सभी tools एक ही जगह'
                  : 'All your tools in one place',
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: modules.length,
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final module = modules[index];

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        openVoiceModule(module['en'] as String);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              module['icon'] as IconData,
                              size: 34,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              hindi ? module['hi'] : module['en'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModulePlaceholderPage extends StatelessWidget {
  final String title;
  final bool hindi;

  const ModulePlaceholderPage({
    super.key,
    required this.title,
    required this.hindi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 70),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hindi
                  ? 'यह मॉड्यूल विकास के अधीन है'
                  : 'This module is under development',
            ),
          ],
        ),
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final bool hindi;

  const CalculatorPage({super.key, required this.hindi});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String display = '0';
  double? firstNumber;
  String? operation;
  bool newNumber = true;

  void press(String value) {
    setState(() {
      if (value == 'C') {
        display = '0';
        firstNumber = null;
        operation = null;
        newNumber = true;
      } else if (value == '⌫') {
        display = display.length > 1
            ? display.substring(0, display.length - 1)
            : '0';
      } else if (['+', '−', '×', '÷'].contains(value)) {
        firstNumber = double.tryParse(display);
        operation = value;
        newNumber = true;
      } else if (value == '=') {
        if (firstNumber == null || operation == null) return;

        final second = double.tryParse(display) ?? 0;
        double result = 0;

        switch (operation) {
          case '+':
            result = firstNumber! + second;
            break;
          case '−':
            result = firstNumber! - second;
            break;
          case '×':
            result = firstNumber! * second;
            break;
          case '÷':
            if (second == 0) {
              display = 'Error';
              firstNumber = null;
              operation = null;
              newNumber = true;
              return;
            }
            result = firstNumber! / second;
            break;
        }

        display = result == result.toInt()
            ? result.toInt().toString()
            : result.toString();

        firstNumber = null;
        operation = null;
        newNumber = true;
      } else {
        if (value == '.' && display.contains('.') && !newNumber) return;

        display = newNumber
            ? (value == '.' ? '0.' : value)
            : display == '0' && value != '.'
                ? value
                : display + value;

        newNumber = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['C', '⌫', '÷', '×'],
      ['7', '8', '9', '−'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['0', '.', '', ''],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hindi ? 'कैलकुलेटर' : 'Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(20),
                child: FittedBox(
                  child: Text(
                    display,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            for (final row in buttons)
              Expanded(
                child: Row(
                  children: [
                    for (final value in row)
                      Expanded(
                        child: value.isEmpty
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.all(4),
                                child: ElevatedButton(
                                  onPressed: () => press(value),
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

