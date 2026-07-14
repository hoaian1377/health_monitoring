# Hướng dẫn Cài đặt và Chạy ứng dụng Health Monitoring

Hệ thống Health Monitoring bao gồm 2 thành phần chính:
1. **Backend**: Python (Django REST Framework)
2. **Frontend App**: Flutter
3. **Cơ sở dữ liệu**: SQL Server

---

## 1. Yêu cầu hệ thống
Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã cài đặt các phần mềm sau:
- **Python** (phiên bản 3.9 trở lên)
- **Flutter SDK** (phiên bản 3.x)
- **Microsoft SQL Server** (cùng với SQL Server Management Studio - SSMS)
- **Trình soạn thảo mã** (như VS Code hoặc Android Studio)

---

## 2. Thiết lập Cơ sở dữ liệu (SQL Server)
Hệ thống sử dụng cơ sở dữ liệu `Health_monitoring`. Bạn cần import file CSDL gốc vào máy.

1. Mở **SQL Server Management Studio (SSMS)** và kết nối tới server `localhost` (Windows Authentication).
2. Tạo database mới hoặc chạy trực tiếp file export:
   - Mở file `Health_monitoring_database.sql` (nằm trong thư mục gốc dự án) bằng SSMS.
   - Nhấn **Execute (F5)** để chạy toàn bộ script.
   - Script này sẽ tự động tạo database `Health_monitoring`, tạo các bảng, khóa ngoại, cấu hình cần thiết và chèn sẵn dữ liệu mẫu.

---

## 3. Thiết lập Backend (Django)

1. Mở Terminal / Command Prompt và di chuyển vào thư mục `backend`:
   ```bash
   cd backend
   ```

2. Tạo môi trường ảo (Virtual Environment) và kích hoạt nó:
   ```bash
   python -m venv venv
   
   # Kích hoạt trên Windows:
   venv\Scripts\activate
   ```

3. Cài đặt các thư viện cần thiết:
   ```bash
   pip install -r requirements.txt
   ```
   *(Nếu dự án chưa có file `requirements.txt`, hãy đảm bảo cài đặt các package chính như `django`, `djangorestframework`, `django-cors-headers`, `pyodbc`, `pillow`...)*

4. Kiểm tra cấu hình kết nối CSDL trong file `backend/settings.py` (khu vực `DATABASES`). Mặc định đã được cấu hình kết nối tới `Health_monitoring` qua `mssql` (Windows Authentication).

5. Chạy server backend:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```
   Backend sẽ chạy tại địa chỉ: `http://localhost:8000/` hoặc IP máy tính của bạn.

---

## 4. Thiết lập Frontend App (Flutter)

1. Mở một Terminal / Command Prompt mới và di chuyển vào thư mục `health_monitoring_app`:
   ```bash
   cd health_monitoring_app
   ```

2. Tải các package Flutter:
   ```bash
   flutter pub get
   ```

3. **Cấu hình địa chỉ IP máy chủ API**:
   - Nếu bạn chạy app trên **Máy ảo Android (Emulator)** hoặc **Thiết bị thật**, IP `localhost` sẽ không hoạt động.
   - Mở Command Prompt, gõ `ipconfig` để lấy địa chỉ **IPv4** của máy tính (ví dụ: `192.168.1.10`).
   - Mở file `lib/utils/api_service.dart` (hoặc nơi chứa base URL) và thay đổi địa chỉ IP thành IP của bạn:
     ```dart
     const String baseUrl = 'http://192.168.1.10:8000'; 
     // Thay bằng IP của bạn, giữ nguyên cổng 8000
     ```

4. Chạy ứng dụng:
   - Kết nối điện thoại hoặc bật máy ảo.
   - Chạy lệnh:
     ```bash
     flutter run
     ```

---
Nếu gặp lỗi liên quan đến kết nối cơ sở dữ liệu `pyodbc`, hãy đảm bảo bạn đã cài đặt **ODBC Driver 17 for SQL Server** trên máy tính Windows.
