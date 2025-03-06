// import 'dart:convert';
// import 'package:app_tester/fluency.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';

// class AudioRecorderApp extends StatelessWidget {
//   const AudioRecorderApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         primaryColor: Colors.deepPurple[900],
//         scaffoldBackgroundColor: Colors.deepPurple[900],
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.deepPurple[900],
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.black,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ),
//       home: const AudioRecorderScreen(),
//     );
//   }
// }

// class AudioRecorderScreen extends StatefulWidget {
//   const AudioRecorderScreen({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _AudioRecorderScreenState createState() => _AudioRecorderScreenState();
// }

// class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
//   FlutterSoundRecorder? _recorder;
//   final _textController = TextEditingController();
//   FlutterSoundPlayer? _player;
//   bool _isRecording = false;
//   bool _isPaused = false;
//   Map<String, dynamic> _aiOutput = {
//     "repCount": 0,
//     "blockCount": 0,
//     "proCount": 0
//   };
//   bool _isLoading = false;
//   // final String _filePath = '/storage/emulated/0/Download/audio_record.wav';
//   String? _filePath;
//   int repcount = 0;
//   int blockcount = 0;
//   int procount = 0;
//   @override
//   void initState() {
//     super.initState();
//     _recorder = FlutterSoundRecorder();
//     _player = FlutterSoundPlayer();
//     _init();
//   }

//   Future<void> _init() async {
//     // await Permission.microphone.request();
//     // await Permission.storage.request();
//     // await _recorder!.openRecorder();
//     // await _player!.openPlayer();

//     await Permission.microphone.request();
//     await Permission.storage.request();

//     await _recorder!.openRecorder();
//     await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));

//     final tempDir = await getTemporaryDirectory();
//     _filePath = '${tempDir.path}/audio_record.wav';

//     _recorder!.onProgress!.listen((event) {
//       debugPrint("Recording Progress: ${event.duration}");
//     });

//     await _player!.openPlayer();
//   }

// void _toggleRecording() async {
//   if (!_isRecording) {
//     await _recorder!.startRecorder(
//       toFile: _filePath,
//       codec: Codec.pcm16WAV,
//       sampleRate: 16000,
//       numChannels: 1,
//     );
//     setState(() {
//       _isRecording = true;
//       _isPaused = false;
//     });
//   } else if (_isPaused) {
//     await _recorder!.resumeRecorder();
//     setState(() {
//       _isPaused = false;
//     });
//   } else {
//     await _recorder!.pauseRecorder();
//     setState(() {
//       _isPaused = true;
//     });
//   }
// }

//   void _stopRecording() async {
//     if (_isRecording) {
//       await _recorder!.stopRecorder();
//       setState(() {
//         _isRecording = false;
//         _isPaused = false;
//       });
//     }
//   }

//   void _saveRecording() async {
//     if (_filePath == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('No recording found. Please record first.')),
//       );
//       return;
//     }

//     String? outputPath = await FilePicker.platform.getDirectoryPath();
//     if (outputPath != null) {
//       try {
//         File recordedFile = File(_filePath!);

//         if (!await recordedFile.exists()) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('No recorded file found!')),
//           );
//           return;
//         }

//         String newPath = '$outputPath/audio_record.wav';
//         await recordedFile.copy(newPath);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Audio saved to: $newPath')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving file: $e')),
//         );
//       }
//     }
//   }

// void _playRecording() async {
//   // _stopRecording();
//   if (!_player!.isPlaying) {
//     await _player!.startPlayer(fromURI: _filePath);
//   } else {
//     await _player!.stopPlayer();
//   }
//   setState(() {});
// }

//   @override
//   void dispose() {
//     _recorder!.closeRecorder();
//     _player!.closePlayer();
//     super.dispose();
//   }

//   Future<void> _sendToAPI() async {
//     _stopRecording();
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       final url = Uri.parse('https://gameapi.svar.in/process_syllable_acc');
//       final request = http.MultipartRequest('POST', url);
//       final audioFile = File(_filePath!);
//       final audioUpload = http.MultipartFile(
//         'wav_file',
//         http.ByteStream(audioFile.openRead()),
//         await audioFile.length(),
//         filename: 'recording.wav',
//       );
//       request.files.add(audioUpload);
//       request.fields['text'] = _textController.text;

//       final response = await request.send();
//       final responseString = await response.stream.bytesToString();
//       if (response.statusCode == 200) {
//         Map<String, dynamic> data = json.decode(responseString)["result"];
//         setState(() {
//           _aiOutput["syllableCount"] = List<int>.from(data['syllableCount']);
//           _aiOutput["score"] = data['score'];
//           _aiOutput["corpus"] = List<String>.from(data['corpus']);
//           _aiOutput["isCorrect"] = data['isCorrect'];
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Processing successful!')),
//         );
//       } else {
//         throw Exception('Failed to process audio');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _navigateToAIOutput() {
//     if (_aiOutput != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => AIOutputVisualization(
//             syllableCount: _aiOutput["syllableCount"],
//             isCorrect: _aiOutput["isCorrect"],
//             score: _aiOutput["score"],
//             corpus: _aiOutput["corpus"],
//             repCount: _aiOutput["repCount"],
//             proCount: _aiOutput["proCount"],
//             blockCount: _aiOutput["blockCount"],
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content:
//                 Text("No AI output available. Please process audio first.")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Fluency AI')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment:
//               MainAxisAlignment.spaceBetween, // Pushes last box to bottom
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Text Input Field
//                 TextField(
//                   controller: _textController,
//                   decoration: const InputDecoration(
//                     labelText: 'Text Input',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Recording and API Buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: _toggleRecording,
//                         child: Text(_isRecording
//                             ? (_isPaused ? 'Resume' : 'Pause')
//                             : 'Record'),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _isLoading
//                           ? const Center(
//                               child:
//                                   CircularProgressIndicator()) // Progress bar
//                           : ElevatedButton(
//                               onPressed: _sendToAPI,
//                               child: const Text('Send to API'),
//                             ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),

