import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:math' as math;
import 'about.dart';
import 'contact_us_page.dart';
import 'faq.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _aboutUsKey = GlobalKey();
  final GlobalKey _contactUsKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  // Animation controller for the screen
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<Animation<Offset>> _slideAnimations;

  // Track the active card for interactive animations
  int _activeCardIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkFirstTimeUser();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Create staggered slide animations for each card
    _slideAnimations = List.generate(
      3,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.1 + (index * 0.15),
          0.7 + (index * 0.1),
          curve: Curves.easeOutCubic,
        ),
      )),
    );

    _animationController.forward();
  }

  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase = prefs.getBool('hasSeenCompanyShowcase') ?? false;

    if (!hasSeenShowcase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([
          _aboutUsKey,
          _contactUsKey,
          _faqKey,
        ]);
      });

      await prefs.setBool('hasSeenCompanyShowcase', true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF8F9FD),
                      const Color(0xFFF0F5FF),
                      Colors.white,
                    ],
                    stops: [0.0, 0.5 + (_animationController.value * 0.1), 1.0],
                  ),
                ),
              );
            },
          ),

          // Decorative circles
          Positioned(
            top: -70.h,
            right: -50.w,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    5 * math.sin(_animationController.value * 2 * math.pi),
                    10 * math.cos(_animationController.value * math.pi),
                  ),
                  child: Container(
                    width: 150.w,
                    height: 150.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF031E4B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: -60.h,
            left: -30.w,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    10 * math.cos(_animationController.value * math.pi),
                    5 * math.sin(_animationController.value * 2 * math.pi),
                  ),
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF095EB2).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // Header section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: EdgeInsets.all(16.sp),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.sp),
                            decoration: BoxDecoration(
                              color: const Color(0xFF031E4B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.business_center_rounded,
                              color: const Color(0xFF031E4B),
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'خدمات الشركة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF031E4B),
                                  ),
                                ),
                                Text(
                                  'استكشف خدماتنا المتنوعة',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 25.h),

                  // Cards section
                  Expanded(
                    child: ListView(
                      children: [
                        // About Us card
                        SlideTransition(
                          position: _slideAnimations[0],
                          child: Showcase(
                            key: _aboutUsKey,
                            description: "تعرف على المزيد حول شركتنا وتاريخها",
                            descTextStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                            tooltipBackgroundColor: const Color(0xFF031E4B),
                            child: _buildCard(
                              index: 0,
                              title: 'عن هسة',
                              description: 'تعرف على رؤيتنا وقيمنا ومهمتنا',
                              imagePath: 'assets/images/about.png',
                              color: const Color(0xFF031E4B),
                              iconData: Icons.business_outlined,
                              onTap: () {
                                _navigateWithAnimation(
                                    context, const AboutUsScreen());
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // Contact Us card
                        SlideTransition(
                          position: _slideAnimations[1],
                          child: Showcase(
                            key: _contactUsKey,
                            description: "تواصل معنا للاستفسارات والمساعدة",
                            descTextStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                            tooltipBackgroundColor: const Color(0xFF095EB2),
                            child: _buildCard(
                              index: 1,
                              title: 'تواصل معنا',
                              description:
                                  'نحن هنا دائمًا للإجابة على استفساراتك',
                              imagePath: 'assets/images/contact us.png',
                              color: const Color(0xFF095EB2),
                              iconData: Icons.contact_support_outlined,
                              onTap: () {
                                _navigateWithAnimation(
                                    context, const ContactUsPage());
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // FAQ card
                        SlideTransition(
                          position: _slideAnimations[2],
                          child: Showcase(
            key: _faqKey,
                            description:
                                "الأسئلة الشائعة - إجابات على استفساراتك",
                            descTextStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                            tooltipBackgroundColor: const Color(0xFF3166AB),
                            child: _buildCard(
                              index: 2,
                              title: 'الأسئلة الشائعة',
                              description: 'إجابات سريعة لأكثر الأسئلة شيوعًا',
              imagePath: 'assets/images/faq.png',
                              color: const Color(0xFF3166AB),
                              iconData: Icons.question_answer_outlined,
              onTap: () {
                                _navigateWithAnimation(
                                    context, const FaqScreen());
              },
                            ),
                          ),
                        ),

                        SizedBox(height: 20.h),
                      ],
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

  Widget _buildCard({
    required int index,
    required String title,
    required String description,
    required String imagePath,
    required Color color,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    bool isActive = _activeCardIndex == index;

    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) {
        setState(() {
          _activeCardIndex = index;
        });
      },
      onTapUp: (_) {
        setState(() {
          _activeCardIndex = -1;
        });
      },
      onTapCancel: () {
        setState(() {
          _activeCardIndex = -1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 180.h,
        transform:
            isActive ? (Matrix4.identity()..scale(0.98)) : Matrix4.identity(),
          decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isActive ? 0.2 : 0.1),
              blurRadius: isActive ? 12 : 8,
              offset: isActive ? const Offset(0, 5) : const Offset(0, 3),
              spreadRadius: isActive ? 1 : 0,
            ),
          ],
          ),
        child: Stack(
          children: [
            // Background image with gradient overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                children: [
                  // Image
                  Image.asset(
                    imagePath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay
                  Container(
              decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          color.withOpacity(0.8),
                          color.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),

            // Content
            Padding(
              padding: EdgeInsets.all(20.sp),
              child: Row(
                children: [
                  // Left side - text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                            fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          description,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'استكشف',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right side - icon
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        iconData,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ripple effect on active state
            if (isActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isActive ? 1.0 : 0.0,
                    child: CustomPaint(
                      painter:
                          RipplePainter(color: Colors.white.withOpacity(0.1)),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  void _navigateWithAnimation(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve = const Interval(0.0, 0.8, curve: Curves.easeOutCubic);

          // Combined animations for a more elegant transition
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0.0, 0.1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: curve)),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0)
                    .animate(CurvedAnimation(parent: animation, curve: curve)),
            child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }
}

// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final Color color;

  RipplePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw ripple circles
    for (int i = 5; i > 0; i--) {
      final double radius = size.width * (i / 5) * 0.3;
      final double opacity = 0.1 / i;
      paint.color = color.withOpacity(opacity);

      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.15),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
