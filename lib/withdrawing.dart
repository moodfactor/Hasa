import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Withdraw extends StatefulWidget {
  const Withdraw({super.key});

  @override
  State<Withdraw> createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          titleSpacing: 0,
          centerTitle: false,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            "السحب ",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0.h, horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleButtons(
                borderColor: Colors.transparent,
                fillColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                selectedBorderColor: Colors.transparent,
                splashColor: Colors.transparent,
                selectedColor: Colors.orange,
                color: Colors.black,
                isSelected: [selectedIndex == 0, selectedIndex == 1],
                children: [
                  Container(
                    width: .40 * MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: selectedIndex == 0
                          ? const Border(
                              bottom:
                                  BorderSide(color: Colors.orange, width: 1))
                          : null,
                    ),
                    child: Text(
                      'سحب الاموال',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: .40 * MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: selectedIndex == 1
                          ? const Border(
                              bottom:
                                  BorderSide(color: Colors.orange, width: 1))
                          : null,
                    ),
                    child: Text(
                      'سجل السحب',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                onPressed: (int index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: selectedIndex == 0
                    ? const WithdrawFundsPage()
                    : const WithdrawHistoryPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Withdraw Funds
class WithdrawFundsPage extends StatefulWidget {
  const WithdrawFundsPage({super.key});

  @override
  State<WithdrawFundsPage> createState() => _WithdrawFundsPageState();
}

class _WithdrawFundsPageState extends State<WithdrawFundsPage> {
  String? selectedItemSend;
  String? selectedItemget;
  TextEditingController sendMoney = TextEditingController();

  final List<String> items = [
    "تحويل بنكي",
    "محفظة إلكترونية",
    "باي بال",
    "ويسترن يونيون"
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "سحب الرصيد",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        fontSize: 16.sp,
                        fontFamily: 'Cairo',
                        color: Colors.black),
                  ),
                  Text(
                    'رصيدك الحالي هو 0.00 IQD',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                        fontFamily: 'Cairo',
                        color: Colors.black),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Text(
                        "حدد طريقة السحب",
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12.sp,
                            fontFamily: 'Cairo'),
                      ),
                      Text(
                        "*",
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16.sp,
                            fontFamily: 'Cairo',
                            color: Colors.red),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  buildDropdown(selectedItemSend, "حدد طريقة السحب", (value) {
                    setState(() {
                      selectedItemSend = value;
                    });
                  }),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        "ارسل المبلغ",
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12.sp,
                            fontFamily: 'Cairo'),
                      ),
                      Text(
                        "*",
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12.sp,
                            fontFamily: 'Cairo',
                            color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  buildAmountField(sendMoney, "IQD"),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        "احصل علي المبلغ",
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12.sp,
                            fontFamily: 'Cairo'),
                      ),
                      Text(
                        "*",
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12.sp,
                            fontFamily: 'Cairo',
                            color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  buildDropdown(selectedItemget, "حدد طريقة السحب", (value) {
                    setState(() {
                      selectedItemget = value;
                    });
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: InkWell(
              onTap: () {},
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xffF5951F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(image: AssetImage("assets/images/send.png")),
                    SizedBox(width: 10),
                    Text(
                      "ارسال",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          fontFamily: "Cairo"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Method for building dropdown fields
  Widget buildDropdown(
      String? selectedItem, String hint, Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffEFF1F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: DropdownButton<String>(
        value: selectedItem,
        hint: Text(
          hint,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        style: TextStyle(
            color: Colors.black, fontSize: 16.sp, fontFamily: 'Cairo'),
        icon: const Icon(Icons.keyboard_arrow_down),
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Method for building text field with currency label
  Widget buildAmountField(TextEditingController controller, String currency) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                fillColor: Color(0xffEFF1F9),
                filled: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'ادخل المبلغ';
                }
                return null;
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(
              currency,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Withdraw History
class WithdrawHistoryPage extends StatelessWidget {
  const WithdrawHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // عناوين الجدول
          Container(
            color: const Color(0xFF031E4B),
            padding: const EdgeInsets.all(8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عمولة من',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'مستوي العمولة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'المبلغ',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'العنوان',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'العملية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // محتوى الجدول
          Container(
            color: const Color(0xFFEFF1F9),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'لا يوجد بيانات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1E1E1E),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
