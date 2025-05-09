import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Feature/Auth/presentation/view/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;
  double percent = 33 / 100;

  final List<OnboardingItem> onboardingItems = [
    OnboardingItem(
      image: 'assets/images/onboarding_one.png',
      title: 'أرسل الأموال بسهولة وأمان',
      description: 'استمتع بتحويل الأموال في أي وقت وأي مكان بكل سهولة وأمان.',
      img: 'assets/images/Vector.png',
    ),
    OnboardingItem(
      image: 'assets/images/onboarding_tow.png',
      title: 'متابعة فورية للمعاملات',
      description: 'تابع حالة تحويلاتك خطوة بخطوة مع إشعارات فورية لكل عملية.',
      img: 'assets/images/Vector.png',
    ),
    OnboardingItem(
      image: 'assets/images/onboarding_three.png',
      title: 'سرعة في التحويل',
      description:
          'نفّذ معاملاتك المالية بسرعة فائقة مع واجهة استخدام سهلة ومريحة.',
      img: 'assets/images/Vector.png',
    ),
  ];

  // Navigate to login screen and save onboarding status
  Future<void> nextPage() async {
    if (currentPage < onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        percent += 0.45;
        if (percent > 1.0) percent = 1.0;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      // ✅ طباعة القيمة للتحقق من تخزينها
      debugPrint(
          "🎯 Onboarding Completed: ${prefs.getBool('onboarding_completed')}");

      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600.w;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemCount: onboardingItems.length,
              itemBuilder: (context, index) {
                final item = onboardingItems[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      item.image,
                      width: isTablet ? 800.w : 400.w,
                      height: isTablet ? 900.h : 350.h,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: isTablet ? 200.sp : 20.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        item.description,
                        style: TextStyle(
                          fontSize: isTablet ? 50.sp : 16.sp,
                          color: const Color(0xFF414141),
                          fontWeight: FontWeight.w200,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingItems.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentPage == index
                    ? (isTablet ? 40.w : 20.w)
                    : (isTablet ? 12.w : 8.w),
                height: isTablet ? 12.h : 8.h,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? const Color(0xff031E4B)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: nextPage,
            child: CircleAvatar(
              radius: isTablet ? 80.r : 45.r,
              backgroundColor: const Color(0xff031E4B),
              child: Icon(
                currentPage == onboardingItems.length - 1
                    ? Icons.check
                    : Icons.arrow_forward,
                color: Colors.white,
                size: isTablet ? 50.sp : 40.sp,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;
  final String img;

  OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
    required this.img,
  });
}
