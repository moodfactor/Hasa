import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project/dummp_drop_dowen.dart';
import 'package:my_project/dummy_drop_dowen_section.dart';
import 'package:my_project/kycform.dart';
import 'package:my_project/send_money_step_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:my_project/Feature/Auth/presentation/view/login_screen.dart';

class TopHomeSection extends StatefulWidget {
  const TopHomeSection({Key? key}) : super(key: key);

  @override
  State<TopHomeSection> createState() => _TopHomeSectionState();
}

class _TopHomeSectionState extends State<TopHomeSection> {
  List<Map<String, String>> sendCurrencies = [];
  List<Map<String, String>> receiveCurrencies = [];
  String? selectedSendCurrency;
  String? selectedReceiveCurrency;
  String? selectedSendCurrencyId;
  String? selectedRecievedCurrencyId;
  bool isLoadingReceiveCurrencies = false;
  bool isSubmitting = false;
  final TextEditingController sendAmountController = TextEditingController();
  final TextEditingController receiveAmountController = TextEditingController();
  String? sendCurrencySymbol;
  String? receiveCurrencySymbol;
  double sendSellRate = 1.0;
  double receiveBuyRate = 1.0;
  String? exchangeId;
  final GlobalKey _sendCurrency = GlobalKey();
  final GlobalKey _recireveCurrency = GlobalKey();
  final GlobalKey _sendAmount = GlobalKey();
  final GlobalKey _receiveAmount = GlobalKey();
  Map<String, dynamic>? userJson;

  Future<void> _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenShowcase =
        prefs.getBool('hasSeenShowcase_AccountScreen') ?? false;

