import 'package:flutter/material.dart';

class ViewGambar extends StatelessWidget {
  final String imageUrl = 'https://webapi.pdj.web.id/api/files/qris_1747206265546.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview Gambar'),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 300, // Batas lebar maksimum
            maxHeight: 300, // Batas tinggi maksimum
          ),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text('Gagal memuat gambar');
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
