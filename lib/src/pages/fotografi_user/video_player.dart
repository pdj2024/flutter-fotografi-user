import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/navigation_provider.dart';


class VideoPlayerPage extends StatefulWidget {
  

  const VideoPlayerPage({Key? key}) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final String videoUrl = context.read<NavigationProvider>().ambilGambar('abb1a869-38ad-4e68-a804-7b0e50bc0afb-2025-03-24 17-03-16.mp4');

    _controller = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play(); // autoplay
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Player")),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
