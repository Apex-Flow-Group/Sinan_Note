# Sinan Note ProGuard Rules (Optimized for R8)
# ══════════════════════════════════════════════════════════════════════
# هدف: رفع نسب Shrinking/Obfuscation/Optimization من ~35% إلى 60%+
# القاعدة: لا تحمي إلا ما يُستدعى بالـ Reflection أو من الأندرويد مباشرة
# ══════════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════════
# App — MainActivity + Widgets (مطلوبة لأن AndroidManifest يشير لها)
# ══════════════════════════════════════════════════════════════════════
-keep class com.apexflow.app.sinan.MainActivity { *; }
-keep class com.apexflow.app.sinan.widget.** { *; }

# ══════════════════════════════════════════════════════════════════════
# Flutter Engine — الحد الأدنى المطلوب
# ══════════════════════════════════════════════════════════════════════
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.android.FlutterFragmentActivity { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-dontwarn io.flutter.**

# ══════════════════════════════════════════════════════════════════════
# Plugins — فقط الكلاسات اللي تُسجّل عبر Reflection
# ══════════════════════════════════════════════════════════════════════

# Isar Database (JNI)
-keep class io.isar.** { *; }
-dontwarn io.isar.**

# SQLite (للترحيل — يمكن إزالته بعد انتهاء الترحيل)
-keep class com.tekartik.sqflite.SqflitePlugin { *; }
-dontwarn com.tekartik.sqflite.**
-dontwarn org.sqlite.**

# Google Sign In — فقط Auth
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-dontwarn com.google.android.gms.**

# Local Auth (Biometric) — الـ Fragment فقط
-keep class androidx.biometric.BiometricPrompt { *; }
-keep class androidx.biometric.BiometricManager { *; }

# Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Home Widget
-keep class es.antonborri.home_widget.HomeWidgetPlugin { *; }
-keep class es.antonborri.home_widget.HomeWidgetProvider { *; }

# ══════════════════════════════════════════════════════════════════════
# AndroidX — فقط ما يُستدعى بالـ Reflection
# ══════════════════════════════════════════════════════════════════════
-keep class androidx.work.impl.WorkManagerInitializer { *; }
-keep class androidx.startup.InitializationProvider { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# Room — إذا لا تستخدم Room مباشرة يمكن حذف هذه
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class * { *; }
-keep @androidx.room.Dao interface * { *; }

# ══════════════════════════════════════════════════════════════════════
# Play Core
# ══════════════════════════════════════════════════════════════════════
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-dontwarn com.google.android.play.core.**

# ══════════════════════════════════════════════════════════════════════
# Debugging — يمكن إزالته في المستقبل لزيادة Obfuscation
# ══════════════════════════════════════════════════════════════════════
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
