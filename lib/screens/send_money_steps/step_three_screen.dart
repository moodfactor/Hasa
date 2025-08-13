import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class StepThreeScreen extends StatefulWidget {
  const StepThreeScreen({
    Key? key,
    required this.onNextPressed,
    required this.transactionDetails,
  }) : super(key: key);

  final VoidCallback onNextPressed;
  final Map<String, dynamic> transactionDetails;

  @override
  State<StepThreeScreen> createState() => _StepThreeScreenState();
}

class _StepThreeScreenState extends State<StepThreeScreen> {
  final Dio dio = Dio();
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    log("🔵 Step 3 Screen Initialized");
    log("🔵 Transaction Details: ${jsonEncode(widget.transactionDetails)}");
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchSendConfirmData() async {
    final sendCurrencyId = widget.transactionDetails["exchange"]
                ?["send_currency_id"]
            ?.toString() ??
        "4222";
    final url =
        'https://ha55a.exchange/api/v1/order/send-confirm.php?id=$sendCurrencyId';

    log("===========================================================");
    log("🔵 SEND-CONFIRM API REQUEST DETAILS:");
    log("🔵 URL: $url");
    log("🔵 METHOD: GET");
    log("🔵 PARAMETERS:");
    log("🔵 - id: $sendCurrencyId");
    log("🔵 - currency: IQD"); // Fixed currency value
    log("🔵 - exchange_rate: 1500"); // Fixed exchange rate
    log("🔵 - version: 1.0"); // Fixed API version
    log("===========================================================");

    try {
      final response = await dio.request(
        url,
        options: Options(
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      log("===========================================================");
      if (response.statusCode == 200) {
        log("🟢 SEND-CONFIRM API RESPONSE DETAILS:");
        log("🟢 STATUS CODE: ${response.statusCode}");
        log("🟢 RESPONSE DATA: ${jsonEncode(response.data)}");
        log("===========================================================");
        return response.data;
      } else {
        log("🔴 SEND-CONFIRM API ERROR DETAILS:");
        log("🔴 STATUS CODE: ${response.statusCode}");
        log("🔴 STATUS MESSAGE: ${response.statusMessage}");
        if (response.data != null) {
          log("🔴 ERROR DATA: ${jsonEncode(response.data)}");
        }
        log("===========================================================");
        throw Exception("Error: ${response.statusMessage}");
      }
    } catch (e) {
      log("🔴 SEND-CONFIRM API EXCEPTION: $e");
      log("===========================================================");
      rethrow;
    }
  }

  Future<void> submitDynamicForm2() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final exchangeId =
          widget.transactionDetails["exchange"]?["exchange_id"] ?? "";

      log("===========================================================");
      log("🔵 SUBMITTING DYNAMIC FORM:");
      log("🔵 Exchange ID: $exchangeId");
      log("🔵 Form Data: ${jsonEncode(_formData)}");
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

        final transformedFormData = transformFormData(_formData);
        log("🔵 Transformed Form Data: ${jsonEncode(transformedFormData)}");

        final requestData = {
          'form_id': dynamicFormId,
          'data': jsonEncode(transformedFormData),
          'exchange_id': exchangeId,
          'currency': 'IQD', // Fixed currency value
          'exchange_rate': '1500', // Fixed exchange rate
          'version': '1.0', // Fixed API version
        };

        log("🔵 Submitting dynamic form with data: ${jsonEncode(requestData)}");

        var data = FormData.fromMap(requestData);

        var response = await dio.request(
          'https://ha55a.exchange/api/v1/order/map2.php',
          options: Options(
            method: 'POST',
            contentType: 'multipart/form-data',
            headers: {
              'Accept': 'application/json',
            },
          ),
          data: data,
        );

        log("===========================================================");
        if (response.statusCode == 200) {
          log("🟢 MAP2 API RESPONSE DETAILS:");
          log("🟢 STATUS CODE: ${response.statusCode}");
          log("🟢 RESPONSE DATA: ${jsonEncode(response.data)}");
          log("===========================================================");

          // Successfully submitted form, proceed to next step
          setState(() {
            _isLoading = false;
          });
          widget.onNextPressed();
        } else {
          log("🔴 MAP2 API ERROR DETAILS:");
          log("🔴 STATUS CODE: ${response.statusCode}");
          log("🔴 STATUS MESSAGE: ${response.statusMessage}");
          if (response.data != null) {
            log("🔴 ERROR DATA: ${jsonEncode(response.data)}");
          }
          log("===========================================================");

          setState(() {
            _isLoading = false;
            _errorMessage = 'فشل في تقديم النموذج. يرجى المحاولة مرة أخرى.';
          });
        }
      } else {
        log("🔴 CHECK-FORM-2 API ERROR: ${dynamicFormResponse.statusCode}");
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في التحقق من النموذج. يرجى المحاولة مرة أخرى.';
        });
      }
    } catch (e) {
      log("🔴 Error in submitDynamicForm2: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء تقديم النموذج.';
      });
    }
  }

  Map<String, dynamic> transformFormData(Map<String, dynamic> formData) {
    Map<String, dynamic> transformed = {};
    formData.forEach((key, value) {
      if (value is Map) {
        transformed[key] = {
          ...value,
          'value':
              value.containsKey('value') ? value['value'] : value.toString()
        };
      } else {
        transformed[key] = {'value': value.toString()};
      }
    });
    return transformed;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchSendConfirmData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/lottie/loading.json', height: 150),
                SizedBox(height: 20.h),
                Text(
                  _isLoading
                      ? 'جاري معالجة النموذج...'
                      : 'جاري تحميل التعليمات...',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'حدث خطأ أثناء جلب التعليمات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Refresh
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5951F),
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        final data = snapshot.data!;
        final instruction = data["instruction"] ?? "";
        final image = data["image"] ?? "";
        final formData = data["form_data"] ?? {};
        final imageUrl = 'https://ha55a.exchange/assets/images/currency/$image';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step description in both languages
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Step 3: Follow Instructions and Submit Information",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Here you'll provide the necessary information for completing your transaction. Follow the instructions shown below and fill in all required fields.",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "الخطوة الثالثة: اتبع التعليمات وقدم المعلومات المطلوبة",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "هنا ستقدم المعلومات اللازمة لإتمام المعاملة. اتبع التعليمات الموضحة أدناه واملأ جميع الحقول المطلوبة.",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Instructions from API
                Text(
                  "تعليمات المعاملة:",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Html(
                  data: instruction,
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
                  },
                ),
                SizedBox(height: 16.h),

                // Currency image
                if (image.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "شعار العملة:",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Image.network(
                        imageUrl,
                        height: 120.h,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error),
                      ),
                    ],
                  ),
                SizedBox(height: 24.h),

                // Form title
                if (formData.isNotEmpty)
                  Text(
                    'بيانات المعاملة:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(height: 8.h),

                // Dynamic form
                if (formData.isNotEmpty) buildDynamicForm(formData),
                SizedBox(height: 16.h),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'Cairo',
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                SizedBox(height: 24.h),

                // Submit button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : submitDynamicForm2,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5951F),
                      disabledBackgroundColor: Colors.grey,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : Text(
                            'إرسال المعلومات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildDynamicForm(Map<String, dynamic> formData) {
    List<Widget> formWidgets = [];

    formData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        String type = value['type']?.toString() ?? '';
        String label = value['label']?.toString() ?? key;

        switch (type) {
          case 'text':
            formWidgets.add(buildTextFieldWidget(label));
            break;
          case 'textarea':
            formWidgets.add(buildTextAreaWidget(label));
            break;
          // Add other form widget types as needed
        }
      } else {
        // Handle simple string values
        formWidgets.add(buildTextFieldWidget(key));
      }
      formWidgets.add(SizedBox(height: 16.h));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: formWidgets,
    );
  }

  Widget buildTextFieldWidget(String fieldName) {
    if (!_controllers.containsKey(fieldName)) {
      _controllers[fieldName] =
          TextEditingController(text: _formData[fieldName] ?? '');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fieldName,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _controllers[fieldName],
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffEFF1F9),
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            hintText: fieldName,
            hintStyle: TextStyle(fontSize: 10.sp),
          ),
          onChanged: (value) {
            _formData[fieldName] = value;
            log("🔵 Text field ($fieldName) value: $value");
          },
        ),
      ],
    );
  }

  Widget buildTextAreaWidget(String fieldName) {
    if (!_controllers.containsKey(fieldName)) {
      _controllers[fieldName] =
          TextEditingController(text: _formData[fieldName] ?? '');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fieldName,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _controllers[fieldName],
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffEFF1F9),
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            hintText: fieldName,
            hintStyle: TextStyle(fontSize: 10.sp),
          ),
          maxLines: 4,
          onChanged: (value) {
            _formData[fieldName] = value;
            log("🔵 Text area ($fieldName) value: $value");
          },
        ),
      ],
    );
  }
}
