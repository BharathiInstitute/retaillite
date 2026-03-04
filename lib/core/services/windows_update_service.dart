/// Windows 5-Layer Bulletproof Auto-Update Service
///
/// Escalating fallback strategy — guarantees 100% update delivery:
///   Layer 1: Silent background download + watchdog (zero interaction)
///   Layer 2: Pending install recovery on next launch
///   Layer 3: Silent retry with fresh re-download (up to 3 attempts)
///   Layer 4: One-click "Update Available" dialog (user sees it)
///   Layer 5: Force update block via Remote Config (handled in main.dart)
///
/// Flow:
///   1. App starts → checks pending installs (Layer 2)
///   2. Background: fetches version.json from Firebase Storage
///   3. If newer → downloads installer silently (Layer 1)
///   4. Watchdog monitors PID → installs on app close
///   5. If watchdog fails → retry on next launch (Layer 2/3)
///   6. After 3 silent failures → show UpdateDialog (Layer 4)
///   7. Remote Config min_app_version blocks very old versions (Layer 5)
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Version info from remote server
class AppVersionInfo {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;

  const AppVersionInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.changelog = '',
    this.forceUpdate = false,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      downloadUrl:
          (json['exeDownloadUrl'] as String?) ??
          (json['downloadUrl'] as String),
      changelog: (json['changelog'] as String?) ?? '',
      forceUpdate: (json['forceUpdate'] as bool?) ?? false,
    );
  }
}

/// Update check result
enum UpdateStatus { upToDate, updateAvailable, error }

class UpdateCheckResult {
  final UpdateStatus status;
  final AppVersionInfo? versionInfo;
  final String? error;

  const UpdateCheckResult({required this.status, this.versionInfo, this.error});
}

/// Current update layer status — used by UI to decide what to show
enum UpdateLayer {
  /// No update available
  upToDate,

  /// Layers 1-3: Silent updates in progress — don't show anything
  silentInProgress,

  /// Layer 4: Silent failed 3+ times — show one-click dialog
  showDialog,

  /// Layer 5: Force update — handled by Remote Config in main.dart
  forceUpdate,
}

class WindowsUpdateService {
  // Firebase Storage URL for version manifest
  static const String _versionUrl =
      'https://firebasestorage.googleapis.com/v0/b/login-radha.firebasestorage.app/o/downloads%2Fwindows%2Fversion.json?alt=media';

  /// Max silent attempts before escalating to dialog (Layer 4)
  static const int _maxSilentAttempts = 3;

  /// Detect if running as MSIX (Microsoft Store install).
  /// MSIX apps run from the WindowsApps directory.
  /// When true, skip all Inno Setup update logic — Store handles updates.
  static bool get isMsixInstall {
    if (kIsWeb) return false;
    try {
      final exePath = Platform.resolvedExecutable;
      return exePath.contains('WindowsApps');
    } catch (_) {
      return false;
    }
  }

  // ─── Directory & marker helpers ──────────────────────────────

  /// Persistent update directory: %LOCALAPPDATA%/LiteRetail/updates/
  static Future<Directory> _updateDir() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory('${appSupport.path}\\updates');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<File> _markerFile() async {
    final dir = await _updateDir();
    return File('${dir.path}\\pending_update.json');
  }

  // ─── Marker read/write with attempt tracking ─────────────────

