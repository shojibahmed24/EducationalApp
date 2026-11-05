// Route: /register/class (Step 4/13)
// Class appears ONLY here (plus Profile Settings change, separate agent).
// UI ONLY - saves to local mock registrationDataNotifier.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/pages/reg_step04_strings.dart';
import '../../../theme/app_theme.dart';
import '../registration_data.dart';
import '../widgets/reg_scaffold.dart';
import '../widgets/reg_widgets.dart';

class Step04Class extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const Step04Class({super.key, this.onNext, this.onBack});

  @override
  State<Step04Class> createState() => _Step04ClassState();
}

class _Step04ClassState extends State<Step04Class> with RegLangMixin {
  int? _cls = registrationDataNotifier.value.schoolClass;

  void _next() {
    if (_cls != null) {
      updateRegistration(
          registrationDataNotifier.value.copyWith(schoolClass: _cls));
    }
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      context.go('/register/medium');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = isBangla ? regStep04Bn : regStep04En;
    return RegScaffold(
      step: 4,
      title: s['title']!,
      subtitle: s['subtitle']!,
      nextLabel: s['next']!,
      nextEnabled: _cls != null,
      onNext: _next,
      onBack: widget.onBack,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 10,
        itemBuilder: (context, i) {
          final cls = i + 1;
          final selected = _cls == cls;
          return Card(
            color: selected
                ? AppTheme.amber.withValues(alpha: 0.25)
                : AppTheme.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: selected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _cls = cls),
              child: Center(
                child: Text('${s['classPrefix']} $cls',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
            ),
          );
        },
      ),
    );
  }
}
