import 'package:flutter/material.dart';
import 'package:engginering/widgets/profile_avatar.dart';
import 'package:engginering/pages/profile_page.dart';

class UserProfileIcon extends StatelessWidget {
  final double radius;

  const UserProfileIcon({
    Key? key,
    this.radius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ProfileAvatar(radius: radius),
      ),
    );
  }
}
