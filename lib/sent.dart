import 'package:app_tester/fluency.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class RecordingWidgetSent extends StatefulWidget {
  const RecordingWidgetSent({super.key});

  @override
  State<RecordingWidgetSent> createState() => _RecordingWidgetSentState();
}

class _RecordingWidgetSentState extends State<RecordingWidgetSent> {
  final _textController = TextEditingController();
  late final AudioRecorder _audioRecorder;
  String? _recordingPath;
  bool _isRecording = false;
  Map<String, dynamic>? _aiOutput;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        _recordingPath = '${directory.path}/recording.wav';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 44100,
            numChannels: 1,
          ),
          path: _recordingPath!,
        );
        
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _sendToAPI() async {
    if (_recordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record audio first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('https://gameapi.svar.in/process_syllable_acc');
      final request = http.MultipartRequest('POST', url);

      final audioFile = File(_recordingPath!);
      final audioStream = http.ByteStream(audioFile.openRead());
      final audioLength = await audioFile.length();
      final audioUpload = http.MultipartFile(
        'wav_file',
        audioStream,
        audioLength,
        filename: 'recording.wav',
      );
      request.files.add(audioUpload);
      request.fields['text'] = _textController.text;

      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      debugPrint(responseString);
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
      } else {
        throw Exception('Failed to send data to API');
      }

      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recording App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter your text',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
              ),
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendToAPI,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send to API'),
            ),
            const SizedBox(height: 15),
            if (_aiOutput != null) 
              AIOutputVisualization(
                syllableCount: _aiOutput!['syllableCount'],
                isCorrect: _aiOutput!['isCorrect'],
                score: _aiOutput!['score'],
                corpus: _aiOutput!['corpus'],
              ),
          ],
        ),
      ),
    );
  }
}
