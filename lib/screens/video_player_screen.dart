import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _isFullScreen = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Lock to portrait mode initially
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
        ),
      )..addListener(_listener);
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize video player: $e';
      });
    }
  }

  void _listener() {
    if (_isPlayerReady != _controller.value.isReady) {
      setState(() {
        _isPlayerReady = _controller.value.isReady;
      });
    }
    // Check if fullscreen state changed
    if (_isFullScreen != _controller.value.isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });
      // Handle orientation changes
      if (!_controller.value.isFullScreen) {
        // Return to portrait mode when exiting fullscreen
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // Reset orientation when leaving the screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _controller.toggleFullScreenMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar:
            _isFullScreen
                ? null
                : AppBar(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
        body: SafeArea(
          child: Center(
            child:
                _error != null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                            });
                            _initializePlayer();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                    : YoutubePlayer(
                      controller: _controller,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Theme.of(context).primaryColor,
                      progressColors: ProgressBarColors(
                        playedColor: Theme.of(context).primaryColor,
                        handleColor: Theme.of(context).primaryColor,
                      ),
                      onReady: () {
                        setState(() {
                          _isPlayerReady = true;
                        });
                      },
                      onEnded: (data) {
                        if (_isFullScreen) {
                          _controller.toggleFullScreenMode();
                        }
                      },
                    ),
          ),
        ),
      ),
    );
  }
}
