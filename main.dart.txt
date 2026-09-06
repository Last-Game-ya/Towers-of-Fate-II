// LAIR RESET FIX: each Lair fight clears buffs, debuffs, relic combat stacks and absorb shield.
// COMPLETE 21-RELIC CLASS/SPECIALIZATION MERGE 2026-08-24
// TOWERS OF FATE - AGREED CHANGES MERGE 2026-08-24
// TOWERS OF FATE - FINAL DARTPAD MERGE 2026-08-23
// Detailní UI specializací, Relic Mastery, Rift Seasons, World Boss, Gear Score,
// Můj build, Tower boss panel, Průvodce, Build Inspector, dnešní cíle,
// Knihovna amuletů a finální balance změny.
// RETENTION SYSTEMS: Build Inspector, Daily Goals, Rift Mutators, Relic Collection.
// DETAILED SPECIALIZATION UI: roles, fantasy, mechanics, strengths, weaknesses and recommended builds.
// SYSTEMS: Relic Mastery, Rift Seasons, Set Synergies, Daily World Boss.
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

part 'ui_design.dart';
part 'data_models.dart';
part 'game_state.dart';
part 'screens.dart';

// ===== CRASH/ERROR REPORTING (Krok 1 - lokální, bez external služby) =====
// Samostatná, na GameState NEZÁVISLÁ třída - chyby se mohou objevit dřív, než GameState vůbec
// vznikne (např. při buildu MaterialApp/theme), takže logger nemůže čekat na Provider strom.
// Ukládá posledních maxEntries chyb do SharedPreferences (přežije i restart appky), plus krátký
// in-memory cache pro rychlé zobrazení bez await. UI panel (Profil > Ostatní) umožní chyby
// zkopírovat do schránky, ať je hráč může poslat vývojáři (Discord/email/support formulář).
// Krok 2 (napojení na Sentry/Firebase Crashlytics) vyžaduje účet + DSN/API klíč a případně
// úpravu nativních android//ios/ složek - mimo dosah tohoto souboru, na tebe až budeš mít vybráno.
class CrashReporter {
  static const int maxEntries = 20;
  static const String _prefsKey = "crash_log_v1";
  static final List<String> _cache = [];

  static List<String> get recentErrors => List.unmodifiable(_cache);

  static void log(String source, Object error, StackTrace? stack) {
    final ts = DateTime.now().toIso8601String();
    final stackPreview = stack == null ? "" : "\n${stack.toString().split('\n').take(4).join('\n')}";
    final entry = "[$ts] [$source] $error$stackPreview";
    _cache.insert(0, entry);
    if (_cache.length > maxEntries) _cache.removeRange(maxEntries, _cache.length);
    // debugPrint místo print - v release buildu je debugPrint ořezaný/zahozený, ale nespadne.
    debugPrint("CrashReporter: $entry");
    _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _cache);
    } catch (_) {
      // Ukládání logu chyb nesmí samo o sobě appku shodit - tichý fallback na in-memory cache.
    }
  }

  static Future<void> loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsKey);
      if (saved != null) {
        _cache.clear();
        _cache.addAll(saved);
      }
    } catch (_) {}
  }

  static Future<void> clear() async {
    _cache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}

