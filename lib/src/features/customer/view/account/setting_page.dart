import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/features/customer/view/account/legal_page.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/confirm_dialog.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Section: Informasi ────────────────────────────
          _SectionLabel(label: 'Informasi'),
          _SettingCard(
            children: [
              _SettingTile(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFFE67E22),
                iconBg: const Color(0xFFFEF3E8),
                title: 'Kebijakan Privasi',
                subtitle: 'Cara kami melindungi data Anda',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalPage(type: LegalType.privacy),
                  ),
                ),
              ),
              _Divider(),
              _SettingTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF2980B9),
                iconBg: const Color(0xFFE8F4FD),
                title: 'Syarat & Ketentuan',
                subtitle: 'Aturan penggunaan aplikasi',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalPage(type: LegalType.terms),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Section: Lainnya ──────────────────────────────
          _SectionLabel(label: 'Lainnya'),
          _SettingCard(
            children: [
              _SettingTile(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFE74C3C),
                iconBg: const Color(0xFFFDECEC),
                title: 'Keluar',
                subtitle: 'Logout dari akun ini',
                titleColor: const Color(0xFFE74C3C),
                onTap: () {
                  ConfirmDialog.showLogoutDialog(
                    context: context,
                    onConfirm: () {
                      final navProv = Provider.of<NavigationProvider>(context,
                          listen: false);
                      navProv.handleLogout(context);
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── App version ───────────────────────────────────
          Center(
            child: Text(
              'Versi 1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }
}
