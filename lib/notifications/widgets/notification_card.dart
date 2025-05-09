import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/drainagedetails.dart';
import 'package:my_project/notifications/controller/notification_provider.dart';
import 'package:my_project/ticket_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

class NotificationCard extends StatelessWidget {
  final String title;
  final String details;
  final String timestamp;
  final bool isRead;
  final String type;
  final String typeId;
  final String notif;
  final Function refreshNotifications;

  const NotificationCard({
    super.key,
    required this.title,
    required this.details,
    required this.timestamp,
    required this.isRead,
    required this.type,
    required this.typeId,
    required this.notif,
    required this.refreshNotifications,
  });

  String _formatTimestamp(String timestamp) {
    try {
      // Parse the timestamp
      DateTime dateTime = DateTime.parse(timestamp);
      // Format it in a friendly way
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 30) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        return intl.DateFormat('yyyy/MM/dd').format(dateTime);
      }
    } catch (e) {
      return timestamp;
    }
  }

  // Get the icon based on notification type
  IconData _getNotificationIcon() {
    if (type.toLowerCase() == 'ticket') {
      return Icons.confirmation_number_outlined;
    } else if (type.toLowerCase() == 'order') {
      return Icons.shopping_bag_outlined;
    } else {
      return Icons.notifications_outlined;
    }
  }

  // Get the color based on notification type
  Color _getNotificationColor() {
    if (type.toLowerCase() == 'ticket') {
      return const Color(0xFF2E7D32);
    } else if (type.toLowerCase() == 'order') {
      return const Color(0xFF1565C0);
    } else {
      return const Color(0xFF9C27B0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (type.toLowerCase() == 'ticket') {
          int? ticketId = int.tryParse(typeId);
          if (ticketId != null && ticketId != 0) {
            // Mark as read and navigate to ticket details
            Provider.of<NotificationProvider>(context, listen: false)
                .readNotification(notif);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetailsScreen(ticketId: ticketId),
              ),
            );
          } else {
            log("❌ معرف التذكرة غير صالح: $typeId");
            _showReadConfirmationBottomSheet(context);
          }
        } else if (type.toLowerCase() == 'order') {
          int? orderId = int.tryParse(typeId);
          if (orderId != null && orderId != 0) {
            // Mark as read and navigate to order details
            Provider.of<NotificationProvider>(context, listen: false)
                .readNotification(notif);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Drainagedetails(
                  id: orderId.toString(),
                  email: '',
                ),
              ),
            );
          } else {
            log("❌ معرف الطلب غير صالح: $typeId");
            _showReadConfirmationBottomSheet(context);
          }
        } else {
          // This is a general notification with no specific navigation
          _showReadConfirmationBottomSheet(context);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF3F8FF),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: isRead
              ? Border.all(color: Colors.grey.shade200, width: 1)
              : Border.all(color: const Color(0xFFE0EAFF), width: 1),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification icon
                    Container(
                      height: 45.r,
                      width: 45.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getNotificationColor().withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(
                          _getNotificationIcon(),
                          color: _getNotificationColor(),
                          size: 24.r,
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Notification content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    color: const Color(0xFF031E4B),
                                    height: 1.2,
                                  ),
                                ),
                              ),

                              // New badge
                              if (!isRead)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    'جديد',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(height: 6.h),

                          // Notification details
                          Text(
                            details,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Divider and timestamp
                Row(
                  children: [
                    const Expanded(
                      child: Divider(),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12.sp,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      child: Divider(),
                    ),
                  ],
                ),

                // Type label at the bottom
                if (type.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getNotificationColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      type.toLowerCase() == 'ticket'
                          ? 'تذكرة'
                          : type.toLowerCase() == 'order'
                              ? 'طلب'
                              : type,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: _getNotificationColor(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method to show the confirmation bottom sheet
  void _showReadConfirmationBottomSheet(BuildContext context) {
    if (isRead) {
      // If already read, no need to show confirmation
      return;
    }

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
                    Icons.mark_email_read_outlined,
                    color: const Color(0xFF031E4B),
                    size: 30.r,
                  ),
                ),
                SizedBox(height: 16.h),

                // Title
                Text(
                  'تأكيد قراءة الإشعار',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF031E4B),
                  ),
                ),
                SizedBox(height: 8.h),

                // Description
                Text(
                  'هل تريد تحديد هذا الإشعار كمقروء؟',
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
                          // Mark notification as read
                          Provider.of<NotificationProvider>(context,
                                  listen: false)
                              .readNotification(notif);

                          Navigator.pop(context);

                          // Refresh notifications list to show updated status
                          refreshNotifications();

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تحديد الإشعار كمقروء',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14.sp,
                                ),
                              ),
                              backgroundColor: const Color(0xFF031E4B),
                              duration: const Duration(seconds: 2),
                            ),
                          );
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
