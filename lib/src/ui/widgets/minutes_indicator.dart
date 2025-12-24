import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/detox_controller.dart';
import '../theme/app_theme.dart';

class MinutesIndicator extends StatelessWidget {
  const MinutesIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DetoxController>(
      builder: (context, detoxController, child) {
        final minutesLeft = detoxController.minutesLeft;
        final minutesUsed = detoxController.minutesUsed;
        final percentage = detoxController.usagePercentage;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.softUICard,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Left Today',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$minutesLeft min',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: _getColorForMinutes(minutesLeft),
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Used',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$minutesUsed min',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  backgroundColor: AppTheme.mediumGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForPercentage(percentage),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColorForMinutes(int minutes) {
    if (minutes <= 0) return Colors.red;
    if (minutes <= 10) return Colors.orange;
    if (minutes <= 30) return Colors.yellow;
    return AppTheme.primaryWhite;
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.7) return Colors.orange;
    if (percentage >= 0.5) return Colors.yellow;
    return AppTheme.primaryWhite;
  }
}
