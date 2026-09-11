import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'device_service.dart';

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
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    if (withAuth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _handle(http.Response res) async {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      final errorMsg = body['error'] ?? 'Request failed (${res.statusCode})';
      if (errorMsg.toString().startsWith('ACCOUNT_BANNED:')) {
        throw Exception('BANNED:${errorMsg.toString().replaceFirst('ACCOUNT_BANNED:', '')}');
      }
      throw Exception(errorMsg);
    }
  }

  // ---------- AUTH ----------
  static Future<void> register(String email, String password, String displayName) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password, 'displayName': displayName}),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> verifyRegistration(String email, String code, {String? referralCode}) async {
    final deviceFingerprint = await DeviceService.getFingerprint();
    final deviceModel = await DeviceService.getModel();
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-registration'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'email': email, 'code': code, 'referralCode': referralCode,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  static Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> verifyLogin(String email, String code) async {
    final deviceFingerprint = await DeviceService.getFingerprint();
    final deviceModel = await DeviceService.getModel();
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'email': email, 'code': code,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  static Future<void> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email}),
    );
    await _handle(res);
  }

  static Future<void> resetPassword(String email, String code, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final deviceFingerprint = await DeviceService.getFingerprint();
    final deviceModel = await DeviceService.getModel();
    final res = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'idToken': idToken,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),
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
      try {
        final err = jsonDecode(resBody);
        final errorMsg = err['error'] ?? 'Upload failed (${streamedRes.statusCode})';
        if (errorMsg.toString().startsWith('ACCOUNT_BANNED:')) {
          throw Exception('BANNED:${errorMsg.toString().replaceFirst('ACCOUNT_BANNED:', '')}');
        }
        throw Exception(errorMsg);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Upload failed (${streamedRes.statusCode})');
      }
    }
    final data = jsonDecode(resBody);
    return data['url'];
  }

  // ---------- USER ----------
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/user/me'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> updateProfile(String displayName, String phone, {String? profilePhotoUrl}) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/me'),
      headers: await _headers(),
      body: jsonEncode({'displayName': displayName, 'phone': phone, 'profilePhotoUrl': profilePhotoUrl}),
    );
    await _handle(res);
  }

  static Future<void> updateProfilePhoto(String profilePhotoUrl) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/me/photo'),
      headers: await _headers(),
      body: jsonEncode({'profilePhotoUrl': profilePhotoUrl}),
    );
    await _handle(res);
  }

  static Future<void> submitSupportRequest(String subject, String message) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/support-request'),
      headers: await _headers(),
      body: jsonEncode({'subject': subject, 'message': message}),
    );
    await _handle(res);
  }

  // ---------- LIVE CHAT WITH ADMIN ----------
  static Future<Map<String, dynamic>?> getActiveChatTicket() async {
    final res = await http.get(Uri.parse('$baseUrl/user/support-chat/active'), headers: await _headers());
    final data = await _handle(res);
    return data['ticket'];
  }

  static Future<int> startLiveChat(String message) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/support-chat/start'),
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    );
    final data = await _handle(res);
    return data['ticketId'];
  }

  static Future<Map<String, dynamic>> getLiveChatMessages(int ticketId) async {
    final res = await http.get(Uri.parse('$baseUrl/user/support-chat/$ticketId/messages'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> sendLiveChatMessage(int ticketId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/support-chat/$ticketId/reply'),
      headers: await _headers(),
      body: jsonEncode({'content': content}),
    );
    await _handle(res);
  }

  // ---------- REPORT LISTING / USER ----------
  static Future<void> reportContent(String targetType, int targetId, String reason, String? details) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/report'),
      headers: await _headers(),
      body: jsonEncode({'targetType': targetType, 'targetId': targetId, 'reason': reason, 'details': details}),
    );
    await _handle(res);
  }

  static Future<void> requestBankDetailsChange(String bankName, String accountName, String accountNumber, String branch) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/bank-details/request-change'),
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

  static Future<void> confirmBankDetailsChange(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/bank-details/confirm-change'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    await _handle(res);
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/password/change'),
      headers: await _headers(),
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    await _handle(res);
  }

  static Future<void> requestEmailChange(String currentPassword, String newEmail) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/email/request-change'),
      headers: await _headers(),
      body: jsonEncode({'currentPassword': currentPassword, 'newEmail': newEmail}),
    );
    await _handle(res);
  }

  static Future<String> confirmEmailChange(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/email/confirm-change'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    final data = await _handle(res);
    return data['newEmail'];
  }

  // ---------- LISTINGS ----------
  static Future<List<dynamic>> getListings({String? game, String? search, String? sort}) async {
    final params = <String, String>{};
    if (game != null) params['game'] = game;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sort != null) params['sort'] = sort;

    final uri = Uri.parse('$baseUrl/listings').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: await _headers(withAuth: false));
    final data = await _handle(res);
    return data['listings'];
  }

  static Future<Map<String, dynamic>> getListingDetail(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/listings/$id'), headers: await _headers(withAuth: false));
    return await _handle(res);
  }

  static Future<List<dynamic>> getMyListings() async {
    final res = await http.get(Uri.parse('$baseUrl/listings/mine/all'), headers: await _headers());
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
    Map<String, String>? stats,
    required String vaultPlatform,
    required String vaultEmail,
    required String vaultPassword,
    String vaultRecoveryCodes = '',
    bool allowBidding = false,
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
        'stats': stats ?? {},
        'vaultPlatform': vaultPlatform,
        'vaultEmail': vaultEmail,
        'vaultPassword': vaultPassword,
        'vaultRecoveryCodes': vaultRecoveryCodes,
        'allowBidding': allowBidding,
      }),
    );
    final data = await _handle(res);
    return data['id'];
  }

  static Future<void> placeBid(int listingId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/listings/$listingId/bid'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount}),
    );
    await _handle(res);
  }

  static Future<void> removeListing(int listingId) async {
    final res = await http.delete(Uri.parse('$baseUrl/listings/$listingId'), headers: await _headers());
    await _handle(res);
  }

  static Future<void> boostListing(int listingId) async {
    final res = await http.post(Uri.parse('$baseUrl/listings/$listingId/boost'), headers: await _headers());
    await _handle(res);
  }

  // ---------- ORDERS ----------
  static Future<Map<String, dynamic>> createOrder(int listingId, {int pointsToUse = 0}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _headers(),
      body: jsonEncode({'listingId': listingId, 'pointsToUse': pointsToUse}),
    );
    return await _handle(res);
  }

  static Future<int> getReferralPoints() async {
    final res = await http.get(Uri.parse('$baseUrl/user/me'), headers: await _headers());
    final data = await _handle(res);
    return (data['referralPoints'] as num?)?.toInt() ?? 0;
  }

  static Future<List<dynamic>> getMyPurchases() async {
    final res = await http.get(Uri.parse('$baseUrl/orders/my-purchases'), headers: await _headers());
    final data = await _handle(res);
    return data['orders'];
  }

  static Future<List<dynamic>> getMySales() async {
    final res = await http.get(Uri.parse('$baseUrl/orders/my-sales'), headers: await _headers());
    final data = await _handle(res);
    return data['orders'];
  }

  static Future<Map<String, dynamic>> getOrderVault(int orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/orders/$orderId/vault'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> raiseDispute(int orderId, String reason) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/dispute'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason}),
    );
    await _handle(res);
  }

  static Future<void> notifyAdminOverdue(int orderId) async {
    final res = await http.post(Uri.parse('$baseUrl/orders/$orderId/notify-admin'), headers: await _headers());
    await _handle(res);
  }

  // ---------- ADMIN CHAT (buyer/seller <-> admin) ----------
  static Future<int> getMyAdminConversation(int orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin-chat/my-conversation/$orderId'), headers: await _headers());
    final data = await _handle(res);
    return data['conversationId'];
  }

  static Future<List<dynamic>> getMyAdminMessages(int conversationId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin-chat/my-messages/$conversationId'), headers: await _headers());
    final data = await _handle(res);
    return data['messages'];
  }

  static Future<void> sendMyAdminMessage(int conversationId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin-chat/my-messages/$conversationId'),
      headers: await _headers(),
      body: jsonEncode({'content': content}),
    );
    await _handle(res);
  }

  // ---------- SELLER PROFILE / BLOCK ----------
  static Future<Map<String, dynamic>> getSellerProfile(int sellerId) async {
    final res = await http.get(Uri.parse('$baseUrl/seller/$sellerId/profile'), headers: await _headers(withAuth: false));
    return await _handle(res);
  }

  static Future<void> blockUser(int userId) async {
    final res = await http.post(Uri.parse('$baseUrl/seller/$userId/block'), headers: await _headers());
    await _handle(res);
  }

  static Future<void> unblockUser(int userId) async {
    final res = await http.post(Uri.parse('$baseUrl/seller/$userId/unblock'), headers: await _headers());
    await _handle(res);
  }

  // ---------- FAVORITES ----------
  static Future<void> addFavorite(int listingId) async {
    final res = await http.post(Uri.parse('$baseUrl/favorites/$listingId'), headers: await _headers());
    await _handle(res);
  }

  static Future<void> removeFavorite(int listingId) async {
    final res = await http.delete(Uri.parse('$baseUrl/favorites/$listingId'), headers: await _headers());
    await _handle(res);
  }

  static Future<List<dynamic>> getFavorites() async {
    final res = await http.get(Uri.parse('$baseUrl/favorites'), headers: await _headers());
    final data = await _handle(res);
    return data['listings'];
  }

  static Future<bool> checkFavorite(int listingId) async {
    final res = await http.get(Uri.parse('$baseUrl/favorites/check/$listingId'), headers: await _headers());
    final data = await _handle(res);
    return data['isFavorite'] ?? false;
  }

  // ---------- PROMOTIONS ----------
  static Future<List<dynamic>> getPromotions() async {
    final res = await http.get(Uri.parse('$baseUrl/promotions'), headers: await _headers(withAuth: false));
    final data = await _handle(res);
    return data['promotions'];
  }

  // ---------- CHATS ----------
  static Future<List<dynamic>> getConversations() async {
    final res = await http.get(Uri.parse('$baseUrl/chats'), headers: await _headers());
    final data = await _handle(res);
    return data['conversations'];
  }

  static Future<List<dynamic>> getMessages(int conversationId) async {
    final res = await http.get(Uri.parse('$baseUrl/chats/$conversationId/messages'), headers: await _headers());
    final data = await _handle(res);
    return data['messages'];
  }

  static Future<int> getOtherUserId(int conversationId) async {
    final res = await http.get(Uri.parse('$baseUrl/chats/$conversationId/other-user'), headers: await _headers());
    final data = await _handle(res);
    return data['otherUserId'];
  }

  static Future<void> sendMessage(int conversationId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chats/$conversationId/messages'),
      headers: await _headers(),
      body: jsonEncode({'content': content}),
    );
    await _handle(res);
  }

  // ---------- OFFERS ----------
  static Future<void> sendOffer(int listingId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/offers'),
      headers: await _headers(),
      body: jsonEncode({'listingId': listingId, 'amount': amount}),
    );
    await _handle(res);
  }

  static Future<List<dynamic>> getOffersSent() async {
    final res = await http.get(Uri.parse('$baseUrl/offers/sent'), headers: await _headers());
    final data = await _handle(res);
    return data['offers'];
  }

  static Future<List<dynamic>> getOffersReceived() async {
    final res = await http.get(Uri.parse('$baseUrl/offers/received'), headers: await _headers());
    final data = await _handle(res);
    return data['offers'];
  }

  static Future<int> acceptOffer(int offerId) async {
    final res = await http.post(Uri.parse('$baseUrl/offers/$offerId/accept'), headers: await _headers());
    final data = await _handle(res);
    return data['orderId'];
  }

  static Future<void> rejectOffer(int offerId) async {
    final res = await http.post(Uri.parse('$baseUrl/offers/$offerId/reject'), headers: await _headers());
    await _handle(res);
  }

  // ---------- NOTIFICATIONS / FCM ----------
  static Future<void> saveFcmToken(String fcmToken) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/notifications/fcm-token'),
        headers: await _headers(),
        body: jsonEncode({'token': fcmToken}),
      );
      await _handle(res);
    } catch (_) {}
  }

  static Future<List<dynamic>> getNotifications() async {
    final res = await http.get(Uri.parse('$baseUrl/notifications'), headers: await _headers());
    final data = await _handle(res);
    return data['notifications'];
  }

  static Future<int> getUnreadNotificationCount() async {
    final res = await http.get(Uri.parse('$baseUrl/notifications/unread-count'), headers: await _headers());
    final data = await _handle(res);
    return data['count'];
  }

  static Future<void> markAllNotificationsRead() async {
    final res = await http.post(Uri.parse('$baseUrl/notifications/mark-all-read'), headers: await _headers());
    await _handle(res);
  }

  static Future<Map<String, dynamic>> getNotificationPreferences() async {
    final res = await http.get(Uri.parse('$baseUrl/notifications/preferences'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> updateNotificationPreferences(bool notifyOrders, bool notifyOffers, bool notifyPromos) async {
    final res = await http.put(
      Uri.parse('$baseUrl/notifications/preferences'),
      headers: await _headers(),
      body: jsonEncode({'notifyOrders': notifyOrders, 'notifyOffers': notifyOffers, 'notifyPromos': notifyPromos}),
    );
    await _handle(res);
  }

  // ---------- WALLET ----------
  static Future<double> getWalletBalance() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/balance'), headers: await _headers());
    final data = await _handle(res);
    return (data['walletBalance'] as num).toDouble();
  }

  static Future<Map<String, dynamic>> getAdminBankDetails() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/admin-bank-details'), headers: await _headers());
    return await _handle(res);
  }

  static Future<List<dynamic>> getTransactions() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/transactions'), headers: await _headers());
    final data = await _handle(res);
    return data['transactions'];
  }

  static Future<void> requestTopUp(double amount, String slipUrl) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/topup'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount, 'slipUrl': slipUrl}),
    );
    await _handle(res);
  }

  static Future<void> requestWithdrawal(double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/withdraw'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount}),
    );
    await _handle(res);
  }

  // ---------- VERIFICATION ----------
  static Future<void> submitVerification({
    required String fullName,
    required String nicNumber,
    required String address,
    required String province,
    required String district,
    required String documentType,
    required String frontImageUrl,
    String? backImageUrl,
    String? selfieImageUrl,
    String? selfieVideoUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verification'),
      headers: await _headers(),
      body: jsonEncode({
        'fullName': fullName,
        'nicNumber': nicNumber,
        'address': address,
        'province': province,
        'district': district,
        'documentType': documentType,
        'frontImageUrl': frontImageUrl,
        'backImageUrl': backImageUrl,
        'selfieImageUrl': selfieImageUrl,
        'selfieVideoUrl': selfieVideoUrl,
      }),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> getVerificationStatusFull() async {
    final res = await http.get(Uri.parse('$baseUrl/verification/status'), headers: await _headers());
    return await _handle(res);
  }

  // ---------- APP UPDATE CHECK ----------
  // Checks GitHub Releases for a newer version than the one currently installed.
  static Future<void> resendOtp(String email, String purpose) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/resend-otp'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'purpose': purpose}),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> checkForUpdate(String currentVersion) async {
    try {
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/shamarcassim1219-cmd/Fistt/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (res.statusCode == 404) {
        return {'updateAvailable': false, 'noReleases': true};
      }
      if (res.statusCode != 200) {
        throw Exception('Could not check for updates right now');
      }

      final data = jsonDecode(res.body);
      final latestTag = (data['tag_name'] ?? '').toString().replaceFirst('v', '');
      final downloadUrl = (data['assets'] as List?)?.cast<Map<String, dynamic>>().firstWhere(
            (a) => (a['name'] ?? '').toString().endsWith('.apk'),
            orElse: () => {},
          )['browser_download_url'];

      final isNewer = _isVersionNewer(latestTag, currentVersion);

      return {
        'updateAvailable': isNewer,
        'latestVersion': latestTag,
        'downloadUrl': downloadUrl,
        'releaseNotes': data['body'],
      };
    } catch (e) {
      throw Exception('Could not check for updates: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  static bool _isVersionNewer(String latest, String current) {
    if (latest.isEmpty) return false;
    final l = latest.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final c = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }
}
