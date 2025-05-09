import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:developer' as dev;

class MaintenanceService {
  static final MaintenanceService _instance = MaintenanceService._internal();

  // Factory constructor
  factory MaintenanceService() {
    return _instance;
  }

  // Private constructor
  MaintenanceService._internal();

  // Store maintenance status
  bool _isInMaintenance = false;
  bool get isInMaintenance => _isInMaintenance;

  // Method to check if app is in maintenance mode
  Future<bool> checkMaintenanceStatus() async {
    try {
      var dio = Dio();
      dev.log("🔄 Checking maintenance status from API...");
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/general/maintenace.php',
        options: Options(
          method: 'GET',
        ),
      );

      dev.log("📝 Status code: ${response.statusCode}");
      dev.log("📝 Raw API response: ${json.encode(response.data)}");

      if (response.statusCode == 200) {
        dev.log("✅ API responded with 200 OK");

        if (response.data['success'] == true) {
          dev.log("✅ Success flag is true");

          if (response.data['data'] is List &&
              response.data['data'].isNotEmpty) {
            dev.log("✅ Data list is not empty");

            final maintenanceData = response.data['data'][0];
            dev.log("🔍 Maintenance data: ${json.encode(maintenanceData)}");

            // معالجة القيمة بغض النظر عن نوعها (رقم أو نص)
            var maintenanceMode = maintenanceData['maintenance_mode'];
            dev.log(
                "🔑 Maintenance mode raw value: $maintenanceMode (type: ${maintenanceMode.runtimeType})");

            // التحقق من القيمة بطريقة مرنة تقبل الرقم 1 أو النص "1"
            _isInMaintenance = maintenanceMode.toString() == "1";

            dev.log(
                "🚦 Maintenance status: ${_isInMaintenance ? 'ACTIVE' : 'INACTIVE'}");
            return _isInMaintenance;
          } else {
            dev.log(
                "❌ Data list is empty or not a list: ${response.data['data']}");
          }
        } else {
          dev.log("❌ Success flag is false: ${response.data['success']}");
        }
      }

      // Default to false if can't determine
      dev.log("⚠️ Defaulting maintenance status to false");
      _isInMaintenance = false;
      return false;
    } catch (e) {
      dev.log("🔴 Error checking maintenance status: $e");
      // In case of error, we don't want to block the app
      _isInMaintenance = false;
      return false;
    }
  }

  // طريقة للاختبار المباشر للاستجابة (يمكن استخدامها للتشخيص)
  static Future<Map<String, dynamic>> testMaintenanceAPI() async {
    try {
      var dio = Dio();
      dev.log("🧪 TEST: Calling maintenance API directly...");

      var response = await dio.get(
        'https://ha55a.exchange/api/v1/general/maintenace.php',
      );

      dev.log("🧪 TEST: Status code: ${response.statusCode}");
      dev.log("🧪 TEST: Raw response: ${json.encode(response.data)}");

      // تحليل مباشر للقيمة
      bool isInMaintenance = false;
      if (response.statusCode == 200 &&
          response.data['success'] == true &&
          response.data['data'] is List &&
          response.data['data'].isNotEmpty) {
        final maintenanceData = response.data['data'][0];
        var maintenanceMode = maintenanceData['maintenance_mode'];

        // التحقق بنفس الطريقة المستخدمة في checkMaintenanceStatus
        isInMaintenance = maintenanceMode.toString() == "1";
        dev.log(
            "🧪 TEST: Detected maintenance mode: ${isInMaintenance ? 'ACTIVE' : 'INACTIVE'}");
      }

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'isInMaintenance': isInMaintenance,
        'success': response.statusCode == 200,
      };
    } catch (e) {
      dev.log("🧪 TEST: Error during API test: $e");
      return {
        'statusCode': 500,
        'data': null,
        'isInMaintenance': false,
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
