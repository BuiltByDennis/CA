# ML Kit text recognition (Phase 2 OCR): the plugin references recognizers
# for scripts whose models are separate artifacts this app does not bundle
# (CA uses the Latin script only). Without these, R8 fails the release build
# with "Missing classes detected" for exactly these four packages.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
