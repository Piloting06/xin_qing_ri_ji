# Flutter ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep all Flutter plugin classes (prevent R8 from stripping platform channel code)
-keep class com.baseflow.** { *; }
-keep class com.baseflow.geolocator.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-dontwarn com.baseflow.**

# Keep data classes that might be serialized/deserialized
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep Android lifecycle components
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**
