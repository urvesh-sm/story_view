import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

class VideoLoader {
  String url;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  VideoLoader(this.url, {this.requestHeaders});

  Map<String, String>? get httpHeaders =>
      requestHeaders?.map((key, value) => MapEntry(key, value.toString()));

  /// An HLS URL (`.m3u8`) needs an explicit format hint on Android; any other
  /// URL is played as a progressive file. Both are streamed, never downloaded.
  bool get isHls =>
      Uri.tryParse(url)?.path.toLowerCase().endsWith('.m3u8') ?? false;
}

class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final VideoLoader videoLoader;
  final Color? backgroundColor;

  StoryVideo(this.videoLoader,
      {this.storyController, Key? key, this.backgroundColor})
      : super(key: key ?? UniqueKey());

  static StoryVideo url(String url,
      {StoryController? controller,
      Color? backgroundColor,
      Map<String, dynamic>? requestHeaders,
      Key? key}) {
    return StoryVideo(VideoLoader(url, requestHeaders: requestHeaders),
        storyController: controller,
        key: key,
        backgroundColor: backgroundColor);
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;
  bool _isMuted = false;

  StreamSubscription? _streamSubscription;
  StreamSubscription? _muteSubscription;

  VideoPlayerController? playerController;

  @override
  void initState() {
    super.initState();

    // Hold the story's progress timer until the first frame is ready, so a
    // slow buffer does not consume the story's duration.
    widget.storyController!.pause();

    _load();
  }

  Future<void> _load() async {
    final isHls = widget.videoLoader.isHls;
    final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoLoader.url),
        formatHint: isHls ? VideoFormat.hls : null,
        httpHeaders: widget.videoLoader.httpHeaders ?? const {});
    playerController = controller;

    _listenToStoryController();

    try {
      // Resolves once the first frame is buffered, not when the download ends.
      await controller.initialize();
    } catch (_) {
      widget.videoLoader.state = LoadState.failure;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    if (!mounted) return;

    widget.videoLoader.state = LoadState.success;
    setState(() {});
    widget.storyController?.play();
  }

  void _listenToStoryController() {
    final storyController = widget.storyController;
    if (storyController == null) return;

    _streamSubscription = storyController.playbackNotifier.listen((state) {
      if (state == PlaybackState.pause) {
        playerController?.pause();
      } else {
        playerController?.play();
      }
    });
    _muteSubscription = storyController.muteNotifier.listen((muteState) {
      if (mounted) {
        setState(() {
          _isMuted = muteState == MuteState.muted;
          playerController?.setVolume(_isMuted ? 0.0 : 1.0);
        });
      }
    });
  }

  Widget getContentView() {
    if (widget.videoLoader.state == LoadState.success &&
        (playerController?.value.isInitialized ?? false)) {
      return Center(
        child: AspectRatio(
          aspectRatio: playerController!.value.aspectRatio,
          child: VideoPlayer(playerController!),
        ),
      );
    }

    return widget.videoLoader.state == LoadState.loading
        ? Center(
            child: Container(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          )
        : Center(
            child: Text(
            "Media failed to load.",
            style: TextStyle(
              color: Colors.white,
            ),
          ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor ?? Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: getContentView(),
    );
  }

  @override
  void dispose() {
    playerController?.dispose();
    _streamSubscription?.cancel();
    _muteSubscription?.cancel();
    super.dispose();
  }
}
