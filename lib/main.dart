import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'WelcomeScreen.dart';
import 'database_helper.dart';
import 'settings_provider.dart'; // Import your provider
import 'speech_service.dart'; // Import SpeechService for Vosk

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the status bar color to transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Initialize the database before running the app
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.connect();

  // Initialize Vosk Speech Recognition
  SpeechService speechService = SpeechService();
  await speechService.initVosk(); // Load Vosk model

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomeScreen(),
    );
  }
}

