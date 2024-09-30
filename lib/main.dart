import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:object_detection_translator/pages/gemini_object.dart';
import 'package:object_detection_translator/pages/ml_kit.dart';

void main() {
  Gemini.init(
    apiKey: "AIzaSyACVefPsjggZ_q7UkdoITFa6f8mqyEpNHQ",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Object Detection and Translation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GeminiObjectDetection(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection and Translation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ObjectDetectionExample()),
                  );
                },
                child: const Text("Using ML Kit")),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GeminiObjectDetection()),
                  );
                },
                child: const Text("Using Gemini")),
          ],
        ),
      ),
    );
  }
}
