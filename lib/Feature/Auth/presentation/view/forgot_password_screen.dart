import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:my_project/Feature/Auth/presentation/view/login_screen.dart';
import 'package:my_project/Feature/Auth/presentation/view/verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>(debugLabel: 'forgotPasswordFormKey');
  final TextEditingController emailController = TextEditingController();
  Map<String, dynamic> formData = {};

  bool isLoading = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
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

    // Add delayed animations for sequential effect
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
                  "تم إرسال رمز التحقق",
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
                "تم إرسال رمز التحقق عبر الواتس اب بنجاح",
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
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          VerificationScreen(
                        accountEmail: emailController.text,
                      ),
                      transitionDuration: const Duration(milliseconds: 700),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        var curve = Curves.easeInOutCubic;
                        var slideCurve =
                            CurvedAnimation(parent: animation, curve: curve);

                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(slideCurve),
                          child: FadeTransition(
                            opacity:
                                Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: const Interval(0.0, 0.7,
                                    curve: Curves.easeOut),
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                    ),
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
                  'التالي',
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

  Future<void> forgotPassRequest() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    var headers = {'Content-Type': 'application/json'};
    var dio = Dio();

    try {
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/auth/forget_password.php',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: {
          "email": emailController.text,
        },
      );

      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        _showSuccessBottomSheet(context);
        dev.log('Success: ${json.encode(response.data)}');
      } else if (response.statusCode == 404) {
        _showErrorBottomSheet(
            context, response.data['error'] ?? 'حدث خطأ غير متوقع.');
        dev.log('Error: ${response.data['error']}');
      } else {
        _showErrorBottomSheet(
            context, response.statusMessage ?? 'حدث خطأ غير متوقع.');
        dev.log('Error: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      String errorMessage = 'حاول مرة اخرى';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = "فشل الاتصال بالخادم. تحقق من اتصال الإنترنت الخاص بك.";
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMessage = "انتهت مهلة الإرسال! استغرق الخادم وقتاً طويلاً للرد.";
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "انتهت مهلة الاستلام! استغرقت الاستجابة وقتاً طويلاً.";
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage = e.response?.data['error'] ??
            "حدث خطأ في الخادم. يرجى المحاولة لاحقًا.";
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = "تعذر الاتصال بالخادم. يرجى المحاولة لاحقًا.";
      }
      _showErrorBottomSheet(context, errorMessage);
      dev.log('Dio error: ${e.message}');
    } catch (e) {
      _showErrorBottomSheet(
          context, 'حدث خطأ غير متوقع. الرجاء المحاولة لاحقًا.');
      dev.log('Unexpected error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
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
                print("تم الضغط على زر الرجوع الجديد");

                // استخدام PageRouteBuilder مع انيميشن مخصص
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                    transitionDuration: const Duration(milliseconds: 700),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      // تعريف انيميشن متعدد
                      var curve = Curves.easeInOutCubic;
                      var slideCurve =
                          CurvedAnimation(parent: animation, curve: curve);
                      var fadeCurve = CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                      );

                      // انيميشن الحركة والشفافية معاً
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0)
                            .animate(fadeCurve),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1.0, 0.0),
                            end: Offset.zero,
                          ).animate(slideCurve),
                          child: child,
                        ),
                      );
                    },
                  ),
                );
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
            'استعادة كلمة المرور',
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
            // Background design - blue top section
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

            // Animated background decorations
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

            // Main content
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

                          // Reset icon card with animated effect
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
                                            Icons.lock_reset_outlined,
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

                          // Content card with staggered animations
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
                                key: formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Header Text with animated effect
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
                                        'نسيت كلمة المرور؟',
                                        style: TextStyle(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF031E4B),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 16.h),

                                    // Description with fade-in effect
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
                                        'أدخل بريدك الإلكتروني وسنرسل لك رمز التحقق لإعادة تعيين كلمة المرور الخاصة بك',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey.shade600,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 32.h),

                                    // Email Input Field with animation
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
                                      child: TextFormField(
                                        controller: emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          color: const Color(0xFF1C2439),
                                        ),
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color: const Color(0xFF646464),
                                            size: 20.sp,
                                          ),
                                          labelText: 'البريد الإلكتروني',
                                          labelStyle: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 14.sp,
                                            color: const Color(0xFF646464),
                                          ),
                                          hintText: 'أدخل بريدك الإلكتروني',
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
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE0E0E0),
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF031E4B),
                                              width: 1.5,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            borderSide: const BorderSide(
                                              color: Colors.red,
                                              width: 1,
                                            ),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
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
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return "يرجي ادخال البريد الإلكتروني الخاص بك";
                                          } else if (!value.contains('@')) {
                                            return "يرجي ادخال بريد إلكتروني صالح";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),

                                    SizedBox(height: 32.h),

                                    // Submit Button with pulse animation
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
                                                    .withOpacity(0.7),
                                            elevation: 0,
                                            minimumSize:
                                                Size(double.infinity, 56.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          onPressed: isLoading
                                              ? null
                                              : forgotPassRequest,
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
                                                      'جاري الإرسال...',
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
                                                  'إرسال رمز التحقق',
                                                  style: TextStyle(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 24.h),

                                    // Return to Login with animation
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
                                        onTap: () {
                                          Navigator.of(context)
                                              .pushAndRemoveUntil(
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation,
                                                      secondaryAnimation) =>
                                                  const LoginScreen(),
                                              transitionDuration:
                                                  const Duration(
                                                      milliseconds: 700),
                                              transitionsBuilder: (context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child) {
                                                // تعريف انيميشن متعدد
                                                var curve =
                                                    Curves.easeInOutCubic;
                                                var slideCurve =
                                                    CurvedAnimation(
                                                        parent: animation,
                                                        curve: curve);
                                                var fadeCurve = CurvedAnimation(
                                                  parent: animation,
                                                  curve: const Interval(
                                                      0.0, 0.7,
                                                      curve: Curves.easeOut),
                                                );

                                                // انيميشن الحركة والشفافية معاً
                                                return FadeTransition(
                                                  opacity: Tween<double>(
                                                          begin: 0.0, end: 1.0)
                                                      .animate(fadeCurve),
                                                  child: SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: const Offset(
                                                          -1.0, 0.0),
                                                      end: Offset.zero,
                                                    ).animate(slideCurve),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                            ),
                                            (route) =>
                                                false, // إزالة جميع الشاشات السابقة
                                          );
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'العودة إلى ',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(
                                              'تسجيل الدخول',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF031E4B),
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
