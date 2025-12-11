import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';

class ChatItemShimmer extends StatelessWidget {
  const ChatItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ShimmerPlaceholder(
        width: 48,
        height: 48,
        radius: 30,
      ),
      title: Row(
        children: [
          Expanded(
            child: ShimmerPlaceholder(
              height: 20,
              radius: 5,
            ),
          ),
          SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 50,
            child: ShimmerPlaceholder(
              height: 20,
              radius: 5,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: ShimmerPlaceholder(
              height: 15,
              radius: 5,
            ),
          ),
          SizedBox(
            width: 100,
          ),
        ],
      ),
    );
  }
}
