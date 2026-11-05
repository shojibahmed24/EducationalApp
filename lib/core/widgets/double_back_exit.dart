// DoubleBackExit — system-back handler for the /home tab root.
// Home has no parent, so a plain system back would silently exit
// the app. First press shows [message] and does nothing; a second
// press within 2 seconds exits. Tapping the bottom nav never exits.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoubleBackExit extends StatefulWidget {
  const DoubleBackExit({super.key, required this.message, required this.child});
  final String message;
  final Widget child;

  @override
  State<DoubleBackExit> createState() => _DoubleBackExitState();
}

class _DoubleBackExitState extends State<DoubleBackExit> {
  DateTime? _lastPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPress != null &&
            now.difference(_lastPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.message)),
        );
      },
      child: widget.child,
    );
  }
}
