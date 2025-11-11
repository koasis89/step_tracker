
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/screens/main_screen.dart';

class AppModeProvider with ChangeNotifier {
  bool _isSimulationMode = true;

  bool get isSimulationMode => _isSimulationMode;

  void toggleMode() {
    _isSimulationMode = !_isSimulationMode;
    notifyListeners();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppModeProvider(),
      child: const PedometerApp(),
    ),
  );
}

class PedometerApp extends StatelessWidget {
  const PedometerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pedometer App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        // Switch의 스타일을 앱 테마에 중앙 관리하도록 추가합니다.
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.orangeAccent; // 켜졌을 때 (Sim)
            }
            return Colors.tealAccent; // 꺼졌을 때 (Live)
          }),
          trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.orange.withOpacity(0.5); // 켜졌을 때 (Sim)
            }
            return Colors.teal.withOpacity(0.5); // 꺼졌을 때 (Live)
          }),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
