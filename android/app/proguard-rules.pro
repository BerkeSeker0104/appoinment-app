# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# ============================================
# Application & MainActivity - CRITICAL
# ============================================
-keep class com.mw.barbershop.** { *; }
-keep class com.mw.barbershop.dev.** { *; }
-keep class com.mw.barbershop.MainActivity { *; }
-keep class * extends android.app.Application { *; }
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }
-keep class * extends io.flutter.embedding.android.FlutterFragmentActivity { *; }

# ============================================
# Flutter specific rules
# ============================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }
-dontwarn io.flutter.**

# ============================================
# Google Maps & Location Services
# ============================================
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.libraries.places.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.libraries.places.**

# ============================================
# HTTP Client (Dio/OkHttp)
# ============================================
-keep class dio.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ============================================
# JSON Serialization
# ============================================
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ============================================
# Native Methods & JNI
# ============================================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================
# Serializable & Model Classes
# ============================================
-keep class * extends java.lang.Enum { *; }
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================
# Exception Classes
# ============================================
-keep class * extends java.lang.Exception

# ============================================
# Kotlin Coroutines
# ============================================
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.** {
    volatile <fields>;
}
-keepclassmembers class kotlin.coroutines.SafeContinuation {
    volatile <fields>;
}

# ============================================
# Google Play Core
# ============================================
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ============================================
# Enum Classes
# ============================================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================
# Remove Logging in Release Builds
# ============================================
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# ============================================
# Performance Optimizations (Less Aggressive)
# ============================================
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Optimization settings - safer options
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

# Remove debug information but keep source file names for stack traces
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Remove verbose logging
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    static void checkNotNull(java.lang.Object);
    static void checkNotNull(java.lang.Object, java.lang.String);
    static void checkParameterIsNotNull(java.lang.Object, java.lang.String);
    static void checkReturnedValueIsNotNull(java.lang.Object, java.lang.String);
}

# ============================================
# Flutter Plugins - Shared Preferences, Path Provider, etc.
# ============================================
-keep class androidx.preference.** { *; }
-keep class androidx.security.crypto.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-dontwarn androidx.preference.**
-dontwarn androidx.security.crypto.**

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Geolocator & Geocoding
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }

# Cached Network Image
-keep class flutter.plugins.cachednetworkimage.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# ============================================
# Kotlin Reflection & Metadata
# ============================================
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Kotlin classes
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class * extends kotlin.coroutines.CoroutineImpl {
    <methods>;
}

# ============================================
# WebView (if used)
# ============================================
# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}