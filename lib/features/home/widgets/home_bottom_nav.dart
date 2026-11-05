import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom nav shared by Home + Learn screens. Practice / Progress /
/// Profile are other groups' routes; integration wires them in.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.current, required this.labels});
  final int current;
  final List<String> labels; // home, search, practice, progress, profile

  void _go(BuildContext context, int index) {
    // Step 7: the Search tab lands on the NEW search flow
    // (defaults: saved class + math), never a deleted route.
    const routes = ['/home', '/search-flow', '/practice', '/progress', '/profile'];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_outlined,
      Icons.search_outlined,
      Icons.edit_note_outlined,
      Icons.trending_up_outlined,
      Icons.account_circle_outlined,
    ];
    return BottomNavigationBar(
      currentIndex: current,
      type: BottomNavigationBarType.fixed,
      onTap: (i) => _go(context, i),
      items: List.generate(5, (i) {
        return BottomNavigationBarItem(icon: Icon(icons[i]), label: labels[i]);
      }),
    );
  }
}
