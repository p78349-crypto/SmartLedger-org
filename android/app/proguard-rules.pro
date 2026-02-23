## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## 🔒 AI 규제 준수로 제외: Google ML Kit (AI/ML 라이브러리)
## Google ML Kit - 18개국 AI 규제 준수로 비활성화
# -keep class com.google.mlkit.** { *; }
# -keep class com.google.android.gms.** { *; }
# -dontwarn com.google.mlkit.**
# -dontwarn com.google.android.gms.**

## 🔒 AI 규제 준수로 제외: ML Kit Text Recognition (OCR AI)
## ML Kit Text Recognition - AI 기능으로 비활성화
# -keep class com.google.mlkit.vision.text.** { *; }
# -keep class com.google.mlkit.vision.text.chinese.** { *; }
# -keep class com.google.mlkit.vision.text.devanagari.** { *; }
# -keep class com.google.mlkit.vision.text.japanese.** { *; }
# -keep class com.google.mlkit.vision.text.korean.** { *; }

## 📦 앱 크기 최적화: 사용하지 않는 리소스 적극 제거
-dontshrink
-dontoptimize
-keepattributes Signature
-keepattributes *Annotation*

## Ignore missing classes for Play Store Split Install (used by Flutter deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

## Ignore missing classes for Apache Tika (used by some Flutter plugins)
-dontwarn javax.xml.stream.**
-dontwarn org.apache.tika.**
