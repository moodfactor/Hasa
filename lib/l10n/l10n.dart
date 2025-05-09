import 'package:flutter/material.dart';

class L10n {
  static const all = [
    Locale('en'), // الإنجليزية
    Locale('ar'), // العربية
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }
}
