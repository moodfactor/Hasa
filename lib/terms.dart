import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'الشروط والأحكام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Text(
                    'شروط عامة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 24.h),

                // General Terms
                _buildBulletPoint(
                    'باستخدام خدمتنا فإنك توافق على إخلاء المسؤولية والمسؤولية المحدودة لـ هسة exchange'),

                _buildBulletPoint(
                    'من خلال تقديم أي طلب عبر الهاتف المحمول أو البريد الإلكتروني أو الموقع الإلكتروني أو استخدام أي من خدماتنا، فإنك توافق تلقائيًا على الشروط والأحكام الخاصة بنا.'),

                _buildBulletPoint(
                    'باستخدام خدماتنا أو زيارة موقعنا الإلكتروني، أنت وحدك المسؤول عن جميع أفعالك وردود أفعالك.'),

                _buildBulletPoint(
                    'نحن لسنا مسؤولين عن أي موقع آخر أو معالج دفع أو أي برنامج أو مدفوعات أو احتيال أو أي شيء آخر، نحن مجرد ميسرين ونقدم المعلومات أو بعض الخدمات ذات الصلة فقط. ليس لدينا علاقة مباشرة أو غير مباشرة مع أي موقع أو شركة أخرى.'),

                _buildBulletPoint(
                    'لدينا الحق في تعليق أو إنهاء حسابك/خدمتك في أي وقت ولأي سبب وجيه ودون سابق إنذار أو إشعار. إذا قررنا تقديم إشعار، فسنخطرك عبر البريد الإلكتروني. إذا تم القبض عليك وأنت تغش بأي شكل من الأشكال، فسيتم تعليق حسابك أو خدمتك أو دفعتك دون إشعار. يرجى ملاحظة أنه نظرًا لطبيعة الملكية الخاصة بنظام المراقبة لدينا، لا يمكننا الكشف عن أي معلومات تفصيلية أو مناقشة السبب.'),

                SizedBox(height: 30.h),

                // Transaction Rules Section Header
                Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.r, horizontal: 16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.gavel_rounded,
                        color: Color(0xFFF97316),
                        size: 20,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'قواعد المعاملات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Transaction Rules
                _buildBulletPoint(
                    'من أجل معالجة أمر الصرف، يتطلب الاستخدام توفير معلومات شخصية ومالية فعالة وصحيحة'),

                _buildBulletPoint(
                    'يمكننا التحقق من معلوماتك المقدمة في أي وقت بإشعار أو بدونه'),

                _buildBulletPoint(
                    'لإكمال عملية التبادل، نحتفظ بالحق في السؤال عن مصدر الأموال من المستخدم'),

                _buildBulletPoint(
                    'يمكننا رفض الطلب لأسباب صحيحة ولكن سرية والتي لا يمكن الكشف عنها مع المستخدم في بعض الأحيان.'),

                _buildBulletPoint(
                    'يدفع المستخدم دائمًا مقدمًا للبدء في أمر التبادل'),

                _buildBulletPoint(
                    'لا تتحمل هسة exchange المسؤولية إذا قدمت معلومات خاطئة عن البنك أو المحفظة الإلكترونية وقمنا بإرسال الأموال إلى هذا الحساب.'),

                _buildBulletPoint(
                    'لن نقبل النقل من قبل طرف ثالث. يجب على المستخدمين التحويل إلينا باسمهم الخاص لإنهاء المعاملة.'),

                _buildBulletPoint(
                    'يجب على المستخدمين ضمان أن الأموال المحولة إلينا هي ملكهم الخاص ولهم الحق في التصرف فيها.'),

                _buildBulletPoint(
                    'المستخدم مسؤول دائمًا عن أمواله في حالة الرجوع أو النزاع.'),

                _buildBulletPoint(
                    'نحن مسؤولون فقط عن الأموال المحولة إليك في هذه المعاملة. بعد إتمام المعاملة، لن نتحمل المسؤولية عن عملياتك المستقبلية أو استخدام الأموال.'),

                SizedBox(height: 30.h),

                // Legal Responsibility Section Header
                Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.r, horizontal: 16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFF97316),
                        size: 20,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'مسئولية قانونية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Legal Responsibility content
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'لن يكون أعضاء فريق هسة exchange أو مالكه مسؤولين عن محاولات القرصنة أو التأخير أو الفشل في الأداء الناجم عن خطأ في البرنامج أو الخادم أو الحرب أو الإرهاب أو الإضراب أو النزاع العمالي أو توقف العمل أو الحريق أو الإجراءات الحكومية أو المراجعات أو الانتظار المدفوعات من معالج الدفع أو أي سبب آخر، سواء كان مشابهًا أو مختلفًا، خارج عن سيطرتنا. يحتفظ موقع هسة exchange بالحق في تقييد أو تغيير أو تعديل الرسوم والمزايا والقواعد واللوائح والعروض الخاصة وشروط وأحكام العضوية أو إنهاء الخدمات في أي وقت ودون إشعار.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      height: 1.6,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),

                SizedBox(height: 30.h),

                // Footer
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.r, horizontal: 16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'باستخدام خدماتنا، فإنك توافق على جميع الشروط والأحكام المذكورة أعلاه',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                        color: const Color(0xFFF97316),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.r),
            child: Container(
              width: 6.r,
              height: 6.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF97316),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
