import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

class StepOneScreen extends StatefulWidget {
  const StepOneScreen({
    Key? key,
    required this.transactionFuture,
    required this.onNextPressed,
    required this.pageController,
  }) : super(key: key);

  final Future<Map<String, dynamic>> transactionFuture;
  final VoidCallback onNextPressed;
  final PageController pageController;

  @override
  State<StepOneScreen> createState() => _StepOneScreenState();
}

class _StepOneScreenState extends State<StepOneScreen> {
  Map<String, dynamic> transactionDetails = {};
  bool _isSendDetailsSelected = true;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: widget.transactionFuture,
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
                            setState(() => _isSendDetailsSelected = true);
                            widget.pageController.jumpToPage(0);
                          },
                          child: _buildTabButton(
                              'تفاصيل الإرسال', _isSendDetailsSelected),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _isSendDetailsSelected = false);
                            widget.pageController.jumpToPage(1);
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
                        controller: widget.pageController,
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
                          widget.onNextPressed();
                        } else {
                          setState(() => _isSendDetailsSelected = false);
                          widget.pageController.jumpToPage(1);
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
          onPressed: widget.onNextPressed,
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
                String receivingAmount;
                if (receiveCurrencySymbol.toUpperCase() == "IQD") {
                  receivingAmount = exchange["receiving_amount"] ?? '';
                  double? value = double.tryParse(receivingAmount);
                  if (value != null) {
                    receivingAmount = value.toInt().toString();
                  }
                } else {
                  receivingAmount =
                      exchange["receiving_amount_in_usd"]?.toString() ?? '';
                }
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

  Widget _buildSendDetails(
      {String? amount, String? currency, String? cost, String? totalAmount}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Implementation needs to match the original
          Text(
            'تفاصيل الإرسال',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          // Add other details from the original implementation
        ],
      ),
    );
  }

  Widget _buildReceiveDetails(Map<String, dynamic> transactionDetails) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Implementation needs to match the original
          Text(
            'تفاصيل الاستلام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          // Add other details from the original implementation
        ],
      ),
    );
  }
}
