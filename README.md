# Prop Manager

Simple Android app to manage FPV drone propeller inventory. Track CW and CCW stock per prop type, with low-stock warnings.

Built with Flutter + Material 3.

## Features

- Add prop types with name and initial CW/CCW counts
- **+ / −** buttons to adjust stock when buying or breaking props
- Red card background when CW or CCW drops below threshold
- Red warning banner when any prop type is critically low
- Data persists locally as JSON

## Changing the Warning Threshold

Edit `lib/main.dart`, line ~7:

```dart
// Change this to adjust the low-stock warning threshold
const int criticalThreshold = 10;
```

Change `10` to whatever number you want (e.g., `5` if you want the warning later, `20` for earlier). Then rebuild:

```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Build from Source

Requirements: Flutter SDK, JDK 21, Android SDK Build-Tools 35.

```bash
export JAVA_HOME=/path/to/jdk21
flutter pub get
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Download

Get the latest APK from the [Releases](https://github.com/KyokoSpl/prop_manager/releases) page.

## License

MIT
