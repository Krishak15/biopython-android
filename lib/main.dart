import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/biotech_analysis_screen.dart';

void main() {
  runApp(const BioTechApp());
}

class BioTechApp extends StatelessWidget {
  const BioTechApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BioPy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const BiotechAnalysisScreen(),
      );
}
