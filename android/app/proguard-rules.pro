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

# SQLite (للترحيل)
-keep class com.tekartik.sqflite.** { *; }
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-dontwarn com.tekartik.sqflite.**
-dontwarn org.sqlite.**

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

# Play Core (للمكونات المؤجلة)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
