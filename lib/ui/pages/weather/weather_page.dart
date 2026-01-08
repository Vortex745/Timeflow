import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/weather_controller.dart';
import '../../../data/models/weather.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherController controller = Get.put(WeatherController());

  // Cache star positions to prevent flickering/moving on refresh
  final List<_StarSpec> _stars = [];

  @override
  void initState() {
    super.initState();
    _generateStars();
  }

  void _generateStars() {
    final random = Random();
    for (int i = 0; i < 50; i++) {
      _stars.add(
        _StarSpec(
          x: random.nextDouble(),
          y: random.nextDouble() * 0.6, // Top 60%
          radius: random.nextDouble() * 1.5 + 0.5,
          opacity: random.nextDouble() * 0.5 + 0.3,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final weather = controller.weatherData.value;
      // Use previous weather if loading to keep background stable, or default if null
      final displayWeather = weather;

      return Scaffold(
        body: Stack(
          children: [
            // 1. Permanent Background (Stable)
            if (displayWeather != null)
              _buildBackground(
                displayWeather.current.isDay == 1,
                displayWeather.current.weatherCode,
              )
            else
              // Default Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  ),
                ),
              ),

            // 2. Content Layer
            if (controller.isLoading.value && displayWeather == null)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (controller.errorMessage.isNotEmpty &&
                displayWeather == null)
              _buildErrorView()
            else if (displayWeather != null)
              _buildContent(context, displayWeather),
          ],
        ),
      );
    });
  }

  Widget _buildBackground(bool isDay, int code) {
    // Simple Gradient Logic
    List<Color> colors = [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];

    if (!isDay) {
      colors = [
        const Color(0xFF0F2027),
        const Color(0xFF203A43),
        const Color(0xFF2C5364),
      ];
    } else {
      if (code >= 95) {
        // Thunder
        colors = [const Color(0xFF232526), const Color(0xFF414345)];
      } else if (code >= 51) {
        // Rain/Snow
        colors = [const Color(0xFF616161), const Color(0xFF9bc5c3)];
      } else if (code >= 1 && code <= 3) {
        // Cloudy
        colors = [const Color(0xFF757F9A), const Color(0xFFD7DDE8)];
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          // Stars (Fixed positions)
          if (!isDay && (code == 0 || code == 1))
            CustomPaint(painter: StarPainter(_stars), size: Size.infinite),

          // Sun (Day only)
          if (isDay && code == 0)
            Positioned(
              top: -60.h,
              right: -60.w,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orangeAccent.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 50.sp),
          SizedBox(height: 10.h),
          Text(
            controller.errorMessage.value,
            style: const TextStyle(color: Colors.white),
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: controller.initLocationAndFetchWeather,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeatherData weather) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.initLocationAndFetchWeather,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // Header: City
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.white30),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          weather.district.isNotEmpty
                              ? "${weather.city} · ${weather.district}"
                              : weather.city,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Current Temp
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${weather.current.temperature.round()}°",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 110.sp,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          _getWeatherIcon(
                            weather.current.weatherCode,
                            weather.current.isDay == 1,
                          ),
                          color: Colors.white,
                          size: 30.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          _getWeatherDesc(weather.current.weatherCode),
                          style: TextStyle(
                            fontSize: 24.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "AQI ${weather.airQuality?.aqi.round() ?? '-'} · ${_getAqiDesc(weather.airQuality?.aqi)}",
                      style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // Hourly Forecast
            SliverToBoxAdapter(
              child: Container(
                height: 140.h,
                margin: EdgeInsets.only(bottom: 20.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: weather.hourly.length,
                  itemBuilder: (context, index) {
                    final h = weather.hourly[index];
                    final timeStr = _formatTime(h.time);
                    return Container(
                      width: 70.w,
                      margin: EdgeInsets.only(right: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Icon(
                            _getWeatherIcon(h.weatherCode, true),
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            "${h.temperature.round()}°",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Daily Forecast Title
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Text(
                  "未来5天预测",
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
              ),
            ),

            // Daily Forecast
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final d = weather.daily[index];
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(d.date),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Icon(
                          _getWeatherIcon(d.weatherCode, true),
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "${d.minTemp.round()}°",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.5),
                                    Colors.orange.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              "${d.maxTemp.round()}°",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: min(5, weather.daily.length)),
            ),

            // Indices Grid
            SliverToBoxAdapter(child: SizedBox(height: 30.h)),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16.h,
                crossAxisSpacing: 16.w,
                childAspectRatio: 1.5,
                children: [
                  _buildGridCard(
                    Icons.wb_sunny_outlined,
                    "UV指数",
                    "${weather.daily[0].uvIndex}",
                  ),
                  _buildGridCard(
                    Icons.water_drop_outlined,
                    "湿度",
                    "${weather.current.humidity}%",
                  ),
                  _buildGridCard(
                    Icons.air,
                    "风速",
                    "${weather.current.windSpeed} km/h",
                  ),
                  _buildGridCard(Icons.remove_red_eye_outlined, "能见度", "良好"),
                ],
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return iso.split("T").last;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      if (dt.day == DateTime.now().day) return "今天";
      const weeks = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
      return weeks[dt.weekday - 1];
    } catch (_) {
      return dateStr;
    }
  }

  String _getAqiDesc(double? aqi) {
    if (aqi == null) return "未知";
    if (aqi <= 50) return "优";
    if (aqi <= 100) return "良";
    if (aqi <= 150) return "轻度污染";
    return "污染警告";
  }

  String _getWeatherDesc(int code) {
    if (code == 0) return "晴";
    if (code == 1 || code == 2 || code == 3) return "多云";
    if (code == 45 || code == 48) return "雾";
    if (code >= 51 && code <= 55) return "毛毛雨";
    if (code >= 61 && code <= 67) return "雨";
    if (code >= 71 && code <= 77) return "雪";
    if (code >= 80 && code <= 82) return "阵雨";
    if (code >= 95) return "雷雨";
    return "未知";
  }

  IconData _getWeatherIcon(int code, bool day) {
    if (code == 0) return day ? Icons.wb_sunny : Icons.nightlight_round;
    if (code >= 1 && code <= 3) return day ? Icons.wb_cloudy : Icons.cloud;
    if (code >= 45 && code <= 48) return Icons.blur_on;
    if (code >= 51 && code <= 67) return Icons.beach_access;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 95) return Icons.flash_on;
    return Icons.cloud;
  }
}

// Data class for a single star
class _StarSpec {
  final double x; // 0..1 relative width
  final double y; // 0..1 relative height
  final double radius;
  final double opacity;

  _StarSpec({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
  });
}

class StarPainter extends CustomPainter {
  final List<_StarSpec> stars;

  StarPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final paint = Paint()..color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
