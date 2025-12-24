import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import '../theme/app_theme.dart';

class AppIconWidget extends StatelessWidget {
  final Application app;
  final VoidCallback onTap;
  final bool isMonochrome;

  const AppIconWidget({
    super.key,
    required this.app,
    required this.onTap,
    this.isMonochrome = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.softGrey,
              ),
              child: app is ApplicationWithIcon
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isMonochrome
                          ? ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.saturation,
                              ),
                              child: Image.memory(
                                (app as ApplicationWithIcon).icon,
                                width: 56,
                                height: 56,
                              ),
                            )
                          : Image.memory(
                              (app as ApplicationWithIcon).icon,
                              width: 56,
                              height: 56,
                            ),
                    )
                  : const Icon(Icons.apps, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 4),
            Text(
              app.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.veryLightGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
