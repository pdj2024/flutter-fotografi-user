import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';

class RoomChatShimmer extends StatelessWidget {
  const RoomChatShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 2,
          shadowColor: Colors.black12,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: ClipOval(
                child: ShimmerPlaceholder(
                  height: 40,
                  width: 40,
                  isCircle: true,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                child: ShimmerPlaceholder(
                  radius: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShimmerPlaceholder(
                  height: 40,
                  radius: 5,
                ),
              ),
              const SizedBox(width: 50),
            ],
          ),
          toolbarHeight: 72,
        ),
        backgroundColor: const Color(0xFFF9F9F9),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final bool isSender =
                        index.isEven; // contoh pola bubble kiri/kanan
      
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: isSender
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Bubble shimmer
                          ShimmerPlaceholder(
                            height: 48,
                            radius: 14,
                            width: MediaQuery.of(context).size.width *
                                (isSender
                                    ? 0.55
                                    : 0.75), // bubble lebih pendek di kanan
                          ),
      
                          const SizedBox(height: 6),
      
                          // Bubble shimmer lebih pendek (variasi)
                          ShimmerPlaceholder(
                            height: 38,
                            radius: 14,
                            width: MediaQuery.of(context).size.width *
                                (isSender ? 0.40 : 0.60),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ShimmerPlaceholder(
                  height: 50,
                  radius: 50,
                ),
              ),
              SizedBox(
                height: 10,
              )
            ],
          ),
        ),
      ),
    );
  }
}
