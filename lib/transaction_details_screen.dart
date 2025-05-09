import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';

class TransactionDetailsScreen extends StatefulWidget {
  final String id;
  final String status;
  final String date;
  final Map<String, dynamic> sendDetails;
  final Map<String, dynamic> receiveDetails;

  const TransactionDetailsScreen({
    super.key,
    required this.id,
    this.status = "معلقة",
    required this.date,
    required this.sendDetails,
    required this.receiveDetails,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen>
    with SingleTickerProviderStateMixin {
  int selectedTab = 0; // 0: تفاصيل الإرسال, 1: تفاصيل الاستلام
  late TabController _tabController;
  bool _showShareOptions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case "مكتملة":
        return Colors.green.shade600;
      case "معلقة":
        return Colors.amber.shade600;
      case "مردودة":
        return Colors.red.shade600;
      case "ملغية":
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case "مكتملة":
        return Icons.check_circle;
      case "معلقة":
        return Icons.access_time;
      case "مردودة":
        return Icons.replay;
      case "ملغية":
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  int _getStatusStep() {
    switch (widget.status) {
      case "مكتملة":
        return 3;
      case "معلقة":
        return 1;
      case "مردودة":
        return 2;
      case "ملغية":
        return 3;
      default:
        return 0;
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
            // الخلفية مع التموّج
            Container(
              height: 240.h,
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
                    top: -50.h,
                    right: -30.w,
                    child: Container(
                      height: 150.h,
                      width: 150.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60.h,
                    left: -20.w,
                    child: Container(
                      height: 180.h,
                      width: 180.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // المحتوى الرئيسي
            SafeArea(
              child: Column(
                children: [
                  // شريط العنوان
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Text(
                          'تفاصيل العملية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _showShareOptions = !_showShareOptions;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // بطاقة الحالة
                  _buildStatusCard(),

                  // بطاقة المعلومات الرئيسية
                  _buildTransactionMainCard(),

                  SizedBox(height: 16.h),

                  // شريط التبويبات
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
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.r),
                        color: const Color(0xFFF5951F),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade700,
                      labelStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'تفاصيل الإرسال'),
                        Tab(text: 'تفاصيل الاستلام'),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // محتوى التبويبات
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSendDetailsTab(),
                        _buildReceiveDetailsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // خيارات المشاركة
            if (_showShareOptions) _buildShareOptions(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF38659B),
          onPressed: () {
            // إظهار معلومات الدعم الفني
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              builder: (context) => _buildSupportSection(),
            );
          },
          child: const Icon(Icons.headset_mic, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رقم الطلب: ${widget.id}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 14.sp,
                      color: _getStatusColor(),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      widget.status,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildTimelineProgress(),
        ],
      ),
    );
  }

  Widget _buildTimelineProgress() {
    final currentStep = _getStatusStep();

    return Column(
      children: [
        Row(
          children: [
            _buildTimelineStep(1, currentStep >= 1, 'تم الطلب', widget.date),
            _buildTimelineLine(currentStep >= 2),
            _buildTimelineStep(
                2, currentStep >= 2, 'قيد التنفيذ', 'معالجة الطلب'),
            _buildTimelineLine(currentStep >= 3),
            _buildTimelineStep(
                3,
                currentStep >= 3,
                widget.status == "ملغية"
                    ? 'تم الإلغاء'
                    : widget.status == "مردودة"
                        ? 'تم الرد'
                        : 'تم الإكمال',
                'إنهاء العملية'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
      int step, bool isCompleted, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color:
                  isCompleted ? const Color(0xFF38659B) : Colors.grey.shade300,
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
              color: isCompleted ? Colors.grey.shade800 : Colors.grey.shade500,
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

  Widget _buildTimelineLine(bool isCompleted) {
    return Container(
      width: 30.w,
      height: 2.h,
      color: isCompleted ? const Color(0xFF38659B) : Colors.grey.shade300,
    );
  }

  Widget _buildTransactionMainCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'تحويل الأموال',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
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
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: Image.network(
                                widget.sendDetails['image'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.account_balance_wallet,
                                  size: 20.sp,
                                  color: const Color(0xFF38659B),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'الإرسال',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${widget.sendDetails['amount']}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          Text(
                            '${widget.sendDetails['currency']}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF38659B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5951F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: const Color(0xFFF5951F),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
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
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: Image.network(
                                widget.receiveDetails['image'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.account_balance_wallet,
                                  size: 20.sp,
                                  color: const Color(0xFF38659B),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'الاستلام',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${widget.receiveDetails['amount']}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          Text(
                            '${widget.receiveDetails['currency']}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF38659B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            'الطريقة',
            widget.sendDetails['method'] ?? 'غير متوفر',
            icon: Icons.payment,
            imagePath: widget.sendDetails['methodImage'],
          ),
          _buildDetailCard(
            'العملة',
            widget.sendDetails['currency'] ?? 'غير متوفر',
            icon: Icons.monetization_on,
          ),
          _buildDetailCard(
            'المبلغ',
            widget.sendDetails['amount'] ?? 'غير متوفر',
            icon: Icons.attach_money,
          ),
          _buildDetailCard(
            'الرسوم',
            widget.sendDetails['fees'] ?? '0.00',
            icon: Icons.account_balance_wallet,
          ),
          _buildDetailCard(
            'الإجمالي',
            widget.sendDetails['total'] ??
                widget.sendDetails['amount'] ??
                'غير متوفر',
            icon: Icons.calculate,
            highlight: true,
          ),
          if (widget.sendDetails['accountName'] != null)
            _buildDetailCard(
              'اسم الحساب',
              widget.sendDetails['accountName'],
              icon: Icons.person,
            ),
          if (widget.sendDetails['accountNumber'] != null)
            _buildDetailCard(
              'رقم الحساب',
              widget.sendDetails['accountNumber'],
              icon: Icons.credit_card,
            ),
          SizedBox(height: 80.h),
        ],
      ),
    );
  }

  Widget _buildReceiveDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            'الطريقة',
            widget.receiveDetails['method'] ?? 'غير متوفر',
            icon: Icons.payment,
            imagePath: widget.receiveDetails['methodImage'],
          ),
          _buildDetailCard(
            'العملة',
            widget.receiveDetails['currency'] ?? 'غير متوفر',
            icon: Icons.monetization_on,
          ),
          _buildDetailCard(
            'المبلغ',
            widget.receiveDetails['amount'] ?? 'غير متوفر',
            icon: Icons.attach_money,
          ),
          if (widget.receiveDetails['accountName'] != null)
            _buildDetailCard(
              'اسم الحساب',
              widget.receiveDetails['accountName'],
              icon: Icons.person,
            ),
          if (widget.receiveDetails['accountNumber'] != null)
            _buildDetailCard(
              'رقم الحساب',
              widget.receiveDetails['accountNumber'],
              icon: Icons.credit_card,
            ),
          if (widget.receiveDetails['bankName'] != null)
            _buildDetailCard(
              'البنك',
              widget.receiveDetails['bankName'],
              icon: Icons.account_balance,
            ),
          if (widget.receiveDetails['notes'] != null)
            _buildDetailCard(
              'ملاحظات',
              widget.receiveDetails['notes'],
              icon: Icons.note,
            ),
          SizedBox(height: 80.h),
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
                      icon,
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
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: 280.w,
              padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'مشاركة تفاصيل العملية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShareOption(
                        icon: Icons.screenshot,
                        title: 'لقطة شاشة',
                        color: Colors.purple,
                      ),
                      _buildShareOption(
                        icon: Icons.picture_as_pdf,
                        title: 'PDF',
                        color: Colors.red.shade700,
                      ),
                      _buildShareOption(
                        icon: Icons.message,
                        title: 'رسالة نصية',
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showShareOptions = false;
                      });
                    },
          child: Text(
                      'إلغاء',
            style: TextStyle(
              fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50.r,
          height: 50.r,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: EdgeInsets.all(20.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Container(
            width: 50.w,
            height: 4.h,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'الدعم الفني',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF38659B),
                  radius: 24.r,
                  child: Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هل تواجه مشكلة؟',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'فريق الدعم متاح للمساعدة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(
                Icons.phone,
                color: Colors.green.shade700,
              ),
            ),
            title: Text(
              'اتصل بنا',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '+964 750 123 4567',
              style: TextStyle(
                fontFamily: 'Cairo',
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
            onTap: () {},
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.chat,
                color: Colors.blue.shade700,
              ),
            ),
            title: Text(
              'محادثة مباشرة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'متاح الآن',
              style: TextStyle(
                fontFamily: 'Cairo',
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
            onTap: () {},
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5951F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              minimumSize: Size(double.infinity, 50.h),
            ),
                child: Text(
              'إغلاق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
