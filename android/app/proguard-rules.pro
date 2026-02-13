# Flutter ProGuard Rules for RetailLite
# ───────────────────────────────────────

# Keep Flutter engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Razorpay
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/*

# Prevent obfuscation of model classes used with Gson/serialization
-keepattributes Signature
-keepattributes *Annotation*

# Bluetooth thermal printing
-dontwarn print_bluetooth_thermal.**
-keep class print_bluetooth_thermal.** { *; }

# Mobile scanner (barcode)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Google Play Core (deferred components / split install)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# General Android
-dontwarn android.**
-keep class android.** { *; }
