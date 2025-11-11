
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/screens/main_screen.dart';
import 'firebase_options.dart'; // flutterfire configure가 생성한 파일

class AppModeProvider with ChangeNotifier {
  bool _isSimulationMode = true;

  bool get isSimulationMode => _isSimulationMode;

  void toggleMode() {
    _isSimulationMode = !_isSimulationMode;
    notifyListeners();
  }
}

// 1. 테마 상태를 관리하는 ThemeProvider 클래스 추가
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // 기본값을 다크 모드로 설정

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners(); // 상태 변경을 알림
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 2. MultiProvider를 사용하여 여러 Provider를 앱에 제공
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppModeProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()), // ThemeProvider 추가
      ],
      child: const PedometerApp(),
    ),
  );
}

class PedometerApp extends StatelessWidget {
  const PedometerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Consumer를 사용하여 ThemeProvider의 상태를 구독
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // 라이트 테마 정의
        final lightTheme = ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.blueGrey,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blueGrey[600],
            elevation: 4,
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) return Colors.orange;
              return Colors.teal;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) return Colors.orange.withOpacity(0.5);
              return Colors.teal.withOpacity(0.5);
            }),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black54),
            headlineSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        );

        // 다크 테마 정의 (기존 테마 활용)
        final darkTheme = ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueGrey,
          scaffoldBackgroundColor: const Color(0xFF1E1E1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) return Colors.orangeAccent;
              return Colors.tealAccent;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) return Colors.orange.withOpacity(0.5);
              return Colors.teal.withOpacity(0.5);
            }),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );

        // 4. MaterialApp에 테마 설정 적용
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pedometer App',
          theme: lightTheme, // 라이트 모드일 때 사용할 테마
          darkTheme: darkTheme, // 다크 모드일 때 사용할 테마
          themeMode: themeProvider.themeMode, // 현재 테마 모드를 provider에서 가져옴
          home: const MainScreen(),
        );
      },
    );
  }
}
