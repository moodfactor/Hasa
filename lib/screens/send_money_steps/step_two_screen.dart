import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

class StepTwoScreen extends StatefulWidget {
  const StepTwoScreen({
    Key? key,
    required this.onNextPressed,
    required this.exchangeId,
  }) : super(key: key);

  final VoidCallback onNextPressed;
  final String exchangeId;

  @override
  State<StepTwoScreen> createState() => _StepTwoScreenState();
}

class _StepTwoScreenState extends State<StepTwoScreen> {
  final Dio dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final walletController = TextEditingController();
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    walletController.dispose();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    log("🔵 Step 2 Screen Initialized");
    log("🔵 Exchange ID: ${widget.exchangeId}");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CustomScrollView(
        slivers: [
          // Step 2 Explanation Section
          SliverToBoxAdapter(
            child: StepTwoExplanation(),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: 24.h),
          ),

          // Dynamic Form Section
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: fetchExchangeInfoTip(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Skeletonizer(child: buildDummyStepTwo());
                } else if (snapshot.hasError) {
                  log("🔴 Error fetching exchange info: ${snapshot.error}");
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 40, color: Colors.red),
                        SizedBox(height: 8.h),
                        Text(
                          'حدث خطأ أثناء جلب المعلومات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Refresh
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5951F),
                          ),
                          child: Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد معلومات'));
                }
                final data = snapshot.data!;
                log("🔵 Is default form: ${data['is_default']}");

                if (data['is_default'] == true) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Form header with explanation
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            data["exchange_info_tip"] ?? "",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Wallet field title
                        Text(
                          "رقم المحفظة",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Wallet input field
                        TextFormField(
                          controller: walletController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xffEFF1F9),
                            border: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                            hintText: 'أدخل رقم المحفظة الخاص بك',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'هذا الحقل مطلوب';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            log("🔵 Wallet ID value changed: $value");
                          },
                        ),
                        SizedBox(height: 16.h),

                        // Dynamic form fields if any
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
                  // Log button press
                  log("===========================================================");
                  log("🔵 BUTTON PRESSED - STARTING FORM SUBMISSION");
                  log("🔵 Wallet ID value: ${walletController.text}");
                  log("🔵 Form key state: ${_formKey.currentState != null ? 'exists' : 'null'}");
                  log("===========================================================");

                  // Validate form if available
                  bool formIsValid = true;
                  if (_formKey.currentState != null) {
                    formIsValid = _formKey.currentState!.validate();
                    log("🔵 Form validation result: ${formIsValid ? 'valid' : 'invalid'}");
                  }

                  if (!formIsValid) {
                    log("🔴 Form validation failed, but proceeding with API call for debugging");
                  }

                  try {
                    final dynamicExchangeId = widget.exchangeId;
                    log("🔵 Using exchange_id: $dynamicExchangeId");

                    // First API call to check-form.php
                    final checkFormUrl =
                        'https://ha55a.exchange/api/v1/order/check-form.php?exchange_id=$dynamicExchangeId';

                    log("🔵 Sending request to: $checkFormUrl");
                    final checkFormResponse = await dio.get(checkFormUrl);

                    // Log complete response
                    if (checkFormResponse.statusCode == 200) {
                      log("🔵 check-form.php response status: ${checkFormResponse.statusCode}");
                      log("🔵 check-form.php response data: ${jsonEncode(checkFormResponse.data)}");
                    } else {
                      log("🔴 check-form.php error: ${checkFormResponse.statusCode} - ${checkFormResponse.statusMessage}");
                    }

                    // Determine form ID
                    String dynamicFormId = "defaultFormId";
                    if (checkFormResponse.statusCode == 200 &&
                        checkFormResponse.data != null) {
                      final data = checkFormResponse.data;
                      if (data is Map) {
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
                      // Handle default form with step3.php
                      final walletId = walletController.text.trim();
                      final step3Url =
                          'https://ha55a.exchange/api/v1/order/step3.php?exchange_id=$dynamicExchangeId&wallet_id=$walletId';

                      log("===========================================================");
                      log("🔵 STEP3 API REQUEST DETAILS:");
                      log("🔵 URL: $step3Url");
                      log("🔵 METHOD: GET");
                      log("🔵 PARAMETERS:");
                      log("🔵 - exchange_id: $dynamicExchangeId");
                      log("🔵 - wallet_id: $walletId");
                      log("🔵 - currency: IQD"); // Fixed currency value
                      log("🔵 - exchange_rate: 1500"); // Fixed exchange rate
                      log("🔵 - version: 1.0"); // Fixed API version
                      log("===========================================================");

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
                        log("🟢 STEP3 API RESPONSE DETAILS:");
                        log("🟢 STATUS CODE: ${step3Response.statusCode}");
                        log("🟢 RESPONSE DATA: ${jsonEncode(step3Response.data)}");
                        log("===========================================================");

                        widget.onNextPressed();
                      } else {
                        log("🔴 STEP3 API ERROR DETAILS:");
                        log("🔴 STATUS CODE: ${step3Response.statusCode}");
                        log("🔴 STATUS MESSAGE: ${step3Response.statusMessage}");
                        if (step3Response.data != null) {
                          log("🔴 ERROR DATA: ${jsonEncode(step3Response.data)}");
                        }
                        log("===========================================================");
                      }
                    } else {
                      // Handle dynamic form with submitDynamicForm
                      await submitDynamicForm(
                          formId: dynamicFormId, exchangeId: dynamicExchangeId);
                      widget.onNextPressed();
                    }
                  } catch (e) {
                    log("🔴 Error in form submission: $e");
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

  // STEP 2 EXPLANATION WIDGET - ENGLISH AND ARABIC
  Widget StepTwoExplanation() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // English Explanation
          Text(
            "Step 2: Form Submission & Validation",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),

          // English details
          Text(
            "In this step, you will provide the necessary information to complete your transaction:",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),

          // English bullet points
          buildBulletPoint(
              "Form Loading: The system determines whether to use a default or dynamic form."),
          buildBulletPoint(
              "Validation: All required fields must be filled correctly."),
          buildBulletPoint(
              "Form Type: Default forms (is_default=true) use a standard wallet ID field."),
          buildBulletPoint(
              "File Uploads: Some forms may require document uploads for verification."),
          buildBulletPoint(
              "API Calls: After validation, data is sent to the step3.php API for processing."),

          SizedBox(height: 20.h),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 20.h),

          // Arabic Explanation
          Text(
            "الخطوة الثانية: تقديم النموذج والتحقق",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),

          // Arabic details
          Text(
            "في هذه الخطوة، ستقدم المعلومات الضرورية لإكمال معاملتك:",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),

          // Arabic bullet points
          buildBulletPoint(
              "تحميل النموذج: يحدد النظام ما إذا كان سيستخدم نموذجًا افتراضيًا أو ديناميكيًا."),
          buildBulletPoint("التحقق: يجب ملء جميع الحقول المطلوبة بشكل صحيح."),
          buildBulletPoint(
              "نوع النموذج: تستخدم النماذج الافتراضية (is_default=true) حقل معرف المحفظة القياسي."),
          buildBulletPoint(
              "تحميل الملفات: قد تتطلب بعض النماذج تحميل مستندات للتحقق."),
          buildBulletPoint(
              "نداءات API: بعد التحقق، يتم إرسال البيانات إلى واجهة برمجة التطبيقات step3.php للمعالجة."),
        ],
      ),
    );
  }

  // Helper to build bullet points
  Widget buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF5951F),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchExchangeInfoTip() async {
    log("🔵 Fetching exchange info tip for exchange ID: ${widget.exchangeId}");

    try {
      final response = await dio.request(
        'https://ha55a.exchange/api/v1/order/check-form.php',
        queryParameters: {'exchange_id': widget.exchangeId},
        options: Options(method: 'GET'),
      );

      if (response.statusCode == 200) {
        log("🟢 Exchange info tip fetched successfully");
        return response.data;
      } else {
        log("🔴 Error fetching exchange info tip: ${response.statusCode}");
        throw Exception("Error fetching exchange info");
      }
    } catch (e) {
      log("🔴 Exception fetching exchange info tip: $e");
      rethrow;
    }
  }

  Future<void> submitDynamicForm({
    required String formId,
    required String exchangeId,
  }) async {
    log("===========================================================");
    log("🔵 SUBMITTING DYNAMIC FORM:");
    log("🔵 Form ID: $formId");
    log("🔵 Exchange ID: $exchangeId");
    log("🔵 Form Data: ${jsonEncode(_formData)}");
    log("===========================================================");

    try {
      // Convert form data to JSON format expected by PHP server
      final jsonData = jsonEncode(_formData);
      log("🔵 Transformed form data for PHP server: $jsonData");

      FormData finalData = FormData.fromMap({
        'form_id': formId,
        'data': jsonData,
        'exchange_id': exchangeId,
        'currency': 'IQD', // Fixed currency value
        'exchange_rate': '1500', // Fixed exchange rate
        'version': '1.0', // Fixed API version
      });

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

      log("===========================================================");
      if (finalResponse.statusCode == 200) {
        log("🟢 FORM SUBMISSION RESPONSE:");
        log("🟢 STATUS CODE: ${finalResponse.statusCode}");
        log("🟢 RESPONSE DATA: ${jsonEncode(finalResponse.data)}");
      } else {
        log("🔴 FORM SUBMISSION ERROR:");
        log("🔴 STATUS CODE: ${finalResponse.statusCode}");
        log("🔴 STATUS MESSAGE: ${finalResponse.statusMessage}");
        if (finalResponse.data != null) {
          log("🔴 ERROR DATA: ${jsonEncode(finalResponse.data)}");
        }
      }
      log("===========================================================");
    } catch (e) {
      log("===========================================================");
      log("🔴 FORM SUBMISSION EXCEPTION: $e");
      if (e is DioException) {
        log("🔴 DioException TYPE: ${e.type}");
        log("🔴 DioException MESSAGE: ${e.message}");
        if (e.response != null) {
          log("🔴 DioException RESPONSE: ${jsonEncode(e.response?.data)}");
        }
      }
      log("===========================================================");
    }
  }

  Widget buildDummyStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'جاري تحميل النموذج...',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'رقم المحفظة',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget buildDynamicForm(Map<String, dynamic> formFields) {
    List<Widget> fieldWidgets = [];

    formFields.forEach((key, field) {
      String fieldName = field['name'] ?? "";
      String fieldLabel = field['label'] ?? "";
      String fieldType = field['type'] ?? "text";

      fieldWidgets.add(Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          fieldName,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      switch (fieldType) {
        case "text":
          fieldWidgets.add(buildTextFieldWidget(fieldName, fieldLabel));
          break;
        default:
          fieldWidgets.add(TextFormField(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xffEFF1F9),
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              hintText: fieldLabel.isEmpty ? 'أدخل $fieldName' : fieldLabel,
            ),
            onChanged: (value) {
              _formData[fieldName] = value;
              log("🔵 Field '$fieldName' value changed: $value");
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

  Widget buildTextFieldWidget(String fieldName, String fieldLabel) {
    if (!_controllers.containsKey(fieldName)) {
      _controllers[fieldName] =
          TextEditingController(text: _formData[fieldName] ?? '');
    }

    return TextFormField(
      controller: _controllers[fieldName],
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xffEFF1F9),
        border: const OutlineInputBorder(borderSide: BorderSide.none),
        hintText: fieldLabel.isEmpty ? 'أدخل $fieldName' : fieldLabel,
      ),
      onChanged: (value) {
        _formData[fieldName] = value;
        log("🔵 Text field '$fieldName' value changed: $value");
      },
    );
  }
}
