# Project IDX / Google Stitch Integration

This project is now configured for **Project IDX** (Google's AI-focused cloud IDE).

## What this enables
1.  **AI Coding Assistance:** Access to Gemini for code generation and explanation within the IDX environment.
2.  **Cloud Emulators:** Run iOS/Android/Web simulators directly in the browser.
3.  **Google Stitch (Future):** As Google Stitch features roll out for Flutter, remaining in the IDX environment ensures you get them first.

## How to use
1.  Push this code to GitHub.
2.  Go to [idx.google.com](https://idx.google.com/).
3.  Choose "Import a repo" and select this repository.
4.  IDX will detect the `.idx/dev.nix` configuration and set up your Flutter environment automatically.

## Configuration
The environment is configured in `.idx/dev.nix`.
- **Flutter & Dart** pre-installed
- **Firebase Tools** pre-installed
- **Android & Web Previews** enabled
