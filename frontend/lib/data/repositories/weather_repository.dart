import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String condition;
  final String icon;
  final double tempMin;
  final double tempMax;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String cityName;
  final String description;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
    this.tempMin = 0.0,
    this.tempMax = 0.0,
    this.feelsLike = 0.0,
    this.humidity = 0,
    this.windSpeed = 0.0,
    this.cityName = 'Unknown',
    this.description = '',
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final weatherList = json['weather'] as List<dynamic>? ?? [{}];
    final weather = weatherList.first as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};

    return WeatherData(
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      condition: weather['main'] as String? ?? 'Clear',
      icon: weather['icon'] as String? ?? '01d',
      tempMin: (main['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (main['temp_max'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      humidity: main['humidity'] as int? ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      cityName: json['name'] as String? ?? 'Unknown',
      description: weather['description'] as String? ?? '',
    );
  }

  /// Realistic demo data used when the API is unavailable
  static WeatherData mock(String city) => WeatherData(
        temperature: 28.5,
        condition: 'Clear',
        icon: '01d',
        tempMin: 24.0,
        tempMax: 32.0,
        feelsLike: 30.2,
        humidity: 62,
        windSpeed: 3.4,
        cityName: city.isNotEmpty ? city : 'Your City',
        description: 'clear sky',
      );
}

class ForecastDay {
  final DateTime date;
  final double temperature;
  final double tempMin;
  final double tempMax;
  final String condition;
  final String icon;
  final int humidity;
  final double windSpeed;

  ForecastDay({
    required this.date,
    required this.temperature,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });
}

class WeatherForecast {
  final String cityName;
  final String country;
  final List<ForecastDay> dailyForecasts;

  WeatherForecast({
    required this.cityName,
    required this.country,
    required this.dailyForecasts,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>? ?? {};
    final cityName = city['name'] as String? ?? 'Unknown';
    final country = city['country'] as String? ?? '';
    final list = json['list'] as List<dynamic>? ?? [];

    final Map<String, Map<String, dynamic>> dailyMap = {};
    for (var item in list) {
      final dtTxt = item['dt_txt'] as String? ?? '';
      if (dtTxt.isEmpty) continue;
      final dateStr = dtTxt.split(' ').first;

      final isNoon = dtTxt.contains('12:00:00');
      if (!dailyMap.containsKey(dateStr) || isNoon) {
        dailyMap[dateStr] = Map<String, dynamic>.from(item);
      }
    }

    final List<ForecastDay> forecasts = [];
    final sortedKeys = dailyMap.keys.toList()..sort();

    for (var key in sortedKeys) {
      final item = dailyMap[key]!;
      final dt = item['dt'] as int? ?? 0;
      final main = item['main'] as Map<String, dynamic>? ?? {};
      final weatherList = item['weather'] as List<dynamic>? ?? [{}];
      final weather = weatherList.first as Map<String, dynamic>? ?? {};
      final wind = item['wind'] as Map<String, dynamic>? ?? {};

      forecasts.add(ForecastDay(
        date: DateTime.fromMillisecondsSinceEpoch(dt * 1000),
        temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
        tempMin: (main['temp_min'] as num?)?.toDouble() ?? 0.0,
        tempMax: (main['temp_max'] as num?)?.toDouble() ?? 0.0,
        condition: weather['main'] as String? ?? 'Clear',
        icon: weather['icon'] as String? ?? '01d',
        humidity: main['humidity'] as int? ?? 0,
        windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      ));
    }

    return WeatherForecast(
      cityName: cityName,
      country: country,
      dailyForecasts: forecasts,
    );
  }

  /// Realistic 5-day mock forecast when the API is unavailable
  static WeatherForecast mock(String city) {
    final now = DateTime.now();
    final conditions = ['Clear', 'Clouds', 'Rain', 'Clear', 'Clouds'];
    final icons = ['01d', '03d', '10d', '01d', '02d'];
    final temps = [28.5, 26.0, 22.5, 30.0, 27.0];
    final mins = [23.0, 21.0, 19.0, 25.0, 22.0];
    final maxs = [33.0, 29.0, 25.0, 34.0, 30.0];

    return WeatherForecast(
      cityName: city.isNotEmpty ? city : 'Your City',
      country: 'IN',
      dailyForecasts: List.generate(
        5,
        (i) => ForecastDay(
          date: now.add(Duration(days: i)),
          temperature: temps[i],
          tempMin: mins[i],
          tempMax: maxs[i],
          condition: conditions[i],
          icon: icons[i],
          humidity: 55 + (i * 5),
          windSpeed: 2.5 + (i * 0.5),
        ),
      ),
    );
  }
}

class WeatherRepository {
  static const String _apiKey = '8db9f310f8a846903f7e6f987f4a2d8a';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastUrl =
      'https://api.openweathermap.org/data/2.5/forecast';

  Future<WeatherData> fetchWeather(String city) async {
    try {
      final url = '$_baseUrl?q=$city&units=metric&appid=$_apiKey';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return WeatherData.fromJson(json.decode(response.body));
      }
      return WeatherData.mock(city);
    } catch (_) {
      return WeatherData.mock(city);
    }
  }

  Future<WeatherData> fetchWeatherByCoords(double lat, double lon) async {
    try {
      final url =
          '$_baseUrl?lat=$lat&lon=$lon&units=metric&appid=$_apiKey';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return WeatherData.fromJson(json.decode(response.body));
      }
      return WeatherData.mock('');
    } catch (_) {
      return WeatherData.mock('');
    }
  }

  Future<WeatherForecast> fetchForecast(String city) async {
    try {
      final url = '$_forecastUrl?q=$city&units=metric&appid=$_apiKey';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return WeatherForecast.fromJson(json.decode(response.body));
      }
      return WeatherForecast.mock(city);
    } catch (_) {
      return WeatherForecast.mock(city);
    }
  }

  Future<WeatherForecast> fetchForecastByCoords(double lat, double lon) async {
    try {
      final url =
          '$_forecastUrl?lat=$lat&lon=$lon&units=metric&appid=$_apiKey';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return WeatherForecast.fromJson(json.decode(response.body));
      }
      return WeatherForecast.mock('');
    } catch (_) {
      return WeatherForecast.mock('');
    }
  }
}
