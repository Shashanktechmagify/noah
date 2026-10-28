import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/registration_sync.dart' show describeApiError;
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Runs [task] behind a full-screen loading page that cannot be dismissed or backed out of, so the
/// member stays on it until the work is done. [task] reports what it is doing with a translation
/// key (`reg_up_video` ...). Returns true when the task finished; on an error the page says what
/// went wrong and offers Try again / Close (Close returns false).
Future<bool> runBlockingTask(
  BuildContext context,
  Future<void> Function(ValueChanged<String> status) task, {
  String titleKey = 'reg_up_title',
}) async {
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => _BlockingTask(task: task, titleKey: titleKey),
  );
  return ok == true;
}

class _BlockingTask extends StatefulWidget {
  const _BlockingTask({required this.task, required this.titleKey});

  final Future<void> Function(ValueChanged<String> status) task;
  final String titleKey;

  @override
  State<_BlockingTask> createState() => _BlockingTaskState();
}

class _BlockingTaskState extends State<_BlockingTask> {
  String _status = 'reg_up_save';
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _error = null);
    try {
      await widget.task((key) {
        if (mounted) setState(() => _status = key);
      });
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = describeApiError(e));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final failed = _error != null;
    return PopScope(
      canPop: false, // the back button does nothing while the upload runs
      child: Material(
        color: Colors.white.withValues(alpha: 0.96),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (failed)
                      const Icon(
                        Icons.error_outline,
                        size: 54,
                        color: Color(0xFFE5334B),
                      )
                    else
                      const SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(strokeWidth: 4),
                      ),
                    const SizedBox(height: 22),
                    Text(
                      failed
                          ? tr(context, 'reg_up_failed')
                          : tr(context, widget.titleKey),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      failed ? _error! : tr(context, _status),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                    ),
                    if (!failed) ...[
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(minHeight: 6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr(context, 'reg_up_keep'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 22),
                      _Button(
                        label: tr(context, 'reg_up_retry'),
                        filled: true,
                        onTap: _run,
                      ),
                      const SizedBox(height: 10),
                      _Button(
                        label: tr(context, 'reg_up_close'),
                        filled: false,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: filled ? AppColors.buttonGradient : null,
        color: filled ? null : AppColors.tint,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : const Color(0xFF555770),
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
