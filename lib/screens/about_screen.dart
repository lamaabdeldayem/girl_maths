// lib/screens/about_screen.dart
import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const routeName = '/about';

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final logo = Image.asset('assets/images/logo.png',
        width: landscape ? 120 : 160, height: landscape ? 120 : 160);
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.appName,
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.hotPink)),
        Text(s.appTagline, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        Text(s.aboutBody, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const Text('v2.0.0', style: TextStyle(color: Colors.grey)),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.about)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          // OrientationBuilder-style switch (Lecture 4)
          child: landscape
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    logo,
                    const SizedBox(width: 32),
                    Flexible(child: text),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [logo, const SizedBox(height: 16), text],
                ),
        ),
      ),
    );
  }
}
