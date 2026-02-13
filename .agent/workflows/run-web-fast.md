---
description: Run Flutter web faster with optimized settings
---

# Run Flutter Web Fast

## Quick Start (Fastest)

Use HTML renderer instead of CanvasKit for faster initial load:

```bash
flutter run -d chrome --web-renderer html
```

## Clean Build (If Having Issues)

```bash
flutter clean
flutter pub get
flutter run -d chrome --web-renderer html
```

## Profile Mode (Best Performance Testing)

```bash
flutter run -d chrome --profile --web-renderer html
```

## Release Mode (Production-like)

```bash
flutter run -d chrome --release
```

## Tips for Faster Development

1. **Don't close Chrome** - Keep it open and use hot reload (press `r`)
2. **Use hot restart** - Press `R` for faster restart than full rebuild
3. **Avoid `flutter clean`** - Only use when necessary, it clears cache
4. **Close unused apps** - Free up RAM for faster compilation
5. **Use SSD** - Compilation is much faster on SSD than HDD
