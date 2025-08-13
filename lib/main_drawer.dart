import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/privacy_screen.dart';
import 'package:my_project/refund.dart';
import 'package:my_project/terms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Feature/Auth/presentation/view/login_screen.dart';
import 'account.dart';
import 'contact_us_page.dart';
import 'package:my_project/new_ticket.dart';
import 'notifications/notification_screen.dart';
import 'offer.dart';
import 'transaction_history_screen.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            bottomLeft: Radius.circular(20.r),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Account Section
                    _buildSectionHeader('الحساب'),
                    _buildMenuItem(
                      icon: 'assets/images/profile_icon.png',
                      label: 'حسابي',
                      onTap: () => _navigateWithAnimation(
                          context, const AccountScreen()),
                    ),
                    _buildMenuItem(
                      icon: 'assets/images/transaction_icon.png',
                      label: 'المعاملات',
                      onTap: () => _navigateWithAnimation(
                          context, const TransactionHistoryScreen()),
                    ),

                    SizedBox(height: 16.h),

                    // Services Section
                    _buildSectionHeader('الخدمات'),
                    _buildMenuItem(
                      icon: 'assets/images/shows_icon.png',
                      label: 'العروض',
                      onTap: () =>
                          _navigateWithAnimation(context, const OffersPage()),
                    ),
                    _buildMenuItem(
                      icon: 'assets/images/arcticons_tickets.png',
                      label: 'التذاكر',
                      onTap: () => _navigateWithAnimation(
                          context, const TicketsScreen()),
                    ),

                    SizedBox(height: 16.h),

                    // Info Section
                    _buildSectionHeader('المعلومات'),
                    _buildMenuItem(
                      icon: 'assets/images/notification.png',
                      label: 'الاشعارات',
                      onTap: () => _navigateWithAnimation(
                          context, const NotificationsScreen()),
                    ),
                    _buildMenuItem(
                      icon: 'assets/images/privacy_icon.png',
                      label: 'الخصوصية و الأمان',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PrivacyScreen())),
                    ),
                    _buildMenuItem(
                      icon: 'assets/images/terms_icons.png',
                      label: 'الشروط والأحكام',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TermsScreen())),
                    ),
                    _buildMenuItem(
                      icon: 'assets/images/hugeicons_database-restore.png',
                      label: 'سياسة الاسترجاع',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const RefundPolicyScreen())),
                    ),
                    _buildMenuItem(
                      icon: 'assets/images/phone_icon.png',
                      label: 'اتصل بنا',
                      onTap: () => _navigateWithAnimation(
                          context, const ContactUsPage()),
                    ),
                  ],
                ),
              ),

              // Logout button at bottom
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(right: 16.w, left: 16.w, top: 8.h, bottom: 4.h),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40.w,
              height: 40.w,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5951F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: ImageIcon(
                AssetImage(icon),
                color: const Color(0xFFF5951F),
                size: 24.r,
              ),
            ),
            SizedBox(width: 16.w),
            // Label
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16.r,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () => _logout(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: ImageIcon(
                const AssetImage('assets/images/solar_logout-outline.png'),
                color: Colors.red.shade700,
                size: 20.r,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateWithAnimation(BuildContext context, Widget page) {
    Navigator.of(context).pop(); // Close the drawer

    // Navigate with animation
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pop(); // Close the drawer

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        bool isTablet = MediaQuery.of(context).size.width > 600;

        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),

              // Icon
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade700,
                  size: 32.r,
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Text(
                'تأكيد تسجيل الخروج',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isTablet ? 22.sp : 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isTablet ? 16.sp : 14.sp,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        backgroundColor: Colors.grey.shade100,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
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

                  // Logout button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('user_data');
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red.shade700,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'تسجيل الخروج',
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
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }
}
