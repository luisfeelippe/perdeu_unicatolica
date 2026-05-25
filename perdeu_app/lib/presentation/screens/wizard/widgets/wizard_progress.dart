import 'package:flutter/material.dart';

class WizardProgress extends StatelessWidget {
  const WizardProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  static const Color _orange = Color(0xFFFF6600);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passo $currentStep de $totalSteps',
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(totalSteps, (index) {
            final step = index + 1;
            final isDone = step < currentStep;
            final isCurrent = step == currentStep;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index == totalSteps - 1 ? 0 : 8,
                ),
                height: 9,
                decoration: BoxDecoration(
                  color: isDone || isCurrent
                      ? _orange
                      : const Color(0xFFE6E0DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}