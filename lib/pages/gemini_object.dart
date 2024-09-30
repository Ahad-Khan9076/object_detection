import 'dart:convert'; // For decoding JSON
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_tts/flutter_tts.dart'; // For text to speech
import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';

class GeminiObjectDetection extends StatefulWidget {
  const GeminiObjectDetection({super.key});

  @override
  State<GeminiObjectDetection> createState() => _GeminiObjectDetectionState();
}

class _GeminiObjectDetectionState extends State<GeminiObjectDetection> {
  final Gemini gemini = Gemini.instance;
  final FlutterTts flutterTts = FlutterTts(); // Initialize FlutterTts
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _resultText = "No objects detected yet";
  final GoogleTranslator _translator = GoogleTranslator();
  String _selectedLanguage = 'en'; // Default language is English
  bool _isLoading = false; // For loading indicator
  bool _isTranslating = false; // To show translation progress
  List<String> _detectedLabels = []; // Store detected labels
  List<String> _originalLabels = []; // Store original English labels

  // Available languages
  final Map<String, String> _languages = {
    'en': 'English',
    'ur': 'Urdu',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'hi': 'Hindi',
  };

  // Convert the image to Uint8List
  Future<Uint8List> _convertImageToUint8List(String imagePath) async {
    try {
      // Read the image as bytes
      return await File(imagePath).readAsBytes();
    } catch (e) {
      print("Error converting image: $e");
      return Uint8List(0);
    }
  }

  Future<void> _sendMessage(String imagePath) async {
    setState(() {
      _isLoading = true;
      _detectedLabels = [];
      _originalLabels = []; // Clear original labels on new detection
      _resultText = "Detecting objects...";
    });

    // Convert image to Uint8List
    Uint8List imageBytes = await _convertImageToUint8List(imagePath);

    try {
      final response = await gemini.textAndImage(
        text:
        "Here is the image. You will tell me the number of objects in this image and objects name. Name should be specific. Just give response in json format. For example: {'objects_found': 2, 'objects_name': ['cat', 'dog']}", // Updated prompt
        images: [imageBytes], // Pass the Uint8List inside a list
      );

      // Replace single quotes with double quotes to make the response valid JSON
      String? jsonString = response!.content!.parts![0].text;
      jsonString = jsonString!
          .replaceAll("'", '"'); // Replace single quotes with double quotes

      // Decode the JSON response
      Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
      print("Response: $jsonResponse");

      int objectsFound = jsonResponse['objects_found'];
      List<String> objectNames =
      List<String>.from(jsonResponse['objects_name']);

      setState(() {
        _isLoading = false;
        _resultText = 'Detected $objectsFound object(s):';
        _detectedLabels = objectNames; // Update detected labels
        _originalLabels =
            List.from(objectNames); // Save original labels in English
      });
    } catch (error) {
      print("Error detecting objects: $error");
      setState(() {
        _isLoading = false;
        _resultText = "Error detecting objects: $error";
      });
    }
  }

  Future<void> _getImageAndDetectObjects() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _sendMessage(pickedFile.path);
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

  Future<void> _captureImageAndDetectObjects() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _sendMessage(pickedFile.path);
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

  Future<void> _translateResult() async {
    if (_originalLabels.isNotEmpty) {
      setState(() {
        _isTranslating = true;
      });
      try {
        for (int i = 0; i < _originalLabels.length; i++) {
          var translation = await _translator.translate(_originalLabels[i],
              to: _selectedLanguage); // Always translate from the original labels (English)
          _detectedLabels[i] = translation.text;
        }
        setState(() {
          _resultText = "Translated to ${_languages[_selectedLanguage]}";
        });
      } catch (e) {
        setState(() {
          _resultText = "Translation error: $e";
        });
      } finally {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  // Speak method for text-to-speech
  Future<void> _speak(String text) async {
    print("Speaking: $text");
    flutterTts.setLanguage(_selectedLanguage);
    flutterTts.progressHandler =
        (String text, int start, int end, String word) {
      print('$start, $end, $word');
    };
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: const Text('Object Detection',style: TextStyle(color: Colors.white),),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _imageFile != null
                    ? Image.file(_imageFile!, height: 200)
                    : const Text('No image selected'),
                const SizedBox(height: 20),
                _isLoading
                    ? const Stack(
                  alignment: Alignment.center, // Aligns all children to the center
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60, // Control the size of the indicator
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 6.0, // Adjust the stroke width if needed
                      ),
                    ),
                    Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 30, // Adjust the icon size to fit inside the indicator
                    ),
                  ],
                )
                    : Column(
                  children: [
                    Text(_resultText,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 20),
                    _detectedLabels.isNotEmpty
                        ? Column(
                      children: _detectedLabels
                          .map(
                            (label) => Card(
                          color: Colors.grey.shade300,
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 20),
                          child: ListTile(
                            title: Text(
                              label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.volume_up),
                              onPressed: () {
                                _speak(
                                    label); // Speak the label
                              },
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    )
                        : const SizedBox.shrink(),
                  ],
                ),
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _getImageAndDetectObjects,
                      icon: const Icon(Icons.image,color: Colors.black,),
                      label: const Text("Select Image",style: TextStyle(color: Colors.black),),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),

                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _captureImageAndDetectObjects,
                      icon: const Icon(Icons.camera_alt,color: Colors.black,),
                      label: const Text("Capture Image",style: TextStyle(color: Colors.black),),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Language Dropdown and Translate Button
                DropdownButton<String>(
                  value: _selectedLanguage,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLanguage = newValue!;
                    });
                  },
                  items: _languages.keys
                      .map<DropdownMenuItem<String>>((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(_languages[key]!),
                    );
                  }).toList(),
                  icon: const Icon(Icons.language, color: Colors.blue),
                  elevation: 16,
                  underline: Container(
                    height: 2,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}