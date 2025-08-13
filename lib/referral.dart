import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ReferralsScreenState createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen>
    with SingleTickerProviderStateMixin {
  String? username;
  bool isLoading = true;
  List<dynamic> referrals = [];
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint));
    _loadUsername();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      Map<String, dynamic> userData = jsonDecode(userJson);
      setState(() {
        username = userData['username'] ?? 'unknown';
        isLoading = false;
        _controller.forward();
      });
    } else {
      setState(() {
        username = 'unknown';
        isLoading = false;
        _controller.forward();
      });
    }
  }

  void _copyReferralLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    HapticFeedback.lightImpact();
    setState(() {
      _isCopied = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10.w),
            Text(
              'تم نسخ رابط الإحالة بنجاح',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5E72E4),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(15.r),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String referralLink =
        'https://ha55a.exchange?reference=${username ?? "unknown"}';

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
          )
        ],
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'الإحالات',
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
                  Color(0xFF5E72E4),
                  Color(0xFF825EE4),
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
                                  'قم بمشاركة الرابط',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                                    fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  'احصل على عمولة من كل إحالة',
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
                                Icons.people_alt_rounded,
                                color: Colors.white,
                                size: 30.r,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Expanded(
                        child: Column(
                          children: [
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
                                child: Padding(
                                  padding: EdgeInsets.all(20.r),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'رابط الإحالة الخاص بك',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2D3748),
                                        ),
                                      ),
                                      SizedBox(height: 15.h),
                                      // Referral link card
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFF8FAFC),
                                              Color(0xFFE2E8F0),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 10,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.all(16.r),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(8.r),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF5E72E4)
                                                            .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.r),
                                                  ),
                                                  child: const Icon(
                                                    Icons.link_rounded,
                                                    color: Color(0xFF5E72E4),
                                                  ),
                                                ),
                                                SizedBox(width: 10.w),
                                                Expanded(
                                                  child: Text(
                                                    isLoading
                                                        ? "جاري التحميل..."
                                                        : referralLink,
                                                    style: TextStyle(
                                                      fontFamily: 'Cairo',
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: const Color(
                                                          0xFF2D3748),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16.h),
                                            Row(
                                              children: [
                                                const Spacer(),
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: _isCopied
                                                          ? [
                                                              const Color(
                                                                  0xFF4CAF50),
                                                              const Color(
                                                                  0xFF2E7D32)
                                                            ]
                                                          : [
                                                              const Color(
                                                                  0xFF5E72E4),
                                                              const Color(
                                                                  0xFF825EE4)
                                                            ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.r),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: _isCopied
                                                            ? const Color(
                                                                    0xFF4CAF50)
                                                                .withOpacity(
                                                                    0.3)
                                                            : const Color(
                                                                    0xFF5E72E4)
                                                                .withOpacity(
                                                                    0.3),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: isLoading
                                                          ? null
                                                          : () =>
                                                              _copyReferralLink(
                                                                  referralLink),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.r),
                                                      child: Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: 16.w,
                                                          vertical: 12.h,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              _isCopied
                                                                  ? Icons.check
                                                                  : Icons
                                                                      .content_copy,
                                                              color:
                                                                  Colors.white,
                                                              size: 16.r,
                                                            ),
                                                            SizedBox(
                                                                width: 5.w),
                                                            Text(
                                                              _isCopied
                                                                  ? 'تم النسخ'
                                                                  : 'نسخ الرابط',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Cairo',
                                                                fontSize: 14.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
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
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF5E72E4),
                                              Color(0xFF825EE4),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF5E72E4)
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 16.h),
                    child: Text(
                      'المستخدمون المشار إليهم من قبلي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                                            fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                                      SizedBox(height: 20.h),
                                      Expanded(
                                        child: Center(
                                          child: referrals.isEmpty
                                              ? Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Lottie.asset(
                            'assets/images/empty.json',
                                                      height: 200.h,
                                                    ),
                                                    Text(
                                                      'لا يوجد مستخدمين محالين بعد',
                                                      style: TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 14.sp,
                                                        color: const Color(
                                                            0xFF718096),
                                                      ),
                                                    ),
                                                    SizedBox(height: 10.h),
                                                    Text(
                                                      'قم بمشاركة الرابط مع أصدقائك',
                                                      style: TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: const Color(
                                                            0xFF5E72E4),
                                                      ),
                                                    ),
                                                  ],
                        )
                      : Container(),
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
