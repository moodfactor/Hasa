import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import 'widgets/ticket_message_item.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  String? error;

  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadTicketMessages();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketMessages() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // 👇 Replace with your actual API endpoint
      final response = await Dio().get(
        'https://ha55a.exchange/api/v1/ticket/get-ticket-messages.php',
        queryParameters: {'ticket_id': widget.ticketId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          // Convert the response data to List<Map<String, dynamic>>
          messages = List<Map<String, dynamic>>.from(response.data['messages']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          error = "فشل في تحميل الرسائل";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = "خطأ أثناء الاتصال بالشبكة";
      });
    }
  }

  Future<void> _sendReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // 👇 Replace with your actual API endpoint
      final response = await Dio().post(
        'https://ha55a.exchange/api/v1/ticket/add-reply.php',
        data: FormData.fromMap({
          'ticket_id': widget.ticketId,
          'message': message,
          // Add other required fields here
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Clear the input field
        _replyController.clear();

        // Reload messages to see the new reply
        await _loadTicketMessages();

        // Success notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الرد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Error notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في إرسال الرد'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ أثناء الاتصال بالشبكة'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "تفاصيل التذكرة",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF333333),
          elevation: 1,
          centerTitle: true,
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Text(
                            error!,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.red,
                              fontSize: 14.sp,
                            ),
                          ),
                        )
                      : messages.isEmpty
                          ? Center(
                              child: Text(
                                "لا توجد رسائل",
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.grey,
                                  fontSize: 14.sp,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16.w),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isAdmin = message['is_admin'] == true;

                                return TicketMessageItem(
                                  message: message,
                                  isAdmin: isAdmin,
                                );
                              },
                            ),
            ),

            // Reply input field
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Send button
                  _isSending
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFF5951F)),
                        )
                      : Material(
                          color: const Color(0xFFF5951F),
                          borderRadius: BorderRadius.circular(50),
                          child: InkWell(
                            onTap: _sendReply,
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                  SizedBox(width: 12.w),

                  // Input field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: TextField(
                        controller: _replyController,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: "اكتب رسالتك هنا...",
                          hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: const Color(0xFF999999),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          border: InputBorder.none,
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
    );
  }
}
