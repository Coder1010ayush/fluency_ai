import 'package:app_tester/donate_audio.dart';
import 'package:app_tester/screen_recorder.dart';
import 'package:app_tester/sent_improved.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluency AI',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      home: const HomeScreen(),
    );
  }
}

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.deepPurple[900],
  primaryColor: Colors.deepPurple[900],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.deepPurple[900],
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[850],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white),
    ),
    labelStyle: const TextStyle(color: Colors.white70),
  ),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Testing App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RecordingWidget()),
                  );
                },
                child: const Text('Word AI'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150, // Same width as above
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AudioRecorderApp()),
                  );
                },
                child: const Text('Fluency AI'),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AudioUploaderApp()));
                  },
                  child: const Text("Donate Voice")),
            ),
          ],
        ),
      ),
    );
  }
}
