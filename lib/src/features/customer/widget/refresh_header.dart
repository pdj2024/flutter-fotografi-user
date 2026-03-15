// ═══════════════════════════════════════════════════════════════
// SMART REFRESH HEADER — Pull Progress + Refresh Indicator
//
// Cara pakai:
//   SmartRefresher(
//     controller: _refreshController,
//     header: buildRefreshHeader(),   ← ganti _buildRefreshHeader()
//     onRefresh: _onRefresh,
//     child: ...,
//   )
//
// Catatan: triggerDistance default SmartRefresher = 80.0
// Sesuaikan _kTriggerDistance jika kamu set headerTriggerDistance berbeda.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// Jarak tarik untuk memicu refresh (harus sama dengan headerTriggerDistance)
const double _kTriggerDistance = 80.0;

/// Drop-in replacement untuk _buildRefreshHeader().
/// Taruh di dalam SmartRefresher sebagai `header:`.
Widget buildRefreshHeader({bool reverse = false}) =>
    _PullProgressHeader(reverse: reverse);

class _PullProgressHeader extends StatefulWidget {
  final bool reverse;
  const _PullProgressHeader({this.reverse = false});

  @override
  State<_PullProgressHeader> createState() => _PullProgressHeaderState();
}

class _PullProgressHeaderState extends State<_PullProgressHeader> {
  // progress 0.0–1.0 saat ditarik, diupdate via LayoutBuilder trick
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    // CustomHeader memberi kita `mode` dan bisa baca offset dari
    // RefreshIndicator internal lewat LayoutBuilder + context trick.
    // Cara paling reliable: pakai notifikasi dari parent SmartRefresher.
    return CustomHeader(
      height: 64,
      refreshStyle: RefreshStyle.Follow,
      onOffsetChange: (offset) {
        // offset = jarak tarik saat ini (dalam px, positif)
        final progress = (offset / _kTriggerDistance).clamp(0.0, 1.0);
        if (_progress != progress) {
          setState(() => _progress = progress);
        }
      },
      builder: (context, mode) {
        return _HeaderContent(
            mode: mode, progress: _progress, reverse: widget.reverse);
      },
    );
  }
}

class _HeaderContent extends StatelessWidget {
  final RefreshStatus? mode;
  final double progress;
  final bool reverse;

  const _HeaderContent(
      {required this.mode, required this.progress, required this.reverse});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.black12,
      alignment: Alignment.center,
      child:
          Transform.rotate(angle: reverse ? 3.14 : 0.0, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    // ── Refreshing ────────────────────────────────────────────
    if (mode == RefreshStatus.refreshing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(Colors.grey.shade800),
            ),
          ),
          // const SizedBox(width: 12),
          // Text(
          //   'Memperbarui profil...',
          //   style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          // ),
        ],
      );
    }

    // ── Completed ─────────────────────────────────────────────
    if (mode == RefreshStatus.completed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 18, color: Colors.green.shade400),
          const SizedBox(width: 8),
          Text(
            'Data berhasil diperbarui',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
        ],
      );
    }

    // ── Failed ────────────────────────────────────────────────
    if (mode == RefreshStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 18, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Text(
            'Gagal memperbarui',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
        ],
      );
    }

    // ── Idle / canRefresh → tampilkan pull progress circle ────
    final bool canRelease = mode == RefreshStatus.canRefresh;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle progress yang terisi seiring tarikan
        SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Track (background circle)
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Colors.grey.shade400),
              ),
              // Foreground: progress saat tarik, penuh saat canRefresh
              CircularProgressIndicator(
                value: canRelease ? 1.0 : progress,
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(
                  canRelease ? Colors.grey.shade800 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        // const SizedBox(width: 12),
        // AnimatedSwitcher(
        //   duration: const Duration(milliseconds: 200),
        //   child: Text(
        //     canRelease ? 'Lepaskan untuk memperbarui' : 'Tarik untuk memperbarui',
        //     key: ValueKey(canRelease),
        //     style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        //   ),
        // ),
      ],
    );
  }
}
