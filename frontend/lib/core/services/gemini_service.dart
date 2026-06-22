import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/ai_config.dart';

class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal() {
    _initConnectionHeartbeat();
  }

  // Model fallback chain
  final List<String> _modelChain = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-flash-latest',
  ];

  // Connection State
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _healthStatus = "Initializing";
  String get healthStatus => _healthStatus;

  // Statistics
  int _totalRequests = 0;
  int get totalRequests => _totalRequests;

  int _successfulRequests = 0;
  int get successfulRequests => _successfulRequests;

  int _failedRequests = 0;
  int get failedRequests => _failedRequests;

  final List<double> _responseTimes = [];
  double get averageResponseTime {
    if (_responseTimes.isEmpty) return 0.0;
    return _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;
  }

  final List<String> _errorLogs = [];
  List<String> get errorLogs => List.unmodifiable(_errorLogs.reversed.take(50));

  // Response Caching
  final Map<String, String> _responseCache = {};

  // Active Futures for Duplicate Prevention
  final Map<String, Future<String>> _activeRequests = {};

  // Listeners for UI state reactivity
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final l in _listeners) {
      try {
        l();
      } catch (_) {}
    }
  }

  void logError(String err) {
    final log = "[${DateTime.now().toIso8601String()}] $err";
    _errorLogs.add(log);
    debugPrint(log);
    _notifyListeners();
  }

  // Connection check & heartbeat
  Timer? _heartbeatTimer;
  bool _isChecking = false;

  void _initConnectionHeartbeat() {
    _checkConnection();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnection();
    });
  }

  void dispose() {
    _heartbeatTimer?.cancel();
  }

  Future<String> _getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('localsync_gemini_api_key');
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        return savedKey.trim();
      }
    } catch (e) {
      debugPrint("Error reading custom api key: $e");
    }
    return AIConfig.geminiApiKey;
  }

  Future<bool> _checkConnection() async {
    if (_isChecking) return _isConnected;
    _isChecking = true;

    try {
      // Resolve Gemini host to verify basic internet connectivity to endpoint without consuming API quota
      final result = await InternetAddress.lookup('generativelanguage.googleapis.com')
          .timeout(const Duration(seconds: 5));
      final hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (hasInternet) {
        // If we were previously disconnected or initializing, mark as healthy.
        // We only set it to false if a real API request fails with a quota or authentication error.
        // This avoids making dummy generateContent requests and depleting the API key's quota.
        if (_healthStatus == "Disconnected" || _healthStatus == "Initializing") {
          _isConnected = true;
          _healthStatus = "Healthy";
        }
      } else {
        _isConnected = false;
        _healthStatus = "Disconnected";
      }
    } catch (e) {
      _isConnected = false;
      _healthStatus = "Disconnected";
      logError("Heartbeat network check failed: $e");
    } finally {
      _isChecking = false;
      _notifyListeners();
    }
    return _isConnected;
  }

  Future<bool> runConnectivityTest() async {
    try {
      final key = await _getApiKey();
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: key,
      );
      final response = await model.generateContent([Content.text('ping')])
          .timeout(const Duration(seconds: 5));
      
      final valid = response.text != null && response.text!.isNotEmpty;
      _isConnected = valid;
      _healthStatus = valid ? "Healthy" : "Degraded";
    } catch (e) {
      _isConnected = false;
      _healthStatus = "Disconnected";
      logError("Connectivity test failed: $e");
    } finally {
      _notifyListeners();
    }
    return _isConnected;
  }

  // Multi-model retry content generation with caching, retry logic, timeout, duplicate prevention
  Future<String> generateResponse({
    required String prompt,
    required List<Content> history,
    required String systemInstruction,
  }) async {
    _totalRequests++;
    _notifyListeners();

    final cacheKey = "${prompt.trim().toLowerCase()}_${history.length}";
    if (_responseCache.containsKey(cacheKey)) {
      _successfulRequests++;
      _notifyListeners();
      return _responseCache[cacheKey]!;
    }

    // Duplicate Request Prevention
    if (_activeRequests.containsKey(cacheKey)) {
      return _activeRequests[cacheKey]!;
    }

    final future = _executeWithRetryAndModels(
      prompt: prompt,
      history: history,
      systemInstruction: systemInstruction,
    );

    _activeRequests[cacheKey] = future;

    try {
      final result = await future;
      _responseCache[cacheKey] = result;
      _successfulRequests++;
      _isConnected = true;
      _healthStatus = "Healthy";
      return result;
    } catch (e) {
      _failedRequests++;
      _isConnected = false;
      _healthStatus = "Degraded";
      logError("All models failed for prompt. Error: $e");
      rethrow;
    } finally {
      _activeRequests.remove(cacheKey);
      _notifyListeners();
    }
  }

  Future<String> _executeWithRetryAndModels({
    required String prompt,
    required List<Content> history,
    required String systemInstruction,
  }) async {
    final startTime = DateTime.now();
    Object? lastError;
    final apiKey = await _getApiKey();

    for (final modelName in _modelChain) {
      int retries = 3;
      double backoffMs = 500;

      while (retries > 0) {
        try {
          final requestOptions = (modelName.contains('2.0') || modelName.contains('2.5'))
              ? const RequestOptions(apiVersion: 'v1beta')
              : const RequestOptions(apiVersion: 'v1');

          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            requestOptions: requestOptions,
            systemInstruction: Content.system(systemInstruction),
          );

          final chat = model.startChat(history: history);
          final response = await chat.sendMessage(Content.text(prompt))
              .timeout(const Duration(seconds: 15));

          final text = response.text ?? '';
          if (text.isNotEmpty) {
            final duration = DateTime.now().difference(startTime).inMilliseconds.toDouble();
            _responseTimes.add(duration);
            return text;
          }
        } catch (e) {
          lastError = e;
          retries--;
          if (retries > 0) {
            await Future.delayed(Duration(milliseconds: backoffMs.toInt()));
            backoffMs *= 2.0; // Exponential backoff
          }
        }
      }
      logError("Model $modelName exhausted. Trying next fallback.");
    }

    throw lastError ?? Exception("Failed to generate content");
  }
}
