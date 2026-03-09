# Retrofit — 只保留必要介面與註解，允許 R8 移除未使用程式碼
-keepattributes Signature
-keepattributes Exceptions
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations
-keep,allowshrinking,allowoptimization class retrofit2.** { *; }
-keep interface com.vegettable.app.network.ApiService { *; }
-dontwarn retrofit2.**

# Gson — 保留 Model 欄位名稱（反序列化需要）
-keep class com.vegettable.app.model.** {
    <fields>;
    <init>();
}
-keepclassmembers class com.vegettable.app.model.** {
    <fields>;
}
-dontwarn com.google.gson.**

# OkHttp — 只保留核心
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.internal.publicsuffix.PublicSuffixDatabase { *; }

# Glide
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule { <init>(...); }

# MPAndroidChart
-keep class com.github.mikephil.charting.** { *; }

# 移除 Log 呼叫 (release)
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
