# Keep Gson classes
-keep class com.google.gson.** { *; }
-keep interface com.google.gson.** { *; }

# Keep Gson internal classes - Fix untuk DateTypeAdapter error
-keep class com.google.gson.internal.** { *; }
-keep class com.google.gson.internal.bind.** { *; }
-keep class com.google.gson.internal.bind.DateTypeAdapter { *; }
-keep class com.google.gson.internal.bind.TypeAdapters { *; }
-keep class com.google.gson.internal.bind.TypeAdapters$* { *; }

# Gson TypeAdapter
-keepclassmembers class * implements com.google.gson.TypeAdapter {
    <init>(...);
}

# Gson annotations
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Keep generic signature
-keep class sun.misc.Unsafe { *; }
-dontwarn sun.misc.**

# Application classes that will be serialized/deserialized over Gson
-keep class com.google.gson.examples.android.model.** { <fields>; }

# Prevent proguard from stripping interface information
-keepattributes InnerClasses

-dontwarn retrofit2.**
-dontwarn org.codehaus.mojo.**
-keep class retrofit2.** { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep all native methods
-keepclassmembers class * {
    native <methods>;
}

# TAMBAHKAN INI - Google Play Core (Fix untuk SplitCompat error)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Split Compat
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter Play Store Split
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }