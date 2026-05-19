# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SQLite / sqflite
-keep class com.tekartik.sqflite.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Play Core (Flutter deferred components — keep to avoid R8 missing class errors)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# OruShops Custom Application Classes & Main Activity
-keep class com.orushops.orushops.** { *; }
