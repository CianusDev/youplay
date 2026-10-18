# NewPipeExtractor : réflexion + moteur JavaScript Rhino (déchiffrement des signatures).
-keep class org.schabi.newpipe.extractor.** { *; }
-keep class org.mozilla.javascript.** { *; }
-keep class org.mozilla.classfile.** { *; }
-keep class com.grack.nanojson.** { *; }
-dontwarn org.mozilla.javascript.**
-dontwarn org.mozilla.classfile.**
-dontwarn java.beans.**
-dontwarn javax.script.**
-dontwarn jdk.dynalink.**
-dontwarn com.google.re2j.**
-dontwarn org.jsoup.**
-keep class org.jsoup.** { *; }

# Lecture en arrière-plan : service audio + notification média (audio_service / just_audio).
-keep class com.ryanheise.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }
-keep class android.support.v4.media.** { *; }
-dontwarn com.ryanheise.**
