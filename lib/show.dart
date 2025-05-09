import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ShowCaseWidget(
          builder: (context) => const HomeScreen(),
        ));
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _key1 = GlobalKey();
  final GlobalKey _key2 = GlobalKey();
  final GlobalKey _key3 = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ShowCaseWidget.of(context).startShowCase([_key1, _key2, _key3]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShowCaseView Example'),
        actions: [
          Showcase(
            key: _key1,
            description: 'هذا هو زر البحث',
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Showcase(
              key: _key2,
              description: 'هذا هو الزر الرئيسي',
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('اضغط هنا'),
              ),
            ),
            const SizedBox(height: 20),
            Showcase(
              key: _key3,
              description: 'هذا هو زر الإضافة',
              child: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
