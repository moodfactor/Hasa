import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/firebase_options.dart';
import 'package:my_project/notifications/controller/notification_provider.dart';
import 'package:my_project/notifications/notification_screen.dart';
import 'package:my_project/utils/fcm.dart';
import 'package:my_project/utils/security_service.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'splash_screen.dart';

// مفتاح Navigator عام
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable secure mode to prevent screenshots and recordings
  // SecurityService.enableSecureMode(); // Commented out to allow screenshots and recordings

  // Explicitly disable secure mode to allow screenshots and recordings
  SecurityService.disableSecureMode();

  // Eliminar el delay que muestra el logo de Flutter
  // await Future.delayed(const Duration(milliseconds: 2000)); // comment
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FcmApi().initNotifications(navigatorKey);
  runApp(DevicePreview(
      enabled: false,
      builder: (context) => ShowCaseWidget(
            builder: (context) => ChangeNotifierProvider(
                create: (context) =>
                    NotificationProvider()..fetchNotifications(),
                child: const MyApp()),
          )));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 500) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData(
          fontFamily: 'Cairo',
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}
