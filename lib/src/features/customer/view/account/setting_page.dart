import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/confirm_dialog.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        leading: CustomBackButton(),
        elevation: 1,
        title: Text(
          "Pengaturan",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListView(
          children: [
            // logout
            ListTile(
              splashColor: Colors.black12,
              trailing: Icon(
                Icons.logout,
                color: Colors.redAccent,
              ),
              title: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text("Keluar",
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
              onTap: () {
                ConfirmDialog.showLogoutDialog(
                  context: context,
                  onConfirm: () {
                    final navProv =
                        Provider.of<NavigationProvider>(context, listen: false);
                    navProv.handleLogout(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
