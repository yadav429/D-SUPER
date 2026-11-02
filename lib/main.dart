import 'package:flutter/material.dart';

void main() {
  runApp(const DSuperApp());
}

class DSuperApp extends StatefulWidget {
  const DSuperApp({super.key});

  @override
  State<DSuperApp> createState() => _DSuperAppState();
}

class _DSuperAppState extends State<DSuperApp> {
  ThemeMode themeMode = ThemeMode.dark;
  bool hindi = true;

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
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'D-SUPER',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
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
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hindi ? 'आपका Personal Dashboard' : 'Your Personal Dashboard',
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${hindi ? module['hi'] : module['en']} - Coming Soon',
                              ),
                            ),
                          );
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
      ),
    );
  }
}
