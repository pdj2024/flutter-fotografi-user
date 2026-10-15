# Keep Gson classes
-keep class com.google.gson.** { *; }
-keep interface com.google.gson.** { *; }

# Keep Gson internal classes - Fix untuk DateTypeAdapter error
-keep class com.google.gson.internal.** { *; }
-keep class com.google.gson.internal.bind.** { *; }
-keep class com.google.gson.internal.bind.DateTypeAdapter { *; }
-keep class com.google.gson.internal.bind.TypeAdapters { *; }
-keep class com.google.gson.internal.bind.TypeAdapters$* { *; }

# DateTypeAdapter tidak ada di versi Gson yang ke-resolve (dipanggil dari
# dependency lain lewat reflection) — R8 melaporkan "missing class", bukan
# "class dihapus". -keep tidak bisa menahan kelas yang memang tidak ada;
# -dontwarn cukup karena path kode ini tidak pernah benar-benar dieksekusi.
-dontwarn com.google.gson.internal.bind.DateTypeAdapter

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
# CATATAN: dulu ada blanket "-keep class io.flutter.** { *; }" dan
# "-keep class io.flutter.plugins.** { *; }" di sini. Dua baris itu dihapus
# karena mencakup SELURUH kode Flutter engine + kode Java/Kotlin semua plugin
# (io.flutter.plugins.** = tempat generated code semua plugin tinggal), jadi
# hampir seluruh DEX app jadi tidak pernah di-obfuscate R8 — inilah penyebab
# persentase Obfuscation rendah di Play Console. Flutter engine & AAR plugin
# sudah bawa consumer-proguard-rules sendiri, jadi tidak perlu di-keep manual
# di sini. Baris di bawah (native <methods>) sudah cukup untuk lindungi
# binding JNI Flutter engine.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

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