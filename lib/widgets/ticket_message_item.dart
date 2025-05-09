import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'ticket_attachments_widget.dart';

class TicketMessageItem extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isAdmin;

  const TicketMessageItem({
    Key? key,
    required this.message,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String messageId = message['id']?.toString() ?? '';
    final String messageText = message['message'] ?? '';
    final String senderName = message['sender_name'] ?? 'مستخدم';
    final String dateTime = message['created_at'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Message header (sender info)
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor:
                    isAdmin ? const Color(0xFFF5951F) : const Color(0xFFECECEC),
                child: Icon(
                  isAdmin ? Icons.support_agent : Icons.person,
                  color: isAdmin ? Colors.white : const Color(0xFF888888),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isAdmin
                          ? const Color(0xFFF5951F)
                          : const Color(0xFF333333),
                    ),
                  ),
                  Text(
                    dateTime,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.sp,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Message content
          Container(
            margin: EdgeInsets.only(top: 8.h, right: 20.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color:
                  isAdmin ? const Color(0xFFFFF8ED) : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color:
                    isAdmin ? const Color(0xFFFFE0B2) : const Color(0xFFE0E0E0),
              ),
            ),
            child: Text(
              messageText,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                height: 1.5,
                color: const Color(0xFF333333),
              ),
            ),
          ),

          // Attachments section
          if (messageId.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 20.w),
              child: TicketAttachments(messageId: messageId),
            ),
        ],
      ),
    );
  }
}
