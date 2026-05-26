# Flutter ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep geolocator plugin (R8 strips shared library JNI classes)
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Keep other plugins that use platform channels
-keep class com.baseflow.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn com.baseflow.**
