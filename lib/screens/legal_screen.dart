import 'package:flutter/material.dart';
import '../main.dart';
import '../services/app_localizations.dart';

/// A policy is shown as a small number of topic cards, each with a short
/// intro and a bullet list, instead of a long wall of numbered paragraphs.
class _Topic {
  final IconData icon;
  final Map<String, String> title;
  final Map<String, String> intro;
  final Map<String, List<String>> points;
  const _Topic({required this.icon, required this.title, required this.intro, required this.points});
}

class LegalScreen extends StatelessWidget {
  final String type; // 'terms', 'privacy', or 'refund'
  const LegalScreen({super.key, required this.type});

  static const _lastUpdated = {
    'English': 'Last updated: September 2026',
    'Sinhala': 'අවසන් වරට යාවත්කාලීන කළේ: 2026 සැප්තැම්බර්',
    'Tamil': 'கடைசியாக புதுப்பிக்கப்பட்டது: செப்டம்பர் 2026',
  };

  String _title(String lang) {
    switch (type) {
      case 'terms':
        return {'English': 'Terms & Conditions', 'Sinhala': 'නියම හා කොන්දේසි', 'Tamil': 'விதிமுறைகள் மற்றும் நிபந்தனைகள்'}[lang]!;
      case 'refund':
        return {'English': 'Refund Policy', 'Sinhala': 'ආපසු ගෙවීමේ ප්‍රතිපත්තිය', 'Tamil': 'திரும்பப் பணம் கொடுக்கும் கொள்கை'}[lang]!;
      default:
        return {'English': 'Privacy Policy', 'Sinhala': 'රහස්‍යතා ප්‍රතිපත්තිය', 'Tamil': 'தனியுரிமைக் கொள்கை'}[lang]!;
    }
  }

  String _heading(String lang) {
    switch (type) {
      case 'terms':
        return {
          'English': 'MYGame Marketplace — Terms & Conditions',
          'Sinhala': 'MYGame Marketplace — නියම හා කොන්දේසි',
          'Tamil': 'MYGame Marketplace — விதிமுறைகள் மற்றும் நிபந்தனைகள்',
        }[lang]!;
      case 'refund':
        return {
          'English': 'MYGame Marketplace — Refund Policy',
          'Sinhala': 'MYGame Marketplace — ආපසු ගෙවීමේ ප්‍රතිපත්තිය',
          'Tamil': 'MYGame Marketplace — திரும்பப் பணம் கொடுக்கும் கொள்கை',
        }[lang]!;
      default:
        return {
          'English': 'MYGame Marketplace — Privacy Policy',
          'Sinhala': 'MYGame Marketplace — රහස්‍යතා ප්‍රතිපත්තිය',
          'Tamil': 'MYGame Marketplace — தனியுரிமைக் கொள்கை',
        }[lang]!;
    }
  }

  List<_Topic> get _topics {
    switch (type) {
      case 'terms':
        return _termsTopics;
      case 'refund':
        return _refundTopics;
      default:
        return _privacyTopics;
    }
  }

