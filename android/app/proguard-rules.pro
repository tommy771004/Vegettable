# Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions
-keepattributes *Annotation*

# Gson
-dontwarn com.google.gson.**
-keep class com.google.gson.** { *; }
-keep class com.vegettable.app.model.** { *; }

# OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-dontwarn okio.**
