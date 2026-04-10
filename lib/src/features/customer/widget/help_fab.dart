import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpFab extends StatefulWidget {
  const HelpFab({super.key});

  @override
  State<HelpFab> createState() => _HelpFabState();
}

class _HelpFabState extends State<HelpFab> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  bool _showTooltip = true;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  static const _waNumber = '62895353837000';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    // Auto-hide tooltip setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTooltip = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _showTooltip = false;
    });
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Future<void> _openWhatsApp({String? message}) async {
    final encoded = Uri.encodeComponent(
      message ?? 'Halo, saya butuh bantuan mengenai aplikasi MPJ Vendor.',
    );
    final uri = Uri.parse('https://wa.me/$_waNumber?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    _toggle();
  }

  Future<void> _openFaq() async {
    // Arahkan ke halaman FAQ atau URL dokumentasi
    // Navigator.push(context, MaterialPageRoute(builder: (_) => FaqPage()));
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Menu items (muncul saat open) ─────────────────────
        ScaleTransition(
          scale: _scaleAnim,
          alignment: Alignment.bottomRight,
          child: _isOpen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MenuItem(
                      icon: Icons.wechat_sharp,
                      iconColor: const Color(0xFF0F6E56),
                      iconBg: const Color(0xFFE1F5EE),
                      label: 'Butuh bantuan?',
                      onTap: () => _openWhatsApp(),
                    ),
                    const SizedBox(height: 8),
                    // _MenuItem(
                    //   icon: Icons.help_outline_rounded,
                    //   iconColor: const Color(0xFF534AB7),
                    //   iconBg: const Color(0xFFEEEDFE),
                    //   label: 'Panduan & FAQ',
                    //   onTap: _openFaq,
                    // ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // ── FAB row (tooltip + button) ─────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tooltip
            AnimatedOpacity(
              opacity: _showTooltip ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Butuh bantuan?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // FAB button dengan pulse
            _AnimatedFab(
              isOpen: _isOpen,
              onTap: _toggle,
            ),
          ],
        ),
      ],
    );
  }
}

// ── FAB dengan pulse animation ─────────────────────────────────────────────

class _AnimatedFab extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const _AnimatedFab({required this.isOpen, required this.onTap});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 1, end: 1.5).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring (hanya saat tertutup)
            // if (!widget.isOpen)
            //   AnimatedBuilder(
            //     animation: _pulseAnim,
            //     builder: (_, __) => Transform.scale(
            //       scale: _pulseAnim.value,
            //       child: Container(
            //         width: 52,
            //         height: 52,
            //         decoration: BoxDecoration(
            //           shape: BoxShape.circle,
            //           border: Border.all(
            //             color: const Color.fromARGB(255, 161, 253, 193)
            //                 .withOpacity(1 - (_pulseAnim.value - 1) / 0.5),
            //             width: 2,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // FAB
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.isOpen
                    ? Colors.grey.shade200
                    : const Color.fromARGB(255, 217, 255, 230),
                shape: BoxShape.circle,
                boxShadow: [
                  if (!widget.isOpen)
                    BoxShadow(
                      color: const Color(0xFF25D366).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.isOpen ? Icons.close_rounded : Icons.chat_rounded,
                  key: ValueKey(widget.isOpen),
                  color: widget.isOpen
                      ? Colors.grey.shade700
                      : const Color(0xFF25D366),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu item chip ─────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
