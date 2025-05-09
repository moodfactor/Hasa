import 'package:flutter/material.dart';
import 'package:my_project/utils/custombutton.dart';

class Qrbarcode extends StatelessWidget {
  const Qrbarcode({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "عرض تفاصيل الطلب",
            style: TextStyle(
                fontFamily: "Cairo", fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              const Text(
                "الرجاء التحويل الى الحساب التالي"
                "        IBAN: IQ26AINI001002116111700"
                "        Acc. Number: 078100211610012517000"
                "او عبر الباركود ?",
                style: TextStyle(
                    fontFamily: "Cairo",
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                    color: Color(0xff031E4B)),
              ),
              const SizedBox(
                height: 30,
              ),
              Image.asset(
                "assets/images/643aremovebgpreview.png",
                height: .61 * MediaQuery.of(context).size.width,
                width: .61 * MediaQuery.of(context).size.width,
              ),
              const SizedBox(
                height: 30,
              ),
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
              SizedBox(
                height: MediaQuery.of(context).size.height / 4,
              ),
              Custombutton(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const Qrbarcode()));
                },
                texttext: 'تاكيد الطلب',
              )
            ],
          ),
        ),
      ),
    );
  }
}
