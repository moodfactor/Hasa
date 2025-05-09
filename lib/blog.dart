import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'single_log.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, String>>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = fetchNews();
  }

  Future<List<Map<String, String>>> fetchNews() async {
    try {
      var dio = Dio();
      var response =
          await dio.get('https://ha55a.exchange/api/v1/general/blog.php');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) {
          final dataValues = item['data_values'];
          return {
            'title': dataValues['title'] as String,
            'description': dataValues['description'] as String,
            'image': dataValues['blog_image'] as String,
            'id': item['id'].toString(),
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch news');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'أخبار ومقالات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: FutureBuilder<List<Map<String, String>>>(
          future: _newsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child:
                      Lottie.asset('assets/lottie/loading.json', height: 120));
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 50, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ أثناء تحميل المقالات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _newsFuture = fetchNews();
                        });
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.article_outlined,
                        size: 50, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد مقالات متاحة حالياً',
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
              final news = snapshot.data!;
              return Padding(
                padding: EdgeInsets.all(12.r),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: news.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: width < 380
                        ? 0.75
                        : width < 600
                            ? 0.85
                            : width < 1050
                                ? 1.7
                                : 2.3,
                  ),
                  itemBuilder: (context, index) {
                    final item = news[index];
                    return _buildNewsCard(
                      context,
                      imageUrl: item['image']!,
                      title: item['title']!,
                      description: item['description']!,
                      id: item['id']!,
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildNewsCard(
    BuildContext context, {
    required String imageUrl,
    required String title,
    required String description,
    required String id,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailsScreen(newsId: id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
              child: Stack(
                children: [
                  // Placeholder
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade100,
                    highlightColor: Colors.white,
                    child: Container(
                      height: 100.h,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                    ),
                  ),
                  // Actual image
                  SizedBox(
                    height: 100.h,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade100,
                          height: 100.h,
                          width: double.infinity,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Expanded(
                      child: Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'اقرأ المزيد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
