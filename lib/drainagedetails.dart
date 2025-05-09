import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:my_project/home_screen.dart';
import 'package:my_project/web_view_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cross_file/cross_file.dart';

class Drainagedetails extends StatefulWidget {
  final String id;
  final String email;

  const Drainagedetails({super.key, required this.id, required this.email});

  @override
  State<Drainagedetails> createState() => _DrainagedetailsState();
}

class _DrainagedetailsState extends State<Drainagedetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> transactionData;
  bool isRefreshing = false;
  bool showShareOptions = false;
  bool isGeneratingPdf = false;
  Map<String, dynamic>? userData;
  String? pdfPath; // Para almacenar la ruta del PDF generado

  @override
  void initState() {
    super.initState();
    log(widget.id);
    transactionData = fetchTransactionDetails(widget.id);
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');
      if (userJson != null) {
        setState(() {
          userData = jsonDecode(userJson);
        });
      }
    } catch (e) {
      log("Error loading user data: $e");
    }
  }

  Future<Map<String, dynamic>> fetchTransactionDetails(String id) async {
    try {
      var dio = Dio();
      log('Fetching transaction details for ID: $id');

      var response = await dio.get(
        'https://ha55a.exchange/api/v1/history/get_by_id.php?exchange_id=$id',
      );

      if (response.statusCode == 200) {
        // Log the full response data
        log('Transaction details API Response: ${json.encode(response.data)}',
            name: 'TRANSACTION_DETAILS');

        // If you want to specifically examine the status value
        if (response.data != null && response.data is Map) {
          final status = response.data['status'];
          log('Transaction status: $status', name: 'TRANSACTION_DETAILS');
        }

        return response.data;
      } else {
        log('Transaction details API Error: Status code ${response.statusCode}',
            name: 'TRANSACTION_DETAILS');
        throw Exception("Failed to load data");
      }
    } catch (e) {
      log("Error fetching transaction details: $e",
          name: 'TRANSACTION_DETAILS');
      return {};
    }
  }

  Future<void> refreshData() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      var newData = await fetchTransactionDetails(widget.id);
      setState(() {
        transactionData = Future.value(newData);
      });
    } catch (e) {
      log("Refresh failed: $e");
    }

    setState(() {
      isRefreshing = false;
    });
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
      case 11: // مكتملة (نفس حالة 1)
        return const Color(0xff3DBD6C);
      case 2:
        return const Color(0xffF5951F);
      case 9:
        return const Color(0xffC81417);
      case 12:
        return const Color(
            0xff9C27B0); // Purple color for "under investigation"
      default:
        return const Color(0xff116F9A);
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
      case 11: // مكتملة (نفس حالة 1)
        return Icons.check_circle;
      case 2:
        return Icons.access_time;
      case 9:
        return Icons.cancel;
      case 12:
        return Icons.security; // Security icon for "under investigation"
      default:
        return Icons.replay;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
      case 11: // مكتملة (نفس حالة 1)
        return 'مكتملة';
      case 2:
        return 'قيد التنفيذ';
      case 9:
        return 'ملغيه';
      case 12:
        return 'تحت التحقيق';
      default:
        return 'استرداد';
    }
  }

  // Método para obtener fecha y hora formateadas
  String _getFormattedDateTimeFromString(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return 'غير متوفر';
    }

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final dateFormatter = intl.DateFormat('dd/MM/yyyy', 'ar');
      final timeFormatter = intl.DateFormat('hh:mm a',
          'ar'); // Changed from 'HH:mm' to 'hh:mm a' for 12-hour format with AM/PM

      final formattedDate = dateFormatter.format(dateTime);
      final formattedTime = timeFormatter.format(dateTime);

      return '$formattedDate | $formattedTime'; // Usar símbolo de barra vertical para mejor separación visual
    } catch (e) {
      // Si el parseo falla, intentar extraer manualmente
      final parts = dateTimeStr.split(' ');
      if (parts.length > 1) {
        // Si la hora tiene segundos, intentar acortarla
        String timeStr = parts[1];
        if (timeStr.split(':').length > 2) {
          // Acortar al formato HH:MM
          final timeParts = timeStr.split(':');
          timeStr = '${timeParts[0]}:${timeParts[1]}';
        }

        // Convert 24-hour time to 12-hour time with AM/PM
        try {
          // Extract hours and minutes
          final timeParts = timeStr.split(':');
          int hours = int.parse(timeParts[0]);
          final minutes = timeParts[1];

          // Determine if it's AM or PM
          final period = (hours >= 12) ? 'م' : 'ص'; // م for PM, ص for AM

          // Convert to 12-hour format
          if (hours > 12) {
            hours = hours - 12;
          } else if (hours == 0) {
            hours = 12;
          }

          // Format the time string in 12-hour format
          final formattedHours = hours.toString().padLeft(2, '0');
          return '${parts[0]} | $formattedHours:$minutes $period';
        } catch (e) {
          // If conversion fails, return the original 24-hour format
          return '${parts[0]} | $timeStr';
        }
      }
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Stack(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: transactionData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Lottie.asset(
                      'assets/lottie/loading.json',
                      height: 150,
                    ),
                  );
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return _buildErrorState();
                }

                final data = snapshot.data!;
                return Stack(
                  children: [
                    // Background gradient header
                    Container(
                      height: 220.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            const Color(0xFF38659B),
                            const Color(0xFF254672),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -30.h,
                            right: -20.w,
                            child: Container(
                              height: 120.h,
                              width: 120.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -40.h,
                            left: -20.w,
                            child: Container(
                              height: 140.h,
                              width: 140.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main content
                    SafeArea(
                      child: Column(
                        children: [
                          // App bar
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen(),
                                      ),
                                      (route) => false,
                                    ),
                                  ),
                                ),
                                Text(
                                  'تفاصيل الصرف',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                        ),
                                        onPressed:
                                            isRefreshing ? null : refreshData,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Transaction summary card
                          _buildTransactionSummaryCard(data),

                          SizedBox(height: 16.h),

                          // Tab bar - تم تحسين شكل التبويبات
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TabBar(
                              controller: _tabController,
                              dividerColor: Colors.transparent, // إزالة الخط
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF5951F),
                                    Color(0xFFE87B24),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(25.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF5951F,
                                    ).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey.shade600,
                              labelStyle: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              padding:
                                  EdgeInsets.zero, // إزالة الهوامش الداخلية
                              indicatorPadding:
                                  EdgeInsets.zero, // إزالة هوامش المؤشر
                              splashBorderRadius: BorderRadius.circular(25.r),
                              tabs: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(25.r),
                                      bottomRight: Radius.circular(25.r),
                                    ),
                                  ),
                                  child: Center(child: Text('تفاصيل الإرسال')),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(25.r),
                                      bottomLeft: Radius.circular(25.r),
                                    ),
                                  ),
                                  child: Center(child: Text('تفاصيل الاستلام')),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // Tab content
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildSendDetailsTab(data),
                                _buildReceiveDetailsTab(data),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Loading indicator overlay
                    if (isRefreshing)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Lottie.asset(
                              'assets/lottie/loading.json',
                              height: 80.h,
                              width: 80.w,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (isGeneratingPdf)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    width: 200.w,
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/lottie/loading.json',
                          height: 80.h,
                          width: 80.w,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'جاري إنشاء الإيصال...',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFF5951F),
          onPressed: () async {
            try {
              // Mostrar indicador de carga
              setState(() {
                isGeneratingPdf = true;
              });

              // Obtener datos de la transacción
              final data = await transactionData;

              // Generar y compartir PDF
              await _generateAndSharePdf(data);
            } catch (e) {
              setState(() {
                isGeneratingPdf = false;
              });

              // Mostrar mensaje de error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'حدث خطأ أثناء إنشاء الإيصال. حاول مرة أخرى.',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const ImageIcon(
            AssetImage('assets/images/download-icon.png'),
            color: Colors.white,
          ),
          label: Text(
            'تنزيل الإيصال',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
          Text(
            "فشل في جلب البيانات",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5951F),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: refreshData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              'إعادة المحاولة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSummaryCard(Map<String, dynamic> data) {
    final int statusValue =
        int.tryParse(data['status']?.toString() ?? '0') ?? 0;
    final String adminFeedback = data['admin_feedback']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Transaction header with ID and status
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 16.sp,
                          color: Colors.grey.shade700,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'رقم الطلب: ${data['exchange_id']}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _getFormattedDateTimeFromString(
                              data['created_at'] ?? data['date']),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(statusValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(statusValue),
                        size: 14.sp,
                        color: _getStatusColor(statusValue),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _getStatusText(statusValue),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(statusValue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Admin Feedback (Only shown for canceled or under investigation status)
          if ((statusValue == 9 ||
                  statusValue == 12 ||
                  (statusValue != 1 &&
                      statusValue != 2 &&
                      statusValue != 11)) &&
              adminFeedback.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: (statusValue == 9
                      ? Colors.red.shade50
                      : statusValue == 12
                          ? Colors.purple.shade50
                          : Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: (statusValue == 9
                        ? Colors.red.shade200
                        : statusValue == 12
                            ? Colors.purple.shade200
                            : Colors.blue.shade200),
                    width: 1.w,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          statusValue == 9
                              ? Icons.error_outline
                              : statusValue == 12
                                  ? Icons.security
                                  : Icons.replay,
                          size: 16.sp,
                          color: statusValue == 9
                              ? Colors.red.shade700
                              : statusValue == 12
                                  ? Colors.purple.shade700
                                  : Colors.blue.shade700,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          statusValue == 9
                              ? 'سبب الإلغاء:'
                              : statusValue == 12
                                  ? 'سبب التحقيق:'
                                  : 'سبب الاسترداد:',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: statusValue == 9
                                ? Colors.red.shade700
                                : statusValue == 12
                                    ? Colors.purple.shade700
                                    : Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      adminFeedback,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Transaction timeline
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: _buildTimelineProgress(statusValue),
          ),

          // Transaction summary
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: Image.network(
                              data['send_currency_image'] ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.account_balance_wallet,
                                size: 20.sp,
                                color: const Color(0xFF38659B),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'إرسال',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          data['sending_amount']?.substring(
                                0,
                                data['sending_amount'].length > 8
                                    ? 8
                                    : data['sending_amount'].length,
                              ) ??
                              '0',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          data['send_currency_symbol'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: const Color(0xFF38659B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5951F).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: const Color(0xFFF5951F),
                      size: 20.sp,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: Image.network(
                              data['receive_currency_image'] ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.account_balance_wallet,
                                size: 20.sp,
                                color: const Color(0xFF38659B),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'المبلغ المستحق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          // حساب المبلغ المستحق للمستخدم (المبلغ المستلم - التكلفة)
                          _formatAmount(((double.tryParse(
                                          data['receiving_amount'] ?? '0') ??
                                      0) -
                                  (double.tryParse(
                                          data['receiving_charge'] ?? '0') ??
                                      0))
                              .toString()),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          data['receive_currency_symbol'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: const Color(0xFF38659B),
                          ),
                        ),
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

  Widget _buildTimelineProgress(int status) {
    // 1 and 11 = مكتملة, 2 = قيد التنفيذ, 9 = مغلقة, 12 = تحت التحقيق, other = استرداد
    final bool isOrderPlaced = true; // Always true once we have order details
    final bool isUnderInvestigation = status == 12;
    // For status 12 (under investigation), the order is not yet in processing stage
    final bool isProcessing =
        (status == 2 || status == 1 || status == 11) && !isUnderInvestigation;
    final bool isCompleted =
        status == 1 || status == 11; // Status 11 is also considered completed
    final bool isCancelled = status == 9;
    final bool isRefunded = status != 1 &&
        status != 2 &&
        status != 9 &&
        status != 12 &&
        status != 11;

    return Row(
      children: [
        // First step: Order placed (always active)
        _buildTimelineStep(
            1,
            isOrderPlaced,
            isUnderInvestigation ? 'قيد التحقيق' : 'تم الطلب',
            isUnderInvestigation ? 'تحت المراجعة' : 'استلام الطلب'),

        // Line connecting first and second step
        _buildTimelineLine(isProcessing),

        // Second step: Processing
        _buildTimelineStep(2, isProcessing, 'قيد التنفيذ', 'معالجة الطلب'),

        // Line connecting second and third step
        _buildTimelineLine(isCompleted || isCancelled || isRefunded),

        // Third step: Completion/Cancellation/Refund
        _buildTimelineStep(
          3,
          isCompleted || isCancelled || isRefunded,
          isCancelled
              ? 'تم الإلغاء'
              : isRefunded
                  ? 'تم الاسترداد'
                  : 'تم الإكمال',
          'إنهاء العملية',
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    int step,
    bool isActive,
    String title,
    String subtitle,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF38659B) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                step == 1
                    ? Icons.receipt_outlined
                    : step == 2
                        ? Icons.sync
                        : Icons.check,
                color: Colors.white,
                size: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.grey.shade800 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10.sp,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isActive) {
    return Container(
      width: 30.w,
      height: 2.h,
      color: isActive ? const Color(0xFF38659B) : Colors.grey.shade300,
    );
  }

  Widget _buildSendDetailsTab(Map<String, dynamic> data) {
    final int statusValue =
        int.tryParse(data['status']?.toString() ?? '0') ?? 0;
    final String adminFeedback = data['admin_feedback']?.toString() ?? '';
    final bool showFeedback = (statusValue == 9 ||
            statusValue == 12 ||
            (statusValue != 1 && statusValue != 2 && statusValue != 11)) &&
        adminFeedback.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            'الطريقة',
            data['send_currency_name'] ?? 'غير متوفر',
            icon: Icons.payment,
            imagePath: data['send_currency_image'],
          ),
          _buildDetailCard(
            'العملة',
            data['send_currency_symbol'] ?? 'غير متوفر',
            icon: Icons.monetization_on,
          ),
          _buildDetailCard(
            'المبلغ',
            '${data['sending_amount']?.substring(0, data['sending_amount'].length > 8 ? 8 : data['sending_amount'].length) ?? '0'} ${data['send_currency_symbol'] ?? ''}',
            icon: Icons.attach_money,
          ),
          _buildDetailCard(
            'التكلفة',
            '${data['sending_charge']?.substring(0, data['sending_charge'].length > 8 ? 8 : data['sending_charge'].length) ?? '0'} ${data['send_currency_symbol'] ?? ''}',
            icon: Icons.account_balance_wallet,
            isError: true,
          ),
          _buildDetailCard(
            'الإجمالي',
            '${(double.tryParse(data['sending_amount'] ?? '0') ?? 0) + (double.tryParse(data['sending_charge'] ?? '0') ?? 0)} ${data['send_currency_symbol'] ?? ''}',
            icon: Icons.calculate,
            highlight: true,
          ),
          if (data['sender_info'] != null)
            _buildDetailCard(
              'معلومات المرسل',
              data['sender_info'] ?? 'غير متوفر',
              icon: Icons.person,
            ),
          SizedBox(height: 70.h), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildReceiveDetailsTab(Map<String, dynamic> data) {
    // Calculate the net amount (receiving_amount - receiving_charge)
    double receivingAmount =
        double.tryParse(data['receiving_amount'] ?? '0') ?? 0;
    double receivingCharge =
        double.tryParse(data['receiving_charge'] ?? '0') ?? 0;
    double netAmount = receivingAmount - receivingCharge;

    final int statusValue =
        int.tryParse(data['status']?.toString() ?? '0') ?? 0;
    final String adminFeedback = data['admin_feedback']?.toString() ?? '';
    final bool showFeedback = (statusValue == 9 ||
            statusValue == 12 ||
            (statusValue != 1 && statusValue != 2 && statusValue != 11)) &&
        adminFeedback.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            'الطريقة',
            data['receive_currency_name'] ?? 'غير متوفر',
            icon: Icons.payment,
            imagePath: data['receive_currency_image'],
          ),
          _buildDetailCard(
            'العملة',
            data['receive_currency_symbol'] ?? 'غير متوفر',
            icon: Icons.monetization_on,
          ),
          _buildDetailCard(
            'المبلغ',
            '${data['receiving_amount']?.substring(0, data['receiving_amount'].length > 8 ? 8 : data['receiving_amount'].length) ?? '0'} ${data['receive_currency_symbol'] ?? ''}',
            icon: Icons.attach_money,
          ),
          _buildDetailCard(
            'التكلفة',
            '${data['receiving_charge']?.substring(0, data['receiving_charge'].length > 8 ? 8 : data['receiving_charge'].length) ?? '0'} ${data['receive_currency_symbol'] ?? ''}',
            icon: Icons.account_balance_wallet,
            isError: true,
          ),
          // بطاقة جديدة: المبلغ المستحق للمستخدم
          _buildDetailCard(
            'المبلغ المستحق للمستخدم',
            '${_formatAmount(netAmount.toString())} ${data['receive_currency_symbol'] ?? ''}',
            icon: Icons.payments_outlined,
            highlight: true,
          ),
          if (data['receiver_info'] != null)
            _buildDetailCard(
              'معلومات المستلم',
              data['receiver_info'] ?? 'غير متوفر',
              icon: Icons.person,
            ),
          SizedBox(height: 70.h), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    String value, {
    IconData? icon,
    String? imagePath,
    bool highlight = false,
    bool isError = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38659B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon ?? Icons.info_outline,
                      size: 16.sp,
                      color: const Color(0xFF38659B),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(right: 44.w, top: 12.h),
              child: Row(
                children: [
                  if (imagePath != null) ...[
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.w,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image,
                            size: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                  ],
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isError
                            ? Colors.red.shade700
                            : highlight
                                ? const Color(0xFFF5951F)
                                : Colors.grey.shade900,
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

  Widget _buildShareOptions() {
    return Container();
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container();
  }

  Future<void> _generateAndSharePdf(Map<String, dynamic> data) async {
    try {
      setState(() {
        isGeneratingPdf = true;
        pdfPath = null; // Resetear la ruta del PDF
      });

      final pdf = pw.Document();

      // Cargar fuentes árabes
      final arabicFont =
          await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      final arabicFontBold =
          await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
      final ttf = pw.Font.ttf(arabicFont);
      final ttfBold = pw.Font.ttf(arabicFontBold);

      // Cargar el logo
      Uint8List? logoBytes;
      try {
        logoBytes = (await rootBundle.load('assets/images/logo.png'))
            .buffer
            .asUint8List();
      } catch (e) {
        log("Error loading logo: $e");
      }

      // Get transaction status and admin feedback
      final int statusValue =
          int.tryParse(data['status']?.toString() ?? '0') ?? 0;
      final String adminFeedback = data['admin_feedback']?.toString() ?? '';

      // Formato de fecha
      String formattedDate = 'N/A';
      String formattedTime = 'N/A'; // Nueva variable para la hora
      if (data['created_at'] != null) {
        try {
          final dateTimeStr = data['created_at'].toString();
          final dateTimeParts = dateTimeStr.split(' ');

          // Procesar la fecha
          final date = DateTime.parse(dateTimeStr);
          final dateFormatter = intl.DateFormat('dd/MM/yyyy');
          formattedDate = dateFormatter.format(date);

          // Procesar la hora
          final timeFormatter =
              intl.DateFormat('hh:mm a'); // Changed from 'HH:mm' to 'hh:mm a'
          formattedTime = timeFormatter.format(date);

          log("🔍 Fecha y hora extraídas: Fecha=$formattedDate, Hora=$formattedTime");
        } catch (e) {
          formattedDate = data['created_at'].toString().split(' ')[0];
          // Intentar extraer la hora si está disponible en el formato string
          final parts = data['created_at'].toString().split(' ');
          if (parts.length > 1) {
            // Convert 24-hour time to 12-hour format with AM/PM
            try {
              String timeStr = parts[1];
              if (timeStr.split(':').length > 2) {
                final timeParts = timeStr.split(':');
                timeStr = '${timeParts[0]}:${timeParts[1]}';
              }

              final timeParts = timeStr.split(':');
              int hours = int.parse(timeParts[0]);
              final minutes = timeParts[1];

              final period = (hours >= 12) ? 'م' : 'ص'; // م for PM, ص for AM

              if (hours > 12) {
                hours = hours - 12;
              } else if (hours == 0) {
                hours = 12;
              }

              final formattedHours = hours.toString().padLeft(2, '0');
              formattedTime = '$formattedHours:$minutes $period';
            } catch (e) {
              // If conversion fails, use original time
              formattedTime = parts[1];
            }
          }
          log("🔍 Error al parsear la fecha completa: $e");
        }
      } else if (data['date'] != null) {
        try {
          final dateTimeStr = data['date'].toString();
          final dateTimeParts = dateTimeStr.split(' ');

          // Procesar la fecha
          final date = DateTime.parse(dateTimeStr);
          final dateFormatter = intl.DateFormat('dd/MM/yyyy');
          formattedDate = dateFormatter.format(date);

          // Procesar la hora
          final timeFormatter =
              intl.DateFormat('hh:mm a'); // Changed from 'HH:mm' to 'hh:mm a'
          formattedTime = timeFormatter.format(date);
        } catch (e) {
          formattedDate = data['date'].toString().split(' ')[0];
          // Intentar extraer la hora si está disponible en el formato string
          final parts = data['date'].toString().split(' ');
          if (parts.length > 1) {
            // Convert 24-hour time to 12-hour format with AM/PM
            try {
              String timeStr = parts[1];
              if (timeStr.split(':').length > 2) {
                final timeParts = timeStr.split(':');
                timeStr = '${timeParts[0]}:${timeParts[1]}';
              }

              final timeParts = timeStr.split(':');
              int hours = int.parse(timeParts[0]);
              final minutes = timeParts[1];

              final period = (hours >= 12) ? 'م' : 'ص'; // م for PM, ص for AM

              if (hours > 12) {
                hours = hours - 12;
              } else if (hours == 0) {
                hours = 12;
              }

              final formattedHours = hours.toString().padLeft(2, '0');
              formattedTime = '$formattedHours:$minutes $period';
            } catch (e) {
              // If conversion fails, use original time
              formattedTime = parts[1];
            }
          }
        }
      }

      // Mejorar la carga de datos de usuario
      log("UserData Debug: ${userData.toString()}");
      // Construir el nombre completo a partir de los componentes
      final String firstName = userData?['firstname'] ?? '';
      final String secondName = userData?['secondname'] ?? '';
      final String lastName = userData?['lastname'] ?? '';
      final String userName = [firstName, secondName, lastName]
          .where((part) => part.isNotEmpty)
          .join(' ');

      final String userEmail = userData?['email'] ?? 'غير متوفر';
      // Usar mobile en lugar de phone
      final String userPhone = userData?['mobile'] ?? 'غير متوفر';

      // Dividir la dirección en componentes
      String userAddress = '';
      String userCity = '';
      String userPostalCode = '';
      String userState = '';
      String userCountry = '';

      // Verificar si la dirección está como un objeto JSON en un string
      if (userData?['address'] != null) {
        String addressStr = userData!['address'].toString();
        if (addressStr.contains('{') || addressStr.contains('(')) {
          try {
            // Intentar limpiar y parsear el string como JSON
            addressStr = addressStr.replaceAll('(', '{').replaceAll(')', '}');
            if (!addressStr.startsWith('{')) {
              addressStr = '{' + addressStr + '}';
            }

            // Intentar parsear como JSON
            Map<String, dynamic> addressMap = {};
            try {
              addressMap = jsonDecode(addressStr);
            } catch (e) {
              // Si falla, intentar extraer con regex
              final regex = RegExp(r'"(\w+)":"([^"]+)"');
              final matches = regex.allMatches(addressStr);
              for (final match in matches) {
                if (match.groupCount >= 2) {
                  String key = match.group(1) ?? '';
                  String value = match.group(2) ?? '';
                  addressMap[key] = value;
                }
              }
            }

            // Asignar valores
            userAddress = addressMap['address'] ?? '';
            userCity = addressMap['city'] ?? '';
            userPostalCode = addressMap['zip'] ??
                addressMap['postal_code'] ??
                addressMap['zip_code'] ??
                '';
            userState = addressMap['state'] ?? '';
            userCountry = addressMap['country'] ?? '';

            log("Address parsed successfully: $addressMap");
          } catch (e) {
            log("Error parsing address JSON: $e");
            userAddress = userData!['address'].toString();
          }
        } else {
          userAddress = addressStr;
        }
      }

      // Usar valores alternativos si están disponibles directamente
      userAddress = userAddress.isNotEmpty
          ? userAddress
          : (userData?['street_address'] ?? '');
      userCity = userCity.isNotEmpty ? userCity : (userData?['city'] ?? '');
      userPostalCode = userPostalCode.isNotEmpty
          ? userPostalCode
          : (userData?['postal_code'] ?? userData?['zip_code'] ?? '');
      userState = userState.isNotEmpty ? userState : (userData?['state'] ?? '');
      userCountry =
          userCountry.isNotEmpty ? userCountry : (userData?['country'] ?? '');

      // Verificar si hay dirección disponible
      final bool hasAddress = [
        userAddress,
        userCity,
        userPostalCode,
        userState,
        userCountry
      ].any((s) => s.isNotEmpty);
      final String addressFallback = !hasAddress ? 'غير متوفر' : '';

      // Construir PDF más compacto (una sola página)
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Encabezado con logo
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColor(0.22, 0.30, 0.47),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (logoBytes != null)
                        pw.Container(
                          height: 40,
                          width: 40,
                          child: pw.Image(pw.MemoryImage(logoBytes)),
                        ),
                      pw.Text(
                        'إيصال معاملة هسه',
                        style: pw.TextStyle(
                          font: ttfBold,
                          color: PdfColor(1, 1, 1),
                          fontSize: 14,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 5),

                // Información del recibo y usuario (2 columnas)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Columna 1: Info de la transacción
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border:
                              pw.Border.all(color: PdfColor(0.86, 0.87, 0.87)),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'معلومات الطلب',
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 10,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.Divider(height: 5),
                            _buildCompactPdfRow(ttf, ttfBold, ':رقم الطلب',
                                data['exchange_id']?.toString() ?? 'N/A'),
                            _buildCompactPdfRow(
                                ttf, ttfBold, ':التاريخ', formattedDate),
                            _buildCompactPdfRow(
                                ttf, ttfBold, ':الوقت', formattedTime),
                            _buildCompactPdfRow(
                                ttf,
                                ttfBold,
                                ':الحالة',
                                _getStatusText(int.tryParse(
                                        data['status']?.toString() ?? '0') ??
                                    0)),
                          ],
                        ),
                      ),
                    ),

                    pw.SizedBox(width: 5),

                    // Columna 2: Info del usuario
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border:
                              pw.Border.all(color: PdfColor(0.86, 0.87, 0.87)),
                          borderRadius: pw.BorderRadius.circular(5),
                          color: PdfColor(0.97, 0.97, 0.97),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'معلومات المستخدم',
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 10,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.Divider(height: 5),
                            _buildCompactPdfRow(
                                ttf, ttfBold, ':الاسم', userName),
                            _buildCompactPdfRow(
                                ttf, ttfBold, ':البريد الإلكتروني', userEmail),
                            _buildCompactPdfRow(
                                ttf, ttfBold, ':رقم الهاتف', userPhone),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Dirección (dividida)
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor(0.86, 0.87, 0.87)),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'العنوان',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 10,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Divider(height: 5),
                      _buildCompactPdfRow(
                          ttf,
                          ttfBold,
                          ':العنوان',
                          userAddress.isNotEmpty
                              ? userAddress
                              : addressFallback),
                      _buildCompactPdfRow(ttf, ttfBold, ':المدينة',
                          userCity.isNotEmpty ? userCity : addressFallback),
                      _buildCompactPdfRow(ttf, ttfBold, ':المنطقة',
                          userState.isNotEmpty ? userState : addressFallback),
                      _buildCompactPdfRow(
                          ttf,
                          ttfBold,
                          ':الرمز البريدي',
                          userPostalCode.isNotEmpty
                              ? userPostalCode
                              : addressFallback),
                      _buildCompactPdfRow(
                          ttf,
                          ttfBold,
                          ':الدولة',
                          userCountry.isNotEmpty
                              ? userCountry
                              : addressFallback),
                    ],
                  ),
                ),

                // Información de la transacción
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor(0.86, 0.87, 0.87)),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'تفاصيل التحويل',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 10,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Divider(height: 5),
                      pw.Row(
                        children: [
                          // Columna de recepción (a la izquierda)
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'المبلغ المستحق',
                                  style:
                                      pw.TextStyle(font: ttfBold, fontSize: 9),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  _formatAmount(((double.tryParse(
                                                  data['receiving_amount'] ??
                                                      '0') ??
                                              0) -
                                          (double.tryParse(
                                                  data['receiving_charge'] ??
                                                      '0') ??
                                              0))
                                      .toString()),
                                  style:
                                      pw.TextStyle(font: ttfBold, fontSize: 11),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.Text(
                                  data['receive_currency_symbol']?.toString() ??
                                      '',
                                  style: pw.TextStyle(font: ttf, fontSize: 9),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),

                          // Columna de envío (a la derecha)
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'إرسال',
                                  style:
                                      pw.TextStyle(font: ttfBold, fontSize: 9),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  _formatAmount(
                                      data['sending_amount']?.toString() ??
                                          '0'),
                                  style:
                                      pw.TextStyle(font: ttfBold, fontSize: 11),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                                pw.Text(
                                  data['send_currency_symbol']?.toString() ??
                                      '',
                                  style: pw.TextStyle(font: ttf, fontSize: 9),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Admin Feedback if status is canceled or under investigation
                if ((statusValue == 9 ||
                        statusValue == 12 ||
                        (statusValue != 1 &&
                            statusValue != 2 &&
                            statusValue != 11)) &&
                    adminFeedback.isNotEmpty)
                  pw.SizedBox(height: 5),
                if ((statusValue == 9 ||
                        statusValue == 12 ||
                        (statusValue != 1 &&
                            statusValue != 2 &&
                            statusValue != 11)) &&
                    adminFeedback.isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: statusValue == 9
                            ? PdfColor(0.9, 0.3, 0.3) // Red for canceled
                            : statusValue == 12
                                ? PdfColor(
                                    0.6, 0.2, 0.6) // Purple for investigation
                                : PdfColor(0.2, 0.4, 0.8), // Blue for refund
                      ),
                      borderRadius: pw.BorderRadius.circular(5),
                      color: statusValue == 9
                          ? PdfColor(1.0, 0.9, 0.9) // Light red background
                          : statusValue == 12
                              ? PdfColor(
                                  0.97, 0.9, 0.97) // Light purple background
                              : PdfColor(
                                  0.9, 0.95, 1.0), // Light blue background
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          statusValue == 9
                              ? 'سبب الإلغاء'
                              : statusValue == 12
                                  ? 'سبب التحقيق'
                                  : 'سبب الاسترداد',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 10,
                            color: statusValue == 9
                                ? PdfColor(0.8, 0.2, 0.2) // Dark red
                                : statusValue == 12
                                    ? PdfColor(0.6, 0.2, 0.6) // Dark purple
                                    : PdfColor(0.1, 0.3, 0.7), // Dark blue
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Divider(height: 5),
                        pw.Text(
                          adminFeedback,
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 9,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),

                // Detalles compactos: envío y recepción
                pw.SizedBox(height: 5),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Detalles de recepción (a la izquierda)
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border:
                              pw.Border.all(color: PdfColor(0.86, 0.87, 0.87)),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'تفاصيل الاستلام',
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 10,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.Divider(height: 5),
                            _buildCompactPdfRow(ttf, ttfBold, ':الطريقة',
                                data['receive_currency_name'] ?? 'غير متوفر'),
                            _buildCompactPdfRow(ttf, ttfBold, ':العملة',
                                data['receive_currency_symbol'] ?? 'غير متوفر'),
                            _buildCompactPdfRow(ttf, ttfBold, ':المبلغ',
                                '${_formatAmount(data['receiving_amount'] ?? '0')} ${data['receive_currency_symbol'] ?? ''}'),
                            _buildCompactPdfRow(ttf, ttfBold, ':التكلفة',
                                '${_formatAmount(data['receiving_charge'] ?? '0')} ${data['receive_currency_symbol'] ?? ''}'),
                            _buildCompactPdfRow(
                                ttf,
                                ttfBold,
                                ':المبلغ المستحق للمستخدم',
                                '${_formatAmount(((double.tryParse(data['receiving_amount'] ?? '0') ?? 0) - (double.tryParse(data['receiving_charge'] ?? '0') ?? 0)).toString())} ${data['receive_currency_symbol'] ?? ''}'),
                            if (data['receiver_info'] != null)
                              _buildCompactPdfRow(
                                  ttf,
                                  ttfBold,
                                  ':معلومات المستلم',
                                  data['receiver_info'] ?? 'غير متوفر'),
                          ],
                        ),
                      ),
                    ),

                    pw.SizedBox(width: 5),

                    // Detalles de envío (a la derecha)
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border:
                              pw.Border.all(color: PdfColor(0.86, 0.87, 0.87)),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'تفاصيل الإرسال',
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 10,
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                            pw.Divider(height: 5),
                            _buildCompactPdfRow(ttf, ttfBold, ':الطريقة',
                                data['send_currency_name'] ?? 'غير متوفر'),
                            _buildCompactPdfRow(ttf, ttfBold, ':العملة',
                                data['send_currency_symbol'] ?? 'غير متوفر'),
                            _buildCompactPdfRow(ttf, ttfBold, ':المبلغ',
                                '${_formatAmount(data['sending_amount'] ?? '0')} ${data['send_currency_symbol'] ?? ''}'),
                            _buildCompactPdfRow(ttf, ttfBold, ':التكلفة',
                                '${_formatAmount(data['sending_charge'] ?? '0')} ${data['send_currency_symbol'] ?? ''}'),
                            if (data['sender_info'] != null)
                              _buildCompactPdfRow(
                                  ttf,
                                  ttfBold,
                                  ':معلومات المرسل',
                                  data['sender_info'] ?? 'غير متوفر'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Pie de página
                pw.Spacer(),
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'شكراً لاستخدامك هسه للتحويلات المالية',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 9,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'تم إنشاء هذا الإيصال بتاريخ ${DateTime.now().toString().split(' ')[0]}',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 8,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Guardar el PDF
      Directory? dir;
      try {
        if (Platform.isIOS) {
          dir = await getApplicationDocumentsDirectory();
        } else {
          dir = await getTemporaryDirectory();
        }

        String fileName =
            'receipt_${data['exchange_id'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(await pdf.save());

        log("PDF guardado en: ${file.path}");

        // Guardar la ruta del PDF en el estado
        setState(() {
          pdfPath = file.path;
          isGeneratingPdf = false;
        });

        // Mostrar vista previa del PDF
        _showPdfPreview(context, file, data);
      } catch (e) {
        setState(() {
          isGeneratingPdf = false;
        });
        log("Error saving PDF: $e");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء حفظ الإيصال. حاول مرة أخرى. $e',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isGeneratingPdf = false;
      });
      log("Error generating PDF: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء إنشاء الإيصال. حاول مرة أخرى. $e',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPdfPreview(
      BuildContext context, File pdfFile, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "معاينة الإيصال",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              Divider(),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 400.h,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "تم إنشاء الإيصال بنجاح!",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: pdfFile.existsSync()
                        ? FutureBuilder<Uint8List>(
                            future: pdfFile.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFFF5951F),
                                  ),
                                );
                              }

                              if (snapshot.hasError || !snapshot.hasData) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 50.sp,
                                        color: Colors.red.shade400,
                                      ),
                                      SizedBox(height: 10.h),
                                      Text(
                                        "خطأ في تحميل الملف: ${snapshot.error}",
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 14.sp,
                                          color: Colors.grey.shade700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Mostrar una imagen representativa del PDF
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.picture_as_pdf,
                                        size: 80.sp,
                                        color: const Color(0xFFF5951F),
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        "تم إنشاء الإيصال بنجاح!",
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        "حجم الملف: ${_formatFileSize(snapshot.data!.length)}",
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 14.sp,
                                          color: Colors.grey.shade700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 50.sp,
                                  color: Colors.red.shade400,
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  "لم يتم العثور على الملف",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade700,
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
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First row with Close button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        alignment: Alignment.center,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close,
                          color: Colors.grey.shade700, size: 18.r),
                      label: Text(
                        "إغلاق",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38659B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      onPressed: () async {
                        try {
                          // Save file to downloads directory
                          await _saveFileToDownloads(pdfFile, data);
                          Navigator.pop(context);
                        } catch (e) {
                          log("Error saving file: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'حدث خطأ أثناء حفظ الملف: $e',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14.sp,
                                ),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.file_download_outlined,
                              color: Colors.white, size: 18.r),
                          SizedBox(width: 8.w),
                          Text(
                            "حفظ على الجهاز",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Share button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5951F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        // Compartir el PDF
                        try {
                          final box = context.findRenderObject() as RenderBox?;
                          if (Platform.isIOS) {
                            await Share.share(
                              'إيصال معاملة هسه رقم ${data["exchange_id"]}',
                              subject: 'إيصال معاملة هسه',
                            );
                          } else {
                            await Share.shareXFiles(
                              [XFile(pdfFile.path)],
                              text:
                                  'إيصال معاملة هسه رقم ${data['exchange_id']}',
                              subject: 'إيصال معاملة هسه',
                              sharePositionOrigin: box != null
                                  ? box.localToGlobal(Offset.zero) & box.size
                                  : null,
                            );
                          }
                        } catch (e) {
                          log("Error al compartir: $e");
                          // Alternativa si el método anterior falla
                          try {
                            await Share.share(
                              'إيصال معاملة هسه رقم ${data["exchange_id"]}',
                              subject: 'إيصال معاملة هسه',
                            );
                          } catch (e) {
                            log("Error al usar método alternativo: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'لا يمكن مشاركة الملف. يرجى التحقق من الصلاحيات.',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.sp,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share, color: Colors.white, size: 18.r),
                          SizedBox(width: 8.w),
                          Text(
                            "مشاركة الإيصال",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Add this new method to save the file to downloads
  Future<void> _saveFileToDownloads(
      File pdfFile, Map<String, dynamic> data) async {
    try {
      String fileName =
          'receipt_${data['exchange_id'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isAndroid) {
        // For Android, save to Downloads directory
        Directory? downloadsDir;
        // First try to get the Downloads directory
        try {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            // Use fallback: get external storage directory
            downloadsDir = await getExternalStorageDirectory();
          }
        } catch (e) {
          // If not accessible, use app's documents directory
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        if (downloadsDir != null) {
          final savedFile = File('${downloadsDir.path}/$fileName');
          await pdfFile.copy(savedFile.path);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم حفظ الإيصال بنجاح في مجلد التنزيلات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                ),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'موافق',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        } else {
          throw Exception('لم يتم العثور على مجلد التنزيلات');
        }
      } else if (Platform.isIOS) {
        // For iOS, save to Documents directory
        final docsDir = await getApplicationDocumentsDirectory();
        final savedFile = File('${docsDir.path}/$fileName');
        await pdfFile.copy(savedFile.path);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ الإيصال بنجاح في مجلد الملفات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
              ),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'موافق',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      log("Error in _saveFileToDownloads: $e");
      // Re-throw to handle in the caller
      throw e;
    }
  }

  pw.Widget _buildCompactPdfRow(
      pw.Font font, pw.Font boldFont, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 8,
              ),
              textAlign: pw.TextAlign.right,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(width: 3),
          pw.Text(
            label,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 8,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  String _formatAmount(String amount) {
    try {
      // Intentar convertir a double para manipular el número
      double numAmount = double.parse(amount);

      // Si es un número entero (sin decimales significativos), mostrar sin decimales
      if (numAmount == numAmount.roundToDouble()) {
        return numAmount.toInt().toString();
      }

      // Si tiene decimales, mostrar máximo 2 decimales
      return numAmount.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    } catch (e) {
      // Si hay error en la conversión, intentar con método de strings
      if (amount.contains('.')) {
        List<String> parts = amount.split('.');
        // Quitar ceros no significativos
        if (parts.length > 1) {
          String decimals = parts[1].replaceAll(RegExp(r'0+$'), '');
          if (decimals.isEmpty) {
            return parts[0]; // Sin decimales
          } else if (decimals.length > 2) {
            decimals = decimals.substring(0, 2); // Máximo 2 decimales
          }
          return parts[0] + '.' + decimals;
        }
      }
      return amount;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // Add new method to build feedback card
  Widget _buildFeedbackCard(int statusValue, String adminFeedback) {
    // Determine if transaction is refunded
    bool isRefunded = statusValue != 1 &&
        statusValue != 2 &&
        statusValue != 9 &&
        statusValue != 11 &&
        statusValue != 12;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: statusValue == 9
            ? Colors.red.shade50
            : isRefunded
                ? Colors.blue.shade50
                : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: statusValue == 9
              ? Colors.red.shade200
              : isRefunded
                  ? Colors.blue.shade200
                  : Colors.purple.shade200,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: (statusValue == 9
                            ? Colors.red.shade700
                            : isRefunded
                                ? Colors.blue.shade700
                                : Colors.purple.shade700)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      statusValue == 9
                          ? Icons.error_outline
                          : isRefunded
                              ? Icons.replay
                              : Icons.security,
                      size: 16.sp,
                      color: statusValue == 9
                          ? Colors.red.shade700
                          : isRefunded
                              ? Colors.blue.shade700
                              : Colors.purple.shade700,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  statusValue == 9
                      ? 'سبب الإلغاء'
                      : isRefunded
                          ? 'سبب الاسترداد'
                          : 'سبب التحقيق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: statusValue == 9
                        ? Colors.red.shade700
                        : isRefunded
                            ? Colors.blue.shade700
                            : Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(right: 44.w, top: 12.h),
              child: Text(
                adminFeedback,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
