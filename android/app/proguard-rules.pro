# ProGuard rules for mathlockv2 Android app

# Keep all classes in our main package from being obfuscated, shrunk, or optimized.
# This prevents ClassNotFoundException for MainActivity and background services.
-keep class com.danibaret014.mathlock.** { *; }

# Keep Flutter plugin registrant and plugins
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }

# Keep AndroidX core/compatibility classes
-keep class androidx.core.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.fragment.** { *; }
-keep class androidx.annotation.Keep

# Keep all implementations of MethodChannel handlers
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
}

# Ignore missing Play Core classes since we don't use deferred components
-dontwarn com.google.android.play.core.**