void main() async {
  // WidgetsFlutterBinding.ensureInitialized() i runApp() musí běžet ve STEJNÉ zóně,
  // jinak Flutter hlásí "Zone mismatch" - proto je celý main() obsah uvnitř runZonedGuarded.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await CrashReporter.loadPersisted();
    // Flutter-framework chyby (build/layout/paint) - zaloguje a POŘÁD ukáže standardní červenou
    // debug obrazovku (FlutterError.presentError), ať se v debug módu nic neskrývá.
    FlutterError.onError = (FlutterErrorDetails details) {
      CrashReporter.log("Flutter", details.exceptionAsString(), details.stack);
      FlutterError.presentError(details);
    };
    // Chyby mimo Flutter framework (native platform callbacky apod.) - vrací true = "zpracováno",
    // ať appka nespadne kvůli něčemu, co bychom stejně nemohli opravit za běhu.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      CrashReporter.log("Platform", error, stack);
      return true;
    };
    runApp(
      ChangeNotifierProvider<GameState>(
        create: (context) => GameState(),
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: FantasyColors.abyss,
          primaryColor: FantasyColors.gold,
          textTheme: fantasyTextTheme(ThemeData.dark().textTheme),
          fontFamily: GoogleFonts.manrope().fontFamily,
          colorScheme: const ColorScheme.dark(
            primary: FantasyColors.gold,
            secondary: Color(0xFF1E88E5),
            surface: FantasyColors.panel,
          ),
          cardColor: FantasyColors.panel,
          cardTheme: CardThemeData(color: FantasyColors.panel, elevation: 8, shape: RoundedRectangleBorder(side: const BorderSide(color: FantasyColors.bronze, width: 1.2), borderRadius: BorderRadius.circular(8))),
          // ===== SDÍLENÝ STYL PRO VŠECHNY 3 DRUHY TLAČÍTEK =====
          // Dřív měl vlastní theme jen ElevatedButton - OutlinedButton a TextButton (použité
          // stovkykrát napříč hrou, např. "Zrušit", "Utéct z Lair", odkazy mezi obrazovkami)
          // padaly na výchozí Flutter modrou, co koliduje s celým zlato-bronzovým vzhledem.
          // Sjednoceno na jednu paletu + jasně odlišený disabled stav (dřív skoro nerozeznatelný
          // od aktivního, matoucí u zamčených nákupů/upgradů).
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? const Color(0xFF2A241C) : FantasyColors.button),
              foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? Colors.grey.shade600 : FantasyColors.parchment),
              side: MaterialStateProperty.resolveWith((states) => BorderSide(color: states.contains(MaterialState.disabled) ? Colors.grey.shade800 : FantasyColors.bronze, width: 1.3)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.bold, letterSpacing: .3)),
              elevation: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? 0.0 : 3.0),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? Colors.grey.shade700 : FantasyColors.gold),
              side: MaterialStateProperty.resolveWith((states) => BorderSide(color: states.contains(MaterialState.disabled) ? Colors.grey.shade800 : FantasyColors.bronze, width: 1.3)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.bold, letterSpacing: .3)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? Colors.grey.shade700 : const Color(0xFFE0C22E)),
              textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          dividerTheme: const DividerThemeData(color: FantasyColors.bronze),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF18181D),
            foregroundColor: Color(0xFFF1E6D0),
            elevation: 4,
          ),
        ),
        home: const CelebrationOverlayHost(child: MainMenuScreen()),
      ),
    ),
  );
  }, (Object error, StackTrace stack) {
    CrashReporter.log("Zone", error, stack);
  });
}

// ===== MONETIZACE — REWARDED AD (Rift bonus pokus) =====
// DartPad stub: DartPad neumí balíčky s nativním kódem (platform channels), takže
// google_mobile_ads tu nejde použít. Tahle třída má STEJNÉ veřejné API jako skutečná
// integrace (instance/preload/isReady/show), ale místo reklamy rovnou udělí odměnu -
// tak jde hra normálně testovat v prohlížeči.
//
// Pro reálné publikování (mimo DartPad, ve skutečném Flutter projektu):
//   1) Přidej do pubspec.yaml: `google_mobile_ads: ^5.1.0` (nebo novější) + import
//      'package:google_mobile_ads/google_mobile_ads.dart' a nastav AndroidManifest.xml /
//      Info.plist App ID - viz https://docs.page/googleads/google-mobile-ads-flutter.
//   2) V main() zavolej `await MobileAds.instance.initialize();` před runApp().
//   3) Nahraď tuhle třídu skutečnou implementací přes RewardedAd.load(...) - Google
//      TEST ad unit ID pro vývoj: 'ca-app-pub-3940256099942544/5224354917' (Android),
//      'ca-app-pub-3940256099942544/1712485313' (iOS). Před publikováním je vyměň za
//      vlastní ID z AdMob konzole.
//   4) K tomu potřebuješ AdMob účet, Google Play Console ($25 jednorázově) / Apple
//      Developer ($99/rok) účet a appku živou v obchodě, aby AdMob počítal impressions.
class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  void preload() {}

  bool get isReady => true;

  // Stub pro DartPad: odměnu udělí rovnou, žádná reklama se nepřehrává.
  void show({required VoidCallback onReward, VoidCallback? onDismissed}) {
    onReward();
    onDismissed?.call();
  }
}


