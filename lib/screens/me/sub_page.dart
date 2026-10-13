import 'package:flutter/material.dart';

import '../../widgets/page_scaffold.dart';

/// A page inside the Me tab: purple header with a back arrow, then content.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    this.subtitle = '',
    this.bandHeight = 150,
    this.headerExtra,
    required this.children,
  });

  final String title;
  final String subtitle;
  final double bandHeight;
  final Widget? headerExtra;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageScaffold(
      title: title,
      subtitle: subtitle,
      leadingIcon: Icons.arrow_back,
      onLeading: () => Navigator.of(context).pop(),
      bandHeight: bandHeight,
      headerExtra: headerExtra,
      children: children,
    ),
  );
}
