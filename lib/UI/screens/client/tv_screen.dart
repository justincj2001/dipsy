import 'dart:convert'; // For JSON parsing
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TVScreen extends StatefulWidget {
  const TVScreen({super.key});

  @override
  State<TVScreen> createState() => _TVScreenState();
}

class _TVScreenState extends State<TVScreen> {
  VideoPlayerController? _controller; // Nullable controller
  String? _videoUrl; // Store the current video URL
  final String _sharedPrefKey = "latestVideoUrl";

  @override
  void initState() {
    super.initState();
    _loadLastVideoUrl(); // Load and play the last video URL
  }

  Future<void> _loadLastVideoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_sharedPrefKey);

    if (savedUrl != null) {
      _initializeVideo(savedUrl);
    }
  }

  Future<void> _saveVideoUrl(String videoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sharedPrefKey, videoUrl);
  }

  void _initializeVideo(String videoUrl) {
    _videoUrl = videoUrl;

    // Dispose the old controller if it exists
    _controller?.dispose();

    // Create a new controller
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _controller?.play(); // Autoplay the video
        });
      }).catchError((e) {
        print("Error initializing video: $e");
      });
  }

  void _handleIncomingJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data.containsKey("videoUrl")) {
        final videoUrl = data["videoUrl"] as String;
        _initializeVideo(videoUrl); // Play the new video
        _saveVideoUrl(videoUrl); // Save the URL for future use
      }
    } catch (e) {
      print("Invalid JSON: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller != null && _controller!.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : const CircularProgressIndicator(), // Show a loader while initializing
      ),
    );
  }

  // This method can be called to process new JSON input dynamically
  void processIncomingJson(String jsonString) {
    _handleIncomingJson(jsonString);
  }
}
