import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DriveVideoView extends StatefulWidget {
  final String url;
  final bool autoPlay;
  final bool showControls;

  const DriveVideoView({
    Key? key,
    required this.url,
    this.autoPlay = false,
    this.showControls = true,
  }) : super(key: key);

  @override
  State<DriveVideoView> createState() => _DriveVideoViewState();
}

class _DriveVideoViewState extends State<DriveVideoView> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  void _initializeVideoController() async {
    if (widget.url.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No video URL provided';
      });
      return;
    }

    try {
      if (widget.url.startsWith('http')) {
        // Handle Google Drive videos - need to use a direct access URL
        String videoUrl = widget.url;
        // If it's a Drive URL that isn't already in the direct format, convert it
        if (widget.url.contains('drive.google.com') &&
            !widget.url.contains('/uc?')) {
          final regex = RegExp(r'file/d/([^/]+)');
          final match = regex.firstMatch(widget.url);
          if (match != null && match.groupCount >= 1) {
            final fileId = match.group(1);
            videoUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
          }
        }

        print('Initializing video with URL: $videoUrl');
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else {
        final file = File(widget.url);
        if (!file.existsSync()) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Video file does not exist';
          });
          return;
        }

        _controller = VideoPlayerController.file(file);
      }

      await _controller!.initialize();

      if (widget.autoPlay) {
        _controller!.play();
        _isPlaying = true;
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        if (widget.showControls) _buildVideoControls(),
      ],
    );
  }

  Widget _buildVideoControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 32,
              color: Colors.blue,
            ),
            onPressed: () {
              setState(() {
                if (_isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
                _isPlaying = !_isPlaying;
              });
            },
          ),
          const SizedBox(width: 8),
          // Add a position indicator
          Expanded(
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Fullscreen button (placeholder - would need implementation)
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.blue),
            onPressed: () {
              // Implement fullscreen functionality if needed
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Video Error',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
