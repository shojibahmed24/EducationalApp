// BackScope — system-back handler for go()-only routes (Phase 6, H1).
// context.go() replaces the route, so the Navigator stack holds a
// single entry and Android system back would otherwise exit the app
// instead of going to the logical parent. Wrap a route's screen in
// this (in its router builder) and system back goes to [parent],
// the same destination as the screen's visible AppBar back button.
// Programmatic go()/push() navigation is unaffected, and dialogs
// on top of the screen still pop normally (they are their own route).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackScope extends StatelessWidget {
  const BackScope({super.key, required this.parent, required this.child});
  final String parent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(parent);
      },
      child: child,
    );
  }
}
