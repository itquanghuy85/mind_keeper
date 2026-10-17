# google_mlkit_text_recognition tham chiếu các gói ngôn ngữ ML Kit tùy chọn
# (chinese/devanagari/japanese/korean) không được kéo vào dependencies.
# R8 báo "missing classes" cho các lớp này — bỏ cảnh báo để release build qua.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
