# Datei: android/app/proguard-rules.pro
# Nur nötig für Release-Builds (flutter build apk / appbundle).
# ML Kit bringt optionale Sprachmodule mit, die wir nicht nutzen –
# ohne diese Zeilen bricht der Release-Build mit "Missing classes" ab.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
