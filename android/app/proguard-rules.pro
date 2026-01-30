# Sinan Note ProGuard Rules
# Add project specific ProGuard rules here.

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Isar Database
-keep class io.isar.** { *; }
-dontwarn io.isar.**

# Google Sign In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Encryption
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }

# Local Auth (Biometric)
-keep class androidx.biometric.** { *; }

# Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
