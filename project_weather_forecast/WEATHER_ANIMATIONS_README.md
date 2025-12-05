# 🌦️ Weather Animations Guide

## Tổng quan

Ứng dụng có hệ thống animated weather effects động, tự động thay đổi theo điều kiện thời tiết thực tế!

## ✨ Các hiệu ứng có sẵn

### 1. ☀️ **Sunny (Nắng)**
- **Background**: Gradient xanh dương sáng (blue → sky blue → golden yellow)
- **Effects**:
  - Animated sun rays (tia nắng xoay 360°)
  - Sun circle với glow effect
  - Vài đám mây nhẹ trong suốt
- **Trigger**: weatherMain = "Clear" hoặc "Sunny"

### 2. 🌧️ **Rainy (Mưa)**
- **Background**: Gradient xám xanh đậm (dark blue-gray)
- **Effects**:
  - Animated rain drops rơi xuống
  - Mây xám dày đặc
  - Intensity: 7/10 (mưa vừa)
- **Trigger**: weatherMain = "Rain" hoặc "Drizzle"

### 3. ⚡ **Thunderstorm (Dông)**
- **Background**: Gradient đen xanh rất tối (very dark blue → deep blue)
- **Effects**:
  - Heavy rain (intensity 10/10)
  - Mây đen dày đặc
  - **Lightning effect** - Sấm chớp ngẫu nhiên mỗi 3-8 giây
  - Flash màn hình trắng khi sấm
- **Trigger**: weatherMain = "Thunder" hoặc "Storm"

### 4. ❄️ **Snowy (Tuyết)**
- **Background**: Gradient xanh nhạt pastel (light steel blue → pale blue)
- **Effects**:
  - Animated snowflakes rơi chậm
  - Tuyết có swing motion (dao động qua lại)
  - Mây xám nhạt
- **Trigger**: weatherMain = "Snow"

### 5. ☁️ **Cloudy (Nhiều mây)**
- **Background**: Gradient xám xanh (gray-blue)
- **Effects**:
  - 5 layers của animated clouds
  - Mây di chuyển ngang màn hình
  - Không có mưa/tuyết
- **Trigger**: weatherMain = "Cloud" hoặc "Clouds"

### 6. 🌫️ **Foggy (Sương mù)**
- **Background**: Gradient xám (misty gray)
- **Effects**:
  - 6 layers mây dày đặc
  - Lớp phủ trắng mờ (opacity 0.2)
  - Giảm visibility
- **Trigger**: weatherMain = "Mist", "Fog", "Haze"

### 7. 🌤️ **Clear (Quang đãng)**
- **Background**: Gradient mặc định (dark blue)
- **Effects**:
  - Vài đám mây nhẹ
  - Không có hiệu ứng đặc biệt
- **Trigger**: Mặc định cho các trường hợp khác

## 🎨 Cấu trúc Code

### File Structure
```
lib/
  widgets/
    weather_animations.dart     # Tất cả animation widgets
    weather_background.dart     # Controller chính
  screens/
    home_screen.dart           # Tích hợp vào UI
```

### Sử dụng trong code

```dart
// Trong home_screen.dart
WeatherBackground(
  weatherCondition: provider.currentWeather?.weatherMain ?? 'Clear',
  child: SafeArea(
    child: YourContent(),
  ),
)
```

## 🔧 Animation Components

### RainDrop
- Giọt mưa chuyển động từ trên xuống
- Có gradient opacity (mờ dần ở đuôi)
- Random speed, size, delay cho tự nhiên

### AnimatedCloud
- Mây di chuyển từ trái sang phải
- Vòng lặp vô hạn
- Tốc độ tùy chỉnh (20-40 giây/vòng)

### LightningEffect
- Flash ngẫu nhiên mỗi 3-8 giây
- Vẽ hình sấm (zigzag path)
- Fade out nhanh 200ms

### AnimatedSunRays
- 12 tia nắng xoay 360° liên tục
- Gradient từ vàng → cam → transparent
- Duration: 20 giây/vòng

### AnimatedSnow
- Snowflakes rơi chậm hơn rain
- Swing motion (dao động qua lại)
- Circular shape với glow

## 🎯 Tùy chỉnh

### Thay đổi intensity của mưa
```dart
AnimatedRain(intensity: 10) // 1-10
```

### Thay đổi số lượng mây
```dart
CloudsLayer(density: 5) // 1-5 layers
```

### Thay đổi màu mây
```dart
CloudsLayer(
  density: 3,
  color: Colors.grey.shade400,
)
```

## 📊 Performance

- **60 FPS** smooth animations
- Optimized với `AnimationController`
- Reusable particles (không tạo widget mới liên tục)
- Efficient layering với Stack

## 🐛 Debugging

Nếu animation không hoạt động:
1. Check `weatherMain` value từ API
2. Verify `WeatherBackground` được wrap đúng
3. Check console cho compilation errors
4. Restart app sau khi thay đổi code

## 🚀 Tính năng mở rộng

Có thể thêm:
- Wind animation (leaves flying)
- Rainbow effect sau mưa
- Stars animation cho đêm
- Dust/sand animation cho khô hanh
- Heat waves cho nhiệt độ cao

---

**Created by**: Weather Forecast App  
**Version**: 1.0.0  
**Last Updated**: November 2025
