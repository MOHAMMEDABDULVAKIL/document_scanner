import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DocumentScannerPage(),
    );
  }
}

class DocumentScannerPage extends StatefulWidget {
  const DocumentScannerPage({super.key});

  @override
  State<DocumentScannerPage> createState() => _DocumentScannerPageState();
}

class _DocumentScannerPageState extends State<DocumentScannerPage> {
  List<File> scannedImages = [];

  final DocumentScanner documentScanner = DocumentScanner(
    options: DocumentScannerOptions(
      mode: ScannerMode.full,
      pageLimit: 10,
      isGalleryImport: true, // Enables gallery inside scanner UI
    ),
  );


  Future<String?> askFileName() async {
    TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter File Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Example: MathNotes",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ===== NEW STORAGE FUNCTIONS =====

  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  Future<Directory> getVisibleAppFolder(String type) async {
    if (Platform.isAndroid) {
      final Directory docsDir = Directory('/storage/emulated/0/Documents');

      final Directory appDir = Directory("${docsDir.path}/DocumentScanner");

      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      final Directory typeDir = Directory("${appDir.path}/$type");

      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }

      return typeDir;
    } else {
      final base = await getApplicationDocumentsDirectory();
      final typeDir = Directory("${base.path}/$type");

      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }

      return typeDir;
    }
  }

  Future<void> scanDocument() async {
    // Delete old files
    for (var file in scannedImages) {
      if (await file.exists()) {
        await file.delete();
      }
    }
    scannedImages.clear();

    final DocumentScanningResult result =
    await documentScanner.scanDocument();

    if (result.images.isNotEmpty) {
      setState(() {
        scannedImages = result.images.map((e) => File(e)).toList();
      });
    }
  }


// Save as PNG
  Future<void> saveAsImage() async {
    if (scannedImages.isEmpty) return;

    final fileName = await askFileName();
    if (fileName == null) return;

    await requestStoragePermission();
    final dir = await getVisibleAppFolder("PNG");

    for (int i = 0; i < scannedImages.length; i++) {
      final path = "${dir.path}/${fileName}_${i + 1}.png";
      await scannedImages[i].copy(path);
    }

    showSnack("Saved as $fileName in PNG folder");
  }


// Save as PDF  (DOC option = PDF)
  Future<void> saveAsPdf() async {
    if (scannedImages.isEmpty) return;

    final fileName = await askFileName();
    if (fileName == null) return;

    await requestStoragePermission();
    final dir = await getVisibleAppFolder("PDF");

    final path = "${dir.path}/$fileName.pdf";

    final pdf = pw.Document();

    for (var img in scannedImages) {
      final bytes = await img.readAsBytes();
      final image = pw.MemoryImage(bytes);

      pdf.addPage(
        pw.Page(
          build: (_) => pw.Center(child: pw.Image(image)),
        ),
      );
    }

    await File(path).writeAsBytes(await pdf.save());

    showSnack("Saved as $fileName.pdf in PDF folder");
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

// Save dialog
  void showSaveDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Save As"),
        content: const Text("Choose format"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              saveAsImage();
            },
            child: const Text("PNG Image"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              saveAsPdf();
            },
            child: const Text("DOC (PDF)"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Document Scanner")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (scannedImages.isNotEmpty) ...[
              const Text("Scanned Pages"),
              const SizedBox(height: 10),

              SizedBox(
                height: 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: scannedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text("Page ${index + 1}"),
                          const SizedBox(height: 5),
                          Image.file(scannedImages[index], height: 220),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: showSaveDialog,
                icon: const Icon(Icons.save),
                label: const Text("Save"),
              ),

              const SizedBox(height: 20),
            ],


            ElevatedButton.icon(
              onPressed: scanDocument,
              icon: const Icon(Icons.document_scanner),
              label: const Text("Scan Document"),
            ),
          ],
        ),
      ),
    );
  }
}
