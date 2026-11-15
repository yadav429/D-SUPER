import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModuleToolsPage extends StatelessWidget {
  const ModuleToolsPage({super.key, required this.module, required this.hindi});
  final String module;
  final bool hindi;

  @override
  Widget build(BuildContext context) {
    switch (module) {
      case 'Photo Analyzer': return PhotoAnalyzerPage(hindi: hindi);
      case 'Phone Checker': return PhoneCheckerPage(hindi: hindi);
      case 'QR & Barcode': return QrScannerPage(hindi: hindi);
      case 'Document Manager': return FileToolPage(hindi: hindi, pdfOnly: false);
      case 'Image Editor': return ImageEditorPage(hindi: hindi);
      case 'PDF Manager': return FileToolPage(hindi: hindi, pdfOnly: true);
      case 'Voice Recorder': return VoiceRecorderPage(hindi: hindi);
      case 'Unit Converter': return UnitConverterPage(hindi: hindi);
      case 'Calendar': return CalendarPage(hindi: hindi);
      case 'File Manager': return FileToolPage(hindi: hindi, pdfOnly: false);
      default: return Scaffold(appBar: AppBar(title: Text(module)), body: Center(child: Text(module)));
    }
  }
}

class PhotoAnalyzerPage extends StatefulWidget {
  const PhotoAnalyzerPage({super.key, required this.hindi});
  final bool hindi;
  @override
  State<PhotoAnalyzerPage> createState() => _PhotoAnalyzerPageState();
}
class _PhotoAnalyzerPageState extends State<PhotoAnalyzerPage> {
  File? file;
  String details = '';
  Future<void> pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final f = File(x.path);
    final bytes = await f.length();
    final decoded = img.decodeImage(await f.readAsBytes());
    setState(() {
      file = f;
      details = decoded == null
          ? 'File size: $bytes bytes'
          : 'Width: ${decoded.width}px\nHeight: ${decoded.height}px\nSize: $bytes bytes\nFormat: ${x.mimeType ?? 'Image'}';
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.hindi ? 'फोटो विश्लेषण' : 'Photo Analyzer')),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      FilledButton.icon(onPressed: pick, icon: const Icon(Icons.photo_library), label: Text(widget.hindi ? 'फोटो चुनें' : 'Choose Photo')),
      const SizedBox(height: 16),
      if (file != null) Expanded(child: Image.file(file!, fit: BoxFit.contain)),
      if (details.isNotEmpty) SelectableText(details),
      if (file == null) const Expanded(child: Center(child: Icon(Icons.image_search, size: 80))),
    ])),
  );
}

class PhoneCheckerPage extends StatefulWidget {
  const PhoneCheckerPage({super.key, required this.hindi});
  final bool hindi;
  @override
  State<PhoneCheckerPage> createState() => _PhoneCheckerPageState();
}
class _PhoneCheckerPageState extends State<PhoneCheckerPage> {
  Map<String, String> info = {};
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final a = await DeviceInfoPlugin().androidInfo;
      if (!mounted) return;
      setState(() => info = {
        'Device': a.model, 'Manufacturer': a.manufacturer, 'Brand': a.brand,
        'Android version': a.version.release, 'SDK': '${a.version.sdkInt}',
        'Device code': a.device, 'Hardware': a.hardware,
      });
    } catch (e) { if (mounted) setState(() => info = {'Error': '$e'}); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.hindi ? 'फोन चेकर' : 'Phone Checker')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Icon(Icons.phone_android, size: 70),
      for (final e in info.entries) ListTile(title: Text(e.key), subtitle: SelectableText(e.value)),
      Text(widget.hindi ? 'यह जानकारी Android से पढ़ी गई है।' : 'Information read from Android system.'),
    ]),
  );
}

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key, required this.hindi});
  final bool hindi;
  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}
class _QrScannerPageState extends State<QrScannerPage> {
  String? value;
  bool handled = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.hindi ? 'QR और बारकोड' : 'QR & Barcode')),
    body: Column(children: [
      Expanded(child: MobileScanner(onDetect: (capture) {
        if (handled) return;
        final raw = capture.barcodes.firstOrNull?.rawValue;
        if (raw == null) return;
        setState(() { value = raw; handled = true; });
      })),
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        SelectableText(value ?? (widget.hindi ? 'कोड कैमरे के सामने रखें' : 'Point camera at a code')),
        const SizedBox(height: 8),
        FilledButton(onPressed: () => setState(() { value = null; handled = false; }), child: Text(widget.hindi ? 'फिर स्कैन करें' : 'Scan Again')),
      ])),
    ]),
  );
}

