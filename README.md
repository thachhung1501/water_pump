=========================================================
                PROJECT: WATERPUMP 
        Hệ Thống Điều Khiển Bơm Thông Minh
=========================================================

1. GIỚI THIỆU
WaterPump là ứng dụng di động đa nền tảng (Android & iOS) được 
phát triển bằng Flutter. Ứng dụng cho phép người dùng giám sát 
và điều khiển hệ thống máy bơm nước từ xa thông qua giao diện 
trực quan, giúp tối ưu hóa việc tưới tiêu và quản lý tài nguyên nước.

2. CÁC TÍNH NĂNG CHÍNH
* Điều khiển Bật/Tắt máy bơm thời gian thực qua Internet/Bluetooth.
* Chế độ tự động: Hẹn giờ tưới hoặc thiết lập điều kiện (độ ẩm, nhiệt độ).
* Giám sát trạng thái: Hiển thị lưu lượng nước và tình trạng hoạt động.
* Thông báo: Cảnh báo khi có sự cố (quá tải, mất nước, rò rỉ).
* Giao diện Dark Mode/Light Mode hiện đại, dễ sử dụng.

3. YÊU CẦU HỆ THỐNG
* Flutter SDK: v3.0.0 trở lên.
* Dart SDK: v2.17.0 trở lên.
* Thiết bị đầu cuối: ESP32/Arduino hoặc thiết bị IOT tương thích.
* Công cụ: Android Studio hoặc VS Code (đã cài Flutter Plugin).

4. HƯỚNG DẪN CÀI ĐẶT

   Bước 1: Tải mã nguồn về máy:
   git clone https://github.com/your-username/WaterPump.git

   Bước 2: Truy cập vào thư mục dự án:
   cd WaterPump

   Bước 3: Tải các thư viện cần thiết:
   flutter pub get

   Bước 4: Chạy ứng dụng:
   flutter run

5. CẤU TRÚC DỰ ÁN (SƠ LƯỢC)
* lib/core: Cấu hình MQTT/Firebase, hằng số và các tiện ích kết nối.
* lib/data: Quản lý dữ liệu, Repository, API kết nối thiết bị.
* lib/logic: Quản lý trạng thái ứng dụng (Provider/Bloc).
* lib/presentation: Chứa màn hình điều khiển, biểu đồ và widget.
* lib/main.dart: Điểm khởi chạy ứng dụng.

6. TÀI LIỆU THAM KHẢO
* Tài liệu Flutter chính thức: https://docs.flutter.dev/
* Tài liệu giao thức kết nối (MQTT/HTTP): https://mqtt.org/
* Flutter Cookbook: https://docs.flutter.dev/cookbook

---------------------------------------------------------
© 2026 Project by HungThach. All rights reserved.
=========================================================
