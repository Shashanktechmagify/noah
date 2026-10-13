import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'hex_pattern.dart';

/// Purple hero header with a white rounded sheet below it (login + OTP).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.footer,
    this.topRight,
    this.headerHeight = 290,
  });

  /// Omit for a compact header with no icon or title.
  final IconData? icon;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;

  /// Shown in a strip along the top of the header (e.g. language pills).
  final Widget? topRight;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final headerH = headerHeight + top;
    return Scaffold(
      backgroundColor: Colors.white,
      // The keyboard pushes the page up; the whole page (header included)
      // scrolls, and the footer button stays above the keyboard.
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: headerH,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.headerGradient,
                        ),
                        child: const HexPattern(),
                      ),
                    ),
                    if (icon != null)
                      Positioned(
                        top: top + (topRight != null ? 58 : 20),
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(icon!, color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (topRight != null)
                      Positioned(
                        top: top + 12,
                        left: 0,
                        right: 0,
                        child: topRight!,
                      ),
                    if (onBack != null)
                      Positioned(
                        top: top + 14,
                        left: 14,
                        child: GestureDetector(
                          onTap: onBack,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    // The white sheet sits over the bottom of the header.
                    Padding(
                      padding: EdgeInsets.only(top: headerH - 36),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: (box.maxHeight - (headerH - 36)).clamp(
                            0,
                            double.infinity,
                          ),
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(36),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).padding.bottom + 14,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.buttonGradient : null,
          color: enabled ? null : const Color(0xFFE2DDF1),
          borderRadius: BorderRadius.circular(26),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.magenta.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : const Color(0xFFB9B4D0),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
