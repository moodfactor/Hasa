import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_project/offer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_screen.dart';

class Kycform extends StatefulWidget {
  const Kycform({super.key});

  @override
  State<Kycform> createState() => _KycformState();
}

class _KycformState extends State<Kycform> with SingleTickerProviderStateMixin {
  // Form controllers and data
  final TextEditingController fullname = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Image files
  File? passportImage;
  File? residenceImage;
  File? selfieImage;

  // User data and loading state
  String? userId;
  bool isLoading = false;

  // Current step in the stepper
  int _currentStep = 0;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    fetchUserData();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    fullname.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      Map<String, dynamic> userData = jsonDecode(userJson);
      setState(() {
        userId = userData['id'].toString();
      });
    }
  }

  // Function to go to next step
  void _nextStep() {
    // Validate current step
    if (_currentStep == 0 && !formKey.currentState!.validate()) {
      _showErrorDialog('يرجى إدخال الاسم الكامل');
      return;
    }

    // Validate document step
    if (_currentStep == 1) {
      if (passportImage == null) {
        _showErrorDialog('يرجى التقاط صورة جواز السفر أو بطاقة الهوية');
        return;
      }
    }

    // Validate residence step
    if (_currentStep == 2) {
      if (residenceImage == null) {
        _showErrorDialog('يرجى التقاط صورة إثبات السكن');
        return;
      }
    }

    // Validate selfie step
    if (_currentStep == 3) {
      if (selfieImage == null) {
        _showErrorDialog('يرجى التقاط صورة سيلفي مع الهوية');
        return;
      }

      // If all validations passed and we're on the last step, submit the form
      submitKyc();
      return;
    }

    // If all validations passed, proceed to next step
    setState(() {
      _currentStep += 1;
    });
  }

  // Function to go to previous step
  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Future<void> pickImage(String type) async {
    try {
      // للصورة الشخصية، نفتح الكاميرا الأمامية مباشرة
      if (type == "selfie") {
        await _getImageFromSource(ImageSource.camera, type,
            forceFrontCamera: true);
        return;
      }

      // لباقي أنواع الصور نعرض خيارات الكاميرا والمعرض
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              Text(
                'اختر مصدر الصورة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2530),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'الكاميرا',
                    onTap: () async {
                      Navigator.pop(context);
                      await _getImageFromSource(ImageSource.camera, type);
                    },
                    color: const Color(0xffF5951F),
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'المعرض',
                    onTap: () async {
                      Navigator.pop(context);
                      await _getImageFromSource(ImageSource.gallery, type);
                    },
                    color: const Color(0xFF4F8DF6),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('حدث خطأ أثناء فتح الكاميرا أو المعرض');
    }
  }

  Future<void> _getImageFromSource(ImageSource source, String type,
      {bool forceFrontCamera = false}) async {
    // إذا كانت صورة سيلفي أو تم تحديد استخدام الكاميرا الأمامية إجبارياً
    final CameraDevice camera = (type == "selfie" || forceFrontCamera)
        ? CameraDevice.front
        : CameraDevice.rear;

    try {
      final returnedImage = await ImagePicker().pickImage(
        source: source,
        preferredCameraDevice: camera,
        imageQuality: 80,
      );

      if (returnedImage == null) return;

      setState(() {
        if (type == "passport") {
          passportImage = File(returnedImage.path);
        } else if (type == "residence") {
          residenceImage = File(returnedImage.path);
        } else if (type == "selfie") {
          selfieImage = File(returnedImage.path);
        }
      });
    } catch (e) {
      _showErrorDialog('حدث خطأ أثناء التقاط الصورة');
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> submitKyc() async {
    // تفعيل اهتزاز عند الضغط على الزر
    HapticFeedback.mediumImpact();

    if (!formKey.currentState!.validate()) {
      _showErrorDialog('يرجى إدخال الاسم الكامل');
      return;
    }

    if (passportImage == null ||
        residenceImage == null ||
        selfieImage == null) {
      String missingItem = '';
      if (passportImage == null) {
        missingItem = 'جواز السفر أو بطاقة الهوية';
      } else if (residenceImage == null) {
        missingItem = 'بطاقة السكن أو إثبات الإقامة';
      } else if (selfieImage == null) {
        missingItem = 'صورة سيلفي مع الهوية';
      }
      _showErrorDialog('يرجى التقاط صورة $missingItem');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var data = FormData.fromMap({
        'user_id': userId ?? '0',
        'full_name': fullname.text.trim(),
        'passport': await MultipartFile.fromFile(passportImage!.path,
            filename: "passport.png"),
        'residence': await MultipartFile.fromFile(residenceImage!.path,
            filename: "residence.png"),
        'selfie': await MultipartFile.fromFile(selfieImage!.path,
            filename: "selfie.png"),
      });

      var dio = Dio();
      print('بدء إرسال البيانات إلى الخادم');
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/kyc/add.php',
        data: data,
        options: Options(
          method: 'POST',
          contentType: 'multipart/form-data',
          validateStatus: (status) => true,
        ),
      );

      setState(() {
        isLoading = false;
      });

      print('استجابة الخادم: ${response.statusCode}');
      print('محتوى الاستجابة: ${response.data}');

      // تعديل: نقبل أي استجابة ناجحة من الخادم
      if (response.statusCode == 200 || response.statusCode == 201) {
        // تحديث قيمة kv قبل عرض رسالة النجاح
        await _updateUserKV();
        _showSuccessDialog();
      } else {
        _showErrorDialog('حدث خطأ في استجابة السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      print('خطأ أثناء إرسال البيانات: $e');
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('حدث خطأ أثناء إرسال البيانات، يرجى المحاولة مرة أخرى');
    }
  }

  // دالة منفصلة لتحديث قيمة kv
  Future<void> _updateUserKV() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('user_data');

      print('بيانات المستخدم قبل التحديث: $userJson');

      if (userJson != null) {
        Map<String, dynamic> userData = jsonDecode(userJson);
        userData['kv'] = 2;
        await prefs.setString('user_data', jsonEncode(userData));

        // التحقق من نجاح تحديث البيانات
        String? updatedJson = prefs.getString('user_data');
        print('بيانات المستخدم بعد التحديث: $updatedJson');
      } else {
        print('لم يتم العثور على بيانات المستخدم');
      }
    } catch (e) {
      print('خطأ أثناء تحديث بيانات المستخدم: $e');
    }
  }

  void _showErrorDialog(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle at top
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),

            // Error icon
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade600,
                size: 40.r,
              ),
            ),

            SizedBox(height: 16.h),

            // Title
            Text(
              "خطأ",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12.h),

            // Error message
            Text(
              message,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.sp,
                height: 1.4,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24.h),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF5951F),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
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

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green.shade600,
                size: 50.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "تم الإرسال بنجاح",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          "تم إرسال بيانات التحقق الخاصة بك بنجاح، وسيتم مراجعتها قريبًا.",
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16.sp,
            height: 1.4,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.r),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF5951F),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                "حسنا",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
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
          backgroundColor: const Color(0xFF38659B),
          title: Text(
            'نموذج التحقق من الهوية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_outlined,
              color: Colors.white,
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                // Top blue section
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60.h,
                    color: const Color(0xFF38659B),
                  ),
                ),

                // Main content
                Container(
                  margin: EdgeInsets.only(top: 30.h),
                  child: Column(
                    children: [
                      // Progress indicator
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Row(
                          children: [
                            for (int i = 0; i < 4; i++) ...[
                              Expanded(
                                child: Column(
                                  children: [
                                    // Circle indicator
                                    Container(
                                      width: 32.r,
                                      height: 32.r,
                                      decoration: BoxDecoration(
                                        color: i <= _currentStep
                                            ? const Color(0xFFF5951F)
                                            : Colors.grey.shade300,
                                        shape: BoxShape.circle,
                                        boxShadow: i <= _currentStep
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFFF5951F)
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: i < _currentStep
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                          : Center(
                                              child: Text(
                                                "${i + 1}",
                                                style: TextStyle(
                                                  color: i == _currentStep
                                                      ? Colors.white
                                                      : Colors.grey.shade600,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),

                                    // Step label
                                    SizedBox(height: 8.h),
                                    Text(
                                      _getStepLabel(i),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12.sp,
                                        fontWeight: i == _currentStep
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: i <= _currentStep
                                            ? const Color(0xFF1A2530)
                                            : Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              // Connecting line
                              if (i < 3)
                                Expanded(
                                  child: Container(
                                    height: 2.h,
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 8.w),
                                    color: i < _currentStep
                                        ? const Color(0xFFF5951F)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 30.h),

                      // Content based on current step
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(20.r),
                              child: Form(
                                key: formKey,
                                child: _buildCurrentStepContent(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom navigation buttons
                      Container(
                        padding: EdgeInsets.all(16.r),
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
                          children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _prevStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF38659B),
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      side: const BorderSide(
                                        color: Color(0xFF38659B),
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    "السابق",
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentStep > 0) SizedBox(width: 16.w),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 54.h,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF5951F),
                                      Color(0xFFFF8D16)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF5951F)
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isLoading
                                        ? null
                                        : _currentStep == 3
                                            ? submitKyc
                                            : _nextStep,
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Center(
                                      child: isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  _currentStep == 3
                                                      ? Icons.send_outlined
                                                      : Icons.arrow_forward,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 8.w),
                                                Text(
                                                  _currentStep == 3
                                                      ? "إرسال للتحقق"
                                                      : "التالي",
                                                  style: TextStyle(
                                                    fontFamily: 'Cairo',
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to get step label
  String _getStepLabel(int step) {
    switch (step) {
      case 0:
        return "الأسم كامل";
      case 1:
        return "بطاقة\nالهوية";
      case 2:
        return "إثبات\nالسكن";
      case 3:
        return "صورة\nشخصية";
      default:
        return "";
    }
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A2530),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          validator: (value) =>
              (value == null || value.isEmpty) ? 'يرجى إدخال $label' : null,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15.sp,
            color: const Color(0xFF1A2530),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
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
            prefixIcon: Icon(
              icon,
              color: const Color(0xFFF5951F),
              size: 20.r,
            ),
          ),
        ),
      ],
    );
  }

  // For image upload section when no image selected
  Widget _buildImageSelector({
    required String label,
    required String description,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: image != null ? const Color(0xFFF5951F) : Colors.grey.shade300,
          width: image != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: image != null
                      ? const Color(0xFFF5951F).withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: image != null
                      ? const Color(0xFFF5951F)
                      : Colors.grey.shade500,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2530),
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (image != null)
                Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5951F),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16.r,
                  ),
                ),
            ],
          ),
          if (image != null) ...[
            SizedBox(height: 16.h),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.file(
                    image,
                    height: 150.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8.r,
                  right: 8.r,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (label.contains("جواز")) {
                          passportImage = null;
                        } else if (label.contains("إثبات")) {
                          residenceImage = null;
                        } else if (label.contains("سيلفي") ||
                            label.contains("شخصية")) {
                          selfieImage = null;
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 16.r,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("تغيير الصورة"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF5951F),
                side: const BorderSide(color: Color(0xFFF5951F)),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 16.h),
            InkWell(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.grey.shade500,
                      size: 30.r,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "اضغط لإضافة صورة",
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
          ],
        ],
      ),
    );
  }

  // Build content based on current step
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildIdDocumentStep();
      case 2:
        return _buildResidenceProofStep();
      case 3:
        return _buildSelfieStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Personal Information
  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildStepHeader(
          icon: Icons.person,
          title: "المعلومات الشخصية",
          description:
              "يرجى تقديم معلوماتك الشخصية كما هي مسجلة في وثائق الهوية",
          isFirstStep: true,
        ),

        SizedBox(height: 24.h),

        // Full name field
        _buildInputField(
          label: "الاسم الكامل",
          hint: "أدخل اسمك كما يظهر في وثائق الهوية",
          controller: fullname,
          icon: Icons.person_outline,
        ),

        SizedBox(height: 24.h),

        // Information note
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 20.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "معلومات مهمة",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "تأكد من أن الاسم المدخل يطابق الاسم الموجود في وثائق الهوية تماما لتجنب أي تأخير في عملية التحقق.",
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        height: 1.5,
                        color: Colors.blue.shade800,
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
    );
  }

  // Step 2: ID Document
  Widget _buildIdDocumentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildStepHeader(
          icon: Icons.contact_mail_outlined,
          title: "بطاقة الهوية أو جواز السفر",
          description: "التقط صورة واضحة لوثيقة الهوية الرسمية",
        ),

        SizedBox(height: 20.h),

        // Guidelines
        _buildDocumentGuidelines(),

        SizedBox(height: 24.h),

        // Document selector
        _buildImageSelector(
          label: "جواز السفر أو بطاقة الهوية",
          description: "صورة واضحة لوثيقة هوية رسمية سارية المفعول",
          icon: Icons.contact_mail_outlined,
          image: passportImage,
          onTap: () => pickImage("passport"),
        ),

        SizedBox(height: 40.h),
      ],
    );
  }

  // Step 3: Residence Proof
  Widget _buildResidenceProofStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildStepHeader(
          icon: Icons.home_outlined,
          title: "إثبات السكن",
          description: "قم بتقديم وثيقة تثبت عنوان سكنك الحالي",
        ),

        SizedBox(height: 20.h),

        // Residence document types
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "الوثائق المقبولة",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2530),
                ),
              ),
              SizedBox(height: 16.h),
              _buildAcceptedDocumentItem(
                icon: Icons.receipt_long_outlined,
                title: "فاتورة مرافق",
                description:
                    "فاتورة كهرباء أو مياه أو غاز حديثة (أقل من 3 أشهر)",
              ),
              _buildAcceptedDocumentItem(
                icon: Icons.account_balance_outlined,
                title: "كشف حساب بنكي",
                description: "كشف حساب بنكي حديث يظهر عنوانك (أقل من 3 أشهر)",
              ),
              _buildAcceptedDocumentItem(
                icon: Icons.home_work_outlined,
                title: "عقد إيجار",
                description: "عقد إيجار ساري المفعول",
              ),
            ],
          ),
        ),

        SizedBox(height: 24.h),

        // Document selector
        _buildImageSelector(
          label: "إثبات السكن",
          description: "فاتورة مرافق أو كشف حساب بنكي يظهر عنوانك",
          icon: Icons.home_outlined,
          image: residenceImage,
          onTap: () => pickImage("residence"),
        ),

        SizedBox(height: 40.h),
      ],
    );
  }

  // Step 4: Selfie with ID
  Widget _buildSelfieStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildStepHeader(
          icon: Icons.face_outlined,
          title: "صورة شخصية مع الهوية",
          description: "التقط صورة سيلفي لك وأنت تحمل وثيقة الهوية",
        ),

        SizedBox(height: 20.h),

        // Selfie guidelines
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF5951F).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFF5951F).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: const Color(0xFFF5951F),
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "إرشادات للصورة الشخصية",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF5951F),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildSelfieGuidelineItem("تأكد من ظهور وجهك بوضوح في الصورة"),
              _buildSelfieGuidelineItem(
                  "امسك وثيقة الهوية بجانب وجهك بحيث تكون مقروءة"),
              _buildSelfieGuidelineItem("التقط الصورة في مكان جيد الإضاءة"),
              _buildSelfieGuidelineItem(
                  "تأكد من أن وجهك والوثيقة يظهران في نفس الصورة"),
              _buildSelfieGuidelineItem(
                  "يجب التقاط الصورة بالكاميرا الأمامية فقط ولا يمكن اختيارها من المعرض"),
            ],
          ),
        ),

        SizedBox(height: 24.h),

        // Document selector - تعديل النص للإشارة إلى أن الكاميرا الأمامية فقط مسموح بها
        _buildImageSelector(
          label: "صورة شخصية مع الهوية",
          description:
              "صورة سيلفي لك وأنت تحمل وثيقة الهوية (الكاميرا الأمامية فقط)",
          icon: Icons.face_outlined,
          image: selfieImage,
          onTap: () => pickImage("selfie"),
        ),

        SizedBox(height: 40.h),
      ],
    );
  }

  // Header for each step
  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String description,
    bool isFirstStep = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xffF5951F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: const Color(0xffF5951F),
            size: 24.r,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: isFirstStep ? 20.sp : 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2530),
                  height: 1.3,
                  letterSpacing: isFirstStep ? 0.5 : 0,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Document guidelines widget
  Widget _buildDocumentGuidelines() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF38659B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF38659B).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: const Color(0xFF38659B),
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "إرشادات للصورة",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF38659B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildGuidelineItem("تأكد من وضوح جميع الزوايا وإمكانية قراءة النص"),
          _buildGuidelineItem("تأكد من أن الوثيقة غير منتهية الصلاحية"),
          _buildGuidelineItem(
              "احرص على أن تكون الصورة ملونة وليست باللونين الأبيض والأسود"),
          _buildGuidelineItem("التقط الصورة في مكان جيد الإضاءة"),
        ],
      ),
    );
  }

  // Guideline item
  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check,
            color: const Color(0xFF38659B),
            size: 16.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                height: 1.5,
                color: const Color(0xFF38659B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Selfie guideline item
  Widget _buildSelfieGuidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check,
            color: const Color(0xFFF5951F),
            size: 16.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                height: 1.5,
                color: const Color(0xFFF5951F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Accepted document item
  Widget _buildAcceptedDocumentItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF38659B),
              size: 18.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2530),
                  ),
                ),
                Text(
                  description,
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
    );
  }
}
