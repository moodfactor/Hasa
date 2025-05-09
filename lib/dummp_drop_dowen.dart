import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DummyDropDown extends StatelessWidget {
  const DummyDropDown({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<String>(
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(labelText: "بحث"),
        ),
      ),
      dropdownBuilder: (context, selectedItem) {
        if (selectedItem == null) {
          return const Text("اختر العملة");
        }

        return Row(
          children: [
            Image.asset(
              'assets/images/1.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              selectedItem,
              style: TextStyle(
                fontSize: 10.sp,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        );
      },
    );
  }
}
