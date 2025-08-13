import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_project/services/pin_security_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_project/Feature/Auth/presentation/view/login_screen.dart';

class PinLockScreen extends StatefulWidget {
  final Widget nextScreen;

  const PinLockScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final PinSecurityService _pinService = PinSecurityService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _showError = false;
  String _errorMessage = '';
  int _remainingAttempts = 3;
  bool _isPinSet = false;
  bool _isLocked = false;
  List<String> _enteredPin = [];
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkPinStatus();
    _checkBiometrics();

    // Add haptic feedback when screen loads
    HapticFeedback.mediumImpact();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPinStatus() async {
    setState(() => _isLoading = true);

    final isPinSet = await _pinService.isPinSet();
    final isLocked = await _pinService.isLocked();
    final remainingAttempts = await _pinService.getRemainingAttempts();

    setState(() {
      _isPinSet = isPinSet;
      _isLocked = isLocked;
      _remainingAttempts = remainingAttempts;
      _isLoading = false;

      if (_isLocked) {
        _showError = true;
        _errorMessage = 'تم قفل التطبيق بسبب محاولات غير صحيحة متكررة';
      }
    });
  }

  Future<void> _checkBiometrics() async {
    if (await _pinService.isLocked()) return;

    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) return;

      // Only show biometric button if PIN is set
      if (await _pinService.isPinSet()) {
        setState(() {
          _showBiometricButton = true;
        });

        // On iOS devices, show biometrics prompt automatically
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          _authenticateWithBiometrics();
        }
      }
    } catch (e) {
      log('Error checking biometrics: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'تأكيد هويتك للدخول إلى التطبيق',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        await _pinService.resetAttempts();
        _navigateToNextScreen();
      }
    } catch (e) {
      log('Error authenticating with biometrics: $e');
    }
  }

  void _navigateToNextScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _addDigitToPin(String digit) {
    if (_enteredPin.length < 6) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredPin.add(digit);
        _showError = false;
      });

      if (_enteredPin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _removeLastDigit() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin.removeLast();
      });
    }
  }

  Future<void> _verifyPin() async {
    final enteredPin = _enteredPin.join();

    setState(() => _isLoading = true);

    final isCorrect = await _pinService.verifyPin(enteredPin);

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      await _pinService.resetAttempts();
      setState(() {
        _showError = false;
        _isLoading = false;
      });
      _navigateToNextScreen();
    } else {
      HapticFeedback.heavyImpact();
      final attempts = await _pinService.incrementAttempts();
      final remainingAttempts = await _pinService.getRemainingAttempts();
      final isLocked = await _pinService.isLocked();

      setState(() {
        _isLoading = false;
        _showError = true;
        _enteredPin = [];
        _remainingAttempts = remainingAttempts;
        _isLocked = isLocked;

        if (isLocked) {
          _errorMessage = 'تم قفل التطبيق بسبب محاولات غير صحيحة متكررة';
        } else {
          _errorMessage =
              'رمز PIN غير صحيح. المحاولات المتبقية: $_remainingAttempts';
        }
      });
    }
  }

  Future<void> _resetPinWithSupport() async {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Warning Icon
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 38.sp),
                ),
                SizedBox(height: 16.h),
                // Title
                Text(
                  'إعادة تعيين رمز PIN',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 14.h),
                // Description
                Text(
                  'سيؤدي هذا إلى مسح جميع بيانات التطبيق وستحتاج إلى تسجيل الدخول من جديد. هل أنت متأكد أنك تريد المتابعة؟',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          setState(() => _isLoading = true);
                          await _pinService.resetPin();
                          await _pinService.resetAttempts();
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          await Future.delayed(
                              const Duration(milliseconds: 1500));
                          if (mounted) {
                            Future.microtask(() {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          elevation: 0,
                        ),
                        child: Text(
                          'مسح البيانات',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          width: isFilled ? 16.w : 16.w,
          height: isFilled ? 16.w : 16.w,
          decoration: BoxDecoration(
            color:
                isFilled ? Theme.of(context).primaryColor : Colors.transparent,
            border: Border.all(
              color:
                  isFilled ? Theme.of(context).primaryColor : Colors.grey[400]!,
              width: 1.5.w,
            ),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: EdgeInsets.all(6.r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  _isLocked || _isLoading ? null : () => _addDigitToPin(number),
              borderRadius: BorderRadius.circular(50),
              child: Container(
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
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: EdgeInsets.all(6.r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLocked || _isLoading || _enteredPin.isEmpty
                  ? null
                  : _removeLastDigit,
              borderRadius: BorderRadius.circular(50),
              child: Container(
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
                child: Center(
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 24.sp,
                    color:
                        _enteredPin.isEmpty ? Colors.grey[300] : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: EdgeInsets.all(6.r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  _isLocked || _isLoading ? null : _authenticateWithBiometrics,
              borderRadius: BorderRadius.circular(50),
              child: Container(
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
                child: Center(
                  child: Icon(
                    Icons.fingerprint,
                    size: 28.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Colors.white,
            ],
            stops: const [0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: LayoutBuilder(builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Column(
                                  children: [
                                    SizedBox(height: 30.h),

                                    // App Logo
                                    Hero(
                                      tag: 'app_logo',
                                      child: Container(
                                        width: 100.w,
                                        height: 100.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.all(15.r),
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          width: 70.w,
                                          height: 70.w,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20.h),

                                    // Title
                                    Text(
                                      'مرحباً بك',
                                      style: TextStyle(
                                        fontSize: 26.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8.h),

                                    // Description
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 40.w),
                                      child: Text(
                                        'أدخل رمز PIN المكون من 6 أرقام للوصول إلى حسابك',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(height: 30.h),

                                    // PIN dots
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24.w),
                                      child: _buildPinDots(),
                                    ),
                                    SizedBox(height: 10.h),

                                    // Error Message
                                    if (_showError)
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 20.w, vertical: 12.h),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          border: Border.all(
                                              color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: Colors.red, size: 18.sp),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                _errorMessage,
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    Expanded(child: SizedBox(height: 20.h)),

                                    // Numpad
                                    Container(
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 8.w),
                                      padding: EdgeInsets.all(12.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius:
                                            BorderRadius.circular(24.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 0,
                                            offset: const Offset(0, -2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              _buildNumberButton('1'),
                                              _buildNumberButton('2'),
                                              _buildNumberButton('3'),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              _buildNumberButton('4'),
                                              _buildNumberButton('5'),
                                              _buildNumberButton('6'),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              _buildNumberButton('7'),
                                              _buildNumberButton('8'),
                                              _buildNumberButton('9'),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              _showBiometricButton
                                                  ? _buildBiometricButton()
                                                  : Expanded(
                                                      child: Container()),
                                              _buildNumberButton('0'),
                                              _buildBackspaceButton(),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Reset PIN Button
                                    if (_isLocked || _isPinSet)
                                      TextButton.icon(
                                        onPressed: _resetPinWithSupport,
                                        icon: Icon(Icons.lock_reset,
                                            size: 16.sp,
                                            color: Colors.grey[700]),
                                        label: Text(
                                          'نسيت الرمز ؟',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),

                                    SizedBox(height: 8.h),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
