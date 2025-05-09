import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:my_project/drainagedetails.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  int selectedTab = 0;
  late Future<List<dynamic>> transactionsFuture;
  final TextEditingController _orderController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<dynamic> transactions = [];
  late TabController _tabController;
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      setState(() {
        selectedTab = _tabController.index;
      });
    });
    transactionsFuture = fetchTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    Map<String, dynamic> userData = jsonDecode(userJson!);
    return userData['id'].toString();
  }

  Future<List<dynamic>> fetchTransactions() async {
    String userId = await getUserId();
    try {
      var dio = Dio();
      var response = await dio
          .get('https://ha55a.exchange/api/v1/history/get.php?user_id=$userId');

      if (response.statusCode == 200) {
        developer.log('API Response: ${json.encode(response.data)}',
            name: 'TRANSACTIONS');

        // Log statuses to check if status 12 is present
        if (response.data is List) {
          final List<dynamic> transactions = response.data;
          final Map<String, int> statusCounts = {};

          for (var transaction in transactions) {
            final status = transaction['status']?.toString() ?? 'unknown';
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }

          developer.log('Transaction status counts: $statusCounts',
              name: 'TRANSACTIONS_DEBUG');
        }

        setState(() {
          transactions = response.data;
        });
        return response.data;
      } else {
        developer.log('API Error: Status code ${response.statusCode}',
            name: 'TRANSACTIONS');
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      developer.log('API Exception: $e', name: 'TRANSACTIONS');
      return [];
    }
  }

  Future<void> _refreshTransactions() async {
    setState(() {
      transactionsFuture = fetchTransactions();
    });
  }

  void _trackOrder() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');
      String email = jsonDecode(userJson!)['email'];

      String exchangeIdInput = _orderController.text.trim();

      // البحث عن المعاملة التي تملك نفس exchange_id
      dynamic foundTransaction;
      for (var transaction in transactions) {
        if (transaction['exchange_id'].toString() == exchangeIdInput) {
          foundTransaction = transaction;
          break;
        }
      }

      if (foundTransaction != null) {
        // استخدام الـ id المرتبط بـ exchange_id
        String actualId = foundTransaction['id'].toString();

        developer.log(
            'Found transaction with exchange_id: $exchangeIdInput, actual id: $actualId',
            name: 'TRANSACTION_TRACK');

        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => Drainagedetails(
              id: actualId,
              email: email,
            ),
          ),
        );
      } else {
        _showErrorPopup("الكود تالف أو ليس لديك صلاحيات الوصول إليه");
      }
    }
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline,
                  color: Colors.red.shade600, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                "خطأ",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.sp,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFF5951F),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 12.h,
                  ),
                ),
                child: Text(
                  "حسناً",
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
      ),
    );
  }

  String formatAmount(String amount) {
    double value = double.parse(amount);
    return value.toStringAsFixed(0);
  }

  int _getStatusFromTab(int tab) {
    switch (tab) {
      case 0:
        return 0; // All (represented by 0, but not used for filtering)
      case 1:
        return 1; // Completed
      case 2:
        return 2; // Pending
      case 3:
        return 3; // Returned
      case 4:
        return 9; // Canceled
      case 5:
        return 12; // Under Investigation
      default:
        return 0;
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
      case 11:
        return Colors.green.shade600;
      case 2:
        return Colors.amber.shade600;
      case 3:
        return Colors.blue.shade600;
      case 9:
        return Colors.red.shade600;
      case 12:
        return Colors.purple.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
      case 11:
        return 'مكتملة';
      case 2:
        return 'معلقة';
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 10:
        // Any status that's not 1, 2, 9, 11, or 12 is considered "refunded"
        return 'استرداد';
      case 9:
        return 'ملغية';
      case 12:
        return 'تحت التحقيق';
      default:
        return 'استرداد'; // Default to "refunded" for any unknown status
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
      case 11:
        return Icons.check_circle;
      case 2:
        return Icons.access_time;
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 10:
        return Icons.replay; // Use replay icon for all refunded statuses
      case 9:
        return Icons.cancel;
      case 12:
        return Icons.security;
      default:
        return Icons.replay; // Default to replay icon for any unknown status
    }
  }

  Widget _buildTransactionCard(dynamic transaction) {
    final status = transaction['status'] ?? 0;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);

    // Obtener la fecha, primero se verifica created_at y si es null se usa date
    String dateStr = 'N/A';
    if (transaction['created_at'] != null) {
      dateStr = transaction['created_at'].split(' ')[0];
    } else if (transaction['date'] != null) {
      dateStr = transaction['date']
          .split(' ')[0]; // Extraer solo la fecha sin la hora
    }

    final formattedDate = dateStr != 'N/A' ? _formatDate(dateStr) : 'N/A';

    // حساب المبلغ المستحق = المبلغ المستلم - تكلفة الاستلام
    double receivingAmount =
        double.tryParse(transaction['receiving_amount'] ?? '0') ?? 0;
    double receivingCharge =
        double.tryParse(transaction['receiving_charge'] ?? '0') ?? 0;
    double netAmount = receivingAmount - receivingCharge;
    String netAmountStr = formatAmount(netAmount.toString());

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Drainagedetails(
                  id: transaction['id'].toString(),
                  email: '',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // رقم الطلب والتاريخ
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              size: 16.sp,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'طلب رقم: ${transaction['exchange_id']}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14.sp,
                              color: Colors.grey.shade500,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // حالة الطلب
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 14.sp,
                            color: statusColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Divider(height: 24.h, color: Colors.grey.shade200),

                // تفاصيل العملات
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Container principal para las columnas de remitente y destinatario
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // من
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المرسل',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Container(
                                    width: 24.w,
                                    height: 24.h,
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
                                        transaction['send_currency_image'] ??
                                            '',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.currency_exchange,
                                          size: 14.sp,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      '${formatAmount(transaction['sending_amount'])} ${transaction['send_currency_symbol']}',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 40.w), // Espacio para la flecha

                        // إلى
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المبلغ المستحق',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Container(
                                    width: 24.w,
                                    height: 24.h,
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
                                        transaction['receive_currency_image'] ??
                                            '',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.currency_exchange,
                                          size: 14.sp,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      '${netAmountStr} ${transaction['receive_currency_symbol'] ?? ''}',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // سهم للتحويل (movido un poco a la derecha)
                    Align(
                      alignment: Alignment(
                          0.1, 0), // Movido ligeramente a la derecha del centro
                      child: Container(
                        margin: EdgeInsets.only(top: 30.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(4.r),
                        child: Icon(
                          Icons.arrow_right_alt,
                          size: 22.sp,
                          color: const Color(0xFFF5951F),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // زر التفاصيل
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Drainagedetails(
                            id: transaction['id'].toString(),
                            email: '',
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF5951F),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض التفاصيل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.arrow_forward, size: 16.sp),
                      ],
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter = intl.DateFormat('dd MMM yyyy', 'ar');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80.sp,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد معاملات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'لم يتم العثور على أي معاملات في هذه الفئة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _refreshTransactions,
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text(
                'تحديث',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFF5951F),
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80.sp,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16.h),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'لم نتمكن من تحميل معاملاتك. يرجى المحاولة مرة أخرى',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _refreshTransactions,
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFF5951F),
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackOrderCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5951F).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search,
                      color: const Color(0xFFF5951F),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تتبع الطلب الخاص بك',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'أدخل رقم الطلب للاطلاع على التفاصيل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'أدخل رقم الطلب',
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.receipt,
                    size: 20.sp,
                    color: Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.w,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.w,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: const Color(0xFFF5951F),
                      width: 1.5.w,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.red.shade400,
                      width: 1.w,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال رقم الطلب';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _trackOrder,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFF5951F),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'تتبع الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.search,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 150.h,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF38659B),
                elevation: 0,
                leading: null,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF38659B),
                          const Color(0xFF2A4D74),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 24.h),
                            Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 30.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'سجل المعاملات',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'تابع جميع عملياتك وطلباتك',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14.sp,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: null,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(60.h),
                  child: Container(
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.r),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF38659B),
                              Color(0xFF2A4D74),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38659B).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        labelStyle: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
                        tabs: [
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: const Text('الكل'),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: const Text('مكتملة'),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: const Text('معلقة'),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: const Text('مردودة'),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: const Text('ملغية'),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: const Text('تحت التحقيق'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              // بطاقة تتبع الطلب
              _buildTrackOrderCard(),

              // قائمة المعاملات
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: transactionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/lottie/loading.json',
                              height: 120.h,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'جاري تحميل المعاملات...',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return _buildErrorState();
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    List<dynamic> filteredTransactions = snapshot.data!;

                    // فلترة حسب التبويب المحدد
                    if (selectedTab != 0) {
                      if (selectedTab == 1) {
                        // For "completed" tab, show both status 1 and 11
                        filteredTransactions = filteredTransactions
                            .where((transaction) =>
                                transaction['status'].toString() == '1' ||
                                transaction['status'].toString() == '11')
                            .toList();
                      } else {
                        int statusToFilter = _getStatusFromTab(selectedTab);
                        filteredTransactions = filteredTransactions
                            .where((transaction) =>
                                transaction['status'].toString() ==
                                statusToFilter.toString())
                            .toList();
                      }
                    }

                    // ترتيب المعاملات حسب التاريخ (الأحدث أولًا)
                    filteredTransactions.sort((a, b) {
                      // استخراج التاريخ من المعاملة الأولى
                      String dateStrA = a['created_at']?.toString() ??
                          a['date']?.toString() ??
                          '';

                      // استخراج التاريخ من المعاملة الثانية
                      String dateStrB = b['created_at']?.toString() ??
                          b['date']?.toString() ??
                          '';

                      // إذا كان أحد التاريخين فارغًا
                      if (dateStrA.isEmpty || dateStrB.isEmpty) {
                        return 0;
                      }

                      try {
                        // تحويل التاريخين إلى كائنات DateTime للمقارنة
                        DateTime dateA = DateTime.parse(dateStrA);
                        DateTime dateB = DateTime.parse(dateStrB);

                        // ترتيب تنازلي (الأحدث أولًا)
                        return dateB.compareTo(dateA);
                      } catch (e) {
                        developer.log(
                            'Error sorting dates: $e, dates: $dateStrA, $dateStrB',
                            name: 'TRANSACTIONS_SORT');
                        return 0;
                      }
                    });

                    // Debug log to verify the filtered results
                    developer.log(
                        'Tab $selectedTab filtered transactions: ${filteredTransactions.length}',
                        name: 'TRANSACTIONS_FILTER');

                    if (filteredTransactions.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshTransactions,
                      color: const Color(0xFFF5951F),
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 24.h),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionCard(
                              filteredTransactions[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
