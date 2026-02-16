import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

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
    final DocumentScanningResult result =
    await documentScanner.scanDocument();

    if (result.images.isNotEmpty) {
      setState(() {
        scannedImage = File(result.images.first);
      });
    }
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
