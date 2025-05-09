import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'لوحة التحكم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: false,
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // رسالة التحقق
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KYC Verification required',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'عزيزي المستخدم، نحتاج إلى بيانات KYC الخاصة بك لاتخاذ بعض الإجراءات. إذا أردت تقديم بيانات "اعرف عميلك"، يرجى النقر على "اضغط هنا للتحقق".',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'اضغط هنا للتحقق',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.h,
                  mainAxisSpacing: 16.w,
                  childAspectRatio: 2,
                  children: [
                    _buildDashboardItem(
                        'الطلبات المكتملة',
                        '0',
                        const ImageIcon(
                          AssetImage('assets/images/order_completed.png'),
                          color: Colors.white,
                          size: 15,
                        )),
                    _buildDashboardItem(
                      'الطلبات المعلقة',
                      '0',
                      const ImageIcon(
                        AssetImage('assets/images/waiting_arders.png'),
                        color: Colors.white,
                      ),
                    ),
                    _buildDashboardItem(
                      'تحت التحقق',
                      '0',
                      const ImageIcon(
                        AssetImage('assets/images/waiting_arders.png'),
                        color: Colors.white,
                      ),
                    ),
                    _buildDashboardItem(
                      'الطلبات الملغية',
                      '0',
                      const ImageIcon(
                        AssetImage('assets/images/roder_cancled.png'),
                        color: Colors.white,
                      ),
                    ),
                    _buildDashboardItem(
                      'طلبات استرداد',
                      '0',
                      const ImageIcon(
                        AssetImage('assets/images/income_orders.png'),
                        color: Colors.white,
                      ),
                    ),
                    _buildDashboardItem(
                      'كل الطلبات',
                      '0',
                      const ImageIcon(
                        AssetImage('assets/images/all_orders.png'),
                        color: Colors.white,
                      ),
                    ),
                    _buildDashboardItem(
                      'تذكرة الرد',
                      '0',
                      const ImageIcon(
                        AssetImage('assets/images/remeber_order.png'),
                        color: Colors.white,
                      ),
                    ),
                    _buildDashboardItem(
                      'تذكرة الاجابة',
                      '0',
                      const ImageIcon(
                        AssetImage('assets/images/response_remeber.png'),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // قائمة التبادلات
              // const Text(
              //   'أحدث التبادلات الخاصة بك',
              //   style: TextStyle(
              //     fontFamily: 'Cairo',
              //     fontSize: 14,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.black,
              //   ),
              // ),
              const SizedBox(height: 8),

            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDashboardItem(String title, String count, Widget icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF5951F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          count,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
      ),
    );
  }
}
