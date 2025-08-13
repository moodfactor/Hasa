import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.accEmail});
  final String accEmail;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  bool visablePassword = true;
  bool visableConfirm = true;
  final formKey = GlobalKey<FormState>();

  bool isLoading = false;
  // مؤشر لإعادة بناء واجهة المستخدم عند تغيير كلمة المرور
  bool _passwordUpdated = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _inputFieldAnimations;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // إضافة مستمع لمراقبة تغييرات كلمة المرور
    password.addListener(_onPasswordChanged);

    // Initialize animations
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

    // Create staggered animations for input fields
    _inputFieldAnimations = List.generate(
      2,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.2 + (index * 0.15),
            1.0,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  // دالة تُستدعى عند تغيير كلمة المرور
  void _onPasswordChanged() {
    // تفعيل اهتزاز خفيف عند تغيير كلمة المرور
    HapticFeedback.lightImpact();

    // تفعيل إعادة بناء الواجهة عند تغيير كلمة المرور
    setState(() {
      _passwordUpdated = !_passwordUpdated; // تبديل القيمة لضمان تنفيذ setState
    });
  }

  @override
  void dispose() {
    password.removeListener(_onPasswordChanged);
    password.dispose();
    confirmPassword.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// عملية تغيير كلمة المرور
  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      var headers = {'Content-Type': 'application/json'};
      var data = json.encode({
        "email": widget.accEmail,
        "new_password": confirmPassword.text,
      });

      var dio = Dio();
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/auth/change_password.php',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      if (response.statusCode == 200) {
        developer
            .log("Change Password Response: ${json.encode(response.data)}");

        // After successful password change, login with new credentials
        await loginRequest(widget.accEmail, confirmPassword.text);
      } else {
        _showErrorBottomSheet('حدث خطأ في النظام: ${response.statusMessage}');
        developer.log('${response.statusMessage}');
      }
    } catch (e) {
      _showErrorBottomSheet(
          'حدث خطأ أثناء تحديث كلمة المرور. الرجاء المحاولة لاحقًا.');
      developer.log('Change Password Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// عملية تسجيل الدخول مع تخزين بيانات المستخدم والانتقال إلى الصفحة الرئيسية
  Future<void> loginRequest(String email, String passwordParam) async {
    try {
      var data = FormData.fromMap({
        'email': email,
        'password': passwordParam,
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
          developer.log('User ID: ${userData['id']}');

          if (userData.isNotEmpty) {
            String userJson = jsonEncode(userData);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_data', userJson);

            if (context.mounted) {
              _showSuccessBottomSheet('تم تحديث كلمة المرور بنجاح');
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
      developer.log('Login error: $e');
    }
  }

  void _showSuccessBottomSheet(String message) {
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
                  "تم بنجاح",
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
                message,
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
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const HomeScreen(),
                      transitionDuration: const Duration(milliseconds: 700),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        var curve = Curves.easeInOutCubic;
                        var slideCurve =
                            CurvedAnimation(parent: animation, curve: curve);

                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0), // يدخل من اليمين
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
                  'الذهاب للرئيسية',
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

  void _showErrorBottomSheet(String errorMessage) {
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required Function() toggleVisibility,
    required Animation<double> animation,
    required String? Function(String?) validator,
  }) {
    // حساب لون الحدود بناءً على قوة كلمة المرور
    Color getBorderColor() {
      if (controller.text.isEmpty) return Colors.grey.shade200;

      if (label.contains('تأكيد')) return Colors.grey.shade200;

      // حساب قوة كلمة المرور
      double strength = _calculatePasswordStrength(controller.text);

      if (strength <= 0.25) return Colors.red.shade400;
      if (strength <= 0.5) return Colors.orange.shade400;
      if (strength <= 0.75) return Colors.yellow.shade700;
      return Colors.green.shade500;
    }

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
        )),
        child: Container(
          margin: EdgeInsets.only(bottom: 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 16.h, right: 20.w, bottom: 8.h),
                child: Row(
                  children: [
                    Icon(
                      label.contains('تأكيد')
                          ? Icons.verified_user_outlined
                          : Icons.lock_outline,
                      size: 18.sp,
                      color: const Color(0xFF031E4B),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF031E4B),
                      ),
                    ),
                  ],
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return Focus(
                    onFocusChange: (hasFocus) {
                      setState(() {});
                    },
                    child: TextFormField(
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        letterSpacing: 1.0,
                        color: const Color(0xFF031E4B),
                      ),
                      controller: controller,
                      obscureText: obscureText,
                      cursorColor: const Color(0xFF031E4B),
                      onChanged: (_) {
                        setState(() {}); // تحديث StatefulBuilder
                      },
                      decoration: InputDecoration(
                        suffixIcon: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.all(8.sp),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: toggleVisibility,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return ScaleTransition(
                                      scale: animation, child: child);
                                },
                                child: Icon(
                                  obscureText
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  key: ValueKey<bool>(obscureText),
                                  color: const Color(0xFF031E4B),
                                  size: 22.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FD),
                        hintText: label.contains('تأكيد')
                            ? 'تأكيد كلمة المرور'
                            : 'أدخل كلمة المرور الجديدة',
                        hintStyle: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          color: Colors.grey.shade400,
                        ),
                        errorStyle: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          color: Colors.redAccent,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide: BorderSide(
                            color: getBorderColor(),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide: BorderSide(
                            color: getBorderColor(),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide: BorderSide(
                            color: Colors.red.shade300,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide: BorderSide(
                            color: Colors.red.shade400,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 18.h,
                        ),
                      ),
                      validator: validator,
                    ),
                  );
                },
              ),
              // Add password strength indicator for the first password field
              if (!label.contains('تأكيد'))
                Padding(
                  padding: EdgeInsets.only(
                      top: 12.h, bottom: 8.h, right: 16.w, left: 16.w),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // Calculate password strength
                      String value = controller.text;
                      double strength = _calculatePasswordStrength(value);

                      // متطلبات كلمة المرور لعرض المعايير
                      bool hasMinLength = value.length >= 8;
                      bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
                      bool hasLowercase = value.contains(RegExp(r'[a-z]'));
                      bool hasDigits = value.contains(RegExp(r'[0-9]'));
                      bool hasSpecialChars =
                          value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

                      Color getColor() {
                        if (strength <= 0.25) return Colors.red.shade400;
                        if (strength <= 0.5) return Colors.orange.shade400;
                        if (strength <= 0.75) return Colors.yellow.shade700;
                        return Colors.green.shade500;
                      }

                      String getText() {
                        if (strength <= 0.1) return 'غير آمنة';
                        if (strength <= 0.25) return 'ضعيفة جداً';
                        if (strength <= 0.5) return 'ضعيفة';
                        if (strength <= 0.75) return 'متوسطة';
                        if (strength <= 0.9) return 'جيدة';
                        return 'قوية جداً';
                      }

                      // أسلوب عرض معايير كلمة المرور
                      Widget buildCriteriaRow(bool criteria, String text) {
                        return Padding(
                          padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 18.w,
                                height: 18.h,
                                decoration: BoxDecoration(
                                  color: criteria
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    criteria ? Icons.check : Icons.close,
                                    size: 12.sp,
                                    color:
                                        criteria ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: criteria
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // إضافة تأثير لوحدة قياس القوة
                      Widget buildStrengthMeter() {
                        return TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          tween: Tween<double>(begin: 0, end: strength),
                          builder: (context, value, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.security,
                                        size: 16.sp,
                                        color: getColor(),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'قوة كلمة المرور:',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: getColor(),
                                    ),
                                    child: Text(getText()),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Stack(
                                children: [
                                  // خلفية شريط القوة
                                  Container(
                                    height: 6.h,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  // شريط قوة كلمة المرور
                                  Container(
                                    height: 6.h,
                                    width: value *
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                    decoration: BoxDecoration(
                                      color: getColor(),
                                      borderRadius: BorderRadius.circular(10.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: getColor().withOpacity(0.4),
                                          blurRadius: value > 0.5 ? 5 : 0,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // علامات قياس
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      5,
                                      (index) => Container(
                                        height: 6.h,
                                        width: 2.w,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // شريط قياس قوة كلمة المرور
                          buildStrengthMeter(),

                          SizedBox(height: 16.h),

                          // عرض معايير كلمة المرور القوية
                          value.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10.h),
                                    child: Text(
                                      'أدخل كلمة المرور لقياس قوتها',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'لكلمة مرور آمنة، يجب توفر:',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    buildCriteriaRow(
                                        hasMinLength, '٨ أحرف على الأقل'),
                                    buildCriteriaRow(
                                        hasUppercase, 'حرف كبير (A-Z)'),
                                    buildCriteriaRow(
                                        hasLowercase, 'حرف صغير (a-z)'),
                                    buildCriteriaRow(
                                        hasDigits, 'رقم واحد على الأقل (0-9)'),
                                    buildCriteriaRow(
                                        hasSpecialChars, 'رمز خاص (!@#\$)'),
                                  ],
                                ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة خارجية لحساب قوة كلمة المرور
  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0;

    // متطلبات كلمة المرور
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    // حساب قوة كلمة المرور بشكل أكثر دقة
    if (password.isNotEmpty) strength += 0.1;
    if (hasMinLength) strength += 0.2;
    if (hasUppercase) strength += 0.2;
    if (hasLowercase) strength += 0.1;
    if (hasDigits) strength += 0.2;
    if (hasSpecialChars) strength += 0.2;

    // ضمان أن القيمة لا تتجاوز 1.0
    return strength.clamp(0.0, 1.0);
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
            'تحديث كلمة المرور',
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 100.h),

                      // Password icon with animated effect
                      ScaleTransition(
                        scale: _scaleAnimation,
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
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF1F9).withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_reset_outlined,
                                size: 50.sp,
                                color: const Color(0xFF031E4B),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Content card with staggered animations
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
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
                                  // Header text with animated effect
                                  TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0.8, end: 1.0),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      'كلمة مرور جديدة',
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
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
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
                                      'قم بإنشاء كلمة مرور جديدة قوية وآمنة ليتم استخدامها في تسجيل الدخول لحسابك',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey.shade600,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 32.h),

                                  // Password fields
                                  _buildPasswordField(
                                    controller: password,
                                    label: 'كلمة المرور الجديدة',
                                    obscureText: visablePassword,
                                    toggleVisibility: () {
                                      setState(() {
                                        visablePassword = !visablePassword;
                                      });
                                    },
                                    animation: _inputFieldAnimations[0],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "يرجى إدخال كلمة المرور";
                                      } else if (value.length < 8) {
                                        return "يجب أن تتكون كلمة المرور من 8 أحرف على الأقل";
                                      }
                                      return null;
                                    },
                                  ),

                                  _buildPasswordField(
                                    controller: confirmPassword,
                                    label: 'تأكيد كلمة المرور',
                                    obscureText: visableConfirm,
                                    toggleVisibility: () {
                                      setState(() {
                                        visableConfirm = !visableConfirm;
                                      });
                                    },
                                    animation: _inputFieldAnimations[1],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "يرجى تأكيد كلمة المرور";
                                      } else if (value != password.text) {
                                        return "كلمة المرور غير مطابقة";
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 32.h),

                                  // Submit button with pulse animation
                                  TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
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
                                              (sin(_animationController.value *
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
                                        onPressed:
                                            isLoading ? null : changePassword,
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
                                                    'جاري التحديث...',
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
                                                'تحديث كلمة المرور',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
          ],
        ),
      ),
    );
  }
}
