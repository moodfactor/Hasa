import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:my_project/currencies_list_widget.dart';
import 'package:my_project/transaction_details_screen.dart';
import 'package:my_project/drainagedetails.dart';
import 'package:my_project/form.dart';
import 'package:my_project/kycform.dart';
import 'package:my_project/send_money_step_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? fullName;
  bool isLoading = true;
  late Future<List<dynamic>> transactionsFuture;
  List<dynamic> transactions = [];
  List<dynamic> currencies = [];
  int selectedTab = 0;
  String? sendText;
  String? recieveText;
  Map<String, dynamic> userData = {};
  dynamic kv = 0;
  String? userid;
  String? profileImageUrl;

  // Special offer variables
  dynamic specialOffer;
  bool isLoadingOffer = true;
  bool offerHasError = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    transactionsFuture = fetchTransactions();
    fetchSpecialOffer();
    fetchUserData();
    getData();
  }

  Future<void> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userJson = prefs.getString('user_data');
    Map<String, dynamic> userData = jsonDecode(userJson!);
    kv = userData['kv'];
    userid = userData['id'].toString();
  }

  Future<void> fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');

    if (userJson != null) {
      userData = jsonDecode(userJson);
      setState(() {
        fullName = "${userData['firstname']}  ${userData['lastname']}";
        isLoading = false;
        profileImageUrl = userData['image'] ?? userData['image_url'];
        print("🔍 رابط صورة المستخدم: $profileImageUrl");
      });
    } else {
      String? email = prefs.getString('email');
      if (email == null || email.isEmpty) {
        setState(() {
          isLoading = false;
          fullName = "الإيميل غير موجود";
        });
        return;
      }

      try {
        var dio = Dio();
        var response = await dio.get(
          'https://ha55a.exchange/api/v1/auth/user-data.php?email=$email',
        );

        if (response.statusCode == 200) {
          var data = response.data['data'];
          await prefs.setString('user_data', jsonEncode(data));
          setState(() {
            fullName =
                "${data['firstname']} ${data['secondname']} ${data['lastname']}";
            isLoading = false;
            profileImageUrl = data['image'] ?? data['image_url'];
            print("🔍 رابط صورة المستخدم (API): $profileImageUrl");
          });
        } else {
          setState(() {
            isLoading = false;
            fullName = "فشل في جلب البيانات";
          });
        }
      } catch (e) {
        setState(() {
          isLoading = false;
          fullName = "حدث خطأ: $e";
        });
      }
    }
  }

  // Latest orders
  Future<List<dynamic>> fetchTransactions() async {
    await getData();
    var dio = Dio();
    var response = await dio.get(
      'https://ha55a.exchange/api/v1/history/last.php',
      queryParameters: {'user_id': userid},
    );
    if (response.statusCode == 200) {
      setState(() {
        transactions = response.data['data'];
      });
      return response.data['data'];
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Widget _buildCurrencyCell({String? imageUrl}) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Image.network(
          'https://ha55a.exchange/assets/images/currency/$imageUrl',
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.image_not_supported,
            size: 20,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  String formatAmount(String amount) {
    double value = double.parse(amount);
    return value.toStringAsFixed(0);
  }

  Future<List<dynamic>> fetchCurrencies() async {
    var dio = Dio();
    var response = await dio.get(
      'https://ha55a.exchange/api/v1/currencies/get.php',
    );
    if (response.statusCode == 200) {
      log('${response.data}');
      setState(() {
        currencies = response.data['currencies'];
      });
      log('enter');
      return response.data['currencies'];
    } else {
      log('false');
      throw Exception('Failed to load currencies');
    }
  }

  Future<void> fetchSpecialOffer() async {
    try {
      var dio = Dio();
      var response = await dio.get(
        'https://ha55a.exchange/api/v1/offer/get.php',
      );
      if (response.statusCode == 200 && response.data['offers'] != null) {
        List offersList = response.data['offers'];
        if (offersList.isNotEmpty) {
          setState(() {
            specialOffer = offersList[0];
            isLoadingOffer = false;
          });
        } else {
          setState(() {
            isLoadingOffer = false;
            offerHasError = true;
          });
        }
      } else {
        setState(() {
          isLoadingOffer = false;
          offerHasError = true;
        });
      }
    } catch (e) {
      log('Error fetching special offer: $e');
      setState(() {
        isLoadingOffer = false;
        offerHasError = true;
      });
    }
  }

  Future<void> _placeOrder(dynamic offer) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');
    if (userJson == null) {
      return;
    }
    Map<String, dynamic> userData = jsonDecode(userJson);
    var headers = {'Content-Type': 'application/json'};
    var data = json.encode({
      "user_id": int.tryParse(userData['id'].toString()) ?? 0,
      "send_currency_id":
          int.tryParse(offer['send_currency_id'].toString()) ?? 0,
      "receive_currency_id":
          int.tryParse(offer['receive_currency_id'].toString()) ?? 0,
      "sending_amount": int.tryParse(offer['send_amount'].toString()) ?? 0,
      "receiving_amount": int.tryParse(offer['receive_amount'].toString()) ?? 0,
    });
    try {
      var dio = Dio();
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/order/new.php',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );
      if (response.statusCode == 200 &&
          response.data['success'] == true &&
          response.data['exchange_id'] != null) {
        // Print exchange_id as a value only
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => SendMoneyStepsScreen(
              exchangeId: response.data['exchange_id'],
            ),
          ),
        );
      } else {}
      // ignore: empty_catches
    } catch (e) {}
  }

  Widget _buildSectionTitle(
    String title, {
    String? action,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                action,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialOffer() {
    if (isLoadingOffer) {
      return Center(
        child: Lottie.asset('assets/lottie/loading.json', height: 150),
      );
    }
    if (offerHasError || specialOffer == null) {
      return const Center(child: Text("لا توجد عروض متوفرة"));
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Image.network(
            specialOffer['image_path'],
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error, size: 40),
          ),
          const SizedBox(height: 8),
          Text(
            specialOffer['name'] ?? '',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${specialOffer['receive_amount']} \$',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${specialOffer['send_amount']} IQD ',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${specialOffer['before_amount']} IQD',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (userData['kv'] == 1) {
                _placeOrder(specialOffer);
              } else {
                _showKycDialog();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5951F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'اشترِ الآن',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  void _showKycDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');

    if (userJson != null) {
      Map<String, dynamic> userData = jsonDecode(userJson);
      int kycStatus = userData['kv'] ?? 0;

      if (kycStatus == 0) {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: const Text(
              "إكمال التحقق (KYC)",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              "بعض المحافظ أو العملات تتطلب التحقق (KYC) لإتمام عمليات الإرسال والاستلام. يُرجى إكمال التحقق في حسابك لتفعيلها.",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: MaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: Color(0xffF5951F),
                          width: 1.5,
                        ),
                      ),
                      color: Colors.white,
                      height: 42,
                      minWidth: 130,
                      child: const Text(
                        "إلغاء",
                        style: TextStyle(
                          color: Color(0xffF5951F),
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MaterialButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Kycform(),
                          ),
                        );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: const Color(0xffF5951F),
                      height: 42,
                      minWidth: 130,
                      child: const Text(
                        "إكمال",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else if (kycStatus == 2) {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: const Text(
              "طلب التحقق قيد المراجعة",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              "طلبك للتحقق من الحساب قيد المراجعة حاليًا. يُرجى الانتظار حتى يتم تأكيده من قبل الإدارة.",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: const Color(0xffF5951F),
                  height: 42,
                  minWidth: 130,
                  child: const Text(
                    "موافق",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (kycStatus == 1) {
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(
              id: "demo-001",
              date: DateTime.now().toString().split(' ')[0],
              sendDetails: const {
                'method': 'حسة باي',
                'currency': 'IQD',
                'amount': '13,226,000.00',
                'fees': '0.00',
                'total': '13,226,000.00',
                'image': 'https://ha55a.exchange/assets/images/logo.png',
              },
              receiveDetails: const {
                'method': 'بنك العراق الأول',
                'currency': 'USD',
                'amount': '10,000.00',
                'image':
                    'https://ha55a.exchange/assets/images/banks/iraq_first.png',
              },
            ),
          ),
        );
      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFF38659B),
                height: 120.h,
                child: Stack(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.only(right: 16.w, left: 16.w, top: 40.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.2),
                                        child: profileImageUrl != null &&
                                                profileImageUrl!.isNotEmpty
                                            ? ClipOval(
                                                child: Image.network(
                                                  profileImageUrl!,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const ImageIcon(
                                                    AssetImage(
                                                        'assets/images/account_icon.png'),
                                                    color: Colors.white,
                                                    size: 30,
                                                  ),
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null) {
                                                      return child;
                                                    }
                                                    return CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                    );
                                                  },
                                                ),
                                              )
                                            : const ImageIcon(
                                                AssetImage(
                                                    'assets/images/account_icon.png'),
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                      ),
                                      if (kv == 1)
                                        Positioned(
                                          bottom: -5,
                                          right: -5,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: const ImageIcon(
                                              AssetImage(
                                                  'assets/images/verified.png'),
                                              color: Color(0xffF5951F),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'أهلا بك',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '🙌',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      isLoading
                                          ? Row(
                                              children: [
                                                Container(
                                                  height: 14.h,
                                                  width: 120.w,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.r),
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                Container(
                                                  height: 14.h,
                                                  width: 60.w,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.r),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              fullName ?? "مستخدم حسة",
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    offset: const Offset(0, 1),
                                                    blurRadius: 2.0,
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                  ),
                                                ],
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.topLeft,
                children: [
                  Container(color: const Color(0xFF38659B), height: 100),
                  const TopHomeSection(),
                ],
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('أحدث عمليات الطلب'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<List<dynamic>>(
                  future: transactionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Lottie.asset(
                          'assets/lottie/loading.json',
                          height: 100,
                        ),
                      );
                    } else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
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
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "لا يوجد بيانات متاحة",
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF666666),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    List<dynamic> filteredTransactions = snapshot.data!;
                    return Container(
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
                      child: Column(
                        children: [
                          // Header row
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                topLeft: Radius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "رقم الطلب",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "المبلغ",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "العملات",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "التاريخ",
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Transactions rows
                          ...filteredTransactions.map((transaction) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Drainagedetails(
                                      id: transaction['id'].toString(),
                                      email: '',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Order ID
                                    Text(
                                      "#${transaction['id']}",
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF38659B),
                                      ),
                                    ),
                                    // Amount
                                    Text(
                                      '${formatAmount(transaction['sending_amount'])} ${transaction['send_currency_details']['cur_sym']}',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    // Currency icons
                                    Row(
                                      children: [
                                        _buildCurrencyCell(
                                          imageUrl: transaction[
                                              'send_currency_details']['image'],
                                        ),
                                        const Icon(Icons.arrow_forward,
                                            size: 16, color: Colors.grey),
                                        _buildCurrencyCell(
                                          imageUrl: transaction[
                                                  'receive_currency_details']
                                              ['image'],
                                        ),
                                      ],
                                    ),
                                    // Date
                                    Text(
                                      transaction['created_at'] != null
                                          ? transaction['created_at']
                                              .split(' ')[0]
                                          : (transaction['date'] != null
                                              ? transaction['date']
                                                  .toString()
                                                  .split(' ')[0]
                                              : 'N/A'),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('احتياطى العملات'),
              const SizedBox(height: 8),
              const CurrenciesListWidget(),
              const SizedBox(height: 30),
              Row(
                children: [_buildSectionTitle('أحدث العروض'), const Spacer()],
              ),
              const SizedBox(height: 8),
              _buildSpecialOffer(),
              const SizedBox(height: 30), // Add bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
