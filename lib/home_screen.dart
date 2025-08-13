import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/notifications/notification_screen.dart';
import 'package:my_project/notifications/controller/notification_provider.dart';
import 'package:my_project/services/maintenance_service.dart';
import 'package:my_project/maintenance_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:developer';
import 'blog.dart';
import 'company_screen.dart';
import 'main_drawer.dart';
import 'transaction_history_screen.dart';
import 'home.dart';

// Make sure this file contains the updated drawer code

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final GlobalKey _drawerKey = GlobalKey();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _transactionsKey = GlobalKey();
  final GlobalKey _newsKey = GlobalKey();
  final GlobalKey _companyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
    _checkMaintenanceStatus();
  }

  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase = prefs.getBool('hasSeenShowcase') ?? false;

    if (!hasSeenShowcase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([
          _drawerKey,
          _homeKey,
          _transactionsKey,
          _newsKey,
          _companyKey,
        ]);
      });

      await prefs.setBool('hasSeenShowcase', true);
    }
  }

  // إضافة دالة فحص حالة الصيانة
  Future<void> _checkMaintenanceStatus() async {
    try {
      final isInMaintenance =
          await MaintenanceService().checkMaintenanceStatus();
      log("Home Screen - Maintenance check result: $isInMaintenance");

      if (isInMaintenance && mounted) {
        // الانتقال إلى شاشة الصيانة إذا كان التطبيق في وضع الصيانة
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
        );
      }
    } catch (e) {
      log("Error checking maintenance status: $e");
    }
  }

  // قائمة الصفحات
  final List<Widget> _screens = [
    const HomePage(),
    const TransactionHistoryScreen(),
    const NewsScreen(), // صفحة الأخبار
    const CompanyScreen(), // صفحة الشركة
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // إضافة دالة التحقق من الخروج
  Future<bool> _onWillPop() async {
    bool? exitConfirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // قبضة البوتوم شيت
              Container(
                width: 50.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),

              // أيقونة التحذير
              Container(
                width: 80.w,
                height: 80.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 40.r,
                  color: Colors.red.shade600,
                ),
              ),

              // عنوان
              Text(
                'هل تريد الخروج من التطبيق؟',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 10.h),

              // رسالة
              Text(
                'اضغط تأكيد للخروج من التطبيق',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30.h),

              // أزرار
              Row(
                children: [
                  // زر الإلغاء
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.grey.shade800,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // زر التأكيد
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                        // إنهاء التطبيق
                        SystemNavigator.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'تأكيد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    // إذا ضغط تأكيد، خروج من التطبيق
    if (exitConfirmed == true) {
      return true;
    }

    // إلغاء الخروج من التطبيق
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<NotificationProvider>(context, listen: false)
        .fetchNotifications();

    return Directionality(
      textDirection: TextDirection.rtl, // لضبط اتجاه النص من اليمين إلى اليسار
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: const Color(0xFF38659B),
            automaticallyImplyLeading: false,
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                SizedBox(width: 4.w),
                // قائمة جانبية
                Showcase(
                  key: _drawerKey,
                  description: "اضغط هنا لفتح القائمة الجانبية",
                  descTextStyle: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                  ),
                  tooltipBackgroundColor: Colors.blueGrey.shade800,
                  child: Builder(
                    builder: (context) => Container(
                      width: 42.w,
                      height: 42.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: const Center(
                          child: Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _selectedIndex == 0
                          ? 'الصفحة الرئيسية'
                          : _selectedIndex == 1
                              ? 'معاملاتي'
                              : _selectedIndex == 2
                                  ? 'التدوينات'
                                  : 'الشركة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 42.w,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Center(
                      child: Consumer<NotificationProvider>(
                        builder: (context, value, child) {
                          return value.notificationCount > 0
                              ? Badge(
                                  backgroundColor: Colors.red.shade600,
                                  label: Text('${value.notificationCount}'),
                                  child: const Icon(
                                    Icons.notifications_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                )
                              : const Icon(
                                  Icons.notifications_rounded,
                                  color: Colors.white,
                                  size: 24,
                                );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
            ),
          ),
          drawer: const MainDrawer(), // القائمة الجانبية
          body: _screens[_selectedIndex], // عرض الصفحة بناءً على الزر المحدد
          bottomNavigationBar: Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  Icons.home_filled,
                  'الرئيسية',
                  0,
                  _homeKey,
                  "الصفحة الرئيسية - المكان الذي تبدأ منه كل عملياتك",
                ),
                _buildNavItem(
                  Icons.sync_alt_rounded,
                  'معاملاتي',
                  1,
                  _transactionsKey,
                  "معاملاتي - تتبع جميع عملياتك وطلباتك",
                ),
                _buildNavItem(
                  Icons.article_rounded,
                  'التدوينات',
                  2,
                  _newsKey,
                  "التدوينات - آخر الأخبار والمقالات المهمة",
                ),
                _buildNavItem(
                  Icons.business_rounded,
                  'الشركة',
                  3,
                  _companyKey,
                  "الشركة - تعرف على شركتنا وخدماتنا",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة لبناء عناصر الشريط السفلي
  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    GlobalKey key,
    String description,
  ) {
    final isSelected = _selectedIndex == index;
    return Showcase(
      key: key,
      description: description,
      descTextStyle: TextStyle(
        fontSize: 14.sp,
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      tooltipBackgroundColor: Colors.blueGrey.shade800,
      showArrow: true,
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          width: 80.w,
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF38659B).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? const Color(0xFF38659B)
                      : Colors.grey.shade500,
                  size: 22.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: 'Cairo',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF38659B)
                      : Colors.grey.shade500,
                ),
              ),
              if (isSelected)
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  width: 8.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38659B),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
