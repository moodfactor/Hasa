import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'twofa_screen.dart';
import 'screens/pin_setup_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController secondNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  // Gender variable
  int gender = 0; // 1 for male, 2 for female
  String genderText = 'ذكر';
  // Address controllers
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  String? phoneNumber;
  String? profileImageUrl;
  File? _profileImage;
  bool _isUploading = false;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSubmitting = false;
  final Dio _dio = Dio();

  // KYC verification status
  bool _isKycVerified = false;
  int _kycValue = 0;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutQuint),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    secondNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    // Dispose address controllers
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipController.dispose();
    countryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      Map<String, dynamic> userData = jsonDecode(userJson);

      // Parse address JSON if it exists
      if (userData['address'] != null) {
        try {
          Map<String, dynamic> addressData = jsonDecode(userData['address']);
          addressController.text = addressData['address'] ?? '';
          cityController.text = addressData['city'] ?? '';
          stateController.text = addressData['state'] ?? '';
          zipController.text = addressData['zip'] ?? '';
          countryController.text = addressData['country'] ?? '';
        } catch (e) {
          // Handle parsing error
          print('Error parsing address: $e');
        }
      }

      setState(() {
        firstNameController.text = userData['firstname'] ?? '';
        secondNameController.text = userData['secondname'] ?? '';
        lastNameController.text = userData['lastname'] ?? '';
        usernameController.text = userData['username'] ?? '';
        phoneNumber = userData['mobile'];
        emailController.text = userData['email'] ?? '';

        // Check for image URL in various possible fields
        profileImageUrl = userData['profile_image'] ??
            userData['image'] ??
            userData['image_url'] ??
            userData['profile_picture'];

        print("🔍 Loaded image URL: $profileImageUrl");
        print("🔍 User data keys: ${userData.keys.toList()}");
        print("🔍 User data: $userData");

        // Set gender value and text
        gender = userData['gender'] ?? 1;
        genderText = gender == 1 ? 'ذكر' : 'أنثى';

        // Get KYC verification status (0 = not verified, 1 = verified)
        _kycValue = userData['kv'] ?? 0;
        _isKycVerified = _kycValue == 1;
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // First upload profile image if one is selected
      String? uploadedImageUrl;
      if (_profileImage != null) {
        setState(() => _isUploading = true);
        uploadedImageUrl = await _uploadProfileImage();
        setState(() => _isUploading = false);
      }

      var data = FormData.fromMap({
        'email': emailController.text.trim(),
        'firstname': firstNameController.text.trim(),
        'secondname': secondNameController.text.trim(),
        'lastname': lastNameController.text.trim(),
        'username': usernameController.text.trim(),
        // Add address fields
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'zip': zipController.text.trim(),
        'country': countryController.text.trim(),
        if (uploadedImageUrl != null) 'image': uploadedImageUrl,
      });

      print("🔍 إرسال بيانات تحديث الملف الشخصي مع معلمات:");
      data.fields.forEach((field) {
        print("🔍 ${field.key}: ${field.value}");
      });

      _dio.options.headers = {
        'Accept': 'application/json',
      };

      var response = await _dio.post(
        'https://ha55a.exchange/api/v1/auth/edit.php',
        data: data,
      );

      print("🔍 استجابة API التحديث: ${response.data}");

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        // استخراج رابط الصورة من الاستجابة إذا كان متاحاً
        String? returnedImageUrl = response.data['image_url'];

        // استخدام الرابط المُرجع من الاستجابة إذا كان متاحاً، وإلا استخدام الرابط المُرفوع
        String? finalImageUrl = returnedImageUrl ?? uploadedImageUrl;

        // طباعة رابط الصورة النهائي
        if (finalImageUrl != null) {
          print("🔍 رابط الصورة النهائي المستخدم: $finalImageUrl");
        }

        await _updateUserDataInCache(finalImageUrl);
        _showSuccessMessage('تم تحديث البيانات بنجاح');
      } else {
        print("🔍 خطأ في تحديث البيانات: ${response.data['message']}");
        _showErrorMessage(response.data['message'] ?? 'حدث خطأ غير متوقع');
      }
    } catch (e) {
      print("🔍 استثناء أثناء تحديث البيانات: $e");
      _showErrorMessage('حدث خطأ أثناء الاتصال. الرجاء المحاولة لاحقًا.');
    }

    setState(() => _isSubmitting = false);
  }

  Future<String?> _uploadProfileImage() async {
    try {
      // Mostrar el indicador de carga
      setState(() => _isUploading = true);

      // Crear FormData con la imagen para upload.php
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          _profileImage!.path,
          filename: _profileImage!.path.split('/').last,
        ),
      });

      print("🔍 بدء رفع الصورة...");

      // Realizar la solicitud a la API de carga
      final response = await _dio.post(
        'https://ha55a.exchange/api/v1/order/upload.php',
        data: formData,
      );

      // طباعة الاستجابة الكاملة للتصحيح
      print("🔍 استجابة API كاملة: ${response.data}");

      // Verificar la respuesta
      if (response.statusCode == 200 && response.data["success"] == true) {
        // Extraer la URL de la imagen subida
        final String imageUrl = response.data["url"];

        // طباعة رابط الصورة المُرجع
        print("🔍 رابط الصورة المرفوعة: $imageUrl");
        print("===========================================");
        print("🔍 SUCCESS: ${response.data["success"]}");
        print("🔍 URL: $imageUrl");
        print("===========================================");

        // Mostrar mensaje de éxito
        _showSuccessMessage('تم رفع الصورة بنجاح');

        return imageUrl;
      } else {
        // طباعة رسالة الخطأ
        print("🔍 فشل في رفع الصورة: ${response.data["message"]}");

        // Mostrar mensaje de error
        _showErrorMessage('فشل في رفع الصورة');
        return null;
      }
    } catch (e) {
      // طباعة الاستثناء
      print("🔍 خطأ أثناء رفع الصورة: $e");

      // Manejar excepciones
      _showErrorMessage('حدث خطأ أثناء رفع الصورة');
      return null;
    } finally {
      // Ocultar el indicador de carga
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _updateUserDataInCache([String? newProfileImage]) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    Map<String, dynamic> updatedData = {};

    if (userJson != null) {
      updatedData = jsonDecode(userJson);
    }

    updatedData['firstname'] = firstNameController.text.trim();
    updatedData['secondname'] = secondNameController.text.trim();
    updatedData['lastname'] = lastNameController.text.trim();
    updatedData['username'] = usernameController.text.trim();
    updatedData['email'] = emailController.text.trim();

    // Update address in cache
    Map<String, dynamic> addressData = {
      'address': addressController.text.trim(),
      'city': cityController.text.trim(),
      'state': stateController.text.trim(),
      'zip': zipController.text.trim(),
      'country': countryController.text.trim(),
    };
    updatedData['address'] = jsonEncode(addressData);

    if (newProfileImage != null) {
      // تحديث حقل profile_image في البيانات المحلية
      updatedData['profile_image'] = newProfileImage;
      // Also store as 'image' for compatibility
      updatedData['image'] = newProfileImage;

      // تحديث المتغير لعرض الصورة فوراً
      setState(() {
        profileImageUrl = newProfileImage;
      });

      print("🔍 تم تحديث رابط الصورة في البيانات المحلية: $newProfileImage");
    }

    prefs.setString('user_data', jsonEncode(updatedData));
    print("🔍 تم حفظ البيانات المحدثة في التخزين المحلي");
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFFF97316),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(15.r),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(15.r),
      ),
    );
  }

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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isReadOnly = false,
    String? Function(String?)? validator,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 12.h),
          TextFormField(
            controller: controller,
            readOnly: isReadOnly,
            style: TextStyle(
              fontSize: 15.sp,
              color: isReadOnly
                  ? const Color(0xFF718096)
                  : const Color(0xFF2D3748),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
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
                  color: const Color(0xFFE2E8F0),
                  width: 1.w,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: iconColor ?? const Color(0xFFF97316),
                  width: 1.5.w,
                ),
              ),
              prefixIcon: Container(
                margin: EdgeInsets.only(right: 12.w, left: 8.w),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFFF97316),
                  size: 20.r,
                ),
              ),
              hintText: isReadOnly ? '' : 'أدخل $label',
              hintStyle: TextStyle(
                color: const Color(0xFFA0AEC0),
                fontSize: 14.sp,
              ),
            ),
            validator: isReadOnly
                ? null
                : (validator ??
                    (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال $label';
                      }
                      return null;
                    }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_forward_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'الملف الشخصي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF97316), // Orange primary
                  Color(0xFFEA580C), // Darker orange
                ],
              ),
            ),
            height: MediaQuery.of(context).size.height * 0.28,
          ),

          // Shimmer pattern effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.28,
              child: CustomPaint(
                painter: ShimmerPatternPainter(),
                size: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.28),
              ),
            ),
          ),

          Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            children: [
                              SizedBox(height: 30.h),
                              // Profile Image and Username Section
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: Row(
                                  children: [
                                    // Profile Image with Edit Button
                                    _buildProfileImageWithEditButton(),
                                    SizedBox(width: 15.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            usernameController.text,
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 3,
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 6.h),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.email,
                                                color: Colors.white70,
                                                size: 16,
                                              ),
                                              SizedBox(width: 6.w),
                                              Expanded(
                                                child: Text(
                                                  emailController.text,
                                                  style: TextStyle(
                                                    fontFamily: 'Cairo',
                                                    fontSize: 14.sp,
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 40.h),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(32.r),
                                        topRight: Radius.circular(32.r),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, -5),
                                        )
                                      ]),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Padding(
                                      padding: EdgeInsets.all(24.r),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // KYC verification message
                                            if (_isKycVerified)
                                              Container(
                                                margin: EdgeInsets.only(
                                                    bottom: 24.h),
                                                padding: EdgeInsets.all(16.r),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFFEF9C3),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16.r),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFFFACC15),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFFCA8A04)
                                                          .withOpacity(0.1),
                                                      blurRadius: 8,
                                                      spreadRadius: 0,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          EdgeInsets.all(8.r),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFFEF08A),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12.r),
                                                      ),
                                                      child: const Icon(
                                                        Icons.verified_user,
                                                        color:
                                                            Color(0xFFCA8A04),
                                                        size: 20,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12.w),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'حساب موثّق',
                                                            style: TextStyle(
                                                              fontSize: 16.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: const Color(
                                                                  0xFFCA8A04),
                                                            ),
                                                          ),
                                                          SizedBox(height: 4.h),
                                                          Text(
                                                            'تم تفعيل حسابك من خلال KYC، لا يمكن تغيير معلومات الاسم أثناء فترة التحقق.',
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color: const Color(
                                                                  0xFFCA8A04),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.person,
                                                  color: Color(0xFFF97316),
                                                  size: 22,
                                                ),
                                                SizedBox(width: 10.w),
                                                Text(
                                                  'المعلومات الشخصية',
                                                  style: TextStyle(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        const Color(0xFF2D3748),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 20.h),

                                            // Personal Information Fields
                                            _buildInputField(
                                              label: 'الاسم الأول',
                                              controller: firstNameController,
                                              icon: Icons.person_outline,
                                              isReadOnly: _isKycVerified,
                                            ),
                                            _buildInputField(
                                              label: 'اسم الأب',
                                              controller: secondNameController,
                                              icon: Icons.person_outline,
                                              isReadOnly: _isKycVerified,
                                            ),
                                            _buildInputField(
                                              label: 'اسم العائلة',
                                              controller: lastNameController,
                                              icon: Icons.person_outline,
                                              isReadOnly: _isKycVerified,
                                            ),

                                            // Add gender field
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 10,
                                                    spreadRadius: 0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.all(16.r),
                                              margin:
                                                  EdgeInsets.only(bottom: 16.h),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'الجنس',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                          0xFF2D3748),
                                                    ),
                                                  ),
                                                  SizedBox(height: 12.h),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 16.w,
                                                      vertical: 16.h,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF8FAFC),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.r),
                                                      border: Border.all(
                                                        color: const Color(
                                                            0xFFE2E8F0),
                                                        width: 1.w,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  right: 12.w,
                                                                  left: 8.w),
                                                          child: Icon(
                                                            gender == 1
                                                                ? Icons.male
                                                                : Icons.female,
                                                            color: gender == 1
                                                                ? Colors.blue
                                                                : Colors.pink,
                                                            size: 20.r,
                                                          ),
                                                        ),
                                                        Text(
                                                          genderText,
                                                          style: TextStyle(
                                                            fontSize: 15.sp,
                                                            color: const Color(
                                                                0xFF718096),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: 24.h),

                                            // Address section
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  color: Color(0xFFF97316),
                                                  size: 22,
                                                ),
                                                SizedBox(width: 10.w),
                                                Text(
                                                  'معلومات العنوان',
                                                  style: TextStyle(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        const Color(0xFF2D3748),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 20.h),

                                            // Address Fields
                                            _buildInputField(
                                              label: 'العنوان',
                                              controller: addressController,
                                              icon: Icons.home_outlined,
                                            ),
                                            _buildInputField(
                                              label: 'المدينة',
                                              controller: cityController,
                                              icon: Icons.location_city,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'الرجاء إدخال المدينة';
                                                }
                                                // Check if contains numbers
                                                if (value.contains(
                                                    RegExp(r'[0-9]'))) {
                                                  return 'المدينة يجب أن تحتوي على حروف فقط';
                                                }
                                                return null;
                                              },
                                            ),
                                            _buildInputField(
                                              label: 'المنطقة/الولاية',
                                              controller: stateController,
                                              icon: Icons.map_outlined,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'الرجاء إدخال المنطقة/الولاية';
                                                }
                                                // Check if contains numbers
                                                if (value.contains(
                                                    RegExp(r'[0-9]'))) {
                                                  return 'المنطقة/الولاية يجب أن تحتوي على حروف فقط';
                                                }
                                                return null;
                                              },
                                            ),
                                            _buildInputField(
                                              label: 'الرمز البريدي',
                                              controller: zipController,
                                              icon: Icons
                                                  .markunread_mailbox_outlined,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'الرجاء إدخال الرمز البريدي';
                                                }
                                                // Check if contains only numbers
                                                if (!RegExp(r'^[0-9]+$')
                                                    .hasMatch(value)) {
                                                  return 'الرمز البريدي يجب أن يحتوي على أرقام فقط';
                                                }
                                                return null;
                                              },
                                            ),
                                            _buildInputField(
                                              label: 'الدولة',
                                              controller: countryController,
                                              icon: Icons.public,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'الرجاء إدخال الدولة';
                                                }
                                                // Check if contains numbers
                                                if (value.contains(
                                                    RegExp(r'[0-9]'))) {
                                                  return 'الدولة يجب أن تحتوي على حروف فقط';
                                                }
                                                return null;
                                              },
                                            ),

                                            SizedBox(height: 24.h),

                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.contact_phone,
                                                  color: Color(0xFFF97316),
                                                  size: 22,
                                                ),
                                                SizedBox(width: 10.w),
                                                Text(
                                                  'معلومات الاتصال',
                                                  style: TextStyle(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        const Color(0xFF2D3748),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 20.h),

                                            // Contact Information Fields
                                            _buildInputField(
                                              label: 'اسم المستخدم',
                                              controller: usernameController,
                                              icon: Icons.alternate_email,
                                              isReadOnly: true,
                                              iconColor:
                                                  const Color(0xFF718096),
                                            ),
                                            _buildInputField(
                                              label: 'البريد الإلكتروني',
                                              controller: emailController,
                                              icon: Icons.email_outlined,
                                              isReadOnly: true,
                                              iconColor:
                                                  const Color(0xFF718096),
                                            ),

                                            // Phone Number Field
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 10,
                                                    spreadRadius: 0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.all(16.r),
                                              margin:
                                                  EdgeInsets.only(bottom: 32.h),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'رقم الجوال',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                          0xFF2D3748),
                                                    ),
                                                  ),
                                                  SizedBox(height: 12.h),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 16.w,
                                                      vertical: 16.h,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF8FAFC),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.r),
                                                      border: Border.all(
                                                        color: const Color(
                                                            0xFFE2E8F0),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.phone_android,
                                                          color: const Color(
                                                              0xFF718096),
                                                          size: 20.r,
                                                        ),
                                                        SizedBox(width: 12.w),
                                                        Text(
                                                          phoneNumber ??
                                                              'جاري التحميل...',
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            color: const Color(
                                                                0xFF2D3748),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Security Settings Section
                                            Container(
                                              margin:
                                                  EdgeInsets.only(top: 16.h),
                                              padding: EdgeInsets.all(16.r),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 10.r,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'إعدادات الأمان',
                                                    style: TextStyle(
                                                      fontSize: 18.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 16.h),

                                                  // Two-Factor Authentication
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const TwoFactorAuthScreen(),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(12.r),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.grey.shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.r),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8.r),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                      0xFF5E72E4)
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.r),
                                                            ),
                                                            child: const Icon(
                                                              Icons.security,
                                                              color: Color(
                                                                  0xFF5E72E4),
                                                            ),
                                                          ),
                                                          SizedBox(width: 12.w),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'المصادقة الثنائية',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        4.h),
                                                                Text(
                                                                  'تأمين حسابك باستخدام المصادقة الثنائية',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        14.sp,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const Icon(
                                                            Icons.chevron_right,
                                                            color: Colors.grey,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  // PIN Lock Security
                                                  SizedBox(height: 12.h),
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const PinSetupScreen(),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(12.r),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.grey.shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.r),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8.r),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                      0xFFFB6340)
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.r),
                                                            ),
                                                            child: const Icon(
                                                              Icons.pin,
                                                              color: Color(
                                                                  0xFFFB6340),
                                                            ),
                                                          ),
                                                          SizedBox(width: 12.w),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'رمز PIN',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        4.h),
                                                                Text(
                                                                  'إعداد رمز PIN لتأمين الوصول إلى التطبيق',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        14.sp,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const Icon(
                                                            Icons.chevron_right,
                                                            color: Colors.grey,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  // ... existing code ...
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: 24.h),

                                            // Save Button
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFF97316),
                                                    Color(0xFFEA580C),
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFFF97316)
                                                            .withOpacity(0.3),
                                                    blurRadius: 12,
                                                    spreadRadius: 0,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              width: double.infinity,
                                              height: 58.h,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: _isSubmitting
                                                      ? null
                                                      : () {
                                                          HapticFeedback
                                                              .mediumImpact();
                                                          _updateUserData();
                                                        },
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16.r),
                                                  child: Center(
                                                    child: _isSubmitting
                                                        ? SizedBox(
                                                            height: 24.h,
                                                            width: 24.h,
                                                            child:
                                                                const CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                        : Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .save_outlined,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              SizedBox(
                                                                  width: 12.w),
                                                              Text(
                                                                'حفظ التغييرات',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      16.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                  ),
                                                ),
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
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageWithEditButton() {
    return Stack(
      children: [
        // Profile image container
        Container(
          width: 80.r,
          height: 80.r,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: _profileImage != null
                ? Image.file(
                    _profileImage!,
                    width: 80.r,
                    height: 80.r,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF97316).withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 40.r,
                        color: const Color(0xFFF97316),
                      ),
                    ),
                  )
                : profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? Image.network(
                        // Add base URL if not present
                        profileImageUrl!.startsWith('http')
                            ? profileImageUrl!
                            : 'https://ha55a.exchange/${profileImageUrl!}',
                        width: 80.r,
                        height: 80.r,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print("🔍 Error loading image: $error");
                          print("🔍 Image URL attempted: $profileImageUrl");
                          return Container(
                            color: const Color(0xFFF97316).withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              size: 40.r,
                              color: const Color(0xFFF97316),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFF97316).withOpacity(0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: const Color(0xFFF97316),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFFF97316).withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 40.r,
                          color: const Color(0xFFF97316),
                        ),
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
                color: const Color(0xFFF97316),
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
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.edit,
                        size: 16.r,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for shimmer pattern effect
class ShimmerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw diagonal shimmer lines
    for (double i = -size.height; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Draw circles
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // Random dots
    final random = math.Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 4 + 1;
      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
