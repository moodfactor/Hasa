import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';
import 'package:my_project/services/maintenance_service.dart';
import 'dart:convert';
import 'dart:developer' as dev;

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String _apiTestResult = '';
  bool _showDebugSection = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFFFFF),
                const Color(0xFFFFF8EE),
              ],
            ),
          ),
          child: Stack(
            children: [
              // المحتوى الأساسي
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Custom animated gear icons
                  SizedBox(height: 60.h),
                  _buildAnimatedGears(),
                  SizedBox(height: 40.h),

                  // Maintenance title
                  Text(
                    "التطبيق تحت الصيانة",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Maintenance message
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      "نعمل حالياً على تحسين خدماتنا لتقديم تجربة أفضل لك. نعتذر عن الإزعاج وسنعود قريباً.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        color: const Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),

                  // Information box
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 32.w),
                    padding: EdgeInsets.all(20.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.access_time_rounded,
                          "وقت العودة المتوقع",
                          "قريباً",
                        ),
                        Divider(height: 24.h, color: const Color(0xFFEEEEEE)),
                        _buildInfoRow(
                          Icons.email_outlined,
                          "للاستفسارات يرجى التواصل",
                          "support@ha55a.exchange",
                        ),
                        Divider(height: 24.h, color: const Color(0xFFEEEEEE)),
                        Row(
                          children: [
                            Container(
                              width: 24.h,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(12.h),
                              ),
                              child: Icon(
                                Icons.chat,
                                color: Colors.white,
                                size: 16.h,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "للتواصل عبر الواتساب",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12.sp,
                                    color: const Color(0xFF999999),
                                  ),
                                ),
                                Text(
                                  "9647722660998",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 60.h),

                  // Decorative element at bottom
                  Container(
                    width: double.infinity,
                    height: 6.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFF5951F),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ],
              ),

              // زر التطوير (تنشيط بالضغط 5 مرات متتالية على الشعار)
              Positioned(
                top: 20.h,
                right: 20.w,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showDebugSection = !_showDebugSection;
                    });
                    if (_showDebugSection) {
                      _testMaintenanceAPI();
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _showDebugSection
                          ? const Color(0xFFF5951F).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.developer_mode,
                      color: _showDebugSection
                          ? const Color(0xFFF5951F)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),

              // قسم اختبارات المطور
              if (_showDebugSection)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(16.h),
                    color: Colors.black.withOpacity(0.8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'وضع المطور',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _showDebugSection = false;
                                });
                              },
                            )
                          ],
                        ),
                        const Divider(color: Colors.white30),
                        ElevatedButton(
                          onPressed: _testMaintenanceAPI,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5951F),
                          ),
                          child: Text(
                            'اختبار API الصيانة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          height: 150.h,
                          padding: EdgeInsets.all(8.h),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _apiTestResult,
                              style: TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 12.sp,
                                color: Colors.white,
                              ),
                            ),
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
    );
  }

  Future<void> _testMaintenanceAPI() async {
    try {
      setState(() {
        _apiTestResult = 'جاري الاختبار...';
      });

      final result = await MaintenanceService.testMaintenanceAPI();

      // تحليل كامل للبيانات
      String formattedResult = '';
      formattedResult += 'Status Code: ${result['statusCode']}\n';
      formattedResult += 'Is In Maintenance: ${result['isInMaintenance']}\n\n';

      if (result['data'] != null) {
        final data = result['data'];
        formattedResult += 'Success: ${data['success']}\n';

        if (data['data'] is List && data['data'].isNotEmpty) {
          final maintenanceData = data['data'][0];
          formattedResult += '\nMaintenance Data:\n';
          formattedResult += 'ID: ${maintenanceData['id']}\n';
          formattedResult += 'Mode: ${maintenanceData['maintenance_mode']}\n';
          formattedResult +=
              'Mode Type: ${maintenanceData['maintenance_mode'].runtimeType}\n\n';

          // فحص ما إذا كانت القيمة تساوي "1" كنص
          final modeValue = maintenanceData['maintenance_mode'];
          formattedResult +=
              'toString() == "1": ${modeValue.toString() == "1"}\n';

          // نتائج طرق المقارنة المختلفة
          formattedResult += 'Direct comparison (== 1): ${modeValue == 1}\n';
          formattedResult +=
              'String comparison (== "1"): ${modeValue == "1"}\n';

          // تحليل السبب المحتمل للمشكلة
          if (modeValue.toString() == "1" && modeValue != 1) {
            formattedResult += '\n🔍 تشخيص: القيمة مخزنة كنص "1" وليس كرقم 1\n';
            formattedResult += 'الحل: استخدام المقارنة .toString() == "1"';
          }
        }
      } else if (result['error'] != null) {
        formattedResult += 'Error: ${result['error']}';
      }

      setState(() {
        _apiTestResult = formattedResult;
      });

      dev.log('API Test Result: $formattedResult');
    } catch (e) {
      setState(() {
        _apiTestResult = 'Error: $e';
      });
      dev.log('Error in test function: $e');
    }
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFF5951F),
          size: 24.h,
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                color: const Color(0xFF999999),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedGears() {
    return SizedBox(
      height: 160.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main gear
          _buildRotatingGear(
            size: 120.h,
            color: const Color(0xFFF5951F),
            duration: const Duration(seconds: 10),
          ),

          // Secondary gear - top right
          Positioned(
            top: 10.h,
            right: 100.w,
            child: _buildRotatingGear(
              size: 60.h,
              color: const Color(0xFF3498DB),
              duration: const Duration(seconds: 8),
              reverse: true,
            ),
          ),

          // Secondary gear - bottom left
          Positioned(
            bottom: 20.h,
            left: 110.w,
            child: _buildRotatingGear(
              size: 40.h,
              color: const Color(0xFF2ECC71),
              duration: const Duration(seconds: 6),
              reverse: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotatingGear({
    required double size,
    required Color color,
    required Duration duration,
    bool reverse = false,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 2 * 3.14159),
      duration: duration,
      builder: (context, double value, child) {
        return Transform.rotate(
          angle: reverse ? -value : value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: GearPainter(color: color),
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }
}

class GearPainter extends CustomPainter {
  final Color color;

  GearPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    // Draw the gear
    Path path = Path();

    // Number of teeth
    final int teethCount = 8;
    final double angleStep = 2 * 3.14159 / teethCount;
    final double outerRadius = radius;
    final double innerRadius = radius * 0.7;
    final double toothDepth = radius * 0.3;

    for (int i = 0; i < teethCount; i++) {
      double angle = i * angleStep;

      // Outer point
      double x1 = centerX + outerRadius * cos(angle);
      double y1 = centerY + outerRadius * sin(angle);

      // Tooth outer point
      double toothAngle = angle + angleStep / 4;
      double x2 = centerX + (outerRadius + toothDepth) * cos(toothAngle);
      double y2 = centerY + (outerRadius + toothDepth) * sin(toothAngle);

      // Tooth outer end point
      double toothEndAngle = angle + angleStep / 2;
      double x3 = centerX + outerRadius * cos(toothEndAngle);
      double y3 = centerY + outerRadius * sin(toothEndAngle);

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }

      path.lineTo(x2, y2);
      path.lineTo(x3, y3);
    }

    path.close();

    // Draw the outer gear
    canvas.drawPath(path, paint);

    // Draw the inner circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(centerX, centerY), innerRadius, paint);

    // Draw a center hole
    paint.color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
