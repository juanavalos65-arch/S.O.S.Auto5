# ==============================================================================
# S.O.S. Auto - Rules for ProGuard & R8 Obfuscation & Security
# Archivo: android/app/proguard-rules.pro
# ==============================================================================

# 1. Reglas Generales de Optimización y Ofuscación
# ------------------------------------------------------------------------------
-repackageclasses ''
-allowaccessmodification
-dontusemixedcaseclassnames
-dontpreverify
-verbose

# Conservar atributos esenciales de depuración y reflexión
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions,SourceFile,LineNumberTable

# 2. Protección y Conservación de Componentes Clave de la Aplicación
# ------------------------------------------------------------------------------
# Evitar que R8 elimine o altere los modelos de datos y paquetes principales
-keep class com.sosauto.app.** { *; }
-keep interface com.sosauto.app.** { *; }

# Conservar las clases generadas por la compilación nativa de Android
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# 3. Mantenimiento de Métodos Nativos (JNI) y Métodos View
# ------------------------------------------------------------------------------
-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# 4. Compatibilidad con Flutter y Librerías de Terceros
# ------------------------------------------------------------------------------
# Reglas estándar para aplicaciones desarrolladas con Flutter / Java / Kotlin
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Evitar advertencias durante el proceso de minificación R8
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
