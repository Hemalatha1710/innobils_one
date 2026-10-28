import 'package:flutter/material.dart';
import 'package:innobils_one/screen/home_screen.dart';
import 'package:innobils_one/screen/login_page.dart';
import 'package:innobils_one/service/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final user = await AuthService().currentUser();
  runApp(MyApp(loggedIn: user != null));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;
  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: loggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
