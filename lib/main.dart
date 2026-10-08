import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/constants/app_colors.dart';
import 'package:blue_pulse/core/di/injection.dart';
import 'package:blue_pulse/views/scanner/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BluePulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: .fromSeed(
          seedColor: AppColors.primarySeed,
        ),
      ),
      home: const ScannerScreen(),
    );
  }
}
