# Sinan Note ProGuard Rules
# Add project specific ProGuard rules here.

# ══════════════════════════════════════════════════════════════════════
# App Native Classes — MUST KEEP (MainActivity, Widgets)
# ══════════════════════════════════════════════════════════════════════
-keep class com.apexflow.app.sinan.** { *; }

# Flutter Embedding — required for AGP 9
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

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

# AndroidX WorkManager + Room (required for R8 with AGP 9)
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class * { *; }
-keep @androidx.room.Dao class * { *; }
-dontwarn androidx.room.**

# AndroidX Startup
-keep class androidx.startup.** { *; }

# Play Core (للمكونات المؤجلة)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
