import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/weather.dart';

class WeatherController extends GetxController {
  // AMap Key for Reverse Geocoding
  final String _amapKey = "a48f896630a5575844a2683b0e2e2516";

  // State
  var isLoading = true.obs;
  var weatherData = Rxn<WeatherData>();
  var errorMessage = ''.obs;
  var locationInfo = '定位中...'.obs;

  @override
  void onInit() {
    super.onInit();
    initLocationAndFetchWeather();
  }

  Future<void> initLocationAndFetchWeather() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      locationInfo.value = "正在定位...";

      // 1. Get GPS Location
      Position position = await _determinePosition();

      // 2. Get City and District Name (AMap)
      Map<String, String> address = await _getAddressFromLocation(
        position.latitude,
        position.longitude,
      );

      String city = address['city'] ?? "未知城市";
      String district = address['district'] ?? "";
      String province = address['province'] ?? "";
      locationInfo.value = "$city $district";

      // 3. Get Weather Data (OpenMeteo) including AQI
      await _fetchOpenMeteoWeather(
        position.latitude,
        position.longitude,
        city,
        district,
        province,
      );
    } catch (e) {
      print("❌ Error: $e");

      // Fallback to Beijing if error (Timeout or No Permission)
      print("⚠️ Switching to Default Location (Beijing) due to error");
      try {
        const double lat = 39.9042;
        const double lng = 116.4074;
        locationInfo.value = "北京市 东城区";
        await _fetchOpenMeteoWeather(lat, lng, "北京市", "东城区", "北京市");
      } catch (fallbackError) {
        errorMessage.value = "无法获取天气数据: $e";
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('定位服务未开启');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('定位权限被拒绝');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('定位权限被永久拒绝');
    }

    // Try last known first
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) return lastKnown;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // Raised accuracy as requested
      timeLimit: const Duration(seconds: 20),
      forceAndroidLocationManager: true,
    );
  }

  Future<Map<String, String>> _getAddressFromLocation(
    double lat,
    double lng,
  ) async {
    final url =
        "https://restapi.amap.com/v3/geocode/regeo?output=json&location=$lng,$lat&key=$_amapKey&radius=1000&extensions=all";

    final dio = Dio();
    final response = await dio.get(url);

    if (response.statusCode == 200 && response.data['status'] == '1') {
      final addressComponent = response.data['regeocode']['addressComponent'];
      String city = "";
      String district = "";
      String province = "";

      if (addressComponent['province'] is String) {
        province = addressComponent['province'];
      }

      // Get both city and district separately
      final c = addressComponent['city'];
      final d = addressComponent['district'];

      if (c is String && c.isNotEmpty) {
        city = c;
      } else {
        city = "未知城市";
      }

      if (d is String && d.isNotEmpty) {
        district = d;
      }

      return {'city': city, 'district': district, 'province': province};
    }
    return {'city': '未知地区', 'district': '', 'province': ''};
  }

  Future<void> _fetchOpenMeteoWeather(
    double lat,
    double lng,
    String city,
    String district,
    String province,
  ) async {
    final dio = Dio();

    // 1. Weather Forecast API
    final weatherUrl =
        "https://api.open-meteo.com/v1/forecast?"
        "latitude=$lat&longitude=$lng"
        "&current=temperature_2m,relative_humidity_2m,is_day,weather_code,wind_speed_10m"
        "&hourly=temperature_2m,weather_code,relative_humidity_2m"
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max"
        "&timezone=auto";

    // 2. Air Quality API
    final aqiUrl =
        "https://air-quality-api.open-meteo.com/v1/air-quality?"
        "latitude=$lat&longitude=$lng"
        "&current=us_aqi,pm10,pm2_5"
        "&timezone=auto";

    // Request in parallel
    print("☁️ Fetching Weather...");
    final responses = await Future.wait([dio.get(weatherUrl), dio.get(aqiUrl)]);

    final wRes = responses[0].data;
    final aRes = responses[1].data;

    // Parse Current
    final current = wRes['current'];
    final curWeather = CurrentWeather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
      isDay: current['is_day'] as int,
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      humidity: current['relative_humidity_2m'] as int,
    );

    // Parse Hourly (limit to next 24 hours)
    final hourly = wRes['hourly'];
    List<HourlyWeather> hourlyList = [];
    final hTimes = hourly['time'] as List;
    final hTemps = hourly['temperature_2m'] as List;
    final hCodes = hourly['weather_code'] as List;

    // Find current index based on time string or just take first 24 if API returns from "now"
    // OpenMeteo usually returns from 00:00 of current day. We need to filter for "now" onwards.
    final now = DateTime.now();
    int startIndex = 0;

    for (int i = 0; i < hTimes.length; i++) {
      if (DateTime.parse(
        hTimes[i],
      ).isAfter(now.subtract(const Duration(hours: 1)))) {
        startIndex = i;
        break;
      }
    }

    for (int i = startIndex; i < hTimes.length && hourlyList.length < 24; i++) {
      hourlyList.add(
        HourlyWeather(
          time: hTimes[i],
          temperature: (hTemps[i] as num).toDouble(),
          weatherCode: hCodes[i] as int,
        ),
      );
    }

    // Parse Daily
    final daily = wRes['daily'];
    List<DailyWeather> dailyList = [];
    final dTimes = daily['time'] as List;
    final dCodes = daily['weather_code'] as List;
    final dMax = daily['temperature_2m_max'] as List;
    final dMin = daily['temperature_2m_min'] as List;
    final dSunrise = daily['sunrise'] as List;
    final dSunset = daily['sunset'] as List;
    final dUv = daily['uv_index_max'] as List;

    for (int i = 0; i < dTimes.length; i++) {
      dailyList.add(
        DailyWeather(
          date: dTimes[i],
          weatherCode: dCodes[i] as int,
          maxTemp: (dMax[i] as num).toDouble(),
          minTemp: (dMin[i] as num).toDouble(),
          sunrise: dSunrise[i],
          sunset: dSunset[i],
          uvIndex: (dUv[i] as num).toDouble(),
        ),
      );
    }

    // Parse Air Quality
    AirQuality? aqi;
    if (aRes != null && aRes['current'] != null) {
      final aCur = aRes['current'];
      aqi = AirQuality(
        aqi: (aCur['us_aqi'] as num).toDouble(),
        pm10: (aCur['pm10'] as num).toDouble(),
        pm25: (aCur['pm2_5'] as num).toDouble(),
      );
    }

    weatherData.value = WeatherData(
      current: curWeather,
      hourly: hourlyList,
      daily: dailyList,
      airQuality: aqi,
      city: city,
      district: district,
      province: province,
    );
  }
}
