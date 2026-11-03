
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

class VoiceAssistant extends StatefulWidget {
  final bool hindi;
  final Future<void> Function(String) onOpenModule;

  const VoiceAssistant({
    super.key,
    required this.hindi,
    required this.onOpenModule,
  });

  @override
  State<VoiceAssistant> createState() => _VoiceAssistantState();
}

class _VoiceAssistantState extends State<VoiceAssistant> {
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  bool available = false;
  bool listening = false;
  late bool hindi;

  String recognized = '';
  String status = 'Ready';

  @override
  void initState() {
    super.initState();
    hindi = widget.hindi;
    initializeVoice();
  }

  Future<void> initializeVoice() async {
    try {
      available = await speech.initialize(
        onStatus: (value) {
          if (mounted) {
            setState(() {
              status = value;
              listening = speech.isListening;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              status = error.errorMsg;
              listening = false;
            });
          }
        },
      );

      await tts.setSpeechRate(0.45);
      await tts.setVolume(1.0);
    } catch (e) {
      status = 'Voice initialization failed';
    }

    if (mounted) setState(() {});
  }

  Future<void> speak(String message) async {
    await tts.stop();
    await tts.setLanguage(hindi ? 'hi-IN' : 'en-US');
    await tts.speak(message);
  }

  Future<void> startListening() async {
    if (!available) {
      await speak('Speech recognition is unavailable');
      return;
    }

    await tts.stop();

    setState(() {
      recognized = '';
      listening = true;
      status = 'Listening...';
    });

    await speech.listen(
      localeId: hindi ? 'hi_IN' : 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          recognized = result.recognizedWords;
        });

        if (result.finalResult) {
          processCommand(recognized);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await speech.stop();

    if (mounted) {
      setState(() {
        listening = false;
        status = 'Stopped';
      });
    }
  }

  Future<void> openVideo() async {
    final uri = Uri.parse('https://www.youtube.com');

    await speak(hindi ? 'वीडियो खोल रहा हूँ' : 'Opening video');

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/');

    await speak(
      hindi ? 'व्हाट्सएप खोल रहा हूँ' : 'Opening WhatsApp',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> prepareMessage(String message) async {
    if (message.trim().isEmpty) return;

    await speak(
      hindi
          ? 'आपका मैसेज तैयार है'
          : 'Your message is ready',
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageReviewPage(message: message),
      ),
    );
  }

  Future<void> processCommand(String command) async {
    final text = command.toLowerCase().trim();

    await speech.stop();

    if (mounted) {
      setState(() {
        listening = false;
        status = 'Processing';
      });
    }

    // Wake word
    if (text.contains('hey d-super') ||
        text.contains('hey d super') ||
        text.contains('हे डी सुपर')) {
      await speak(
        hindi
            ? 'जी, बताइए क्या करना है'
            : 'Yes, tell me what to do',
      );
      return;
    }

    // Calculator
    if (text.contains('calculator') ||
        text.contains('कैलकुलेटर')) {
      await speak(hindi ? 'कैलकुलेटर खोल रहा हूँ' : 'Opening calculator');
      await widget.onOpenModule('Calculator');
      return;
    }

    // Chart
    if (text.contains('chart') ||
        text.contains('चार्ट')) {
      await speak(hindi ? 'चार्ट खोल रहा हूँ' : 'Opening chart');
      await widget.onOpenModule('Chart');
      return;
    }

    // Video
    if (text.contains('video') ||
        text.contains('वीडियो')) {
      await openVideo();
      return;
    }

    // WhatsApp
    if (text.contains('whatsapp') ||
        text.contains('व्हाट्सएप')) {
      await openWhatsApp();
      return;
    }

    // Message
    final englishPrefixes = [
      'type message ',
      'message ',
      'write message ',
    ];

    String? message;

    for (final prefix in englishPrefixes) {
      if (text.startsWith(prefix)) {
        message = command.trim().substring(prefix.length).trim();
        break;
      }
    }

    if (message == null) {
      final hindiPrefixes = [
        'मैसेज लिखो ',
        'संदेश लिखो ',
      ];

      for (final prefix in hindiPrefixes) {
        if (command.trim().startsWith(prefix)) {
          message = command.trim().substring(prefix.length).trim();
          break;
        }
      }
    }

    if (message != null && message.isNotEmpty) {
      await prepareMessage(message);
      return;
    }

    // Gallery
    if (text.contains('gallery') ||
        text.contains('गैलरी')) {
      await widget.onOpenModule('Gallery');
      return;
    }

    // Lock
    if (text.contains('lock app') ||
        text.contains('ऐप लॉक')) {
      await speak(
        hindi
            ? 'डैशबोर्ड से लॉक बटन दबाएँ'
            : 'Please use the dashboard lock button',
      );
      return;
    }

    await speak(
      hindi
          ? 'माफ कीजिए, यह कमांड समझ नहीं आया'
          : 'Sorry, command not recognized',
    );
  }

  @override
  void dispose() {
    speech.cancel();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D-SUPER AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              setState(() => hindi = !hindi);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.smart_toy,
                size: 85,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 15),
              const Text(
                'HEY D-SUPER',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('Status: $status'),
              const SizedBox(height: 25),
              Icon(
                listening ? Icons.graphic_eq : Icons.mic_none,
                size: 90,
                color: listening ? Colors.green : Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                recognized.isEmpty
                    ? (hindi ? 'अपना कमांड बोलें' : 'Speak your command')
                    : recognized,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 25),
              FilledButton.icon(
                onPressed: listening
                    ? stopListening
                    : startListening,
                icon: Icon(
                  listening ? Icons.stop : Icons.mic,
                ),
                label: Text(
                  listening
                      ? (hindi ? 'बंद करें' : 'Stop')
                      : (hindi ? 'बोलना शुरू करें' : 'Start Voice'),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hindi
                    ? 'भाषा: हिन्दी'
                    : 'Language: English',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageReviewPage extends StatelessWidget {
  final String message;

  const MessageReviewPage({
    super.key,
    required this.message,
  });

  Future<void> openWhatsApp() async {
    final uri = Uri.https(
      'wa.me',
      '/',
      {'text': message},
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Message'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.message, size: 65),
            const SizedBox(height: 20),
            SelectableText(
              message,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 25),
            FilledButton.icon(
              onPressed: openWhatsApp,
              icon: const Icon(Icons.send),
              label: const Text('Continue to WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}