    if (!hasSeenShowcase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase(
            [_sendCurrency, _recireveCurrency, _sendAmount, _receiveAmount]);
      });
      await prefs.setBool('hasSeenShowcase_AccountScreen', true);
    }
  }

  final String baseUrl = 'https://ha55a.exchange/assets/images/currency/';
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    fetchSendCurrencies();
    _checkFirstTimeUser();

    // Flag to prevent infinite loop between listeners
    bool isUpdating = false;

    sendAmountController.addListener(() {
      if (isUpdating) return;

      if (sendAmountController.text.isEmpty) {
        isUpdating = true;
        receiveAmountController.text = '';
        isUpdating = false;
        return;
      }

      double sendAmount = double.tryParse(sendAmountController.text) ?? 0.0;

      setState(() {
        isUpdating = true;
        if (sendCurrencySymbol == receiveCurrencySymbol) {
          receiveAmountController.text = sendAmount.toStringAsFixed(2);
        } else if (sendCurrencySymbol == "IQD" &&
            receiveCurrencySymbol == "USD") {
          receiveAmountController.text =
              ((sendAmount / 1500) * receiveBuyRate).toStringAsFixed(2);
        } else if (sendCurrencySymbol == "USD" &&
            receiveCurrencySymbol == "IQD") {
          receiveAmountController.text =
              (sendAmount * 1500 * receiveBuyRate).toStringAsFixed(2);
        } else {
          receiveAmountController.text =
              (sendAmount * (sendSellRate / receiveBuyRate)).toStringAsFixed(2);
        }
        isUpdating = false;
      });
    });

    // Add listener for receive amount controller - reverse calculation
    receiveAmountController.addListener(() {
      if (isUpdating) return;

      if (receiveAmountController.text.isEmpty) {
        isUpdating = true;
        sendAmountController.text = '';
        isUpdating = false;
        return;
      }

      if (selectedSendCurrency == null || selectedReceiveCurrency == null) {
        return;
      }

      double receiveAmount =
          double.tryParse(receiveAmountController.text) ?? 0.0;

      setState(() {
        isUpdating = true;
        if (sendCurrencySymbol == receiveCurrencySymbol) {
          sendAmountController.text = receiveAmount.toStringAsFixed(2);
        } else if (sendCurrencySymbol == "IQD" &&
            receiveCurrencySymbol == "USD") {
          sendAmountController.text =
              ((receiveAmount * 1500) / receiveBuyRate).toStringAsFixed(2);
        } else if (sendCurrencySymbol == "USD" &&
            receiveCurrencySymbol == "IQD") {
          sendAmountController.text =
              ((receiveAmount / 1500) / receiveBuyRate).toStringAsFixed(2);
        } else {
          sendAmountController.text =
              (receiveAmount * (receiveBuyRate / sendSellRate))
                  .toStringAsFixed(2);
        }
        isUpdating = false;
      });
    });
  }

  @override
  void dispose() {
    sendAmountController.dispose();
    receiveAmountController.dispose();
    super.dispose();
  }

  Future<bool> _checkUserAccountStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');

    if (userJson == null) {
      _showErrorMessage('بيانات المستخدم غير موجودة.');
      return false;
    }

    Map<String, dynamic> storedUserData = jsonDecode(userJson);
    String? email = storedUserData['email'];

    if (email == null || email.isEmpty) {
      _showErrorMessage('بريد المستخدم غير موجود.');
      return false;
    }

    try {
      log("🔄 التحقق من حالة الحساب قبل إرسال الطلب...");
      var dio = Dio();
      var response = await dio.get(
        'https://ha55a.exchange/api/v1/auth/user-data.php?email=$email',
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        Map<String, dynamic> fetchedUserData = response.data['data'];

        if (fetchedUserData['status'] == 0) {
          log("🚫 تم اكتشاف حساب محظور! البريد: $email");
          await _showBlockedAccountDialog();
          await _logout();
          return false;
        }

        if (jsonEncode(storedUserData) != jsonEncode(fetchedUserData)) {
          await prefs.setString('user_data', jsonEncode(fetchedUserData));
          userJson = jsonEncode(fetchedUserData);
          this.userJson = fetchedUserData;
        }

        return true;
      } else {
        _showErrorMessage('فشل في التحقق من حالة الحساب.');
        return false;
      }
    } catch (e) {
      log("🔴 خطأ أثناء التحقق من حالة الحساب: $e");
      _showErrorMessage('حدث خطأ أثناء التحقق من حالة الحساب.');
      return false;
    }
  }

  Future<void> _showBlockedAccountDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // رأس الحوار مع خلفية حمراء وتأثير ظلال
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 24.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          // أيقونة الإغلاق مع تأثير بصري محسن
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.block,
                              color: const Color(0xFFE53935),
                              size: 36.r,
                            ),
                          ),
                          SizedBox(height: 16.r),
                          // عنوان الحوار
                          Text(
                            "الحساب محظور",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // محتوى الحوار
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.r, vertical: 24.r),
                    child: Column(
                      children: [
                        // رسالة الحظر
                        Text(
                          "عذراً، تم حظر حسابك من قبل إدارة النظام.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16.r),
                        // تفاصيل إضافية
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3F3),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: const Color(0xFFFFCDD2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: const Color(0xFFD32F2F), size: 24.r),
                                  SizedBox(width: 10.r),
                                  Expanded(
                                    child: Text(
                                      "يمكن أن يحدث هذا للأسباب التالية:",
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFD32F2F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.r),
                              _buildReasonItem("مخالفة شروط الاستخدام"),
                              _buildReasonItem("نشاط مشبوه في الحساب"),
                              _buildReasonItem("طلب من الجهات المختصة"),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.r),
                        // معلومات الاتصال مع أيقونات التواصل الاجتماعي
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F8),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.support_agent,
                                    color: const Color(0xFF38659B),
                                    size: 24.r,
                                  ),
                                  SizedBox(width: 12.r),
                                  Expanded(
                                    child: Text(
                                      "للاستفسار والمساعدة:",
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF38659B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                color: Colors.grey.withOpacity(0.3),
                                thickness: 1,
                                height: 24.r,
                              ),
                              Text(
                                "يرجى التواصل معنا عبر:",
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 16.r),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // WhatsApp
                                  _buildContactButton(
                                    icon: Icons.whatshot,
                                    color: const Color(0xFF25D366),
                                    onTap: () {
                                      // Add WhatsApp link action
                                    },
                                  ),
                                  SizedBox(width: 24.r),
                                  // Email
                                  _buildContactButton(
                                    icon: Icons.email_outlined,
                                    color: const Color(0xFF38659B),
                                    onTap: () {
                                      // Email action
                                    },
                                  ),
                                  SizedBox(width: 24.r),
                                  // Facebook
                                  _buildContactButton(
                                    icon: Icons.facebook,
                                    color: const Color(0xFF1877F2),
                                    onTap: () {
                                      // Add Facebook link action
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.r),
                              Center(
                                child: Text(
                                  "البريد الإلكتروني: support@ha55a.exchange",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12.sp,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // زر تسجيل الخروج
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.r, vertical: 16.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16.r),
                        bottomRight: Radius.circular(16.r),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5951F),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0xFFF5951F).withOpacity(0.4),
                          padding: EdgeInsets.symmetric(vertical: 12.r),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          "موافق",
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to create contact buttons
  Widget _buildContactButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        width: 48.r,
        height: 48.r,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 24.r,
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء عنصر سبب في قائمة أسباب الحظر
  Widget _buildReasonItem(String reason) {
    return Padding(
      padding: EdgeInsets.only(right: 8.r, bottom: 4.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.r),
            width: 6.r,
            height: 6.r,
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.r),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<bool> fetchOrderData() async {
    setState(() {
      isSubmitting = true;
    });

    bool isAccountActive = await _checkUserAccountStatus();
    if (!isAccountActive) {
      setState(() {
        isSubmitting = false;
      });
      return false;
    }

    final SharedPreferences pref = await SharedPreferences.getInstance();
    final String? userJson = pref.getString('user_data');

    if (userJson == null) {
      log('User data not found in SharedPreferences');
      _showErrorMessage('بيانات المستخدم غير موجودة.');
      setState(() {
        isSubmitting = false;
      });
      return false;
    }

    String userId = jsonDecode(userJson)['id'].toString();
    try {
      var response = await dio.post(
        'https://ha55a.exchange/api/v1/order/new.php',
        data: {
          "user_id": userId,
          "send_currency_id": selectedSendCurrencyId,
          "receive_currency_id": selectedRecievedCurrencyId,
          "sending_amount": sendAmountController.text,
          "receiving_amount": receiveAmountController.text,
          "is_offer": null
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        log('Success: ${response.data}');
        setState(() {
          exchangeId = response.data['exchange_id'];
        });
        return true;
      } else if (response.statusCode == 400) {
        log('Error Response: ${response.data}');
        String errorMessage =
            response.data['error'] ?? 'حدث خطأ أثناء تنفيذ الطلب';
        _showErrorMessage(errorMessage);
        setState(() {
          isSubmitting = false;
        });
        return false;
      } else {
        log('Error Response: ${response.data}');
        _showErrorMessage("حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى.");
        setState(() {
          isSubmitting = false;
        });
        return false;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        _showErrorMessage('انتهت مهلة الاتصال، يرجى التحقق من الإنترنت.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        _showErrorMessage(
            'انتهت مهلة الاستقبال، استغرق الخادم وقتاً طويلاً للرد.');
      } else if (e.type == DioExceptionType.badResponse) {
        _showErrorMessage('${e.response?.data}');
      } else if (e.type == DioExceptionType.cancel) {
        _showErrorMessage('تم إلغاء الطلب.');
      } else if (e.type == DioExceptionType.unknown) {
        _showErrorMessage('حدث خطأ غير معروف: ${e.message}');
      } else {
        _showErrorMessage('خطأ: ${e.message}');
      }
      setState(() {
        isSubmitting = false;
      });
      return false;
    } catch (e) {
      _showErrorMessage('خطأ غير متوقع: $e');
      setState(() {
        isSubmitting = false;
      });
      return false;
    }
  }

  Future<void> fetchSendCurrencies() async {
    try {
      var response =
          await dio.get('https://ha55a.exchange/api/v1/currencies/get.php');
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (response.statusCode == 200 && response.data['success'] == true) {
        List currencyList = response.data['currencies'];

        userJson = jsonDecode(prefs.getString('user_data')!);
        setState(() {
          sendCurrencies = currencyList.map((currency) {
            return {
              'id': currency['id'].toString(),
              'name': currency['name'].toString(),
              'image': baseUrl + currency['image'].toString(),
              'cur_sym': currency['cur_sym'].toString(),
              'sell_at': currency['sell_at']?.toString() ?? '1.0',
              'kyc_req': currency['kyc_req'].toString(),
            };
          }).toList();

          selectedSendCurrency = null;
          selectedSendCurrencyId = null;
          sendSellRate = 1.0;
          sendCurrencySymbol = null;
        });
      }
    } catch (e) {
      _showErrorMessage('Error fetching send currencies.');
    }
  }

  Future<void> fetchReceiveCurrencies(String currencyId) async {
    setState(() {
      isLoadingReceiveCurrencies = true;
      receiveCurrencies = [];
      selectedReceiveCurrency = null;
    });

    try {
      var response = await dio.get(
        'https://ha55a.exchange/api/v1/currencies/get_child_currencies.php?currency_id=$currencyId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        List currencyList = response.data['currencies'];

        setState(() {
          receiveCurrencies = currencyList.map((currency) {
            return {
              'id': currency['id'].toString(),
              'name': currency['name'].toString(),
              'image': baseUrl + currency['image'].toString(),
              'cur_sym': currency['cur_sym'].toString(),
              'buy_at': currency['buy_at']?.toString() ?? '1.0',
            };
          }).toList();

          selectedReceiveCurrency = null;
          selectedRecievedCurrencyId = null;
          receiveBuyRate = 1.0;
          receiveCurrencySymbol = null;
        });
      }
    } catch (e) {
      _showErrorMessage('Error fetching receive currencies.');
    }

    setState(() {
      isLoadingReceiveCurrencies = false;
    });
  }

  void _showErrorMessage(String message) {
    // تحقق من وجود كلمة "أقصى مبلغ" أو "مبلغ للإرسال" في الرسالة للتحقق من أنها خطأ حد أقصى للمبلغ
    bool isAmountLimitError = message.contains('أقصى مبلغ') ||
        message.contains('مبلغ للإرسال') ||
        message.contains('IQD') ||
        message.contains('USD');

    if (isAmountLimitError) {
      // عرض رسالة خطأ بتنسيق خاص لأخطاء حدود المبالغ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // أيقونة التحذير
                      Container(
                        width: 60.r,
                        height: 60.r,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 32.r,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // عنوان الخطأ
                      Text(
                        "تجاوز الحد الأقصى للمبلغ",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // رسالة الخطأ
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1.r,
                          ),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            height: 1.5,
                            color: Colors.red.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // زر الإغلاق
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.r),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "موافق",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      });
    } else {
      // رسائل الخطأ العادية تظهر كإشعار منبثق (SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.sp,
            ),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16.r, vertical: 16.r),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'إغلاق',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Widget _buildTextField(
      String hint, String label, GlobalKey? showcaseKey, String? showcaseDesc,
      {TextEditingController? controller, void Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 8.h),
        showcaseKey != null && showcaseDesc != null
            ? Showcase(
                key: showcaseKey,
                description: showcaseDesc,
                descTextStyle: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                tooltipBackgroundColor: Colors.white,
                tooltipPadding: EdgeInsets.all(16.r),
                tooltipBorderRadius: BorderRadius.circular(12.r),
                overlayColor: Colors.black.withOpacity(0.7),
                overlayOpacity: 0.7,
                titleAlignment: TextAlign.right,
                descriptionAlignment: TextAlign.right,
                onToolTipClick: () {
                  ShowCaseWidget.of(context).next();
                },
                child: _buildTextFieldContent(hint, controller, onChanged),
              )
            : _buildTextFieldContent(hint, controller, onChanged),
      ],
    );
  }

  Widget _buildTextFieldContent(String hint, TextEditingController? controller,
      void Function(String)? onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.r, vertical: 12.r),
          suffixIcon: controller != null && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  color: const Color(0xFF94A3B8),
                  onPressed: () {
                    controller.clear();
                    if (onChanged != null) onChanged('');
                  },
                )
              : null,
        ),
        textAlign: TextAlign.start,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 15.sp,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildDropdownSection(
      String title,
      GlobalKey showcaseKey,
      String showcaseDesc,
      List<Map<String, String>> currencies,
      String? selectedItem,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 8.h),
        currencies.isEmpty
            ? const Skeletonizer(child: DummyDropDown())
            : Showcase(
                key: showcaseKey,
                description: showcaseDesc,
                descTextStyle: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                tooltipBackgroundColor: Colors.white,
                tooltipPadding: EdgeInsets.all(16.r),
                tooltipBorderRadius: BorderRadius.circular(12.r),
                overlayColor: Colors.black.withOpacity(0.7),
                overlayOpacity: 0.7,
                titleAlignment: TextAlign.right,
                descriptionAlignment: TextAlign.right,
                onToolTipClick: () {
                  ShowCaseWidget.of(context).next();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                    color: const Color(0xFFF8FAFC),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: DropdownSearch<String>(
                    items: currencies.map((e) => e['name']!).toList(),
                    selectedItem: selectedItem,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.r, vertical: 10.r),
                        hintText: "اختر العملة",
                        hintStyle: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      textAlign: TextAlign.start,
                      textAlignVertical: TextAlignVertical.center,
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          labelText: "بحث",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                        ),
                      ),
                      containerBuilder: (context, popupWidget) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(12.r),
                            color: Colors.white,
                            child: popupWidget,
                          ),
                        );
                      },
                      itemBuilder: (context, item, isSelected) {
                        final currency =
                            currencies.firstWhere((e) => e['name'] == item);
                        return SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.r, vertical: 10.r),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFFF97316)
                                          : const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Container(
                                  width: 20.r,
                                  height: 20.r,
                                  padding: EdgeInsets.all(2.r),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6.r),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.r),
                                    child: Image.network(
                                      currency['image']!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius:
                                              BorderRadius.circular(5.r),
                                        ),
                                        child: const Icon(Icons.error_outline,
                                            size: 12, color: Color(0xFF94A3B8)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    onChanged: onChanged,
                    dropdownBuilder: (context, selectedItem) {
                      if (selectedItem == null) {
                        return Center(
                          child: Text(
                            "اختر العملة",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      }
                      final currency = currencies
                          .firstWhere((e) => e['name'] == selectedItem);
                      return SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.r),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  selectedItem,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12.sp,
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Container(
                                width: 16.r,
                                height: 16.r,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4.r),
                                  color: Colors.white,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: Image.network(
                                    currency['image']!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.error_outline,
                                            size: 8.r,
                                            color: const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(horizontal: 20.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFFBA8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: 24.r,
                ),
                SizedBox(width: 10.w),
                Text(
                  "تحويل الأموال",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 4.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 12.r,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        "آمن و موثوق",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.sp,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Form content
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dropdown row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 10,
                      child: _buildDropdownSection(
                        'أنت ترسل',
                        _sendCurrency,
                        'اختر العملة التي ترسلها',
                        sendCurrencies,
                        selectedSendCurrency,
                        (value) {
                          setState(() {
                            selectedSendCurrency = value;
                            final sendCurrency = sendCurrencies
                                .firstWhere((e) => e['name'] == value);
                            selectedSendCurrencyId = sendCurrency['id'];
                            sendSellRate =
                                double.parse(sendCurrency['sell_at'] ?? '1.0');
                            sendCurrencySymbol = sendCurrency['cur_sym']!;

                            if (sendCurrency['kyc_req'] == '1') {
                              // Check KYC status
                              if (userJson?['kv'] == 1) {
                                // KYC is active/approved, proceed normally
                                fetchReceiveCurrencies(selectedSendCurrencyId!);
                              } else if (userJson?['kv'] == 2) {
                                // KYC is under review, show review pending dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    title: Column(
                                      children: [
                                        Icon(
                                          Icons.hourglass_top,
                                          color: const Color(0xFF3498db),
                                          size: 48.r,
                                        ),
                                        SizedBox(height: 10.h),
                                        Text(
                                          "طلب التحقق قيد المراجعه",
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E293B),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      "الخاص بكم قيد المراجعة. سيتم KYC طلب تحقق إخطارك فور الانتهاء من المراجعة والموافقة عليه. يرجى الانتظار.",
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14.sp,
                                        height: 1.5,
                                        color: const Color(0xFF64748B),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    actions: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.r, vertical: 8.r),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              setState(() {
                                                selectedSendCurrency = null;
                                                selectedSendCurrencyId = null;
                                                sendSellRate = 1.0;
                                                sendCurrencySymbol = null;
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                              ),
                                              backgroundColor:
                                                  const Color(0xFF3498db),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12.r),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              "حسناً",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Cairo',
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                // KYC is not started/not approved (kv=0 or null), show complete KYC dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    title: Column(
                                      children: [
                                        Icon(
                                          Icons.verified_user_outlined,
                                          color: const Color(0xFFF97316),
                                          size: 48.r,
                                        ),
                                        SizedBox(height: 10.h),
                                        Text(
                                          "إكمال التحقق (KYC)",
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E293B),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      "بعض المحافظ أو العملات تتطلب التحقق (KYC) لإتمام عمليات الإرسال والاستلام. يُرجى إكمال التحقق في حسابك لتفعيلها.",
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14.sp,
                                        height: 1.5,
                                        color: const Color(0xFF64748B),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    actions: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.r, vertical: 8.r),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    selectedSendCurrency = null;
                                                    selectedSendCurrencyId =
                                                        null;
                                                    sendSellRate = 1.0;
                                                    sendCurrencySymbol = null;
                                                  });
                                                },
                                                style: TextButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.r),
                                                    side: const BorderSide(
                                                        color:
                                                            Color(0xFFF97316),
                                                        width: 1.5),
                                                  ),
                                                  backgroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 12.r),
                                                ),
                                                child: Text(
                                                  "إلغاء",
                                                  style: TextStyle(
                                                    color:
                                                        const Color(0xFFF97316),
                                                    fontFamily: 'Cairo',
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const Kycform()),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.r),
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFF97316),
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 12.r),
                                                  elevation: 0,
                                                ),
                                                child: Text(
                                                  "إكمال التحقق",
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
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } else {
                              fetchReceiveCurrencies(selectedSendCurrencyId!);
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Transfer icon between dropdowns
                    Container(
                      width: 30.r,
                      height: 30.r,
                      margin: EdgeInsets.only(top: 32.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: Icon(
                        Icons.swap_horiz,
                        color: const Color(0xFF64748B),
                        size: 16.r,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      flex: 10,
                      child: isLoadingReceiveCurrencies
                          ? const Skeletonizer(
                              child: SizedBox(
                                width: double.infinity,
                                child: DummyDropDowenSection(),
                              ),
                            )
                          : _buildDropdownSection(
                              'أنت تستلم',
                              _recireveCurrency,
                              'اختر العملة التي تستلمها',
                              receiveCurrencies,
                              selectedReceiveCurrency,
                              (value) {
                                setState(() {
                                  selectedReceiveCurrency = value;
                                  final receiveCurrency = receiveCurrencies
                                      .firstWhere((e) => e['name'] == value);
                                  selectedRecievedCurrencyId =
                                      receiveCurrency['id'];
                                  receiveBuyRate = double.parse(
                                      receiveCurrency['buy_at'] ?? '1.0');
                                  receiveCurrencySymbol =
                                      receiveCurrency['cur_sym']!;

                                  // Update receive amount if send amount is set
                                  if (sendAmountController.text.isNotEmpty) {
                                    double sendAmount = double.tryParse(
                                            sendAmountController.text) ??
                                        0.0;
                                    if (sendCurrencySymbol ==
                                        receiveCurrencySymbol) {
                                      receiveAmountController.text =
                                          sendAmount.toStringAsFixed(2);
                                    } else if (sendCurrencySymbol == "IQD" &&
                                        receiveCurrencySymbol == "USD") {
                                      receiveAmountController.text =
                                          ((sendAmount / 1500) * receiveBuyRate)
                                              .toStringAsFixed(2);
                                    } else if (sendCurrencySymbol == "USD" &&
                                        receiveCurrencySymbol == "IQD") {
                                      receiveAmountController.text =
                                          (sendAmount * 1500 * receiveBuyRate)
                                              .toStringAsFixed(2);
                                    } else {
                                      receiveAmountController
                                          .text = (sendAmount *
                                              (sendSellRate / receiveBuyRate))
                                          .toStringAsFixed(2);
                                    }
                                  }
                                });
                              },
                            ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Amounts row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        '0.00',
                        'ارسل المبلغ *',
                        _sendAmount,
                        'ادخل المبلغ التي تريد ارساله',
                        controller: sendAmountController,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildTextField(
                        '0.00',
                        'احصل علي المبلغ *',
                        _receiveAmount,
                        'ادخل المبلغ التي تريد استلامه',
                        controller: receiveAmountController,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Submit button
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          // Validate form
                          if (selectedSendCurrency == null) {
                            _showErrorMessage('الرجاء اختيار العملة المرسلة');
                            return;
                          }
                          if (selectedReceiveCurrency == null) {
                            _showErrorMessage('الرجاء اختيار العملة المستلمة');
                            return;
                          }
                          if (sendAmountController.text.isEmpty) {
                            _showErrorMessage('الرجاء إدخال المبلغ المرسل');
                            return;
                          }

                          bool success = await fetchOrderData();
                          if (success && exchangeId != null) {
                            setState(() {
                              isSubmitting = false;
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SendMoneyStepsScreen(
                                  exchangeId: exchangeId!,
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.r),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'ابدأ الآن',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      SizedBox(width: 8.w),
                      isSubmitting
                          ? Text(
                              'جاري التنفيذ...',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
