# ProGuard & R8 Obfuscation Rules for Nabd AppSec

# Preserve Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# SQLCipher / SQLite native interfaces
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }

# Security & Biometrics
-keep class androidx.biometric.** { *; }

# Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
