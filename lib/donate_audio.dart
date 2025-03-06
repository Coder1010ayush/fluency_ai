import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_tester/data/data.dart';

class AudioUploaderApp extends StatelessWidget {
  const AudioUploaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.deepPurple[900],
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AudioUploaderScreen(),
    );
  }
}

class AudioUploaderScreen extends StatefulWidget {
  const AudioUploaderScreen({super.key});

  @override
  _AudioUploaderScreenState createState() => _AudioUploaderScreenState();
}

class _AudioUploaderScreenState extends State<AudioUploaderScreen> {
  File? _audioFile;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _indexController = TextEditingController();
  final TextEditingController _phonemeController = TextEditingController();
  bool _isUploading = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String _uploadStatus = "";
  String _selectedType = "rep";
  int counter = 2;
  late String random_text = data[counter];
  bool _isAvail = true;
  Map<int, String> indexCharMap = {};
  int? selectedIndex;
  String inputString = "";

  Future<void> _loadCounterFromFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/info.json');

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString);
        setState(() {
          counter = jsonData['count'] ?? 2; // Default to 2 if not found
          random_text = data[counter];
        });
      } catch (e) {
        print("Error reading info.json: $e");
      }
    }
  }

  Future<void> _updateCounterInFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/info.json');

    final data = {'count': counter};
    await file.writeAsString(jsonEncode(data));
  }

  void _buildIndexCharacterMap(String newString) {
    setState(() {
      inputString = newString;
      indexCharMap = {
        for (int i = 0; i < newString.length; i++) i: newString[i]
      };
      indexCharMap[-1] = "";
      selectedIndex = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadCounterFromFile(); // Load counter when the app starts
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future<void> _startRecording() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      final dir = await getApplicationDocumentsDirectory();
      String path = '${dir.path}/recorded_audio.wav';

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _audioFile = File(path);
      });
    } else {
      setState(() {
        _uploadStatus = "Microphone permission denied.";
      });
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _playAudio() async {
    if (_audioFile != null && _audioFile!.existsSync()) {
      await _player.startPlayer(
        fromURI: _audioFile!.path,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _stopAudio() async {
    await _player.stopPlayer();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _uploadAudio() async {
    if (_audioFile == null) {
      setState(() {
        _uploadStatus = "Please select or record an audio file.";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = "Uploading...";
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://gameapi.svar.in/send_audio'),
    );

    request.files.add(await http.MultipartFile.fromPath(
      'wav_file',
      _audioFile!.path,
      filename: basename(_audioFile!.path),
    ));
    if (_textController.text.isEmpty) {
      request.fields['text'] = random_text;
    } else {
      request.fields['text'] = _textController.text;
    }
    if (_indexController.text.isEmpty) {
      request.fields['index'] = "-1";
    } else {
      request.fields['index'] = _indexController.text;
    }
    request.fields['type'] = _selectedType;
    request.fields['phoneme'] = _phonemeController.text;

    try {
      var response = await request.send();

      setState(() {
        _isUploading = false;
        _uploadStatus = response.statusCode == 200
            ? "Upload Successful ✅"
            : "Upload Failed ❌: ${response.reasonPhrase}";

        if (data.length - 1 > counter && _textController.text.isEmpty) {
          counter += 1;
          random_text = data[counter];
          _updateCounterInFile(); // Update the counter in the file
        } else {
          if (data.length - 1 < counter && _textController.text.isNotEmpty) {
            _isAvail = false;
          } else {
            _isAvail = true;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = "Error: $e";
      });
    }
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      items: ['rep', 'pro', 'norm']
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedType = value!;
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Upload Audio 🎤",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _isAvail
                ? Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 14, 14, 13),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(66, 121, 119, 119),
                          blurRadius: 6.0,
                          spreadRadius: 2.0,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      random_text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 14, 14, 13),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(66, 121, 119, 119),
                          blurRadius: 6.0,
                          spreadRadius: 2.0,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Enter Your Own Text",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? "Stop Recording" : "Start Recording"),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isRecording ? Colors.red[800] : Colors.green[800],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isPlaying ? _stopAudio : _playAudio,
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(_isPlaying ? "Stop Playback" : "Play Audio"),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            ),
            const SizedBox(height: 20),
            _buildTextField("Enter Index", _indexController, isNumeric: true),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Enter Label',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _buildIndexCharacterMap,
                  ),
                  const SizedBox(height: 20),
                  indexCharMap.isNotEmpty
                      ? DropdownButton<int>(
                          value: selectedIndex,
                          hint: const Text('Select a character'),
                          items: indexCharMap.entries.map((entry) {
                            return DropdownMenuItem<int>(
                              value: entry.key,
                              child: Text('Index ${entry.key}: ${entry.value}'),
                            );
                          }).toList(),
                          onChanged: (int? newIndex) {
                            setState(() {
                              selectedIndex = newIndex;
                              _indexController.text = selectedIndex.toString();
                              _phonemeController.text =
                                  indexCharMap[selectedIndex]!;
                              _textController.text = inputString;
                            });
                          },
                        )
                      : const Text("Enter text to see options"),
                ],
              ),
            ),
            _buildDropdown(),
            const SizedBox(height: 10),
            _buildTextField("Enter Phoneme", _phonemeController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadAudio,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Upload Audio"),
            ),
            const SizedBox(height: 20),
            Center(
                child: Text(_uploadStatus,
                    style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
