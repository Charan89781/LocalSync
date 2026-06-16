import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/weather_repository.dart';
import '../../../core/services/location_service.dart';

final weatherRepositoryProvider = Provider((ref) => WeatherRepository());

final weatherDataProvider = FutureProvider<WeatherData>((ref) async {
  final coordinatesAsync = ref.watch(userCoordinatesProvider);
  final locationAsync = ref.watch(userLocationProvider);
  final repo = ref.watch(weatherRepositoryProvider);

  return coordinatesAsync.when(
    data: (position) async {
      if (position != null) {
        return repo.fetchWeatherByCoords(position.latitude, position.longitude);
      }
      final fullLocation = locationAsync.value ?? 'New Delhi';
      final city = fullLocation.contains(',') ? fullLocation.split(',').last.trim() : fullLocation;
      return repo.fetchWeather(city);
    },
    loading: () => repo.fetchWeather('New Delhi'),
    error: (err, _) => repo.fetchWeather('New Delhi'),
  );
});

final weatherForecastProvider = FutureProvider<WeatherForecast>((ref) async {
  final coordinatesAsync = ref.watch(userCoordinatesProvider);
  final locationAsync = ref.watch(userLocationProvider);
  final repo = ref.watch(weatherRepositoryProvider);

  return coordinatesAsync.when(
    data: (position) async {
      if (position != null) {
        return repo.fetchForecastByCoords(position.latitude, position.longitude);
      }
      final fullLocation = locationAsync.value ?? 'New Delhi';
      final city = fullLocation.contains(',') ? fullLocation.split(',').last.trim() : fullLocation;
      return repo.fetchForecast(city);
    },
    loading: () => repo.fetchForecast('New Delhi'),
    error: (err, _) => repo.fetchForecast('New Delhi'),
  );
});
