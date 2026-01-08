class WeatherData {
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final AirQuality? airQuality;
  final String city;
  final String district;
  final String province;

  WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
    this.airQuality,
    required this.city,
    required this.district,
    required this.province,
  });
}

class CurrentWeather {
  final double temperature;
  final int weatherCode;
  final int isDay;
  final double windSpeed;
  final int humidity; // Getting from hourly[current_hour] or current if avail

  CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.isDay,
    required this.windSpeed,
    required this.humidity,
  });
}

class HourlyWeather {
  final String time; // ISO format or just hour string
  final double temperature;
  final int weatherCode;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.weatherCode,
  });
}

class DailyWeather {
  final String date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final String sunrise;
  final String sunset;
  final double uvIndex;

  DailyWeather({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    required this.sunrise,
    required this.sunset,
    required this.uvIndex,
  });
}

class AirQuality {
  final double aqi; // US AQI
  final double pm25;
  final double pm10;

  AirQuality({required this.aqi, required this.pm25, required this.pm10});
}
