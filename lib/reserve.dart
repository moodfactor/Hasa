import 'package:flutter/material.dart';

class CurrencyOptionsPage extends StatelessWidget {
  const CurrencyOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضبط الاتجاه من اليمين لليسار
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'اختيارات العملات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // شريط العناوين
              Row(
                children: [
                  _buildTabButton('الاحتياطي', isSelected: false),
                  _buildTabButton('العملة الأساسية للنظام', isSelected: true),
                ],
              ),
              const SizedBox(height: 16),
              // قائمة العملات
              Expanded(
                child: ListView.builder(
                  itemCount: 10, // عدد العناصر
                  itemBuilder: (context, index) {
                    return _buildCurrencyRow(
                      title: index % 2 == 0 ? 'IQD - أسيا باي' : 'IQD - فاستي',
                      logoPath: index % 2 == 0
                          ? 'assets/images/logo.png'
                          : 'assets/images/logo.png',
                      amount: '13,226,000.00 IQD',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // زر التبويب
  Widget _buildTabButton(String title, {required bool isSelected}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.orange : Colors.grey.shade300,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.orange : Colors.black,
          ),
        ),
      ),
    );
  }

  // صف العملة
  Widget _buildCurrencyRow({
    required String title,
    required String logoPath,
    required String amount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Image.asset(
            logoPath,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
