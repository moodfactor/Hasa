import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../home_screen.dart';
import '../../../../tfa_otp_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

TextEditingController usernameController = TextEditingController();
TextEditingController passwordController = TextEditingController();

bool visable = true;

bool checked = false;

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  bool _showcaseInitialized = false;

  final formKey = GlobalKey<FormState>(debugLabel: 'loginFormKey');
  final GlobalKey _forgotPasswordKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
  }

  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase = prefs.getBool('hasSeenShowcase') ?? false;

    if (!hasSeenShowcase && mounted && !_showcaseInitialized) {
      setState(() {
        _showcaseInitialized = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            ShowCaseWidget.of(context).startShowCase([_forgotPasswordKey]);
            prefs.setBool('hasSeenShowcase', true);
          } catch (e) {
            print('Showcase error: $e');
          }
        }
      });
    }
  }

  void _showSuccessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet handle
              Container(
                width: 50.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),

              // Success icon
              Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.greenAccent.shade100,
                      Colors.green.shade50,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 50.sp,
                ),
              ),

              SizedBox(height: 24.h),

              // Success title with animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Text(
                  "تم تسجيل الدخول بنجاح",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A2530),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Success message
              Text(
                "HA55A مرحبا بك في تطبيق",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF646464),
                ),
              ),

              SizedBox(height: 32.h),

              // Confirmation button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF031E4B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                ),
                child: Text(
                  'حسنًا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _showErrorBottomSheet(BuildContext context, String errorMessage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet handle
              Container(
                width: 50.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),

              // Error icon
              Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.redAccent.shade100.withOpacity(0.3),
                      Colors.red.shade50,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_rounded,
                  color: Colors.red.shade500,
                  size: 50.sp,
                ),
              ),

              SizedBox(height: 24.h),

              // Error title with animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Text(
                  "حدث خطأ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A2530),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Error message
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF646464),
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Confirmation button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF031E4B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                ),
                child: Text(
                  'حسنًا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void login() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        var data = FormData.fromMap({
          'email': usernameController.text,
          'password': passwordController.text,
        });

        var dio = Dio();
        var response = await dio.post(
          'https://ha55a.exchange/api/v1/auth/login.php',
          data: data,
        );

        if (response.statusCode == 200) {
          var responseData = response.data;

          if (responseData['status'] == true) {
            Map<String, dynamic> userData = responseData['user'];

            log('${userData['id']}');
            log('${userData['kv']}');

            // طباعة جميع بيانات المستخدم
            log('=========== بيانات المستخدم ===========');
            log('المعرف: ${userData['id']}');
            log('البريد الإلكتروني: ${userData['email']}');
            log('اسم المستخدم: ${userData['username']}');
            log('الاسم الأول: ${userData['firstname']}');
            log('الاسم الثاني: ${userData['secondname']}');
            log('الاسم الأخير: ${userData['lastname']}');
            log('رقم الجوال: ${userData['mobile']}');
            log('حالة KYC: ${userData['kv']}');
            log('حالة المصادقة الثنائية: ${userData['ts']}');
            log('البيانات الكاملة: ${json.encode(userData)}');
            log('=========== نهاية بيانات المستخدم ===========');

            if (userData.isNotEmpty) {
              String userJson = jsonEncode(userData);

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_data', userJson);

              // Check if two-factor authentication is enabled
              int twoFaStatus = userData['ts'] ?? 0;

              if (twoFaStatus == 1) {
                // إضافة متغير يشير إلى أن المصادقة الثنائية قيد التنفيذ
                await prefs.setBool('tfa_completed', false);

                // 2FA is enabled - request OTP and navigate to TfaOtpScreen
                try {
                  // Call 2FA login API to send OTP
                  var tfaData = {"user_id": userData['id']};

                  var tfaResponse = await dio.post(
                    'https://ha55a.exchange/api/v1/auth/2fa-login.php',
                    data: tfaData,
                  );

                  if (tfaResponse.statusCode == 200) {
                    log('2FA OTP Request: ${json.encode(tfaResponse.data)}');

                    // Navigate to TfaOtpScreen
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TfaOtpScreen(
                            userId: userData['id'].toString(),
                          ),
                        ),
                      );
                    }
                  } else {
                    _showErrorBottomSheet(context,
                        'فشل في إرسال رمز التحقق. الرجاء المحاولة مرة أخرى.');
                  }
                } catch (e) {
                  log('Error in 2FA process: $e');
                  _showErrorBottomSheet(
                      context, 'حدث خطأ أثناء عملية المصادقة الثنائية.');
                }
              } else {
                // 2FA is disabled - proceed to home screen
                // ignore: use_build_context_synchronously
                _showSuccessBottomSheet(context);
              }
            } else {
              // ignore: use_build_context_synchronously
              _showErrorBottomSheet(context, 'بيانات المستخدم غير موجودة.');
            }
          } else {
            _showErrorBottomSheet(
                context, responseData['message'] ?? 'حدث خطأ غير متوقع.');
          }
        } else {
          _showErrorBottomSheet(
              context, 'خطأ في الاتصال بالسيرفر: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorBottomSheet(
            context, 'حدث خطأ في الاتصال. الرجاء المحاولة لاحقًا.');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background - white
          Container(
            color: Colors.white,
          ),

          // Blue gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 250.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF031E4B),
                    const Color(0xFF031E4B).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25.r),
                  bottomRight: Radius.circular(25.r),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 50.h),

                    // App logo
                    Center(
                      child: Container(
                        width: 120.w,
                        height: 120.h,
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        // Replace this with actual logo
                        child: ClipOval(
                          child: Container(
                            color: Colors.white,
                            child: FutureBuilder(
                              future: Future.delayed(Duration.zero),
                              builder: (context, snapshot) {
                                try {
                                  // Try to load the logo image
                                  return Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  );
                                } catch (e) {
                                  // Fallback to text if image is not available
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "HA55A",
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF031E4B),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Login card
                    Container(
                      padding: EdgeInsets.all(24.r),
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Heading
                            Text(
                              'أهلا بك من جديد',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A2530),
                              ),
                              textAlign: TextAlign.right,
                            ),

                            SizedBox(height: 8.h),

                            // Subheading
                            Text(
                              'يسعدنا رؤيتك هنا مرة أخرى',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF646464),
                              ),
                              textAlign: TextAlign.right,
                            ),

                            SizedBox(height: 32.h),

                            // Username field
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextFormField(
                                controller: usernameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال البريد الإلكتروني.';
                                  }
                                  return null;
                                },
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15.sp,
                                  color: const Color(0xFF1C2439),
                                ),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: const Color(0xFF646464),
                                    size: 20.sp,
                                  ),
                                  labelText:
                                      'اسم المستخدم أو البريد الإلكتروني',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: const Color(0xFF646464),
                                  ),
                                  hintText:
                                      'ادخل اسم المستخدم أو البريد الإلكتروني',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: const Color(0xFFAAAAAA),
                                  ),
                                  errorStyle: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12.sp,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FD),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF031E4B),
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // Password field
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextFormField(
                                controller: passwordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال كلمة المرور.';
                                  }
                                  return null;
                                },
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15.sp,
                                  color: const Color(0xFF1C2439),
                                ),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.ltr,
                                obscureText: visable,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: const Color(0xFF646464),
                                    size: 20.sp,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        visable = !visable;
                                      });
                                    },
                                    icon: Icon(
                                      visable
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF646464),
                                      size: 20.sp,
                                    ),
                                  ),
                                  labelText: 'كلمة المرور',
                                  labelStyle: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: const Color(0xFF646464),
                                  ),
                                  hintText: 'ادخل كلمة المرور',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: const Color(0xFFAAAAAA),
                                  ),
                                  errorStyle: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12.sp,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FD),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF031E4B),
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 12.h),

                            // Forgot password
                            Showcase(
                              key: _forgotPasswordKey,
                              description:
                                  "اضغط هنا إذا كنت قد نسيت كلمة المرور",
                              descTextStyle: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              tooltipBackgroundColor: const Color(0xFF031E4B),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'هل نسيت كلمة المرور؟',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF031E4B),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 32.h),

                            // Login button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF031E4B),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFF031E4B).withOpacity(0.6),
                                elevation: 0,
                                minimumSize: Size(double.infinity, 56.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: isLoading ? null : login,
                              child: isLoading
                                  ? SizedBox(
                                      height: 24.h,
                                      width: 24.w,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),

                            SizedBox(height: 20.h),

                            // Or divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: const Color(0xFFE0E0E0),
                                    thickness: 1.h,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Text(
                                    'أو',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14.sp,
                                      color: const Color(0xFF646464),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: const Color(0xFFE0E0E0),
                                    thickness: 1.h,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 20.h),

                            // Register
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.w),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'اشترك الآن',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF031E4B),
                                    ),
                                  ),
                                ),
                                Text(
                                  'ليس لديك حساب؟',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF646464),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
