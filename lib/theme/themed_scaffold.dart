// Scaffold with the layered AppBackground behind the body
// (UI plan §5.2/phase 3). The body is wrapped in
// Positioned.fill, so it keeps exactly the tight constraints a
// plain Scaffold body gives — layout, padding and scrolling do
// not change, only the background layer is added. [calm] is
// for lesson/chat reading areas (gradient only, no blobs).
import 'package:flutter/material.dart';

import 'app_background.dart';

class ThemedScaffold extends StatelessWidget {
  const ThemedScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.calm = false,
  });
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: body == null
          ? const AppBackground()
          : Stack(
              children: [
                AppBackground(calm: calm),
                Positioned.fill(child: body),
              ],
            ),
    );
  }
}
