import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ReviewUploadPage extends StatefulWidget {
  final File file; // hanya satu file

  const ReviewUploadPage({super.key, required this.file});

  @override
  State<ReviewUploadPage> createState() => _ReviewUploadPageState();
}

class _ReviewUploadPageState extends State<ReviewUploadPage> {
  bool _uploading = false;

  void showPersistentDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // Tidak bisa ditutup dengan tap di luar
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: SelectableText(message), // Bisa di-select & di-copy manual juga
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Copied to clipboard")),
              );
            },
            child: Text("Copy"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      );
    },
  );
}

  Future<void> _upload() async {
  setState(() => _uploading = true);

  final user = FirebaseAuth.instance.currentUser;
  final email = user?.email ?? 'unknown';
  final uri = Uri.parse('https://fotoapi.pdj.web.id/api/files/image/$email');

  try {
    final request = http.MultipartRequest('POST', uri);

    final mimeType = lookupMimeType(widget.file.path) ?? 'application/octet-stream';
    final mimeSplit = mimeType.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        widget.file.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (!mounted) return;

    if (response.statusCode == 200) {
      // Success case: body might still contain useful message
      showPersistentDialog(context, "Success", "Upload successful: ${response.body}");
      Navigator.pop(context);
    } else {
      // Failure case: show raw response body to help debug
      showPersistentDialog(context, "Upload Failed",
        "Status: ${response.statusCode}\nBody: ${response.body}");
    }
  } catch (e) {
    if (!mounted) return;
    showPersistentDialog(context, "Upload Error", 'Upload error: $e');
  } finally {
    if (mounted) {
      setState(() => _uploading = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Upload'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(widget.file, fit: BoxFit.contain),
          ),
          if (_uploading)
            const LinearProgressIndicator(minHeight: 4)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _upload,
                child: const Text('Upload'),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
