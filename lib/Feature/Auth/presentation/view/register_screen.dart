import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/Feature/Auth/presentation/view/regsister_otp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
// ignore: depend_on_referenced_packages
import 'package:uni_country_city_picker/uni_country_city_picker.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

TextEditingController password = TextEditingController();
TextEditingController confirmPassword = TextEditingController();
bool visable = true;
bool visableConfirm = true;
final TextEditingController phoneNumber = TextEditingController();

TextEditingController firstName = TextEditingController();
TextEditingController secondName = TextEditingController();
TextEditingController lastName = TextEditingController();
TextEditingController username = TextEditingController();
TextEditingController email = TextEditingController();

final formKey = GlobalKey<FormState>();

String? selectedCountry;
String countryCode = "+20";
String? selectedCountryIso;
String? selectedCountryFlag;

Map<String, dynamic> formData = {};

bool checked = false;
int selectedGender = 1; // 1 for male, 2 for female

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey termPrivacy = GlobalKey();
  final _uniCountryServices = UniCountryServices.instance;
  List<Country> countriesAndCities = [];

  // Add variables for profile image handling
  File? _profileImage;
  bool _isUploading = false;
  String? _uploadedImageUrl;

  bool isLoading = false;
  bool _passwordUpdated = false;

  // Add Dio instance for API calls
  final Dio _dio = Dio();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _inputFieldAnimations;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
    _getCountriesAndCities();

    // إضافة مستمع لمراقبة تغييرات كلمة المرور
    password.addListener(_onPasswordChanged);

    // تهيئة الانيميشن
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // الانيميشن للحقول - تظهر واحدة تلو الأخرى
    int fieldsCount = 9; // عدد الحقول في النموذج
    _inputFieldAnimations = List.generate(
      fieldsCount,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.1 + (index * 0.05),
            1.0,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    // انيميشن زر الاشتراك
    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  // دالة تُستدعى عند تغيير كلمة المرور
  void _onPasswordChanged() {
    // تفعيل اهتزاز خفيف عند تغيير كلمة المرور
    HapticFeedback.lightImpact();

    // تفعيل إعادة بناء الواجهة عند تغيير كلمة المرور
    setState(() {
      _passwordUpdated = !_passwordUpdated; // تبديل القيمة لضمان تنفيذ setState
    });
  }

  @override
  void dispose() {
    password.removeListener(_onPasswordChanged);
    _animationController.dispose();
    super.dispose();
  }

  // دالة لحساب قوة كلمة المرور
  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0;

    // متطلبات كلمة المرور
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    // حساب قوة كلمة المرور بشكل أكثر دقة
    if (password.isNotEmpty) strength += 0.1;
    if (hasMinLength) strength += 0.2;
    if (hasUppercase) strength += 0.2;
    if (hasLowercase) strength += 0.1;
    if (hasDigits) strength += 0.2;
    if (hasSpecialChars) strength += 0.2;

    // ضمان أن القيمة لا تتجاوز 1.0
    return strength.clamp(0.0, 1.0);
  }

  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase = prefs.getBool('hasSeenShowcase') ?? false;
    if (!hasSeenShowcase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([termPrivacy]);
      });
      await prefs.setBool('hasSeenShowcase', true);
    }
  }

  Future<void> _getCountriesAndCities() async {
    countriesAndCities = await _uniCountryServices.getCountriesAndCities();
    setState(() {});
  }

  Future<void> _showCountryPicker() async {
    if (countriesAndCities.isEmpty) {
      await _getCountriesAndCities();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<Country> filteredCountries = countriesAndCities
                .where((country) => country.name
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
                .toList();
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // قبضة البوتوم شيت
                  Container(
                    width: 50.w,
                    height: 5.h,
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),

                  // عنوان
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Text(
                      'اختر الدولة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF031E4B),
                      ),
                    ),
                  ),

                  // البحث
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: TextField(
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن دولة...',
                          hintTextDirection: TextDirection.rtl,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF031E4B),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),

                  // قائمة الدول
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCountries.length,
                      itemBuilder: (_, i) {
                        Country country = filteredCountries[i];
                        return Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: selectedCountry == country.name
                                ? const Color(0xFFF0F5FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: selectedCountry == country.name
                                  ? const Color(0xFF031E4B)
                                  : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            // عكس ترتيب العناصر في ListTile
                            leading: selectedCountry == country.name
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF031E4B),
                                  )
                                : null,
                            trailing: Text(
                              country.flag,
                              style: TextStyle(fontSize: 24.sp),
                            ),
                            title: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                country.name,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16.sp,
                                  fontWeight: selectedCountry == country.name
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: const Color(0xFF1A2530),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedCountry = country.name;
                                selectedCountryFlag = country.flag;
                                countryCode = country.dialCode;
                                selectedCountryIso = country.isoCode;
                                print(
                                    "🔍 Selected country ISO: ${country.isoCode}, Name: ${country.name}");
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Add image picking functionality
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('التقاط صورة'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo =
                      await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    setState(() {
                      _profileImage = File(photo.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('اختيار من المعرض'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _profileImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add image upload functionality
  Future<String?> _uploadProfileImage() async {
    try {
      setState(() => _isUploading = true);

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          _profileImage!.path,
          filename: _profileImage!.path.split('/').last,
        ),
      });

      print("🔍 بدء رفع صورة الملف الشخصي...");

      final response = await _dio.post(
        'https://ha55a.exchange/api/v1/order/upload.php',
        data: formData,
      );

      print("🔍 استجابة API رفع الصورة: ${response.data}");

      if (response.statusCode == 200 && response.data["success"] == true) {
        final String imageUrl = response.data["url"];
        print("🔍 تم رفع الصورة بنجاح: $imageUrl");
        return imageUrl;
      } else {
        print("🔍 فشل في رفع الصورة: ${response.data["message"]}");
        _showErrorBottomSheet('فشل في رفع الصورة');
        return null;
      }
    } catch (e) {
      print("🔍 خطأ أثناء رفع الصورة: $e");
      _showErrorBottomSheet('حدث خطأ أثناء رفع الصورة');
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Update resister method to include image URL
  void resister() async {
    if (formKey.currentState!.validate()) {
      // Upload profile image if selected
      if (_profileImage != null && _uploadedImageUrl == null) {
        _uploadedImageUrl = await _uploadProfileImage();
        if (_uploadedImageUrl == null) {
          // Upload failed, show error
          return;
        }
      }

      setState(() {
        formData = {
          "firstname": firstName.text,
          "secondname": secondName.text,
          "lastname": lastName.text,
          "username": username.text,
          "email": email.text,
          "country_code": selectedCountryIso ?? "EG",
          "mobile": "${countryCode.replaceAll('+', '')}${phoneNumber.text}",
          "password": password.text,
          "gender": selectedGender,
        };

        // Add image URL if available
        if (_uploadedImageUrl != null) {
          formData["image"] = _uploadedImageUrl;
        }
      });
      print("🔍 Form data: $formData");
      formData.forEach((key, value) {
        print("🔍 $key: $value");
      });
    }
  }

  Future<void> registerRequest() async {
    // Validate the form first
    if (!formKey.currentState!.validate()) {
      _showErrorBottomSheet("يرجى إدخال جميع البيانات المطلوبة بشكل صحيح");
      return;
    }

    // Check if image is selected
    if (_profileImage == null) {
      _showErrorBottomSheet("الصورة الشخصية مطلوبة، يرجى اختيار صورة شخصية");
      return;
    }

    // التحقق من الموافقة على الشروط
    if (!checked) {
      _showErrorBottomSheet(
          "يجب الموافقة على شروط الخدمة وسياسة الخصوصية للاستمرار");
      return;
    }

    try {
      // If profile image is selected but not yet uploaded, upload it now
      if (_profileImage != null && _uploadedImageUrl == null) {
        setState(() => isLoading = true);
        _uploadedImageUrl = await _uploadProfileImage();
        setState(() => isLoading = false);
        if (_uploadedImageUrl == null) {
          // Upload failed, show error
          return;
        }
      }

      resister();

      var headers = {'Content-Type': 'application/json'};
      var dio = Dio();

      if (formData.isEmpty) {
        _showErrorBottomSheet("الرجاء إدخال جميع البيانات المطلوبة.");
        return;
      }

      setState(() => isLoading = true);
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/auth/register.php',
        options: Options(headers: headers),
        data: formData,
      );
      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        developer.log('Success: ${json.encode(response.data)}');
        if (context.mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  Regsisterotp(
                mobileNumber: formData['mobile'].toString(),
                email: email.text,
                password: password.text,
              ),
              transitionDuration: const Duration(milliseconds: 800),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var curve = Curves.easeInOutCubic;
                var curveTween =
                    CurvedAnimation(parent: animation, curve: curve);

                return Stack(
                  children: [
                    // تأثير تلاشي الصفحة الحالية
                    FadeTransition(
                      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                        CurvedAnimation(
                          parent: secondaryAnimation,
                          curve:
                              const Interval(0.0, 0.5, curve: Curves.easeOut),
                        ),
                      ),
                      child: secondaryAnimation.value > 0.5
                          ? Container()
                          : Container(color: Colors.white),
                    ),
                    // انزلاق وظهور الصفحة الجديدة
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(curveTween),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve:
                                const Interval(0.3, 1.0, curve: Curves.easeOut),
                          ),
                        ),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.9, end: 1.0)
                              .animate(curveTween),
                          child: child,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ).then((result) {
            // استعادة البيانات عند العودة من صفحة OTP
            if (result != null && result is Map) {
              setState(() {
                // تحديث القيم في النموذج بناءً على البيانات المعادة
                if (result.containsKey('email')) {
                  email.text = result['email'] ?? email.text;
                }
                if (result.containsKey('mobile')) {
                  String mobileValue = result['mobile'] ?? '';
                  // تحديث رقم الهاتف بالطريقة المناسبة
                  if (mobileValue.isNotEmpty) {
                    // استخراج رمز البلد من الرقم
                    String extractedCountryCode =
                        "+${mobileValue.substring(0, 2)}";
                    String phone = mobileValue.substring(2);

                    // تحديث حقول النموذج
                    phoneNumber.text = phone;
                    countryCode = extractedCountryCode; // تحديث المتغير العام
                  }
                }
                if (result.containsKey('password')) {
                  password.text = result['password'] ?? password.text;
                  confirmPassword.text =
                      result['password'] ?? confirmPassword.text;
                }
              });

              // تحديث قوة كلمة المرور إذا تم تغييرها
              if (result.containsKey('password')) {
                _onPasswordChanged();
              }
            }
          });
        }
      } else {
        String errorMessage =
            response.data['error'] ?? "فشل التسجيل، حاول مرة أخرى.";
        _showErrorBottomSheet(errorMessage);
        developer.log('API Error: ${json.encode(response.data)}');
      }
    } on DioException catch (e) {
      String errorMessage =
          e.response?.data['error'] ?? "فشل في تسجيل الحساب. حاول مرة أخرى.";

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "فشل الاتصال بالخادم. تحقق من اتصال الإنترنت.";
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = "تعذر الاتصال بالخادم. حاول مرة أخرى لاحقًا.";
      } else if (e.type == DioExceptionType.cancel) {
        errorMessage = "تم إلغاء الطلب.";
      }

      _showErrorBottomSheet(errorMessage);
      developer.log("Dio error: ${e.message}");
    } catch (e, stackTrace) {
      developer.log("Unexpected error: $e");
      developer.log("StackTrace: $stackTrace");
      _showErrorBottomSheet("حدث خطأ غير متوقع. حاول مرة أخرى.");
    }
  }

  void _showErrorBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet handle
              Container(
                width: 50.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),

              // Error icon
              Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.redAccent.shade100.withOpacity(0.3),
                      Colors.red.shade50,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_rounded,
                  color: Colors.red.shade500,
                  size: 50.sp,
                ),
              ),

              SizedBox(height: 24.h),

              // Error title with animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Text(
                  "حدث خطأ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A2530),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Error message
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF646464),
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Confirmation button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF031E4B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                ),
                child: Text(
                  'حسنًا',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isTablet = width > 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'إنشاء حساب جديد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isTablet ? 22.sp : 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: false,
        ),
        body: Stack(
          children: [
            // خلفية بيضاء للشاشة بالكامل
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
            ),

            // خلفية جزئية متدرجة للجزء العلوي فقط
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 220.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF031E4B),
                      const Color(0xFF042C6A),
                      const Color(0xFF095EB2).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25.r),
                    bottomRight: Radius.circular(25.r),
                  ),
                ),
              ),
            ),

            // زخارف متحركة
            Positioned(
              top: 50.h,
              right: -50.w,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      15 * sin(_animationController.value * 2 * pi),
                      0,
                    ),
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 120.h,
              left: -20.w,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      10 * cos(_animationController.value * 2 * pi),
                    ),
                    child: Opacity(
                      opacity: 0.08,
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // محتوى الصفحة
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 15.h),

                      // أيقونة الحساب المتحركة مع إمكانية تحديد صورة
                      Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Stack(
                            children: [
                              // Profile image container
                              Container(
                                width: 100.w,
                                height: 100.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _profileImage != null
                                      ? Image.file(
                                          _profileImage!,
                                          width: 100.w,
                                          height: 100.h,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                            Icons.person_add_rounded,
                                            size: 50.sp,
                                            color: const Color(0xFF031E4B),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person_add_rounded,
                                          size: 50.sp,
                                          color: const Color(0xFF031E4B),
                                        ),
                                ),
                              ),

                              // Edit button
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isUploading ? null : _pickImage,
                                  child: Container(
                                    width: 30.r,
                                    height: 30.r,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF031E4B),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.w,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isUploading
                                          ? SizedBox(
                                              width: 15.r,
                                              height: 15.r,
                                              child:
                                                  const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              Icons.add_a_photo,
                                              size: 16.r,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // نص ترحيبي
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            padding: EdgeInsets.all(16.sp),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(15.r),
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
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'أهلاً بك',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: isTablet ? 24.sp : 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF031E4B),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'قم بإكمال معلوماتك الشخصية لإنشاء حساب جديد',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: isTablet ? 18.sp : 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF646464),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 25.h),

                      // نموذج التسجيل
                      Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // الاسم الأول والأخير
                            FadeTransition(
                              opacity: _inputFieldAnimations[0],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.1, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 16.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8.sp),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            controller: firstName,
                                            label: 'الاسم الأول',
                                            icon: Icons.person_outline,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return "يرجى إدخال الاسم الأول";
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: _buildInputField(
                                            controller: secondName,
                                            label: 'اسم الأب',
                                            icon: Icons.person_outline,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return "يرجى إدخال اسم الأب";
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // اسم العائلة
                            FadeTransition(
                              opacity: _inputFieldAnimations[1],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.15, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: _buildSingleInputContainer(
                                  child: _buildInputField(
                                    controller: lastName,
                                    label: 'اسم العائلة',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "يرجى إدخال اسم العائلة";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // اسم المستخدم
                            FadeTransition(
                              opacity: _inputFieldAnimations[2],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.2, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: _buildSingleInputContainer(
                                  child: _buildInputField(
                                    controller: username,
                                    label: 'اسم المستخدم',
                                    icon: Icons.alternate_email,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "يرجى إدخال اسم المستخدم";
                                      }
                                      // تحقق من أن اسم المستخدم يحتوي على أحرف انجليزية وأرقام فقط
                                      if (!RegExp(r'^[a-zA-Z0-9]+$')
                                          .hasMatch(value)) {
                                        return "يجب أن يحتوي اسم المستخدم على أحرف انجليزية وأرقام فقط";
                                      }
                                      // تحقق من طول اسم المستخدم
                                      if (value.length < 6) {
                                        return "يجب أن يكون اسم المستخدم ٦ أحرف على الأقل";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // البريد الإلكتروني
                            FadeTransition(
                              opacity: _inputFieldAnimations[3],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.25, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: _buildSingleInputContainer(
                                  child: _buildInputField(
                                    controller: email,
                                    label: 'البريد الإلكتروني',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "يرجى إدخال البريد الإلكتروني";
                                      } else if (!RegExp(
                                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                          .hasMatch(value)) {
                                        return "يرجى إدخال بريد إلكتروني صالح";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // اختيار الدولة
                            FadeTransition(
                              opacity: _inputFieldAnimations[4],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.3, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: _buildSingleInputContainer(
                                  child: InkWell(
                                    onTap: _showCountryPicker,
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 15.h,
                                        horizontal: 16.w,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        color: const Color(0xFFF8F9FD),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.flag_outlined,
                                            size: 22.sp,
                                            color: const Color(0xFF031E4B),
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Text(
                                              selectedCountry != null
                                                  ? "${selectedCountryFlag ?? ''} ${selectedCountry!}"
                                                  : 'اختر دولة',
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 16.sp,
                                                color: selectedCountry != null
                                                    ? const Color(0xFF1C2439)
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // رقم الهاتف
                            FadeTransition(
                              opacity: _inputFieldAnimations[5],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.35, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: _buildSingleInputContainer(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 14.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F4FA),
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        child: Text(
                                          countryCode,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: const Color(0xFF031E4B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: _buildInputField(
                                          controller: phoneNumber,
                                          label: 'رقم الهاتف',
                                          icon: Icons.phone_android_outlined,
                                          keyboardType: TextInputType.phone,
                                          hintText:
                                              'أدخل الرقم بدون الصفر في البداية',
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return "يرجى إدخال رقم الهاتف";
                                            }
                                            if (value.startsWith('0')) {
                                              return "يجب أن لا يبدأ الرقم بصفر";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // كلمة المرور
                            FadeTransition(
                              opacity: _inputFieldAnimations[6],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.4, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: _buildSingleInputContainer(
                                  child: _buildPasswordField(
                                    controller: password,
                                    label: 'كلمة المرور',
                                    isVisible: visable,
                                    toggleVisibility: () {
                                      setState(() {
                                        visable = !visable;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.length < 8) {
                                        return "يجب أن تتكون كلمة المرور من 8 أحرف على الأقل";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // قياس قوة كلمة المرور
                            if (password.text.isNotEmpty)
                              FadeTransition(
                                opacity: _inputFieldAnimations[6],
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 15.w, vertical: 8.h),
                                  child: _buildPasswordStrengthIndicator(
                                      password.text),
                                ),
                              ),

                            // تأكيد كلمة المرور
                            FadeTransition(
                              opacity: _inputFieldAnimations[7],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.45, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: _buildSingleInputContainer(
                                  child: _buildPasswordField(
                                    controller: confirmPassword,
                                    label: 'تأكيد كلمة المرور',
                                    isVisible: visableConfirm,
                                    toggleVisibility: () {
                                      setState(() {
                                        visableConfirm = !visableConfirm;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "يرجى تأكيد كلمة المرور";
                                      } else if (value != password.text) {
                                        return "كلمة المرور غير متطابقة";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // اختيار الجنس
                            FadeTransition(
                              opacity: _inputFieldAnimations[7],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.5, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: _buildSingleInputContainer(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.w, vertical: 8.h),
                                        child: Text(
                                          'الجنس',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF646464),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: RadioListTile<int>(
                                              value: 1,
                                              groupValue: selectedGender,
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedGender = value!;
                                                });
                                              },
                                              title: Text(
                                                'ذكر',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              activeColor:
                                                  const Color(0xFF031E4B),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8.w),
                                              dense: true,
                                            ),
                                          ),
                                          Expanded(
                                            child: RadioListTile<int>(
                                              value: 2,
                                              groupValue: selectedGender,
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedGender = value!;
                                                });
                                              },
                                              title: Text(
                                                'أنثى',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              activeColor:
                                                  const Color(0xFF031E4B),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8.w),
                                              dense: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // شروط الخدمة
                            FadeTransition(
                              opacity: _inputFieldAnimations[7],
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.5, 0.9,
                                        curve: Curves.easeOut),
                                  ),
                                ),
                                child: Showcase(
                                  key: termPrivacy,
                                  description:
                                      'الموافقة على شروط الخدمة وسياسة الخصوصية إلزامية للاستمرار',
                                  descTextStyle: TextStyle(
                                    fontSize: 14.sp,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  tooltipBackgroundColor:
                                      const Color(0xFF031E4B),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: checked
                                          ? const Color(0xFFF0F5FF)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(15.r),
                                      border: Border.all(
                                        color: checked
                                            ? const Color(0xFF031E4B)
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Transform.scale(
                                          scale: 1,
                                          child: Checkbox(
                                            value: checked,
                                            activeColor:
                                                const Color(0xFF031E4B),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                checked = value ?? true;
                                              });
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'أوافق على',
                                                  style: TextStyle(
                                                    fontFamily: 'Cairo',
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w400,
                                                    color:
                                                        const Color(0xFF646464),
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  // عرض سياسة الخصوصية
                                                },
                                                child: Text(
                                                  'سياسة الخصوصية',
                                                  style: TextStyle(
                                                    fontFamily: 'Cairo',
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        const Color(0xFF031E4B),
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                ' و',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w400,
                                                  color:
                                                      const Color(0xFF646464),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  // عرض شروط الخدمة
                                                },
                                                child: Text(
                                                  'شروط الخدمة',
                                                  style: TextStyle(
                                                    fontFamily: 'Cairo',
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        const Color(0xFF031E4B),
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
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
                            ),

                            SizedBox(height: 24.h),

                            // زر الإشتراك
                            ScaleTransition(
                              scale: _buttonAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.5),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(0.6, 1.0,
                                        curve: Curves.easeOutBack),
                                  ),
                                ),
                                child: Container(
                                  height: 55.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF031E4B)
                                            .withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF031E4B),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.r),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (!checked) {
                                        // إظهار رسالة خطأ إذا لم يتم الموافقة على الشروط
                                        _showErrorBottomSheet(
                                            "يجب الموافقة على شروط الخدمة وسياسة الخصوصية للاستمرار");
                                        return;
                                      }

                                      if (formKey.currentState!.validate()) {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        await registerRequest();
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'إنشاء حساب',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 20.sp,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // زر تسجيل الدخول
                            FadeTransition(
                              opacity: _inputFieldAnimations[7],
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'لديك حساب بالفعل؟ ',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF4F4F4F),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF031E4B),
                                    ),
                                    child: Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF031E4B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading Overlay
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(25.sp),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF031E4B),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'جاري إنشاء الحساب...',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16.sp,
        color: const Color(0xFF1C2439),
      ),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: Colors.grey.shade500,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF646464),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF031E4B),
          size: 22.sp,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(
            color: Color(0xFF031E4B),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      validator: validator,
    );
  }

  Widget _buildSingleInputContainer({required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8.sp),
        child: child,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    String? Function(String?)? validator,
  }) {
    Color getBorderColor() {
      if (controller.text.isEmpty) return Colors.grey.shade200;

      double strength = _calculatePasswordStrength(controller.text);

      if (strength <= 0.25) return Colors.red.shade400;
      if (strength <= 0.5) return Colors.orange.shade400;
      if (strength <= 0.75) return Colors.yellow.shade700;
      return Colors.green.shade500;
    }

    return TextFormField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16.sp,
        color: const Color(0xFF1C2439),
      ),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      obscureText: isVisible,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        alignLabelWithHint: true,
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF646464),
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: const Color(0xFF031E4B),
          size: 22.sp,
        ),
        suffixIcon: IconButton(
          onPressed: toggleVisibility,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              key: ValueKey<bool>(isVisible),
              color: const Color(0xFF031E4B),
              size: 22.sp,
            ),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: getBorderColor(),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: getBorderColor(),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    double strength = _calculatePasswordStrength(password);

    // متطلبات كلمة المرور
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars =
        password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

    // ألوان لقوة كلمة المرور
    Color getColor() {
      if (strength <= 0.25) return Colors.red.shade400;
      if (strength <= 0.5) return Colors.orange.shade400;
      if (strength <= 0.75) return Colors.yellow.shade700;
      return Colors.green.shade500;
    }

    // وصف قوة كلمة المرور
    String getText() {
      if (strength <= 0.1) return 'غير آمنة';
      if (strength <= 0.25) return 'ضعيفة جداً';
      if (strength <= 0.5) return 'ضعيفة';
      if (strength <= 0.75) return 'متوسطة';
      if (strength <= 0.9) return 'جيدة';
      return 'قوية';
    }

    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 16.sp,
                    color: getColor(),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'قوة كلمة المرور:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: getColor(),
                ),
                child: Text(getText()),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: Tween<double>(begin: 0, end: strength),
            builder: (context, value, _) => Stack(
              children: [
                Container(
                  height: 6.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                Container(
                  height: 6.h,
                  width: value * MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: getColor(),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: getColor().withOpacity(0.4),
                        blurRadius: value > 0.5 ? 5 : 0,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // معايير قوة كلمة المرور
          SizedBox(height: 10.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCriteriaRow(hasMinLength, '٨ أحرف على الأقل'),
              _buildCriteriaRow(hasUppercase, 'حرف كبير (A-Z)'),
              _buildCriteriaRow(hasLowercase, 'حرف صغير (a-z)'),
              _buildCriteriaRow(hasDigits, 'رقم واحد على الأقل (0-9)'),
              _buildCriteriaRow(hasSpecialChars, 'رمز خاص (!@#\$)'),
            ],
          ),
        ],
      ),
    );
  }

  // معيار قوة كلمة المرور
  Widget _buildCriteriaRow(bool criteria, String text) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 18.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: criteria
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                criteria ? Icons.check : Icons.close,
                size: 12.sp,
                color: criteria ? Colors.green : Colors.grey,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: criteria ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
