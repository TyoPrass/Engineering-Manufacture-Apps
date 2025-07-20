import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:engginering/controllers/auth_controller.dart';
import 'package:engginering/widgets/profile_avatar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() => UserAccountsDrawerHeader(
                accountName: Text(authController.username.value),
                accountEmail: Text(authController.userEmail.value),
                currentAccountPicture: ProfileAvatar(radius: 30),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
              )),

          // ...existing drawer items...

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),

          // ...existing drawer items...
        ],
      ),
    );
  }
}
