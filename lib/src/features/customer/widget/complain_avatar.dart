import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/complain_model.dart';

/// Avatar pengirim pesan Complain.
///
/// Payload complain tidak membawa foto profil, jadi [vendorPhotoUrl] di-resolve
/// oleh halaman pemanggil (foto vendor pada order terkait). Pengirim selain
/// vendor jatuh ke avatar inisial — sama seperti halaman chat.
class ComplainAvatar extends StatelessWidget {
  final ComplainMessageModel message;

  /// URL foto untuk pesan ber-`tipeUser` vendor. Null/kosong -> inisial.
  final String? vendorPhotoUrl;

  final double radius;

  const ComplainAvatar({
    super.key,
    required this.message,
    this.vendorPhotoUrl,
    this.radius = 11,
  });

  /// Palet tetap supaya orang yang sama selalu dapat warna yang sama.
  static const List<Color> _palette = [
    Color(0xFF3B3ADD),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFD97706),
    Color(0xFF0284C7),
    Color(0xFFDB2777),
  ];

  String get _initial {
    final name = message.senderNama.trim();
    if (name.isEmpty) return '';
    return name[0].toUpperCase();
  }

  Color get _initialColor =>
      _palette[message.senderNama.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    if (message.isAdmin) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Constants.primaryColor.withOpacity(0.12),
        child: Icon(
          Icons.support_agent_rounded,
          size: radius * 1.1,
          color: Constants.primaryColor,
        ),
      );
    }

    final isVendor = message.tipeUser.toLowerCase() == 'vendor';
    final photo = vendorPhotoUrl;
    if (isVendor && photo != null && photo.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: CachedNetworkImage(
          imageUrl: photo,
          imageBuilder: (_, imageProvider) =>
              CircleAvatar(radius: radius, backgroundImage: imageProvider),
          placeholder: (_, __) =>
              ShimmerPlaceholder(width: size, height: size, radius: radius),
          errorWidget: (_, __, ___) => _initialAvatar(),
        ),
      );
    }

    return _initialAvatar();
  }

  Widget _initialAvatar() {
    final initial = _initial;
    return CircleAvatar(
      radius: radius,
      backgroundColor: _initialColor.withOpacity(0.15),
      child: initial.isEmpty
          ? Icon(Icons.person, size: radius, color: _initialColor)
          : Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.95,
                fontWeight: FontWeight.w700,
                color: _initialColor,
              ),
            ),
    );
  }
}
