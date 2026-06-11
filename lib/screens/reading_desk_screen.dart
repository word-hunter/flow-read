import 'package:flutter/material.dart';

import '../pages/reader_page.dart';

class ReadingDeskScreen extends StatelessWidget {
  const ReadingDeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ReaderPage(),
      ),
    );
  }
}
