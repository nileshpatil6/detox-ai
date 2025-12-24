import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/ui/screens/onboarding_screen.dart';
import 'src/ui/screens/launcher_home_screen.dart';
import 'src/ui/screens/lock_mode_screen.dart';
import 'src/ui/theme/app_theme.dart';
import 'src/controllers/detox_controller.dart';
import 'src/controllers/usage_controller.dart';
import 'src/controllers/task_controller.dart';
import 'src/services/storage_service.dart';
import 'src/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness
          .light, // Fixed: was dark, should be light for dark background
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DetoxLauncherApp());
}

class DetoxLauncherApp extends StatelessWidget {
  const DetoxLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DetoxController()),
        ChangeNotifierProvider(create: (_) => UsageController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
      ],
      child: MaterialApp(
        title: 'Detox Launcher',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkMonochrome,
        home: const InitialRouteResolver(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const LauncherHomeScreen(),
          '/lock': (context) => const LockModeScreen(),
        },
      ),
    );
  }
}

class InitialRouteResolver extends StatelessWidget {
  const InitialRouteResolver({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();

    return FutureBuilder<bool>(
      future: storageService.isOnboardingComplete(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        final isOnboarded = snapshot.data ?? false;

        if (!isOnboarded) {
          return const OnboardingScreen();
        }

        // Check if in lock mode
        final detoxController = context.read<DetoxController>();
        return FutureBuilder<bool>(
          future: detoxController.checkLockStatus(),
          builder: (context, lockSnapshot) {
            if (lockSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              );
            }

            final isLocked = lockSnapshot.data ?? false;
            return isLocked
                ? const LockModeScreen()
                : const LauncherHomeScreen();
          },
        );
      },
    );
  }
}
