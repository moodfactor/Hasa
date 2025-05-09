import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class CurrenciesListWidget extends StatefulWidget {
  const CurrenciesListWidget({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CurrenciesListWidgetState createState() => _CurrenciesListWidgetState();
}

class _CurrenciesListWidgetState extends State<CurrenciesListWidget> {
  List<Map<String, String>> currencies = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchCurrencies();
  }

  Future<void> fetchCurrencies() async {
    try {
      var dio = Dio();
      var response =
          await dio.get('https://ha55a.exchange/api/v1/currencies/get.php');
      if (response.statusCode == 200 && response.data['success'] == true) {
        List<Map<String, String>> fetchedCurrencies =
            (response.data['currencies'] as List)
                .map((currency) => {
                      'system': currency['name'].toString(),
                      'currency': 'IQD',
                      'amount': '${currency['main_reserve'].toString()} IQD',
                      'icon': currency['image'].toString(),
                    })
                .toList();
        setState(() {
          currencies = fetchedCurrencies;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = "لا يمكن تحميل بيانات العملات";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = "حدث خطأ أثناء جلب بيانات العملات";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10.r,
              offset: Offset(0, 3.h),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38659B), Color(0xFF284B73)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'الاحتياطي',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Cairo",
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'العملة الأساسية للنظام',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Cairo",
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            if (isLoading)
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Lottie.asset('assets/lottie/loading.json', height: 100),
                    SizedBox(height: 8.h),
                    Text(
                      'جاري تحميل بيانات العملات...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: 'Cairo',
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else if (hasError)
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 48.sp,
                      color: Colors.amber,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      errorMessage,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          hasError = false;
                        });
                        fetchCurrencies();
                      },
                      icon: Icon(Icons.refresh, size: 16.sp),
                      label: Text(
                        'إعادة المحاولة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF38659B),
                      ),
                    ),
                  ],
                ),
              )
            else if (currencies.isEmpty)
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48.sp,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'لا توجد بيانات متاحة',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF666666),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currencies.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1.h,
                  color: Colors.grey[200],
                  indent: 16.w,
                  endIndent: 16.w,
                ),
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  return Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Amount
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6.h, horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              currency['amount']!,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),

                        // Currency name & icon
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  '${currency['currency']} - ${currency['system']!.length > 15 ? '${currency['system'].toString().substring(0, 15)}...' : currency['system']}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade100,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(4.w),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Image.network(
                                    'https://ha55a.exchange/assets/images/currency/${currency['icon']!.isNotEmpty ? currency['icon'] : '642af4d96a9d11680536793.jpg'}',
                                    width: 24.w,
                                    height: 24.h,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.currency_exchange,
                                            size: 16.sp,
                                            color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
