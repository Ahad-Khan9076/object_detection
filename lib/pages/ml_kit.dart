import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';

class ObjectDetectionExample extends StatefulWidget {
  const ObjectDetectionExample({super.key});

  @override
  _ObjectDetectionExampleState createState() => _ObjectDetectionExampleState();
}

class _ObjectDetectionExampleState extends State<ObjectDetectionExample> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _resultText = "No objects detected yet";
  final GoogleTranslator _translator = GoogleTranslator();
  String _selectedLanguage = 'en'; // Default language is English
  final ObjectDetector _objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  List<DetectedObject> _detectedObjects =
      []; // Store detected objects with bounding boxes
  bool _isTranslating = false;
  List<String> _detectedLabels = []; // Store detected labels

  // Available languages
  final Map<String, String> _languages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'hi': 'Hindi',
    'ur': 'Urdu',
  };

  // Function to get image and detect objects
  Future<void> _getImageAndDetectObjects() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _resultText = "Processing image...";
        });
        await _detectObjects(File(pickedFile.path));
      } else {
        setState(() {
          _resultText = "No image selected";
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "Error picking image: $e";
      });
    }
  }

  // Function to detect objects
  Future<void> _detectObjects(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<DetectedObject> objects =
          await _objectDetector.processImage(inputImage);

      List<String> detectedLabels = [];
      for (DetectedObject object in objects) {
        for (Label label in object.labels) {
          detectedLabels.add(label.text); // Store the detected object labels
        }
      }

      if (detectedLabels.isNotEmpty) {
        setState(() {
          _detectedObjects =
              objects; // Store the detected objects (with bounding boxes)
          _detectedLabels = detectedLabels;
        });
        await _translateLabels(); // Translate the detected labels based on the current language
      } else {
        setState(() {
          _resultText = "No objects detected";
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "Error detecting objects: $e";
      });
    }
  }

  // Function to translate detected labels
  Future<void> _translateLabels() async {
    if (_detectedLabels.isEmpty) {
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      List<String> translatedLabels = [];
      for (String label in _detectedLabels) {
        final translation =
            await _translator.translate(label, to: _selectedLanguage);
        translatedLabels.add(translation.text);
      }

      setState(() {
        _resultText = translatedLabels.isNotEmpty
            ? translatedLabels.join('\n')
            : "No objects detected";
      });
    } catch (e) {
      setState(() {
        _resultText = "Error translating labels: $e";
      });
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  @override
  void dispose() {
    _objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection & Translation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _getImageAndDetectObjects,
              child: const Text('Capture Image'),
            ),
            const SizedBox(height: 20),
            _imageFile != null
                ? Stack(
                    children: [
                      Image.file(
                        _imageFile!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      if (_detectedObjects.isNotEmpty)
                        CustomPaint(
                          size: const Size(double.infinity, 300),
                          painter: ObjectPainter(_detectedObjects),
                        ),
                    ],
                  )
                : const Placeholder(
                    fallbackHeight: 300,
                    fallbackWidth: double.infinity,
                  ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) async {
                setState(() {
                  _selectedLanguage = newValue!;
                });
                await _translateLabels(); // Trigger translation when the language is changed
              },
              items: _languages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _isTranslating
                ? const CircularProgressIndicator()
                : Text(
                    _resultText,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
            const SizedBox(height: 20),
            // Show detected object numbers and their translated names below
            // if (_detectedObjects.isNotEmpty)
            //   Column(
            //     children: List.generate(_detectedObjects.length, (index) {
            //       // Check for bounds to avoid RangeError
            //       if (index < _detectedLabels.length) {
            //         return Text(
            //           "Object ${index + 1}: ${_detectedLabels[index]}",
            //           style: const TextStyle(
            //               fontSize: 16, fontWeight: FontWeight.bold),
            //         );
            //       }
            //       return Container(); // Return an empty container if out of bounds
            //     }),
            //   ),
          ],
        ),
      ),
    );
  }
}

class ObjectPainter extends CustomPainter {
  final List<DetectedObject> detectedObjects;

  ObjectPainter(this.detectedObjects);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < detectedObjects.length; i++) {
      final object = detectedObjects[i];
      final rect = object.boundingBox;

      // Draw the rectangle
      canvas.drawRect(
        Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right,
          rect.bottom,
        ),
        paint,
      );

      // Draw the object number label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Object ${i + 1}',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(
        canvas,
        Offset(
            rect.left, rect.top - 10), // Position the label above the rectangle
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
