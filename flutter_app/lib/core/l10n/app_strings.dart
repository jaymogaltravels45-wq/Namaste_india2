import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Lightweight localization: Hinglish (default), English, Hindi, Gujarati.
/// Usage: ValueListenableBuilder(valueListenable: AppLang.current, builder: (_, lang, __) => Text(tr('bookRide')))
class AppLang {
  static const _prefsKey = "pref_language";
  static final ValueNotifier<String> current = ValueNotifier("Hinglish");

  static const supported = ["Hinglish", "English", "Hindi", "Gujarati"];

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_prefsKey);
      if (v != null && supported.contains(v)) current.value = v;
    } catch (_) {}
  }

  static Future<void> set(String lang) async {
    if (!supported.contains(lang)) return;
    current.value = lang;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefsKey, lang);
    } catch (_) {}
  }
}

/// Localized strings for the main customer-facing UI.
const Map<String, Map<String, String>> _s = {
  "tagline": {
    "Hinglish": "Kahan jaana hai aaj?",
    "English": "Where to today?",
    "Hindi": "आज कहाँ जाना है?",
    "Gujarati": "આજે ક્યાં જવું છે?",
  },
  "taglineSub": {
    "Hinglish": "Premium rides, fair fares",
    "English": "Premium rides, fair fares",
    "Hindi": "प्रीमियम राइड, सही किराया",
    "Gujarati": "પ્રીમિયમ રાઇડ, યોગ્ય ભાડું",
  },
  "searchHint": {
    "Hinglish": "Pickup location search karo...",
    "English": "Search pickup location...",
    "Hindi": "पिकअप लोकेशन खोजें...",
    "Gujarati": "પિકઅપ લોકેશન શોધો...",
  },
  "bookRide": {
    "Hinglish": "Book a Ride",
    "English": "Book a Ride",
    "Hindi": "राइड बुक करें",
    "Gujarati": "રાઇડ બુક કરો",
  },
  "chooseTrip": {
    "Hinglish": "Apni trip choose karo",
    "English": "Choose your trip",
    "Hindi": "अपनी ट्रिप चुनें",
    "Gujarati": "તમારી ટ્રિપ પસંદ કરો",
  },
  "oneWay": {
    "Hinglish": "One Way",
    "English": "One Way",
    "Hindi": "वन वे",
    "Gujarati": "વન વે",
  },
  "oneWaySub": {
    "Hinglish": "City to city comfort",
    "English": "City to city comfort",
    "Hindi": "शहर से शहर आराम से",
    "Gujarati": "શહેરથી શહેર આરામથી",
  },
  "roundTrip": {
    "Hinglish": "Round Trip",
    "English": "Round Trip",
    "Hindi": "राउंड ट्रिप",
    "Gujarati": "રાઉન્ડ ટ્રિપ",
  },
  "roundTripSub": {
    "Hinglish": "Go & return easy",
    "English": "Go & return easy",
    "Hindi": "जाना-आना आसान",
    "Gujarati": "જવું-આવવું સરળ",
  },
  "local": {
    "Hinglish": "Local",
    "English": "Local",
    "Hindi": "लोकल",
    "Gujarati": "લોકલ",
  },
  "localSub": {
    "Hinglish": "Hourly packages",
    "English": "Hourly packages",
    "Hindi": "घंटे के पैकेज",
    "Gujarati": "કલાકના પેકેજ",
  },
  "bid": {
    "Hinglish": "Bid",
    "English": "Bid",
    "Hindi": "बिड",
    "Gujarati": "બિડ",
  },
  "bidSub": {
    "Hinglish": "Name your price",
    "English": "Name your price",
    "Hindi": "अपनी कीमत बताओ",
    "Gujarati": "તમારી કિંમત જણાવો",
  },
  "popularRoutes": {
    "Hinglish": "Popular Routes",
    "English": "Popular Routes",
    "Hindi": "लोकप्रिय रूट",
    "Gujarati": "લોકપ્રિય રૂટ",
  },
  "book": {
    "Hinglish": "Book",
    "English": "Book",
    "Hindi": "बुक करें",
    "Gujarati": "બુક કરો",
  },
  "safe": {
    "Hinglish": "Safe",
    "English": "Safe",
    "Hindi": "सुरक्षित",
    "Gujarati": "સુરક્ષિત",
  },
  "fairFare": {
    "Hinglish": "Fair Fare",
    "English": "Fair Fare",
    "Hindi": "सही किराया",
    "Gujarati": "યોગ્ય ભાડું",
  },
  "home": {
    "Hinglish": "Home",
    "English": "Home",
    "Hindi": "होम",
    "Gujarati": "હોમ",
  },
  "trips": {
    "Hinglish": "Trips",
    "English": "Trips",
    "Hindi": "ट्रिप्स",
    "Gujarati": "ટ્રિપ્સ",
  },
  "profile": {
    "Hinglish": "Profile",
    "English": "Profile",
    "Hindi": "प्रोफ़ाइल",
    "Gujarati": "પ્રોફાઇલ",
  },
};

String tr(String key) {
  final m = _s[key];
  if (m == null) return key;
  return m[AppLang.current.value] ?? m["Hinglish"]!;
}
