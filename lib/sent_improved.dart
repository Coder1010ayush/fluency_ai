import 'dart:convert';
import 'package:app_tester/fluency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
class AudioRecorderApp extends StatelessWidget {
  const AudioRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AudioRecorderScreen(),
    );
  }
}

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AudioRecorderScreenState createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  FlutterSoundRecorder? _recorder;
  final _textController = TextEditingController();
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPaused = false;
  Map<String, dynamic>? _aiOutput;
  bool _isLoading = false;
  final String _filePath = '/storage/emulated/0/Download/audio_record.wav';


  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _init();
  }

  Future<void> _init() async {
    // await Permission.microphone.request();
    // await Permission.storage.request();
    // await _recorder!.openRecorder();
    // await _player!.openPlayer();

      await Permission.microphone.request();
      await Permission.storage.request();

      await _recorder!.openRecorder();
      await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));

      _recorder!.onProgress!.listen((event) {
        debugPrint("Recording Progress: ${event.duration}");
      });

  await _player!.openPlayer();

  }

  void _toggleRecording() async {
    if (!_isRecording) {
      await _recorder!.startRecorder(
        toFile: _filePath,
        codec: Codec.pcm16WAV, 
        sampleRate: 16000, 
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
        _isPaused = false;
      });
    } else if (_isPaused) {
      await _recorder!.resumeRecorder();
      setState(() {
        _isPaused = false;
      });
    } else {
      await _recorder!.pauseRecorder();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _stopRecording() async {
    if (_isRecording) {
      await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    }
  }

  void _saveRecording() async {
    String? outputPath = await FilePicker.platform.getDirectoryPath();
    if (outputPath != null) {
      File recordedFile = File(_filePath);
      String newPath = '$outputPath/audio_record.wav';
      await recordedFile.copy(newPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio saved to: $newPath')),
      );
    }
  }

  void _playRecording() async {
    _stopRecording();
    if (!_player!.isPlaying) {
      await _player!.startPlayer(fromURI: _filePath);
    } else {
      await _player!.stopPlayer();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    _player!.closePlayer();
    super.dispose();
  }



  Future<void> _sendToAPI() async {
    _stopRecording();
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('https://gameapi.svar.in/process_syllable_acc');
      final request = http.MultipartRequest('POST', url);
      final audioFile = File(_filePath);
      final audioUpload = http.MultipartFile(
        'wav_file',
        http.ByteStream(audioFile.openRead()),
        await audioFile.length(),
        filename: 'recording.wav',
      );
      request.files.add(audioUpload);
      request.fields['text'] = _textController.text;
      
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(responseString)["result"];
        setState(() {
          _aiOutput = {
            'syllableCount': List<int>.from(data['syllableCount']),
            'isCorrect': data['isCorrect'],
            'score': data['score'],
           'corpus': List<String>.from(data['corpus']),
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing successful!')),
        );
      } else {
        throw Exception('Failed to process audio');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToAIOutput() {
    if (_aiOutput != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIOutputVisualization(
            syllableCount: _aiOutput!["syllableCount"],
            isCorrect: _aiOutput!["isCorrect"],
            score: _aiOutput!["score"],
            corpus: _aiOutput!["corpus"],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No AI output available. Please process audio first.")),
      );
    }
  }



@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Fluency AI')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes last box to bottom
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Text Input Field
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Text Input',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Recording and API Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _toggleRecording,
                      child: Text(_isRecording ? (_isPaused ? 'Resume' : 'Pause') : 'Record'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator()) // Progress bar
                        : ElevatedButton(
                            onPressed: _sendToAPI,
                            child: const Text('Send to API'),
                          ),
                  ),
                ],
              ),
            ],
          ),

          // Pushes this to bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveRecording,
                        child: const Text('Save Audio'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _playRecording,
                        child: const Text('Listen Audio'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, // Full width button
                  child: ElevatedButton(
                    onPressed: _navigateToAIOutput,
                    child: const Text('Result'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}



}