  // ======================================================================
  //  TERMS & CONDITIONS — 4 topics
  // ======================================================================
  static final List<_Topic> _termsTopics = [
    _Topic(
      icon: Icons.how_to_reg_outlined,
      title: const {
        'English': '1. Using MYGame Marketplace',
        'Sinhala': '1. MYGame Marketplace භාවිතය',
        'Tamil': '1. MYGame Marketplace-ஐப் பயன்படுத்துதல்',
      },
      intro: const {
        'English': 'By using the app you agree to these Terms. A few basic rules apply to every account:',
        'Sinhala': 'මෙම ඇප් එක භාවිතා කිරීමෙන් ඔබ මෙම නියමයන්ට එකඟ වේ. සෑම ගිණුමකටම මූලික නීති කිහිපයක් අදාළ වේ:',
        'Tamil': 'இந்த ஆப்பைப் பயன்படுத்துவதன் மூலம் நீங்கள் இந்த விதிமுறைகளை ஏற்கிறீர்கள். ஒவ்வொரு கணக்கிற்கும் சில அடிப்படை விதிகள் பொருந்தும்:',
      },
      points: const {
        'English': [
          'You must be at least 18 (or the age of majority where you live) to buy or sell.',
          'To sell, you must complete identity verification (NIC, Driving License, or Passport, plus a selfie/video if requested). False or fraudulent documents can lead to suspension and loss of pending funds.',
          'You are responsible for keeping your login details private and for everything done on your account.',
          'Game names, logos, and trademarks shown in the app (e.g. Free Fire, PUBG, Call of Duty Mobile, Mobile Legends) belong to their own publishers. MYGame Marketplace is independent and not affiliated with or endorsed by them.',
          'We may update these Terms from time to time; continuing to use the app after an update means you accept the changes.',
        ],
        'Sinhala': [
          'මිලදී ගැනීමට හෝ විකිණීමට ඔබට අවම වශයෙන් වයස අවුරුදු 18ක් (හෝ ඔබ ජීවත් වන රටේ නීතිමය වයස) විය යුතුය.',
          'විකිණීමට, ඔබ අනන්‍යතා සත්‍යාපනය සම්පූර්ණ කළ යුතුය (ජාතික හැඳුනුම්පත, රියදුරු බලපත්‍රය, හෝ විදේශ ගමන් බලපත්‍රය, අවශ්‍ය නම් සෙල්ෆි/වීඩියෝවක් සමඟ). වැරදි හෝ මංකොල්ලකාරී ලේඛන නිසා ගිණුම අත්හිටුවීමට සහ පොරොත්තු ලාභ අහිමි වීමට හේතු විය හැක.',
          'ඔබගේ ලොගින් තොරතුරු රහසිගතව තබා ගැනීමට සහ ඔබගේ ගිණුම යටතේ සිදු වන සියල්ලට ඔබ වගකිව යුතුය.',
          'ඇප් එකෙහි පෙන්වන ක්‍රීඩා නම්, ලාංඡන සහ වෙළඳ ලකුණු (උදා: Free Fire, PUBG, Call of Duty Mobile, Mobile Legends) ඒවායේ ප්‍රකාශකයන්ට අයත් වේ. MYGame Marketplace ස්වාධීන වන අතර ඔවුන් සමඟ සම්බන්ධ හෝ අනුමත කර නොමැත.',
          'අපි වරින් වර මෙම නියමයන් යාවත්කාලීන කළ හැක; යාවත්කාලීන කිරීමකින් පසුව ඇප් එක තවදුරටත් භාවිතා කිරීම එම වෙනස්කම් ඔබ පිළිගන්නා බව අදහස් කරයි.',
        ],
        'Tamil': [
          'வாங்க அல்லது விற்க நீங்கள் குறைந்தது 18 வயது (அல்லது நீங்கள் வசிக்கும் நாட்டின் முதிர்வயது) ஆக இருக்க வேண்டும்.',
          'விற்பதற்கு, நீங்கள் அடையாள சரிபார்ப்பை முடிக்க வேண்டும் (தேசிய அடையாள அட்டை, ஓட்டுநர் உரிமம், அல்லது கடவுச்சீட்டு, தேவைப்பட்டால் செல்ஃபி/வீடியோவுடன்). தவறான அல்லது மோசடி ஆவணங்கள் கணக்கு இடைநிறுத்தத்திற்கும் நிலுவையிலுள்ள நிதி இழப்பிற்கும் வழிவகுக்கும்.',
          'உங்கள் உள்நுழைவு விவரங்களை ரகசியமாக வைத்திருப்பதற்கும், உங்கள் கணக்கின் கீழ் நடக்கும் அனைத்திற்கும் நீங்களே பொறுப்பு.',
          'ஆப்பில் காட்டப்படும் விளையாட்டு பெயர்கள், லோகோக்கள் மற்றும் வர்த்தக முத்திரைகள் (எ.கா. Free Fire, PUBG, Call of Duty Mobile, Mobile Legends) அந்தந்த வெளியீட்டாளர்களுக்கு சொந்தமானவை. MYGame Marketplace சுயாதீனமானது, அவர்களுடன் இணைக்கப்படவில்லை.',
          'நாங்கள் அவ்வப்போது இந்த விதிமுறைகளை புதுப்பிக்கலாம்; புதுப்பிப்புக்குப் பிறகு ஆப்பைத் தொடர்ந்து பயன்படுத்துவது மாற்றங்களை ஏற்றுக்கொள்வதைக் குறிக்கும்.',
        ],
      },
    ),
    _Topic(
      icon: Icons.storefront_outlined,
      title: const {
        'English': '2. Buying, Selling & Escrow',
        'Sinhala': '2. මිලදී ගැනීම, විකිණීම සහ එස්ක්‍රෝ',
        'Tamil': '2. வாங்குதல், விற்பனை மற்றும் எஸ்க்ரோ',
      },
      intro: const {
        'English': 'Every purchase is protected by our escrow system:',
        'Sinhala': 'සෑම මිලදී ගැනීමක්ම අපගේ එස්ක්‍රෝ පද්ධතිය මගින් ආරක්ෂා වේ:',
        'Tamil': 'ஒவ்வொரு வாங்குதலும் எங்கள் எஸ்க்ரோ முறையால் பாதுகாக்கப்படுகிறது:',
      },
      points: const {
        'English': [
          'Sellers are responsible for the accuracy of their listing (rank, items, ownership history). A misleading listing can be removed and the account suspended.',
          'Your payment is held in escrow and is not released to the seller until you confirm the account, the review period ends without a dispute, or an admin resolves a dispute in the seller\'s favor.',
          'MYGame Marketplace charges a commission on each completed sale, shown to the seller before they list. Withdrawals may have fees or minimum amounts, shown in the app.',
          'Funds can be withheld or reversed if fraud or misrepresentation is found.',
        ],
        'Sinhala': [
          'ලැයිස්තුවේ නිරවද්‍යතාවයට (ශ්‍රේණිය, අයිතම, හිමිකාරිත්ව ඉතිහාසය) විකුණුම්කරු වගකිව යුතුය. නොමග යවන ලැයිස්තුවක් ඉවත් කර ගිණුම අත්හිටුවිය හැක.',
          'ඔබගේ ගෙවීම එස්ක්‍රෝහි තබා ගනු ලබන අතර, ඔබ ගිණුම තහවුරු කරන තුරු, විවාදයකින් තොරව සමාලෝචන කාලය අවසන් වන තුරු, හෝ පරිපාලකයෙක් විවාදයක් විකුණුම්කරු වෙනුවෙන් විසඳන තුරු එය විකුණුම්කරුට නිකුත් නොවේ.',
          'MYGame Marketplace සම්පූර්ණ කරන ලද සෑම විකිණීමකටම කොමිස් මුදලක් අය කරයි, එය ලැයිස්තුගත කිරීමට පෙර විකුණුම්කරුට පෙන්වයි. මුදල් ආපසු ගැනීම් සඳහා ගාස්තු හෝ අවම මුදල් ඇප් එකේ පෙන්වයි.',
          'වංචාවක් හෝ වැරදි ලෙස ඉදිරිපත් කිරීමක් හමු වුවහොත් මුදල් රඳවා තැබීමට හෝ ආපසු හැරවීමට හැක.',
        ],
        'Tamil': [
          'பட்டியலின் துல்லியத்திற்கு (தரம், பொருட்கள், உரிமை வரலாறு) விற்பனையாளர் பொறுப்பு. தவறான பட்டியல் அகற்றப்பட்டு கணக்கு இடைநிறுத்தப்படலாம்.',
          'உங்கள் பணம் எஸ்க்ரோவில் வைக்கப்படும், நீங்கள் கணக்கை உறுதிப்படுத்தும் வரை, சர்ச்சை இல்லாமல் மறுஆய்வு காலம் முடியும் வரை, அல்லது நிர்வாகி விற்பனையாளருக்கு சாதகமாக சர்ச்சையைத் தீர்க்கும் வரை விற்பனையாளருக்கு வழங்கப்படாது.',
          'MYGame Marketplace ஒவ்வொரு முடிக்கப்பட்ட விற்பனைக்கும் கமிஷன் வசூலிக்கிறது, இது பட்டியலிடும் முன் விற்பனையாளருக்குக் காட்டப்படும். திரும்பப் பெறுதலுக்கு கட்டணங்கள் அல்லது குறைந்தபட்ச தொகைகள் இருக்கலாம், ஆப்பில் காட்டப்படும்.',
          'மோசடி அல்லது தவறான தகவல் கண்டறியப்பட்டால் நிதி நிறுத்தி வைக்கப்படலாம் அல்லது திரும்பப் பெறப்படலாம்.',
        ],
      },
    ),
    _Topic(
      icon: Icons.gavel_outlined,
      title: const {
        'English': '3. Prohibited Activities & Enforcement',
        'Sinhala': '3. තහනම් ක්‍රියාකාරකම් සහ බලාත්මක කිරීම',
        'Tamil': '3. தடைசெய்யப்பட்ட செயல்பாடுகள் மற்றும் அமலாக்கம்',
      },
      intro: const {
        'English': 'To keep the marketplace safe, the following are not allowed:',
        'Sinhala': 'වෙළඳපොළ ආරක්ෂිතව තබා ගැනීමට, පහත සඳහන් දෑ අවසර නැත:',
        'Tamil': 'சந்தையை பாதுகாப்பாக வைத்திருக்க, பின்வருபவை அனுமதிக்கப்படாது:',
      },
      points: const {
        'English': [
          'Listing stolen, hacked, or unauthorized accounts.',
          'Fraud, phishing, or trying to bypass the escrow, verification, or dispute systems.',
          'Harassing or threatening other users or staff, or creating multiple accounts to evade a ban.',
          'Any of the above can result in immediate, permanent account termination without a refund.',
          'If a disagreement happens, either party can raise a dispute before the escrow period ends. Our admin team reviews the evidence (chat logs, screenshots, account access records) and makes a final decision — refunding the buyer, releasing funds to the seller, or another suitable action.',
        ],
        'Sinhala': [
          'සොරකම් කරන ලද, හැක් කරන ලද, හෝ අනවසර ගිණුම් ලැයිස්තුගත කිරීම.',
          'වංචාව, ෆිෂිං, හෝ එස්ක්‍රෝ, සත්‍යාපන, හෝ විවාද පද්ධති මගහැරීමට උත්සාහ කිරීම.',
          'වෙනත් පරිශීලකයන්ට හෝ කාර්ය මණ්ඩලයට හිරිහැර කිරීම හෝ තර්ජනය කිරීම, හෝ තහනමකින් මිදීමට බහු ගිණුම් සෑදීම.',
          'ඉහත ඕනෑම දෙයක් ආපසු ගෙවීමකින් තොරව ක්ෂණිකව, ස්ථිරව ගිණුම අවසන් කිරීමට හේතු විය හැක.',
          'මතභේදයක් ඇති වුවහොත්, එස්ක්‍රෝ කාලය අවසන් වීමට පෙර ඕනෑම පාර්ශවයකට විවාදයක් ඉදිරිපත් කළ හැක. අපගේ පරිපාලක කණ්ඩායම සාක්ෂි (චැට් ලොග්, තිර රුවා, ගිණුම් ප්‍රවේශ වාර්තා) සමාලෝචනය කර, මිලදී ගැනුම්කරුට ආපසු ගෙවීම, විකුණුම්කරුට මුදල් නිකුත් කිරීම, හෝ වෙනත් සුදුසු ක්‍රියාමාර්ගයක් ලෙස අවසාන තීරණයක් ගනී.',
        ],
        'Tamil': [
          'திருடப்பட்ட, ஹேக் செய்யப்பட்ட, அல்லது அங்கீகரிக்கப்படாத கணக்குகளைப் பட்டியலிடுவது.',
          'மோசடி, ஃபிஷிங், அல்லது எஸ்க்ரோ, சரிபார்ப்பு அல்லது சர்ச்சை முறைகளைத் தவிர்க்க முயற்சிப்பது.',
          'மற்ற பயனர்களை அல்லது ஊழியர்களை துன்புறுத்துவது அல்லது மிரட்டுவது, அல்லது தடையைத் தவிர்க்க பல கணக்குகளை உருவாக்குவது.',
          'மேற்கண்டவற்றில் ஏதேனும் ஒன்று திரும்பப் பணம் இல்லாமல் உடனடி, நிரந்தர கணக்கு நிறுத்தத்திற்கு வழிவகுக்கும்.',
          'கருத்து வேறுபாடு ஏற்பட்டால், எஸ்க்ரோ காலம் முடிவதற்குள் எந்த தரப்பினரும் சர்ச்சையை எழுப்பலாம். எங்கள் நிர்வாகக் குழு ஆதாரங்களை (அரட்டை பதிவுகள், ஸ்கிரீன்ஷாட்கள், கணக்கு அணுகல் பதிவுகள்) மறுஆய்வு செய்து, வாங்குபவருக்குத் திருப்பிச் செலுத்துதல், விற்பனையாளருக்கு நிதியை வெளியிடுதல், அல்லது வேறு பொருத்தமான நடவடிக்கை என இறுதி முடிவை எடுக்கும்.',
        ],
      },
    ),
    _Topic(
      icon: Icons.balance_outlined,
      title: const {
        'English': '4. Liability & Changes to These Terms',
        'Sinhala': '4. වගකීම සහ මෙම නියමයන් වෙනස් කිරීම',
        'Tamil': '4. பொறுப்பு மற்றும் இந்த விதிமுறைகளில் மாற்றங்கள்',
      },
      intro: const {
        'English': 'A few final points about how we\'re responsible, and how these Terms can change:',
        'Sinhala': 'අපගේ වගකීම සහ මෙම නියමයන් වෙනස් විය හැකි ආකාරය පිළිබඳ අවසාන කරුණු කිහිපයක්:',
        'Tamil': 'நாங்கள் எப்படி பொறுப்பு வகிக்கிறோம், இந்த விதிமுறைகள் எவ்வாறு மாறலாம் என்பது பற்றிய இறுதி சில குறிப்புகள்:',
      },
      points: const {
        'English': [
          'MYGame Marketplace is an intermediary platform connecting buyers and sellers — we verify identity and run escrow/dispute systems, but do not guarantee an account\'s long-term status beyond what our process covers.',
          'We are not liable for indirect or consequential damages, including in-game bans issued by a game publisher, or disputes raised after a transaction is already marked complete.',
          'These Terms are governed by the laws applicable where MYGame Marketplace operates.',
          'We may revise these Terms at any time; we\'ll make reasonable efforts to notify you of important changes in the app, and continued use after an update means you accept it.',
        ],
        'Sinhala': [
          'MYGame Marketplace යනු මිලදී ගැනුම්කරුවන් සහ විකුණුම්කරුවන් සම්බන්ධ කරන අතරමැදි වේදිකාවකි — අපි අනන්‍යතාව සත්‍යාපනය කර එස්ක්‍රෝ/විවාද පද්ධති ක්‍රියාත්මක කරමු, නමුත් අපගේ ක්‍රියාවලියෙන් ආවරණය වන දේට වඩා ගිණුමක දිගුකාලීන තත්ත්වය සහතික නොකරමු.',
          'ක්‍රීඩා ප්‍රකාශකයෙකු විසින් නිකුත් කරන ලද ක්‍රීඩාව තුළ තහනම් කිරීම් ඇතුළුව, හෝ ගනුදෙනුවක් දැනටමත් සම්පූර්ණ ලෙස සලකුණු කිරීමෙන් පසුව ඉදිරිපත් කරන ලද විවාද ඇතුළුව වක්‍ර හෝ ප්‍රතිවිපාක හානි සඳහා අපි වගකිව යුතු නොවේ.',
          'මෙම නියමයන් MYGame Marketplace ක්‍රියාත්මක වන ස්ථානයේ අදාළ නීති මගින් පාලනය වේ.',
          'අපි ඕනෑම වේලාවක මෙම නියමයන් සංශෝධනය කළ හැක; වැදගත් වෙනස්කම් ඇප් එකේ ඔබට දැනුම් දීමට සාධාරණ උත්සාහයක් ගන්නෙමු, යාවත්කාලීන කිරීමකින් පසුව දිගටම භාවිතා කිරීම ඔබ එය පිළිගන්නා බව අදහස් කරයි.',
        ],
        'Tamil': [
          'MYGame Marketplace என்பது வாங்குபவர்களையும் விற்பனையாளர்களையும் இணைக்கும் ஒரு இடைத்தரகர் தளம் — நாங்கள் அடையாளத்தை சரிபார்த்து எஸ்க்ரோ/சர்ச்சை முறைகளை இயக்குகிறோம், ஆனால் எங்கள் செயல்முறை உள்ளடக்குவதற்கு அப்பால் ஒரு கணக்கின் நீண்டகால நிலையை உத்தரவாதம் செய்யவில்லை.',
          'விளையாட்டு வெளியீட்டாளரால் வழங்கப்படும் விளையாட்டு தடைகள் உட்பட, அல்லது ஒரு பரிவர்த்தனை ஏற்கனவே முடிந்ததாகக் குறிக்கப்பட்ட பிறகு எழுப்பப்படும் சர்ச்சைகள் உட்பட மறைமுக அல்லது விளைவு சேதங்களுக்கு நாங்கள் பொறுப்பல்ல.',
          'இந்த விதிமுறைகள் MYGame Marketplace இயங்கும் இடத்தில் பொருந்தும் சட்டங்களால் நிர்வகிக்கப்படுகின்றன.',
          'நாங்கள் எந்த நேரத்திலும் இந்த விதிமுறைகளைத் திருத்தலாம்; முக்கியமான மாற்றங்களை ஆப்பில் உங்களுக்குத் தெரிவிக்க நியாயமான முயற்சி செய்வோம், புதுப்பிப்புக்குப் பிறகு தொடர்ந்து பயன்படுத்துவது நீங்கள் அதை ஏற்றுக்கொள்வதைக் குறிக்கும்.',
        ],
      },
    ),
  ];

