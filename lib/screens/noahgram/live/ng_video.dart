import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../data/api_client.dart';
import '../../../data/live_noahgram.dart';
import '../../../theme/app_theme.dart';
import 'ng_widgets.dart' show NgPicture;

/// A reel's video. It starts playing when [active] and stops (and frees the player) when it is not, so only
/// the reel on screen holds a video decoder. A tap pauses or plays. The first time it plays it counts a view.
class NgVideo extends StatefulWidget {
  const NgVideo({
    super.key,
    required this.post,
    this.active = true,
    this.fit = BoxFit.cover,
    this.controls = false,
  });

  final NgPost post;
  final bool active;
  final BoxFit fit;

  /// Show a thin progress bar under the video.
  final bool controls;

  @override
  State<NgVideo> createState() => _NgVideoState();
}

class _NgVideoState extends State<NgVideo> with WidgetsBindingObserver {
  VideoPlayerController? _c;
  bool _failed = false;
  bool _loading = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) _start();
  }

  bool _covered = false;
  bool _appAway = false;

  /// The phone went to the home screen or another app: no sound from here.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appAway = state != AppLifecycleState.resumed;
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    if (_appAway) {
      c.pause();
    } else if (!_paused && !_covered && widget.active) {
      c.play();
    }
  }

  /// A page opened on top of this one (a profile, a post) turns this page's tickers off: stop the sound then,
  /// and carry on when the member comes back.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final covered = !TickerMode.valuesOf(context).enabled;
    if (covered == _covered) return;
    _covered = covered;
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    if (covered) {
      c.pause();
    } else if (!_paused && widget.active) {
      c.play();
    }
  }

  @override
  void didUpdateWidget(NgVideo old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _start();
    } else if (!widget.active && old.active) {
      _stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final src = widget.post.mediaSrc;
    if (src == null) {
      setState(() => _failed = true);
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
      _paused = false;
    });
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(src),
      httpHeaders: api.authHeaders,
    );
    _c = controller;
    try {
      await controller.initialize();
      if (!mounted || _c != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      if (!_covered && !_appAway) await controller.play();
      liveNoahgram.markViewed(widget.post);
      setState(() => _loading = false);
    } catch (_) {
      if (_c == controller) _c = null;
      await controller.dispose();
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _stop() {
    final c = _c;
    _c = null;
    c?.dispose();
    if (mounted) {
      setState(() {
        _loading = false;
        _paused = false;
      });
    }
  }

  void _toggle() {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _paused = true;
      } else {
        c.play();
        _paused = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _failed
          ? _start
          : widget.active
          ? _toggle
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The still picture shows until the video is ready.
          if (!ready)
            widget.post.stillSrc != null
                ? NgPicture(url: widget.post.stillSrc, fit: widget.fit)
                : const ColoredBox(color: Colors.black),
          if (ready)
            ColoredBox(
              color: Colors.black,
              child: FittedBox(
                fit: widget.fit,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            ),
          if (_loading)
            const Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          if (_paused)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white70,
                size: 80,
              ),
            ),
          if (_failed)
            const Center(
              child: Icon(Icons.refresh, color: Colors.white70, size: 48),
            ),
          if (widget.controls && ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.magenta,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