  /// Read current marker data (returns null if no marker)
  static Future<Map<String, dynamic>?> _readMarker() async {
    final marker = await _markerFile();
    if (!marker.existsSync()) return null;
    try {
      return jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Write marker with all tracking fields
  static Future<void> _writeMarker({
    required String installerPath,
    required String version,
    required int buildNumber,
    int silentAttempts = 0,
    bool dialogDismissed = false,
  }) async {
    final marker = await _markerFile();
    await marker.writeAsString(
      jsonEncode({
        'installerPath': installerPath,
        'version': version,
        'buildNumber': buildNumber,
        'downloadedAt': DateTime.now().toIso8601String(),
        'silentAttempts': silentAttempts,
        'dialogDismissed': dialogDismissed,
      }),
    );
  }

  /// Increment the silent attempt counter in the marker
  static Future<int> _incrementSilentAttempts() async {
    final data = await _readMarker();
    if (data == null) return 0;

    final attempts = ((data['silentAttempts'] as int?) ?? 0) + 1;
    data['silentAttempts'] = attempts;

    final marker = await _markerFile();
    await marker.writeAsString(jsonEncode(data));

    debugPrint('🔄 Silent update attempt count: $attempts');
    return attempts;
  }

  /// Mark that user dismissed the update dialog
  static Future<void> markDialogDismissed() async {
    final data = await _readMarker();
    if (data == null) return;

    data['dialogDismissed'] = true;
    final marker = await _markerFile();
    await marker.writeAsString(jsonEncode(data));
  }

  // ─── Public API ──────────────────────────────────────────────

  /// Get current update layer — UI uses this to decide what to show
  static Future<UpdateLayer> getUpdateLayer() async {
    if (kIsWeb || !Platform.isWindows) return UpdateLayer.upToDate;
    if (isMsixInstall) return UpdateLayer.upToDate; // Store handles updates

    final data = await _readMarker();
    if (data == null) return UpdateLayer.upToDate;

    // Check if we're already at or above the staged version
    final stagedBuild = data['buildNumber'] as int;
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    if (currentBuild >= stagedBuild) {
      // Already updated — clean up
      await _cleanupUpdateFiles(
        await _markerFile(),
        data['installerPath'] as String,
      );
      return UpdateLayer.upToDate;
    }

    final silentAttempts = (data['silentAttempts'] as int?) ?? 0;

    if (silentAttempts >= _maxSilentAttempts) {
      return UpdateLayer.showDialog;
    }

    return UpdateLayer.silentInProgress;
  }

  /// Check if update dialog should be shown (Layer 4)
  static Future<bool> shouldShowDialog() async {
    final layer = await getUpdateLayer();
    return layer == UpdateLayer.showDialog;
  }

  /// Get the cached version info from marker (for UpdateDialog)
  static Future<AppVersionInfo?> getCachedVersionInfo() async {
    final data = await _readMarker();
    if (data == null) return null;

    // We need to re-fetch from remote for download URL
    final result = await checkForUpdate();
    return result.versionInfo;
  }

  /// Master update entry point — call once from main.dart.
  /// Handles the entire lifecycle: pending → version check → download → escalation.
  static Future<void> runBackgroundUpdateCheck() async {
    if (kIsWeb) return;
    if (!Platform.isWindows) return;
    if (isMsixInstall) return; // Store handles updates

    try {
      // ── Layer 2: Check if a previous download is pending ──
      final installed = await _installPendingIfNeeded();
      if (installed) return; // app will exit — installer is running

      // ── Check remote for a new version ──
      final result = await checkForUpdate();
      if (result.status != UpdateStatus.updateAvailable) return;

      // ── Check attempt count → decide layer ──
      final data = await _readMarker();
      final silentAttempts = (data?['silentAttempts'] as int?) ?? 0;

      if (silentAttempts >= _maxSilentAttempts) {
        // Layer 4: Don't try silent anymore — UI will show dialog
        debugPrint(
          '⚠️ Silent update failed $silentAttempts times — escalating to dialog',
        );
        return;
      }

      // ── Layer 1 & 3: Silent download (fresh or retry) ──
      debugPrint(
        '🔄 Silent update attempt ${silentAttempts + 1}/$_maxSilentAttempts',
      );
      await _downloadAndStage(
        result.versionInfo!,
        silentAttempts: silentAttempts,
      );
    } catch (e) {
      debugPrint('⚠️ Background update check failed (non-fatal): $e');

      // Increment attempt counter on failure
      await _incrementSilentAttempts();
    }
  }

  /// Check if an update is available
  static Future<UpdateCheckResult> checkForUpdate() async {
    if (!Platform.isWindows || isMsixInstall) {
      return const UpdateCheckResult(status: UpdateStatus.upToDate);
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint(
        '🔄 Checking for updates... Current: v${packageInfo.version}+$currentBuild',
      );

      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('❌ Update check failed: HTTP ${response.statusCode}');
        return UpdateCheckResult(
          status: UpdateStatus.error,
          error: 'Server returned ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteVersion = AppVersionInfo.fromJson(json);

      if (remoteVersion.buildNumber > currentBuild) {
        debugPrint(
          '✅ Update available: v${remoteVersion.version}+${remoteVersion.buildNumber}',
        );
        return UpdateCheckResult(
          status: UpdateStatus.updateAvailable,
          versionInfo: remoteVersion,
        );
      }

      debugPrint('✅ App is up to date');
      return const UpdateCheckResult(status: UpdateStatus.upToDate);
    } catch (e) {
      debugPrint('❌ Update check error: $e');
      return UpdateCheckResult(status: UpdateStatus.error, error: e.toString());
    }
  }

  // ─── Public download API (used by UpdateDialog — Layer 4) ────

  /// Download and install update with progress reporting.
  /// Returns true if download succeeded and watchdog was started.
  static Future<bool> downloadAndInstall(
    AppVersionInfo info, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      await _downloadAndStage(info, onProgress: onProgress);
      return true;
    } catch (e) {
      debugPrint('❌ Download and install failed: $e');
      return false;
    }
  }

  // ─── Background download + watchdog ──────────────────────────

  /// Download installer to persistent directory, write marker, start watchdog.
  static Future<void> _downloadAndStage(
    AppVersionInfo info, {
    void Function(double progress)? onProgress,
    int silentAttempts = 0,
  }) async {
    final dir = await _updateDir();
    final installerPath = '${dir.path}\\RetailLite_Update.exe';
    final installerFile = File(installerPath);

    debugPrint('⬇️ Downloading update v${info.version} in background...');

    // Stream download
    final request = http.Request('GET', Uri.parse(info.downloadUrl));
    final streamedResponse = await request.send();
    final totalBytes = streamedResponse.contentLength ?? 0;
    var receivedBytes = 0;

    final sink = installerFile.openWrite();
    await for (final chunk in streamedResponse.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        final progress = receivedBytes / totalBytes;
        final pct = (progress * 100).toInt();
        if (pct % 25 == 0) debugPrint('   ⬇️ Download: $pct%');
        onProgress?.call(progress);
      }
    }
    await sink.close();

    debugPrint(
      '✅ Update downloaded: $installerPath (${installerFile.lengthSync()} bytes)',
    );

    // Write pending-update marker with attempt tracking
    await _writeMarker(
      installerPath: installerPath,
      version: info.version,
      buildNumber: info.buildNumber,
      silentAttempts: silentAttempts,
    );

    // Start watchdog — it monitors our PID, installs after we exit
    await _startWatchdog(installerPath);
    debugPrint('👀 Watchdog started — update will install when app closes');
  }

  /// Creates and launches a background .bat script that:
  ///   - Polls every 3 s until this process (PID) exits
  ///   - Times out after 2 hours (safety)
  ///   - Runs the Inno Setup installer /VERYSILENT
  ///   - Cleans up its own files
  static Future<void> _startWatchdog(String installerPath) async {
    final dir = await _updateDir();
    final batPath = '${dir.path}\\update_watchdog.bat';
    final markerPath = (await _markerFile()).path;
    final appPid = pid; // current Dart process PID

    // Escape backslashes for batch
    final escapedInstaller = installerPath.replaceAll('/', '\\');
    final escapedMarker = markerPath.replaceAll('/', '\\');
    final escapedBat = batPath.replaceAll('/', '\\');

    final script =
        '''@echo off
setlocal
set COUNTER=0

:wait
if %COUNTER% GEQ 2400 goto timeout
tasklist /FI "PID eq $appPid" /FI "IMAGENAME eq retaillite.exe" 2>NUL | find /I "$appPid" >NUL
if "%ERRORLEVEL%"=="0" (
  set /a COUNTER+=1
  timeout /t 3 /nobreak >NUL
  goto wait
)

rem Process exited — wait a moment for file handles to release
timeout /t 2 /nobreak >NUL

rem Run installer silently
start "" "$escapedInstaller" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
goto cleanup

:timeout
rem Watchdog timed out — increment failure counter via a flag file
echo timeout > "${dir.path}\\watchdog_timeout.flag"

:cleanup
timeout /t 5 /nobreak >NUL
del "$escapedMarker" 2>NUL
del "$escapedBat" 2>NUL
endlocal
exit
''';

    await File(batPath).writeAsString(script);

    // Launch watchdog detached — it runs independently of this process
    await Process.start('cmd.exe', [
      '/c',
      batPath,
    ], mode: ProcessStartMode.detached);
  }

  // ─── Pending update fallback (Layer 2 — runs on next app start) ──

  /// If a previous download exists but wasn't installed (watchdog failed,
  /// system restarted, etc.), install it now. Returns true if installing.
  static Future<bool> _installPendingIfNeeded() async {
    final marker = await _markerFile();
    if (!marker.existsSync()) return false;

    try {
      final data =
          jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
      final installerPath = data['installerPath'] as String;
      final stagedBuild = data['buildNumber'] as int;
      final silentAttempts = (data['silentAttempts'] as int?) ?? 0;

      // Compare with current build — if we're already at or above the staged
      // version, the update was applied successfully → clean up.
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (currentBuild >= stagedBuild) {
        debugPrint(
          '✅ Pending update v${data['version']} already applied — cleaning up',
        );
        await _cleanupUpdateFiles(marker, installerPath);
        return false;
      }

      // Check for watchdog timeout flag → increment silent attempts
      final dir = await _updateDir();
      final timeoutFlag = File('${dir.path}\\watchdog_timeout.flag');
      if (timeoutFlag.existsSync()) {
        await timeoutFlag.delete();
        final newAttempts = silentAttempts + 1;
        debugPrint(
          '⚠️ Watchdog timed out — silent attempt $newAttempts/$_maxSilentAttempts',
        );

        // Update the marker with incremented attempt count
        data['silentAttempts'] = newAttempts;
        await marker.writeAsString(jsonEncode(data));

        if (newAttempts >= _maxSilentAttempts) {
          debugPrint('⚠️ Escalating to Layer 4 (dialog)');
          return false; // Don't auto-install; let UI handle it
        }
      }

      // Installer exists but update wasn't applied — run it now
      final installer = File(installerPath);
      if (!installer.existsSync()) {
        debugPrint('⚠️ Staged installer missing — incrementing attempt count');
        await _incrementSilentAttempts();
        return false;
      }

      // Layer 2: Install pending update
      debugPrint(
        '🔄 Pending update found — installing v${data['version']} now...',
      );
      await Process.start(installerPath, [
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        '/CLOSEAPPLICATIONS',
        '/RESTARTAPPLICATIONS',
      ], mode: ProcessStartMode.detached);

      // Exit so installer can replace files — app will restart automatically
      exit(0);
    } catch (e) {
      debugPrint('⚠️ Pending update check failed: $e');
      return false;
    }
  }

  /// Remove downloaded installer and marker file
  static Future<void> _cleanupUpdateFiles(
    File marker,
    String installerPath,
  ) async {
    try {
      await marker.delete();
    } catch (e) {
      debugPrint('⚠️ Cleanup: marker delete failed: $e');
    }
    try {
      final installer = File(installerPath);
      if (installer.existsSync()) await installer.delete();
    } catch (e) {
      debugPrint('⚠️ Cleanup: installer delete failed: $e');
    }
    // Delete any leftover watchdog/flag files
    try {
      final dir = await _updateDir();
      final bat = File('${dir.path}\\update_watchdog.bat');
      if (bat.existsSync()) await bat.delete();
      final flag = File('${dir.path}\\watchdog_timeout.flag');
      if (flag.existsSync()) await flag.delete();
    } catch (e) {
      debugPrint('⚠️ Cleanup: watchdog files delete failed: $e');
    }
  }

  /// Clean up all update files (for manual reset)
  static Future<void> cleanupAll() async {
    final marker = await _markerFile();
    final data = await _readMarker();
    final installerPath =
        data?['installerPath'] as String? ?? 'nonexistent.exe';
    await _cleanupUpdateFiles(marker, installerPath);
  }
}
