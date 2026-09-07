import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static final ValueNotifier<String> currentLanguage = ValueNotifier('English');

  static Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    currentLanguage.value = prefs.getString('app_language') ?? 'English';
  }

  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    currentLanguage.value = lang;
  }

  static String t(String key) {
    final lang = currentLanguage.value;
    return _translations[key]?[lang] ?? _translations[key]?['English'] ?? key;
  }

  static final Map<String, Map<String, String>> _translations = {
    // ---------- Common ----------
    'app_name': {'English': 'MYGame Marketplace', 'Sinhala': 'MYGame වෙළඳපොළ', 'Tamil': 'MYGame சந்தை'},
    'login': {'English': 'Login', 'Sinhala': 'පිවිසෙන්න', 'Tamil': 'உள்நுழைய'},
    'sign_up': {'English': 'Sign Up', 'Sinhala': 'ලියාපදිංචි වන්න', 'Tamil': 'பதிவு செய்யவும்'},
    'logout': {'English': 'Logout', 'Sinhala': 'ඉවත් වන්න', 'Tamil': 'வெளியேறு'},
    'email': {'English': 'Email', 'Sinhala': 'විද්‍යුත් තැපෑල', 'Tamil': 'மின்னஞ்சல்'},
    'password': {'English': 'Password', 'Sinhala': 'මුරපදය', 'Tamil': 'கடவுச்சொல்'},
    'cancel': {'English': 'Cancel', 'Sinhala': 'අවලංගු කරන්න', 'Tamil': 'ரத்து செய்'},
    'save': {'English': 'Save', 'Sinhala': 'සුරකින්න', 'Tamil': 'சேமி'},
    'submit': {'English': 'Submit', 'Sinhala': 'ඉදිරිපත් කරන්න', 'Tamil': 'சமர்ப்பிக்கவும்'},
    'confirm': {'English': 'Confirm', 'Sinhala': 'තහවුරු කරන්න', 'Tamil': 'உறுதிப்படுத்து'},
    'delete': {'English': 'Delete', 'Sinhala': 'මකන්න', 'Tamil': 'நீக்கு'},
    'edit': {'English': 'Edit', 'Sinhala': 'සංස්කරණය කරන්න', 'Tamil': 'திருத்து'},
    'search': {'English': 'Search', 'Sinhala': 'සොයන්න', 'Tamil': 'தேடு'},
    'loading': {'English': 'Loading...', 'Sinhala': 'පූරණය වෙමින්...', 'Tamil': 'ஏற்றுகிறது...'},
    'error': {'English': 'Error', 'Sinhala': 'දෝෂයකි', 'Tamil': 'பிழை'},
    'success': {'English': 'Success', 'Sinhala': 'සාර්ථකයි', 'Tamil': 'வெற்றி'},
    'close': {'English': 'Close', 'Sinhala': 'වසන්න', 'Tamil': 'மூடு'},
    'send': {'English': 'Send', 'Sinhala': 'යවන්න', 'Tamil': 'அனுப்பு'},
    'back': {'English': 'Back', 'Sinhala': 'ආපසු', 'Tamil': 'பின்னால்'},
    'yes': {'English': 'Yes', 'Sinhala': 'ඔව්', 'Tamil': 'ஆம்'},
    'no': {'English': 'No', 'Sinhala': 'නැත', 'Tamil': 'இல்லை'},

    // ---------- Home / Navigation ----------
    'home': {'English': 'Home', 'Sinhala': 'මුල් පිටුව', 'Tamil': 'முகப்பு'},
    'wallet': {'English': 'Wallet', 'Sinhala': 'පසුම්බිය', 'Tamil': 'பணப்பை'},
    'sell': {'English': 'Sell', 'Sinhala': 'විකුණන්න', 'Tamil': 'விற்க'},
    'chats': {'English': 'Chats', 'Sinhala': 'චැට්', 'Tamil': 'அரட்டைகள்'},
    'settings': {'English': 'Settings', 'Sinhala': 'සැකසුම්', 'Tamil': 'அமைப்புகள்'},
    'search_accounts': {'English': 'Search accounts...', 'Sinhala': 'ගිණුම් සොයන්න...', 'Tamil': 'கணக்குகளைத் தேடு...'},

    // ---------- Settings screen ----------
    'account': {'English': 'Account', 'Sinhala': 'ගිණුම', 'Tamil': 'கணக்கு'},
    'profile_management': {'English': 'Profile Management', 'Sinhala': 'පැතිකඩ කළමනාකරණය', 'Tamil': 'சுயவிவர மேலாண்மை'},
    'change_password': {'English': 'Change Password / PIN', 'Sinhala': 'මුරපදය වෙනස් කරන්න', 'Tamil': 'கடவுச்சொல்லை மாற்றவும்'},
    'verified_badge': {'English': 'Verified Badge Status', 'Sinhala': 'තහවුරු කළ බැඡ් තත්ත්වය', 'Tamil': 'சரிபார்க்கப்பட்ட பேட்ஜ் நிலை'},
    'my_listings': {'English': 'My Listings', 'Sinhala': 'මගේ ලැයිස්තු', 'Tamil': 'எனது பட்டியல்கள்'},
    'my_purchases': {'English': 'My Purchases', 'Sinhala': 'මගේ මිලදී ගැනීම්', 'Tamil': 'எனது கொள்முதல்'},
    'my_sales': {'English': 'My Sales', 'Sinhala': 'මගේ විකිණීම්', 'Tamil': 'எனது விற்பனை'},
    'offers': {'English': 'Offers', 'Sinhala': 'දීමනා', 'Tamil': 'சலுகைகள்'},
    'wallet_bank_details': {'English': 'Wallet & Bank Details', 'Sinhala': 'පසුම්බිය සහ බැංකු විස්තර', 'Tamil': 'பணப்பை & வங்கி விவரங்கள்'},
    'referral_code': {'English': 'Referral Code', 'Sinhala': 'යොමු කේතය', 'Tamil': 'பரிந்துரை குறியீடு'},
    'security': {'English': 'Security', 'Sinhala': 'ආරක්ෂාව', 'Tamil': 'பாதுகாப்பு'},
    'biometric_lock': {'English': 'Biometric Lock', 'Sinhala': 'ජීවමිතික අගුල', 'Tamil': 'உயிரியல் பூட்டு'},
    'blocked_users': {'English': 'Blocked Users', 'Sinhala': 'අවහිර කළ පරිශීලකයින්', 'Tamil': 'தடுக்கப்பட்ட பயனர்கள்'},
    'notifications': {'English': 'Notifications', 'Sinhala': 'දැනුම්දීම්', 'Tamil': 'அறிவிப்புகள்'},
    'order_updates': {'English': 'Order Updates', 'Sinhala': 'ඇණවුම් යාවත්කාලීන', 'Tamil': 'ஆர்டர் புதுப்பிப்புகள்'},
    'offers_bids': {'English': 'Offers & Bids', 'Sinhala': 'දීමනා සහ ලංසු', 'Tamil': 'சலுகைகள் & ஏலங்கள்'},
    'promotions': {'English': 'Promotions', 'Sinhala': 'ප්‍රවර්ධන', 'Tamil': 'விளம்பரங்கள்'},
    'preferences': {'English': 'Preferences', 'Sinhala': 'මනාපයන්', 'Tamil': 'விருப்பங்கள்'},
    'language': {'English': 'Language', 'Sinhala': 'භාෂාව', 'Tamil': 'மொழி'},
    'support': {'English': 'Support', 'Sinhala': 'සහාය', 'Tamil': 'ஆதரவு'},
    'report_problem': {'English': 'Report a Problem / Contact Admin', 'Sinhala': 'ගැටළුවක් වාර්තා කරන්න', 'Tamil': 'சிக்கலைப் புகாரளிக்கவும்'},
    'delete_account': {'English': 'Delete Account', 'Sinhala': 'ගිණුම මකන්න', 'Tamil': 'கணக்கை நீக்கு'},

    // ---------- Login/Register ----------
    'welcome_back': {'English': 'Welcome back', 'Sinhala': 'නැවත සාදරයෙන් පිළිගනිමු', 'Tamil': 'மீண்டும் வரவேற்கிறோம்'},
    'login_to_continue': {'English': 'Login to continue', 'Sinhala': 'ඉදිරියට යාමට පිවිසෙන්න', 'Tamil': 'தொடர உள்நுழையவும்'},
    'create_account': {'English': 'Create account', 'Sinhala': 'ගිණුමක් සාදන්න', 'Tamil': 'கணக்கை உருவாக்கு'},
    'sign_up_to_get_started': {'English': 'Sign up to get started', 'Sinhala': 'ආරම්භ කිරීමට ලියාපදිංචි වන්න', 'Tamil': 'தொடங்க பதிவு செய்யவும்'},
    'forgot_password': {'English': 'Forgot Password?', 'Sinhala': 'මුරපදය අමතකද?', 'Tamil': 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?'},
    'dont_have_account': {'English': "Don't have an account? ", 'Sinhala': 'ගිණුමක් නැද්ද? ', 'Tamil': 'கணக்கு இல்லையா? '},
    'already_have_account': {'English': 'Already have an account? ', 'Sinhala': 'දැනටමත් ගිණුමක් තිබේද? ', 'Tamil': 'ஏற்கனவே கணக்கு உள்ளதா? '},

    // ---------- Wallet ----------
    'available_balance': {'English': 'Available Balance', 'Sinhala': 'ලබා ගත හැකි ශේෂය', 'Tamil': 'கிடைக்கும் இருப்பு'},
    'top_up_wallet': {'English': 'Top Up Wallet', 'Sinhala': 'පසුම්බිය රීචාර්ජ් කරන්න', 'Tamil': 'பணப்பையை நிரப்பு'},
    'withdraw': {'English': 'Withdraw', 'Sinhala': 'ආපසු ගන්න', 'Tamil': 'திரும்பப் பெறு'},
    'transaction_history': {'English': 'Transaction History', 'Sinhala': 'ගනුදෙනු ඉතිහාසය', 'Tamil': 'பரிவர்த்தனை வரலாறு'},

    // ---------- Listings ----------
    'buy_now': {'English': 'Buy Now', 'Sinhala': 'දැන් මිලදී ගන්න', 'Tamil': 'இப்போது வாங்கு'},
    'make_an_offer': {'English': 'Make an Offer', 'Sinhala': 'දීමනාවක් කරන්න', 'Tamil': 'சலுகை செய்யவும்'},
    'place_a_bid': {'English': 'Place a Bid', 'Sinhala': 'ලංසුවක් තබන්න', 'Tamil': 'ஏலம் வையுங்கள்'},
    'price': {'English': 'Price', 'Sinhala': 'මිල', 'Tamil': 'விலை'},
    'description': {'English': 'Description', 'Sinhala': 'විස්තරය', 'Tamil': 'விளக்கம்'},
    'sell_an_account': {'English': 'Sell an Account', 'Sinhala': 'ගිණුමක් විකුණන්න', 'Tamil': 'கணக்கை விற்கவும்'},
    'post_listing': {'English': 'Post Listing', 'Sinhala': 'ලැයිස්තුව පළ කරන්න', 'Tamil': 'பட்டியலை இடுகையிடு'},
  };
}
