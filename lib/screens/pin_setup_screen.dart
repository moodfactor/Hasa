import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/services/pin_security_service.dart';
import 'package:my_project/services/biometric_service.dart';
import 'package:local_auth/local_auth.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isVerification;

  const PinSetupScreen({
    Key? key,
    this.isVerification = false,
  }) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  final PinSecurityService _pinService = PinSecurityService();
  final BiometricService _biometricService = BiometricService();
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  final List<String> _oldPin = [];
  bool _isConfirmStep = false;
  bool _isLoading = false;
  bool _showError = false;
  String _errorMessage = '';
  bool _isPinSet = false;
  bool _isChangingPin = false;
  bool _isDeactivatingPin = false;
  bool _isVerifyingOldPin = false;
  final List<String> _deactivationPin = [];
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
    _checkBiometricAvailability();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPinStatus() async {
    setState(() => _isLoading = true);
    final isPinSet = await _pinService.isPinSet();
    setState(() {
      _isPinSet = isPinSet;
      _isLoading = false;
    });
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _biometricService.isFingerPrintEnabled();

    setState(() {
      _isBiometricAvailable = isAvailable;
      _isBiometricEnabled = isEnabled;
    });

    // إذا كانت البصمة مفعلة وفي وضع التحقق، نعرض شاشة البصمة مباشرة
    if (widget.isVerification && _isBiometricAvailable && _isBiometricEnabled) {
      _authenticateWithBiometric();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      setState(() => _isLoading = true);

      final result = await _biometricService.authenticate();
      final bool success = result.$1;
      final String error = result.$2;

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        // تم المصادقة بنجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم المصادقة بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (error.isNotEmpty) {
        // عرض رسالة الخطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ غير متوقع'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleFingerprint(bool enabled) async {
    setState(() => _isLoading = true);

    try {
      if (enabled) {
        // تأكيد البصمة قبل تفعيلها
        final result = await _biometricService.authenticate();
        if (!result.$1) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.$2),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      await _biometricService.setFingerPrintEnabled(enabled);

      if (!mounted) return;
      setState(() {
        _isBiometricEnabled = enabled;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              enabled ? 'تم تفعيل بصمة الإصبع' : 'تم إلغاء تفعيل بصمة الإصبع'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تغيير إعدادات البصمة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startChangingPin() {
    setState(() {
      _isChangingPin = true;
      _isDeactivatingPin = false;
      _isVerifyingOldPin = true;
      _oldPin.clear();
      _pin.clear();
      _confirmPin.clear();
      _isConfirmStep = false;
      _showError = false;
    });
  }

  void _startDeactivatingPin() {
    setState(() {
      _isDeactivatingPin = true;
      _isChangingPin = false;
      _deactivationPin.clear();
      _showError = false;
    });
  }

  void _onNumberPress(String number) {
    HapticFeedback.lightImpact();

    if (_isVerifyingOldPin) {
      if (_oldPin.length < 6) {
        setState(() {
          _oldPin.add(number);
          _showError = false;
        });

        if (_oldPin.length == 6) {
          _verifyOldPin();
        }
      }
      return;
    }

    if (_isDeactivatingPin) {
      if (_deactivationPin.length < 6) {
        setState(() {
          _deactivationPin.add(number);
          _showError = false;
        });

        if (_deactivationPin.length == 6) {
          _validateAndDeactivatePin();
        }
      }
      return;
    }

    if (_isConfirmStep) {
      if (_confirmPin.length < 6) {
        setState(() {
          _confirmPin.add(number);
          _showError = false;
        });

        if (_confirmPin.length == 6) {
          _validateAndSavePin();
        }
      }
    } else {
      if (_pin.length < 6) {
        setState(() {
          _pin.add(number);
          _showError = false;
        });

        if (_pin.length == 6) {
          setState(() => _isConfirmStep = true);
        }
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();

    if (_isVerifyingOldPin && _oldPin.isNotEmpty) {
      setState(() => _oldPin.removeLast());
    } else if (_isDeactivatingPin && _deactivationPin.isNotEmpty) {
      setState(() => _deactivationPin.removeLast());
    } else if (_isConfirmStep && _confirmPin.isNotEmpty) {
      setState(() => _confirmPin.removeLast());
    } else if (!_isConfirmStep && _pin.isNotEmpty) {
      setState(() => _pin.removeLast());
    }
  }

  Future<void> _verifyOldPin() async {
    setState(() => _isLoading = true);

    final isCorrect = await _pinService.verifyPin(_oldPin.join());

    if (!isCorrect) {
      setState(() {
        _isLoading = false;
        _showError = true;
        _errorMessage = 'رمز الحماية غير صحيح';
        _oldPin.clear();
      });
      return;
    }

    // Old PIN is correct, proceed to new PIN
    setState(() {
      _isLoading = false;
      _isVerifyingOldPin = false;
      _showError = false;
    });
  }

  Future<void> _validateAndDeactivatePin() async {
    setState(() => _isLoading = true);

    // Verify current PIN
    final isCorrect = await _pinService.verifyPin(_deactivationPin.join());

    if (!isCorrect) {
      setState(() {
        _isLoading = false;
        _showError = true;
        _errorMessage = 'رمز الحماية غير صحيح';
        _deactivationPin.clear();
      });
      return;
    }

    // Deactivate PIN
    final success = await _pinService.resetPin();
    await _pinService.resetAttempts();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء رمز الحماية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Return to previous screen
    } else {
      setState(() {
        _isLoading = false;
        _showError = true;
        _errorMessage = 'حدث خطأ أثناء إلغاء رمز الحماية';
      });
    }
  }

  Future<void> _validateAndSavePin() async {
    if (_pin.join() != _confirmPin.join()) {
      setState(() {
        _showError = true;
        _errorMessage = 'رمز الحماية والتأكيد غير متطابقين';
        _confirmPin.clear();
      });
      return;
    }

    setState(() => _isLoading = true);
    final success = await _pinService.savePin(_pin.join());

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('تم حفظ رمز الحماية بنجاح'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Return to main screen after successful PIN change
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isLoading = false;
        _showError = true;
        _errorMessage = 'حدث خطأ أثناء حفظ رمز الحماية';
      });
    }
  }

  Widget _buildPinDots() {
    final List<String> currentPin = _isVerifyingOldPin
        ? _oldPin
        : _isConfirmStep
            ? _confirmPin
            : _pin;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < currentPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          width: 16.w,
          height: 16.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? Theme.of(context).primaryColor : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        _onNumberPress(number);
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyOldPinUI() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outlined,
                  size: 64.sp,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 32.h),
                Text(
                  'التحقق من رمز الحماية',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'الرجاء إدخال رمز الحماية الحالي',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                _buildPinDots(),
                if (_showError) ...[
                  SizedBox(height: 16.h),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildNumericKeypad(),
        ],
      ),
    );
  }

  Widget _buildDeactivationUI() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_open,
                  size: 64.sp,
                  color: const Color(0xFFE53935),
                ),
                SizedBox(height: 32.h),
                Text(
                  'إلغاء رمز الحماية',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'الرجاء إدخال رمز الحماية الحالي للتأكيد',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                _buildPinDots(),
                if (_showError) ...[
                  SizedBox(height: 16.h),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildNumericKeypad(),
        ],
      ),
    );
  }

  Widget _buildPinEntryUI() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64.sp,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 32.h),
                Text(
                  _isConfirmStep ? 'تأكيد رمز الحماية' : 'إنشاء رمز الحماية',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _isConfirmStep
                      ? 'الرجاء إدخال رمز الحماية مرة أخرى للتأكيد'
                      : 'الرجاء إدخال رمز الحماية المكون من ٦ أرقام',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                _buildPinDots(),
                if (_showError) ...[
                  SizedBox(height: 16.h),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildNumericKeypad(),
        ],
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        children: [
          if (widget.isVerification && _isBiometricAvailable) ...[
            FutureBuilder<String>(
              future: _biometricService.getBiometricString(),
              builder: (context, snapshot) {
                final String buttonText = snapshot.data ?? 'استخدام البصمة';
                final bool isFaceId = buttonText.contains('Face ID');

                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _authenticateWithBiometric,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 12.h, horizontal: 24.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                isFaceId
                                    ? Icons.face_unlock_outlined
                                    : Icons.fingerprint,
                                color: Theme.of(context).primaryColor,
                                size: 24.sp,
                              ),
                            SizedBox(width: 8.w),
                            Text(
                              _isLoading ? 'جاري المصادقة...' : buttonText,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('3'),
              _buildNumberButton('2'),
              _buildNumberButton('1'),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('6'),
              _buildNumberButton('5'),
              _buildNumberButton('4'),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('9'),
              _buildNumberButton('8'),
              _buildNumberButton('7'),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 80.w,
                height: 80.w,
                child: GestureDetector(
                  onTapDown: (_) => _animationController.forward(),
                  onTapUp: (_) {
                    _animationController.reverse();
                    _onBackspace();
                  },
                  onTapCancel: () => _animationController.reverse(),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 24.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildNumberButton('0'),
              SizedBox(width: 80.w),
            ],
          ),
        ],
      ),
    );
  }

  String _convertArabicToEnglish(String number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    for (int i = 0; i < arabicNumbers.length; i++) {
      if (number == arabicNumbers[i]) {
        return englishNumbers[i];
      }
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إعداد رمز الحماية',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: _isVerifyingOldPin
                    ? _buildVerifyOldPinUI()
                    : _isDeactivatingPin
                        ? _buildDeactivationUI()
                        : _isPinSet && !_isChangingPin
                            ? _buildMainUI()
                            : _buildPinEntryUI(),
              ),
      ),
    );
  }

  Widget _buildMainUI() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حالة رمز الحماية',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'رمز الحماية مفعل',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    if (_isBiometricAvailable) ...[
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'بصمة الإصبع',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Switch(
                            value: _isBiometricEnabled,
                            onChanged: _isLoading ? null : _toggleFingerprint,
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                      Text(
                        'استخدم بصمة إصبعك لفتح التطبيق بدلاً من إدخال رمز الحماية',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'إدارة رمز الحماية',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startChangingPin,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_reset,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 12.w),
                        const Expanded(
                          child: Text(
                            'تغيير رمز الحماية',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startDeactivatingPin,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_open,
                          color: Color(0xFFE53935),
                        ),
                        SizedBox(width: 12.w),
                        const Expanded(
                          child: Text(
                            'إلغاء رمز الحماية',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
