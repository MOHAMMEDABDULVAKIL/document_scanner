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
      isGalleryImport: true, // ✅ Enables gallery inside scanner UI
    ),
  );

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


  // ================= SAVE HELPERS =================

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }



  Future<Directory> getPublicDownloadDirectory() async {
    if (Platform.isAndroid) {
      final Directory dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }



// Save as PNG
  Future<void> saveAsImage() async {
    if (scannedImages.isEmpty) return;

    await requestPermission();
    final dir = await getPublicDownloadDirectory();

    for (int i = 0; i < scannedImages.length; i++) {
      final String path =
          "${dir.path}/scan_page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.png";

      await scannedImages[i].copy(path);
    }

    showSnack("Saved ${scannedImages.length} images as PNG in Download folder");
  }


// Save as PDF  (DOC option = PDF)
  Future<void> saveAsPdf() async {
    if (scannedImages.isEmpty) return;

    await requestPermission();
    final dir = await getPublicDownloadDirectory();

    final String path =
        "${dir.path}/scanned_${DateTime.now().millisecondsSinceEpoch}.pdf";

    final pdf = pw.Document();

    for (var imgFile in scannedImages) {
      final imageBytes = await imgFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    showSnack("Multi-page PDF saved\n$path");
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
