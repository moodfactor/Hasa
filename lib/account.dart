import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/reset_pass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'commission.dart';
import 'profile.dart';
import 'referral.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  // Track the currently pressed item
  int? _pressedItemIndex;

  final List<Map<String, dynamic>> accountOptions = [
    {
      'icon': 'assets/images/profile_settings_icon.png',
      'label': 'إعدادات الملف الشخصي',
      'description': 'تعديل البيانات الشخصية والإعدادات',
      'gradient': const [Color(0xFFFF8A00), Color(0xFFF5951F)],
      'screen': const ProfileSettingsScreen(),
      'key': GlobalKey(),
    },
    {
      'gradient': const [Color(0xFF5E72E4), Color(0xFF825EE4)],
      'icon': 'assets/images/Referrals_icon.png',
      'label': 'الأحالات',
      'description': 'إدارة الإحالات الخاصة بك',
      'screen': const ReferralsScreen(),
      'key': GlobalKey(),
    },
    {
      'gradient': const [Color(0xFF11CDEF), Color(0xFF1171EF)],
      'icon': 'assets/images/history_ico.png',
      'label': 'سجل العمولات',
      'description': 'عرض سجل العمولات الخاصة بك',
      'screen': const CommissionHistoryScreen(),
      'key': GlobalKey(),
    },
    {
      'icon': 'assets/images/carbon_password.png',
      'label': 'تغير كلمة السر',
      'description': 'تعديل كلمة السر وتأمين الحساب',
      'gradient': const [Color(0xFFFB6340), Color(0xFFFF3159)],
      'screen': const ResetPasswordScreen(),
      'key': GlobalKey(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
    _checkFirstTimeUser();

    // Add haptic feedback when screen loads
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase =
        prefs.getBool('hasSeenShowcase_AccountScreen') ?? false;

    if (!hasSeenShowcase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([
          accountOptions[0]['key'], // Profile Settings (now first)
          accountOptions[1]['key'], // Referrals
          accountOptions[2]['key'], // Commission History
          accountOptions[3]['key'], // Change Password
        ]);
      });

      await prefs.setBool('hasSeenShowcase_AccountScreen', true);
    }
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeOutCubic;

          var slideTween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: curve));
          var scaleTween = Tween<double>(begin: 0.9, end: 1.0)
              .chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(slideTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0.w),
            child: Container(
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
                  Icons.arrow_forward,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'حسابي',
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
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D3748),
                  Color(0xFF1A202C),
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

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ScaleTransition(
                  scale: _scaleAnimation,
                  child: child,
                );
              },
              child: Column(
                children: [
                  SizedBox(height: 60.h),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.r),
                          topRight: Radius.circular(30.r),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                            left: 20.w, right: 20.w, top: 30.h, bottom: 30.h),
                        physics: const BouncingScrollPhysics(),
                        itemCount: accountOptions.length,
                        itemBuilder: (context, index) {
                          final option = accountOptions[index];
                          final gradientColors =
                              option['gradient'] as List<Color>;

                          // Different animation speeds based on index
                          final delay = index * 150;

                          return TweenAnimationBuilder(
                            duration: Duration(milliseconds: 550 + delay),
                            tween: Tween<double>(begin: 0, end: 1),
                            curve: Curves.easeOutQuint,
                            builder: (context, double value, child) {
                              // Ensure opacity is between 0.0 and 1.0
                              final safeOpacity = value.clamp(0.0, 1.0);

                              return Opacity(
                                opacity: safeOpacity,
                                child: Transform.translate(
                                  offset: Offset(50 * (1 - value), 0),
                                  child: Transform.scale(
                                    scale: 0.8 + (0.2 * value.clamp(0.0, 1.0)),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: Showcase(
                                key: option['key'],
                                description:
                                    'اضغط هنا للدخول إلى ${option['label']}',
                                descTextStyle: TextStyle(
                                  fontSize: 14.sp,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                child: StatefulBuilder(
                                    builder: (context, setState) {
                                  bool isPressed = _pressedItemIndex == index;

                                  return GestureDetector(
                                    onTapDown: (_) {
                                      setState(() {
                                        _pressedItemIndex = index;
                                      });
                                      HapticFeedback.lightImpact();
                                    },
                                    onTapUp: (_) {
                                      setState(() {
                                        _pressedItemIndex = null;
                                      });
                                      _navigateToScreen(
                                          context, option['screen'] as Widget);
                                    },
                                    onTapCancel: () {
                                      setState(() {
                                        _pressedItemIndex = null;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      transform: isPressed
                                          ? Matrix4.translationValues(0, 2, 0)
                                          : Matrix4.identity(),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(24.r),
                                        boxShadow: isPressed
                                            ? [
                                                BoxShadow(
                                                  color: gradientColors.first
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 6,
                                                  spreadRadius: 0,
                                                  offset: const Offset(0, 2),
                                                ),
                                                BoxShadow(
                                                  color: gradientColors.first
                                                      .withOpacity(0.07),
                                                  blurRadius: 15,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.r),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              height: 36.h,
                                              width: 36.w,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    gradientColors.first
                                                        .withOpacity(0.1),
                                                    gradientColors.last
                                                        .withOpacity(0.2),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              child: Icon(
                                                Icons.arrow_back_ios_rounded,
                                                color: gradientColors.last,
                                                size: 16,
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 16.w),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Text(
                                                            option['label']
                                                                as String,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Cairo',
                                                              fontSize: 17.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: const Color(
                                                                  0xFF2D3748),
                                                            ),
                                                          ),
                                                          SizedBox(height: 5.h),
                                                          Text(
                                                            option['description']
                                                                as String,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Cairo',
                                                              fontSize: 13.sp,
                                                              color: const Color(
                                                                  0xFF718096),
                                                            ),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 60.w,
                                                    height: 60.h,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: gradientColors,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              18.r),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: gradientColors
                                                              .first
                                                              .withOpacity(0.4),
                                                          blurRadius: 10,
                                                          spreadRadius: 0,
                                                          offset: const Offset(
                                                              0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: ImageIcon(
                                                        AssetImage(
                                                            option['icon']
                                                                as String),
                                                        color: Colors.white,
                                                        size: 26.r,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
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
