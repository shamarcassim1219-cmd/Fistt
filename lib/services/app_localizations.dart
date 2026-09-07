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
    'retry': {'English': 'Retry', 'Sinhala': 'නැවත උත්සාහ කරන්න', 'Tamil': 'மீண்டும் முயற்சிக்கவும்'},

    'home': {'English': 'Home', 'Sinhala': 'මුල් පිටුව', 'Tamil': 'முகப்பு'},
    'wallet': {'English': 'Wallet', 'Sinhala': 'පසුම්බිය', 'Tamil': 'பணப்பை'},
    'sell': {'English': 'Sell', 'Sinhala': 'විකුණන්න', 'Tamil': 'விற்க'},
    'chats': {'English': 'Chats', 'Sinhala': 'චැට්', 'Tamil': 'அரட்டைகள்'},
    'settings': {'English': 'Settings', 'Sinhala': 'සැකසුම්', 'Tamil': 'அமைப்புகள்'},
    'search_accounts': {'English': 'Search accounts...', 'Sinhala': 'ගිණුම් සොයන්න...', 'Tamil': 'கணக்குகளைத் தேடு...'},

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

    'welcome_back': {'English': 'Welcome back', 'Sinhala': 'නැවත සාදරයෙන් පිළිගනිමු', 'Tamil': 'மீண்டும் வரவேற்கிறோம்'},
    'login_to_continue': {'English': 'Login to continue', 'Sinhala': 'ඉදිරියට යාමට පිවිසෙන්න', 'Tamil': 'தொடர உள்நுழையவும்'},
    'create_account': {'English': 'Create account', 'Sinhala': 'ගිණුමක් සාදන්න', 'Tamil': 'கணக்கை உருவாக்கு'},
    'sign_up_to_get_started': {'English': 'Sign up to get started', 'Sinhala': 'ආරම්භ කිරීමට ලියාපදිංචි වන්න', 'Tamil': 'தொடங்க பதிவு செய்யவும்'},
    'forgot_password': {'English': 'Forgot Password?', 'Sinhala': 'මුරපදය අමතකද?', 'Tamil': 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?'},
    'dont_have_account': {'English': "Don't have an account? ", 'Sinhala': 'ගිණුමක් නැද්ද? ', 'Tamil': 'கணக்கு இல்லையா? '},
    'already_have_account': {'English': 'Already have an account? ', 'Sinhala': 'දැනටමත් ගිණුමක් තිබේද? ', 'Tamil': 'ஏற்கனவே கணக்கு உள்ளதா? '},

    'available_balance': {'English': 'Available Balance', 'Sinhala': 'ලබා ගත හැකි ශේෂය', 'Tamil': 'கிடைக்கும் இருப்பு'},
    'my_wallet': {'English': 'My Wallet', 'Sinhala': 'මගේ පසුම්බිය', 'Tamil': 'எனது பணப்பை'},
    'top_up': {'English': 'Top Up', 'Sinhala': 'රීචාර්ජ් කරන්න', 'Tamil': 'நிரப்பு'},
    'top_up_wallet': {'English': 'Top Up Wallet', 'Sinhala': 'පසුම්බිය රීචාර්ජ් කරන්න', 'Tamil': 'பணப்பையை நிரப்பு'},
    'withdraw': {'English': 'Withdraw', 'Sinhala': 'ආපසු ගන්න', 'Tamil': 'திரும்பப் பெறு'},
    'withdraw_to_bank': {'English': 'Withdraw to Bank', 'Sinhala': 'බැංකුවට ආපසු ගන්න', 'Tamil': 'வங்கிக்குத் திரும்பப் பெறு'},
    'transaction_history': {'English': 'Transaction History', 'Sinhala': 'ගනුදෙනු ඉතිහාසය', 'Tamil': 'பரிவர்த்தனை வரலாறு'},
    'no_transactions': {'English': 'No transactions yet', 'Sinhala': 'තවම ගනුදෙනු නැත', 'Tamil': 'இன்னும் பரிவர்த்தனைகள் இல்லை'},
    'amount_lkr': {'English': 'Amount (LKR)', 'Sinhala': 'මුදල (රු)', 'Tamil': 'தொகை (LKR)'},
    'deposit_to_account': {'English': 'Deposit to this account', 'Sinhala': 'මෙම ගිණුමට තැන්පත් කරන්න', 'Tamil': 'இந்த கணக்கில் டெபாசிட் செய்யவும்'},
    'upload_bank_slip': {'English': 'Upload Bank Slip', 'Sinhala': 'බැංකු පත්‍රිකාව උඩුගත කරන්න', 'Tamil': 'வங்கி நழுவலைப் பதிவேற்றவும்'},
    'tap_upload_slip': {'English': 'Tap to upload slip', 'Sinhala': 'පත්‍රිකාව උඩුගත කිරීමට ස්පර්ශ කරන්න', 'Tamil': 'ஸ்லிப்பைப் பதிவேற்ற தட்டவும்'},
    'submit_topup': {'English': 'Submit Top-Up', 'Sinhala': 'රීචාර්ජ් ඉදිරිපත් කරන්න', 'Tamil': 'நிரப்புதலைச் சமர்ப்பிக்கவும்'},
    'request_withdrawal': {'English': 'Request Withdrawal', 'Sinhala': 'ආපසු ගැනීමට ඉල්ලන්න', 'Tamil': 'திரும்பப்பெறலைக் கோரவும்'},
    'available_colon': {'English': 'Available: LKR', 'Sinhala': 'ලබාගත හැක: රු', 'Tamil': 'கிடைக்கும்: LKR'},

    'buy_now': {'English': 'Buy Now', 'Sinhala': 'දැන් මිලදී ගන්න', 'Tamil': 'இப்போது வாங்கு'},
    'make_an_offer': {'English': 'Make an Offer', 'Sinhala': 'දීමනාවක් කරන්න', 'Tamil': 'சலுகை செய்யவும்'},
    'place_a_bid': {'English': 'Place a Bid', 'Sinhala': 'ලංසුවක් තබන්න', 'Tamil': 'ஏலம் வையுங்கள்'},
    'price': {'English': 'Price', 'Sinhala': 'මිල', 'Tamil': 'விலை'},
    'description': {'English': 'Description', 'Sinhala': 'විස්තරය', 'Tamil': 'விளக்கம்'},
    'sell_an_account': {'English': 'Sell an Account', 'Sinhala': 'ගිණුමක් විකුණන්න', 'Tamil': 'கணக்கை விற்கவும்'},
    'post_listing': {'English': 'Post Listing', 'Sinhala': 'ලැයිස්තුව පළ කරන්න', 'Tamil': 'பட்டியலை இடுகையிடு'},

    'game': {'English': 'Game', 'Sinhala': 'ක්‍රීඩාව', 'Tamil': 'விளையாட்டு'},
    'listing_details': {'English': 'Listing Details', 'Sinhala': 'ලැයිස්තු විස්තර', 'Tamil': 'பட்டியல் விவரங்கள்'},
    'title_field': {'English': 'Title', 'Sinhala': 'මාතෘකාව', 'Tamil': 'தலைப்பு'},
    'in_game_uid': {'English': 'In-Game UID', 'Sinhala': 'ක්‍රීඩාව තුළ UID', 'Tamil': 'விளையாட்டு UID'},
    'allow_bidding': {'English': 'Allow Bidding', 'Sinhala': 'ලංසු තැබීමට ඉඩ දෙන්න', 'Tamil': 'ஏலம் அனுமதிக்கவும்'},
    'screenshots_max6': {'English': 'Screenshots (max 6)', 'Sinhala': 'තිර රුව (උපරිම 6)', 'Tamil': 'ஸ்கிரீன்ஷாட்கள் (அதிகபட்சம் 6)'},
    'account_vault': {'English': 'Account Vault (Private & Encrypted)', 'Sinhala': 'ගිණුම් හැඳුනුම (පුද්ගලික සහ සංකේතාත්මක)', 'Tamil': 'கணக்கு பெட்டகம் (தனிப்பட்ட & குறியாக்கம்)'},
    'account_email': {'English': 'Account Email', 'Sinhala': 'ගිණුම් විද්‍යුත් තැපෑල', 'Tamil': 'கணக்கு மின்னஞ்சல்'},
    'account_password': {'English': 'Account Password', 'Sinhala': 'ගිණුම් මුරපදය', 'Tamil': 'கணக்கு கடவுச்சொல்'},
    'recovery_codes': {'English': 'Recovery Codes (optional)', 'Sinhala': 'ප්‍රතිසාධන කේත (විකල්ප)', 'Tamil': 'மீட்பு குறியீடுகள் (விருப்பம்)'},
    'verification_required': {'English': 'Verification Required', 'Sinhala': 'තහවුරු කිරීම අවශ්‍යයි', 'Tamil': 'சரிபார்ப்பு தேவை'},

    'active': {'English': 'Active', 'Sinhala': 'ක්‍රියාකාරී', 'Tamil': 'செயலில்'},
    'pending': {'English': 'Pending', 'Sinhala': 'අපේක්ෂිත', 'Tamil': 'நிலுவையில்'},
    'sold': {'English': 'Sold', 'Sinhala': 'විකුණන ලදී', 'Tamil': 'விற்கப்பட்டது'},
    'removed': {'English': 'Removed', 'Sinhala': 'ඉවත් කරන ලදී', 'Tamil': 'அகற்றப்பட்டது'},
    'boost': {'English': 'Boost', 'Sinhala': 'තල්ලු කරන්න', 'Tamil': 'ஊக்கு'},
    'boosted': {'English': 'Boosted', 'Sinhala': 'තල්ලු කරන ලදී', 'Tamil': 'ஊக்கப்பட்டது'},
    'remove': {'English': 'Remove', 'Sinhala': 'ඉවත් කරන්න', 'Tamil': 'அகற்று'},
    'remove_listing': {'English': 'Remove Listing', 'Sinhala': 'ලැයිස්තුව ඉවත් කරන්න', 'Tamil': 'பட்டியலை அகற்று'},
    'no_listings_yet': {'English': 'No listings yet.\nTap "Sell" to post your first account.', 'Sinhala': 'තවම ලැයිස්තු නැත.\nඔබේ පළමු ගිණුම පළ කිරීමට "විකුණන්න" ස්පර්ශ කරන්න.', 'Tamil': 'இன்னும் பட்டியல்கள் இல்லை.\nஉங்கள் முதல் கணக்கை இடுகையிட "விற்க" தட்டவும்.'},
    'no_purchases_yet': {'English': 'No purchases yet', 'Sinhala': 'තවම මිලදී ගැනීම් නැත', 'Tamil': 'இன்னும் கொள்முதல் இல்லை'},
    'no_sales_yet': {'English': 'No sales yet', 'Sinhala': 'තවම විකිණීම් නැත', 'Tamil': 'இன்னும் விற்பனை இல்லை'},
    'view_credentials': {'English': 'View Account Credentials', 'Sinhala': 'ගිණුම් අක්තපත්‍ර බලන්න', 'Tamil': 'கணக்கு சான்றுகளைப் பார்க்கவும்'},
    'raise_dispute': {'English': 'Raise a Dispute', 'Sinhala': 'ආරවුලක් ඉදිරිපත් කරන්න', 'Tamil': 'ஒரு தகராறை எழுப்பவும்'},
    'in_escrow': {'English': 'In Escrow', 'Sinhala': 'භාරයේ', 'Tamil': 'எஸ்க்ரோவில்'},
    'completed': {'English': 'Completed', 'Sinhala': 'සම්පූර්ණයි', 'Tamil': 'முடிந்தது'},
    'disputed': {'English': 'Disputed', 'Sinhala': 'ආරවුල් සහිත', 'Tamil': 'சர்ச்சைக்குரியது'},
    'refunded': {'English': 'Refunded', 'Sinhala': 'ආපසු ගෙවන ලදී', 'Tamil': 'திரும்பப் பெறப்பட்டது'},
    'paid_out': {'English': 'Paid Out', 'Sinhala': 'ගෙවනු ලැබීය', 'Tamil': 'செலுத்தப்பட்டது'},
    'order_id': {'English': 'Order ID', 'Sinhala': 'ඇණවුම් අංකය', 'Tamil': 'ஆர்டர் ஐடி'},
    'amount_paid': {'English': 'Amount Paid', 'Sinhala': 'ගෙවූ මුදල', 'Tamil': 'செலுத்தப்பட்ட தொகை'},
    'status': {'English': 'Status', 'Sinhala': 'තත්ත්වය', 'Tamil': 'நிலை'},
    'purchased_on': {'English': 'Purchased On', 'Sinhala': 'මිලදී ගත් දිනය', 'Tamil': 'வாங்கிய தேதி'},
    'sold_on': {'English': 'Sold On', 'Sinhala': 'විකුණන ලද දිනය', 'Tamil': 'விற்ற தேதி'},
    'sale_price': {'English': 'Sale Price', 'Sinhala': 'විකුණුම් මිල', 'Tamil': 'விற்பனை விலை'},
    'you_receive_amount': {'English': 'You Receive', 'Sinhala': 'ඔබ ලබා ගනී', 'Tamil': 'நீங்கள் பெறுவீர்கள்'},
    'chat_with_admin': {'English': 'Chat with Admin', 'Sinhala': 'පරිපාලක සමඟ කතාබහ කරන්න', 'Tamil': 'நிர்வாகியுடன் அரட்டையடிக்கவும்'},

    'view_seller_profile': {'English': 'View Seller Profile', 'Sinhala': 'විකුණන්නාගේ පැතිකඩ බලන්න', 'Tamil': 'விற்பனையாளர் சுயவிவரத்தைப் பார்க்கவும்'},
    'your_listing': {'English': 'Your Listing', 'Sinhala': 'ඔබේ ලැයිස්තුව', 'Tamil': 'உங்கள் பட்டியல்'},
    'current_highest_bid': {'English': 'Current Highest Bid', 'Sinhala': 'වර්තමාන ඉහළම ලංසුව', 'Tamil': 'தற்போதைய அதிக ஏலம்'},
    'starting_price': {'English': 'Starting Price', 'Sinhala': 'ආරම්භක මිල', 'Tamil': 'தொடக்க விலை'},
    'bid_history': {'English': 'Bid History', 'Sinhala': 'ලංසු ඉතිහාසය', 'Tamil': 'ஏல வரலாறு'},
    'confirm_purchase': {'English': 'Confirm Purchase', 'Sinhala': 'මිලදී ගැනීම තහවුරු කරන්න', 'Tamil': 'கொள்முதலை உறுதிப்படுத்தவும்'},
    'confirm_pay': {'English': 'Confirm & Pay', 'Sinhala': 'තහවුරු කර ගෙවන්න', 'Tamil': 'உறுதிப்படுத்தி செலுத்தவும்'},
    'your_offer': {'English': 'Your Offer (LKR)', 'Sinhala': 'ඔබේ දීමනාව (රු)', 'Tamil': 'உங்கள் சலுகை (LKR)'},
    'send_offer': {'English': 'Send Offer', 'Sinhala': 'දීමනාව යවන්න', 'Tamil': 'சலுகையை அனுப்பு'},
    'listing_price': {'English': 'Listing price', 'Sinhala': 'ලැයිස්තු මිල', 'Tamil': 'பட்டியல் விலை'},

    'type_message': {'English': 'Type a message...', 'Sinhala': 'පණිවිඩයක් ටයිප් කරන්න...', 'Tamil': 'செய்தியை தட்டச்சு செய்யவும்...'},
    'no_messages_yet': {'English': 'No messages yet — say hello!', 'Sinhala': 'තවම පණිවිඩ නැත — හෙලෝ කියන්න!', 'Tamil': 'இன்னும் செய்திகள் இல்லை — வணக்கம் சொல்லுங்கள்!'},
    'message_admin': {'English': 'Message admin...', 'Sinhala': 'පරිපාලකට පණිවිඩයක්...', 'Tamil': 'நிர்வாகிக்கு செய்தி...'},
    'no_admin_messages': {'English': 'No messages yet. Ask admin any questions here.', 'Sinhala': 'තවම පණිවිඩ නැත. ඕනෑම ප්‍රශ්නයක් මෙහි අහන්න.', 'Tamil': 'இன்னும் செய்திகள் இல்லை. இங்கே எந்த கேள்விகளையும் கேளுங்கள்.'},

    'get_verified': {'English': 'Get Verified', 'Sinhala': 'තහවුරු කරගන්න', 'Tamil': 'சரிபார்க்கப்படவும்'},
    'verification_pending': {'English': 'Verification Pending', 'Sinhala': 'තහවුරු කිරීම අපේක්ෂිතයි', 'Tamil': 'சரிபார்ப்பு நிலுவையில்'},
    'verified_seller': {'English': 'Verified Seller', 'Sinhala': 'තහවුරු කළ විකුණන්නා', 'Tamil': 'சரிபார்க்கப்பட்ட விற்பனையாளர்'},
    'get_blue_checkmark': {'English': 'Get the Blue Checkmark', 'Sinhala': 'නිල් සලකුණ ලබාගන්න', 'Tamil': 'நீல அடையாளத்தைப் பெறவும்'},
    'personal_details': {'English': 'Personal Details', 'Sinhala': 'පුද්ගලික විස්තර', 'Tamil': 'தனிப்பட்ட விவரங்கள்'},
    'full_name': {'English': 'Full Name (as on document)', 'Sinhala': 'සම්පූර්ණ නම (ලේඛනයේ ඇති පරිදි)', 'Tamil': 'முழு பெயர் (ஆவணத்தில் உள்ளபடி)'},
    'nic_number': {'English': 'NIC Number', 'Sinhala': 'ජාතික හැඳුනුම්පත් අංකය', 'Tamil': 'தேசிய அடையாள எண்'},
    'address_field': {'English': 'Address', 'Sinhala': 'ලිපිනය', 'Tamil': 'முகவரி'},
    'province': {'English': 'Province', 'Sinhala': 'පළාත', 'Tamil': 'மாகாணம்'},
    'district': {'English': 'District', 'Sinhala': 'දිස්ත්‍රික්කය', 'Tamil': 'மாவட்டம்'},
    'select_document_type': {'English': 'Select Document Type', 'Sinhala': 'ලේඛන වර්ගය තෝරන්න', 'Tamil': 'ஆவண வகையைத் தேர்ந்தெடுக்கவும்'},
    'driving_license': {'English': 'Driving License', 'Sinhala': 'රියදුරු බලපත්‍රය', 'Tamil': 'ஓட்டுநர் உரிமம்'},
    'submit_for_review': {'English': 'Submit for Review', 'Sinhala': 'සමාලෝචනය සඳහා ඉදිරිපත් කරන්න', 'Tamil': 'மறுஆய்வுக்கு சமர்ப்பிக்கவும்'},
    'take_selfie': {'English': 'Take a Selfie', 'Sinhala': 'සෙල්ෆියක් ගන්න', 'Tamil': 'செல்ஃபி எடுக்கவும்'},
  };
}
