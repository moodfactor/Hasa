import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NewsDetailsScreen extends StatelessWidget {
  final String newsId;

  const NewsDetailsScreen({super.key, required this.newsId});

  Future<Map<String, String>> fetchNewsDetails() async {
    try {
      var dio = Dio();
      var response =
          await dio.get('https://ha55a.exchange/api/v1/general/blog.php');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final selectedNews =
            data.firstWhere((item) => item['id'].toString() == newsId);
        final dataValues = selectedNews['data_values'];

        return {
          'title': dataValues['title'] as String,
          'description': dataValues['description'] as String,
          'image': dataValues['blog_image'] as String,
        };
      } else {
        throw Exception('Failed to fetch news details');
      }
    } catch (e) {
      throw Exception('Error fetching news details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تفاصيل المقال',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.white,
        body: FutureBuilder<Map<String, String>>(
          future: fetchNewsDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Lottie.asset('assets/lottie/loading.json', height: 120),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 50, color: Colors.grey.shade300),
                    SizedBox(height: 16.h),
                    Text(
                      'حدث خطأ أثناء تحميل المقال',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('العودة للصفحة السابقة'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.article_outlined,
                        size: 50, color: Colors.grey.shade300),
                    SizedBox(height: 16.h),
                    Text(
                      'المقال غير متاح',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final newsDetails = snapshot.data!;
              return _buildNewsContent(context, newsDetails);
            }
          },
        ),
      ),
    );
  }

  Widget _buildNewsContent(
      BuildContext context, Map<String, String> newsDetails) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Stack(
            children: [
              // Placeholder shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey.shade100,
                highlightColor: Colors.white,
                child: Container(
                  height: 200.h,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                ),
              ),
              // Actual image
              SizedBox(
                height: 200.h,
                width: double.infinity,
                child: Image.network(
                  newsDetails['image']!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade100,
                      height: 200.h,
                      width: double.infinity,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Content section
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  newsDetails['title']!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),

                SizedBox(height: 16.h),

                // Description
                Text(
                  newsDetails['description']!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15.sp,
                    height: 1.6,
                    color: const Color(0xFF64748B),
                  ),
                ),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
