import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:engginering/controllers/auth_controller.dart';
import 'package:engginering/widgets/drive_image_view.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const ProfileAvatar({
    Key? key,
    this.radius = 20,
    this.onTap,
    this.showEditIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Obx(() {
      final profileUrl = authController.profileImageUrl.value;

      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey.shade200,
              child: profileUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: DriveImageView(
                        url: profileUrl,
                        width: radius * 2,
                        height: radius * 2,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: radius,
                      color: Colors.grey,
                    ),
            ),
            if (showEditIcon)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(radius / 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: radius / 3,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
