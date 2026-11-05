// Parent-dashboard session gate: in-memory only, never persisted.
// Set ONLY by ParentPinScreen after a correct PIN verify or a fresh
// PIN set. The router redirect reads this flag, so a deep link or a
// direct go to /parent-dashboard without it lands on /parent-pin.
// App restart clears it automatically (process memory); sign-out
// clears it explicitly in ProfileScreen._signOut.
import 'package:flutter/foundation.dart';

class ParentSession extends ChangeNotifier {
  bool _verified = false;
  bool get verified => _verified;

  void markVerified() {
    if (_verified) return;
    _verified = true;
    notifyListeners();
  }

  void clear() {
    if (!_verified) return;
    _verified = false;
    notifyListeners();
  }
}

final parentSession = ParentSession();
