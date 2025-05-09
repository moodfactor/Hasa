import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'سياسة الاسترجاع',
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
                // Introduction
                Text(
                  'نحن في موقع هسه Exchange نعمل على توفير خدمة تبادل الأموال بين المحافظ المالية المحلية والعالمية لعملائنا في جميع أنحاء العالم. نحن نسعى جاهدين لتوفير أفضل خدمة لعملائنا، ولذلك نقدم سياسة الإرجاع التي تسمح لك بإرجاع الأموال إذا كان هناك أي خطأ في العملية.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15.sp,
                    height: 1.6,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.justify,
                ),

                SizedBox(height: 24.h),

                // Legal Disclaimer
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFFCA5A5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'إخلاء المسؤولية القانونية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'إن استخدامك لخدمات موقع هسه Exchange يتطلب منك الالتزام بالشروط والأحكام المذكورة أدناه. في حال لم يتم التعامل مباشرة من قبلك مع الموقع أو في حال تم التعامل من خلال وسطاء أو أطراف ثالثة، فإن الموقع لا يتحمل أي مسؤولية عن أي خسائر أو أضرار قد تنشأ عن ذلك. نوصيك بالتعامل مباشرة مع الموقع لضمان الحصول على المعلومات الدقيقة والخدمات الموثوقة.',
                        style: TextStyle(
                      fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          height: 1.5,
                          color: const Color(0xFFDC2626),
                        ),
                      textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Refund Policy Section Header
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
                        Icons.policy_outlined,
                        color: Color(0xFFF97316),
                        size: 20,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'سياسة الإرجاع',
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

                SizedBox(height: 16.h),

                // Refund Policy Paragraph
                Text(
                  'تهدف سياسة الإرجاع التي نقدمها إلى توفير الراحة والأمان لعملائنا، وتتضمن بعض الشروط والقيود التي يجب اتباعها. يجب عليك قراءة هذه الشروط بعناية قبل القيام بأي عملية تبادل عملة في موقعنا.\nتحتفظ "هسه Exchange" بحق تعديل أو تحديث هذه الشروط والأحكام في أي وقت دون إشعار مسبق. لذا، يرجى مراجعة هذه الصفحة بانتظام للتأكد من التزامك بأحدث الشروط والأحكام.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    height: 1.6,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.justify,
                ),

                SizedBox(height: 24.h),

                // Refund Terms Section Header
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
                        Icons.fact_check_outlined,
                        color: Color(0xFFF97316),
                        size: 20,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'شروط الإرجاع',
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

                SizedBox(height: 16.h),

                // Refund Terms
                _buildBulletPoint(
                    'التأكد من المعلومات المدخلة: يجب أن تتأكد من إدخال المعلومات الصحيحة والدقيقة أثناء إجراء العملية. إذا كان هناك أي خطأ في المعلومات التي أدخلتها، فنحن غير مسؤولون عن ذلك ولن نتمكن من استرداد الأموال المرسلة.'),

                _buildBulletPoint(
                    'تقييد الإرجاع لبعض المحافظ أو البنوك المالية الإلكترونية أو بعض البلدان: قد يتم تقييد الإرجاع لبعض المحافظ أو البنوك المالية الإلكترونية أو لبعض البلدان.'),

                _buildBulletPoint(
                    'طريقة الإرجاع: إذا وافقنا على استرداد المبلغ فسيكون هناك حدود معينة ورسوم استرداد قدرها 1% الى 5% كحد أقصى من المبلغ الإجمالي ويتم ارجاع الطلب بنفس طريقة الدفع إن كانت تتيح ذلك.'),

                _buildBulletPoint(
                    'إبلاغ الدعم الفني في الوقت المحدد: يتم إرجاع الطلب إذا كان قيد الانتظار ويجب تبليغ الدعم الفني بمدة لا تزيد عن 3 ساعات من إرسال الطلب.'),

                _buildBulletPoint(
                    'قيود الإرجاع على طرق الدفع: لا يمكن إرجاع الطلب إذا كان الدفع عن طريق فيزا أو عن طريق ماستر كارد.'),

                _buildBulletPoint(
                    'تقديم إثباتات عند عملية الإرجاع: يجب تقديم إثباتات عند عملية الإرجاع.'),

                SizedBox(height: 24.h),

                // Additional Notes Section Header
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
                        Icons.info_outline,
                        color: Color(0xFFF97316),
                        size: 20,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'ملاحظات إضافية',
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

                SizedBox(height: 16.h),

                // Additional Notes
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
                    'في حال تم الكشف عن أي حركة مالية مسروقة، سيتم رد المبالغ إلى نفس المحفظة التي تم الدفع من خلالها وعلى نفس الرقم المرتبط بالمحفظة. يُرجى ملاحظة أن المبلغ الذي سيتم ردّه سيخصم منه عمولات الموقع مقابل خدماته آلياً، ولا يتحمل الموقع أي خسائر ناجمة عن ذلك.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      height: 1.6,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),

                SizedBox(height: 24.h),

                // Footer
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.support_agent,
                        color: Color(0xFFF97316),
                        size: 20,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'إذا كان لديك أي استفسار أو تحتاج إلى المزيد من المعلومات، يُرجى التواصل معنا عبر وسائل الاتصال المتاحة على الموقع.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
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
      padding: EdgeInsets.only(bottom: 16.r),
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
