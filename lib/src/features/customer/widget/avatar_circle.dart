import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/utils/app_image.dart';

class AvatarCircle extends StatelessWidget {
  final String? imgUrl;
  final double size;
  const AvatarCircle({super.key, this.imgUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade300,
        child: ClipOval(
          child: (imgUrl == null || imgUrl!.trim().isEmpty)
              ? Container(
                  width: size,
                  height: size,
                  color: Colors.grey,
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 40),
                )
              : AppNetworkImage(
                  url: imgUrl!, // dijamin non-null
                  width: size,
                  height: size,
                  decodeWidth: decodeWidthFor(context, size),
                  errorWidget: Container(
                    width: size,
                    height: size,
                    color: Colors.grey,
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                ),
        ),
      ),
    );
  }
}
