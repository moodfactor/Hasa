import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage>
    with TickerProviderStateMixin {
  List<dynamic> contactItems = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasError = false;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final GlobalKey _subjectFieldKey = GlobalKey();
  final GlobalKey _messageFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // تهيئة الـ slideAnimation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // بدء الأنيميشن
    _animationController.forward();

    // استدعاء جلب البيانات
    fetchContactItems();
    _checkFirstTimeUser();
  }

  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase = prefs.getBool('hasSeenShowcase') ?? false;

    if (!hasSeenShowcase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context)
            .startShowCase([_messageFieldKey, _subjectFieldKey]);
      });

      await prefs.setBool('hasSeenShowcase', true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> fetchContactItems() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      var dio = Dio();
      final response = await dio.get(
        'https://ha55a.exchange/api/v1/general/contact.php',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            contactItems = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            contactItems = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          contactItems = [];
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'فشل في الاتصال بالخادم';
        });
      }
    } catch (e) {
      setState(() {
        contactItems = [];
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'حدث خطأ أثناء جلب البيانات';
      });
    }
  }

  Future<void> _sendForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        var dio = Dio();
        var data = FormData.fromMap({
          'name': _nameController.text,
          'email': _emailController.text,
          'subject': _subjectController.text,
          'message': _messageController.text,
        });

        var response = await dio.post(
          'https://ha55a.exchange/api/v1/general/send-ticket.php',
          data: data,
        );

        setState(() {
          _isSubmitting = false;
        });

        if (response.statusCode == 200 &&
            response.data['status'] == 'success') {
          _resetForm();
          _showSuccessBottomSheet(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'فشل الإرسال: ${response.data['message'] ?? "حدث خطأ غير متوقع"}'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الإرسال، يرجى المحاولة مرة أخرى'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();
    _formKey.currentState?.reset();
  }

  void _showSuccessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle bar
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),

              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 60.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "تم إرسال الرسالة بنجاح",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "لقد تم إرسال رسالتك إلى فريق الدعم. سيتم التواصل معك قريبًا. شكرًا لتواصلك معنا.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFF5951F),
                  elevation: 0,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'حسناً',
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
      },
    );
  }

  void launchURL(String url, String type) async {
    String launchableUrl;

    switch (type) {
      case 'phone':
        launchableUrl = 'tel:$url';
        break;
      case 'email':
        launchableUrl = 'mailto:$url';
        break;
      case 'whatsapp':
        launchableUrl =
            "https://wa.me/$url?text=${Uri.encodeComponent('السلام عليكم، أحتاج مساعدة في ')}";
        break;
      case 'address':
        launchableUrl = 'https://maps.google.com/?q=$url';
        break;
      default:
        launchableUrl = url;
    }

    try {
      final Uri uri = Uri.parse(launchableUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $launchableUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن فتح $launchableUrl'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ النص'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'اتصل بنا',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: fetchContactItems,
          color: const Color(0xFFF5951F),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading
                  ? _buildLoadingState()
                  : _hasError
                      ? _buildErrorState()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF5951F),
                                    Color(0xFFFF8F00)
                                  ],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF5951F)
                                        .withOpacity(0.2),
                                    offset: const Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30.r,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.2),
                                    child: Icon(
                                      Icons.headset_mic,
                                      color: Colors.white,
                                      size: 30.r,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'بحاجة إلى مساعدة؟',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          'فريق الدعم متاح للإجابة على استفساراتك',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 14.sp,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Contact Methods Section
                            if (contactItems.isNotEmpty) ...[
                              Text(
                                'وسائل التواصل',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              ...contactItems
                                  .map((item) => _buildContactCard(item))
                                  .toList(),
                              SizedBox(height: 24.h),
                            ],

                            // Contact Form Section
                            Container(
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
                              ),
                              padding: EdgeInsets.all(20.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5951F)
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.email_outlined,
                                          color: const Color(0xFFF5951F),
                                          size: 20.sp,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'راسلنا الآن',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'نحن هنا من أجلك، كيف يمكننا مساعدتك؟',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 24.h),

                                  // Form
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        _buildTextField(
                                          controller: _nameController,
                                          label: 'الاسم',
                                          hint: 'أدخل اسمك الكامل',
                                          icon: Icons.person_outline,
                                          required: true,
                                        ),
                                        SizedBox(height: 16.h),
                                        _buildTextField(
                                          controller: _emailController,
                                          label: 'البريد الإلكتروني',
                                          hint: 'example@email.com',
                                          icon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          required: true,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'يرجى إدخال البريد الإلكتروني';
                                            }
                                            if (!RegExp(
                                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value)) {
                                              return 'يرجى إدخال بريد إلكتروني صحيح';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 16.h),
                                        _buildTextField(
                                          controller: _subjectController,
                                          label: 'الموضوع',
                                          hint: 'موضوع الرسالة',
                                          icon: Icons.subject,
                                          required: true,
                                        ),
                                        SizedBox(height: 16.h),
                                        _buildTextField(
                                          controller: _messageController,
                                          label: 'الرسالة',
                                          hint: 'اكتب رسالتك هنا...',
                                          icon: Icons.message_outlined,
                                          maxLines: 5,
                                          required: true,
                                        ),
                                        SizedBox(height: 24.h),

                                        // Submit Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50.h,
                                          child: ElevatedButton(
                                            onPressed: _isSubmitting
                                                ? null
                                                : _sendForm,
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor:
                                                  const Color(0xFFF5951F),
                                              disabledBackgroundColor:
                                                  Colors.grey.shade300,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                            ),
                                            child: _isSubmitting
                                                ? SizedBox(
                                                    height: 24.h,
                                                    width: 24.h,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.5.w,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'إرسال الرسالة',
                                                        style: TextStyle(
                                                          fontFamily: 'Cairo',
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8.w),
                                                      const Icon(
                                                        Icons.send,
                                                        size: 18,
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
                            SizedBox(height: 40.h),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 50.h,
              width: 50.h,
              child: CircularProgressIndicator(
                strokeWidth: 3.w,
                color: const Color(0xFFF5951F),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'جاري تحميل وسائل التواصل...',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 300.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: fetchContactItems,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFF5951F),
                elevation: 0,
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

  Widget _buildContactCard(dynamic item) {
    final dataValues = item['data_values'];
    final heading = dataValues['heading'] ?? 'العنوان مفقود';
    final subheading = dataValues['subheading'] ?? 'الوصف مفقود';
    final value = dataValues['value'] ?? 'المحتوى مفقود';

    String contactType = 'phone';
    IconData icon = Icons.phone;
    Color iconColor = Colors.blue.shade700;
    Color cardColor = Colors.blue.shade50;

    // تحديد نوع وسيلة التواصل بناءً على محتوى البيانات
    if (value.toString().contains('@')) {
      // إذا كانت البيانات تحتوي على @ فهي بريد إلكتروني
      icon = Icons.email;
      contactType = 'email';
      iconColor = Colors.orange.shade700;
      cardColor = Colors.orange.shade50;
    } else if (value.toString().startsWith('٠٠٩٤') ||
        value.toString().startsWith('00964')) {
      // إذا كانت البيانات تبدأ بـ ٠٠٩٤ أو 00964 فهي رقم هاتف
      icon = Icons.phone;
      contactType = 'phone';
      iconColor = Colors.blue.shade700;
      cardColor = Colors.blue.shade50;
    } else if (value.toString().contains('بغداد') ||
        value.toString().toLowerCase().contains('baghdad')) {
      // إذا كانت البيانات تحتوي على كلمة بغداد فهي عنوان
      icon = Icons.location_on;
      contactType = 'address';
      iconColor = Colors.red.shade700;
      cardColor = Colors.red.shade50;
    } else if (value.toString().startsWith('+') ||
        RegExp(r'^\d{10,}$').hasMatch(value.toString())) {
      // أرقام أخرى تبدأ بـ + أو تتكون من 10 أرقام على الأقل
      icon = Icons.phone;
      contactType = 'phone';
      iconColor = Colors.blue.shade700;
      cardColor = Colors.blue.shade50;
    } else if (heading.toLowerCase().contains('whatsapp')) {
      // الواتساب من العنوان
      icon = Icons.whatshot;
      contactType = 'whatsapp';
      iconColor = Colors.green.shade700;
      cardColor = Colors.green.shade50;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
      child: InkWell(
        onTap: () => launchURL(value, contactType),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.content_copy,
                      color: Colors.grey.shade600,
                      size: 20.sp,
                    ),
                    onPressed: () => _copyToClipboard(value),
                  ),
                  Text(
                    'نسخ',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4.w, bottom: 8.h),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: Colors.grey.shade700,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              if (required)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade600,
                  ),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15.sp,
            color: Colors.grey.shade800,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: maxLines > 1 ? 16.h : 0,
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
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 1.5.w,
              ),
            ),
          ),
          validator: validator ??
              (required
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال $label';
                      }
                      return null;
                    }
                  : null),
        ),
      ],
    );
  }
}
