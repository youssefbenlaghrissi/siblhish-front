# Keep Flutter engine and plugins (generally handled by default, but safe)
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Firebase / Google Play services (avoid stripping)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin metadata
-keep class kotlin.Metadata { *; }