//             // Pushes this to bottom
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.white),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _handleRepetition,
//                           child: const Text('Repeat'),
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _handleProlong,
//                           child: const Text('Prolong'),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _handleBlock,
//                           child: const Text('Block'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _saveRecording,
//                           child: const Text('Save Audio'),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _playRecording,
//                           child: const Text('Listen Audio'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _navigateToAIOutput,
//                       child: const Text('Result'),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleRepetition() {
//     setState(() {
//       repcount += 1;
//       _aiOutput["repCount"] = repcount;
//     });
//   }

//   void _handleBlock() {
//     setState(() {
//       blockcount += 1;
//       _aiOutput["blockCount"] = blockcount;
//     });
//   }

//   void _handleProlong() {
//     setState(() {
//       procount += 1;
//       _aiOutput["proCount"] = procount;
//     });
//   }
// }

// ---------------------------------------------------------- line seperator ----------------------------------------------------
import 'dart:convert';
import 'package:app_tester/fluency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
        primaryColor: Colors.deepPurple[900],
        scaffoldBackgroundColor: Colors.deepPurple[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple[900],
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
  final Map<String, dynamic> _aiOutput = {
    "repCount": 0,
    "blockCount": 0,
    "proCount": 0
  };
  bool _isLoading = false;
  // final String _filePath = '/storage/emulated/0/Download/audio_record.wav';
  String? _filePath;
  int repcount = 0;
  int blockcount = 0;
  int procount = 0;
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

    final tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio_record.wav';

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
    if (_isRecording || _isPaused) {
      try {
        await _recorder!.stopRecorder();
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping the recording: $e')),
        );
      }
    }
  }

  void _saveRecording() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No recording found. Please record first.')),
      );
      return;
    }

    String? outputPath = await FilePicker.platform.getDirectoryPath();
    if (outputPath != null) {
      try {
        File recordedFile = File(_filePath!);

        if (!await recordedFile.exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No recorded file found!')),
          );
          return;
        }

        String newPath = '$outputPath/audio_record.wav';
        await recordedFile.copy(newPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio saved to: $newPath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  void _clearRecording() async {
    try {
      if (_recorder != null && _recorder!.isRecording) {
        await _recorder!.stopRecorder();
      }
      if (_filePath != null) {
        final file = File(_filePath!);
        if (await file.exists()) {
          await file.writeAsBytes([]);
        }
      }

      setState(() {
        _isRecording = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio Cleared')),
        );
      });

      await _recorder!.openRecorder();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  void _playRecording() async {
    if (_player == null || _filePath == null || _filePath!.isEmpty) {
      print('Player or file path is not ready.');
      return;
    }

    try {
      if (_player!.isPlaying) {
        await _player!.stopPlayer();
      } else {
        await _player!.startPlayer(fromURI: _filePath);
      }
      setState(() {});
    } catch (e) {
      print('Error while playing/ stopping audio: $e');
    }
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    _player!.closePlayer();
    super.dispose();
  }

  Future<void> _sendToAPI() async {
    _stopRecording();
    setState(() {
      _isLoading = true;
    });
    try {
      final url = Uri.parse('https://gameapi.svar.in/process_syllable_acc');
      final request = http.MultipartRequest('POST', url);
      final audioFile = File(_filePath!);
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
          _aiOutput["syllableCount"] = List<int>.from(data['syllableCount']);
          _aiOutput["score"] = data['score'];
          _aiOutput["corpus"] = List<String>.from(data['corpus']);
          _aiOutput["isCorrect"] = data['isCorrect'];
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
            syllableCount: _aiOutput["syllableCount"],
            isCorrect: _aiOutput["isCorrect"],
            score: _aiOutput["score"],
            corpus: _aiOutput["corpus"],
            repCount: _aiOutput["repCount"],
            proCount: _aiOutput["proCount"],
            blockCount: _aiOutput["blockCount"],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("No AI output available. Please process audio first.")),
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
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Pushes last box to bottom
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
                        child: Text(_isRecording
                            ? (_isPaused ? 'Resume' : 'Pause')
                            : 'Record'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child:
                                  CircularProgressIndicator()) // Progress bar
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
                          onPressed: _handleRepetition,
                          child: const Text('Repeat'),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleProlong,
                          child: const Text('Prolong'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleBlock,
                          child: const Text('Block'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _clearRecording,
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
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

  void _handleRepetition() {
    setState(() {
      repcount += 1;
      _aiOutput["repCount"] = repcount;
    });
  }

  void _handleBlock() {
    setState(() {
      blockcount += 1;
      _aiOutput["blockCount"] = blockcount;
    });
  }

  void _handleProlong() {
    setState(() {
      procount += 1;
      _aiOutput["proCount"] = procount;
    });
  }
}
