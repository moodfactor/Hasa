import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:my_project/home_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_project/kycform.dart';
import 'package:my_project/send_money_step_screen.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  _OffersPageState createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  List<dynamic> offers = [];
  bool isLoading = true;
  bool hasError = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchOffers();
  }

  Future<void> fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user_data');

    if (userJson != null) {
      setState(() {
        userData = jsonDecode(userJson);
      });
    } else {}
  }

  Future<void> fetchOffers() async {
    try {
      var dio = Dio();
      var response =
          await dio.get('https://ha55a.exchange/api/v1/offer/get.php');

      if (response.statusCode == 200 && response.data['offers'] != null) {
        setState(() {
          offers = response.data['offers'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _placeOrder(dynamic offer) async {
    if (userData == null) {
      return;
    }
    var headers = {'Content-Type': 'application/json'};
    var data = json.encode({
      "user_id": int.tryParse(userData!['id'].toString()) ?? 0,
      "send_currency_id":
          int.tryParse(offer['send_currency_id'].toString()) ?? 0,
      "receive_currency_id":
          int.tryParse(offer['receive_currency_id'].toString()) ?? 0,
      "sending_amount": int.tryParse(offer['send_amount'].toString()) ?? 0,
      "receiving_amount": int.tryParse(offer['receive_amount'].toString()) ?? 0,
      "is_offer": 1
    });
    try {
      var dio = Dio();
      var response = await dio.request(
        'https://ha55a.exchange/api/v1/order/new.php',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        // Print exchange id as a value only
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) =>
                SendMoneyStepsScreen(exchangeId: response.data['exchange_id']),
          ),
        );
      } else {}
      // ignore: empty_catches
    } catch (e) {}
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
                  MaterialButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                          color: Color(0xffF5951F), width: 1.5),
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
                  const SizedBox(width: 10),
                  MaterialButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Kycform()),
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
      }
    } else {}
  }

  Widget _buildOfferCard(dynamic offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.network(
              offer['image_path'],
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${offer['receive_amount']} \$',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Text(
                offer['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${offer['send_amount']} IQD ',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${offer['before_amount']} IQD',
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
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (userData != null && userData!['kv'] == 1) {
                _placeOrder(offer);
              } else {
                _showKycDialog();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5951F),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'اشترِ الآن',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoOffers() {
    return const Center(
      child: Text(
        "لا توجد عروض متاحة حاليًا، يرجى المحاولة لاحقًا.",
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo() {
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined, color: Colors.black),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            ),
          ),
          title: const Text(
            'عروض هسة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: false,
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildUserInfo(),
            Expanded(
              child: isLoading
                  ? _buildShimmerEffect()
                  : offers.isEmpty
                      ? _buildNoOffers()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: offers.length,
                          itemBuilder: (context, index) {
                            var offer = offers[index];
                            return _buildOfferCard(offer);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
