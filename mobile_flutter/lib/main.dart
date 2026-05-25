import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(const FoundationApp());
}

class FoundationApp extends StatelessWidget {
  const FoundationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BVisionry Connect',
      theme: buildAppTheme(Brightness.light),
      home: const Scaffold(
        body: Center(child: Text('Foundation OK')),
      ),
    );
  }
}
