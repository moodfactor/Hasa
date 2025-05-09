import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final String _biometricEnabledKey = 'biometric_enabled';

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      // التحقق من وجود مستشعر البصمة تحديداً
      return isAvailable &&
          isDeviceSupported &&
          availableBiometrics.contains(BiometricType.fingerprint);
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isFingerPrintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setFingerPrintEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  Future<bool> hasFingerPrints() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  Future<String> getBiometricString() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.contains(BiometricType.fingerprint)) {
        return 'استخدام بصمة الإصبع';
      } else if (biometrics.contains(BiometricType.face)) {
        return 'استخدام Face ID';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'استخدام قزحية العين';
      }
      return 'استخدام المصادقة البيومترية';
    } catch (_) {
      return 'استخدام بصمة الإصبع';
    }
  }

  Future<(bool, String)> authenticate() async {
    try {
      // التحقق من وجود البصمة وتفعيلها
      final hasFingerprint = await hasFingerPrints();
      final isEnabled = await isFingerPrintEnabled();

      if (!hasFingerprint) {
        return (false, 'البصمة غير متوفرة على هذا الجهاز');
      }

      if (!isEnabled) {
        return (false, 'يرجى تفعيل خاصية البصمة من إعدادات التطبيق');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'الرجاء وضع إصبعك على مستشعر البصمة للمصادقة',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
          sensitiveTransaction: true, // لزيادة مستوى الأمان
        ),
      );

      if (authenticated) {
        return (true, '');
      } else {
        return (false, 'فشلت المصادقة، يرجى المحاولة مرة أخرى');
      }
    } on PlatformException catch (e) {
      String errorMsg = 'حدث خطأ أثناء المصادقة';

      switch (e.code) {
        case 'LockedOut':
          errorMsg =
              'تم قفل البصمة مؤقتاً بسبب المحاولات الكثيرة، يرجى المحاولة لاحقاً';
          break;
        case 'PermanentlyLockedOut':
          errorMsg = 'تم قفل البصمة، يرجى إعادة ضبط الجهاز';
          break;
        case 'NotEnrolled':
          errorMsg =
              'لم يتم العثور على بصمات مسجلة، يرجى تسجيل بصمة في إعدادات الجهاز';
          break;
      }

      return (false, errorMsg);
    } catch (e) {
      return (false, 'حدث خطأ غير متوقع');
    }
  }
}
