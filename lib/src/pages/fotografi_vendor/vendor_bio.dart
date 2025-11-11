import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';
import 'vendor_pilihan_paket.dart';
import 'vendor_singlepage.dart';

class VendorBio extends StatefulWidget {
  const VendorBio({super.key});

  @override
  State<VendorBio> createState() => _VendorBioState();
}

class _VendorBioState extends State<VendorBio> {
  /// Daftar nama file gambar (atau URL) portfolio
  final List<String> _imageList = [
   
  ];

  /// Status load tiap gambar
  late List<bool> _imageLoaded;
  bool _avatarLoaded = false;

  /// True bila SEMUA gambar sudah selesai di-load ⇒ shimmer diangkat
  bool _allImagesLoaded = false;

  @override
  void initState() {
    super.initState();

    _imageList.add('portfolio_wedding1.jpeg');
     _imageList.add('portfolio_wedding2.jpg');
      _imageList.add('portfolio_wedding3.jpg');
       _imageList.add('portfolio_random4.jpg');
        _imageList.add('portfolio_random5.jpg');
    // Inisialisasi list status loading
    _imageLoaded = List<bool>.filled(_imageList.length, false);
  }

  

  /// Dipanggil setiap gambar selesai (atau gagal) dimuat
  void _handleImageFinish(int index) {
    _imageLoaded[index] = true;

    // Jika semua true, matikan shimmer
    if (_imageLoaded.every((loaded) => loaded)) {
      setState(() {
        _allImagesLoaded = true;
      });
    }
  }
  void _handleAvatarFinish() {
  if (!_avatarLoaded) {
    setState(() {
      _avatarLoaded = true;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();

    return Scaffold(
      appBar: AppBar(
  backgroundColor: const Color(0xFFF9F9F9),
  elevation: 1,
  leading: CustomBackButton(),
  title: const Text(
    'jordanlangton',
    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.settings, color: Colors.black),
      tooltip: 'Pengaturan',
      onPressed: () async {
        final nav = context.read<NavigationProvider>();
        await nav.handleLogout(context);
      },
    ),
  ],
),

      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ---------- Biodata & rating ----------
              Row(
                children: [
                 _buildAvatar('photographer_icon.png'),

                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jordan Langton',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Surabaya, Indonesia',
                            style:
                                TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      SizedBox(width: 4),
                      Text('4.5',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                'Fotografer pernikahan dengan gaya dokumenter dan sentuhan sinematik. '
                'Siap menangkap momen terbaik Anda.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              /// ---------- Tombol aksi ----------
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColorVendor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VendorPilihanPaket()),
                          );
                        },
                        child: const Text('Paket Saya',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              /// ---------- Grid portfolio + shimmer ----------
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  _imageList.length,
                  (i) => _buildPortfolioItem(
                    context: context,
                    imagePath: _imageList[i],
                    index: i,
                    nav: nav,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildAvatar(String imagePath) {
  final String imgUrl = context.read<NavigationProvider>().ambilGambar(imagePath);

  return ClipOval(
    child: Stack(
      alignment: Alignment.center,
      children: [
        CachedNetworkImage(
          imageUrl: imgUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          imageBuilder: (context, imageProvider) {
            // kalau sudah berhasil load
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleAvatarFinish();
            });
            return Image(image: imageProvider, fit: BoxFit.cover);
          },
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 60,
              height: 60,
              color: Colors.white,
            ),
          ),
          errorWidget: (context, url, error) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleAvatarFinish();
            });
            return Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined, size: 30),
            );
          },
        ),
      ],
    ),
  );
}



  /// Widget satu slot portfolio
 Widget _buildPortfolioItem({
  required BuildContext context,
  required String imagePath,
  required int index,
  required NavigationProvider nav,
}) {
  final String imgUrl = nav.ambilGambar(imagePath);

  return GestureDetector(
    onTap: () => nav.navigateToPage(
      context,
      const VendorSinglePostPage(),
      targetTabIndex: 0,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: imgUrl,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) {
          if (!_imageLoaded[index]) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleImageFinish(index);
            });
          }
          return Image(image: imageProvider, fit: BoxFit.cover);
        },
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white),
        ),
        errorWidget: (context, url, error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleImageFinish(index);
          });
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, size: 40),
          );
        },
      ),
    ),
  );
}


}
