import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  int _notificationCount = 0;

  int get notificationCount => _notificationCount;

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      Map<String, dynamic> userData = jsonDecode(userJson);
      return userData['id'].toString();
    }
    return null;
  }

  saveNotificationCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_count', count.toString());
  }

  Future<void> fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = await getUserId();
      if (userId == null) return;
      var dio = Dio();
      log('user id $userId');
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/notfication/get.php?user_id=$userId',
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        log(' notification count ${response.data['unread_count']}');
        _notificationCount = response.data['unread_count'];
        prefs.setInt('notification_count', _notificationCount);
        saveNotificationCount(_notificationCount);
        notifyListeners();
      } else {
        log('${response.statusMessage}');
      }
    } catch (e) {
      log('$e');
    }
  }

  Future<void> readNotification(String notificationId) async {
    try {
      String? userId = await getUserId();
      if (userId == null) return;
      var dio = Dio();
      log('user id $userId');
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/notfication/edit.php?user_id=$userId&notification_id=$notificationId',
        options: Options(method: 'POST'),
      );
      if (response.statusCode == 200) {
        log(response.data.toString());
        notifyListeners();
      } else {
        log('${response.statusMessage}');
      }
    } catch (e) {
      log('$e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      String? userId = await getUserId();
      if (userId == null) return;
      var dio = Dio();
      log('user id $userId');
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/notfication/read.php?user_id=$userId',
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        log(response.data.toString());
        notifyListeners();
      } else {
        log('${response.statusMessage}');
      }
    } catch (e) {
      log('$e');
    }
  }
}