class FileToolPage extends StatefulWidget {
  const FileToolPage({super.key, required this.hindi, required this.pdfOnly});
  final bool hindi;
  final bool pdfOnly;
  @override
  State<FileToolPage> createState() => _FileToolPageState();
}
class _FileToolPageState extends State<FileToolPage> {
  PlatformFile? selected;
  String? path;
  Future<void> choose() async {
    final result = await FilePicker.platform.pickFiles(
      type: widget.pdfOnly ? FileType.custom : FileType.any,
      allowedExtensions: widget.pdfOnly ? ['pdf'] : null,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() { selected = result.files.first; path = result.files.first.path; });
  }
  Future<void> open() async {
    if (path != null) await OpenFilex.open(path!);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.pdfOnly ? (widget.hindi ? 'PDF मैनेजर' : 'PDF Manager') : (widget.hindi ? 'डॉक्यूमेंट / फाइल मैनेजर' : 'Document / File Manager'))),
    body: Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(widget.pdfOnly ? Icons.picture_as_pdf : Icons.folder_open, size: 76),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: choose, icon: const Icon(Icons.folder), label: Text(widget.hindi ? 'फाइल चुनें' : 'Choose File')),
      if (selected != null) ...[
        const SizedBox(height: 16),
        Text(selected!.name, textAlign: TextAlign.center),
        Text('${(selected!.size / 1024).toStringAsFixed(1)} KB'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: open, icon: const Icon(Icons.open_in_new), label: Text(widget.hindi ? 'फाइल खोलें' : 'Open File')),
      ],
    ]))),
  );
}

class ImageEditorPage extends StatefulWidget {
  const ImageEditorPage({super.key, required this.hindi});
  final bool hindi;
  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}
class _ImageEditorPageState extends State<ImageEditorPage> {
  Uint8List? bytes;
  String? sourcePath;
  int filter = 0;
  Future<void> pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() { sourcePath = x.path; bytes = File(x.path).readAsBytesSync(); filter = 0; });
  }
  Future<void> save() async {
    if (bytes == null) return;
    final decoded = img.decodeImage(bytes!);
    if (decoded == null) return;
    img.Image out = decoded;
    if (filter == 1) out = img.grayscale(decoded);
    if (filter == 2) out = img.adjustColor(decoded, saturation: 1.5, brightness: 1.08);
    if (filter == 3) out = img.adjustColor(decoded, contrast: 1.25);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(img.encodeJpg(out, quality: 90));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.hindi ? 'सेव हुआ: ' : 'Saved: '}${file.path}')));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.hindi ? 'इमेज एडिटर' : 'Image Editor'), actions: [IconButton(onPressed: bytes == null ? null : save, icon: const Icon(Icons.save))]),
    body: Column(children: [
      Expanded(child: Center(child: bytes == null ? const Icon(Icons.image, size: 90) : Image.memory(bytes!, fit: BoxFit.contain))),
      Wrap(spacing: 8, children: [
        FilledButton(onPressed: pick, child: Text(widget.hindi ? 'फोटो चुनें' : 'Choose Image')),
        for (var i = 0; i < 4; i++) ChoiceChip(label: Text(['Original', 'B&W', 'Vivid', 'Contrast'][i]), selected: filter == i, onSelected: (_) => setState(() => filter = i)),
      ]),
      const SizedBox(height: 12),
    ]),
  );
}

class VoiceRecorderPage extends StatefulWidget {
  const VoiceRecorderPage({super.key, required this.hindi});
  final bool hindi;
  @override
  State<VoiceRecorderPage> createState() => _VoiceRecorderPageState();
}
class _VoiceRecorderPageState extends State<VoiceRecorderPage> {
  final AudioRecorder recorder = AudioRecorder();
  bool recording = false;
  String? savedPath;
  Future<void> toggle() async {
    if (recording) {
      savedPath = await recorder.stop();
      setState(() => recording = false);
    } else {
      if (!await recorder.hasPermission()) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() { recording = true; savedPath = null; });
    }
  }
  @override
  void dispose() { recorder.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.hindi ? 'वॉइस रिकॉर्डर' : 'Voice Recorder')),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(recording ? Icons.mic : Icons.mic_none, size: 90, color: recording ? Colors.red : null),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: toggle, icon: Icon(recording ? Icons.stop : Icons.fiber_manual_record), label: Text(recording ? (widget.hindi ? 'रिकॉर्डिंग रोकें' : 'Stop Recording') : (widget.hindi ? 'रिकॉर्ड शुरू करें' : 'Start Recording'))),
      if (savedPath != null) Padding(padding: const EdgeInsets.all(16), child: SelectableText(savedPath!)),
    ])),
  );
}

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key, required this.hindi});
  final bool hindi;
  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}
