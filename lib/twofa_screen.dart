import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isTwoFAEnabled = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

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

    // Load user 2FA status
    _loadTwoFAStatus();
  }

  Future<void> _loadTwoFAStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');

      if (userJson != null) {
        Map<String, dynamic> userData = jsonDecode(userJson);

        // Check if ts exists and set the 2FA status accordingly
        // ts = 0: 2FA disabled, ts = 1: 2FA enabled
        int tsValue = userData['ts'] ?? 0;

        setState(() {
          _isTwoFAEnabled = tsValue == 1;
        });
      }
    } catch (e) {
      print('Error loading 2FA status: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTwoFA(bool value) async {
    // Play haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _isTwoFAEnabled = value;
    });

    try {
      // 1. Update in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');

      if (userJson != null) {
        Map<String, dynamic> userData = jsonDecode(userJson);

        // Set ts to 1 if enabled, 0 if disabled
        int tsValue = value ? 1 : 0;
        userData['ts'] = tsValue;

        // Save updated user data back to SharedPreferences
        await prefs.setString('user_data', jsonEncode(userData));

        // 2. Update in database via API
        String userId = userData['id']?.toString() ?? '';

        if (userId.isNotEmpty) {
          var data =
              FormData.fromMap({'user_id': userId, 'ts': tsValue.toString()});

          var dio = Dio();
          var response = await dio.request(
            'https://ha55a.exchange/api/v1/auth/2fa.php',
            options: Options(
              method: 'POST',
            ),
            data: data,
          );

          if (response.statusCode == 200) {
            print('2FA API Response: ${json.encode(response.data)}');
          } else {
            print('2FA API Error: ${response.statusMessage}');
          }
        } else {
          print('Cannot update 2FA status in database: user_id not found');
        }
      }
    } catch (e) {
      print('Error updating 2FA status: $e');
    }

    // Show success message
    if (value) {
      _showSuccessMessage('تم تفعيل المصادقة الثنائية بنجاح');
    } else {
      _showSuccessMessage('تم إيقاف المصادقة الثنائية');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFFF97316),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(15.r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            'المصادقة الثنائية',
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
                  Color(0xFFF97316), // Orange primary
                  Color(0xFFEA580C), // Darker orange
                ],
              ),
            ),
            height: MediaQuery.of(context).size.height * 0.28,
          ),

          // Shimmer pattern effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.28,
              child: CustomPaint(
                painter: ShimmerPatternPainter(),
                size: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.28),
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
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        SizedBox(height: 40.h),

                        // Security icon
                        Container(
                          width: 100.w,
                          height: 100.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.security,
                            color: Colors.white,
                            size: 50.r,
                          ),
                        ),

                        SizedBox(height: 20.h),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Text(
                            "تعزيز حماية حسابك",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: 30.h),

                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(32.r),
                                  topRight: Radius.circular(32.r),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, -5),
                                  )
                                ]),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Padding(
                                padding: EdgeInsets.all(24.r),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Main toggle card
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(20.r),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'المصادقة الثنائية',
                                                      style: TextStyle(
                                                        fontSize: 18.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                            0xFF2D3748),
                                                      ),
                                                    ),
                                                    SizedBox(height: 8.h),
                                                    Text(
                                                      _isTwoFAEnabled
                                                          ? 'مفعلة'
                                                          : 'غير مفعلة',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: _isTwoFAEnabled
                                                            ? const Color(
                                                                0xFF10B981) // green
                                                            : const Color(
                                                                0xFF6B7280), // gray
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Switch(
                                                value: _isTwoFAEnabled,
                                                onChanged: _toggleTwoFA,
                                                activeColor: Colors.white,
                                                activeTrackColor:
                                                    const Color(0xFF10B981),
                                                inactiveThumbColor:
                                                    Colors.white,
                                                inactiveTrackColor:
                                                    const Color(0xFFE5E7EB),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16.h),
                                          const Divider(height: 1),
                                          SizedBox(height: 16.h),
                                          Text(
                                            'المصادقة الثنائية تضيف طبقة إضافية من الحماية لحسابك. عند تسجيل الدخول ستحتاج إلى إدخال رمز تحقق يتم إرساله عبر الواتساب.',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: const Color(0xFF6B7280),
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 24.h),

                                    // WhatsApp notification
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                        border: Border.all(
                                          color: const Color(0xFFD1FAE5),
                                          width: 1,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(16.r),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(10.r),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD1FAE5),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            child: Icon(
                                              Icons.chat,
                                              color: const Color(0xFF10B981),
                                              size: 24.r,
                                            ),
                                          ),
                                          SizedBox(width: 16.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'رمز التحقق عبر الواتساب',
                                                  style: TextStyle(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF065F46),
                                                  ),
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  'سيتم إرسال رمز التحقق الخاص بك عبر الواتساب إلى رقم هاتفك المسجل.',
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    color:
                                                        const Color(0xFF065F46),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 24.h),

                                    // How it works
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(20.r),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'كيف تعمل المصادقة الثنائية؟',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2D3748),
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          _buildStep(
                                            icon: Icons.login,
                                            title: 'تسجيل الدخول',
                                            description:
                                                'أدخل اسم المستخدم وكلمة المرور الخاصة بك كالمعتاد.',
                                            stepNumber: 1,
                                          ),
                                          SizedBox(height: 16.h),
                                          _buildStep(
                                            icon: Icons.message,
                                            title: 'استلام الرمز',
                                            description:
                                                'ستتلقى رمز تحقق من 6 أرقام عبر الواتساب على رقم هاتفك المسجل.',
                                            stepNumber: 2,
                                          ),
                                          SizedBox(height: 16.h),
                                          _buildStep(
                                            icon: Icons.check_circle,
                                            title: 'إدخال الرمز',
                                            description:
                                                'أدخل الرمز في الصفحة المخصصة لإكمال عملية تسجيل الدخول.',
                                            stepNumber: 3,
                                          ),
                                        ],
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String description,
    required int stepNumber,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFFF97316),
              size: 20.r,
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24.r,
                    height: 24.r,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF97316),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom painter for shimmer pattern effect - same as in the profile page
class ShimmerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

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
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // Random dots
    final random = math.Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 4 + 1;
      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
