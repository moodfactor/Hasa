import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:my_project/drainagedetails.dart';
import 'package:my_project/main_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_html/flutter_html.dart';

class SendMoneyStepsScreen extends StatefulWidget {
  const SendMoneyStepsScreen({
    required this.exchangeId,
    Key? key,
  }) : super(key: key);

  final String exchangeId;

  @override
  State<SendMoneyStepsScreen> createState() => _SendMoneyStepsScreenState();
}

class _SendMoneyStepsScreenState extends State<SendMoneyStepsScreen> {
  Map<String, dynamic> transactionDetails = {};
  bool isLoading = true;
  bool isFetching = false;
  late Future<Map<String, dynamic>> transactionFuture;
  late Future<Map<String, dynamic>> _exchangeInfoTipFuture;
  int _currentStep = 0;
  bool _isSendDetailsSelected = true;

  final TextEditingController walletController = TextEditingController();
  final TextEditingController sendAmountController = TextEditingController();
  final TextEditingController receiveAmountController = TextEditingController();

  String? sendCurrencySymbol;
  String? receiveCurrencySymbol;
  double sendSellRate = 1.0;
  double receiveBuyRate = 1.0;
  String? exchangeId;
  // متغير جديد للاحتفاظ بمعرف العملة المرسل بها
  String? curid;

  List<Map<String, String>> sendCurrencies = [];
  List<Map<String, String>> receiveCurrencies = [];
  String? selectedSendCurrency;
  String? selectedReceiveCurrency;
  String? selectedSendCurrencyId;
  String? selectedRecievedCurrencyId;
  bool isLoadingReceiveCurrencies = false;
  int? orderId;

  final String baseUrl = 'https://ha55a.exchange/assets/images/currency/';
  final Dio dio = Dio();

  final Map<String, dynamic> _formData = {};

  final Map<String, TextEditingController> _controllers = {};
  late PageController _pageController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);

    super.initState();

    transactionFuture = fetchTransactionDetails();
    _exchangeInfoTipFuture = fetchExchangeInfoTip();
    _fetchSendCurrencies();
