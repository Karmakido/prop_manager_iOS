# Prop Manager

Simple Android app to manage FPV drone propeller inventory. Track CW and CCW stock per prop type, with configurable low-stock warnings.

Built with Flutter + Material 3.

## Features

- Add prop types with name, initial CW/CCW counts, and optional order link
- **+ / −** buttons to adjust stock when buying or breaking props
- **Edit** prop details (name, counts, order link) via pen icon on each card
- **Order link** — tap "Bestellen" on any prop card to open its shop URL in browser
- Red card background when CW or CCW drops below the threshold
- Red warning banner when any prop type is critically low
- **Settings screen** (gear icon) to configure:
  - **Theme**: Light / Dark / Follow system
  - **Critical threshold**: stock level that triggers the warning (default 10)
- Dark mode by default, Material 3 design
- Data persists locally as JSON (`props.json` + `settings.json`)

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
