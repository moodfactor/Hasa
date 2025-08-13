import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/new_password_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../btn/btns.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.accountEmail});
  final String accountEmail;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String currentText = "";
  final TextEditingController _otpControllers = TextEditingController();
  final StreamController<ErrorAnimationType>? errorController =
      StreamController<ErrorAnimationType>();

  bool isLoading = false;
  bool isResending = false;

  // إضافة متغيرات العد التنازلي
  Timer? _resendTimer;
  int _resendCountdown = 0;

  // إضافة متغيرات الانيميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // تهيئة الانيميشن
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();

    // بدء عداد الستين ثانية تلقائياً عند فتح الصفحة
    _startResendCountdown();
  }

  @override
  void dispose() {
    _animationController.dispose();
    errorController?.close();
    _otpControllers.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // بدء العد التنازلي لإعادة الإرسال
  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _resendTimer?.cancel();
        }
      });
    });
  }

  // وظيفة إعادة إرسال الرمز
  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;

    setState(() {
      isResending = true;
    });

    try {
      var headers = {'Content-Type': 'application/json'};
      var data = json.encode({"email": widget.accountEmail});

      var dio = Dio();
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/auth/forget_password.php',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      setState(() {
        isResending = false;
      });

      if (response.statusCode == 200) {
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة إرسال رمز التحقق بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        developer.log(json.encode(response.data));
      } else {
        _showErrorMessage(
            response.statusMessage ?? "حدث خطأ في إعادة إرسال الرمز");
        developer.log(response.statusMessage ?? "");
      }
    } catch (e) {
      setState(() {
        isResending = false;
      });
      _showErrorMessage("حدث خطأ في إعادة إرسال الرمز. حاول مرة أخرى.");
      developer.log("Error resending OTP: $e");
    }
  }

  // إظهار رسالة خطأ
  void _showErrorMessage(String message) {
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
              // الجزء العلوي للبوتوم شيت
              Container(
                width: 50.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),

              // أيقونة الخطأ
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

              // عنوان الخطأ مع انيميشن
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

              // رسالة الخطأ
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  message,
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

              // زر التأكيد
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

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      var headers = {'Content-Type': 'application/json'};
      var data = {
        "email": widget.accountEmail,
        "otp": _otpControllers.text,
      };

      var dio = Dio();
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/auth/verify_reset.php',
        options: Options(headers: headers),
        data: data,
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                NewPasswordScreen(accEmail: widget.accountEmail),
            transitionDuration: const Duration(milliseconds: 700),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              var curve = Curves.easeInOutCubic;
              var slideCurve = CurvedAnimation(parent: animation, curve: curve);

              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0), // يدخل من اليمين
                  end: Offset.zero,
                ).animate(slideCurve),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                    ),
                  ),
                  child: child,
                ),
              );
            },
          ),
        );
        developer.log("OTP Response: ${json.encode(response.data)}");
      } else {
        _showErrorMessage(response.statusMessage ?? "حدث خطأ غير متوقع");
        developer.log("Error: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      setState(() {
        isLoading = false;
      });

      String errorMessage = 'رمز التأكيد خطأ بإمكانك إعادة كتابته مرة أخرى';

      // تحقق إذا كان الخطأ هو "invalid OTP" أو أي نوع من أنواع رمز OTP غير صالح
      if (e.response?.data is Map) {
        var responseData = e.response?.data;
        if (responseData.containsKey('error')) {
          String apiErrorMsg = responseData['error'].toString().toLowerCase();
          if (!apiErrorMsg.contains('invalid') &&
              !apiErrorMsg.contains('otp')) {
            // إذا كان الخطأ ليس متعلقاً بـ OTP غير صالح، استخدم رسالة الخطأ الأصلية
            errorMessage = responseData['error'];
          }
        }
      }

      _showErrorMessage(errorMessage);
      errorController?.add(ErrorAnimationType.shake);
      developer.log("Dio error: ${e.message}");
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorMessage("حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى.");
      developer.log("Unexpected error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                margin: EdgeInsets.all(8.sp),
                padding: EdgeInsets.all(4.sp),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          title: Text(
            'التحقق من الرمز',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // الخلفية - الجزء العلوي الأزرق
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 220.h,
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

            // زخارف الخلفية المتحركة
            Positioned(
              top: 50.h,
              right: -50.w,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      15 * sin(_animationController.value * 2 * 3.14159),
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
                      10 * cos(_animationController.value * 2 * 3.14159),
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 100.h),

                          // أيقونة التحقق مع تأثير الانيميشن
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: sin(_animationController.value *
                                              3.14159 *
                                              2) *
                                          0.02,
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    width: 120.w,
                                    height: 120.h,
                                    padding: EdgeInsets.all(20.r),
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
                                    child: AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF1F9)
                                                .withOpacity(0.7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.verified_outlined,
                                            size: 50.sp,
                                            color: const Color(0xFF031E4B),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 32.h),

                          // بطاقة المحتوى مع انيميشن متدرج
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                    0, 20 * (1 - _animationController.value)),
                                child: Opacity(
                                  opacity: _animationController.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(24.r),
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
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // نص الترويسة مع تأثير انيميشن
                                    TweenAnimationBuilder(
                                      tween:
                                          Tween<double>(begin: 0.8, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 800),
                                      curve: Curves.elasticOut,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: child,
                                        );
                                      },
                                      child: Text(
                                        'تحقق من الرمز',
                                        style: TextStyle(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF031E4B),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 16.h),

                                    // الوصف مع تأثير التلاشي
                                    TweenAnimationBuilder(
                                      tween:
                                          Tween<double>(begin: 0.0, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 1000),
                                      curve: Curves.easeIn,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: child,
                                        );
                                      },
                                      child: Text(
                                        'أدخل رمز التحقق المكون من 6 أرقام المرسل عبر الواتس اب إلى الرقم المرتبط ب ${widget.accountEmail}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey.shade600,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 32.h),

                                    // حقول إدخال رمز التحقق مع انيميشن
                                    TweenAnimationBuilder(
                                      tween:
                                          Tween<double>(begin: 0.0, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 1200),
                                      curve: Curves.easeInOut,
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: Opacity(
                                            opacity: value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: PinCodeTextField(
                                          controller: _otpControllers,
                                          length: 6,
                                          obscureText: false,
                                          animationType: AnimationType.fade,
                                          animationDuration:
                                              const Duration(milliseconds: 300),
                                          errorAnimationController:
                                              errorController,
                                          onChanged: (value) {
                                            setState(() {
                                              currentText = value;
                                            });
                                          },
                                          appContext: context,
                                          // validator: (v) {
                                          //   if (v == null || v.length < 6) {
                                          //     return "الرمز يجب أن يكون 6 أرقام";
                                          //   }
                                          //   return null;
                                          // },
                                          pinTheme: PinTheme(
                                            activeColor:
                                                const Color(0xFF031E4B),
                                            selectedColor:
                                                const Color(0xFF031E4B),
                                            inactiveColor: Colors.grey.shade300,
                                            inactiveFillColor:
                                                Colors.grey.shade50,
                                            selectedFillColor:
                                                Colors.grey.shade100,
                                            activeFillColor:
                                                Colors.grey.shade50,
                                            shape: PinCodeFieldShape.box,
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            fieldHeight: 55.h,
                                            fieldWidth: 45.w,
                                          ),
                                          keyboardType: TextInputType.number,
                                          enableActiveFill: true,
                                          textStyle: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF031E4B),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 32.h),

                                    // زر التأكيد مع انيميشن نبض
                                    TweenAnimationBuilder(
                                      tween:
                                          Tween<double>(begin: 0.0, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 1400),
                                      curve: Curves.easeInOut,
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: Opacity(
                                            opacity: value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: 1.0 +
                                                (sin(_animationController
                                                            .value *
                                                        3.14159 *
                                                        4) *
                                                    0.01),
                                            child: child,
                                          );
                                        },
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF031E4B),
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                const Color(0xFF031E4B)
                                                    .withOpacity(0.5),
                                            elevation: 0,
                                            minimumSize:
                                                Size(double.infinity, 56.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          // تعديل الزر ليكون معطلاً حتى يتم إدخال 6 أرقام أو إذا كان التحميل قيد التنفيذ
                                          onPressed: (isLoading ||
                                                  currentText.length < 6)
                                              ? null
                                              : _sendOTP,
                                          child: isLoading
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 20.w,
                                                      height: 20.h,
                                                      child:
                                                          const CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10.w),
                                                    Text(
                                                      'جاري التحقق...',
                                                      style: TextStyle(
                                                        fontSize: 16.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  'تأكيد الرمز',
                                                  style: TextStyle(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 24.h),

                                    // إعادة إرسال الرمز مع عداد تنازلي
                                    TweenAnimationBuilder(
                                      tween:
                                          Tween<double>(begin: 0.0, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 1600),
                                      curve: Curves.easeIn,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: child,
                                        );
                                      },
                                      child: GestureDetector(
                                        onTap: (_resendCountdown > 0 ||
                                                isResending)
                                            ? null
                                            : _resendOTP,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'لم تستلم الرمز؟ ',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            _resendCountdown > 0
                                                ? Row(
                                                    children: [
                                                      Text(
                                                        'أعد الإرسال بعد ',
                                                        style: TextStyle(
                                                          fontSize: 14.sp,
                                                          color: Colors
                                                              .grey.shade600,
                                                        ),
                                                      ),
                                                      Text(
                                                        '$_resendCountdown',
                                                        style: TextStyle(
                                                          fontSize: 14.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .grey.shade700,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' ثانية',
                                                        style: TextStyle(
                                                          fontSize: 14.sp,
                                                          color: Colors
                                                              .grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : isResending
                                                    ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          SizedBox(
                                                            width: 12.w,
                                                            height: 12.h,
                                                            child:
                                                                const CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Color(
                                                                  0xFF031E4B),
                                                            ),
                                                          ),
                                                          SizedBox(width: 8.w),
                                                          Text(
                                                            'جاري الإرسال...',
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: const Color(
                                                                      0xFF031E4B)
                                                                  .withOpacity(
                                                                      0.7),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        'إعادة الإرسال',
                                                        style: TextStyle(
                                                          fontSize: 14.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: const Color(
                                                              0xFF031E4B),
                                                        ),
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

                          SizedBox(height: 20.h),
                        ],
                      ),
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
