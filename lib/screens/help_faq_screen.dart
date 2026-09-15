import 'package:flutter/material.dart';
import '../main.dart';
import '../services/app_localizations.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  static const List<Map<String, Map<String, String>>> _faqs = [
    {
      'q': {
        'English': 'How do I buy a game account?',
        'Sinhala': 'ගේම් ගිණුමක් මම මිලදී ගන්නේ කෙසේද?',
        'Tamil': 'நான் எவ்வாறு ஒரு கேம் கணக்கை வாங்குவது?',
      },
      'a': {
        'English': 'Browse listings, tap on an account you like, and tap "Buy Now" or make an offer. Once payment is confirmed, the funds go into escrow and the seller releases the account credentials to you.',
        'Sinhala': 'ලැයිස්තු බලන්න, ඔබ කැමති ගිණුමක් තට්ටු කර "Buy Now" තට්ටු කරන්න හෝ offer එකක් දෙන්න. ගෙවීම තහවුරු වූ පසු, මුදල් escrow තුළ තැන්පත් වන අතර විකුණුම්කරු ගිණුමේ credentials ඔබට ලබා දෙයි.',
        'Tamil': 'பட்டியல்களை உலாவவும், நீங்கள் விரும்பும் கணக்கை தட்டி "Buy Now" ஐ தட்டவும் அல்லது ஒரு சலுகையை வழங்கவும். கட்டணம் உறுதிப்படுத்தப்பட்டதும், நிதி escrow இல் செல்கிறது, விற்பனையாளர் கணக்கு விவரங்களை உங்களுக்கு வழங்குகிறார்.',
      },
    },
    {
      'q': {
        'English': 'How does escrow protect me?',
        'Sinhala': 'escrow මගින් මාව ආරක්ෂා කරන්නේ කෙසේද?',
        'Tamil': 'escrow என்னை எவ்வாறு பாதுகாக்கிறது?',
      },
      'a': {
        'English': 'When you pay for an account, your money is held safely by MYGame Marketplace instead of going directly to the seller. It is only released to the seller after the order is confirmed complete or after the review period ends without a dispute.',
        'Sinhala': 'ඔබ ගිණුමක් සඳහා ගෙවන විට, ඔබේ මුදල් කෙලින්ම විකුණුම්කරුට යනවා වෙනුවට MYGame Marketplace විසින් ආරක්ෂිතව තබා ගනියි. Order එක සම්පූර්ණ බව තහවුරු වූ පසු හෝ dispute එකක් නොමැතිව review කාලය අවසන් වූ පසු එය විකුණුම්කරුට නිකුත් කරයි.',
        'Tamil': 'நீங்கள் ஒரு கணக்குக்கு பணம் செலுத்தும்போது, உங்கள் பணம் நேரடியாக விற்பனையாளரிடம் செல்வதற்கு பதிலாக MYGame Marketplace ஆல் பாதுகாப்பாக வைக்கப்படுகிறது. ஆர்டர் முடிந்தது என உறுதிப்படுத்தப்பட்ட பிறகு அல்லது சர்ச்சை இல்லாமல் மதிப்பாய்வு காலம் முடிந்த பிறகு மட்டுமே அது விற்பனையாளருக்கு வழங்கப்படும்.',
      },
    },
    {
      'q': {
        'English': 'How do I sell my game account?',
        'Sinhala': 'මගේ ගේම් ගිණුම විකුණන්නේ කෙසේද?',
        'Tamil': 'எனது கேம் கணக்கை எவ்வாறு விற்பது?',
      },
      'a': {
        'English': 'Go to "Sell an Account" from the home screen, fill in the game details, price, and upload proof of ownership. Once approved by our admin team, your listing goes live.',
        'Sinhala': 'home screen එකේ සිට "Sell an Account" වෙත ගොස්, ගේම් විස්තර, මිල පුරවා, අයිතිය තහවුරු කිරීමේ සාක්ෂි upload කරන්න. අපගේ admin කණ්ඩායම විසින් අනුමත කළ පසු, ඔබේ ලැයිස්තුව live වේ.',
        'Tamil': 'முகப்புத் திரையிலிருந்து "Sell an Account" க்குச் சென்று, கேம் விவரங்கள், விலையை நிரப்பி, உரிமையை உறுதிப்படுத்தும் ஆதாரத்தை பதிவேற்றவும். எங்கள் நிர்வாகக் குழுவால் அங்கீகரிக்கப்பட்டதும், உங்கள் பட்டியல் நேரலையில் வரும்.',
      },
    },
    {
      'q': {
        'English': 'Why do I need to verify my identity?',
        'Sinhala': 'මගේ අනන්‍යතාවය තහවුරු කිරීම අවශ්‍ය ඇයි?',
        'Tamil': 'எனது அடையாளத்தை ஏன் சரிபார்க்க வேண்டும்?',
      },
      'a': {
        'English': 'Identity verification (NIC, Driving License, or Passport) helps keep the marketplace safe from scammers and fraud, protecting both buyers and sellers.',
        'Sinhala': 'අනන්‍යතා තහවුරු කිරීම (NIC, රියදුරු බලපත්‍රය, හෝ පාස්පෝට්) වංචාකරුවන්ගෙන් සහ වංචාවෙන් marketplace එක ආරක්ෂිතව තබා ගැනීමට උපකාරී වේ, මෙමගින් ගැනුම්කරුවන් සහ විකුණුම්කරුවන් දෙදෙනාම ආරක්ෂා වේ.',
        'Tamil': 'அடையாள சரிபார்ப்பு (NIC, ஓட்டுநர் உரிமம் அல்லது கடவுச்சீட்டு) மோசடி செய்பவர்களிடமிருந்தும் மோசடியிலிருந்தும் சந்தையை பாதுகாப்பாக வைத்திருக்க உதவுகிறது, இது வாங்குபவர்கள் மற்றும் விற்பவர்கள் இருவரையும் பாதுகாக்கிறது.',
      },
    },
    {
      'q': {
        'English': 'What happens if there is a dispute?',
        'Sinhala': 'dispute එකක් ඇති වුවහොත් සිදුවන්නේ කුමක්ද?',
        'Tamil': 'ஒரு சர்ச்சை ஏற்பட்டால் என்ன நடக்கும்?',
      },
      'a': {
        'English': 'If a buyer or seller raises a dispute on an order, our admin team reviews the evidence from both sides and makes a final decision to resolve it fairly.',
        'Sinhala': 'order එකක් සම්බන්ධයෙන් ගැනුම්කරුවෙකු හෝ විකුණුම්කරුවෙකු dispute එකක් ඇති කළහොත්, අපගේ admin කණ්ඩායම දෙපාර්ශ්වයේම සාක්ෂි review කර, එය සාධාරණව විසඳීමට අවසන් තීරණයක් ගනියි.',
        'Tamil': 'ஒரு ஆர்டரில் வாங்குபவர் அல்லது விற்பவர் சர்ச்சையை எழுப்பினால், எங்கள் நிர்வாகக் குழு இரு தரப்பினரிடமிருந்தும் ஆதாரங்களை மதிப்பாய்வு செய்து, அதை நியாயமாக தீர்க்க இறுதி முடிவை எடுக்கும்.',
      },
    },
    {
      'q': {
        'English': 'How long does withdrawal take?',
        'Sinhala': 'withdrawal එකකට කොපමණ කාලයක් ගතවේද?',
        'Tamil': 'திரும்பப் பெறுவதற்கு எவ்வளவு நேரம் ஆகும்?',
      },
      'a': {
        'English': 'Withdrawals are reviewed and processed by our admin team, typically within 24-48 hours after being requested from your Wallet.',
        'Sinhala': 'Withdrawals අපගේ admin කණ්ඩායම විසින් review කර process කරනු ලබන අතර, ඔබේ Wallet එකෙන් request කළායින් පසු සාමාන්‍යයෙන් පැය 24-48 අතර ගතවේ.',
        'Tamil': 'திரும்பப் பெறுதல்கள் எங்கள் நிர்வாகக் குழுவால் மதிப்பாய்வு செய்யப்பட்டு செயலாக்கப்படும், பொதுவாக உங்கள் Wallet இலிருந்து கோரிய பிறகு 24-48 மணி நேரத்திற்குள்.',
      },
    },
    {
      'q': {
        'English': 'What fees does MYGame Marketplace charge?',
        'Sinhala': 'MYGame Marketplace අය කරන ගාස්තු මොනවාද?',
        'Tamil': 'MYGame Marketplace என்ன கட்டணங்களை வசூலிக்கிறது?',
      },
      'a': {
        'English': 'A commission is charged on each successful sale. The exact percentage is shown to sellers at the time of listing an account.',
        'Sinhala': 'සාර්ථක සෑම විකිණීමකටම commission එකක් අය කරනු ලැබේ. නිශ්චිත percentage එක ගිණුමක් list කරන අවස්ථාවේදී විකුණුම්කරුවන්ට පෙන්වනු ලැබේ.',
        'Tamil': 'ஒவ்வொரு வெற்றிகரமான விற்பனைக்கும் கமிஷன் வசூலிக்கப்படுகிறது. துல்லியமான சதவீதம் ஒரு கணக்கை பட்டியலிடும் நேரத்தில் விற்பனையாளர்களுக்கு காட்டப்படும்.',
      },
    },
    {
      'q': {
        'English': 'Can I cancel an order?',
        'Sinhala': 'order එකක් cancel කළ හැකිද?',
        'Tamil': 'ஒரு ஆர்டரை ரத்து செய்ய முடியுமா?',
      },
      'a': {
        'English': 'Orders can be cancelled before the seller confirms the handover. Once credentials are shared and confirmed, cancellations are handled through the dispute process instead.',
        'Sinhala': 'විකුණුම්කරු handover එක තහවුරු කිරීමට පෙර orders cancel කළ හැක. credentials share කර confirm කළ පසු, cancellations dispute process එක හරහා handle කරනු ලැබේ.',
        'Tamil': 'விற்பனையாளர் ஒப்படைப்பை உறுதிப்படுத்தும் முன் ஆர்டர்களை ரத்து செய்யலாம். சான்றுகள் பகிரப்பட்டு உறுதிப்படுத்தப்பட்ட பிறகு, ரத்துசெய்தல்கள் சர்ச்சை செயல்முறை மூலம் கையாளப்படும்.',
      },
    },
    {
      'q': {
        'English': 'Is my payment information safe?',
        'Sinhala': 'මගේ ගෙවීම් තොරතුරු ආරක්ෂිතද?',
        'Tamil': 'எனது கட்டண தகவல் பாதுகாப்பானதா?',
      },
      'a': {
        'English': 'Yes. We do not store your card details. Payments are processed securely and account credentials shared during transactions are encrypted.',
        'Sinhala': 'ඔව්. අපි ඔබේ card විස්තර store කරන්නේ නැත. ගෙවීම් ආරක්ෂිතව process කරනු ලබන අතර transactions අතරතුර share කරන ගිණුම් credentials encrypt කර ඇත.',
        'Tamil': 'ஆம். நாங்கள் உங்கள் கார்டு விவரங்களை சேமிக்க மாட்டோம். கட்டணங்கள் பாதுகாப்பாக செயலாக்கப்படுகின்றன, பரிவர்த்தனைகளின் போது பகிரப்படும் கணக்கு சான்றுகள் என்க்ரிப்ட் செய்யப்படுகின்றன.',
      },
    },
    {
      'q': {
        'English': 'How do I contact support?',
        'Sinhala': 'support සම්බන්ධ කර ගන්නේ කෙසේද?',
        'Tamil': 'ஆதரவை எவ்வாறு தொடர்பு கொள்வது?',
      },
      'a': {
        'English': 'Use "Live Chat with Admin" in Settings for direct help, or use the "Report a Problem" option for account-specific issues.',
        'Sinhala': 'සෘජු උදව් සඳහා Settings හි "Live Chat with Admin" භාවිතා කරන්න, හෝ ගිණුම් විශේෂිත ගැටලු සඳහා "Report a Problem" විකල්පය භාවිතා කරන්න.',
        'Tamil': 'நேரடி உதவிக்கு Settings இல் "Live Chat with Admin" ஐப் பயன்படுத்தவும், அல்லது கணக்கு-குறிப்பிட்ட சிக்கல்களுக்கு "Report a Problem" விருப்பத்தை பயன்படுத்தவும்.',
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: Text(AppLocalizations.t('help_and_faq'))),
          body: SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                final item = _faqs[index];
                final q = item['q']![lang] ?? item['q']!['English']!;
                final a = item['a']![lang] ?? item['a']!['English']!;
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.hint,
                      title: Text(q, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a, style: const TextStyle(color: AppColors.hint, fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
