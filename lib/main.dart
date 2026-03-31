import 'package:flutter/material.dart';

import 'screens/biotech_analysis_screen.dart';

void main() {
  runApp(const BioTechApp());
}

class BioTechApp extends StatelessWidget {
  const BioTechApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FlutterPy BioPython',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          useMaterial3: true,
        ),
        home: const BiotechAnalysisScreen(),
      );
}