class _UnitConverterPageState extends State<UnitConverterPage> {
  final controller = TextEditingController(text: '1');
  String kind = 'Length';
  String from = 'Meter';
  String to = 'Kilometer';
  final Map<String, Map<String, double>> units = {
    'Length': {'Meter': 1, 'Kilometer': 1000, 'Centimeter': .01, 'Mile': 1609.344, 'Foot': .3048},
    'Weight': {'Kilogram': 1, 'Gram': .001, 'Pound': .45359237, 'Tonne': 1000},
    'Temperature': {'Celsius': 1, 'Fahrenheit': 2, 'Kelvin': 3},
    'Area': {'Square meter': 1, 'Acre': 4046.8564224, 'Hectare': 10000},
    'Volume': {'Liter': 1, 'Milliliter': .001, 'Gallon (US)': 3.785411784},
  };
  double convert(double v) {
    if (kind == 'Temperature') {
      final c = from == 'Celsius' ? v : from == 'Fahrenheit' ? (v - 32) * 5 / 9 : v - 273.15;
      return to == 'Celsius' ? c : to == 'Fahrenheit' ? c * 9 / 5 + 32 : c + 273.15;
    }
    return v * units[kind]![from]! / units[kind]![to]!;
  }
  @override
  Widget build(BuildContext context) {
    final options = units[kind]!.keys.toList();
    return Scaffold(appBar: AppBar(title: Text(widget.hindi ? 'यूनिट कन्वर्टर' : 'Unit Converter')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(value: kind, items: units.keys.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() { kind = v!; from = units[kind]!.keys.first; to = units[kind]!.keys.elementAt(1); })),
        TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: widget.hindi ? 'मान' : 'Value'), onChanged: (_) => setState(() {})),
        DropdownButtonFormField<String>(value: from, items: options.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => from = v!)),
        const Icon(Icons.swap_vert, size: 32),
        DropdownButtonFormField<String>(value: to, items: options.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => to = v!)),
        const SizedBox(height: 20),
        Text(controller.text.isEmpty || double.tryParse(controller.text) == null ? '—' : convert(double.parse(controller.text)).toStringAsPrecision(8), style: Theme.of(context).textTheme.headlineMedium),
      ]));
  }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.hindi});
  final bool hindi;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}
class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now();
  List<String> events = [];
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => events = p.getStringList('calendar_events') ?? []);
  }
  Future<void> addEvent() async {
    final c = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(widget.hindi ? 'नया इवेंट' : 'New Event'),
      content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: widget.hindi ? 'इवेंट का नाम' : 'Event title')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save'))],
    ));
    c.dispose();
    if (value == null || value.isEmpty) return;
    final item = '${selected.year}-${selected.month.toString().padLeft(2,'0')}-${selected.day.toString().padLeft(2,'0')}|$value';
    final p = await SharedPreferences.getInstance();
    events.add(item); await p.setStringList('calendar_events', events);
    if (mounted) setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final date = '${selected.year}-${selected.month.toString().padLeft(2,'0')}-${selected.day.toString().padLeft(2,'0')}';
    final dayEvents = events.where((e) => e.startsWith('$date|')).toList();
    return Scaffold(appBar: AppBar(title: Text(widget.hindi ? 'कैलेंडर' : 'Calendar')),
      floatingActionButton: FloatingActionButton(onPressed: addEvent, child: const Icon(Icons.add)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        CalendarDatePicker(initialDate: selected, firstDate: DateTime(2000), lastDate: DateTime(2100), onDateChanged: (d) => setState(() => selected = d)),
        Text(date, style: Theme.of(context).textTheme.titleLarge),
        if (dayEvents.isEmpty) Text(widget.hindi ? 'इस दिन कोई इवेंट नहीं' : 'No events for this day'),
        for (final e in dayEvents) ListTile(leading: const Icon(Icons.event), title: Text(e.split('|').skip(1).join('|')), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () async { events.remove(e); final p = await SharedPreferences.getInstance(); await p.setStringList('calendar_events', events); setState(() {}); })),
      ]));
  }
}