  // ======================================================================
  //  PRIVACY POLICY — 4 topics
  // ======================================================================
  static final List<_Topic> _privacyTopics = [
    _Topic(
      icon: Icons.folder_shared_outlined,
      title: const {
        'English': '1. Information We Collect & Why',
        'Sinhala': '1. අප එකතු කරන තොරතුරු සහ ඇයි',
        'Tamil': '1. நாங்கள் சேகரிக்கும் தகவல் மற்றும் ஏன்',
      },
      intro: const {
        'English': 'We collect what\'s needed to run a safe marketplace, and use it for these purposes:',
        'Sinhala': 'ආරක්ෂිත වෙළඳපොළක් ක්‍රියාත්මක කිරීමට අවශ්‍ය දේ අපි එකතු කරන අතර, එය මෙම කාර්යයන් සඳහා භාවිතා කරමු:',
        'Tamil': 'பாதுகாப்பான சந்தையை இயக்க தேவையானதை நாங்கள் சேகரிக்கிறோம், அதை இந்த நோக்கங்களுக்காகப் பயன்படுத்துகிறோம்:',
      },
      points: const {
        'English': [
          'Account details you give us: name, email, phone, profile photo, and bank/payment details for withdrawals.',
          'Verification documents: NIC, Driving License, or Passport, plus a selfie or short video when required.',
          'Technical data: device identifiers, app usage, IP address, and transaction history.',
          'Used to: create and manage your account, verify identity and prevent fraud, process purchases/sales/escrow/withdrawals, send order and security notifications, investigate disputes, and improve the app.',
        ],
        'Sinhala': [
          'ඔබ අපට දෙන ගිණුම් විස්තර: නම, විද්‍යුත් තැපෑල, දුරකථන අංකය, පැතිකඩ ඡායාරූපය, සහ මුදල් ආපසු ගැනීම් සඳහා බැංකු/ගෙවීම් විස්තර.',
          'සත්‍යාපන ලේඛන: ජාතික හැඳුනුම්පත, රියදුරු බලපත්‍රය, හෝ විදේශ ගමන් බලපත්‍රය, අවශ්‍ය විටෙක සෙල්ෆි එකක් හෝ කෙටි වීඩියෝවක් සමඟ.',
          'තාක්ෂණික දත්ත: උපාංග හඳුනාගැනීම්, ඇප් භාවිතය, IP ලිපිනය, සහ ගනුදෙනු ඉතිහාසය.',
          'භාවිතා කරන්නේ: ඔබගේ ගිණුම සෑදීමට සහ කළමනාකරණය කිරීමට, අනන්‍යතාව සත්‍යාපනය කර වංචා වළක්වා ගැනීමට, මිලදී ගැනීම්/විකිණීම්/එස්ක්‍රෝ/මුදල් ආපසු ගැනීම් සකසන්නට, ඇණවුම් සහ ආරක්ෂක දැනුම්දීම් යැවීමට, විවාද විමර්ශනය කිරීමට, සහ ඇප් එක වැඩිදියුණු කිරීමට.',
        ],
        'Tamil': [
          'நீங்கள் எங்களுக்குக் கொடுக்கும் கணக்கு விவரங்கள்: பெயர், மின்னஞ்சல், தொலைபேசி எண், சுயவிவரப் புகைப்படம், மற்றும் திரும்பப் பெறுதலுக்கான வங்கி/பணம் செலுத்தும் விவரங்கள்.',
          'சரிபார்ப்பு ஆவணங்கள்: தேசிய அடையாள அட்டை, ஓட்டுநர் உரிமம், அல்லது கடவுச்சீட்டு, தேவைப்படும் போது செல்ஃபி அல்லது குறுகிய வீடியோவுடன்.',
          'தொழில்நுட்ப தரவு: சாதன அடையாளங்கள், ஆப் பயன்பாடு, IP முகவரி, மற்றும் பரிவர்த்தனை வரலாறு.',
          'பயன்படுத்தப்படுவது: உங்கள் கணக்கை உருவாக்கி நிர்வகிக்க, அடையாளத்தை சரிபார்த்து மோசடியைத் தடுக்க, வாங்குதல்/விற்பனை/எஸ்க்ரோ/திரும்பப் பெறுதலைச் செயல்படுத்த, ஆர்டர் மற்றும் பாதுகாப்பு அறிவிப்புகளை அனுப்ப, சர்ச்சைகளை விசாரிக்க, மற்றும் ஆப்பை மேம்படுத்த.',
        ],
      },
    ),
    _Topic(
      icon: Icons.lock_outline,
      title: const {
        'English': '2. Storage, Sharing & Verification Documents',
        'Sinhala': '2. ගබඩා කිරීම, බෙදාගැනීම සහ සත්‍යාපන ලේඛන',
        'Tamil': '2. சேமிப்பு, பகிர்வு மற்றும் சரிபார்ப்பு ஆவணங்கள்',
      },
      intro: const {
        'English': 'How your data is kept, and who can see it:',
        'Sinhala': 'ඔබගේ දත්ත තබා ගන්නා ආකාරය සහ එය දැකිය හැක්කේ කාට ද:',
        'Tamil': 'உங்கள் தரவு எவ்வாறு வைக்கப்படுகிறது, யார் அதைப் பார்க்க முடியும்:',
      },
      points: const {
        'English': [
          'Stored securely for as long as your account is active, and for a reasonable period after for legal, dispute, and record-keeping purposes.',
          'We never sell your personal information.',
          'Account login credentials are shared with a buyer only after their payment is confirmed and held in escrow.',
          'Verification documents (NIC/License/Passport, selfies, videos) are encrypted where applicable and only accessible to authorized admins for identity checks — never shared with other users.',
          'We may disclose information when required by law, to protect user safety, or to prevent fraud.',
        ],
        'Sinhala': [
          'ඔබගේ ගිණුම ක්‍රියාකාරී තාක් සහ නීතිමය, විවාද, සහ වාර්තා තබා ගැනීමේ අරමුණු සඳහා සාධාරණ කාලයක් පසුව ආරක්ෂිතව ගබඩා කර ඇත.',
          'අපි ඔබගේ පුද්ගලික තොරතුරු කිසි විටෙක විකුණන්නේ නැත.',
          'ගිණුම් පිවිසුම් තොරතුරු මිලදී ගැනුම්කරුවෙකුට බෙදාගන්නේ ඔවුන්ගේ ගෙවීම තහවුරු කර එස්ක්‍රෝහි තබා ගත් පසුව පමණි.',
          'සත්‍යාපන ලේඛන (ජාතික හැඳුනුම්පත/බලපත්‍රය/විදේශ ගමන් බලපත්‍රය, සෙල්ෆි, වීඩියෝ) අදාළ තැන් වල සංකේතනය කර ඇති අතර, අනන්‍යතා පරීක්ෂා කිරීම් සඳහා අනුමත පරිපාලකයන්ට පමණක් ප්‍රවේශ විය හැක — වෙනත් පරිශීලකයන් සමඟ කිසි විටෙකත් බෙදා නොගනී.',
          'නීතියෙන් අවශ්‍ය වූ විට, පරිශීලක ආරක්ෂාව සුරැකීමට, හෝ වංචා වළක්වා ගැනීමට අපට තොරතුරු හෙළිදරව් කිරීමට සිදු විය හැක.',
        ],
        'Tamil': [
          'உங்கள் கணக்கு செயலில் இருக்கும் வரை, மற்றும் சட்ட, சர்ச்சை, பதிவு பராமரிப்பு நோக்கங்களுக்காக நியாயமான காலத்திற்குப் பிறகும் பாதுகாப்பாக சேமிக்கப்படும்.',
          'நாங்கள் உங்கள் தனிப்பட்ட தகவலை ஒருபோதும் விற்பதில்லை.',
          'கணக்கு உள்நுழைவு விவரங்கள் வாங்குபவரின் பணம் உறுதிப்படுத்தப்பட்டு எஸ்க்ரோவில் வைக்கப்பட்ட பிறகுதான் பகிரப்படும்.',
          'சரிபார்ப்பு ஆவணங்கள் (தேசிய அடையாள அட்டை/உரிமம்/கடவுச்சீட்டு, செல்ஃபி, வீடியோ) பொருந்தும் இடங்களில் குறியாக்கம் செய்யப்பட்டு, அடையாள சோதனைகளுக்காக அங்கீகரிக்கப்பட்ட நிர்வாகிகளுக்கு மட்டுமே அணுகக்கூடியது — மற்ற பயனர்களுடன் ஒருபோதும் பகிரப்படாது.',
          'சட்டப்படி தேவைப்படும் போது, பயனர் பாதுகாப்பைப் பாதுகாக்க, அல்லது மோசடியைத் தடுக்க நாங்கள் தகவலை வெளியிடலாம்.',
        ],
      },
    ),
    _Topic(
      icon: Icons.shield_outlined,
      title: const {
        'English': '3. Your Rights, Notifications & Security',
        'Sinhala': '3. ඔබගේ අයිතිවාසිකම්, දැනුම්දීම් සහ ආරක්ෂාව',
        'Tamil': '3. உங்கள் உரிமைகள், அறிவிப்புகள் மற்றும் பாதுகாப்பு',
      },
      intro: const {
        'English': 'You stay in control of your data and notifications:',
        'Sinhala': 'ඔබගේ දත්ත සහ දැනුම්දීම් පිළිබඳ පාලනය ඔබ සතුව පවතී:',
        'Tamil': 'உங்கள் தரவு மற்றும் அறிவிப்புகள் மீதான கட்டுப்பாடு உங்களிடமே உள்ளது:',
      },
      points: const {
        'English': [
          'You can request access to, correction of, or deletion of your data (subject to legal record-keeping needs) via "Report a Problem" or "Live Chat with Admin" in Settings.',
          'You can manage notification preferences (order, security, promotional) from Settings.',
          'We use encryption and role-based access to protect sensitive data such as escrow credentials, but no system is 100% secure.',
          'MYGame Marketplace is not intended for anyone under 18. If we learn a minor has given us data, we delete it and close the account.',
        ],
        'Sinhala': [
          'සැකසුම් තුළ "ගැටලුවක් වාර්තා කරන්න" හෝ "පරිපාලක සමඟ සජීවී කතාබහ" හරහා ඔබගේ දත්ත වෙත ප්‍රවේශය, නිවැරදි කිරීම, හෝ මකා දැමීම (නීතිමය වාර්තා තබා ගැනීමේ අවශ්‍යතාවලට යටත්ව) ඉල්ලා සිටිය හැක.',
          'සැකසුම් වලින් ඔබට දැනුම්දීම් අභිප්‍රේත (ඇණවුම්, ආරක්ෂක, ප්‍රවර්ධන) කළමනාකරණය කළ හැක.',
          'එස්ක්‍රෝ අක්තපත්‍ර වැනි සංවේදී දත්ත ආරක්ෂා කිරීමට අපි සංකේතනය සහ භූමිකා පදනම් කරගත් ප්‍රවේශය භාවිතා කරමු, නමුත් කිසිදු පද්ධතියක් 100% ආරක්ෂිත නොවේ.',
          'MYGame Marketplace වයස අවුරුදු 18ට අඩු කිසිවෙකු සඳහා අදහස් කර නොමැත. නාबාලකයෙකු අපට දත්ත ලබා දී ඇති බව අප දැන ගතහොත්, අපි එය මකා දමා ගිණුම වසා දමමු.',
        ],
        'Tamil': [
          'அமைப்புகளில் "சிக்கலைப் புகாரளி" அல்லது "நிர்வாகியுடன் நேரடி அரட்டை" மூலம் உங்கள் தரவை அணுகவும், திருத்தவும், நீக்கவும் (சட்ட பதிவு தேவைகளுக்கு உட்பட்டு) கோரலாம்.',
          'அமைப்புகளில் இருந்து அறிவிப்பு விருப்பங்களை (ஆர்டர், பாதுகாப்பு, விளம்பரம்) நிர்வகிக்கலாம்.',
          'எஸ்க்ரோ சான்றுகள் போன்ற முக்கியமான தரவைப் பாதுகாக்க நாங்கள் குறியாக்கம் மற்றும் பங்கு அடிப்படையிலான அணுகலைப் பயன்படுத்துகிறோம், ஆனால் எந்த அமைப்பும் 100% பாதுகாப்பானது அல்ல.',
          'MYGame Marketplace 18 வயதுக்குட்பட்ட எவருக்கும் நோக்கம் கொள்ளப்படவில்லை. ஒரு சிறார் எங்களுக்கு தரவு கொடுத்திருப்பதை நாங்கள் அறிந்தால், அதை நீக்கி கணக்கை மூடுவோம்.',
        ],
      },
    ),
    _Topic(
      icon: Icons.public_outlined,
      title: const {
        'English': '4. International Handling, Changes & Contact',
        'Sinhala': '4. ජාත්‍යන්තර හැසිරවීම, වෙනස්කම් සහ සම්බන්ධතා',
        'Tamil': '4. சர்வதேச கையாளுதல், மாற்றங்கள் மற்றும் தொடர்பு',
      },
      intro: const {
        'English': 'A few closing notes:',
        'Sinhala': 'අවසාන සටහන් කිහිපයක්:',
        'Tamil': 'சில இறுதி குறிப்புகள்:',
      },
      points: const {
        'English': [
          'If you access the app from outside the country where our servers are located, your data may be processed there instead — using the app means you agree to this.',
          'We may update this Privacy Policy; we\'ll make reasonable efforts to notify you of important changes in the app.',
          'Questions about this policy or your data can be sent through "Report a Problem" or "Live Chat with Admin" in Settings.',
        ],
        'Sinhala': [
          'අපගේ සර්වර් පිහිටා ඇති රටෙන් පිටත සිට ඔබ ඇප් එකට ප්‍රවේශ වන්නේ නම්, ඔබගේ දත්ත ඒ වෙනුවට එහි සැකසිය හැක — ඇප් එක භාවිතා කිරීම මින් ඔබ එකඟ වන බව අදහස් කරයි.',
          'අපි මෙම රහස්‍යතා ප්‍රතිපත්තිය යාවත්කාලීන කළ හැක; වැදගත් වෙනස්කම් ඇප් එකේ ඔබට දැනුම් දීමට සාධාරණ උත්සාහයක් ගන්නෙමු.',
          'මෙම ප්‍රතිපත්තිය හෝ ඔබගේ දත්ත පිළිබඳ ප්‍රශ්න සැකසුම් තුළ "ගැටලුවක් වාර්තා කරන්න" හෝ "පරිපාලක සමඟ සජීවී කතාබහ" හරහා යැවිය හැක.',
        ],
        'Tamil': [
          'எங்கள் சேவையகங்கள் அமைந்துள்ள நாட்டிற்கு வெளியே இருந்து நீங்கள் ஆப்பை அணுகினால், உங்கள் தரவு அங்கு செயலாக்கப்படலாம் — ஆப்பைப் பயன்படுத்துவது நீங்கள் இதை ஏற்றுக்கொள்வதைக் குறிக்கும்.',
          'நாங்கள் இந்த தனியுரிமைக் கொள்கையை புதுப்பிக்கலாம்; முக்கியமான மாற்றங்களை ஆப்பில் உங்களுக்குத் தெரிவிக்க நியாயமான முயற்சி செய்வோம்.',
          'இந்த கொள்கை அல்லது உங்கள் தரவு பற்றிய கேள்விகளை அமைப்புகளில் உள்ள "சிக்கலைப் புகாரளி" அல்லது "நிர்வாகியுடன் நேரடி அரட்டை" மூலம் அனுப்பலாம்.',
        ],
      },
    ),
  ];

