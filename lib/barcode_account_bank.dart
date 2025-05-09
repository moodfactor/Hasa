import 'package:flutter/material.dart';
import 'package:my_project/utils/custombutton.dart';

import 'order_information.dart';

class BarcodeAccountBank extends StatelessWidget {
  const BarcodeAccountBank({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "عرض تفاصيل الطلب",
            style: TextStyle(
                fontFamily: "Cairo", fontWeight: FontWeight.w600, fontSize: 16),
          ),
          titleSpacing: 0.0,
          elevation: 0,
          leading: const Icon(Icons.arrow_back_rounded),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      "صورة باركود حسابك في بنك العراق الأول*",
                      style: TextStyle(
                          fontFamily: "Cairo",
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Color(0xff5E6366)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      alignment: Alignment.centerRight,
                      width: MediaQuery.of(context).size.width * .70,
                      height: 40,
                      color: const Color(0xffEFF1F9),
                      child: const Text(
                        "لم يتم اختيار صورة بعد",
                        style: TextStyle(
                            color: Color(0xff909090),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Cairo"),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width * .25,
                      height: 40,
                      // ignore: use_full_hex_values_for_flutter_colors
                      color: const Color(0xffbfbfbfe5),
                      child: const Text(
                        "اختار صورة",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Cairo"),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              const Padding(
                padding: EdgeInsets.all(2.0),
                child: Row(
                  children: [
                    Text(
                      "الصيغ الدعومة: jpg,jpeg,png",
                      style: TextStyle(
                          fontFamily: "Cairo",
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Color(0xffFF6F6F)),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Text(
                          "الرجاء كتابة رقم الهاتف المرتبط بحسابك في FIB*",
                          style: TextStyle(
                              fontFamily: "Cairo",
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Color(0xff5E6366)),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    _buildTextField("ss"),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 2,
              ),
              Custombutton(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const OrderInformation()));
                },
                texttext: 'تاكيد الطلب',
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: Color(0xFFB3B3B3),
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
