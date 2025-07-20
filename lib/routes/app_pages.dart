import 'package:get/get.dart';
import 'package:engginering/pages/login_page.dart';
import 'package:engginering/pages/register_page.dart';
import 'package:engginering/pages/home_page.dart';

part 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => RegisterPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.HOME,
      page: () => HomePage(),
      transition: Transition.fadeIn,
    ),
  ];
}