// ✅ Fetch only once

    sendAmountController.addListener(() {
      if (sendAmountController.text.isEmpty) {
        receiveAmountController.text = '';
        return;
      }
      double sendAmount = double.tryParse(sendAmountController.text) ?? 0.0;
      String newValue;

      if (sendCurrencySymbol == receiveCurrencySymbol) {
        newValue = sendAmount.toStringAsFixed(2);
      } else if (sendCurrencySymbol == "IQD" &&
          receiveCurrencySymbol == "USD") {
        newValue = ((sendAmount * receiveBuyRate) / 1500).toStringAsFixed(2);
      } else {
        newValue =
            (sendAmount * (sendSellRate / receiveBuyRate)).toStringAsFixed(2);
      }

      if (receiveAmountController.text != newValue) {
        receiveAmountController.text = newValue; // ✅ Update without setState
      }
    });
  }

  @override
  void dispose() {
    sendAmountController.dispose();
    receiveAmountController.dispose();
    walletController.dispose();

    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchTransactionDetails() async {
    if (isFetching) return {};
    if (mounted) {
      setState(() {
        isLoading = true;
        isFetching = true;
      });
    }
    try {
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/order/get.php?exchange_id=${widget.exchangeId}',
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        orderId = response.data['exchange']['id'];

        // تعيين curid من بيانات المعاملة إذا كانت متوفرة
        if (response.data['exchange']['send_currency_id'] != null) {
          setState(() {
            curid = response.data['exchange']['send_currency_id'].toString();
          });
        }

        return response.data;
      } else {
        throw Exception("Failed to load data: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception("Unexpected Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isFetching = false;
        });
      }
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout, please check your internet.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Receive timeout, server took too long to respond.';
    } else if (e.type == DioExceptionType.badResponse) {
      return 'Bad response: ${e.response?.statusCode} - ${e.response?.data}';
    } else if (e.type == DioExceptionType.cancel) {
      return 'Request was cancelled.';
    } else if (e.type == DioExceptionType.unknown) {
      return 'Unknown error occurred: ${e.message}';
    } else {
      return 'Dio Error: ${e.message}';
    }
  }

  Future<void> updateWalletId() async {
    final walletId = walletController.text.trim();

    _formData["wallet_id"] = walletId;

    // log("Dynamic Form Data: ${jsonEncode(_formData)}");

    try {
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/order/submit-form.php',
        data: _formData,
      );
      if (response.statusCode == 200 && response.data["success"] == true) {
        setState(() => _currentStep = 2);
      } else {}
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<Map<String, dynamic>> fetchExchangeInfoTip() async {
    try {
      final transactionDetails = await transactionFuture;
      // log("Transaction Details: ${jsonEncode(transactionDetails)}");

      if (transactionDetails.isEmpty ||
          transactionDetails['exchange'] == null) {
        throw Exception(
            "لم يتم استلام تفاصيل المعاملة أو تفاصيل التبادل ناقصة");
      }

      final exchange = transactionDetails['exchange'];
      if (exchange['receive_currency_id'] == null) {
        throw Exception(
            "لم يتم العثور على receive_currency_id في تفاصيل التبادل");
      }

      final receiveCurrencyId = exchange['receive_currency_id'];
      // log("Received receive_currency_id: $receiveCurrencyId");

      final url =
          'https://ha55a.exchange/api/v1/order/send-step.php?id=$receiveCurrencyId';
      // log("Send-step URL: $url");

      final response = await dio.request(
        url,
        options: Options(method: 'GET'),
      );

      // log("Full response: ${jsonEncode(response.data)}");

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          throw Exception("صيغة البيانات غير متوقعة: ${response.data}");
        }
      } else {
        throw Exception("خطأ من السيرفر: ${response.statusMessage}");
      }
    } on DioException catch (dioError) {
      // log("DioError: ${dioError.message}");
      if (dioError.response != null) {
        // log("Dio error response: ${dioError.response?.data}");
      }
      throw Exception("حدث خطأ أثناء جلب البيانات: ${dioError.message}");
    } catch (e) {
      // log("حدث خطأ أثناء جلب البيانات: $e");
      // log("StackTrace: $stackTrace");
      throw Exception("حدث خطأ أثناء جلب البيانات: $e");
    }
  }

  Future<void> submitDynamicForm({
    required String formId,
    required String exchangeId,
  }) async {
    log("===========================================================");
    log("🔵 SUBMITTING DYNAMIC FORM TO MAP.PHP:");
    log("🔵 Form ID: $formId");
    log("🔵 Exchange ID: $exchangeId");
    log("🔵 Form Data: ${jsonEncode(_formData)}");

    // فحص وجود حقول صور في النموذج (تبدأ بـ http)
    bool hasImageUrls = false;
    _formData.forEach((key, value) {
      if (value is String &&
          (value.startsWith('http://') || value.startsWith('https://'))) {
        log("🔵 FOUND IMAGE URL IN FORM: Field '$key' contains URL: $value");
        hasImageUrls = true;
      }
    });

    if (hasImageUrls) {
      log("🔵 The form contains image URLs that were uploaded previously");
      log("🔵 These URLs will be sent to map.php instead of local file paths");
    }

    log("===========================================================");

    // Process any file or image fields that need to be uploaded
    List<String> fileKeys = [];
    _formData.forEach((key, value) {
      if (value is String && value.startsWith("/data/")) {
        fileKeys.add(key);
      }
    });

    // Upload any files or images that need to be sent
    for (String key in fileKeys) {
      String filePath = _formData[key];
      log("🔵 Processing file upload for '$key': $filePath");

      try {
        // IMPORTANT: Using 'image' parameter name as required by the API
        FormData imageData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            filePath,
            filename: filePath.split('/').last,
          )
        });

        log("🔵 Uploading file for '$key'...");
        log("🔵 IMPORTANT: Sending file with parameter name 'image' as required by the API");

        Response uploadResponse = await dio.post(
          'https://ha55a.exchange/api/v1/order/upload.php',
          options: Options(method: 'POST'),
          data: imageData,
        );

        log("🔵 Upload response for '$key': ${jsonEncode(uploadResponse.data)}");

        if (uploadResponse.statusCode == 200 &&
            uploadResponse.data["success"] == true) {
          _formData[key] = uploadResponse.data["url"];
          log("🟢 Uploaded file for '$key': ${_formData[key]}");
        } else {
          log("🔴 Upload failed for '$key': ${uploadResponse.statusMessage}");
        }
      } catch (e) {
        log("🔴 Error uploading file for '$key': $e");
      }
    }

    try {
      // Convert form data to JSON format expected by PHP server
      final jsonData = jsonEncode(_formData);
      log("🔵 Transformed form data for PHP server: $jsonData");

      // تحقق من وجود روابط الصور في البيانات المحولة
      if (jsonData.contains("http")) {
        log("🔵 VERIFICATION: The JSON data contains image URLs");
      }

      // Prepare the complete FormData object with all parameters
      FormData finalData = FormData.fromMap({
        'form_id': formId,
        'data': jsonData,
        'exchange_id': exchangeId,
        'currency': 'IQD', // Fixed currency value
        'exchange_rate': '1500', // Fixed exchange rate
        'version': '1.0', // Fixed API version
      });

      // Log complete details of the request
      log("===========================================================");
      log("🔵 MAP.PHP API REQUEST DETAILS:");
      log("🔵 URL: https://ha55a.exchange/api/v1/order/map.php");
      log("🔵 METHOD: POST");
      log("🔵 HEADERS:");
      log("🔵 - Content-Type: multipart/form-data");
      log("🔵 - Accept: application/json");
      log("🔵 PARAMETERS:");
      log("🔵 - form_id: $formId");
      log("🔵 - exchange_id: $exchangeId");
      log("🔵 - data: $jsonData");
      log("🔵 - currency: IQD");
      log("🔵 - exchange_rate: 1500");
      log("🔵 - version: 1.0");
      log("===========================================================");

      // Send the API request
      log("🔵 Sending API request to map.php...");
      Response finalResponse = await dio.post(
        'https://ha55a.exchange/api/v1/order/map.php',
        options: Options(
          method: 'POST',
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
        ),
        data: finalData,
      );

      // Log complete details of the response
      log("===========================================================");
      if (finalResponse.statusCode == 200) {
        log("🟢 MAP.PHP API RESPONSE DETAILS:");
        log("🟢 STATUS CODE: ${finalResponse.statusCode}");
        log("🟢 RESPONSE HEADERS:");
        finalResponse.headers.forEach((name, values) {
          log("🟢 - $name: ${values.join(', ')}");
        });
        log("🟢 RESPONSE DATA: ${jsonEncode(finalResponse.data)}");

        // Extract specific fields from response if they exist
        if (finalResponse.data is Map) {
          var responseMap = finalResponse.data as Map;
          log("🟢 SUCCESS: ${responseMap['success']}");
          if (responseMap.containsKey('message')) {
            log("🟢 MESSAGE: ${responseMap['message']}");
          }
          if (responseMap.containsKey('order_id')) {
            log("🟢 ORDER ID: ${responseMap['order_id']}");
          }
          if (responseMap.containsKey('exchange_id')) {
            log("🟢 EXCHANGE ID: ${responseMap['exchange_id']}");
          }
        }
      } else {
        log("🔴 MAP.PHP API ERROR DETAILS:");
        log("🔴 STATUS CODE: ${finalResponse.statusCode}");
        log("🔴 STATUS MESSAGE: ${finalResponse.statusMessage}");
        log("🔴 RESPONSE HEADERS:");
        finalResponse.headers.forEach((name, values) {
          log("🔴 - $name: ${values.join(', ')}");
        });
        if (finalResponse.data != null) {
          log("🔴 ERROR DATA: ${jsonEncode(finalResponse.data)}");
        }
      }
      log("===========================================================");

      return finalResponse.data;
    } catch (e) {
      log("===========================================================");
      log("🔴 MAP.PHP API EXCEPTION: $e");
      if (e is DioException) {
        log("🔴 DioException TYPE: ${e.type}");
        log("🔴 DioException MESSAGE: ${e.message}");
        if (e.response != null) {
          log("🔴 STATUS CODE: ${e.response?.statusCode}");
          log("🔴 RESPONSE DATA: ${jsonEncode(e.response?.data)}");
        }
      }
      log("===========================================================");
      rethrow;
    }
  }

  Future<void> submitDynamicForm2() async {
    try {
      final exchangeId =
          transactionDetails["exchange"]?["exchange_id"] ?? widget.exchangeId;

      log("===========================================================");
      log("🔵 SUBMITTING DYNAMIC FORM TO MAP2.PHP:");
      log("🔵 Exchange ID: $exchangeId");

      // Log FULL form data to examine all fields with values
      log("🔵 FORM DATA DETAILS (FULL):");
      _formData.forEach((key, value) {
        log("🔵 Field: $key = $value");
      });

      log("🔵 COMPLETE FORM DATA JSON: ${jsonEncode(_formData)}");
      log("===========================================================");

      var dynamicFormResponse = await dio.request(
        'https://ha55a.exchange/api/v1/order/check-form-2.php',
        options: Options(method: 'GET'),
        queryParameters: {'exchange_id': exchangeId},
      );

      if (dynamicFormResponse.statusCode == 200) {
        log("🟢 CHECK-FORM-2 RESPONSE: ${jsonEncode(dynamicFormResponse.data)}");

        final dynamicFormId = dynamicFormResponse.data['result'];
        log("🔵 Retrieved dynamic form id: $dynamicFormId");

        // Process any file uploads in form before submitting
        List<String> fileKeys = [];
        _formData.forEach((key, value) {
          if (value is String && value.startsWith("/data/")) {
            fileKeys.add(key);
          }
        });

        // Upload any files first
        for (String key in fileKeys) {
          String filePath = _formData[key];
          log("🔵 Processing file upload for '$key': $filePath");

          try {
            // Using 'image' parameter as required by the API
            FormData imageData = FormData.fromMap({
              'image': await MultipartFile.fromFile(
                filePath,
                filename: filePath.split('/').last,
              )
            });

            var uploadResponse = await dio.post(
              'https://ha55a.exchange/api/v1/order/upload.php',
              data: imageData,
            );

            if (uploadResponse.statusCode == 200 &&
                uploadResponse.data["success"] == true) {
              _formData[key] = uploadResponse.data["url"];
              log("🟢 Uploaded file for '$key': ${_formData[key]}");
            } else {
              log("🔴 Upload failed for '$key': ${uploadResponse.statusMessage}");
            }
          } catch (e) {
            log("🔴 Error uploading file for '$key': $e");
          }
        }

        // Prepare data for submission with updated form data after file uploads
        final Map<String, dynamic> requestData = {
          'form_id': dynamicFormId,
          'data': jsonEncode(_formData),
          'exchange_id': exchangeId,
          'currency': 'IQD', // Fixed currency value
          'exchange_rate': '1500', // Fixed exchange rate
          'version': '1.0', // Fixed API version
        };

        // Log complete details of the request
        log("===========================================================");
        log("🔵 MAP2.PHP API REQUEST DETAILS:");
        log("🔵 URL: https://ha55a.exchange/api/v1/order/map2.php");
        log("🔵 METHOD: POST");
        log("🔵 HEADERS:");
        log("🔵 - Content-Type: multipart/form-data");
        log("🔵 - Accept: application/json");
        log("🔵 PARAMETERS (DETAILED):");
        requestData.forEach((key, value) {
          if (key == 'data') {
            log("🔵 - $key: (JSON DATA - see next log)");
          } else {
            log("🔵 - $key: $value");
          }
        });
        log("🔵 DATA JSON PARAMETER CONTENTS: ${requestData['data']}");
        log("===========================================================");

        log("🔵 Submitting dynamic form with data: ${jsonEncode(requestData)}");

        var data = FormData.fromMap(requestData);

        var response = await dio.request(
          'https://ha55a.exchange/api/v1/order/map2.php',
          options: Options(
            method: 'POST',
            // لا تحدد contentType - دع Dio يضبطه تلقائياً مع boundary المناسب
            // contentType: 'multipart/form-data',
            headers: {
              'Accept': 'application/json',
            },
          ),
          data: data,
        );

        // Log complete details of the response
        log("===========================================================");
        if (response.statusCode == 200) {
          log("🟢 MAP2.PHP API RESPONSE DETAILS:");
          log("🟢 STATUS CODE: ${response.statusCode}");
          log("🟢 RESPONSE HEADERS:");
          response.headers.forEach((name, values) {
            log("🟢 - $name: ${values.join(', ')}");
          });
          log("🟢 RESPONSE DATA (FULL): ${jsonEncode(response.data)}");

          // Extract and log specific fields from response if they exist
          if (response.data is Map) {
            var responseMap = response.data as Map;
            log("🟢 SUCCESS: ${responseMap['success']}");

            if (responseMap.containsKey('message')) {
              log("🟢 MESSAGE: ${responseMap['message']}");
            }

            if (responseMap.containsKey('order_id')) {
              log("🟢 ORDER ID: ${responseMap['order_id']}");
            }

            if (responseMap.containsKey('exchange_id')) {
              log("🟢 EXCHANGE ID: ${responseMap['exchange_id']}");
            }

            // طباعة البيانات المستلمة والمدمجة من الخادم (حسب كود PHP)
            if (responseMap.containsKey('received')) {
              log("🟢 RECEIVED DATA: ${jsonEncode(responseMap['received'])}");
            }

            if (responseMap.containsKey('merged')) {
              log("🟢 MERGED DATA: ${jsonEncode(responseMap['merged'])}");

              // طباعة تفاصيل البيانات المدمجة
              log("🟢 MERGED DATA DETAILS:");
              if (responseMap['merged'] is Map) {
                (responseMap['merged'] as Map).forEach((key, value) {
                  log("🟢 - Field '$key': ${jsonEncode(value)}");
                });
              }
            }

            // Log additional fields if they exist
            responseMap.forEach((key, value) {
              if (![
                'success',
                'message',
                'order_id',
                'exchange_id',
                'received',
                'merged'
              ].contains(key)) {
                log("🟢 $key: $value");
              }
            });
          }
        } else {
          log("🔴 MAP2.PHP API ERROR DETAILS:");
          log("🔴 STATUS CODE: ${response.statusCode}");
          log("🔴 STATUS MESSAGE: ${response.statusMessage}");
          log("🔴 RESPONSE HEADERS:");
          response.headers.forEach((name, values) {
            log("🔴 - $name: ${values.join(', ')}");
          });
          if (response.data != null) {
            log("🔴 ERROR DATA: ${jsonEncode(response.data)}");
          }
        }
        log("===========================================================");
      } else {
        log("🔴 CHECK-FORM-2 API ERROR: ${dynamicFormResponse.statusCode}");
        log("🔴 ERROR DATA: ${jsonEncode(dynamicFormResponse.data)}");
      }
    } catch (e) {
      log("===========================================================");
      log("🔴 MAP2.PHP API EXCEPTION: $e");
      if (e is DioException) {
        log("🔴 DioException TYPE: ${e.type}");
        log("🔴 DioException MESSAGE: ${e.message}");
        if (e.response != null) {
          log("🔴 STATUS CODE: ${e.response?.statusCode}");
          log("🔴 RESPONSE DATA: ${jsonEncode(e.response?.data)}");
        }
      }
      log("===========================================================");
    }
  }

  Future<Map<String, dynamic>> fetchSendConfirmData() async {
    try {
      // التأكد من وجود بيانات المعاملة أولاً
      final transactionData = await transactionFuture;
      if (transactionData.isEmpty || transactionData['exchange'] == null) {
        throw Exception("لم يتم استلام بيانات المعاملة بشكل صحيح");
      }

      // استخراج send_currency_id من بيانات المعاملة
      final sendCurrencyId =
          transactionData['exchange']['send_currency_id']?.toString();
      if (sendCurrencyId == null || sendCurrencyId.isEmpty) {
        throw Exception("معرف العملة المرسل بها غير متوفر في بيانات المعاملة");
      }

      // تحديث curid من البيانات المستلمة
      setState(() {
        curid = sendCurrencyId;
      });

      // استخدام send_currency_id في طلب API
      final url =
          'https://ha55a.exchange/api/v1/order/send-confirm.php?id=$sendCurrencyId';

      final response = await dio.request(
        url,
        options: Options(method: 'GET'),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("Error: ${response.statusMessage}");
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cache for send confirm data to prevent reloading
  Map<String, dynamic>? _cachedSendConfirmData;
  bool _isLoadingSendConfirmData = false;

  Future<Map<String, dynamic>> _getCachedSendConfirmData() async {
    if (_cachedSendConfirmData != null) {
      return _cachedSendConfirmData!;
    }

    if (!_isLoadingSendConfirmData) {
      _isLoadingSendConfirmData = true;
      try {
        final data = await fetchSendConfirmData();
        _cachedSendConfirmData = data;

        // Reset cache if needed
        if (mounted) {
          setState(() {
            // Force clear cache if needed for testing
            // _cachedSendConfirmData = null;
          });
        }

        return data;
      } finally {
        _isLoadingSendConfirmData = false;
      }
    }

    // Return empty map while loading for the first time
    return {};
  }

  ///TODO the main pip for work
  Widget _buildStep3() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCachedSendConfirmData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedSendConfirmData == null) {
          return Center(
            child: Lottie.asset('assets/lottie/loading.json', height: 150),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ أثناء جلب التعليمات'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final data = snapshot.data!;

        final instruction = data["instruction"] ?? "";
        final image = data["image"] ?? "";
        final formId = data["form_id"]?.toString() ?? "";

        // استخراج بيانات النموذج مباشرة من الاستجابة
        Map<String, dynamic> formData = {};
        if (data["form_data"] != null && data["form_data"] is Map) {
          formData = Map<String, dynamic>.from(data["form_data"]);
        }

        final imageUrl = image != null && image.isNotEmpty
            ? 'https://ha55a.exchange/assets/images/currency/$image'
            : null;

        // Preprocess HTML to highlight quoted text
        String processedHtml = instruction;
        try {
          // Match text between quotation marks and wrap it in a span with custom class
          RegExp quotedTextRegex = RegExp(r'"([^"]*)"');
          processedHtml = instruction.replaceAllMapped(
            quotedTextRegex,
            (match) {
              String quotedText = match.group(1) ?? '';
              // Only apply if not a CSS style
              if (!quotedText.contains(':') && !quotedText.contains(';')) {
                return '"<span class="copyable-text">$quotedText</span>"';
              }
              return match.group(0) ?? '';
            },
          );
        } catch (e) {
          // If any error in processing, fall back to original HTML
          processedHtml = instruction;
        }

        // Function to extract quoted text when tapped
        void checkAndCopyQuotedText(String htmlContent) {
          try {
            // Strip HTML tags first to get plain text
            String plainText = htmlContent
                .replaceAll(RegExp(r'<[^>]*>'), ' ')
                .replaceAll('&nbsp;', ' ');

            // Extract text between quotation marks
            RegExp regex = RegExp(r'"([^"]*)"');
            var matches = regex.allMatches(plainText);

            if (matches.isNotEmpty) {
              for (var match in matches) {
                String quotedText = match.group(1) ?? '';
                if (quotedText.isNotEmpty &&
                    !quotedText.contains(':') &&
                    !quotedText.contains(';')) {
                  Clipboard.setData(ClipboardData(text: quotedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ: $quotedText'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  return;
                }
              }
            }

            // If no matches with quotes or all were style attributes, try to find any meaningful text
            if (plainText.trim().isNotEmpty) {
              String cleanText = plainText.trim();
              Clipboard.setData(ClipboardData(text: cleanText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ النص'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          } catch (e) {
            // Handle errors gracefully
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تعذر نسخ النص'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 1),
              ),
            );
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions to users about copying text
                if (instruction.contains('"'))
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Container(
                      padding: EdgeInsets.all(8.h),
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3))),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 20.h),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'اضغط على النص لنسخ أي محتوى بين علامتي اقتباس " "',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12.sp,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Make HTML content tappable
                GestureDetector(
                  onTap: () {
                    checkAndCopyQuotedText(instruction);
                  },
                  child: Html(
                    data: processedHtml,
                    style: {
                      "span": Style(
                        fontFamily: 'Cairo',
                        fontSize: FontSize(16.sp),
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      "font": Style(
                        fontFamily: 'Cairo',
                        fontSize: FontSize(16.sp),
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      ".copyable-text": Style(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        textDecoration: TextDecoration.underline,
                      ),
                    },
                  ),
                ),
                SizedBox(height: 8.h),

                // عرض الصورة إذا كانت متوفرة
                if (imageUrl != null)
                  Image.network(
                    imageUrl,
                    height: 200.h,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
                SizedBox(height: 16.h),

                // عرض النموذج إذا كانت هناك حقول للنموذج
                if (formData.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'يرجى إدخال البيانات المطلوبة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Builder(builder: (context) {
                        // حفظ معرف النموذج للاستخدام في الإرسال
                        if (formId.isNotEmpty) {
                          _formData['form_id'] = formId;
                        }
                        return DynamicFormBuilder(
                          formData: formData,
                          onFormDataChanged: (newData) {
                            _formData.addAll(newData);
                          },
                        );
                      }),
                    ],
                  )
                else
                  // عرض بديل إذا لم تكن هناك حقول للنموذج
                  Container(
                    padding: EdgeInsets.all(16.h),
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF1F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFF5951F), size: 32),
                        SizedBox(height: 8.h),
                        Text(
                          'لا توجد حقول مطلوبة للإدخال',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16.h),
                // Add a StatefulBuilder for the submit button to manage loading state
                StatefulBuilder(builder: (context, setState) {
                  bool isSubmitting = false;

                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setState(() => isSubmitting = true);

                              try {
                                final exchangeId =
                                    transactionDetails["exchange"]
                                            ?["exchange_id"] ??
                                        widget.exchangeId;

                                // Process any file uploads in form before submitting
                                List<String> fileKeys = [];
                                _formData.forEach((key, value) {
                                  if (value is String &&
                                      value.startsWith("/data/")) {
                                    fileKeys.add(key);
                                  }
                                });

                                // Upload any files first
                                for (String key in fileKeys) {
                                  String filePath = _formData[key];
                                  log("🔵 Processing file upload for '$key': $filePath");

                                  try {
                                    // IMPORTANT: Using 'image' parameter name as required by the API
                                    FormData imageData = FormData.fromMap({
                                      'image': await MultipartFile.fromFile(
                                        filePath,
                                        filename: filePath.split('/').last,
                                      )
                                    });

                                    log("🔵 Uploading file for '$key'...");
                                    log("🔵 IMPORTANT: Using 'image' parameter as required by API");

                                    Response uploadResponse = await dio.post(
                                      'https://ha55a.exchange/api/v1/order/upload.php',
                                      data: imageData,
                                    );

                                    if (uploadResponse.statusCode == 200 &&
                                        uploadResponse.data["success"] ==
                                            true) {
                                      _formData[key] =
                                          uploadResponse.data["url"];
                                      log("🟢 Uploaded file for '$key': ${_formData[key]}");
                                    } else {
                                      log("🔴 Upload failed for '$key': ${uploadResponse.statusMessage}");
                                    }
                                  } catch (e) {
                                    log("🔴 Error uploading file for '$key': $e");
                                  }
                                }

                                // الطريقة الصحيحة للإرسال: استخدام FormData بدلاً من JSON مباشر
                                // ليتوافق مع توقعات الباك إند الذي يستخدم $_POST

                                final formDataObject = FormData.fromMap({
                                  'form_id': formId,
                                  'exchange_id': exchangeId,
                                  'data': jsonEncode(
                                      _formData) // البيانات مشفرة كـ JSON string
                                });

                                log("===========================================================");
                                log("🔵 MAP2.PHP API REQUEST FROM STEP 3:");
                                log("🔵 URL: https://ha55a.exchange/api/v1/order/map2.php");
                                log("🔵 FORM ID: $formId");
                                log("🔵 EXCHANGE ID: $exchangeId");
                                log("🔵 CONTENT TYPE: multipart/form-data (FormData)");

                                // Log form data fields in detail
                                log("🔵 FORM DATA FIELDS:");
                                _formData.forEach((key, value) {
                                  log("🔵 - Field '$key': $value");
                                });

                                log("🔵 FULL DATA PARAMETER: ${jsonEncode(_formData)}");
                                log("===========================================================");

                                final response = await dio.post(
                                  'https://ha55a.exchange/api/v1/order/map2.php',
                                  data: formDataObject,
                                  options: Options(
                                    method: 'POST',
                                    // لا نحدد Content-Type لأن Dio سيضبطه تلقائياً
                                    // مع boundary المناسب لـ multipart/form-data
                                    headers: {
                                      'Accept': 'application/json',
                                    },
                                  ),
                                );

                                if (response.statusCode == 200) {
                                  log("===========================================================");
                                  log("🟢 MAP2.PHP API RESPONSE IN STEP 3:");
                                  log("🟢 RESPONSE STATUS: ${response.statusCode}");
                                  log("🟢 FULL RESPONSE DATA: ${jsonEncode(response.data)}");

                                  // Extract and log specific fields if available
                                  if (response.data is Map) {
                                    final responseMap = response.data as Map;
                                    log("🟢 SUCCESS: ${responseMap['success']}");

                                    if (responseMap.containsKey('message')) {
                                      log("🟢 MESSAGE: ${responseMap['message']}");
                                    }

                                    if (responseMap.containsKey('order_id')) {
                                      log("🟢 ORDER ID: ${responseMap['order_id']}");
                                    }

                                    if (responseMap
                                        .containsKey('exchange_id')) {
                                      log("🟢 EXCHANGE ID: ${responseMap['exchange_id']}");
                                    }

                                    // طباعة البيانات المستلمة والمدمجة (حسب كود PHP الأصلي)
                                    if (responseMap.containsKey('received')) {
                                      log("🟢 RECEIVED DATA: ${jsonEncode(responseMap['received'])}");
                                    }

                                    if (responseMap.containsKey('merged')) {
                                      log("🟢 MERGED DATA: ${jsonEncode(responseMap['merged'])}");

                                      // طباعة تفاصيل البيانات المدمجة
                                      log("🟢 MERGED DATA DETAILS:");
                                      if (responseMap['merged'] is Map) {
                                        (responseMap['merged'] as Map)
                                            .forEach((key, value) {
                                          log("🟢 - Field '$key': ${jsonEncode(value)}");
                                        });
                                      }
                                    }

                                    // Log any additional fields if they exist
                                    responseMap.forEach((key, value) {
                                      if (![
                                        'success',
                                        'message',
                                        'order_id',
                                        'exchange_id',
                                        'received',
                                        'merged'
                                      ].contains(key)) {
                                        log("🟢 ADDITIONAL FIELD - $key: $value");
                                      }
                                    });
                                  }
                                  log("===========================================================");

                                  // الانتقال للخطوة التالية
                                  if (mounted) {
                                    setState(() {});
                                    this.setState(() {
                                      _currentStep = 3;
                                    });
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('حدث خطأ أثناء إرسال البيانات'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('حدث خطأ: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => isSubmitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5951F),
                        disabledBackgroundColor: const Color(0xFFE0E0E0),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'إرسال',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep4() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // رسالة النجاح
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF4CAF50),
                  size: 70.h,
                ),
                SizedBox(height: 16.h),
                Text(
                  'تم إرسال الطلب بنجاح',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'سنقوم بمراجعة طلبك والرد عليك في أقرب وقت',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    color: const Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 16.h),
                // تفاصيل الطلب - عرض exchange ID بدلاً من order ID
                Container(
                  padding: EdgeInsets.all(12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: const Color(0xFFF5951F), size: 24.h),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'رقم المعاملة: ${widget.exchangeId}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // زر التالي
          Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5951F).withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Drainagedetails(
                              email: '',
                              id: '${orderId!}',
                            )));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5951F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'عرض تفاصيل الطلب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  const Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderID(Map<String, dynamic> transactionDetails) {
    final String exchangeIdText =
        transactionDetails["exchange"]?["exchange_id"]?.toString() ?? '---';
    return Container(
      height: 120.h,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.black),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: exchangeIdText));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الـ ID')));
                },
              ),
              SelectableText(
                'ID الطلب $exchangeIdText',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Builder(
              builder: (context) {
                final exchange = transactionDetails["exchange"];
                final String sendCurrencyName =
                    exchange["send_currency_name"] ?? '';
                final String receiveCurrencyName =
                    exchange["receive_currency_name"] ?? '';
                final String sendCurrencySymbol =
                    exchange["send_currency_symbol"] ?? '';
                final String receiveCurrencySymbol =
                    exchange["receive_currency_symbol"] ?? '';
                String sendingAmount;
                if (sendCurrencySymbol.toUpperCase() == "IQD") {
                  sendingAmount = exchange["sending_amount"] ?? '';
                  double? value = double.tryParse(sendingAmount);
                  if (value != null) {
                    sendingAmount = value.toInt().toString();
                  }
                } else {
                  sendingAmount =
                      exchange["sending_amount_in_usd"]?.toString() ?? '';
                }
                // حساب صافي المبلغ المستلم (بعد خصم الرسوم)
                double receivingAmountVal = 0;
                double receivingChargeVal = 0;

                // الحصول على إجمالي المبلغ المستلم
                if (receiveCurrencySymbol.toUpperCase() == "IQD") {
                  final rawAmount = exchange["receiving_amount"] ?? "0";
                  receivingAmountVal = double.tryParse(rawAmount) ?? 0;
                } else {
                  receivingAmountVal =
                      (exchange["receiving_amount_in_usd"] ?? 0).toDouble();
                }

                // الحصول على قيمة الرسوم
                if (receiveCurrencySymbol.toUpperCase() == "IQD") {
                  final rawCharge = exchange["receiving_charge"] ?? "0";
                  receivingChargeVal = double.tryParse(rawCharge) ?? 0;
                } else {
                  receivingChargeVal =
                      (exchange["receiving_charge_in_usd"] ?? 0).toDouble();
                }

                // حساب صافي المبلغ (الإجمالي - الرسوم)
                final double totalReceivedVal =
                    receivingAmountVal - receivingChargeVal;
                final String receivingAmount =
                    receiveCurrencySymbol.toUpperCase() == "IQD"
                        ? totalReceivedVal.toInt().toString()
                        : totalReceivedVal.toString();

                return Text(
                  'اذا قمت بإرسال $sendingAmount عبر $sendCurrencyName - $sendCurrencySymbol سوف تحصل على مبلغ مقداره $receivingAmount عبر $receiveCurrencyName - $receiveCurrencySymbol',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xffF5951F),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return Container(
      width: .45 * MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.orange : Colors.black,
        ),
      ),
    );
  }

  // New method to transform form data into required array format
  List<Map<String, dynamic>> transformFormDataToArray(
      Map<String, dynamic> formData, Map<String, dynamic> formFields) {
    List<Map<String, dynamic>> result = [];

    formFields.forEach((key, fieldConfig) {
      if (formData.containsKey(key) && fieldConfig is Map<String, dynamic>) {
        Map<String, dynamic> fieldData = {
          "name": fieldConfig["name"] ?? key,
          "type": fieldConfig["type"] ?? "text",
          "is_showdetails": fieldConfig["is_showdetails"] ?? "0",
          "value": formData[key].toString()
        };
        result.add(fieldData);
      }
    });

    // If no data matched from formFields, create entries from the raw formData directly
    if (result.isEmpty && formData.isNotEmpty) {
      formData.forEach((key, value) {
        // Try to find any matching field in formFields to get type
        String type = "text";
        String name = key;
        String isShowDetails = "0";

        formFields.forEach((fieldKey, fieldConfig) {
          if (fieldConfig is Map<String, dynamic> &&
              (fieldConfig["name"] == key || fieldKey == key)) {
            type = fieldConfig["type"] ?? "text";
            name = fieldConfig["name"] ?? key;
            isShowDetails = fieldConfig["is_showdetails"] ?? "0";
          }
        });

        result.add({
          "name": name,
          "type": type,
          "is_showdetails": isShowDetails,
          "value": value.toString()
        });
      });
    }

    return result;
  }

  // Implementation for the missing fetchSendCurrencies method
  Future<void> _fetchSendCurrencies() async {
    try {
      var response =
          await dio.get('https://ha55a.exchange/api/v1/currencies/get.php');
      if (response.statusCode == 200 && response.data['success'] == true) {
        List currencyList = response.data['currencies'];
        setState(() {
          sendCurrencies = currencyList.map<Map<String, String>>((currency) {
            return {
              'id': currency['id'].toString(),
              'name': currency['name'].toString(),
              'image': baseUrl + currency['image'].toString(),
              'cur_sym': currency['cur_sym'].toString(),
              'sell_at': currency['sell_at']?.toString() ?? '1.0',
            };
          }).toList();
          if (sendCurrencies.isNotEmpty) {
            selectedSendCurrency = sendCurrencies.first['name'];
            selectedSendCurrencyId = sendCurrencies.first['id'];
            // تحديث curid عند اختيار العملة الافتراضية
            curid = sendCurrencies.first['id'];
            sendSellRate =
                double.parse(sendCurrencies.first['sell_at'] ?? '1.0');
            sendCurrencySymbol = sendCurrencies.first['cur_sym']!;
            _fetchReceiveCurrencies(selectedSendCurrencyId!);
          }
        });
      }
    } catch (e) {
      _showErrorMessage('Error fetching send currencies.');
    }
  }

  // Implemented related _fetchReceiveCurrencies method
  Future<void> _fetchReceiveCurrencies(String currencyId) async {
    setState(() {
      isLoadingReceiveCurrencies = true;
      receiveCurrencies = [];
      selectedReceiveCurrency = null;
    });
    try {
      var response = await dio.get(
          'https://ha55a.exchange/api/v1/currencies/get_child_currencies.php?currency_id=$currencyId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        List currencyList = response.data['currencies'];
        setState(() {
          receiveCurrencies = currencyList.map<Map<String, String>>((currency) {
            return {
              'id': currency['id'].toString(),
              'name': currency['name'].toString(),
              'image': baseUrl + currency['image'].toString(),
              'cur_sym': currency['cur_sym'].toString(),
              'buy_at': currency['buy_at']?.toString() ?? '1.0',
            };
          }).toList();
          if (receiveCurrencies.isNotEmpty) {
            selectedReceiveCurrency = receiveCurrencies.first['name'];
            selectedRecievedCurrencyId = receiveCurrencies.first['id'];
            receiveBuyRate =
                double.parse(receiveCurrencies.first['buy_at'] ?? '1.0');
            receiveCurrencySymbol = receiveCurrencies.first['cur_sym']!;
          }
        });
      }
    } catch (e) {
      _showErrorMessage('Error fetching receive currencies.');
    }
    setState(() {
      isLoadingReceiveCurrencies = false;
    });
  }

  // Helper method to show error messages
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Adding the missing build method
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: const MainDrawer(),
        backgroundColor: Colors.white,
        appBar: AppBar(
          actions: [
            GestureDetector(
              onTap: () {
                if (_currentStep == 0) {
                  Navigator.pop(context);
                  return;
                }
                setState(() {
                  _currentStep--;
                });
              },
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.black,
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) {
              return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: const ImageIcon(
                      AssetImage('assets/images/drawer_icon.png')));
            },
          ),
          title: Text(
            'عرض تفاصيل الطلب',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentStep,
          children: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
            _buildStep4(),
          ],
        ),
      ),
    );
  }

  // Implementation of Step 1
  Widget _buildStep1() {
    double height = MediaQuery.of(context).size.height;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: transactionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Skeletonizer(child: buildDummyData(snapshot));
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('حدث خطأ أثناء جلب البيانات'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد بيانات متاحة'));
                }
                transactionDetails = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOrderID(snapshot.data!),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _isSendDetailsSelected = true;
                            _pageController.jumpToPage(0);
                          },
                          child: _buildTabButton(
                              'تفاصيل الإرسال', _isSendDetailsSelected),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _isSendDetailsSelected = false);
                            _pageController.jumpToPage(1);
                          },
                          child: _buildTabButton(
                              'تفاصيل الاستلام', !_isSendDetailsSelected),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      height: height > 667 ? height * 0.6 : height * 0.75,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _isSendDetailsSelected = (index == 0);
                          });
                        },
                        children: [
                          _buildSendDetails(
                            amount: transactionDetails['sending_amount'],
                            currency:
                                transactionDetails['send_currency_symbol'],
                            cost: transactionDetails['sending_charge'],
                            totalAmount: transactionDetails[''],
                          ),
                          _buildReceiveDetails(transactionDetails),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_isSendDetailsSelected == false) {
                          setState(() => _currentStep = 1);
                        } else {
                          setState(() => _isSendDetailsSelected = false);
                          _pageController.jumpToPage(1);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5951F),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'التالي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for Step 1
  Column buildDummyData(AsyncSnapshot<Map<String, dynamic>> snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isSendDetailsSelected = true),
              child: _buildTabButton('تفاصيل الإرسال', _isSendDetailsSelected),
            ),
            GestureDetector(
              onTap: () => setState(() => _isSendDetailsSelected = false),
              child:
                  _buildTabButton('تفاصيل الاستلام', !_isSendDetailsSelected),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF5951F),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'التالي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Implementation of Step 2
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _exchangeInfoTipFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Skeletonizer(child: buildDummyStepTwo());
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('حدث خطأ أثناء جلب المعلومات'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد معلومات'));
                }
                final data = snapshot.data!;
                if (data['is_default'] == true) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          data["exchange_info_tip"] ?? "",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: walletController,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xffEFF1F9),
                            border:
                                OutlineInputBorder(borderSide: BorderSide.none),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'هذا الحقل مطلوب';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        if (data['form_data']?['form_data'] != null &&
                            data['form_data']?['form_data']
                                is Map<String, dynamic>)
                          buildDynamicForm(data['form_data']['form_data']),
                      ],
                    ),
                  );
                } else {
                  final dynamic formDataMap = data['form_data']?['form_data'];
                  if (formDataMap is Map<String, dynamic>) {
                    return buildDynamicForm(formDataMap);
                  } else {
                    return const Center(
                        child: Text('تنسيق بيانات النموذج غير صحيح'));
                  }
                }
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  // Registrar presión del botón
                  log("===========================================================");
                  log("🔵 BUTTON PRESSED - STARTING FORM SUBMISSION");

                  // Registrar el valor del wallet_id
                  log("🔵 Wallet ID value: ${walletController.text}");
                  log("🔵 Form key state: ${_formKey.currentState != null ? 'exists' : 'null'}");
                  log("===========================================================");

                  // If we are in the default form mode, try to validate
                  // even if validation fails, we continue for debugging purposes
                  bool formIsValid = true;
                  if (_formKey.currentState != null) {
                    formIsValid = _formKey.currentState!.validate();
                    log("🔵 Form validation result: ${formIsValid ? 'valid' : 'invalid'}");
                  }

                  try {
                    // Log transaction details for debugging
                    log("🔵 Transaction details available: ${transactionDetails != null ? 'yes' : 'no'}");

                    final dynamicExchangeId = transactionDetails["exchange"]
                                ?["exchange_id"]
                            ?.toString() ??
                        widget.exchangeId;

                    log("🔵 Using exchange_id: $dynamicExchangeId");

                    final checkFormUrl =
                        'https://ha55a.exchange/api/v1/order/check-form.php?exchange_id=$dynamicExchangeId';

                    log("🔵 Sending request to: $checkFormUrl");
                    final checkFormResponse = await dio.get(checkFormUrl);

                    // Log the complete response to verify its structure
                    if (checkFormResponse.statusCode == 200) {
                      log("🔵 check-form.php response status: ${checkFormResponse.statusCode}");
                      log("🔵 check-form.php response data: ${jsonEncode(checkFormResponse.data)}");
                    } else {
                      log("🔴 check-form.php error: ${checkFormResponse.statusCode} - ${checkFormResponse.statusMessage}");
                    }

                    String dynamicFormId = "defaultFormId";
                    if (checkFormResponse.statusCode == 200 &&
                        checkFormResponse.data != null) {
                      final data = checkFormResponse.data;
                      if (data is Map) {
                        // Log is_default
                        log("🔵 is_default value: ${data["is_default"]}");

                        if (data.containsKey("result") &&
                            data["result"] != null) {
                          dynamicFormId = data["result"].toString();
                        } else if (data["is_default"] == true) {
                          dynamicFormId = "0";
                        } else if (data.containsKey("form_data") &&
                            data["form_data"] is Map &&
                            data["form_data"]["id"] != null) {
                          dynamicFormId = data["form_data"]["id"].toString();
                        }
                      }
                    }

                    log("🔵 Using formId: $dynamicFormId");

                    if (dynamicFormId == "0") {
                      final walletId = walletController.text.trim();
                      final step3Url =
                          'https://ha55a.exchange/api/v1/order/step3.php?exchange_id=$dynamicExchangeId&wallet_id=$walletId';

                      log("===========================================================");
                      log("🔵 STEP3.PHP API REQUEST DETAILS:");
                      log("🔵 URL: $step3Url");
                      log("🔵 METHOD: GET");
                      log("🔵 HEADERS:");
                      log("🔵 - Content-Type: application/json");
                      log("🔵 - Accept: application/json");
                      log("🔵 PARAMETERS:");
                      log("🔵 - exchange_id: $dynamicExchangeId");
                      log("🔵 - wallet_id: $walletId");
                      log("🔵 - currency: IQD"); // Fixed currency value
                      log("🔵 - exchange_rate: 1500"); // Fixed exchange rate
                      log("🔵 - version: 1.0"); // Fixed API version
                      log("===========================================================");

                      try {
                        // First log button press to confirm this code is being executed
                        log("🔵 Button pressed, attempting API call to step3.php");

                        final step3Response = await dio.request(
                          step3Url,
                          options: Options(
                            method: 'GET',
                            headers: {
                              'Content-Type': 'application/json',
                              'Accept': 'application/json',
                            },
                          ),
                        );

                        log("===========================================================");
                        if (step3Response.statusCode == 200) {
                          log("🟢 STEP3.PHP API RESPONSE DETAILS:");
                          log("🟢 STATUS CODE: ${step3Response.statusCode}");
                          log("🟢 RESPONSE HEADERS:");
                          step3Response.headers.forEach((name, values) {
                            log("🟢 - $name: ${values.join(', ')}");
                          });
                          log("🟢 RESPONSE DATA: ${jsonEncode(step3Response.data)}");

                          // Extract specific fields from response if they exist
                          if (step3Response.data is Map) {
                            var responseMap = step3Response.data as Map;
                            log("🟢 SUCCESS: ${responseMap['success']}");
                            if (responseMap.containsKey('message')) {
                              log("🟢 MESSAGE: ${responseMap['message']}");
                            }
                            if (responseMap.containsKey('order_id')) {
                              log("🟢 ORDER ID: ${responseMap['order_id']}");
                            }
                            if (responseMap.containsKey('exchange_id')) {
                              log("🟢 EXCHANGE ID: ${responseMap['exchange_id']}");
                            }
                          }

                          setState(() {
                            _currentStep = 2;
                          });
                        } else {
                          log("🔴 STEP3.PHP API ERROR DETAILS:");
                          log("🔴 STATUS CODE: ${step3Response.statusCode}");
                          log("🔴 STATUS MESSAGE: ${step3Response.statusMessage}");
                          log("🔴 RESPONSE HEADERS:");
                          step3Response.headers.forEach((name, values) {
                            log("🔴 - $name: ${values.join(', ')}");
                          });
                          if (step3Response.data != null) {
                            log("🔴 ERROR DATA: ${jsonEncode(step3Response.data)}");
                          }
                        }
                        log("===========================================================");
                      } catch (error) {
                        log("===========================================================");
                        log("🔴 STEP3.PHP API EXCEPTION: $error");
                        if (error is DioException) {
                          log("🔴 DioException TYPE: ${error.type}");
                          log("🔴 DioException MESSAGE: ${error.message}");
                          if (error.response != null) {
                            log("🔴 STATUS CODE: ${error.response?.statusCode}");
                            log("🔴 RESPONSE DATA: ${jsonEncode(error.response?.data)}");
                          }
                        }
                        log("===========================================================");
                      }
                    } else {
                      await submitDynamicForm(
                          formId: dynamicFormId, exchangeId: dynamicExchangeId);

                      setState(() {
                        _currentStep = 2;
                      });
                    }
                  } catch (e) {
                    // log("Error in dynamic form submission: $e");
                    // log("StackTrace: $stackTrace");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5951F),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  'تأكيد الطلب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  // Helper method for Step 2
  Widget buildDummyStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dummy Step 2',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp)),
        TextFormField(
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffEFF1F9),
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            hintText: 'fieldLabel',
            hintStyle: TextStyle(fontSize: 10.sp),
          ),
        )
      ],
    );
  }

  // Helper method to build dynamic forms
  Widget buildDynamicForm(Map<String, dynamic> formFields) {
    List<Widget> fieldWidgets = [];

    formFields.forEach((key, field) {
      String fieldName = field['name'] ?? "";
      String fieldLabel = field['label'] ?? "";
      String fieldType = field['type'] ?? "text";
      List<dynamic> options = field['options'] ?? [];

      log("🔵 Processing form field: $fieldName, type: $fieldType");

      fieldWidgets.add(Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          fieldName,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ));

      switch (fieldType) {
        case "text":
          fieldWidgets.add(TextFormField(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xffEFF1F9),
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              hintText: fieldLabel.isEmpty ? fieldName : fieldLabel,
            ),
            onChanged: (value) {
              _formData[fieldName] = value;
              log("🔵 Text field value updated: $fieldName = $value");
            },
          ));
          break;
        case "file":
          fieldWidgets.add(buildFileUploadField(fieldName, fieldLabel));
          break;
        case "camerafront":
          fieldWidgets.add(buildCameraField(fieldName, fieldLabel, true));
          break;
        case "cameraback":
          fieldWidgets.add(buildCameraField(fieldName, fieldLabel, false));
          break;
        default:
          fieldWidgets.add(TextFormField(
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xffEFF1F9),
              border: OutlineInputBorder(borderSide: BorderSide.none),
              hintText: 'الرجاء كتابة رقم المحفظة',
            ),
            onChanged: (value) {
              _formData[fieldName] = value;
              log("🔵 Default field value updated: $fieldName = $value");
            },
          ));
          break;
      }
      fieldWidgets.add(SizedBox(height: 16.h));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fieldWidgets,
    );
  }

  // Method to build file upload field
  Widget buildFileUploadField(String fieldName, String fieldLabel) {
    return Container(
      height: 50,
      color: const Color(0xffEFF1F9),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _formData.containsKey(fieldName) && _formData[fieldName] != null
                    ? (_formData[fieldName].toString().contains("/")
                        ? _formData[fieldName].toString().split('/').last
                        : _formData[fieldName].toString())
                    : 'لم يتم اختيار ملف',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff909090),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffBFBFBF),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () async {
                log("🔵 File upload button pressed for field: $fieldName");
                try {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  if (result == null) {
                    log("🔵 File selection canceled for field: $fieldName");
                    return;
                  }

                  final String filePath = result.files.single.path!;
                  final String fileName = filePath.split('/').last;

                  log("🔵 File selected for $fieldName: $fileName (path: $filePath)");

                  setState(() {
                    _formData[fieldName] = filePath;
                  });

                  // Create form data for upload
                  log("===========================================================");
                  log("🔵 UPLOADING FILE FOR FIELD: $fieldName");
                  log("🔵 FILE NAME: $fileName");
                  log("🔵 FILE PATH: $filePath");
                  log("===========================================================");

                  var formData = FormData.fromMap({
                    'image': await MultipartFile.fromFile(
                      filePath,
                      filename: fileName,
                    )
                  });

                  var dio = Dio();
                  try {
                    log("🔵 Sending file upload request to: https://ha55a.exchange/api/v1/order/upload.php");
                    log("🔵 IMPORTANT: Sending file with parameter name 'image' as required by the API");

                    var response = await dio.post(
                      'https://ha55a.exchange/api/v1/order/upload.php',
                      data: formData,
                    );

                    log("===========================================================");
                    if (response.statusCode == 200) {
                      log("🟢 FILE UPLOAD RESPONSE:");
                      log("🟢 STATUS CODE: ${response.statusCode}");
                      log("🟢 RESPONSE DATA: ${jsonEncode(response.data)}");

                      var responseData = response.data;
                      if (responseData["success"] == true &&
                          responseData["url"] != null) {
                        log("🟢 FILE UPLOADED SUCCESSFULLY");
                        log("🟢 UPLOADED URL: ${responseData["url"]}");

                        // احفظ رابط الصورة في formData لاستخدامه لاحقًا في API map.php
                        final String imageUrl = responseData["url"];
                        setState(() {
                          // تحديث النموذج بالرابط الجديد بدلاً من مسار الملف المحلي
                          _formData[fieldName] = imageUrl;
                        });
                        log("🟢 FORM DATA UPDATED: Field '$fieldName' now contains URL: $imageUrl");
                        log("🟢 This URL will be sent with the form data to map.php");

                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تم رفع الملف بنجاح'),
                          backgroundColor: Colors.green,
                        ));
                      } else {
                        log("🔴 FILE UPLOAD SERVER ERROR: ${responseData["message"] ?? "Unknown error"}");

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'فشل رفع الملف: ${responseData["message"] ?? "خطأ غير معروف"}'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    } else {
                      log("🔴 FILE UPLOAD HTTP ERROR: ${response.statusCode}");
                      log("🔴 STATUS MESSAGE: ${response.statusMessage}");

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('خطأ في الخادم: ${response.statusCode}'),
                        backgroundColor: Colors.red,
                      ));
                    }
                    log("===========================================================");
                  } on DioException catch (dioError) {
                    log("===========================================================");
                    log("🔴 FILE UPLOAD DIO ERROR:");
                    log("🔴 ERROR TYPE: ${dioError.type}");
                    log("🔴 ERROR MESSAGE: ${dioError.message}");
                    if (dioError.response != null) {
                      log("🔴 STATUS CODE: ${dioError.response?.statusCode}");
                      log("🔴 RESPONSE DATA: ${jsonEncode(dioError.response?.data)}");
                    }
                    log("===========================================================");

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('خطأ في الاتصال: ${dioError.message}'),
                      backgroundColor: Colors.red,
                    ));
                  }
                } catch (e) {
                  log("===========================================================");
                  log("🔴 FILE UPLOAD EXCEPTION: $e");
                  log("===========================================================");

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('حدث خطأ أثناء رفع الملف: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: Text(
                'اختيار ملف',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build camera field (front or back)
  Widget buildCameraField(
      String fieldName, String fieldLabel, bool isFrontCamera) {
    return Container(
      height: 50,
      color: const Color(0xffEFF1F9),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _formData.containsKey(fieldName) && _formData[fieldName] != null
                    ? (_formData[fieldName].toString().contains("/")
                        ? _formData[fieldName].toString().split('/').last
                        : _formData[fieldName].toString())
                    : 'لم يتم اختيار صورة',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff909090),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffBFBFBF),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () async {
                log("🔵 Camera button pressed for field: $fieldName (${isFrontCamera ? 'front' : 'back'} camera)");
                try {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    preferredCameraDevice:
                        isFrontCamera ? CameraDevice.front : CameraDevice.rear,
                  );

                  if (pickedFile == null) {
                    log("🔵 Camera capture canceled for field: $fieldName");
                    return;
                  }

                  final String imagePath = pickedFile.path;
                  final String imageName = imagePath.split('/').last;

                  log("🔵 Image captured for $fieldName: $imageName (path: $imagePath)");

                  setState(() {
                    _formData[fieldName] = imagePath;
                  });

                  // Create form data for upload
                  log("===========================================================");
                  log("🔵 UPLOADING IMAGE FOR FIELD: $fieldName");
                  log("🔵 IMAGE NAME: $imageName");
                  log("🔵 IMAGE PATH: $imagePath");
                  log("🔵 CAMERA: ${isFrontCamera ? 'Front' : 'Back'}");
                  log("===========================================================");

                  var formData = FormData.fromMap({
                    'image': await MultipartFile.fromFile(
                      imagePath,
                      filename: imageName,
                    )
                  });

                  var dio = Dio();
                  try {
                    log("🔵 Sending image upload request to: https://ha55a.exchange/api/v1/order/upload.php");
                    log("🔵 IMPORTANT: Sending image with parameter name 'image' as required by the API");

                    var response = await dio.post(
                      'https://ha55a.exchange/api/v1/order/upload.php',
                      data: formData,
                    );

                    log("===========================================================");
                    if (response.statusCode == 200) {
                      log("🟢 IMAGE UPLOAD RESPONSE:");
                      log("🟢 STATUS CODE: ${response.statusCode}");
                      log("🟢 RESPONSE DATA: ${jsonEncode(response.data)}");

                      var responseData = response.data;
                      if (responseData["success"] == true &&
                          responseData["url"] != null) {
                        log("🟢 IMAGE UPLOADED SUCCESSFULLY");
                        log("🟢 UPLOADED URL: ${responseData["url"]}");

                        // احفظ رابط الصورة في formData لاستخدامه لاحقًا في API map.php
                        final String imageUrl = responseData["url"];
                        setState(() {
                          // تحديث النموذج بالرابط الجديد بدلاً من مسار الملف المحلي
                          _formData[fieldName] = imageUrl;
                        });
                        log("🟢 FORM DATA UPDATED: Field '$fieldName' now contains URL: $imageUrl");
                        log("🟢 This URL will be sent with the form data to map.php");

                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تم رفع الصورة بنجاح'),
                          backgroundColor: Colors.green,
                        ));
                      } else {
                        log("🔴 IMAGE UPLOAD SERVER ERROR: ${responseData["message"] ?? "Unknown error"}");

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'فشل رفع الصورة: ${responseData["message"] ?? "خطأ غير معروف"}'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    } else {
                      log("🔴 IMAGE UPLOAD HTTP ERROR: ${response.statusCode}");
                      log("🔴 STATUS MESSAGE: ${response.statusMessage}");

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('خطأ في الخادم: ${response.statusCode}'),
                        backgroundColor: Colors.red,
                      ));
                    }
                    log("===========================================================");
                  } on DioException catch (dioError) {
                    log("===========================================================");
                    log("🔴 IMAGE UPLOAD DIO ERROR:");
                    log("🔴 ERROR TYPE: ${dioError.type}");
                    log("🔴 ERROR MESSAGE: ${dioError.message}");
                    if (dioError.response != null) {
                      log("🔴 STATUS CODE: ${dioError.response?.statusCode}");
                      log("🔴 RESPONSE DATA: ${jsonEncode(dioError.response?.data)}");
                    }
                    log("===========================================================");

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('خطأ في الاتصال: ${dioError.message}'),
                      backgroundColor: Colors.red,
                    ));
                  }
                } catch (e) {
                  log("===========================================================");
                  log("🔴 IMAGE UPLOAD EXCEPTION: $e");
                  log("===========================================================");

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('حدث خطأ أثناء رفع الصورة: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: Text(
                'التقاط صورة',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for Step 1
  Widget _buildSendDetails({
    String? currency,
    String? amount,
    String? cost,
    String? totalAmount,
  }) {
    return Builder(
      builder: (context) {
        final exchange = transactionDetails["exchange"];
        final String sendCurrencyName = exchange["send_currency_name"] ?? '';
        final String sendCurrencySymbol =
            exchange["send_currency_symbol"] ?? '';
        final String sendCurrencyImage = exchange["send_currency_image"] ?? '';

        String formatValue(String rawValue, {bool isIqd = false}) {
          if (isIqd) {
            final double? value = double.tryParse(rawValue);
            return value != null ? value.toInt().toString() : rawValue;
          }
          return rawValue;
        }

        String sendingAmountStr;
        double sendingAmountVal = 0;
        if (sendCurrencySymbol.toUpperCase() == "IQD") {
          final rawAmount = exchange["sending_amount"] ?? "0";
          sendingAmountStr = formatValue(rawAmount, isIqd: true);
          sendingAmountVal = double.tryParse(rawAmount) ?? 0;
        } else {
          sendingAmountVal =
              (exchange["sending_amount_in_usd"] ?? 0).toDouble();
          sendingAmountStr = sendingAmountVal.toString();
        }

        String sendingChargeStr;
        double sendingChargeVal = 0;
        if (sendCurrencySymbol.toUpperCase() == "IQD") {
          final rawCharge = exchange["sending_charge"] ?? "0";
          sendingChargeStr = formatValue(rawCharge, isIqd: true);
          sendingChargeVal = double.tryParse(rawCharge) ?? 0;
        } else {
          sendingChargeVal =
              (exchange["sending_charge_in_usd"] ?? 0).toDouble();
          sendingChargeStr = sendingChargeVal.toString();
        }

        final double totalReceivedVal = sendingAmountVal - sendingChargeVal;
        final String totalReceivedStr =
            sendCurrencySymbol.toUpperCase() == "IQD"
                ? totalReceivedVal.toInt().toString()
                : totalReceivedVal.toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الطريقة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            SizedBox(height: 8.h),
            _buildTextField(
              sendCurrencyName,
              prefixIcon: Transform.scale(
                scale: 0.6,
                child: Image.network(
                  'https://ha55a.exchange/assets/images/currency/$sendCurrencyImage',
                  width: 16,
                  height: 16,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('العملة الاساسية للنظام',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
            const SizedBox(height: 8),
            _buildTextField(sendCurrencySymbol),
            const SizedBox(height: 20),
            Text('المبلغ',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            const SizedBox(height: 8),
            _buildTextField(sendingAmountStr),
            const SizedBox(height: 20),
            Text('التكلفة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            const SizedBox(height: 8),
            _buildTextField(sendingChargeStr, color: const Color(0xffF9282B)),
            const SizedBox(height: 20),
            Text('اجمالي مبلغ الارسال',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            SizedBox(height: 8.h),
            _buildTextField(totalReceivedStr),
          ],
        );
      },
    );
  }

  Widget _buildReceiveDetails(Map<String, dynamic> transactionDetails) {
    return Builder(
      builder: (context) {
        final exchange = transactionDetails["exchange"];
        final String receiveCurrencySymbol =
            exchange["receive_currency_symbol"] ?? '';
        final String receiveCurrencyImage =
            exchange["receive_currency_image"] ?? '';

        String formatValue(String rawValue, {bool isIqd = false}) {
          if (isIqd) {
            final double? value = double.tryParse(rawValue);
            return value != null ? value.toInt().toString() : rawValue;
          }
          return rawValue;
        }

        String receivingAmountStr;
        double receivingAmountVal = 0;
        if (receiveCurrencySymbol.toUpperCase() == "IQD") {
          final rawAmount = exchange["receiving_amount"] ?? "0";
          receivingAmountStr = formatValue(rawAmount, isIqd: true);
          receivingAmountVal = double.tryParse(rawAmount) ?? 0;
        } else {
          receivingAmountVal =
              (exchange["receiving_amount_in_usd"] ?? 0).toDouble();
          receivingAmountStr = receivingAmountVal.toString();
        }

        String receivingChargeStr;
        double receivingChargeVal = 0;
        if (receiveCurrencySymbol.toUpperCase() == "IQD") {
          final rawCharge = exchange["receiving_charge"] ?? "0";
          receivingChargeStr = formatValue(rawCharge, isIqd: true);
          receivingChargeVal = double.tryParse(rawCharge) ?? 0;
        } else {
          receivingChargeVal =
              (exchange["receiving_charge_in_usd"] ?? 0).toDouble();
          receivingChargeStr = receivingChargeVal.toString();
        }

        final double totalReceivedVal = receivingAmountVal - receivingChargeVal;
        final String totalReceivedStr =
            receiveCurrencySymbol.toUpperCase() == "IQD"
                ? totalReceivedVal.toInt().toString()
                : totalReceivedVal.toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الطريقة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            SizedBox(height: 8.h),
            _buildTextField(
              exchange["receive_currency_name"] ?? '',
              prefixIcon: Transform.scale(
                scale: 0.6,
                child: Image.network(
                  'https://ha55a.exchange/assets/images/currency/$receiveCurrencyImage',
                  width: 16,
                  height: 16,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            const Text('العملة الاساسية للنظام',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
            SizedBox(height: 8.h),
            _buildTextField(receiveCurrencySymbol),
            SizedBox(height: 20.h),
            Text('المبلغ',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            SizedBox(height: 8.h),
            _buildTextField(receivingAmountStr),
            const SizedBox(height: 20),
            Text('التكلف',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            SizedBox(height: 8.h),
            _buildTextField(receivingChargeStr, color: const Color(0xffF9282B)),
            SizedBox(height: 20.h),
            Text('اجمالي مبلغ الاستلام',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)),
            SizedBox(height: 8.h),
            _buildTextField(totalReceivedStr),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String hint, {Widget? prefixIcon, Color? color}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xffEFF1F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: color ?? Colors.black,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }
}

// Add this new widget class at the end of the file, outside the _SendMoneyStepsScreenState class
class DynamicFormBuilder extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onFormDataChanged;

  const DynamicFormBuilder({
    Key? key,
    required this.formData,
    required this.onFormDataChanged,
  }) : super(key: key);

  @override
  State<DynamicFormBuilder> createState() => _DynamicFormBuilderState();
}

class _DynamicFormBuilderState extends State<DynamicFormBuilder> {
  final Map<String, dynamic> _localFormData = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // log("DynamicFormBuilder initialized with ${widget.formData.length} fields");
    // log("Field keys: ${widget.formData.keys.join(', ')}");
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Widget buildTextFieldWidget(
      String fieldName, Map<String, dynamic> fieldConfig) {
    if (!_controllers.containsKey(fieldName)) {
      _controllers[fieldName] =
          TextEditingController(text: _localFormData[fieldName] ?? '');
    }
    return TextFormField(
      controller: _controllers[fieldName],
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xffEFF1F9),
        border: const OutlineInputBorder(borderSide: BorderSide.none),
        hintText: fieldConfig["name"] ?? fieldName,
        hintStyle: TextStyle(fontSize: 10.sp),
      ),
      onChanged: (value) {
        _localFormData[fieldName] = value;
        widget.onFormDataChanged(_localFormData);
        // log("Text field ($fieldName) value: $value");
      },
    );
  }

  Widget buildTextAreaWidget(
      String fieldName, Map<String, dynamic> fieldConfig) {
    if (!_controllers.containsKey(fieldName)) {
      _controllers[fieldName] =
          TextEditingController(text: _localFormData[fieldName] ?? '');
    }
    return TextFormField(
      controller: _controllers[fieldName],
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xffEFF1F9),
        border: const OutlineInputBorder(borderSide: BorderSide.none),
        hintText: fieldConfig["name"] ?? fieldName,
        hintStyle: TextStyle(fontSize: 10.sp),
      ),
      maxLines: 4,
      onChanged: (value) {
        _localFormData[fieldName] = value;
        widget.onFormDataChanged(_localFormData);
        // log("Text area ($fieldName) value: $value");
      },
    );
  }

  Widget buildSelectWidget(String fieldName, Map<String, dynamic> fieldConfig) {
    String? selectedValue = _localFormData[fieldName];
    final List<dynamic> options = fieldConfig["options"] ?? [];
    final String fieldLabel =
        fieldConfig["label"] ?? fieldConfig["name"] ?? fieldName;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xffEFF1F9),
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
          hint: Text(
            fieldLabel,
            style: TextStyle(fontSize: 10.sp),
          ),
          items: options.map<DropdownMenuItem<String>>((option) {
            return DropdownMenuItem<String>(
              value: option.toString(),
              child: Text(option.toString()),
            );
          }).toList(),
          value: selectedValue,
          onChanged: (value) {
            setState(() {
              selectedValue = value;
            });
            _localFormData[fieldName] = value;
            widget.onFormDataChanged(_localFormData);
            // log("Select ($fieldName) selected value: $value");
          },
        );
      },
    );
  }

  Widget buildCheckboxWidget(
      String fieldName, Map<String, dynamic> fieldConfig) {
    final List<dynamic> options = fieldConfig["options"] ?? [];
    Map<String, bool> selected = {};

    for (var option in options) {
      if (_localFormData[fieldName] != null &&
          _localFormData[fieldName] is List &&
          (_localFormData[fieldName] as List).contains(option.toString())) {
        selected[option.toString()] = true;
      } else {
        selected[option.toString()] = false;
      }
    }

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: options.map<Widget>((option) {
            String key = option.toString();
            return CheckboxListTile(
              title: Text(key),
              value: selected[key],
              onChanged: (bool? newValue) {
                setState(() {
                  selected[key] = newValue ?? false;
                  List<String> selectedValues = selected.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList();
                  _localFormData[fieldName] = selectedValues;
                });
                widget.onFormDataChanged(_localFormData);
                // log("Checkbox ($fieldName) option '$key' selected: ${selected[key]}");
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildRadioWidget(String fieldName, Map<String, dynamic> fieldConfig) {
    final List<dynamic> options = fieldConfig["options"] ?? [];
    String? selectedRadio = _localFormData[fieldName]?.toString();

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: options.map<Widget>((option) {
            return RadioListTile<String>(
              title: Text(option.toString()),
              value: option.toString(),
              groupValue: selectedRadio,
              onChanged: (value) {
                setState(() {
                  selectedRadio = value;
                  _localFormData[fieldName] = value;
                });
                widget.onFormDataChanged(_localFormData);
                // log("Radio widget ($fieldName) selected value: $value");
              },
            );
          }).toList(),
        );
      },
    );
  }

  // Updated to match backend API which expects 'image' parameter
  Widget buildFileWidget(String fieldName, Map<String, dynamic> fieldConfig) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        bool isUploading = false;

        return Container(
          height: 50,
          color: const Color(0xffEFF1F9),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    _localFormData[fieldName] != null
                        ? (_localFormData[fieldName].toString().contains("/")
                            ? _localFormData[fieldName]
                                .toString()
                                .split('/')
                                .last
                            : _localFormData[fieldName].toString())
                        : 'لم يتم اختيار ملف',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff909090),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffBFBFBF),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          log("🔵 File upload button pressed for field: $fieldName");

                          setState(() {
                            isUploading = true;
                          });

                          try {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles();
                            if (result == null) {
                              log("🔵 File selection canceled for field: $fieldName");
                              setState(() {
                                isUploading = false;
                              });
                              return;
                            }
                            final String filePath = result.files.single.path!;
                            final String fileName = filePath.split('/').last;

                            log("🔵 File selected for $fieldName: $fileName (path: $filePath)");

                            setState(() {
                              _localFormData[fieldName] = filePath;
                            });
                            widget.onFormDataChanged(_localFormData);

                            // Create form data for upload - IMPORTANT: Use 'image' parameter
                            log("===========================================================");
                            log("🔵 UPLOADING FILE FOR FIELD: $fieldName");
                            log("🔵 FILE NAME: $fileName");
                            log("🔵 FILE PATH: $filePath");
                            log("🔵 IMPORTANT: Using parameter name 'image' as required by the API");
                            log("===========================================================");

                            var formData = FormData.fromMap({
                              'image': await MultipartFile.fromFile(
                                filePath,
                                filename: fileName,
                              )
                            });

                            var dio = Dio();
                            try {
                              log("🔵 Sending file upload request to: https://ha55a.exchange/api/v1/order/upload.php");

                              var response = await dio.post(
                                'https://ha55a.exchange/api/v1/order/upload.php',
                                data: formData,
                              );

                              log("===========================================================");
                              if (response.statusCode == 200) {
                                log("🟢 FILE UPLOAD RESPONSE:");
                                log("🟢 STATUS CODE: ${response.statusCode}");
                                log("🟢 RESPONSE DATA: ${jsonEncode(response.data)}");

                                var responseData = response.data;
                                if (responseData["success"] == true &&
                                    responseData["url"] != null) {
                                  log("🟢 FILE UPLOADED SUCCESSFULLY");
                                  log("🟢 UPLOADED URL: ${responseData["url"]}");

                                  // Save image URL to form data for later use in API calls
                                  final String imageUrl = responseData["url"];
                                  setState(() {
                                    _localFormData[fieldName] = imageUrl;
                                  });
                                  widget.onFormDataChanged(_localFormData);
                                  log("🟢 FORM DATA UPDATED: Field '$fieldName' now contains URL: $imageUrl");
                                  log("🟢 This URL will be sent with the form data to map.php");

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('تم رفع الملف بنجاح'),
                                    backgroundColor: Colors.green,
                                  ));
                                } else {
                                  log("🔴 FILE UPLOAD SERVER ERROR: ${responseData["message"] ?? "Unknown error"}");

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'فشل رفع الملف: ${responseData["message"] ?? "خطأ غير معروف"}'),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              } else {
                                log("🔴 FILE UPLOAD HTTP ERROR: ${response.statusCode}");
                                log("🔴 STATUS MESSAGE: ${response.statusMessage}");

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'خطأ في الخادم: ${response.statusCode}'),
                                  backgroundColor: Colors.red,
                                ));
                              }
                              log("===========================================================");
                            } on DioException catch (dioError) {
                              log("===========================================================");
                              log("🔴 FILE UPLOAD DIO ERROR:");
                              log("🔴 ERROR TYPE: ${dioError.type}");
                              log("🔴 ERROR MESSAGE: ${dioError.message}");
                              if (dioError.response != null) {
                                log("🔴 STATUS CODE: ${dioError.response?.statusCode}");
                                log("🔴 RESPONSE DATA: ${jsonEncode(dioError.response?.data)}");
                              }
                              log("===========================================================");

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content:
                                    Text('خطأ في الاتصال: ${dioError.message}'),
                                backgroundColor: Colors.red,
                              ));
                            }
                          } catch (e) {
                            log("===========================================================");
                            log("🔴 FILE SELECTION ERROR: $e");
                            log("===========================================================");

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('حدث خطأ أثناء اختيار الملف: $e'),
                              backgroundColor: Colors.red,
                            ));
                          } finally {
                            setState(() {
                              isUploading = false;
                            });
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'اختيار ملف',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Updated camera widget to use 'image' parameter
  Widget buildCameraFrontWidget(
      String fieldName, Map<String, dynamic> fieldConfig) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setLocalState) {
        bool isUploading = false;

        return Container(
          height: 50,
          color: const Color(0xffEFF1F9),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    _localFormData[fieldName] != null
                        ? (_localFormData[fieldName].toString().contains("/")
                            ? _localFormData[fieldName]
                                .toString()
                                .split('/')
                                .last
                            : _localFormData[fieldName].toString())
                        : 'لم يتم اختيار صورة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff909090),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffBFBFBF),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          log("🔵 Camera button pressed for field: $fieldName (front camera)");

                          setLocalState(() {
                            isUploading = true;
                          });

                          try {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.camera,
                              preferredCameraDevice: CameraDevice.front,
                            );
                            if (pickedFile == null) {
                              log("🔵 Camera capture canceled for field: $fieldName");
                              setLocalState(() {
                                isUploading = false;
                              });
                              return;
                            }

                            final String imagePath = pickedFile.path;
                            final String imageName = imagePath.split('/').last;

                            log("🔵 Image captured for $fieldName: $imageName (path: $imagePath)");

                            setState(() {
                              _localFormData[fieldName] = imagePath;
                            });
                            widget.onFormDataChanged(_localFormData);

                            // Create form data for upload - IMPORTANT: Using 'image' parameter
                            log("===========================================================");
                            log("🔵 UPLOADING IMAGE FOR FIELD: $fieldName");
                            log("🔵 IMAGE NAME: $imageName");
                            log("🔵 IMAGE PATH: $imagePath");
                            log("🔵 CAMERA: Front");
                            log("🔵 IMPORTANT: Using parameter name 'image' as required by the API");
                            log("===========================================================");

                            var formData = FormData.fromMap({
                              'image': await MultipartFile.fromFile(
                                imagePath,
                                filename: imageName,
                              )
                            });

                            var dio = Dio();
                            try {
                              log("🔵 Sending image upload request to: https://ha55a.exchange/api/v1/order/upload.php");

                              var response = await dio.post(
                                'https://ha55a.exchange/api/v1/order/upload.php',
                                data: formData,
                              );

                              log("===========================================================");
                              if (response.statusCode == 200) {
                                log("🟢 IMAGE UPLOAD RESPONSE:");
                                log("🟢 STATUS CODE: ${response.statusCode}");
                                log("🟢 RESPONSE DATA: ${jsonEncode(response.data)}");

                                var responseData = response.data;
                                if (responseData["success"] == true &&
                                    responseData["url"] != null) {
                                  log("🟢 IMAGE UPLOADED SUCCESSFULLY");
                                  log("🟢 UPLOADED URL: ${responseData["url"]}");

                                  // Save image URL to form data for later use in API calls
                                  final String imageUrl = responseData["url"];
                                  setState(() {
                                    _localFormData[fieldName] = imageUrl;
                                  });
                                  widget.onFormDataChanged(_localFormData);
                                  log("🟢 FORM DATA UPDATED: Field '$fieldName' now contains URL: $imageUrl");
                                  log("🟢 This URL will be sent with the form data to map.php");

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('تم رفع الصورة بنجاح'),
                                    backgroundColor: Colors.green,
                                  ));
                                } else {
                                  log("🔴 IMAGE UPLOAD SERVER ERROR: ${responseData["message"] ?? "Unknown error"}");

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'فشل رفع الصورة: ${responseData["message"] ?? "خطأ غير معروف"}'),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              } else {
                                log("🔴 IMAGE UPLOAD HTTP ERROR: ${response.statusCode}");
                                log("🔴 STATUS MESSAGE: ${response.statusMessage}");

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'خطأ في الخادم: ${response.statusCode}'),
                                  backgroundColor: Colors.red,
                                ));
                              }
                              log("===========================================================");
                            } on DioException catch (dioError) {
                              log("===========================================================");
                              log("🔴 IMAGE UPLOAD DIO ERROR:");
                              log("🔴 ERROR TYPE: ${dioError.type}");
                              log("🔴 ERROR MESSAGE: ${dioError.message}");
                              if (dioError.response != null) {
                                log("🔴 STATUS CODE: ${dioError.response?.statusCode}");
                                log("🔴 RESPONSE DATA: ${jsonEncode(dioError.response?.data)}");
                              }
                              log("===========================================================");

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content:
                                    Text('خطأ في الاتصال: ${dioError.message}'),
                                backgroundColor: Colors.red,
                              ));
                            }
                          } catch (e) {
                            log("===========================================================");
                            log("🔴 CAMERA ERROR: $e");
                            log("===========================================================");

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('حدث خطأ أثناء التقاط الصورة: $e'),
                              backgroundColor: Colors.red,
                            ));
                          } finally {
                            setLocalState(() {
                              isUploading = false;
                            });
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'التقاط صورة',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Updated camera widget to use 'image' parameter
  Widget buildCameraBackWidget(
      String fieldName, Map<String, dynamic> fieldConfig) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setLocalState) {
        bool isUploading = false;

        return Container(
          height: 50,
          color: const Color(0xffEFF1F9),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    _localFormData[fieldName] != null
                        ? (_localFormData[fieldName].toString().contains("/")
                            ? _localFormData[fieldName]
                                .toString()
                                .split('/')
                                .last
                            : _localFormData[fieldName].toString())
                        : 'لم يتم اختيار صورة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff909090),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffBFBFBF),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          log("🔵 Camera button pressed for field: $fieldName (back camera)");

                          setLocalState(() {
                            isUploading = true;
                          });

                          try {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.camera,
                              preferredCameraDevice: CameraDevice.rear,
                            );
                            if (pickedFile == null) {
                              log("🔵 Camera capture canceled for field: $fieldName");
                              setLocalState(() {
                                isUploading = false;
                              });
                              return;
                            }

                            final String imagePath = pickedFile.path;
                            final String imageName = imagePath.split('/').last;

                            log("🔵 Image captured for $fieldName: $imageName (path: $imagePath)");

                            setState(() {
                              _localFormData[fieldName] = imagePath;
                            });
                            widget.onFormDataChanged(_localFormData);

                            // Create form data for upload - IMPORTANT: Using 'image' parameter
                            log("===========================================================");
                            log("🔵 UPLOADING IMAGE FOR FIELD: $fieldName");
                            log("🔵 IMAGE NAME: $imageName");
                            log("🔵 IMAGE PATH: $imagePath");
                            log("🔵 CAMERA: Back");
                            log("🔵 IMPORTANT: Using parameter name 'image' as required by the API");
                            log("===========================================================");

                            var formData = FormData.fromMap({
                              'image': await MultipartFile.fromFile(
                                imagePath,
                                filename: imageName,
                              )
                            });

                            var dio = Dio();
                            try {
                              log("🔵 Sending image upload request to: https://ha55a.exchange/api/v1/order/upload.php");

                              var response = await dio.post(
                                'https://ha55a.exchange/api/v1/order/upload.php',
                                data: formData,
                              );

                              log("===========================================================");
                              if (response.statusCode == 200) {
                                log("🟢 IMAGE UPLOAD RESPONSE:");
                                log("🟢 STATUS CODE: ${response.statusCode}");
                                log("🟢 RESPONSE DATA: ${jsonEncode(response.data)}");

                                var responseData = response.data;
                                if (responseData["success"] == true &&
                                    responseData["url"] != null) {
                                  log("🟢 IMAGE UPLOADED SUCCESSFULLY");
                                  log("🟢 UPLOADED URL: ${responseData["url"]}");

                                  // Save image URL to form data for later use in API calls
                                  final String imageUrl = responseData["url"];
                                  setState(() {
                                    _localFormData[fieldName] = imageUrl;
                                  });
                                  widget.onFormDataChanged(_localFormData);
                                  log("🟢 FORM DATA UPDATED: Field '$fieldName' now contains URL: $imageUrl");
                                  log("🟢 This URL will be sent with the form data to map.php");

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('تم رفع الصورة بنجاح'),
                                    backgroundColor: Colors.green,
                                  ));
                                } else {
                                  log("🔴 IMAGE UPLOAD SERVER ERROR: ${responseData["message"] ?? "Unknown error"}");

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'فشل رفع الصورة: ${responseData["message"] ?? "خطأ غير معروف"}'),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              } else {
                                log("🔴 IMAGE UPLOAD HTTP ERROR: ${response.statusCode}");
                                log("🔴 STATUS MESSAGE: ${response.statusMessage}");

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'خطأ في الخادم: ${response.statusCode}'),
                                  backgroundColor: Colors.red,
                                ));
                              }
                              log("===========================================================");
                            } on DioException catch (dioError) {
                              log("===========================================================");
                              log("🔴 IMAGE UPLOAD DIO ERROR:");
                              log("🔴 ERROR TYPE: ${dioError.type}");
                              log("🔴 ERROR MESSAGE: ${dioError.message}");
                              if (dioError.response != null) {
                                log("🔴 STATUS CODE: ${dioError.response?.statusCode}");
                                log("🔴 RESPONSE DATA: ${jsonEncode(dioError.response?.data)}");
                              }
                              log("===========================================================");

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content:
                                    Text('خطأ في الاتصال: ${dioError.message}'),
                                backgroundColor: Colors.red,
                              ));
                            }
                          } catch (e) {
                            log("===========================================================");
                            log("🔴 CAMERA ERROR: $e");
                            log("===========================================================");

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('حدث خطأ أثناء التقاط الصورة: $e'),
                              backgroundColor: Colors.red,
                            ));
                          } finally {
                            setLocalState(() {
                              isUploading = false;
                            });
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'التقاط صورة',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> fieldWidgets = [];

    // Procesar cada campo del formulario
    widget.formData.forEach((key, field) {
      // Asegurarse de que el campo sea un Map<String, dynamic>
      if (field is Map) {
        Map<String, dynamic> fieldConfig = {};
        try {
          fieldConfig = Map<String, dynamic>.from(field);
        } catch (e) {
          return; // Saltar este campo
        }

        String fieldName = fieldConfig["name"]?.toString() ?? key;
        String fieldType = fieldConfig["type"]?.toString() ?? "text";

        fieldWidgets.add(Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            fieldName,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ));

        // Llamar al constructor apropiado según el tipo de campo
        switch (fieldType) {
          case "text":
            fieldWidgets.add(buildTextFieldWidget(key, fieldConfig));
            break;
          case "textarea":
            fieldWidgets.add(buildTextAreaWidget(key, fieldConfig));
            break;
          case "select":
            fieldWidgets.add(buildSelectWidget(key, fieldConfig));
            break;
          case "checkbox":
            fieldWidgets.add(buildCheckboxWidget(key, fieldConfig));
            break;
          case "radio":
            fieldWidgets.add(buildRadioWidget(key, fieldConfig));
            break;
          case "file":
            fieldWidgets.add(buildFileWidget(key, fieldConfig));
            break;
          case "camerafront":
            fieldWidgets.add(buildCameraFrontWidget(key, fieldConfig));
            break;
          case "cameraback":
            fieldWidgets.add(buildCameraBackWidget(key, fieldConfig));
            break;
          default:
            fieldWidgets.add(TextFormField(
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xffEFF1F9),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                hintText: fieldName,
              ),
              onChanged: (value) {
                _localFormData[key] = value;
              },
            ));
            break;
        }
        fieldWidgets.add(SizedBox(height: 16.h));
      } else {
        // Saltar campos que no son mapas
      }
    });

    if (fieldWidgets.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: const Color(0xffEFF1F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'لا توجد حقول للعرض',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fieldWidgets,
    );
  }
}
