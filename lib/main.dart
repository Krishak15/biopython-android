import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'screens/biotech_analysis_screen.dart';
import 'providers/analysis_hub_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BioTechApp());
}

class BioTechApp extends StatelessWidget {
  const BioTechApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => AnalysisHubProvider()
                ..checkHealth()
                ..loadSettings()),
        ],
        child: MaterialApp(
          title: 'BioPy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const BiotechAnalysisScreen(),
        ),
      );
}
