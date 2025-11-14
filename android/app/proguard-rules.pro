# Add project specific ProGuard rules here.

# AndroidX Window - These are optional extension classes that may not be available
# Suppress warnings for missing optional window extension classes
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.extensions.WindowExtensions
-dontwarn androidx.window.extensions.WindowExtensionsProvider
-dontwarn androidx.window.extensions.area.ExtensionWindowAreaPresentation
-dontwarn androidx.window.extensions.layout.DisplayFeature
-dontwarn androidx.window.extensions.layout.FoldingFeature
-dontwarn androidx.window.extensions.layout.WindowLayoutComponent
-dontwarn androidx.window.extensions.layout.WindowLayoutInfo

# Suppress warnings for missing optional sidecar classes
-dontwarn androidx.window.sidecar.**
-dontwarn androidx.window.sidecar.SidecarDeviceState
-dontwarn androidx.window.sidecar.SidecarDisplayFeature
-dontwarn androidx.window.sidecar.SidecarInterface
-dontwarn androidx.window.sidecar.SidecarInterface$SidecarCallback
-dontwarn androidx.window.sidecar.SidecarProvider
-dontwarn androidx.window.sidecar.SidecarWindowLayoutInfo

# Keep core AndroidX Window classes that are actually used
-keep class androidx.window.core.** { *; }
-keep class androidx.window.layout.** { *; }

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.**  { *; }

# Keep all Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }

# Keep MethodChannel and PlatformChannel classes
-keep class * extends io.flutter.plugin.common.MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.BinaryMessenger { *; }
-keep class * implements io.flutter.embedding.engine.plugins.PluginRegistry { *; }

# Keep Dart runtime classes
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.engine.dart.** { *; }

# Flutter deferred components (Play Core is optional)
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Firebase Firestore - Critical for release builds
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**

# gRPC - Required for Firestore (fixes ExceptionInInitializerError)
-keep class io.grpc.** { *; }
-keep class io.grpc.okhttp.** { *; }
-keep class io.grpc.netty.** { *; }
-keepclassmembers class io.grpc.** { *; }
-keepclassmembers enum io.grpc.** { *; }
-dontwarn io.grpc.**
-dontwarn io.grpc.okhttp.**
-dontwarn io.grpc.netty.**

# gRPC TLS Channel Credentials - Fix for NoSuchMethodException: values []
-keep class io.grpc.TlsChannelCredentials { *; }
-keep class io.grpc.TlsChannelCredentials$Feature { *; }
-keepclassmembers enum io.grpc.TlsChannelCredentials$Feature {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-keepclassmembers class io.grpc.TlsChannelCredentials$Feature { *; }

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Play Core - Optional classes for deferred components (may not be available)
# These classes are only needed for Flutter's deferred components feature, which this app doesn't use
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Suppress all warnings for optional Play Core classes (deferred components not used)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep line numbers for stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep SharedPreferences classes
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$** { *; }
-keepclassmembers class * implements android.content.SharedPreferences {
    *;
}

# Keep Provider classes
-keep class provider.** { *; }
-keep class * extends provider.ChangeNotifier { *; }
-keep class * implements provider.ChangeNotifier { *; }

# Keep SharedPreferences plugin classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# Keep SharedPreferences specifically
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Keep FlutterSecureStorage plugin classes
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class io.flutter.plugins.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**
-dontwarn io.flutter.plugins.fluttersecurestorage.**

# Keep PIN code fields plugin
-keep class com.joecode.pin_code_fields.** { *; }
-dontwarn com.joecode.pin_code_fields.**

# Keep HTTP client classes
-keep class io.flutter.plugins.connectivity.** { *; }
-dontwarn io.flutter.plugins.connectivity.**

# Keep all model classes (for JSON serialization)
-keep class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep classes used by reflection (Provider, SharedPreferences)
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes *Annotation*

# Keep JSON serialization classes
-keep class * extends java.util.List { *; }
-keep class * extends java.util.Map { *; }

# Keep your application class
-keep class com.example.healthymamaapp.** { *; }

