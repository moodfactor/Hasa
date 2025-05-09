import 'package:flutter/material.dart';

class Custombutton extends StatelessWidget {
  const Custombutton({super.key, required this.onTap, required this.texttext});
  final void Function() onTap;
  final String texttext;
  @override
  Widget build(BuildContext context) {
    return               InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: 0.9 * MediaQuery.of(context).size.width,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xffF5951F),
          borderRadius: BorderRadius.circular(10),
        ),
        child:  Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
               texttext,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: "Cairo",
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),

    )
    ;
  }
}
