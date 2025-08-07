import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/constants.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';


class VendorPilihanPaket extends StatelessWidget {
  const VendorPilihanPaket({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: const Text(
          "Paket Saya",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xfff9f9f9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Profil Header
            // Container(
            //   margin: const EdgeInsets.only(top: 20, bottom: 16),
            //   child: GestureDetector(
            //     //  onTap: () => context.read<NavigationProvider>().navigateToPage(
            //     //           context, PhotographerBio(), targetTabIndex:0, ),
            //     onTap: () {},
            //     child: Row(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         CircleAvatar(
            //           radius: 30,
                     
            //           backgroundImage: NetworkImage(context.read<NavigationProvider>().ambilGambar('photographer_icon.png')),
            //         ),
            //         const SizedBox(width: 12),
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               const Text(
            //                 'Jordan Langton',
            //                 style: TextStyle(
            //                     fontSize: 16, fontWeight: FontWeight.bold),
            //               ),
            //               const SizedBox(height: 2),
            //               const Text(
            //                 'Photographer',
            //                 style: TextStyle(fontSize: 13),
            //               ),
            //               const SizedBox(height: 2),
            //               Row(
            //                 children:  [
            //                   Icon(Icons.location_on_outlined,
            //                       size: 14, color: Colors.grey.shade600),
            //                   SizedBox(width: 4),
            //                   Text(
            //                     'Surabaya',
            //                     style:
            //                         TextStyle(fontSize: 13, color: Colors.grey.shade600),
            //                   ),
            //                 ],
            //               ),
            //             ],
            //           ),
            //         ),
            //         const SizedBox(width: 12),
            //         Column(
            //           crossAxisAlignment: CrossAxisAlignment.end,
            //           children: [
            //             Row(
            //               children: const [
            //                 Icon(Icons.star, size: 20, color: Colors.amber),
            //                 SizedBox(width: 4),
            //                 Text(
            //                   '4.5',
            //                   style: TextStyle(
            //                       fontWeight: FontWeight.bold, fontSize: 14),
            //                 ),
            //               ],
            //             ),
            //             const SizedBox(height: 10),
            //             SizedBox(
            //               height: 44,
            //               width: 44,
            //               child: OutlinedButton(
            //                 style: OutlinedButton.styleFrom(
            //                   side:
            //                       const BorderSide(color: Constants.primaryColorVendor),
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(20),
            //                   ),
            //                   padding: EdgeInsets.zero,
            //                 ),
            //                 onPressed: () {
            //                 //    context.read<NavigationProvider>().navigateToPage(
            //                 // context, SingleChat(), targetTabIndex:1, );
            //                 },
            //                 child: const Icon(Icons.chat_outlined,
            //                     size: 20, color: Constants.primaryColorVendor),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            SizedBox(height: 26),
            // List Paket
            buildPackageCard(
                context: context, 
              title: "Wedding Package",
              price: "IDR 500,000",
              duration: "6 jam",
              photos: "200 foto",
                isActive: true
            ),
            buildPackageCard(
                context: context, 
              title: "Engagement Package",
              price: "IDR 300,000",
              duration: "2 jam",
              photos: "100 foto",
              isActive: false
            ),
           
          ],
        ),
      ),
    );
  }

  Widget buildPackageCard({
  required BuildContext context,
  required String title,
  required String price,
  required String duration,
  required String photos,
  bool isActive = true, // Tambahan parameter opsional untuk status
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
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
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isActive ? 'TAYANG' : 'TIDAK TAYANG',
              style: TextStyle(
                color: isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
              
                        Row(
  children: [
    SizedBox(
      height: 44,
      width: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.primaryColorVendor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
          elevation: 0, // optional: remove shadow if you want it flat
        ),
        onPressed: () {
          // context.read<NavigationProvider>().navigateToPage(
          // context, SingleChat(), targetTabIndex: 1, );
        },
        child: const Icon(
          Icons.edit_outlined,
          size: 20,
          color: Colors.white,
        ),
      ),
    ),
    const SizedBox(width: 10),
    SizedBox(
      height: 44,
      width: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        onPressed: () {
          // context.read<NavigationProvider>().navigateToPage(
          // context, SingleChat(), targetTabIndex: 1, );
        },
        child: const Icon(
          Icons.delete_outlined,
          size: 20,
          color: Colors.white,
        ),
      ),
    ),
  ],
)

               
              ],
            ),
          ],
        ),
      ],
    ),
  );
}


}
