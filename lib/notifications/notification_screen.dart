import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:my_project/home_screen.dart';
import 'package:my_project/notifications/controller/notification_provider.dart';
import 'package:my_project/notifications/widgets/notification_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  Future<List<dynamic>>? notificationsFuture;
  bool isRefreshing = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    notificationsFuture = fetchNotifications();

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      Map<String, dynamic> userData = jsonDecode(userJson);
      return userData['id'].toString();
    }
    return null;
  }

  Future<List<dynamic>> fetchNotifications() async {
    try {
      String? userId = await getUserId();
      if (userId == null) return [];
      var dio = Dio();
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/notfication/get.php?user_id=$userId',
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        // تحويل البيانات لقائمة وعكس ترتيبها بحيث يكون الأحدث أولاً
        var notifications = List<dynamic>.from(response.data['notifications']);
        return notifications.reversed.toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      isRefreshing = true;
    });

    notificationsFuture = fetchNotifications();

    // Also update the notification count in the provider
    await Provider.of<NotificationProvider>(context, listen: false)
        .fetchNotifications();

    // Simulate a slight delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                _showMarkAllAsReadConfirmation();
              },
              icon: const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: Color(0xFF031E4B),
              ),
              label: Text(
                'قراءة الكل',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF031E4B),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF031E4B),
              ),
            ),
          ],
          title: Text(
            'الإشعارات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _refreshNotifications,
          color: const Color(0xFF031E4B),
          backgroundColor: Colors.white,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: FutureBuilder<List<dynamic>>(
              future: notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !isRefreshing) {
                  return Center(
                      child: Lottie.asset('assets/lottie/loading.json',
                          height: 150, width: 150));
                } else if (snapshot.hasError) {
                  return _buildErrorState();
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                } else {
                  return _buildNotificationsList(snapshot.data!);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/images/empty.json',
            height: 200.h,
            repeat: false,
          ),
          SizedBox(height: 20.h),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF031E4B),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'ستظهر هنا جميع الإشعارات الخاصة بك',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 30.h),
          ElevatedButton.icon(
            onPressed: _refreshNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF031E4B),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.sp,
            color: Colors.red.shade400,
          ),
          SizedBox(height: 20.h),
          Text(
            'حدث خطأ أثناء جلب البيانات',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF031E4B),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30.h),
          ElevatedButton.icon(
            onPressed: _refreshNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF031E4B),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<dynamic> notifications) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: notifications.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var notif = notifications[index];

        // Add staggered animation
        return AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeInOut,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  0.1 + (index * 0.05 > 0.5 ? 0.5 : index * 0.05),
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: NotificationCard(
              title: notif['text'] ?? '',
              details: notif['message'] ?? '',
              timestamp: notif['created_at'] ?? '',
              isRead: notif['is_read'] ?? false,
              type: notif['type'] ?? '',
              typeId: notif['type_id']?.toString() ?? '',
              notif: notif['id'].toString(),
              refreshNotifications: _refreshNotifications,
            ),
          ),
        );
      },
    );
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
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showMarkAllAsReadConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(height: 24.h),

                // Icon
                Container(
                  width: 60.r,
                  height: 60.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF031E4B).withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.done_all,
                    color: const Color(0xFF031E4B),
                    size: 30.r,
                  ),
                ),
                SizedBox(height: 16.h),

                // Title
                Text(
                  'قراءة جميع الإشعارات',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF031E4B),
                  ),
                ),
                SizedBox(height: 8.h),

                // Description
                Text(
                  'هل أنت متأكد أنك تريد تحديد جميع الإشعارات كمقروءة؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),

                    // Confirm button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Mark all notifications as read
                          Provider.of<NotificationProvider>(context,
                                  listen: false)
                              .markAllAsRead();

                          Navigator.pop(context);

                          // Refresh notifications list
                          _refreshNotifications();

                          // Show success message
                          _showSuccessMessage(
                              'تم تحديد جميع الإشعارات كمقروءة');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF031E4B),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'تأكيد',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Add extra padding for bottom inset
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom)
              ],
            ),
          ),
        );
      },
    );
  }
}
