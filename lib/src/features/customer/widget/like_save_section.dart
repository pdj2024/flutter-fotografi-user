import 'package:flutter/material.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/portofolio_service.dart';
import 'package:provider/provider.dart';

class LikeSaveSection extends StatefulWidget {
  final bool isLiked;
  final bool isSaved;
  final int likeCount;
  final String portofolioId;
  const LikeSaveSection({
    super.key,
    required this.isLiked,
    required this.isSaved,
    required this.likeCount,
    required this.portofolioId,
  });

  @override
  State<LikeSaveSection> createState() => _LikeSaveSectionState();
}

class _LikeSaveSectionState extends State<LikeSaveSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final prevLiked = widget.isLiked;
                  final prevCount = widget.likeCount;

                  setState(() {
                    widget.isLiked = !isLiked;
                    likeCount += isLiked ? 1 : -1; // update lokal langsung
                  });

                  try {
                    await PortofolioService().action(
                      no_id: context.read<UserProvider>().userId!,
                      id_portofolio: widget.portofolioId,
                      action_type: isLiked ? "like" : "unlike",
                    );
                  } catch (e) {
                    // rollback kalau error
                    setState(() {
                      isLiked = prevLiked;
                      likeCount = prevCount;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mengubah like: $e')),
                    );
                  }
                },
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.black,
                  size: 28,
                ),
              ),
              // const SizedBox(width: 16),
              // const Icon(Icons.chat_bubble_outline, size: 28),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final prevSaved = isSaved;

                  setState(() {
                    isSaved = !isSaved;
                  });

                  try {
                    await PortofolioService().action(
                      no_id: context.read<UserProvider>().userId!,
                      id_portofolio: widget.portofolioId,
                      action_type: isSaved ? "save" : "unsave",
                    );
                  } catch (e) {
                    // rollback kalau error
                    setState(() {
                      isSaved = prevSaved;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mengubah save: $e')),
                    );
                  }
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
        // ✅ Sembunyikan likes jika null atau 0
        if (likeCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "$likeCount likes",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
