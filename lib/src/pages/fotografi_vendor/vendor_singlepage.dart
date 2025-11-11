import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/vendor_bio.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';


import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';


class VendorSinglePostPage extends StatefulWidget {
 

  const VendorSinglePostPage({super.key});

  @override
  _VendorSinglePostPageState createState() => _VendorSinglePostPageState();
}

class _VendorSinglePostPageState extends State<VendorSinglePostPage> {
  bool isLiked = false;
  bool isSaved = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
         leading: CustomBackButton(),
        title: const Text(
          "Portofolio",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (user info + rating)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
  children: [
   SizedBox(
  width: 32,
  height: 32,
  child: ClipOval(
    child: CachedNetworkImage(
      imageUrl: context.read<NavigationProvider>().ambilGambar('photographer_icon.png'),
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey,
        child: const Icon(Icons.error, color: Colors.red, size: 16),
      ),
    ),
  ),
),
    const SizedBox(width: 12),
    Expanded(
      child: GestureDetector(
       onTap: () => context.read<NavigationProvider>().vendorNavigateToPage(
                          context, VendorBio(), targetTabIndex:0, ),
   
        child: Row(
          children: [
            const Text(
              "Jordan Langton",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 2),
            const Text(
              "4.5",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    ),
    SizedBox(
      height: 44,
      width: 44,
    //   child: OutlinedButton(
    //     style: OutlinedButton.styleFrom(
    //       side: const BorderSide(color: Constants.primaryColorVendor),
    //       shape: RoundedRectangleBorder(
    //         borderRadius: BorderRadius.circular(20),
    //       ),
    //       padding: EdgeInsets.zero,
    //     ),
    //     onPressed: () {
    // //  context.read<NavigationProvider>().navigateToPage(
    // //                       context, SingleChat(), targetTabIndex:1, );
    //     },
    //     child: const Icon(Icons.chat_outlined, color: Constants.primaryColorVendor),
    //   ),
    ),
  ],
)

            ),

            // Image
            ClipRRect(
  child: CachedNetworkImage(
    imageUrl: context.read<NavigationProvider>().ambilGambar('portfolio_wedding1.jpeg'),
    width: double.infinity,
    height: screenHeight * 0.4,
    fit: BoxFit.cover,
    placeholder: (context, url) => Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.4,
        color: Colors.white,
      ),
    ),
    errorWidget: (context, url, error) => Container(
      width: double.infinity,
      height: screenHeight * 0.4,
      color: Colors.grey,
      child: const Icon(Icons.error, color: Colors.red),
    ),
  ),
),


            // Like, Comment, Save
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isLiked = !isLiked;
                      });
                    },
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.black,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 28,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isSaved = !isSaved;
                      });
                    },
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? Colors.amber : Colors.black,
                      size: 29,
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text("2,516 likes", style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            
            const OfferCard(
              title: "Paket Wedding",
              price: "IDR 500,000",
              includes: [
                "3 jam, 50 png",
                "Hasil via Google Drive",
                "Termasuk Jasa Edit",
              ],
            ),
            // buildPackageCard(
            //   title: "Wedding Package",
            //   price: "IDR 500,000",
            //   duration: "6 jam",
            //   photos: "200 foto",
            // ),
          ],
        ),
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> includes;

  const OfferCard({
    super.key,
    required this.title,
    required this.price,
    required this.includes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text("Rincian", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...includes.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text("• $item", style: const TextStyle(fontSize: 13)),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColorVendor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                  //  context.read<NavigationProvider>().navigateToPage(
                  //         context, 
                  //         SingleChat( ), targetTabIndex:1, );
              },
              child: const Text("Atur Jadwal", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  
}

Widget buildPackageCard({
    required String title,
    required String price,
    required String duration,
    required String photos,
  }) {
    return Container(
     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              Text(price,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• $duration"),
                  Text("• $photos"),
                  const Text("• Google Drive"),
                ],
              )),
          // const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColorVendor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {},
              child: const Text('Atur Jadwal',
                  style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

