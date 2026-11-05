// RegistrationWizard - OPTIONAL container for the 13 steps.
// Integration agent: EITHER mount this at /register (it slides between
// steps with AnimatedSwitcher) OR mount each step at its route below.
// It does NOT replace the individual step routes.
// UI ONLY - local mock state, // TODO backend on Step 12 confirm.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'steps/step01_welcome.dart';
import 'steps/step02_name.dart';
import 'steps/step03_gender.dart';
import 'steps/step04_class.dart';
import 'steps/step05_medium.dart';
import 'steps/step06_school.dart';
import 'steps/step07_contact.dart';
import 'steps/step08_password.dart';
import 'steps/step09_otp.dart';
import 'steps/step10_goal.dart';
import 'steps/step11_guardian.dart';
import 'steps/step12_review.dart';
import 'steps/step13_success.dart';

class RegistrationWizard extends StatefulWidget {
  const RegistrationWizard({super.key});

  @override
  State<RegistrationWizard> createState() => _RegistrationWizardState();
}

class _RegistrationWizardState extends State<RegistrationWizard> {
  int _index = 0;

  void _next() => setState(() => _index = (_index + 1).clamp(0, 12));
  void _back() => setState(() => _index = (_index - 1).clamp(0, 12));

  Widget _step() {
    switch (_index) {
      case 0:
        return Step01Welcome(onNext: _next);
      case 1:
        return Step02Name(onNext: _next, onBack: _back);
      case 2:
        return Step03Gender(onNext: _next, onBack: _back, onSkip: _next);
      case 3:
        return Step04Class(onNext: _next, onBack: _back);
      case 4:
        return Step05Medium(onNext: _next, onBack: _back);
      case 5:
        return Step06School(onNext: _next, onBack: _back, onSkip: _next);
      case 6:
        return Step07Contact(onNext: _next, onBack: _back);
      case 7:
        return Step08Password(onNext: _next, onBack: _back);
      case 8:
        return Step09Otp(onNext: _next, onBack: _back);
      case 9:
        return Step10Goal(onNext: _next, onBack: _back);
      case 10:
        return Step11Guardian(
            onNext: _next, onBack: _back, onSkip: _next);
      case 11:
        return Step12Review(onNext: _next, onBack: _back);
      default:
        return Step13Success(onNext: () => context.go('/home'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: KeyedSubtree(key: ValueKey(_index), child: _step()),
    );
  }
}
