# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in getDefaultProguardFile('proguard-android.txt').
# You can edit the include path and syntax by changing the proguardFiles
# directive in build.gradle.

# Flutter specific rules (usually handled automatically by the Flutter Gradle plugin)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve Supabase / Postgrest classes if needed (already handled by their own consumer rules usually)
-keep class com.supabase.** { *; }

# Google Play Core rules
-keep class com.google.android.play.core.** { *; }

