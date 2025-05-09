import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class TfaOtpScreen extends StatefulWidget {
  final String userId;

  const TfaOtpScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<TfaOtpScreen> createState() => _TfaOtpScreenState();
}

class _TfaOtpScreenState extends State<TfaOtpScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String currentText = "";
  final TextEditingController _otpController = TextEditingController();
  final StreamController<ErrorAnimationType> errorController =
      StreamController<ErrorAnimationType>();

  bool isLoading = false;
  bool isResending = false;

  // Timer for countdown
  Timer? _resendTimer;
  int _resendCountdown = 60;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Start countdown for resend button
    _startResendTimer();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutQuint),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    errorController.close();
    _animationController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;

    setState(() {
      isResending = true;
    });

    try {
      var dio = Dio();
      var data = {"user_id": widget.userId};

      var response = await dio.post(
        'https://ha55a.exchange/api/v1/auth/2fa-login.php',
        data: data,
      );

      if (response.statusCode == 200) {
        developer.log("Resent OTP: ${json.encode(response.data)}");
        _showSuccessMessage("تم إعادة إرسال رمز التحقق بنجاح");
        _startResendTimer();
      } else {
        _showErrorMessage("فشل في إرسال رمز التحقق. الرجاء المحاولة مرة أخرى.");
      }
    } catch (e) {
      _showErrorMessage("حدث خطأ أثناء إعادة إرسال الرمز: ${e.toString()}");
    } finally {
      setState(() {
        isResending = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (currentText.length != 6) {
      errorController.add(ErrorAnimationType.shake);
      _showErrorMessage("الرجاء إدخال رمز التحقق المكون من 6 أرقام");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var dio = Dio();
      var data = {"user_id": widget.userId, "otp": currentText};

      var response = await dio.post(
        'https://ha55a.exchange/api/v1/auth/confirm.php',
        data: data,
      );

      developer.log("2FA Verification Response: ${json.encode(response.data)}");

      if (response.statusCode == 200) {
        var responseData = response.data;

        if (responseData['success'] == true) {
          // تحديث حالة المصادقة الثنائية إلى مكتملة
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('tfa_completed', true);

          // طباعة بيانات المستخدم بعد المصادقة الثنائية الناجحة
          try {
            String? userJson = prefs.getString('user_data');
            if (userJson != null) {
              Map<String, dynamic> userData = jsonDecode(userJson);
              developer.log(
                  '=========== بيانات المستخدم بعد المصادقة الثنائية ===========');
              developer.log('المعرف: ${userData['id']}');
              developer.log('البريد الإلكتروني: ${userData['email']}');
              developer.log('اسم المستخدم: ${userData['username']}');
              developer.log('حالة المصادقة الثنائية: ${userData['ts']}');
              developer.log('البيانات الكاملة: ${json.encode(userData)}');
              developer.log('=========== نهاية بيانات المستخدم ===========');
            }
          } catch (e) {
            developer.log('خطأ في قراءة بيانات المستخدم: $e');
          }

          // Navigate to home screen
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HomeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  var begin = const Offset(1.0, 0.0);
                  var end = Offset.zero;
                  var curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
              (route) => false,
            );
          }
        } else {
          // حالة الفشل - عرض رسالة الخطأ من الخادم
          _showErrorMessage(responseData['message'] ??
              "رمز التحقق غير صحيح، الرجاء المحاولة مرة أخرى.");
        }
      } else {
        _showErrorMessage("فشل في الاتصال بالخادم. الرجاء المحاولة مرة أخرى.");
      }
    } catch (e) {
      _showErrorMessage("حدث خطأ أثناء التحقق: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(15.r),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(15.r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: null,
        body: Stack(
          children: [
            // خلفية بيضاء للصفحة بأكملها
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
            ),

            // Gradient background for top part only
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF031E4B),
                      Color(0xFF0A2A5E),
                    ],
                  ),
                ),
                height: MediaQuery.of(context).size.height * 0.35,
              ),
            ),

            // Custom AppBar - نضيف شريط عنوان مخصص بدون زر رجوع
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Center(
                    // child: Text(
                    //   'المصادقة الثنائية',
                    //   style: TextStyle(
                    //     fontFamily: 'Cairo',
                    //     fontSize: 22.sp,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.white,
                    //   ),
                    // ),
                    ),
              ),
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),

                        // Icon
                        Center(
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 100.w,
                              height: 100.h,
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
                              child: Icon(
                                Icons.security,
                                size: 50.sp,
                                color: const Color(0xFF031E4B),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 30.h),

                        // Main card
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(25.r),
                              margin: EdgeInsets.only(top: 20.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'رمز التحقق',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A2530),
                                    ),
                                  ),

                                  SizedBox(height: 15.h),

                                  Text(
                                    'تم إرسال رمز التحقق إلى رقم هاتفك المحمول عبر الواتساب، الرجاء إدخاله أدناه',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14.sp,
                                      color: const Color(0xFF646464),
                                    ),
                                  ),

                                  SizedBox(height: 30.h),

                                  // OTP input field
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: PinCodeTextField(
                                      controller: _otpController,
                                      length: 6,
                                      obscureText: false,
                                      animationType: AnimationType.fade,
                                      pinTheme: PinTheme(
                                        shape: PinCodeFieldShape.box,
                                        borderRadius: BorderRadius.circular(12),
                                        fieldHeight: 50,
                                        fieldWidth: 45,
                                        activeFillColor: Colors.white,
                                        inactiveFillColor:
                                            const Color(0xFFF8F9FD),
                                        selectedFillColor: Colors.white,
                                        activeColor: const Color(0xFF031E4B),
                                        inactiveColor: const Color(0xFFE0E0E0),
                                        selectedColor: const Color(0xFF031E4B),
                                      ),
                                      animationDuration:
                                          const Duration(milliseconds: 300),
                                      backgroundColor: Colors.transparent,
                                      enableActiveFill: true,
                                      errorAnimationController: errorController,
                                      keyboardType: TextInputType.number,
                                      onCompleted: (v) {
                                        // Auto verify when complete
                                        _verifyOTP();
                                      },
                                      onChanged: (value) {
                                        setState(() {
                                          currentText = value;
                                        });
                                      },
                                      beforeTextPaste: (text) {
                                        // Check if pasted text is numeric and of length 6
                                        if (text != null) {
                                          if (text.length != 6 ||
                                              !RegExp(r'^[0-9]+$')
                                                  .hasMatch(text)) {
                                            return false;
                                          }
                                        }
                                        return true;
                                      },
                                      appContext: context,
                                    ),
                                  ),

                                  SizedBox(height: 30.h),

                                  // Submit button
                                  ElevatedButton(
                                    onPressed: isLoading ? null : _verifyOTP,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF031E4B),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          const Color(0xFF031E4B)
                                              .withOpacity(0.6),
                                      elevation: 0,
                                      minimumSize: Size(double.infinity, 56.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.r),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          )
                                        : Text(
                                            'تحقق',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),

                                  SizedBox(height: 20.h),

                                  // Resend button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'لم تستلم الرمز؟',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 14.sp,
                                          color: const Color(0xFF646464),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            _resendCountdown > 0 || isResending
                                                ? null
                                                : _resendOTP,
                                        child: Text(
                                          _resendCountdown > 0
                                              ? 'إعادة الإرسال خلال $_resendCountdown ثانية'
                                              : 'إعادة الإرسال',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: _resendCountdown > 0 ||
                                                    isResending
                                                ? Colors.grey
                                                : const Color(0xFF031E4B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
