import 'package:go_router/go_router.dart';
import '../features/registration/steps/step01_welcome.dart';
import '../features/registration/steps/step02_name.dart';
import '../features/registration/steps/step03_gender.dart';
import '../features/registration/steps/step04_class.dart';
import '../features/registration/steps/step05_medium.dart';
import '../features/registration/steps/step06_school.dart';
import '../features/registration/steps/step07_contact.dart';
import '../features/registration/steps/step08_password.dart';
import '../features/registration/steps/step09_otp.dart';
import '../features/registration/steps/step10_goal.dart';
import '../features/registration/steps/step11_guardian.dart';
import '../features/registration/steps/step12_review.dart';
import '../features/registration/steps/step13_success.dart';

// Registration wizard, 13 steps. Paths verified against step file headers.
// NOTE: there is no /registration route - login's old link to it was fixed
// to /register/welcome (see login_screen.dart).
final List<GoRoute> registrationRoutes = [
  GoRoute(path: '/register/welcome', builder: (c, s) => const Step01Welcome()),
  GoRoute(path: '/register/name', builder: (c, s) => const Step02Name()),
  GoRoute(path: '/register/gender', builder: (c, s) => const Step03Gender()),
  GoRoute(path: '/register/class', builder: (c, s) => const Step04Class()),
  GoRoute(path: '/register/medium', builder: (c, s) => const Step05Medium()),
  GoRoute(path: '/register/school', builder: (c, s) => const Step06School()),
  GoRoute(path: '/register/contact', builder: (c, s) => const Step07Contact()),
  GoRoute(path: '/register/password', builder: (c, s) => const Step08Password()),
  GoRoute(path: '/register/otp', builder: (c, s) => const Step09Otp()),
  GoRoute(path: '/register/goal', builder: (c, s) => const Step10Goal()),
  GoRoute(path: '/register/guardian', builder: (c, s) => const Step11Guardian()),
  GoRoute(path: '/register/review', builder: (c, s) => const Step12Review()),
  GoRoute(path: '/register/success', builder: (c, s) => const Step13Success()),
];
