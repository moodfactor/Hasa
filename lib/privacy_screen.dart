import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'سياسة الخصوصية',
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
                    'سياسة الخصوصية لموقع هسة exchange',
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

                // Introduction
                _buildParagraph(
                  'نحن في موقع هسة exchange نهتم بحماية خصوصية معلوماتك الشخصية ونلتزم بالحفاظ على سرية هذه المعلومات. يُرجى قراءة سياسة الخصوصية التالية بعناية لفهم كيفية جمع واستخدام وحماية المعلومات التي نجمعها.',
                  isBold: false,
                ),

                SizedBox(height: 30.h),

                // Section 1
                _buildSection(
                  '1. جمع المعلومات:',
                  [
                    'نقوم بجمع المعلومات الشخصية التي تقدمها بشكل طوعي عندما تقوم بإنشاء حساب على موقعنا أو تقوم بتقديم طلب لعملية تبادل عملة.',
                    'يمكن أن تتضمن هذه المعلومات اسمك الكامل، عنوان بريدك الإلكتروني، رقم هاتفك، ومعلومات أخرى ذات صلة بعملية التبادل.',
                  ],
                ),

                // Section 2
                _buildSection(
                  '2. استخدام المعلومات:',
                  [
                    'نحن نستخدم المعلومات التي نجمعها لتقديم خدمات تبادل العملات وتنفيذ العمليات الخاصة بك.',
                    'يمكن أن نستخدم معلوماتك للاتصال بك بشأن عمليات التبادل وإشعارك بأي تحديثات أو تغييرات في خدماتنا.',
                  ],
                ),

                // Section 3
                _buildSection(
                  '3. حفظ المعلومات:',
                  [
                    'نحن نحتفظ بالمعلومات الشخصية لفترة زمنية معقولة تتوافق مع الأغراض التي تم جمع المعلومات من أجلها.',
                    'نحن نتخذ إجراءات أمان ملائمة لحماية معلوماتك الشخصية من الوصول غير المصرح به والاستخدام غير المصرح به.',
                  ],
                ),

                // Section 4
                _buildSection(
                  '4. مشاركة المعلومات:',
                  [
                    'نحن لن نشارك معلوماتك الشخصية مع أطراف ثالثة دون موافقتك الصريحة، ما لم تكن هناك متطلبات قانونية تلزمنا بالقيام بذلك.',
                    'قد نشارك المعلومات مع شركاء خدمات معتمدين إذا كان ذلك ضروريًا لتنفيذ عمليات التبادل.',
                  ],
                ),

                // Section 5
                _buildSection(
                  '5. حقوق الوصول والتصحيح:',
                  [
                    'لديك الحق في الوصول إلى معلوماتك الشخصية وتصحيحها أو حذفها عند الضرورة.',
                    'يمكنك ممارسة هذه الحقون عن طريق الاتصال بنا عبر البريد الإلكتروني المُدرج في نهاية هذه السياسة.',
                  ],
                ),

                // Section 6
                _buildSection(
                  '6. تحديثات لسياسة الخصوصية:',
                  [
                    'نحتفظ بالحق في تحديث سياسة الخصوصية هذه من وقت لآخر. سيتم نشر أية تحديثات على موقعنا على الويب.',
                    'يُفترض أنك قد قرأت ووافقت على النسخة الأحدث من سياسة الخصوصية عند استخدامك للموقع وخدماتنا.',
                  ],
                ),

                SizedBox(height: 30.h),

                // Closing paragraph
                _buildParagraph(
                  'إذا كان لديك أي استفسارات أو مخاوف بشأن سياسة الخصوصية الخاصة بنا، فلا تتردد في الاتصال بنا عبر البريد الإلكتروني المُدرج أدناه. نحن نعمل جاهدين على حماية خصوصيتك وتوفير تجربة آمنة ومأمونة عند استخدام موقعنا.',
                  isBold: false,
                ),

                SizedBox(height: 16.h),

                // Contact email
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.r),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: Color(0xFFF97316),
                        size: 18,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Email: info@ha55a.exchange',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Last updated
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'تاريخ آخر تحديث: 01-10-2023',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12.h),
          ...points.map((point) => _buildBulletPoint(point)).toList(),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.r),
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

  Widget _buildParagraph(String text, {bool isBold = false}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15.sp,
        height: 1.6,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: const Color(0xFF64748B),
      ),
      textAlign: TextAlign.justify,
    );
  }
}
