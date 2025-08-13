import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/home_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Regsisterotp extends StatefulWidget {
  const Regsisterotp({
    super.key,
    required this.mobileNumber,
    required this.email,
    required this.password,
  });

  final String mobileNumber;
  final String email;
  final String password;

  @override
  // ignore: library_private_types_in_public_api
  _RegsisterotpState createState() => _RegsisterotpState();
}

class _RegsisterotpState extends State<Regsisterotp>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool hasError = false;
  String currentText = "";
  final TextEditingController _otpControllers = TextEditingController();
  final StreamController<ErrorAnimationType>? errorController =
      StreamController<ErrorAnimationType>();

  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    errorController?.close();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    developer.log("OTP Request Mobile: ${widget.mobileNumber}");
    developer.log("email: ${widget.email}");
    developer.log("password: ${widget.password}");
    try {
      var headers = {'Content-Type': 'application/json'};
      var data = {
        "mobile": widget.mobileNumber,
        "otp": _otpControllers.text,
      };

      var dio = Dio();
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/auth/verify.php',
        options: Options(headers: headers),
        data: data,
      );

      developer.log("OTP Response: ${json.encode(response.data)}");

      if (response.statusCode == 200) {
        // إذا كان رمز الاستجابة 200، فالرمز صحيح بغض النظر عن status
        await loginrequest();
      } else {
        setState(() {
          hasError = true;
        });
        errorController?.add(ErrorAnimationType.shake);
        HapticFeedback.vibrate();
        _showErrorBottomSheet('رمز التحقق غير صحيح');
        developer.log("Error: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      setState(() {
        hasError = true;
      });
      errorController?.add(ErrorAnimationType.shake);
      HapticFeedback.vibrate();
      _showErrorBottomSheet('رمز التحقق غير صحيح');
      developer.log("Dio error: ${e.message}");
    } catch (e, stackTrace) {
      setState(() {
        hasError = true;
      });
      errorController?.add(ErrorAnimationType.shake);
      HapticFeedback.vibrate();
      _showErrorBottomSheet('رمز التحقق غير صحيح');
      developer.log("Unexpected error: $e");
      developer.log("StackTrace: $stackTrace");
    }
  }

  Future<void> loginrequest() async {
    setState(() {
      isLoading = true;
    });

    try {
      var data = FormData.fromMap({
        'email': widget.email,
        'password': widget.password,
      });

      var dio = Dio();
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/auth/login.php',
        data: data,
      );

      developer.log("Login Response: ${json.encode(response.data)}");

      if (response.statusCode == 200) {
        var responseData = response.data;

        if (responseData['status'] == true) {
          Map<String, dynamic> userData = responseData['user'];
          developer.log('${userData['id']}');

          if (userData.isNotEmpty) {
            String userJson = jsonEncode(userData);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_data', userJson);

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
            _showErrorBottomSheet('بيانات المستخدم غير موجودة.');
          }
        } else {
          _showErrorBottomSheet(
              responseData['message'] ?? 'حدث خطأ غير متوقع.');
        }
      } else {
        _showErrorBottomSheet(
            'خطأ في الاتصال بالسيرفر: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorBottomSheet('حدث خطأ في الاتصال. الرجاء المحاولة لاحقًا.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 80.sp),
              SizedBox(height: 20.h),
              Text(
                "رمز التحقق خطأ",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2530),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF031E4B),
                  minimumSize: Size(double.infinity, 48.sp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'حسنًا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isTablet = width > 600;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          'email': widget.email,
          'mobile': widget.mobileNumber,
          'password': widget.password
        });
        return false;
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              iconSize: 20.sp,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context, {
                  'email': widget.email,
                  'mobile': widget.mobileNumber,
                  'password': widget.password
                });
              },
            ),
            title: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'انشاء حساب جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isTablet ? 25.sp : 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            centerTitle: false,
          ),
          body: Stack(
            children: [
              // خلفية متدرجة
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
              ),

              // الجزء العلوي المتدرج
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 240.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF031E4B),
                        Color(0xFF042C6A),
                        Color(0xFF0057FF),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30.r),
                      bottomRight: Radius.circular(30.r),
                    ),
                  ),
                ),
              ),

              // زخارف متحركة
              Positioned(
                top: 50.h,
                right: -50.w,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        15 * sin(_animationController.value * 2 * pi),
                        0,
                      ),
                      child: Opacity(
                        opacity: 0.1,
                        child: Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: 120.h,
                left: -20.w,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        10 * cos(_animationController.value * 2 * pi),
                      ),
                      child: Opacity(
                        opacity: 0.08,
                        child: Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // المحتوى الرئيسي
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 20.h),

                        // أيقونة التحقق المتحركة
                        Center(
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0)
                                .animate(_animationController),
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
                                Icons.message_outlined,
                                size: 50.sp,
                                color: const Color(0xFF25D366),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 30.h),

                        // بطاقة OTP
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: EdgeInsets.all(24.sp),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    spreadRadius: 1,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "تحقق من الواتس اب",
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A2530),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "أدخل رمز التحقق المكون من 6 أرقام المرسل عبر الواتس اب",
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14.sp,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 30.h),

                                  // OTP input fields
                                  Form(
                                    key: _formKey,
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 5.w),
                                        child: PinCodeTextField(
                                          controller: _otpControllers,
                                          length: 6,
                                          obscureText: false,
                                          animationType: AnimationType.scale,
                                          animationDuration:
                                              const Duration(milliseconds: 300),
                                          errorAnimationController:
                                              errorController,
                                          onChanged: (value) {
                                            setState(() {
                                              currentText = value;
                                            });

                                            // إضافة اهتزاز خفيف عند كتابة رمز التحقق
                                            if (value.length == 6) {
                                              HapticFeedback.lightImpact();
                                            }
                                          },
                                          beforeTextPaste: (text) {
                                            if (text != null &&
                                                text.length == 6 &&
                                                RegExp(r'^\d+$')
                                                    .hasMatch(text)) {
                                              return true;
                                            }
                                            return false;
                                          },
                                          appContext: context,
                                          // validator: (v) {
                                          //   if (v == null || v.length < 6) {
                                          //     return "الرمز يجب أن يكون 6 أرقام";
                                          //   } else {
                                          //     return null;
                                          //   }
                                          // },
                                          pinTheme: PinTheme(
                                            inactiveColor: Colors.grey.shade300,
                                            activeColor:
                                                const Color(0xFF031E4B),
                                            selectedColor:
                                                const Color(0xFF0057FF),
                                            selectedFillColor:
                                                Colors.grey.shade100,
                                            inactiveFillColor: Colors.white,
                                            activeFillColor: Colors.white,
                                            shape: PinCodeFieldShape.box,
                                            borderRadius:
                                                BorderRadius.circular(15.r),
                                            borderWidth: 2,
                                            fieldHeight: 55.h,
                                            fieldWidth: isTablet ? 60.w : 38.w,
                                            fieldOuterPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 2.w),
                                          ),
                                          keyboardType: TextInputType.number,
                                          enableActiveFill: true,
                                          textStyle: TextStyle(
                                            fontSize: 22.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          cursorColor: const Color(0xFF0057FF),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 16.h),

                                  // رسالة خطأ
                                  if (hasError)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8.h),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            "رمز خاطئ، تأكد من الرمز المرسل",
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 12.sp,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 30.h),

                        // Confirm button
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            height: 56.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF031E4B).withOpacity(
                                      currentText.length == 6 ? 0.3 : 0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentText.length == 6
                                    ? const Color(0xFF031E4B)
                                    : const Color(0xFF031E4B).withOpacity(0.5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.r),
                                ),
                                disabledBackgroundColor:
                                    const Color(0xFF031E4B).withOpacity(0.3),
                                disabledForegroundColor:
                                    Colors.white.withOpacity(0.7),
                              ),
                              onPressed: currentText.length == 6
                                  ? () async {
                                      HapticFeedback.mediumImpact();
                                      setState(() {
                                        isLoading = true;
                                      });
                                      await _sendOTP();
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  : null,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "تأكيد",
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 20.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 30.h),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading indicator
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(25.sp),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 50.w,
                            height: 50.h,
                            child: const CircularProgressIndicator(
                              color: Color(0xFF031E4B),
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'جاري التحقق...',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
