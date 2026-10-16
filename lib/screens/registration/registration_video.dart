import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/registration_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart';
import 'registration_widgets.dart' show declarationIntro;
import 'uploads.dart';
import 'registration_status.dart';

String clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Plays the recorded video KYC in a popup.
Future<void> showVideoDialog(BuildContext context) {
  final path = registration.videoPath;
  return showDialog<void>(
    context: context,
    builder: (dialog) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr(dialog, 'reg_video_title'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (path == null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  tr(dialog, 'reg_video_demo'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else
              _VideoPlayerBox(path: path, height: 360, autoPlay: true),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: Text(
                tr(dialog, 'reg_close'),
                style: const TextStyle(
                  color: AppColors.magenta,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A video player that toggles on tap.
class _VideoPlayerBox extends StatefulWidget {
  const _VideoPlayerBox({
    super.key,
    required this.path,
    required this.height,
    this.autoPlay = false,
  });

  final String path;
  final double height;
  final bool autoPlay;

  @override
  State<_VideoPlayerBox> createState() => _VideoPlayerBoxState();
}

class _VideoPlayerBoxState extends State<_VideoPlayerBox> {
  VideoPlayerController? _c;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.file(File(widget.path));
      await c.initialize();
      await c.setLooping(true);
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _c = c);
      if (widget.autoPlay) await c.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF10131E),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: c == null
          ? Center(
              child: _failed
                  ? const Icon(Icons.error_outline, color: Colors.white54)
                  : const CircularProgressIndicator(color: Colors.white54),
            )
          : GestureDetector(
              onTap: () => c.value.isPlaying ? c.pause() : c.play(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: c.value.size.width,
                      height: c.value.size.height,
                      child: VideoPlayer(c),
                    ),
                  ),
                  if (!c.value.isPlaying)
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Step 6: record a short read-aloud video with the front camera, then watch it
/// back before submitting. Falls back to a timer-only demo if there is no camera.
class VideoStep extends StatefulWidget {
  const VideoStep({super.key});

  @override
  State<VideoStep> createState() => _VideoStepState();
}

class _VideoStepState extends State<VideoStep> {
  CameraController? _cam;
  bool _demo = false;
  Timer? _timer;
  bool _recording = false;
  bool _compressing = false;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_langSet) {
      _langSet = true;
      final app = AppLocale.of(context).lang;
      _lang = app == AppLang.hi || app == AppLang.mr ? app : AppLang.en;
      registration.videoLang = _lang;
    }
  }

  bool _langSet = false;
  final _scriptScroll = ScrollController();

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw StateError('no camera');
      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _cam = controller);
    } catch (_) {
      if (mounted) setState(() => _demo = true);
    }
  }

  @override
  void dispose() {
    _scriptScroll.dispose();
    _timer?.cancel();
    final cam = _cam;
    if (cam != null) {
      if (cam.value.isRecordingVideo) {
        cam.stopVideoRecording().catchError((_) => XFile(''));
      }
      cam.dispose();
    }
    super.dispose();
  }

  Future<void> _start() async {
    registration.videoSeconds = null;
    registration.videoPath = null;
    registration.touch();
    final cam = _cam;
    if (cam != null) {
      try {
        await cam.startVideoRecording();
      } catch (_) {
        _demo = true;
      }
    }
    if (!mounted) return;
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      if (_seconds >= videoLimits(_lang).$2) _stop();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    String? path;
    final cam = _cam;
    if (cam != null && cam.value.isRecordingVideo) {
      try {
        path = (await cam.stopVideoRecording()).path;
      } catch (_) {}
    }
    registration.videoSeconds = _seconds;
    registration.videoPath = path;
    registration.videoBytes = registration.videoOriginalBytes = null;
    registration.touch();
    if (mounted) setState(() => _recording = false);
    if (path != null) await _compress(path);
  }

  /// Shrinks the file so it does not fill up storage once uploaded.
  Future<void> _compress(String path) async {
    if (mounted) setState(() => _compressing = true);
    final out = await compressVideo(path);
    registration.videoPath = out.path;
    registration.videoBytes = out.after;
    registration.videoOriginalBytes = out.before;
    registration.touch();
    if (mounted) setState(() => _compressing = false);
  }

  void _again() {
    registration.videoSeconds = null;
    registration.videoPath = null;
    registration.touch();
    setState(() => _seconds = 0);
  }

  void _complete() {
    registration.complete();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const RegistrationStatusScreen(showSuccess: true),
      ),
    );
  }

  AppLang _lang = AppLang.en;

  /// The whole declaration, read aloud in the chosen language.
  Widget _script(BuildContext context) {
    final paragraphs = trIn(_lang, 'reg_decl_body').split('\n\n');
    const body = TextStyle(
      fontSize: 15,
      height: 1.5,
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trIn(_lang, 'reg_decl_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text.rich(
          declarationIntro(
            _lang,
            highlight: const TextStyle(
              color: AppColors.magenta,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: body,
        ),
        const SizedBox(height: 10),
        for (final p in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(p, style: body),
          ),
      ],
    );
  }

  Widget _preview() {
    final cam = _cam;
    final size = cam?.value.previewSize;
    if (cam == null || size == null) return const SizedBox.expand();
    // The sensor reports landscape sizes; swap for a portrait preview.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.height,
        height: size.width,
        child: CameraPreview(cam),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = registration;
    final recorded = !_recording && r.videoSeconds != null;
    final shown = recorded ? r.videoSeconds! : _seconds;
    final badge = _recording
        ? 'reg_recording'
        : recorded
        ? 'reg_recorded'
        : 'reg_cam_ready';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.status == RegStatus.videoReturned)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEBD3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              tr(context, 'reg_returned_note'),
              style: const TextStyle(
                color: Color(0xFFC2620A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (recorded && r.videoPath != null)
          // Watch the recording back before submitting.
          _VideoPlayerBox(
            key: ValueKey(r.videoPath),
            path: r.videoPath!,
            height: 300,
          )
        else
          Container(
            height: 250,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF232A3F), Color(0xFF10131E)],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cam != null) _preview(),
                Positioned(
                  left: 14,
                  top: 14,
                  child: _Badge(
                    dot: _recording ? const Color(0xFFE5334B) : Colors.white54,
                    text: tr(context, badge),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: _Badge(text: clock(shown)),
                ),
                if (recorded)
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                else ...[
                  Center(
                    child: CustomPaint(
                      size: const Size(130, 170),
                      painter: _OvalPainter(),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: Text(
                      tr(context, 'reg_oval'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        if (recorded) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _Check(label: tr(context, 'reg_chk_face'), ok: true),
                const Divider(height: 1, color: AppColors.border),
                _Check(label: tr(context, 'reg_chk_voice'), ok: true),
                const Divider(height: 1, color: AppColors.border),
                _Check(
                  label: tr(
                    context,
                    'reg_chk_len',
                    args: {
                      'len': clock(shown),
                      'min': '${videoLimits(r.videoLang).$1}',
                      'max': '${videoLimits(r.videoLang).$2}',
                    },
                  ),
                  ok: r.videoValid,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_compressing)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tr(context, 'reg_compressing'),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            )
          else if (r.videoBytes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: Text(
                  tr(
                    context,
                    'reg_video_size',
                    args: {
                      'now': formatBytes(r.videoBytes!),
                      'was': formatBytes(r.videoOriginalBytes ?? r.videoBytes!),
                    },
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          GradientButton(
            label: tr(context, 'reg_complete'),
            onPressed: r.videoValid && !_compressing ? _complete : null,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _again,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Text(
                tr(context, 'reg_record_again'),
                style: const TextStyle(
                  color: Color(0xFF555770),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ] else ...[
          // Read the declaration in English, Hindi or Marathi.
          Row(
            children: [
              for (final l in [AppLang.en, AppLang.hi, AppLang.mr])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: _recording
                        ? null
                        : () => setState(() {
                            _lang = l;
                            registration.videoLang = l;
                          }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: l == _lang ? AppColors.magenta : AppColors.tint,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        l.native,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: l == _lang ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Scrollbar(
              controller: _scriptScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scriptScroll,
                padding: const EdgeInsets.all(16),
                child: _script(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'reg_vid_note'),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _seconds / videoLimits(_lang).$2,
              minHeight: 5,
              backgroundColor: const Color(0xFFE3DDF1),
              color: AppColors.magenta,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              tr(
                context,
                'reg_secs',
                args: {
                  'min': '${videoLimits(_lang).$1}',
                  'max': '${videoLimits(_lang).$2}',
                },
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _recording ? _stop : _start,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _recording
                        ? Icons.stop_circle_outlined
                        : Icons.videocam_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr(context, _recording ? 'reg_stop_rec' : 'reg_start_rec'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_demo)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  tr(context, 'reg_cam_unavailable'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.dot});

  final String text;
  final Color? dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _Check extends StatelessWidget {
  const _Check({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ok ? const Color(0xFFA719C8) : const Color(0xFFD6334B),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            ok ? Icons.check : Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _OvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()..addOval(Offset.zero & size);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_OvalPainter old) => false;
}
