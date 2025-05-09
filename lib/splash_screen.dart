import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:my_project/utils/fcm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:my_project/maintenance_screen.dart';
import 'package:my_project/services/maintenance_service.dart';
import 'package:my_project/services/pin_security_service.dart';
import 'package:my_project/screens/pin_lock_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'Feature/Auth/presentation/view/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    _checkMaintenanceAndOnboardingStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkMaintenanceAndOnboardingStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    final isInMaintenance = await MaintenanceService().checkMaintenanceStatus();
    log("Maintenance check result: $isInMaintenance");

    if (isInMaintenance) {
      _navigateTo(const MaintenanceScreen());
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool? onboardingCompleted = prefs.getBool('onboarding_completed');
    final String? userJson = prefs.getString('user_data');

    if (onboardingCompleted == null || onboardingCompleted == false) {
      _navigateTo(const OnboardingScreen());
    } else if (userJson != null) {
      await _fetchAndUpdateUserData();
      await firebaseToken();
    } else {
      _navigateTo(const LoginScreen());
    }
  }

  Future<void> _fetchAndUpdateUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');

    if (userJson == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    Map<String, dynamic> storedUserData = jsonDecode(userJson);
    String? email = storedUserData['email'];

    if (email == null || email.isEmpty) {
      _navigateTo(const LoginScreen());
      return;
    }

    bool? tfaCompleted = prefs.getBool('tfa_completed');
    int tfaStatus = storedUserData['ts'] ?? 0;

    if (tfaStatus == 1 && (tfaCompleted == null || tfaCompleted == false)) {
      log('المصادقة الثنائية مفعلة ولم تكتمل - توجيه إلى صفحة تسجيل الدخول');
      _navigateTo(const LoginScreen());
      return;
    }

    try {
      var dio = Dio();
      var response = await dio.get(
        'https://ha55a.exchange/api/v1/auth/user-data.php?email=$email',
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        Map<String, dynamic> fetchedUserData = response.data['data'];

        if (fetchedUserData['status'] == 0) {
          await _logout();
          return;
        }

        if (!_isDataEqual(storedUserData, fetchedUserData)) {
          await prefs.setString('user_data', jsonEncode(fetchedUserData));
        } else {}

        _navigateTo(const HomeScreen());
      } else {
        _navigateTo(const LoginScreen());
      }
    } catch (e) {
      _navigateTo(const LoginScreen());
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _navigateTo(const LoginScreen());
  }

  bool _isDataEqual(
      Map<String, dynamic> oldData, Map<String, dynamic> newData) {
    return jsonEncode(oldData) == jsonEncode(newData);
  }

  void _navigateTo(Widget screen) {
    // Check if PIN is set and show PIN lock screen if needed
    _checkAndShowPinLock(screen);
  }

  Future<void> _checkAndShowPinLock(Widget nextScreen) async {
    final PinSecurityService pinService = PinSecurityService();
    final isPinSet = await pinService.isPinSet();

    if (isPinSet) {
      // PIN is set, show PIN lock screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => PinLockScreen(nextScreen: nextScreen)),
      );
    } else {
      // PIN not set, proceed normally
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  Future<void> firebaseToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('user_data');

      if (userJson == null) {
        log('No user data found in SharedPreferences');
        return;
      }

      Map<String, dynamic> userData = jsonDecode(userJson);
      log('User ID: ${userData['id']}');

      String? token = await FcmApi().getToken();
      log('Firebase Token: $token');

      if (token == null) {
        log('Error: Firebase token is null');
        return;
      }

      var data = FormData.fromMap({
        'user_id': '${userData['id']}',
        'firebase_token': token,
      });

      var dio = Dio();
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/auth/update_token.php',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        log('Response: ${jsonEncode(response.data)}');
      } else {
        log('Server Error: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      log('Dio Error: ${e.message}');
      if (e.response != null) {
        log('Response Data: ${e.response?.data}');
        log('Response Status Code: ${e.response?.statusCode}');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        log('Error: Connection timeout');
      } else if (e.type == DioExceptionType.sendTimeout) {
        log('Error: Send timeout');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        log('Error: Receive timeout');
      } else if (e.type == DioExceptionType.badResponse) {
        log('Error: Invalid status code: ${e.response?.statusCode}');
      } else if (e.type == DioExceptionType.unknown) {
        log('Error: No internet connection or unknown error');
      }
    } catch (e) {
      log('Unexpected Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 226.26,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
