import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({Key? key}) : super(key: key);

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playAlarm();
  }

  Future<void> _playAlarm() async {
    setState(() => _isPlaying = true);
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('alarm.mp3'));
  }

  Future<void> _stopAlarm() async {
    await _audioPlayer.stop();
    setState(() => _isPlaying = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm, color: Colors.red, size: 100),
            const SizedBox(height: 32),
            const Text(
              'Alarm! Time to take your medication.',
              style: TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isPlaying ? _stopAlarm : null,
              child: const Text('Stop Alarm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
