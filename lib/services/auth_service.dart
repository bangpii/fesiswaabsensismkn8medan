import 'package:dio/dio.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 🔥 LOGIN
  static Future login(String login, String password) async {
    try {
      final response = await ApiService.dio.post('/login', data: {
        "login": login,
        "password": password,
      });

      final data = response.data;

      if (data["token"] != null) {
        await ApiService.setToken(data["token"]);

        final prefs = await SharedPreferences.getInstance();
        // Simpan login identifier agar bisa auto-fetch data siswa saat resume
        await prefs.setString('login', login);
      }

      return data;
    } catch (e) {
      if (e is DioException) {
        return e.response?.data ?? {"message": "Login gagal"};
      }
      return {"message": "Terjadi kesalahan"};
    }
  }

  // 🔥 LOGOUT — bersihkan SEMUA data sesi
  static Future logout() async {
    try {
      // Coba beritahu server dulu
      await ApiService.dio.post('/logout');
    } catch (_) {
      // Tidak masalah kalau server tidak bisa dicapai — tetap lanjut logout lokal
    } finally {
      // Selalu bersihkan lokal meskipun server error
      await ApiService.clearToken();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('login');
      await prefs.remove('identifier');
    }
  }

  // 🔥 ME
  static Future me() async {
    try {
      final response = await ApiService.dio.get('/me');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        return e.response?.data ?? {"message": "Gagal ambil user"};
      }
      return {"message": "Terjadi kesalahan"};
    }
  }

  // 🔥 STATUS — dipakai untuk validasi token saat app dibuka
  static Future status() async {
    try {
      final response = await ApiService.dio.get('/status');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        // 401 = token tidak valid
        if (e.response?.statusCode == 401) {
          return {"message": "Unauthenticated."};
        }
        return e.response?.data ?? {"message": "Gagal cek status"};
      }
      return {"message": "Terjadi kesalahan"};
    }
  }

  // =========================================
  // 🔐 RESET PASSWORD FLOW
  // =========================================

  // 🔥 STEP 1: KIRIM OTP
  static Future sendOtp(String login, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/reset/send-otp',
        data: {
          "login": login,
          "email": email,
        },
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        return e.response?.data ?? {"message": "Gagal kirim OTP"};
      }
      return {"message": "Terjadi kesalahan"};
    }
  }

  // 🔥 STEP 2: VERIFY OTP
  static Future verifyOtp(String login, String otp) async {
    try {
      final response = await ApiService.dio.post(
        '/reset/verify-otp',
        data: {
          "login": login,
          "otp": otp,
        },
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        return e.response?.data ?? {"message": "OTP tidak valid"};
      }
      return {"message": "Terjadi kesalahan"};
    }
  }

  // 🔥 STEP 3: RESET PASSWORD
  static Future resetPassword(String login, String password) async {
    try {
      final response = await ApiService.dio.post(
        '/reset/password',
        data: {
          "login": login,
          "password": password,
        },
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        return e.response?.data ?? {"message": "Gagal reset password"};
      }
      return {"message": "Terjadi kesalahan"};
    }
  }
}