import 'package:flutter/material.dart';

class OrderInformation extends StatelessWidget {
  const OrderInformation({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          titleSpacing: 0,
          title: const Text(
            "معلومات الطلب",
            style: TextStyle(
                fontFamily: "Cairo", fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Pushes elements to opposite sides
                children: [
                  MaterialButton(
                    shape: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.transparent, width: 1),
                    ),
                    onPressed: () {},
                    color: Colors.orange,
                    elevation: 0,
                    child: const Row(
                      children: [
                        Image(image: AssetImage("assets/images/printer.png")),
                        SizedBox(width: 5),
                        Text(
                          "تنزيل",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Cairo"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Text(
                'طلب ID',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Cairo",
                    color: Color(0xff5E6366)),
              ),
              const SizedBox(
                height: 5,
              ),
              TextFormField(
                decoration: InputDecoration(
                    hintText: "8YN69X3DU3ZF",
                    hintStyle: const TextStyle(
                        fontFamily: "Cairo",
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                    fillColor: const Color(0xffEFF1F9),
                    filled: true,
                    focusColor: const Color(0xffEFF1F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none)),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'معرف المحفظة / الرقم',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Cairo",
                    color: Color(0xff5E6366)),
              ),
              const SizedBox(
                height: 5,
              ),
              TextFormField(
                decoration: InputDecoration(
                    hintText: "بنك العراق الاول",
                    hintStyle: const TextStyle(
                        color: Color(0xffE96163),
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                    fillColor: const Color(0xffEFF1F9),
                    filled: true,
                    focusColor: const Color(0xffEFF1F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none)),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'الحالة',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Cairo",
                    color: Color(0xff5E6366)),
              ),
              const SizedBox(
                height: 5,
              ),
              TextFormField(
                decoration: InputDecoration(
                    hintText: "قيد الانتظار",
                    hintStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xffCF7725),
                        fontSize: 14),
                    fillColor: const Color(0xffEFF1F9),
                    filled: true,
                    focusColor: const Color(0xffEFF1F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none)),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'تاريخ الطلب',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Cairo",
                    color: Color(0xff5E6366)),
              ),
              const SizedBox(
                height: 5,
              ),
              TextFormField(
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10),
                    hintText: "2025-01-22 12:08 PM 59 minutes ago",
                    hintStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    fillColor: const Color(0xffEFF1F9),
                    filled: true,
                    focusColor: const Color(0xffEFF1F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none)),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'FIB',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: "Cairo",
                    color: Color(0xff5E6366)),
              ),
              const SizedBox(
                height: 5,
              ),
              TextFormField(
                decoration: InputDecoration(
                    hintText: "44444444444",
                    hintStyle: const TextStyle(
                        color: Color(0xff313131),
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    fillColor: const Color(0xffEFF1F9),
                    filled: true,
                    focusColor: const Color(0xffEFF1F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
