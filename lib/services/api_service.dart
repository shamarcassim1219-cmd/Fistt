import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api.finbassshamar.online';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _handle(http.Response res) async {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Request failed (${res.statusCode})');
    }
  }

  // ---------- AUTH ----------
  static Future<Map<String, dynamic>> register(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  // ---------- UPLOAD ----------
  static Future<String> uploadImage(File file) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedRes = await request.send();
    final resBody = await streamedRes.stream.bytesToString();

    if (streamedRes.statusCode != 200) {
      final err = jsonDecode(resBody);
      throw Exception(err['error'] ?? 'Upload failed (${streamedRes.statusCode})');
    }
    final data = jsonDecode(resBody);
    return data['url'];
  }

  // ---------- USER ----------
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/user/me'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> updateProfile(String displayName, String phone) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/me'),
      headers: await _headers(),
      body: jsonEncode({'displayName': displayName, 'phone': phone}),
    );
    await _handle(res);
  }

  static Future<void> updateBankDetails(String bankName, String accountName, String accountNumber, String branch) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/bank-details'),
      headers: await _headers(),
      body: jsonEncode({
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'branch': branch,
      }),
    );
    await _handle(res);
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/change-password'),
      headers: await _headers(),
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    await _handle(res);
  }

  // ---------- LISTINGS ----------
  static Future<List<dynamic>> getListings({String? game}) async {
    final uri = Uri.parse('$baseUrl/listings').replace(
      queryParameters: game != null ? {'game': game} : null,
    );
    final res = await http.get(uri, headers: await _headers(withAuth: false));
    final data = await _handle(res);
    return data['listings'];
  }

  static Future<List<dynamic>> getMyListings() async {
    final res = await http.get(Uri.parse('$baseUrl/listings/mine'), headers: await _headers());
    final data = await _handle(res);
    return data['listings'];
  }

  static Future<int> createListing({
    required String game,
    required String title,
    required String description,
    required String inGameUID,
    required double price,
    required List<String> screenshots,
    required String vaultEmail,
    required String vaultPassword,
    String vaultRecoveryCodes = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/listings'),
      headers: await _headers(),
      body: jsonEncode({
        'game': game,
        'title': title,
        'description': description,
        'inGameUID': inGameUID,
        'price': price,
        'screenshots': screenshots,
        'vaultEmail': vaultEmail,
        'vaultPassword': vaultPassword,
        'vaultRecoveryCodes': vaultRecoveryCodes,
      }),
    );
    final data = await _handle(res);
    return data['id'];
  }

  // ---------- WALLET ----------
  static Future<double> getWalletBalance() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/balance'), headers: await _headers());
    final data = await _handle(res);
    return (data['walletBalance'] as num).toDouble();
  }

  static Future<List<dynamic>> getTransactions() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/transactions'), headers: await _headers());
    final data = await _handle(res);
    return data['transactions'];
  }

  static Future<void> requestTopUp(double amount, {String? slipUrl}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/topup'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount, 'slipUrl': slipUrl}),
    );
    await _handle(res);
  }

  static Future<void> requestWithdrawal(double amount, {String paymentMethod = 'bank_deposit'}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/withdraw'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount, 'paymentMethod': paymentMethod}),
    );
    await _handle(res);
  }

  // ---------- VERIFICATION ----------
  static Future<void> submitVerification(String nicImageUrl, String selfieImageUrl) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verification'),
      headers: await _headers(),
      body: jsonEncode({'nicImageUrl': nicImageUrl, 'selfieImageUrl': selfieImageUrl}),
    );
    await _handle(res);
  }

  static Future<String> getVerificationStatus() async {
    final res = await http.get(Uri.parse('$baseUrl/verification/status'), headers: await _headers());
    final data = await _handle(res);
    return data['verifiedStatus'];
  }
}
