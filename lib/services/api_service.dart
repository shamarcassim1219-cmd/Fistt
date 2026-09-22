import 'socket_service.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_service.dart';
import '../main.dart';
import '../screens/login_screen.dart';

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
    SocketService.disconnect(); // drop the old user's realtime connection
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

  static bool _forcingLogout = false;

  static Future<void> _forceLogoutDeleted() async {
    if (_forcingLogout) return;
    _forcingLogout = true;
    await clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Your account no longer exists. Please sign up again if this is a mistake.'), duration: Duration(seconds: 5)),
        );
      }
    }
    _forcingLogout = false;
  }

  static Future<void> _forceLogoutExpired() async {
    if (_forcingLogout) return;
    _forcingLogout = true;
    await clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Your session expired. Please log in again.'), duration: Duration(seconds: 4)),
        );
      }
    }
    _forcingLogout = false;
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
      if (errorMsg.toString().startsWith('ACCOUNT_DELETED:')) {
        _forceLogoutDeleted();
        throw Exception('Your account no longer exists.');
      }
      if (errorMsg.toString().contains('Invalid or expired token') && await getToken() != null) {
        _forceLogoutExpired();
        throw Exception('Your session expired. Please log in again.');
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

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    // {requiresTotp: true, ticket} when two-step verification is on, otherwise {message, email}
    return await _handle(res);
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

  static Future<Map<String, dynamic>> googleSignIn(String idToken, {String? totpCode}) async {
    final deviceFingerprint = await DeviceService.getFingerprint();
    final deviceModel = await DeviceService.getModel();
    final res = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'idToken': idToken,
        if (totpCode != null) 'totpCode': totpCode,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),
    );
    final data = await _handle(res);
    if (data['requiresTotp'] == true) return data; // needs the authenticator code first
    await saveToken(data['token']);
    return data;
  }

  // ---------- UPLOAD ----------
  static Future<String> uploadImage(XFile file) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));

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

  static Future<void> reportProblem(String description) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/report-problem'),
      headers: await _headers(),
      body: jsonEncode({'description': description}),
    );
    await _handle(res);
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

  static Future<void> sendLiveChatTyping(int ticketId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/user/support-chat/$ticketId/typing'),
        headers: await _headers(),
      );
    } catch (_) {}
  }

  static Future<void> closeLiveChat(int ticketId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/support-chat/$ticketId/close'),
      headers: await _headers(),
    );
    await _handle(res);
  }

  static Future<void> transferChatToOperator(int ticketId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/support-chat/$ticketId/transfer'),
      headers: await _headers(),
    );
    await _handle(res);
  }

  static Future<void> sendLiveChatMessage(int ticketId, String content, {String? imageUrl}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/support-chat/$ticketId/reply'),
      headers: await _headers(),
      body: jsonEncode({'content': content, if (imageUrl != null) 'imageUrl': imageUrl}),
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

  static Future<void> requestSetPassword() async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/set-password/request'),
      headers: await _headers(),
    );
    await _handle(res);
  }

  static Future<void> confirmSetPassword(String code, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/set-password/confirm'),
      headers: await _headers(),
      body: jsonEncode({'code': code, 'newPassword': newPassword}),
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
    String saleType = 'full',
    String? rentalUnit,
    double? rentalPricePerUnit,
    int? installmentCount,
    String? installmentFrequency,
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
        'saleType': saleType,
        'rentalUnit': rentalUnit,
        'rentalPricePerUnit': rentalPricePerUnit,
        'installmentCount': installmentCount,
        'installmentFrequency': installmentFrequency,
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
  static Future<Map<String, dynamic>> createOrder(int listingId, {int pointsToUse = 0, String purchaseType = 'full', int? rentalQuantity}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _headers(),
      body: jsonEncode({
        'listingId': listingId,
        'pointsToUse': pointsToUse,
        'purchaseType': purchaseType,
        'rentalQuantity': rentalQuantity,
      }),
    );
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> getInstallments(int orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/orders/$orderId/installments'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> payInstallment(int paymentId) async {
    final res = await http.post(Uri.parse('$baseUrl/orders/installments/$paymentId/pay'), headers: await _headers());
    await _handle(res);
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
  static Future<void> raiseDispute(int orderId, String reason, {String? photoUrl}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/dispute'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason, 'photoUrl': photoUrl}),
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

  // ---------- TOP-UP STORE ----------
  static Future<List<dynamic>> getTopupGames() async {
    final res = await http.get(Uri.parse('$baseUrl/topup/games'), headers: await _headers());
    final data = await _handle(res);
    return data['games'];
  }

  static Future<List<dynamic>> getTopupPackages(int gameId) async {
    final res = await http.get(Uri.parse('$baseUrl/topup/games/$gameId/packages'), headers: await _headers());
    final data = await _handle(res);
    return data['packages'];
  }

  static Future<Map<String, dynamic>> submitTopupOrder({
    required int gameId,
    required int packageId,
    required String playerId,
    String? zoneId,
    String? region,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/topup/order'),
      headers: await _headers(),
      body: jsonEncode({
        'gameId': gameId,
        'packageId': packageId,
        'playerId': playerId,
        'zoneId': zoneId,
        'region': region,
      }),
    );
    return await _handle(res);
  }

  static Future<List<dynamic>> getMyTopupOrders() async {
    final res = await http.get(Uri.parse('$baseUrl/topup/my-orders'), headers: await _headers());
    final data = await _handle(res);
    return data['orders'];
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

  static Future<void> clearFcmToken() async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/notifications/fcm-token'),
        headers: await _headers(),
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

  static Future<List<dynamic>> getDepositMethods() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/deposit-methods'), headers: await _headers());
    final data = await _handle(res);
    return data['methods'];
  }

  static Future<List<dynamic>> getTransactions() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/transactions'), headers: await _headers());
    final data = await _handle(res);
    return data['transactions'];
  }

  static Future<void> requestTopUp(double amount, String slipUrl, String referenceNumber) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/topup'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount, 'slipUrl': slipUrl, 'referenceNumber': referenceNumber}),
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
  static Future<Map<String, dynamic>> getVerificationStatusFull() async {
    final res = await http.get(Uri.parse('$baseUrl/verification/status'), headers: await _headers());
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> submitVerificationFiles({
    required Map<String, String> fields,
    required Map<String, String> filePaths,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/verification/submit'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    for (final e in filePaths.entries) {
      request.files.add(await http.MultipartFile.fromPath(e.key, e.value, contentType: MediaType('image', 'jpeg')));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 180));
    final res = await http.Response.fromStream(streamed);
    return await _handle(res);
  }

  // web: photos live in memory (no files), so they are uploaded from bytes
  static Future<Map<String, dynamic>> submitVerificationBytes({
    required Map<String, String> fields,
    required Map<String, Uint8List> files,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/verification/submit'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    for (final e in files.entries) {
      request.files.add(http.MultipartFile.fromBytes(e.key, e.value, filename: '${e.key}.jpg', contentType: MediaType('image', 'jpeg')));
    }
    final streamed = await request.send().timeout(const Duration(seconds: 180));
    final res = await http.Response.fromStream(streamed);
    return await _handle(res);
  }

  // ---------- BINANCE DEPOSIT ----------
  static Future<Map<String, dynamic>> getBinanceDepositInfo() async {
    final res = await http.get(Uri.parse('$baseUrl/binance/info'), headers: await _headers());
    final data = await _handle(res);
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> verifyBinanceDeposit(String orderId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/binance/verify'),
      headers: await _headers(),
      body: jsonEncode({'orderId': orderId}),
    );
    final data = await _handle(res);
    return Map<String, dynamic>.from(data);
  }

  static Future<bool> checkNicExists(String nic) async {
    final res = await http.get(
      Uri.parse('$baseUrl/verification/check-nic?nic=${Uri.encodeQueryComponent(nic)}'),
      headers: await _headers(),
    );
    final data = await _handle(res);
    return data['exists'] == true;
  }

  // ---------- MORE TOOLS ----------
  static Future<List<dynamic>> getMoreTools() async {
    final res = await http.get(Uri.parse('$baseUrl/tools/list'), headers: await _headers());
    final data = await _handle(res);
    return (data['tools'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> ffInfoCheck(String uid, String region) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tools/ff-info'),
      headers: await _headers(),
      body: jsonEncode({'uid': uid, 'region': region}),
    );
    final data = await _handle(res);
    return Map<String, dynamic>.from(data);
  }

  // ---------- TOURNAMENTS ----------
  static Future<Map<String, dynamic>> getTournaments() async {
    final res = await http.get(Uri.parse('$baseUrl/tournaments'), headers: await _headers());
    final data = await _handle(res);
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getTournament(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/tournaments/$id'), headers: await _headers());
    final data = await _handle(res);
    return Map<String, dynamic>.from(data);
  }

  static Future<String> registerTournament(int id, {required String guildName, String? guildImageUrl, required String gameId, required String gameName}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tournaments/$id/register'),
      headers: await _headers(),
      body: jsonEncode({'guildName': guildName, 'guildImageUrl': guildImageUrl ?? '', 'gameId': gameId, 'gameName': gameName}),
    );
    final data = await _handle(res);
    return '${data['message'] ?? 'Registered'}';
  }

  static Future<List<dynamic>> searchTournamentUsers(String q) async {
    final res = await http.get(Uri.parse('$baseUrl/tournaments/users/search?q=${Uri.encodeQueryComponent(q)}'), headers: await _headers());
    final data = await _handle(res);
    return (data['users'] as List?) ?? [];
  }

  static Future<void> inviteTournamentPlayer(int teamId, int userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tournaments/teams/$teamId/invite'),
      headers: await _headers(),
      body: jsonEncode({'userId': userId}),
    );
    await _handle(res);
  }

  static Future<void> acceptTournamentInvite(int memberId, String gameId, String gameName) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tournaments/invites/$memberId/accept'),
      headers: await _headers(),
      body: jsonEncode({'gameId': gameId, 'gameName': gameName}),
    );
    await _handle(res);
  }

  static Future<void> rejectTournamentInvite(int memberId) async {
    final res = await http.post(Uri.parse('$baseUrl/tournaments/invites/$memberId/reject'), headers: await _headers());
    await _handle(res);
  }

  static Future<void> removeTournamentMember(int teamId, int memberId) async {
    final res = await http.delete(Uri.parse('$baseUrl/tournaments/teams/$teamId/members/$memberId'), headers: await _headers());
    await _handle(res);
  }

  static Future<void> leaveTournamentTeam(int teamId) async {
    final res = await http.post(Uri.parse('$baseUrl/tournaments/teams/$teamId/leave'), headers: await _headers());
    await _handle(res);
  }

  static Future<String> dissolveTournamentTeam(int teamId) async {
    final res = await http.post(Uri.parse('$baseUrl/tournaments/teams/$teamId/dissolve'), headers: await _headers());
    final data = await _handle(res);
    return '${data['message'] ?? 'Team dissolved'}';
  }

  static Future<void> updateTournamentTeam(int teamId, {String? guildName, String? guildImageUrl}) async {
    final body = <String, dynamic>{};
    if (guildName != null) body['guildName'] = guildName;
    if (guildImageUrl != null) body['guildImageUrl'] = guildImageUrl;
    final res = await http.put(Uri.parse('$baseUrl/tournaments/teams/$teamId'), headers: await _headers(), body: jsonEncode(body));
    await _handle(res);
  }

  // ---------- GAME DPI & SENSITIVITY ----------
  static Future<Map<String, dynamic>> getGameTunerConfig(String game) async {
    final res = await http.get(Uri.parse('$baseUrl/gamedpi/config?game=${Uri.encodeQueryComponent(game)}'), headers: await _headers());
    final data = await _handle(res);
    return Map<String, dynamic>.from(data);
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
        Uri.parse('https://buysellgame.store/downloads/version.json?t=${DateTime.now().millisecondsSinceEpoch}'),
      );

      if (res.statusCode != 200) {
        throw Exception('Could not check for updates right now');
      }

      final data = jsonDecode(res.body);
      final latestVersion = (data['version'] ?? '').toString();
      final downloadUrl = data['downloadUrl'];

      final isNewer = _isVersionNewer(latestVersion, currentVersion);

      return {
        'updateAvailable': isNewer,
        'latestVersion': latestVersion,
        'downloadUrl': downloadUrl,
        'releaseNotes': data['releaseNotes'],
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

  // ---------- TWO-STEP VERIFICATION (Google Authenticator) ----------
  static Future<Map<String, dynamic>> verifyTotpLogin(String ticket, String code) async {
    final deviceFingerprint = await DeviceService.getFingerprint();
    final deviceModel = await DeviceService.getModel();
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-totp-login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'ticket': ticket, 'code': code,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  static Future<bool> totpStatus() async {
    final res = await http.get(Uri.parse('$baseUrl/auth/totp/status'), headers: await _headers());
    final data = await _handle(res);
    return data['enabled'] == true;
  }

  static Future<Map<String, dynamic>> totpGenerate() async {
    final res = await http.post(Uri.parse('$baseUrl/auth/totp/generate'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> totpConfirm(String secret, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/totp/confirm'),
      headers: await _headers(),
      body: jsonEncode({'secret': secret, 'code': code}),
    );
    await _handle(res);
  }

  static Future<void> totpDisable(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/totp/disable'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    await _handle(res);
  }

  static Future<bool> totpVerifyUnlock(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/totp/verify'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    final data = await _handle(res);
    return data['enabled'] == true;
  }
}
