import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;


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
  File? scannedImage;

  final DocumentScanner documentScanner = DocumentScanner(
    options: DocumentScannerOptions(
      mode: ScannerMode.full,
      pageLimit: 1,
      isGalleryImport: true, // ✅ Enables gallery inside scanner UI
    ),
  );

  Future<void> scanDocument() async {
    //  Delete previous scanned image file
    if (scannedImage != null && await scannedImage!.exists()) {
      await scannedImage!.delete();
      scannedImage = null;
    }

    final DocumentScanningResult result =
    await documentScanner.scanDocument();

    if (result.images.isNotEmpty) {
      setState(() {
        scannedImage = File(result.images.first);
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
    if (scannedImage == null) return;

    await requestPermission();
    final dir = await getPublicDownloadDirectory();

    final String path =
        "${dir.path}/scanned_${DateTime.now().millisecondsSinceEpoch}.png";

    await scannedImage!.copy(path);

    showSnack("Saved as PNG\n$path");
  }

// Save as PDF  (DOC option = PDF)
  Future<void> saveAsPdf() async {
    if (scannedImage == null) return;

    await requestPermission();
    final dir = await getPublicDownloadDirectory();

    final String path =
        "${dir.path}/scanned_${DateTime.now().millisecondsSinceEpoch}.pdf";

    final pdf = pw.Document();

    final imageBytes = await scannedImage!.readAsBytes();
    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          );
        },
      ),
    );

    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    showSnack("Saved as PDF\n$path");
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
            if (scannedImage != null) ...[
              const Text("Scanned Document"),
              const SizedBox(height: 10),
              Image.file(scannedImage!, height: 300),
              const SizedBox(height: 20),

              // SAVE BUTTON
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
