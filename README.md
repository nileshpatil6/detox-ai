# Detox Launcher - Digital Detox Android Launcher

A minimal, monochrome Android launcher built with Flutter that helps you reduce smartphone usage and increase focus through intentional friction and reward-driven behavior.

## Overview

Detox Launcher is an Android home screen replacement that:

- **Enforces phone usage goals** with configurable daily/weekly limits
- **Makes distracting apps harder to access** through monochrome UI and intentional friction
- **Rewards productive activities** with phone time credits
- **Verifies tasks using AI** (Gemini 2.5 Flash) for authenticity
- **Provides escape hatches** through a pass system (Gold/Silver/Grey)

## Key Features

### 🏠 Launcher Functionality
- Replaces your default Android home screen
- Minimal, monochrome interface to reduce visual appeal
- Important apps always accessible
- Long-scrolling app list creates friction

### ⏱️ Usage Tracking & Limits
- Set daily and weekly phone time goals
- Real-time usage monitoring
- Lock mode when limits are exceeded
- Visual progress indicators

### ✅ Task-Based Rewards
- **Walking Tasks**: Earn minutes by taking steps
- **Reading Tasks**: Take photo of book page + answer comprehension questions
- **Creative Tasks**: Submit drawings or creative work
- **Physical Tasks**: Touch grass, plant something (photo/video verification)
- **AI Verification**: All tasks verified using Gemini 2.5 Flash multimodal AI

### 🎫 Pass System
- **Gold Pass** (2/month): Unlock for entire month
- **Silver Pass** (3/month): 10 minutes each
- **Grey Pass** (5/month): 2 minutes each (emergency use)

### 🤖 Robot Assistant
- Animated avatar with personality
- Motivational messages
- Voice/text interaction (planned)

## Tech Stack

- **Framework**: Flutter (Dart)
- **Platform**: Android (API 24+)
- **AI**: Google Gemini 2.5 Flash
- **Storage**: Hive (local), flutter_secure_storage (encrypted)
- **Services**:
  - AccessibilityService (app monitoring)
  - ForegroundService (persistence)
  - Usage Stats API
  - Pedometer
  - Camera

## Project Structure

```
detox/
├── android/
│   ├── app/
│   │   └── src/main/
│   │       ├── kotlin/com/detox/detox_launcher/
│   │       │   ├── MainActivity.kt
│   │       │   ├── DetoxAccessibilityService.kt
│   │       │   ├── DetoxForegroundService.kt
│   │       │   └── BootReceiver.kt
│   │       ├── res/
│   │       │   ├── values/strings.xml
│   │       │   └── xml/accessibility_service_config.xml
│   │       └── AndroidManifest.xml
│   ├── build.gradle
│   └── settings.gradle
├── lib/
│   ├── main.dart
│   └── src/
│       ├── ai/
│       │   └── gemini_service.dart
│       ├── controllers/
│       │   ├── detox_controller.dart
│       │   ├── usage_controller.dart
│       │   └── task_controller.dart
│       ├── models/
│       │   ├── user_profile.dart
│       │   ├── task.dart
│       │   └── session.dart
│       ├── services/
│       │   ├── storage_service.dart
│       │   └── notification_service.dart
│       └── ui/
│           ├── screens/
│           │   ├── onboarding_screen.dart
│           │   ├── launcher_home_screen.dart
│           │   └── lock_mode_screen.dart
│           ├── widgets/
│           │   ├── robot_avatar.dart
│           │   ├── minutes_indicator.dart
│           │   └── app_icon_widget.dart
│           └── theme/
│               └── app_theme.dart
├── pubspec.yaml
└── README.md
```

## Setup Instructions

### Prerequisites

1. **Flutter SDK** (3.0.0+)
   ```bash
   flutter doctor
   ```

2. **Android Studio** or Android SDK (API 24+)

3. **Gemini API Key**
   - Get your free API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Installation

