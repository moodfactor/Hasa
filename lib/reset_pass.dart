import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool currentPasswordVisible = false;
  bool newPasswordVisible = false;
  bool confirmPasswordVisible = false;
  bool isSubmitting = false;

  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutQuint));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _showPopupError('خطأ', 'الرجاء التأكد من صحة البيانات.');
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      _showPopupError('خطأ', 'كلمة المرور الجديدة وتأكيدها غير متطابقين.');
      return;
    }
    setState(() {
      isSubmitting = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('user_data');
    if (userJson == null) {
      setState(() {
        isSubmitting = false;
      });
      _showPopupError('خطأ', 'لم يتم العثور على بيانات المستخدم.');
      return;
    }
    final Map<String, dynamic> userData = jsonDecode(userJson);
    final String? email = userData['email'];
    if (email == null || email.isEmpty) {
      setState(() {
        isSubmitting = false;
      });
      _showPopupError('خطأ', 'لم يتم العثور على البريد الإلكتروني.');
      return;
    }
    try {
      var data = FormData.fromMap({
        'email': email,
        'current_password': currentPasswordController.text,
        'new_password': newPasswordController.text,
      });
      var dio = Dio();
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/auth/change-pass.php',
        data: data,
      );
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() {
          isSubmitting = false;
        });
        _showSuccessBottomSheet();
      } else {
        setState(() {
          isSubmitting = false;
        });
        String errorMessage = response.data['message'] ?? 'حدث خطأ غير متوقع.';
        _showPopupError('خطأ', errorMessage);
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      _showPopupError('خطأ', 'كلمة المرور الحالية غير صحيحة.');
    }
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.all(24.0.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFB6340), Color(0xFFFF3159)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFB6340).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 60.r),
                ),
                SizedBox(height: 24.h),
                Text(
                  "تم تغيير كلمة المرور بنجاح",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  "يمكنك الآن استخدام كلمة المرور الجديدة",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF718096),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFB6340), Color(0xFFFF3159)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFB6340).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Text(
                          'حسنًا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  void _showPopupError(String title, String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.all(24.0.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child:
                      Icon(Icons.error_outline, color: Colors.red, size: 60.r),
                ),
                SizedBox(height: 24.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF718096),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Text(
                          'حسنًا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      VoidCallback toggleVisibility, bool isVisible, IconData prefixIcon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 12.h),
          TextFormField(
            controller: controller,
            obscureText: !isVisible,
            validator: (value) =>
                value == null || value.isEmpty ? 'الرجاء إدخال $label.' : null,
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF2D3748),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: const Color(0xFFE2E8F0),
                  width: 1.w,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: const Color(0xFFFB6340),
                  width: 1.5.w,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF718096),
                  size: 20.r,
                ),
                onPressed: toggleVisibility,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.only(right: 12.w, left: 8.w),
                child: Icon(
                  prefixIcon,
                  color: const Color(0xFFFB6340),
                  size: 20.r,
                ),
              ),
              hintText: 'أدخل $label',
              hintStyle: TextStyle(
                color: const Color(0xFFA0AEC0),
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_forward_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'تغيير كلمة المرور',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFB6340),
                  Color(0xFFFF3159),
                ],
              ),
            ),
            height: MediaQuery.of(context).size.height * 0.25,
          ),

          // Shimmer pattern effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.25,
              child: CustomPaint(
                painter: ShimmerPatternPainter(),
                size: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.25),
              ),
            ),
          ),

          Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      SizedBox(height: 30.h),
                      // Illustrations and stats
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تأمين حسابك',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  'قم بتغيير كلمة المرور بشكل دوري',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 60.h,
                              width: 60.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Icon(
                                Icons.security,
                                color: Colors.white,
                                size: 30.r,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30.r),
                              topRight: Radius.circular(30.r),
                            ),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.all(20.r),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8.h),
                                    _buildPasswordField(
                                      'كلمة المرور الحالية',
                                      currentPasswordController,
                                      () {
                                        setState(() {
                                          currentPasswordVisible =
                                              !currentPasswordVisible;
                                        });
                                      },
                                      currentPasswordVisible,
                                      Icons.lock_outline,
                                    ),
                                    _buildPasswordField(
                                      'كلمة المرور الجديدة',
                                      newPasswordController,
                                      () {
                                        setState(() {
                                          newPasswordVisible =
                                              !newPasswordVisible;
                                        });
                                      },
                                      newPasswordVisible,
                                      Icons.vpn_key_outlined,
                                    ),
                                    _buildPasswordField(
                                      'تأكيد كلمة المرور',
                                      confirmPasswordController,
                                      () {
                                        setState(() {
                                          confirmPasswordVisible =
                                              !confirmPasswordVisible;
                                        });
                                      },
                                      confirmPasswordVisible,
                                      Icons.check_circle_outline,
                                    ),
                                    SizedBox(height: 20.h),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFB6340),
                                            Color(0xFFFF3159),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFB6340)
                                                .withOpacity(0.3),
                                            blurRadius: 10,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      width: double.infinity,
                                      height: 56.h,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: isSubmitting
                                              ? null
                                              : () {
                                                  HapticFeedback.mediumImpact();
                                                  _handleSubmit();
                                                },
                                          borderRadius:
                                              BorderRadius.circular(16.r),
                                          child: Center(
                                            child: isSubmitting
                                                ? SizedBox(
                                                    height: 24.h,
                                                    width: 24.h,
                                                    child:
                                                        const CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                        Icons.save_outlined,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 10.w),
                                                      Text(
                                                        'حفظ التغييرات',
                                                        style: TextStyle(
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Padding(
                                      padding: EdgeInsets.all(16.r),
                                      child: Container(
                                        padding: EdgeInsets.all(16.r),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF9F0),
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: const Color(0xFFFBD38D),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: const Color(0xFFED8936),
                                              size: 24.r,
                                            ),
                                            SizedBox(width: 16.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'نصائح لكلمة مرور قوية',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14.sp,
                                                      color: const Color(
                                                          0xFF2D3748),
                                                    ),
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    'استخدم 8 أحرف على الأقل مع مزيج من الأحرف والأرقام والرموز',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: const Color(
                                                          0xFF718096),
                                                    ),
                                                  ),
                                                ],
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for shimmer pattern effect
class ShimmerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw diagonal shimmer lines
    for (double i = -size.height; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Draw circles
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Random dots
    final random = math.Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 4 + 1;
      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
