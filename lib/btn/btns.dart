import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ignore: must_be_immutable
class Btn extends StatelessWidget {
  late String txt;
  late VoidCallback onPressed;

  Btn({super.key, required this.txt, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isTablet = width > 600;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0.sp),
      child: MaterialButton(
        minWidth: double.infinity,
        height: isTablet ? 75.h : 50.h,
        onPressed: onPressed,
        color: const Color(0xff031E4B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          txt,
          style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
      ),
    );
  }
}