1. **Clone or navigate to the project**
   ```bash
   cd detox
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Build the app**
   ```bash
   flutter build apk --release
   # or for development
   flutter run
   ```

4. **Install on Android device**
   ```bash
   flutter install
   ```

### First-Time Setup

1. **Launch the app** and complete onboarding:
   - Set daily/weekly goals (use presets or custom values)
   - Enter your motivation for reducing screen time
   - Review required permissions

2. **Set as Default Launcher**
   - Press the Home button on your device
   - Select "Detox Launcher" and choose "Always"
   - Or go to Settings > Apps > Default Apps > Home app

3. **Grant Required Permissions**

   #### Usage Access (Required)
   - Settings > Apps > Special Access > Usage Access
   - Enable for "Detox Launcher"
   - Allows tracking of app usage time

   #### Accessibility Service (Recommended)
   - Settings > Accessibility > Detox Launcher
   - Enable the service
   - Allows blocking apps in lock mode

   #### Camera (Required for Tasks)
   - Needed to verify photo/video tasks
   - Granted during onboarding

   #### Activity Recognition (Optional)
   - For step counting / walking tasks
   - Granted during onboarding

4. **Set Gemini API Key**
   - In the app, go to Settings (when implemented)
   - Enter your Gemini API key
   - This enables AI-powered task verification

## Usage Guide

### Daily Flow

1. **Wake up** → Detox Launcher is your home screen
2. **Check remaining minutes** in the top indicator
3. **Use allowed apps** from the Important Apps row
4. **Access other apps** from the scrolling list (creates friction)
5. **When locked out** → Complete tasks to earn minutes
6. **Use passes wisely** for emergencies or important needs

### Completing Tasks

#### Walking Task
1. Tap task card
2. **New:** Opens dedicated walking tracker screen
3. Start walking and watch real-time step count
4. Progress bar shows completion percentage
5. Automatically verified by pedometer when target reached
6. Minutes added to your balance instantly

#### Reading Task
1. Tap task card
2. Take photo of book page with in-app camera
3. AI extracts text via OCR
4. **New:** Navigate to Q&A screen with generated questions
5. Answer 2 comprehension questions in text fields
6. AI verifies your answers for comprehension
7. Earn minutes upon correct answers

#### Photo Tasks (Touch Grass, Creative, etc.)
1. Tap task card
2. **New:** Opens full-screen camera interface
3. Take live photo (gallery uploads blocked)
4. Review and retake if needed
5. Submit for AI verification
6. Real-time processing feedback
7. Earn minutes if verified

#### Video Tasks (Planting, etc.)
1. Tap task card
2. **New:** Camera screen with video recording controls
3. Record short video (with start/stop button)
4. Review recording before submission
5. AI analyzes video frames for verification
6. Earn more minutes (higher reward for video tasks)

### Using Passes

**Gold Pass** (Nuclear Option)
- Unlocks phone for entire month
- Use only in extreme circumstances
- 2 per month

**Silver Pass** (Moderate Relief)
- Grants 10 minutes
- 3 per month
- Good for important tasks

**Grey Pass** (Emergency)
- Grants 2 minutes
- 5 per month
- Quick emergency access

## Advanced Configuration

### Strict Mode (Device Owner)

For maximum enforcement, you can provision the app as a Device Owner. This enables:

- Kiosk mode (prevents changing launcher)
- Prevents force-stop
- Prevents uninstallation
- Stronger app blocking

**⚠️ Warning**: Device Owner setup requires factory reset to remove. Only use on dedicated devices.

**Setup** (requires ADB):
```bash
# Factory reset device first
adb shell dpm set-device-owner com.detox.detox_launcher/.MainActivity
```

### Customization

#### Adjusting Goals
- Edit goals in Settings (when implemented)
- Reset monthly passes on the 1st of each month

#### Managing Allowed Apps
- Mark frequently needed apps as "Important"
- These appear in the quick-access row

#### Task Difficulty
- Adjust step requirements for walking tasks
- Configure reward minutes per task type

## Troubleshooting

### Lock Mode Not Working
- Ensure Accessibility Service is enabled
- Check that app has Usage Access permission
- Restart the app

### Tasks Not Verifying
- Check internet connection (Gemini API requires network)
- Verify Gemini API key is set correctly
- Ensure you're using live camera (not gallery)

### App Crashes / Force Closes
- Enable Foreground Service for persistence
- Check Android battery optimization (disable for this app)
- Review system logs: `adb logcat | grep Detox`

### Can't Set as Default Launcher
- Go to Settings > Apps > Default Apps > Home app
- Select Detox Launcher
- Press Home button to test

### Gemini API Quota Exceeded
- Free tier: 15 requests per minute, 1,500 per day
- Reduce task verification frequency
- Upgrade to paid tier if needed

## Limitations & Bypass Risks

### What Can Be Bypassed (Standard Mode)

1. **Force Stop**: User can force-stop the app in Settings
2. **Uninstall**: User can uninstall the app
3. **Change Launcher**: User can switch to another launcher
4. **Safe Mode**: Booting in safe mode disables the launcher
5. **Factory Reset**: Nuclear option but always possible

### Mitigation Strategies

- **Social Accountability**: Share your progress with someone
- **Device Owner Mode**: Maximum enforcement (see Advanced Configuration)
- **Physical Barriers**: Keep charger in another room, etc.
- **Mindfulness**: Remember your motivation

### What Cannot Be Prevented

- Power off the device
- Emergency calls (always allowed)
- System Settings access (by design for safety)

## Privacy & Data

### Local-First Approach
- All usage data stored locally on device
- Gemini API calls: only task verification images sent
- No analytics or tracking

### Data Collected
- App usage stats (local only)
- Task completion history (local only)
- Photos/videos for verification (temporary, deleted after verification)

### Gemini API Privacy
- Images sent to Google for verification
- Not stored permanently by Google (per their policy)
- See [Gemini API Privacy Policy](https://ai.google.dev/gemini-api/terms)

## Roadmap

### MVP (Completed)
- ✅ Launcher functionality
- ✅ Usage tracking and lock mode
- ✅ Task system with Gemini verification
- ✅ Pass system
- ✅ Basic UI and onboarding

### Phase 2 (Completed)
- ✅ Camera task execution UI with live capture
- ✅ Step counter implementation
- ✅ Usage stats integration
- ✅ Settings screen with full configuration
- ✅ Walking task tracker with real-time progress
- ✅ Reading comprehension Q&A flow
- ✅ Platform channel integration for native operations

### Phase 3 (Next)
- ⬜ Device owner provisioning guide
- ⬜ Weekly/monthly reports
- ⬜ Streak tracking
- ⬜ Social accountability features
- ⬜ Focus mode scheduling
- ⬜ Voice interaction with robot

### Future Considerations
- iOS companion app (non-launcher, tracking only)
- Widget support
- Themes (monochrome variants)
- Export/import data
- Cloud sync (optional, opt-in)

## Development

### Running in Development
```bash
flutter run
```

### Building Release APK
```bash
flutter build apk --release
```

### Running Tests
```bash
flutter test
```

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` before commits

## Contributing

This is currently a solo project. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Email: [your-email]

## Acknowledgments

- Google Gemini AI for task verification
- Flutter team for the amazing framework
- Digital wellness researchers for inspiration

## Disclaimer

This app is a tool to assist with digital wellness goals. It is not foolproof and should be used as part of a broader strategy for healthy phone usage. The developers are not responsible for any issues arising from use or bypass of the app's restrictions.

---

**Built with 🤖 for humans who want to touch more grass.**
