import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/app_config.dart';

class ApiService {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: {
        "Accept": "application/json",
      },
      // Timeout wajar agar tidak nunggu selamanya
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout:    const Duration(seconds: 10),
    ),
  )..interceptors.add(PrettyDioLogger(
      requestBody: true,
      responseBody: true,
    ));

  // ── KEY KONSISTEN ──────────────────────────────────────
  static const String _tokenKey = 'token';

  // 🔥 SIMPAN TOKEN
  static Future<void> setToken(String token) async {
    dio.options.headers["Authorization"] = "Bearer $token";

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 🔥 LOAD TOKEN — dipanggil saat app restart / hot restart
  // Membaca token dari SharedPreferences dan set ke header Dio
  static Future<bool> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null && token.isNotEmpty) {
      dio.options.headers["Authorization"] = "Bearer $token";
      return true; // Token ditemukan
    }

    return false; // Tidak ada token
  }

  // 🔥 CLEAR TOKEN
  static Future<void> clearToken() async {
    dio.options.headers.remove("Authorization");

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // 🔥 CEK APAKAH TOKEN ADA (tanpa network request)
  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }
}