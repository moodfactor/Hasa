import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/contact_us_page.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, String>>> _faqsFuture;
  late AnimationController _animationController;
  final List<int> _expandedItems = [];

  @override
  void initState() {
    super.initState();
    _faqsFuture = fetchFaqs();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Map<String, String>>> fetchFaqs() async {
    final dio = Dio();
    try {
      final response = await dio.get(
        'https://ha55a.exchange/api/v1/general/faq.php',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List<dynamic>;

        // تحويل البيانات إلى قائمة من نوع List<Map<String, String>>
        return data.map((item) {
          final dynamic values = item['data_values'];
          return {
            'question': values['question'] as String,
            'answer': values['answer'] as String,
          };
        }).toList();
      } else {
        throw Exception('Failed to load FAQs: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error fetching FAQs: $e');
    }
  }

  void _toggleItem(int index) {
    setState(() {
      if (_expandedItems.contains(index)) {
        _expandedItems.remove(index);
      } else {
        _expandedItems.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'الأسئلة الشائعة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF38659B),
                Colors.white,
              ],
              stops: [0.0, 0.3],
            ),
          ),
          child: FutureBuilder<List<Map<String, String>>>(
            future: _faqsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child:
                      Lottie.asset('assets/lottie/loading.json', height: 150),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 60),
                      SizedBox(height: 16.h),
                      Text(
                        'حدث خطأ: ${snapshot.error}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.help_outline,
                          color: Colors.amber, size: 60),
                      SizedBox(height: 16.h),
                      Text(
                        'لا توجد أسئلة شائعة حالياً.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                final faqs = snapshot.data!;
                return _buildContent(faqs);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, String>> faqs) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: kToolbarHeight + 40.h),

            // Header Section
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38659B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const Icon(
                          Icons.question_answer_outlined,
                          color: Color(0xFF38659B),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'الأسئلة المتكررة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF38659B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
                  SizedBox(height: 16.h),
                  Text(
                    'يمكنك العثور على إجابات للأسئلة الشائعة هنا. إذا لم تجد ما تبحث عنه، لا تتردد في التواصل معنا.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // FAQ Items
            ...List.generate(faqs.length, (index) {
              final faq = faqs[index];
              final isExpanded = _expandedItems.contains(index);

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Column(
                    children: [
                      // Question Header
                      InkWell(
                        onTap: () => _toggleItem(index),
                        child: Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: isExpanded
                                ? const Color(0xFFF97316).withOpacity(0.05)
                                : Colors.white,
                            border: Border(
                              right: BorderSide(
                                color: isExpanded
                                    ? const Color(0xFFF97316)
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: isExpanded
                                      ? const Color(0xFFF97316).withOpacity(0.1)
                                      : const Color(0xFF38659B)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: SvgPicture.asset(
                                  "assets/images/Questions.svg",
                                  height: 16.r,
                                  width: 16.r,
                                  color: isExpanded
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFF38659B),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  faq['question']!,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isExpanded
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: isExpanded
                                      ? const Color(0xFFF97316)
                                      : Colors.grey.shade400,
                                  size: 24.r,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Answer Section
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        child: Container(
                          height: isExpanded ? null : 0,
                          color: Colors.white,
                          padding: isExpanded
                              ? EdgeInsets.all(16.r).copyWith(top: 0)
                              : EdgeInsets.zero,
                          child: isExpanded
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(color: Colors.grey.shade200),
                                    Padding(
                                      padding: EdgeInsets.only(right: 36.r),
                                      child: Text(
                                        faq['answer']!,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey.shade700,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            SizedBox(height: 24.h),

            // Contact Card
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38659B), Color(0xFF274973)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هل لديك سؤال آخر؟',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'فريق الدعم جاهز للمساعدة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactUsPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_outlined,
                            color: Color(0xFF38659B),
                            size: 18,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'راسلنا',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF38659B),
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
        ),
      ),
    );
  }
}
