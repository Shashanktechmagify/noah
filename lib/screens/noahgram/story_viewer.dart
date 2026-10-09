import 'package:flutter/material.dart';

import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import 'noahgram_widgets.dart';

/// Full-screen story: progress bars, auto-advance, tap right/left to skip.
class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key, required this.person});

  final Person person;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late final List<Look> _frames = noahgram.storyFrames(widget.person);
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _next();
        });
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => noahgram.markStorySeen(widget.person),
    );
    _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _frames.length - 1) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
    _progress.forward(from: 0);
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
    _progress.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final look = _frames[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final width = MediaQuery.of(context).size.width;
          d.localPosition.dx < width / 3 ? _prev() : _next();
        },
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 300) Navigator.of(context).pop();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            LookCanvas(look: look),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < _frames.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: i == _index
                                    ? AnimatedBuilder(
                                        animation: _progress,
                                        builder: (_, _) =>
                                            LinearProgressIndicator(
                                              value: _progress.value,
                                              minHeight: 3,
                                              backgroundColor: Colors.white30,
                                              color: Colors.white,
                                            ),
                                      )
                                    : LinearProgressIndicator(
                                        value: i < _index ? 1 : 0,
                                        minHeight: 3,
                                        backgroundColor: Colors.white30,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Avatar(person: widget.person, size: 34),
                        const SizedBox(width: 10),
                        Text(
                          widget.person.handle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          agoText(context, 2),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                child: Container(
                  height: 46,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: Colors.white70),
                  ),
                  child: Text(
                    '${tr(context, 'ng_message')} ${widget.person.handle}…',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
