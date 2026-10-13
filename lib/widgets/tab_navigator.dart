import 'package:flutter/material.dart';

/// Gives a tab its own [Navigator], so pages pushed from it open inside the
/// tab and the app's bottom navigation bar stays visible underneath.
class TabNavigator extends StatefulWidget {
  const TabNavigator({super.key, required this.root});

  final Widget root;

  @override
  State<TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<TabNavigator> {
  final _key = GlobalKey<NavigatorState>();
  late final _observer = _StackObserver(_sync);
  bool _canPop = false;

  void _sync() {
    // Navigator callbacks can fire mid-build, so update after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final can = _key.currentState?.canPop() ?? false;
      if (mounted && can != _canPop) setState(() => _canPop = can);
    });
  }

  @override
  Widget build(BuildContext context) {
    // The system back button pops this tab's pages before leaving the app.
    return NavigatorPopHandler(
      enabled: _canPop,
      onPopWithResult: (_) => _key.currentState?.maybePop(),
      child: Navigator(
        key: _key,
        observers: [_observer],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => widget.root),
      ),
    );
  }
}

class _StackObserver extends NavigatorObserver {
  _StackObserver(this.onChange);

  final VoidCallback onChange;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onChange();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onChange();
}