  // ======================================================================
  //  REFUND POLICY — 4 topics
  // ======================================================================
  static final List<_Topic> _refundTopics = [
    _Topic(
      icon: Icons.verified_user_outlined,
      title: const {
        'English': '1. Escrow Protection & When a Refund Applies',
        'Sinhala': '1. එස්ක්‍රෝ ආරක්ෂාව සහ ආපසු ගෙවීම අදාළ වන අවස්ථා',
        'Tamil': '1. எஸ்க்ரோ பாதுகாப்பு மற்றும் திரும்பப் பணம் எப்போது பொருந்தும்',
      },
      intro: const {
        'English': 'Every order is protected before a refund is ever needed:',
        'Sinhala': 'ආපසු ගෙවීමක් අවශ්‍ය වීමට පෙර සෑම ඇණවුමක්ම ආරක්ෂා කර ඇත:',
        'Tamil': 'திரும்பப் பணம் தேவைப்படுவதற்கு முன்பே ஒவ்வொரு ஆர்டரும் பாதுகாக்கப்படுகிறது:',
      },
      points: const {
        'English': [
          'Your payment is held in escrow until you confirm the account, the review period ends without a dispute, or an admin resolves a dispute in your favor.',
          'A refund may be given if: the seller doesn\'t deliver in time, the account doesn\'t match the listing (wrong rank/items/ownership), the account is reclaimed or banned shortly after handover, or the seller is found to have committed fraud.',
          'Every refund decision is made after reviewing the evidence submitted by both sides.',
        ],
        'Sinhala': [
          'ඔබ ගිණුම තහවුරු කරන තුරු, විවාදයකින් තොරව සමාලෝචන කාලය අවසන් වන තුරු, හෝ පරිපාලකයෙක් විවාදයක් ඔබ වෙනුවෙන් විසඳන තුරු ඔබගේ ගෙවීම එස්ක්‍රෝහි තබා ගනී.',
          'ආපසු ගෙවීමක් ලබා දිය හැක්කේ: විකුණුම්කරු වේලාවට භාරදීමට අසමත් වූ විට, ගිණුම ලැයිස්තුවට නොගැලපෙන විට (වැරදි ශ්‍රේණිය/අයිතම/හිමිකාරිත්වය), භාරදීමෙන් ටික වේලාවකට පසු ගිණුම ආපසු ලබා ගත් හෝ තහනම් කළ විට, හෝ විකුණුම්කරු වංචාවක් සිදු කර ඇති බව හමු වූ විට.',
          'සෑම ආපසු ගෙවීමේ තීරණයක්ම දෙපාර්ශවයෙන්ම ඉදිරිපත් කරන ලද සාක්ෂි සමාලෝචනය කිරීමෙන් පසුව ගනු ලැබේ.',
        ],
        'Tamil': [
          'நீங்கள் கணக்கை உறுதிப்படுத்தும் வரை, சர்ச்சை இல்லாமல் மறுஆய்வு காலம் முடியும் வரை, அல்லது நிர்வாகி உங்களுக்கு சாதகமாக சர்ச்சையைத் தீர்க்கும் வரை உங்கள் பணம் எஸ்க்ரோவில் வைக்கப்படும்.',
          'திரும்பப் பணம் வழங்கப்படலாம்: விற்பனையாளர் நேரத்திற்குள் வழங்கத் தவறினால், கணக்கு பட்டியலுடன் பொருந்தவில்லை என்றால் (தவறான தரம்/பொருட்கள்/உரிமை), ஒப்படைத்த சிறிது நேரத்திலேயே கணக்கு மீட்கப்பட்டால் அல்லது தடை செய்யப்பட்டால், அல்லது விற்பனையாளர் மோசடி செய்ததாகக் கண்டறியப்பட்டால்.',
          'ஒவ்வொரு திரும்பப் பணம் முடிவும் இரு தரப்பினரும் சமர்ப்பித்த ஆதாரங்களை மறுஆய்வு செய்த பிறகே எடுக்கப்படும்.',
        ],
      },
    ),
    _Topic(
      icon: Icons.support_agent_outlined,
      title: const {
        'English': '2. How to Request a Refund & How You\'re Paid',
        'Sinhala': '2. ආපසු ගෙවීමක් ඉල්ලා සිටින්නේ කෙසේද සහ ගෙවනු ලබන ආකාරය',
        'Tamil': '2. திரும்பப் பணம் கோருவது எப்படி & பணம் எப்படி வழங்கப்படும்',
      },
      intro: const {
        'English': 'What to do if something goes wrong, and where the money goes:',
        'Sinhala': 'යමක් වැරදුනහොත් කුමක් කළ යුතුද සහ මුදල් යන්නේ කොහාට ද:',
        'Tamil': 'ஏதேனும் தவறு நடந்தால் என்ன செய்வது, பணம் எங்கு செல்கிறது:',
      },
      points: const {
        'English': [
          'Raise a dispute from the order details screen before the escrow period ends, with clear evidence (screenshots, chat logs, login attempts).',
          'Requests made after the escrow period ends and funds are released to the seller cannot be guaranteed.',
          'Approved refunds go to your MYGame Marketplace wallet balance — not directly back to your original payment method.',
          'You can then withdraw from your wallet using your saved bank/payment details, subject to normal processing times.',
        ],
        'Sinhala': [
          'එස්ක්‍රෝ කාලය අවසන් වීමට පෙර, පැහැදිලි සාක්ෂි (තිර රුවා, චැට් ලොග්, පිවිසුම් උත්සාහයන්) සමඟ ඇණවුම් විස්තර තිරයෙන් විවාදයක් ඉදිරිපත් කරන්න.',
          'එස්ක්‍රෝ කාලය අවසන් වී විකුණුම්කරුට මුදල් නිකුත් කිරීමෙන් පසුව කරන ලද ඉල්ලීම් සහතික කළ නොහැක.',
          'අනුමත ආපසු ගෙවීම් ඔබගේ MYGame Marketplace මුදල් පසුම්බි ශේෂයට යයි — ඔබගේ මුල් ගෙවීම් ක්‍රමයට කෙලින්ම ආපසු නොයයි.',
          'ඉන්පසු ඔබට සාමාන්‍ය සැකසුම් කාලයන්ට යටත්ව ඔබගේ සුරැකි බැංකු/ගෙවීම් විස්තර භාවිතයෙන් පසුම්බියෙන් ආපසු ගත හැක.',
        ],
        'Tamil': [
          'எஸ்க்ரோ காலம் முடிவதற்குள், தெளிவான ஆதாரங்களுடன் (ஸ்கிரீன்ஷாட்கள், அரட்டை பதிவுகள், உள்நுழைவு முயற்சிகள்) ஆர்டர் விவரங்கள் திரையிலிருந்து சர்ச்சையை எழுப்பவும்.',
          'எஸ்க்ரோ காலம் முடிந்து விற்பனையாளருக்கு நிதி வழங்கப்பட்ட பிறகு செய்யப்படும் கோரிக்கைகளுக்கு உத்தரவாதம் அளிக்க முடியாது.',
          'அங்கீகரிக்கப்பட்ட திரும்பப் பணம் உங்கள் MYGame Marketplace வாலட் இருப்புக்குச் செல்லும் — உங்கள் அசல் பணம் செலுத்தும் முறைக்கு நேரடியாகச் செல்லாது.',
          'பின்னர் நீங்கள் சாதாரண செயலாக்க நேரங்களுக்கு உட்பட்டு, உங்கள் சேமிக்கப்பட்ட வங்கி/பணம் செலுத்தும் விவரங்களைப் பயன்படுத்தி வாலட்டில் இருந்து திரும்பப் பெறலாம்.',
        ],
      },
    ),
    _Topic(
      icon: Icons.block_outlined,
      title: const {
        'English': '3. When Refunds Are Not Given',
        'Sinhala': '3. ආපසු ගෙවීම් ලබා නොදෙන අවස්ථා',
        'Tamil': '3. திரும்பப் பணம் வழங்கப்படாத சூழ்நிலைகள்',
      },
      intro: const {
        'English': 'Refunds are generally not given if:',
        'Sinhala': 'සාමාන්‍යයෙන් ආපසු ගෙවීම් ලබා නොදෙනුයේ:',
        'Tamil': 'பொதுவாக பின்வரும் சூழ்நிலைகளில் திரும்பப் பணம் வழங்கப்படாது:',
      },
      points: const {
        'English': [
          'You simply changed your mind after a successful, verified handover.',
          'The account was delivered as described, but you delayed changing the password/securing it, and it was reclaimed as a result.',
          'The issue is a ban or suspension issued by the game publisher, unrelated to the account\'s ownership history.',
          'You violated the Terms & Conditions during the transaction.',
        ],
        'Sinhala': [
          'සාර්ථක, තහවුරු කරන ලද භාරදීමකින් පසු ඔබ හුදෙක් අදහස වෙනස් කර ගත් විට.',
          'ගිණුම විස්තර කළ ආකාරයටම භාර දුන් නමුත්, ඔබ මුරපදය වෙනස් කිරීම/එය ආරක්ෂා කිරීම ප්‍රමාද කළ අතර, එහි ප්‍රතිඵලයක් ලෙස එය ආපසු ලබා ගත් විට.',
          'ගැටලුව ගිණුමේ හිමිකාරිත්ව ඉතිහාසයට සම්බන්ධ නොවන, ක්‍රීඩා ප්‍රකාශකයා විසින් නිකුත් කරන ලද තහනමක් හෝ අත්හිටුවීමක් වූ විට.',
          'ගනුදෙනුව අතරතුර ඔබ නියම හා කොන්දේසි උල්ලංඝනය කළ විට.',
        ],
        'Tamil': [
          'வெற்றிகரமான, சரிபார்க்கப்பட்ட ஒப்படைப்புக்குப் பிறகு நீங்கள் வெறுமனே மனதை மாற்றிக்கொண்டால்.',
          'கணக்கு விவரிக்கப்பட்டபடி வழங்கப்பட்டது, ஆனால் நீங்கள் கடவுச்சொல்லை மாற்றுவதை/பாதுகாப்பதை தாமதப்படுத்தியதால் அது மீட்கப்பட்டது.',
          'சிக்கல் கணக்கின் உரிமை வரலாற்றுடன் தொடர்பில்லாத, விளையாட்டு வெளியீட்டாளரால் வழங்கப்பட்ட தடை அல்லது இடைநிறுத்தமாக இருந்தால்.',
          'பரிவர்த்தனையின் போது நீங்கள் விதிமுறைகள் மற்றும் நிபந்தனைகளை மீறினால்.',
        ],
      },
    ),
    _Topic(
      icon: Icons.receipt_long_outlined,
      title: const {
        'English': '4. Fees on Refunds, Final Decisions & Changes',
        'Sinhala': '4. ආපසු ගෙවීම් මත ගාස්තු, අවසාන තීරණ සහ වෙනස්කම්',
        'Tamil': '4. திரும்பப் பணத்தில் கட்டணங்கள், இறுதி முடிவுகள் மற்றும் மாற்றங்கள்',
      },
      intro: const {
        'English': 'How commission is handled, and what happens after a decision:',
        'Sinhala': 'කොමිස් හසුරුවනු ලබන ආකාරය සහ තීරණයකින් පසු සිදුවන දේ:',
        'Tamil': 'கமிஷன் எவ்வாறு கையாளப்படுகிறது, ஒரு முடிவுக்குப் பிறகு என்ன நடக்கும்:',
      },
      points: const {
        'English': [
          'If a refund is approved due to a seller-side issue (non-delivery, misrepresentation, fraud), our commission on that sale is reversed in full.',
          'For a goodwill or shared-fault resolution, commission may be adjusted proportionally at the admin team\'s discretion.',
          'Refund and dispute decisions are based on the evidence available at the time and are final; you may reopen a case if new evidence appears, via "Report a Problem" or "Live Chat with Admin".',
          'We may update this Refund Policy from time to time; continued use of the app after an update means you accept the changes.',
        ],
        'Sinhala': [
          'විකුණුම්කරු පාර්ශවයේ ගැටලුවක් (භාරදීම නොකිරීම, වැරදි ලෙස ඉදිරිපත් කිරීම, වංචාව) හේතුවෙන් ආපසු ගෙවීමක් අනුමත කළහොත්, එම විකිණීම මත අපගේ කොමිස් සම්පූර්ණයෙන්ම ආපසු හරවනු ලැබේ.',
          'සද්භාවයෙන් හෝ බෙදාගත් වරදකාරී විසඳුමක් සඳහා, පරිපාලක කණ්ඩායමේ අභිමතය පරිදි කොමිස් සමානුපාතිකව සකස් කළ හැක.',
          'ආපසු ගෙවීම් සහ විවාද තීරණ එම වේලාවේ ලබා ගත හැකි සාක්ෂි මත පදනම් වන අතර අවසන් ය; නව සාක්ෂි පෙනී ගියහොත් ඔබට "ගැටලුවක් වාර්තා කරන්න" හෝ "පරිපාලක සමඟ සජීවී කතාබහ" හරහා නඩුව නැවත විවෘත කළ හැක.',
          'අපි වරින් වර මෙම ආපසු ගෙවීමේ ප්‍රතිපත්තිය යාවත්කාලීන කළ හැක; යාවත්කාලීන කිරීමකින් පසුව ඇප් එක දිගටම භාවිතා කිරීම එම වෙනස්කම් ඔබ පිළිගන්නා බව අදහස් කරයි.',
        ],
        'Tamil': [
          'விற்பனையாளர் தரப்பு சிக்கல் (வழங்காமை, தவறான தகவல், மோசடி) காரணமாக திரும்பப் பணம் அங்கீகரிக்கப்பட்டால், அந்த விற்பனையின் மீதான எங்கள் கமிஷன் முழுவதுமாக திரும்பப் பெறப்படும்.',
          'நல்லெண்ண அல்லது பகிரப்பட்ட தவறு தீர்வுக்கு, நிர்வாகக் குழுவின் விருப்பப்படி கமிஷன் விகிதாசாரமாக சரிசெய்யப்படலாம்.',
          'திரும்பப் பணம் மற்றும் சர்ச்சை முடிவுகள் அந்த நேரத்தில் கிடைக்கக்கூடிய ஆதாரங்களின் அடிப்படையில் இறுதியானவை; புதிய ஆதாரம் கிடைத்தால் "சிக்கலைப் புகாரளி" அல்லது "நிர்வாகியுடன் நேரடி அரட்டை" மூலம் வழக்கை மீண்டும் திறக்கலாம்.',
          'நாங்கள் இந்த திரும்பப் பணக் கொள்கையை அவ்வப்போது புதுப்பிக்கலாம்; புதுப்பிப்புக்குப் பிறகு ஆப்பைத் தொடர்ந்து பயன்படுத்துவது மாற்றங்களை ஏற்றுக்கொள்வதைக் குறிக்கும்.',
        ],
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        final l = ['English', 'Sinhala', 'Tamil'].contains(lang) ? lang : 'English';
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(_title(l))),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _heading(l),
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(_lastUpdated[l]!, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                const SizedBox(height: 20),
                ..._topics.map((t) => _topicCard(t, l)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topicCard(_Topic t, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(t.icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.title[lang]!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(t.intro[lang]!, style: const TextStyle(color: AppColors.hint, fontSize: 13, height: 1.5)),
          const SizedBox(height: 10),
          ...t.points[lang]!.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 8),
                      child: Icon(Icons.circle, size: 5, color: AppColors.primary),
                    ),
                    Expanded(
                      child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
