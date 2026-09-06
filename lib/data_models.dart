part of 'main.dart';

// ===== LOKALIZACE (CZ/EN) =====
// Zatím pokrývá hlavní menu, žebříček a ukládání. Zbytek hry (Věž, Tržiště, Kovář...) je
// prozatím pouze česky - plný překlad všech obrazovek je rozsáhlý navazující krok.
class AppStrings {
  final String lang; // "cs" nebo "en"
  AppStrings(this.lang);
  bool get isEn => lang == "en";

  String get gameTitle => isEn ? "Towers of Fate" : "Věže Osudu";
  String get heroNameLabel => isEn ? "Hero name" : "Jméno hrdiny";
  String get heroNameHint => isEn ? "Enter your hero's name..." : "Zadej jméno svého hrdiny...";
  String get startGame => isEn ? "Start Game" : "Začít hru";
  String get continueGame => isEn ? "Continue" : "Pokračovat";
  String get newGame => isEn ? "New Game" : "Nová hra";
  String get newGameConfirmTitle => isEn ? "Start a new game?" : "Začít novou hru?";
  String get newGameConfirmBody => isEn ? "Your current hero and progress will be lost (unless saved)." : "Aktuální hrdina a postup budou ztraceny (pokud nejsou uloženi).";
  String get cancel => isEn ? "Cancel" : "Zrušit";
  String get confirm => isEn ? "Confirm" : "Potvrdit";
  String get save => isEn ? "Save & Exit" : "Uložit a ukončit";
  String get load => isEn ? "Load Game" : "Načíst hru";
  String get saved => isEn ? "Game saved!" : "Hra uložena!";
  String get loaded => isEn ? "Game loaded!" : "Hra načtena!";
  String get noSaveFound => isEn ? "No saved game found." : "Nebyla nalezena žádná uložená hra.";
  String get saveAndExitConfirmTitle => isEn ? "Save and exit?" : "Uložit a ukončit hru?";
  String get saveAndExitConfirmBody => isEn
      ? "The game will save right now and the current run will end - you'll return to the main menu. You can't use this to reload after a bad outcome: the game already autosaves continuously as you play, including deaths."
      : "Hra se hned uloží a aktuální hraní skončí - vrátíš se do hlavního menu. Nejde to použít jako záchranu po neúspěchu: hra se průběžně ukládá sama za běhu, včetně smrti.";
  String get ladder => isEn ? "Ladder" : "Žebříček";
  String get ladderEmpty => isEn ? "No runs recorded yet. Die once and you'll show up here!" : "Zatím žádné záznamy. Jednou zemři a objevíš se tady!";
  String get ladderFloor => isEn ? "Floor" : "Patro";
  String get language => isEn ? "Language" : "Jazyk";
  String get vibration => isEn ? "Vibration" : "Vibrace";
  String get vibrationOn => isEn ? "Vibration: On" : "Vibrace: Zapnuto";
  String get vibrationOff => isEn ? "Vibration: Off" : "Vibrace: Vypnuto";
  String get close => isEn ? "Close" : "Zavřít";
  String get nameRequired => isEn ? "Please enter a hero name first." : "Nejprve zadej jméno hrdiny.";
  String heroNameLockedNote(String name) => isEn ? "Your hero's name is $name. It can only be changed after death." : "Tvůj hrdina se jmenuje $name. Jméno lze změnit jen po smrti.";
}

// Záznam v žebříčku - kam se konkrétní hrdina dostal a s jakou třídou, než zemřel.
class LadderEntry {
  final String heroName;
  final HeroClass heroClass;
  final int floorReached;
  final DateTime date;

  LadderEntry({required this.heroName, required this.heroClass, required this.floorReached, required this.date});

  Map<String, dynamic> toJson() => {
        "heroName": heroName,
        "heroClass": heroClass.name,
        "floorReached": floorReached,
        "date": date.toIso8601String(),
      };

  factory LadderEntry.fromJson(Map<String, dynamic> json) => LadderEntry(
        heroName: json["heroName"] as String,
        heroClass: HeroClass.values.firstWhere((c) => c.name == json["heroClass"], orElse: () => HeroClass.none),
        floorReached: json["floorReached"] as int,
        date: DateTime.parse(json["date"] as String),
      );
}

enum HeroClass { none, warrior, hunter, healer, deathknight, mage, duelist, monk, druid, paladin, demonhunter, necromancer }

// ===== PORTRÉTY POSTAV (AI-generovaná ilustrace, viz portrety_prompty.txt) =====
// Cesta k portrétu dané třídy, pokud už existuje vygenerovaný a napojený obrázek - jinak
// třída chybí v mapě a UI (viz _ClassBadge ve screens.dart) spadne zpět na starý procedurální
// ikonový systém (FantasyIconRegistry). Postupně doplňovat, jak budou další portréty hotové -
// nic dalšího v kódu se měnit nemusí, stačí sem přidat řádek + soubor do assets/images/portraits/.
const Map<HeroClass, String> kClassPortraitAssets = {
  HeroClass.warrior: 'assets/images/portraits/class_warrior.png',
  HeroClass.hunter: 'assets/images/portraits/class_hunter.png',
  HeroClass.deathknight: 'assets/images/portraits/class_deathknight.png',
  HeroClass.demonhunter: 'assets/images/portraits/class_demonhunter.png',
  HeroClass.mage: 'assets/images/portraits/class_mage.png',
  HeroClass.druid: 'assets/images/portraits/class_druid.png',
  HeroClass.healer: 'assets/images/portraits/class_healer.png',
};

// ===== RUNY OSUDOVÉ VOLBY (Ma-Túš, Runový Čaroděj - 2. záložka) =====
// Datový podklad z "Towers of Fate - pasivní talenty 3x6": pro každou třídu 6 řádků × 3 sloupce
// (sloupec = tematicky jedna ze 3 specializací dané třídy, ale výběr NENÍ zamčený podle aktuální
// specializace hráče - viz GameState.osudovaVolbaChoice). Teď jde jen o název + popis efektu pro
// UI/výběr; SKUTEČNÉ mechanické hooky (startCombat/beforeDamageTaken/afterSpell/onRelicProc/...)
// popsané v checklistu dokumentu ještě nejsou zapojené do combat enginu - to je samostatný,
// mnohem větší krok (198 unikátních efektů přes 11 tříd), který přijde postupně po částech.
class RuneTalentOption {
  final String name;
  final String description;
  const RuneTalentOption(this.name, this.description);
}

const Map<HeroClass, List<List<RuneTalentOption>>> runeTalentTable = {
  HeroClass.warrior: [
    [
      RuneTalentOption('Nezlomný nástup', 'Začne boj s absorpčním štítem ve výši 12 % Max HP.'),
      RuneTalentOption('Zuřivost bolesti', 'První přímý zásah v boji způsobí o 20 % méně poškození a vytvoří 10 Rage.'),
      RuneTalentOption('Krev volá po krvi', 'Při poklesu pod 40 % HP získá absorb 15 % Max HP a na 2 kola +10 % lifesteal. 1× za boj.'),
    ],
    [
      RuneTalentOption('Bezohledný průraz', 'Ignoruje 10 % Armor cíle.'),
      RuneTalentOption('Rozdrcená zbroj', 'Základní útok sníží Armor cíle o 4 %, max. 20 % do konce boje.'),
      RuneTalentOption('Pach krve', 'Proti cíli pod 50 % HP způsobuje o 10 % vyšší poškození.'),
    ],
    [
      RuneTalentOption('Připravený k boji', 'Začne boj s 30 Rage.'),
      RuneTalentOption('Hněv pod údery', 'Po obdržení přímého poškození získá 4 Rage, max. 1× za kolo.'),
      RuneTalentOption('Neutuchající zuřivost', 'Schopnost, která utratí alespoň 30 Rage, má 20% šanci vrátit 10 Rage.'),
    ],
    [
      RuneTalentOption('Drtivý doskok', 'Po aktivním spellu získá další základní útok +40 % dmg a vytvoří o 50 % více Rage.'),
      RuneTalentOption('Štít a čepel', 'Block nebo poškození absorbu posílí další základní útok; ten sníží dmg cíle o 5 % na 2 kola.'),
      RuneTalentOption('Krvavý rytmus', 'Lifesteal ze spellu nabije další základní útok; jeho overheal se převede na absorb.'),
    ],
    [
      RuneTalentOption('Nespoutaný hněv', 'Po utracení 50 Rage je další aktivní spell o 30 % silnější.'),
      RuneTalentOption('Ocelová odveta', 'Block vytvoří 5 Rage; po třech blocích okamžitě zesílí příští obranný spell o 30 %.'),
      RuneTalentOption('Krvavé opojení', 'Lifesteal a self-heal class pasivky jsou o 30 % silnější; overheal vytváří absorb.'),
    ],
    [
      RuneTalentOption('Zuřivá rezonance', 'Aktivace hlavní relic mechaniky po Rage spenderu zesílí její dmg efekt o 30 %.'),
      RuneTalentOption('Runová bašta', 'Obranný relic proc vytvoří navíc absorb 8 % Max HP; po rozbití štítu posílí další základní útok.'),
      RuneTalentOption('Relikvie krve', 'Relic heal/lifesteal efekt je o 30 % silnější; overheal z relicu se převede na absorb.'),
    ],
  ],
  HeroClass.hunter: [
    [
      RuneTalentOption('Instinkt stopaře', 'První útok nepřítele má o 15 procentních bodů nižší šanci zasáhnout.'),
      RuneTalentOption('Ochrana smečky', 'Začne s absorbem 10 % Max HP; s aktivním companionem 13 %.'),
      RuneTalentOption('Splynutí se stínem', 'Pod 50 % HP získá na 2 kola +8 % Dodge. 1× za boj.'),
    ],
    [
      RuneTalentOption('Odhalená slabina', 'Crit označí cíl na 2 kola; od Lovce utrpí o 6 % více dmg.'),
      RuneTalentOption('Trhající tesáky', 'Companion/extra útok sníží Armor o 2 %, max. 10 %.'),
      RuneTalentOption('Stínový hrot', 'Útoky proti cíli s DoT ignorují 8 % Armor.'),
    ],
    [
      RuneTalentOption('Připravený výstřel', 'Začne boj s 25 body zdroje.'),
      RuneTalentOption('Lovecký rytmus', 'Každý 3. základní útok obnoví 8 zdroje.'),
      RuneTalentOption('Trpělivý predátor', 'Kolo bez aktivního spellu zkrátí nejdelší cooldown o 1, max. 1× za 2 kola.'),
    ],
    [
      RuneTalentOption('Přesný sled', "Spell proti označenému cíli nabije další základní útok; přidá 2 Hunter's Mark stacky."),
      RuneTalentOption('Koordinovaný lov', 'Po základním útoku companion okamžitě provede 40% útok, pokud předtím Lovec použil spell.'),
      RuneTalentOption('Výstřel ze stínu', 'Základní útok do cíle s DoT prodlouží nejkratší vlastní DoT o 1 kolo; max. 1× za 2 kola.'),
    ],
    [
      RuneTalentOption('Dokonalé zaměření', "Bonus každého Hunter's Mark stacku je o 30 % silnější; maximum zůstává 5."),
      RuneTalentOption('Alfa predátor', "Dosažení 5 Hunter's Mark vyvolá okamžitý companion útok; nemůže spustit další extra útok."),
      RuneTalentOption('Znamení soumraku', "Při 5 Hunter's Mark okamžitě tiknou všechny vlastní DoT jednou za 50 % běžné síly."),
    ],
    [
      RuneTalentOption('Relikvie přesnosti', 'Relic proc na označeném cíli je o 30 % silnější a spotřebuje nejvýše 1 Mark.'),
      RuneTalentOption('Relikvie smečky', 'Relic spell současně přikáže companionovi provést 50% útok.'),
      RuneTalentOption('Relikvie stínu', 'Relic proc obnoví jednu vlastní DoT a její příští tick zesílí o 30 %.'),
    ],
  ],
  HeroClass.healer: [
    [
      RuneTalentOption('Požehnání úsvitu', 'Začne s absorbem 12 % Max HP.'),
      RuneTalentOption('Spravedlivé utrpení', 'První zásah -20 % dmg; další základní útok vytvoří o 50 % více absorbu.'),
      RuneTalentOption('Bojová modlitba', 'Pod 50 % HP heal 8 % Max HP a -5 % dmg taken na 2 kola. 1× za boj.'),
    ],
    [
      RuneTalentOption('Paprsek soudu', 'Magické útoky ignorují 10 % obrany.'),
      RuneTalentOption('Rozsudek odplaty', 'Základní útok sníží obranu o 3 %, max. 15 %.'),
      RuneTalentOption('Posvátná válka', 'Po vytvoření absorbu je další útočný spell o 8 % silnější.'),
    ],
    [
      RuneTalentOption('Plnost víry', 'Začne s 25 zdroje.'),
      RuneTalentOption('Víra skrze bolest', 'Ztráta alespoň 10 % Max HP v kole vrátí 8 zdroje.'),
      RuneTalentOption('Ozvěna modlitby', 'Overheal převedený na absorb má 20% šanci zkrátit cooldown léčivého spellu o 1.'),
    ],
    [
      RuneTalentOption('Světelný dozvuk', 'Po léčivém spellu další základní útok vytvoří dvojnásobný absorb.'),
      RuneTalentOption('Trestající sled', 'Po základním útoku další útočný spell aplikuje Rozsudek; proti odsouzenému cíli další útok crituje.'),
      RuneTalentOption('Bitevní liturgie', 'Střídání základního útoku a heal/dmg spellu posílí jeho heal, dmg nebo absorb o 20 %.'),
    ],
    [
      RuneTalentOption('Přetékající světlo', 'Overheal a absorb z class pasivky jsou o 30 % silnější.'),
      RuneTalentOption('Hněv víry', 'Když absorb z útoku přijme dmg, další damage spell je o 30 % silnější.'),
      RuneTalentOption('Fanatická ochrana', 'Každé třetí vytvoření absorbu základním útokem vrátí 15 zdroje a sníží cooldown spellu o 1.'),
    ],
    [
      RuneTalentOption('Relikvie milosti', 'Relic heal je o 30 % silnější; jeho overheal vytvoří absorb.'),
      RuneTalentOption('Relikvie soudu', 'Relic damage označí cíl; následující základní útok ignoruje 20 % obrany.'),
      RuneTalentOption('Relikvie válečné víry', 'Relic proc současně zesílí příští absorb ze základního útoku o 50 %.'),
    ],
  ],
  HeroClass.deathknight: [
    [
      RuneTalentOption('Krvavá pevnost', 'Začne s absorbem 12 % Max HP; lifesteal obnoví až 20 % chybějící hodnoty tohoto štítu.'),
      RuneTalentOption('Ledové brnění', 'První zásah -25 % dmg a +5 % Armor na 2 kola.'),
      RuneTalentOption('Mrtvé tělo', 'DoT dmg -15 %; pod 35 % HP absorb 10 % Max HP. 1× za boj.'),
    ],
    [
      RuneTalentOption('Krvavé otevření', 'Lifesteal útoky +8 % dmg proti cíli nad 70 % HP.'),
      RuneTalentOption('Křehkost', 'Základní útok sníží Armor o 3 %, max. 15 %.'),
      RuneTalentOption('Morová hostina', '+4 % dmg za každý odlišný vlastní DoT, max. 12 %.'),
    ],
    [
      RuneTalentOption('Připravená duše', 'Začne boj s 1 Soul Rune.'),
      RuneTalentOption('Duše padlých', 'Každý 5. zásah vytvoří 1 Soul Rune.'),
      RuneTalentOption('Zamrzlý čas', 'Aktivace 7 Soul Runes zkrátí nejdelší cooldown o 1.'),
    ],
    [
      RuneTalentOption('Krvavé ostří', 'Spell posílený 7 Soul Runes nabije další základní útok; healne za 5 % Max HP a overheal převede na absorb.'),
      RuneTalentOption('Runová námraza', 'Po aktivním spellu základní útok přidá Námrazu; při 3 stackách okamžitě zopakuje 40 % posledního frost spellu.'),
      RuneTalentOption('Morový nositel', 'Základní útok po disease spellu okamžitě tikne nejkratší vlastní DoT za 50 % síly.'),
    ],
    [
      RuneTalentOption('Nezlomná krev', 'Po aktivaci 7 Soul Runes získá absorb 15 % Max HP; heal/absorb výsledného trojitého spellu je o 30 % silnější.'),
      RuneTalentOption('Ledové runy', 'Spell spuštěný po 7 Soul Runes má svůj výsledný efekt o dalších 30 % silnější; počet potřebných run zůstává 7.'),
      RuneTalentOption('Morová exploze', 'Po aktivaci 7 Soul Runes všechny vlastní DoT okamžitě provedou extra tick za 50 % síly.'),
    ],
    [
      RuneTalentOption('Relikvie krve', 'Relic lifesteal/heal/štít je o 30 % silnější; proc po trojitém spellu vytvoří absorb.'),
      RuneTalentOption('Zmrzlá relikvie', 'Relic proc vyvolaný spellovým oknem 7 run zopakuje 50 % svého dmg efektu bez dalšího procování.'),
      RuneTalentOption('Relikvie nákazy', 'Relic spell prodlouží vlastní DoT o 1 kolo a okamžitě spustí jejich 30% tick.'),
    ],
  ],
  HeroClass.mage: [
    [
      RuneTalentOption('Plamenný plášť', 'Pod 50 % HP absorb 12 % Max HP; jeho rozbití způsobí malý fire dmg. 1× za boj.'),
      RuneTalentOption('Ledová bariéra', 'Začne s absorbem 14 % Max HP.'),
      RuneTalentOption('Časová odchylka', 'První zásah -20 % dmg a nejdelší cooldown -1.'),
    ],
    [
      RuneTalentOption('Spálená obrana', 'Burn snižuje magickou obranu o 3 % za stack, max. 15 %.'),
      RuneTalentOption('Roztříštěný led', 'Proti Slow/Frozen cíli +8 % Crit Chance.'),
      RuneTalentOption('Aetherický průraz', 'Ignoruje 10 % magické obrany.'),
    ],
    [
      RuneTalentOption('Přetékající mana', 'Začne s 25 zdroje.'),
      RuneTalentOption('Elementární koloběh', 'Aplikace elementárního stavu vrátí 5 zdroje, max. 1× za kolo.'),
      RuneTalentOption('Časová ozvěna', 'Každý 3. aktivní spell zkrátí cooldown posledního jiného spellu o 1.'),
    ],
    [
      RuneTalentOption('Žhavá hůl', 'Po fire spellu základní útok aplikuje Burn; do hořícího cíle vytvoří 1 Arcane Charge.'),
      RuneTalentOption('Tříštivý výboj', 'Základní útok do Slow/Frozen cíle nabije příští frost spell; ten okamžitě spustí 40% druhý zásah.'),
      RuneTalentOption('Aetherický sled', 'Střídání základního útoku a spellu ukládá Ozvěnu; třetí správné střídání zopakuje 50 % spellu.'),
    ],
    [
      RuneTalentOption('Přetopené jádro', 'Spotřebování Arcane Charges zesílí aplikovaný Burn o 30 %.'),
      RuneTalentOption('Ledová rezonance', 'Bonus z Arcane Charges pro frost spell je o 30 % silnější; max. stacků se nemění.'),
      RuneTalentOption('Přetížení reality', 'Efekt Arcane Charges je o 30 % silnější; jejich spotřebování zkrátí cooldown jiného spellu o 1.'),
    ],
    [
      RuneTalentOption('Relikvie požáru', 'Relic proc na hořícím cíli okamžitě tikne Burn za 50 % a obnoví jeho trvání.'),
      RuneTalentOption('Relikvie věčného ledu', 'Relic spell proti kontrolovanému cíli je o 30 % silnější a vytvoří malou bariéru.'),
      RuneTalentOption('Relikvie ozvěny', 'Relic Echo zopakuje 30 % posledního odlišného spellu; nesmí zopakovat sama sebe.'),
    ],
  ],
  HeroClass.duelist: [
    [
      RuneTalentOption('Přísaha pomsty', 'První zásah -20 % dmg a označí útočníka Vendettou.'),
      RuneTalentOption('Elegantní úkrok', 'Na 2 kola od startu +10 % Dodge.'),
      RuneTalentOption('Dokonalý kryt', 'První nepřátelský crit se změní na normální zásah.'),
    ],
    [
      RuneTalentOption('Odhalený viník', 'Označený cíl utrpí +8 % dmg.'),
      RuneTalentOption('Riposta', 'Po Dodge další základní útok +25 % dmg.'),
      RuneTalentOption('Přesný zásah', 'Crit ignoruje 15 % Armor.'),
    ],
    [
      RuneTalentOption('První tempo', 'Začne se 2 stacky Tempa.'),
      RuneTalentOption('Dech duelanta', 'Dodge/Block vrátí 6 zdroje, max. 1× za kolo.'),
      RuneTalentOption('Encore', 'Po 3 critech nejdelší cooldown -1.'),
    ],
    [
      RuneTalentOption('Sekvence pomsty', 'Spell na označený cíl nabije základní útok; přidá 2 stacky Odplaty/Vendetty.'),
      RuneTalentOption('Krok mezi čepelemi', 'Po Dodge základní útok spustí Riposte; po Riposte je další spell o 20 % silnější.'),
      RuneTalentOption('Virtuózní fráze', 'Spell → základní útok → spell vytvoří Finale, které zopakuje 40 % posledního spellu.'),
    ],
    [
      RuneTalentOption('Neodvratná Nemesis', 'Payoff Vendetta/Odplata je o 30 % silnější; požadované stacky se nezvyšují.'),
      RuneTalentOption('Dokonalá odpověď', 'Riposte je o 30 % silnější a její heal se může převést na absorb.'),
      RuneTalentOption('Maestro', 'Každý 5. crit zesílí další odlišný spell o 30 % a vytvoří Tempo.'),
    ],
    [
      RuneTalentOption('Erb Nemesis', 'Relic Rozsudek proti označenému cíli je o 30 % silnější.'),
      RuneTalentOption('Erb tance', 'Relic stance aktivuje jednu zesílenou Riposte bez nutnosti Dodge.'),
      RuneTalentOption('Erb virtuóza', 'Relic proc po Finale zopakuje 50 % posledního základního útoku bez rekurze.'),
    ],
  ],
  HeroClass.monk: [
    [
      RuneTalentOption('Krok větru', 'Na 2 kola +8 % Dodge; první Dodge vytvoří 10 Chi.'),
      RuneTalentOption('Kamenné tělo', 'Začne s absorbem 13 % Max HP.'),
      RuneTalentOption('Vnitřní harmonie', 'Pod 50 % HP heal 7 % Max HP a odstraní 1 negativní efekt. 1× za boj.'),
    ],
    [
      RuneTalentOption('Vířivé údery', 'Každý 3. základní útok provede 35% extra zásah bez rekurze.'),
      RuneTalentOption('Dlaň rozbité skály', 'Základní útok sníží Armor o 3 %, max. 15 %.'),
      RuneTalentOption('Soustředěný úder', 'Kolo bez utracení Chi zesílí další spell o 12 %.'),
    ],
    [
      RuneTalentOption('Naplněná Chi', 'Začne s 25 Chi.'),
      RuneTalentOption('Chi bolesti', 'Po obdržení dmg +5 Chi, max. 1× za kolo.'),
      RuneTalentOption('Plynulý přechod', 'Střídání útoku/spellu vrátí 4 Chi; každé 3. střídání cooldown -1.'),
    ],
    [
      RuneTalentOption('Pěst vichru', 'Po spellu další základní útok přidá 2 Flowing Chi; při maximu spustí 40% extra attack.'),
      RuneTalentOption('Ozvěna skály', 'Základní útok po obranném spellu obnoví 20 % chybějícího absorbu.'),
      RuneTalentOption('Vyrovnaný dech', 'Střídání heal/utility spellu a základního útoku posílí následující odlišný spell o 20 %.'),
    ],
    [
      RuneTalentOption('Proudící Chi', 'Damage payoff Flowing Chi je o 30 % silnější; počet stacků se nemění.'),
      RuneTalentOption('Nehybná hora', 'Při max Flowing Chi získá místo čekání okamžitě absorb 10 % Max HP; 1× za 3 kola.'),
      RuneTalentOption('Osvícení', 'Spotřebování max Flowing Chi zesílí heal/štít dalšího spellu o 30 %.'),
    ],
    [
      RuneTalentOption('Relikvie bouře', 'Relic proc při max Chi vyvolá 50% extra zásah bez rekurze.'),
      RuneTalentOption('Relikvie kamene', 'Relic obranný efekt je o 30 % silnější; po jeho zániku vytvoří Chi.'),
      RuneTalentOption('Relikvie klidu', 'Relic spell při správném střídání obnoví 30 % svého resource costu a posílí další heal.'),
    ],
  ],
  HeroClass.druid: [
    [
      RuneTalentOption('Astrální kůra', 'Začne s absorbem 10 % Max HP a během něj -8 % magic dmg.'),
      RuneTalentOption('Kůže šelmy', 'Po prvním zásahu +6 % Armor na 3 kola.'),
      RuneTalentOption('Semeno života', 'Pod 40 % HP heal 12 % Max HP během 3 kol. 1× za boj.'),
    ],
    [
      RuneTalentOption('Zatmění', 'Střídání magického a základního útoku zesílí další odlišný útok o 8 %.'),
      RuneTalentOption('Trhající drápy', 'Základní útok může aplikovat Bleed; proti Bleed cíli ignoruje 6 % Armor.'),
      RuneTalentOption('Rozpuk', 'Po vlastním healu je další útočný efekt o 8 % silnější.'),
    ],
    [
      RuneTalentOption('Astrální zarovnání', 'Začne s 25 zdroje.'),
      RuneTalentOption('Koloběh života', 'DoT/HoT tick může vrátit 4 zdroje, max. 1× za kolo.'),
      RuneTalentOption('Proměnlivá příroda', 'Střídání útoku a léčivého spellu zkrátí cooldown druhého typu o 1, max. 1× za 2 kola.'),
    ],
    [
      RuneTalentOption('Nebeský cyklus', 'Základní útok po astrálním spellu posune Eclipse; spell po útoku získá +20 % efekt.'),
      RuneTalentOption('Drápy a tesáky', 'Spell v bestiální formě nabije další základní útok; okamžitě tikne Bleed za 50 %.'),
      RuneTalentOption('Dotek života', 'Základní útok po HoT spellu rozkvete: okamžitě spustí 40 % nejsilnějšího HoT ticku.'),
    ],
    [
      RuneTalentOption('Dokonalé Zatmění', 'Payoff Eclipse je o 30 % silnější; počet kroků cyklu se nemění.'),
      RuneTalentOption('Vrcholový predátor', 'Při max Bleed stackách se další formový spell zesílí o 30 % a obnoví Bleed.'),
      RuneTalentOption('Rozkvetlá příroda', 'HoT class pasivky jsou o 30 % silnější; overheal jejich ticků vytváří absorb.'),
    ],
    [
      RuneTalentOption('Astrální relikvie', 'Relic proc během Eclipse zopakuje 50 % opačného astrálního efektu.'),
      RuneTalentOption('Relikvie šelmy', 'Relic spell na krvácející cíl okamžitě spustí 50% Bleed tick.'),
      RuneTalentOption('Relikvie prastarého háje', 'Relic HoT je o 30 % silnější a při overhealu prodlouží nejslabší HoT o 1 kolo.'),
    ],
  ],
  HeroClass.paladin: [
    [
      RuneTalentOption('Štít víry', 'Začne s absorbem 15 % Max HP.'),
      RuneTalentOption('Neústupný rozsudek', 'První zásah -20 % dmg a vytvoří 1 stack Odplaty.'),
      RuneTalentOption('Posvěcená půda', 'Pod 50 % HP na 3 kola -5 % dmg a heal 2 % Max HP/kolo. 1× za boj.'),
    ],
    [
      RuneTalentOption('Úder štítem', 'Aktivní absorb zvyšuje v omezené míře dmg základního útoku.'),
      RuneTalentOption('Rozsudek viníka', 'Ignoruje 10 % Armor; pod 35 % HP cíle 15 %.'),
      RuneTalentOption('Hořící posvěcení', 'Cíl zasažený posvěcením utrpí +8 % magic dmg od Paladina.'),
    ],
    [
      RuneTalentOption('Připravená víra', 'Začne s 25 zdroje.'),
      RuneTalentOption('Víra pod tlakem', 'Poškození absorbu vrátí 4 zdroje, max. 1× za kolo.'),
      RuneTalentOption('Věčné požehnání', 'Vlastní časované buffy/absorby trvají o 1 kolo déle v rámci limitu.'),
    ],
    [
      RuneTalentOption('Štít a rozsudek', 'Obranný spell nabije základní útok; obnoví 20 % chybějícího absorbu a aplikuje slabý Rozsudek.'),
      RuneTalentOption('Křižácký sled', 'Základní útok po Rozsudku vytvoří Odplatu; další aktivní spell ji spotřebuje pro +25 % dmg.'),
      RuneTalentOption('Posvěcený úder', 'Základní útok v aktivní auře spustí 40 % jejího heal/dmg ticku.'),
    ],
    [
      RuneTalentOption('Nezdolná hradba', 'Class absorb a Block payoff jsou o 30 % silnější; rozbití štítu zesílí další spell.'),
      RuneTalentOption('Poslední soud', 'Po 5 aplikacích Rozsudku je další útočný spell o 30 % silnější; počet potřebných aplikací se nezvyšuje.'),
      RuneTalentOption('Ztělesněné požehnání', 'Po vypršení vlastního buffu se jeho poslední tick zopakuje za 30 % a cooldown jiného spellu se zkrátí o 1.'),
    ],
    [
      RuneTalentOption('Relikvie bašty', 'Relic shield je o 30 % silnější; jeho poškození vytváří zdroj.'),
      RuneTalentOption('Relikvie odplaty', 'Relic spell spotřebující Rozsudek zopakuje 50 % dmg bez rekurze.'),
      RuneTalentOption('Relikvie posvěcení', 'Relic aura po aktivaci okamžitě tikne za 50 % a prodlouží aktivní požehnání o 1 kolo.'),
    ],
  ],
  HeroClass.demonhunter: [
    [
      RuneTalentOption('Démonický spěch', 'Na 2 kola +10 % Dodge.'),
      RuneTalentOption('Ohnivá kůže', 'První zásah -20 % dmg a vrátí malý Fel dmg.'),
      RuneTalentOption('Závoj Propasti', 'Pod 40 % HP absorb 13 % Max HP a 1 kolo zvýšený lifesteal. 1× za boj.'),
    ],
    [
      RuneTalentOption('Fel průraz', 'Ignoruje 10 % Armor.'),
      RuneTalentOption('Značka pomsty', 'Základní útok sníží dmg cíle o 2 %, max. 10 %, a dává +1 % vlastní dmg/stack.'),
      RuneTalentOption('Hlad Propasti', 'Proti cíli s DoT/kletbou +8 % dmg.'),
    ],
    [
      RuneTalentOption('Připravená zuřivost', 'Začne s 25 zdroje.'),
      RuneTalentOption('Bolest jako palivo', 'Přímý dmg vytvoří 5 zdroje, max. 1× za kolo.'),
      RuneTalentOption('Démonické tempo', 'Extra Attack má 25% šanci cooldown -1; bez rekurze.'),
    ],
    [
      RuneTalentOption('Felová smršť', 'Po aktivním spellu další základní útok provede druhý 40% zásah a vytvoří Fury.'),
      RuneTalentOption('Odvetný plamen', 'Po poškození absorbu základní útok označí cíl; další obranný spell jej popálí a obnoví část štítu.'),
      RuneTalentOption('Čepel Propasti', 'Základní útok do cíle s kletbou okamžitě tikne nejsilnější DoT za 50 %.'),
    ],
    [
      RuneTalentOption('Démonický běs', 'Payoff class burst okna je o 30 % silnější; jeho trvání ani požadavky se nemění.'),
      RuneTalentOption('Nesmrtelná pomsta', 'Po přijetí 25 % Max HP dmg se další obranný/odvetný class efekt zesílí o 30 %.'),
      RuneTalentOption('Pohlcení Propastí', 'Při max stackách kletby okamžitě exploduje za 30 % celkové zbývající DoT hodnoty; DoT nezmizí.'),
    ],
    [
      RuneTalentOption('Felová relikvie', 'Relic proc během burst okna je o 30 % silnější a vyvolá 30% základní útok.'),
      RuneTalentOption('Relikvie pomsty', 'Relic obrana při zásahu vrátí 30 % mitigovaného dmg jako Fel damage v rámci capu.'),
      RuneTalentOption('Relikvie Propasti', 'Relic spell obnoví kletbu a okamžitě spustí její 50% tick.'),
    ],
  ],
  HeroClass.necromancer: [
    [
      RuneTalentOption('Kostěné brnění', 'Začne s absorbem 13 % Max HP.'),
      RuneTalentOption('Morové tělo', 'DoT dmg -15 %; první cizí DoT vytvoří absorb 5 % Max HP.'),
      RuneTalentOption('Krvavá oběť', 'Pod 40 % HP spotřebuje část zdroje a vytvoří absorb 15 % Max HP. 1× za boj.'),
    ],
    [
      RuneTalentOption('Tříštivé kosti', 'Minion/kostěný útok sníží Armor o 3 %, max. 15 %.'),
      RuneTalentOption('Rozšířená nákaza', '+4 % dmg za každý odlišný vlastní DoT, max. 12 %.'),
      RuneTalentOption('Krvavé znamení', 'Po obětování HP je další útočný spell o 15 % silnější.'),
    ],
    [
      RuneTalentOption('Připravené duše', 'Začne s 25 zdroje / 1 duší dle resource implementace.'),
      RuneTalentOption('Sklizeň bolesti', 'DoT tick může vrátit 4 zdroje, max. 1× za kolo.'),
      RuneTalentOption('Vůle mrtvých', 'Zničení absorbu/sluhy zkrátí cooldown o 1, max. 1× za 2 kola.'),
    ],
    [
      RuneTalentOption('Kostěný povel', 'Po základním útoku sluha provede 40% útok; po minion spellu základní útok obnoví část jeho štítu.'),
      RuneTalentOption('Nosič moru', 'Základní útok do nakaženého cíle okamžitě tikne nejkratší DoT za 50 %.'),
      RuneTalentOption('Krvavý obřad', 'Spell s HP cenou nabije další základní útok; healne 30 % zaplaceného HP a vytvoří stack Rituálu.'),
    ],
    [
      RuneTalentOption('Vládce legie', 'Payoff class minion pasivky je o 30 % silnější; smrt sluhy předá příštímu spellu část jeho síly.'),
      RuneTalentOption('Epidemie', 'Při max disease stackách všechny vlastní DoT provedou extra 50% tick; požadovaný počet stacků se nezvyšuje.'),
      RuneTalentOption('Zakázaná krev', 'Damage/heal/absorb class efektu vyvolaného obětí HP je o 30 % silnější.'),
    ],
    [
      RuneTalentOption('Relikvie kostí', 'Relic spell přikáže sluhovi okamžitý 50% útok a obnoví jeho ochranný efekt.'),
      RuneTalentOption('Relikvie moru', 'Relic proc prodlouží všechny vlastní DoT o 1 kolo a jeden z nich tikne za 50 %.'),
      RuneTalentOption('Relikvie krvavého oltáře', 'Relic efekt po zaplacení HP je o 30 % silnější; 30 % zaplaceného HP se vrátí jako absorb.'),
    ],
  ],
};

// Hlavní/vedlejší stat a Tank Armor koeficient PRO KONKRÉTNÍ SPECIALIZACI (ne jen třídu) -
// viz GameState.specStatProfile. mainStat vždy plnou váhou (1.0), secondaryStat (pokud není
// null) váhou secondaryWeight (0.2-0.5 dle toho, jak moc je daná spec hybridní).
class SpecStatProfile {
  final String mainStat;
  final String? secondaryStat;
  final double secondaryWeight;
  final double tankArmorCoefficient;
  const SpecStatProfile(this.mainStat, this.secondaryStat, this.secondaryWeight, {this.tankArmorCoefficient = 1.0});
}
enum LegendaryRelic { gladiatorCrest, bulwarkCore, soulReaper, chronosSigil }
enum RiftSeasonTheme { bastion, plague, precision, chaos }
enum RiftDailyMutator { frozenCurse, arcaneStorm, bloodMoon, shatteredArmor, decay, unstableTime }
extension RiftDailyMutatorInfo on RiftDailyMutator {
 String get displayName => const ["Ledové prokletí","Arkánová bouře","Krvavý měsíc","Roztříštěná zbroj","Rozklad","Nestabilní čas"][index];
 String get description => const ["Strážce má +40 % HP, odměny +25 %.","Strážce má +50 % ATK. Obranné specializace získají +25 % odměn.","Léčení -50 %, lifesteal +25 %.","Obrana strážce -50 %, jeho útok +25 %.","DoT -40 %, přímé poškození +20 %.","Cooldowny -25 %, léčení a lifesteal -35 %."][index];
}
extension LegendaryRelicInfo on LegendaryRelic {
 String get displayName => const ["Hřeben gladiátora","Jádro bašty","Žnec duší","Chronosův symbol"][index];
 String get description => const ["Přímé poškození a kritické zásahy.","MaxHP a absorb štíty.","Lifesteal, execute a heal po zabití.","Zkrácení cooldownů."][index];
}
extension RiftSeasonInfo on RiftSeasonTheme {
 String get displayName => const ["Sezóna Bašty","Morová sezóna","Sezóna Přesnosti","Sezóna Chaosu"][index];
 String get description => const ["Štíty +50 %, léčení -25 %.","DoT +75 %, přímé poškození -15 %.","Crit damage +50 %, dodge -10 p. b.","Nepřátelé +40 % ATK, odměny +50 %."][index];
}
enum Rarity { common, rare, epic, legendary, artifact }

// Priorita hodnocení lootu - ovlivňuje váhy v itemPowerScore() (co se počítá jako "lepší item").
// balanced = stávající chování (spec main/secondary stat, tank vs. ofenziva podle profilu).
// offensive = ignoruje přežití, tlačí čistě na damage - pro rychlé farmy/speedrun postup.
// defensive = ignoruje ofenzivu, tlačí na přežití - pro bezpečný postup na vyšší obtížnosti/Hardcore+.
enum LootPriorityMode { balanced, offensive, defensive }
enum QuestType { standard, daily, weekly, monthly }
enum CompanionRole { tank, archer, healer, rogue, guardian, warrior }
enum EquipSlot { weapon, armor, accessory, gloves, boots, ring, helmet, belt, cloak, relic, shoulders }

// ===== HARDCORE MODE — PROKLETÍ OSUDU =====
// Odemyká se prvním zabitím bosse v Lair 100 (viz GameState._handleLairBossDeath).
// Hráč si v Hardcore módu volí právě jedno prokletí navíc k obtížnosti; odměnou je
// (25 × tier) % zlato/dust/xp a (1 × tier) % loot chance - škáluje s hardcoreTier stejně jako
// obtížnost, aby risk/reward zůstal proporční (viz GameState.curseRewardMultiplier / curseLootBonus).
enum CurseOfFate { none, poison, revival, darkness, bloodbath, fragmentation, reflection }

// Definice setu (žánrově obvyklý formát): 4 kusy (1x zbraň, 1x zbroj, 2x přívěsek).
// Za 2 nasazené kusy stejného setu platí "dvoubonus", za 4 kusy silnější "čtyřbonus".
// Sada vázaná na konkrétní (třída, specializace) - viz GameState.activeGearSetDef. Skládá se
// z 8 kusů (bez zbraně a prstenu - viz _createSetItem/_tryDropItem). 2pc = stat (zapečený přímo
// v itemu, žádný speciální kód netřeba), 4pc/6pc/8pc navíc zesílí poškození schopností i útoků
// a přežitelnost - viz GameState.gearSetPhysDmgBonus/gearSetMagDmgBonus/gearSetDefHpBonus.
class GearSetDef {
  final String id;
  final HeroClass heroClass;
  final int specialization; // 1/2/3 - musí odpovídat GameState.specialization, aby set vůbec fungoval
  final String name;
  final String statName; // stat, co set přidává na 2pc (Strength/Agility/Wisdom/Vitality)
  final int statValue;
  final String twoPieceDesc;
  final String fourPieceDesc;
  final String sixPieceDesc;
  final String eightPieceDesc;
  const GearSetDef({
    required this.id,
    required this.heroClass,
    required this.specialization,
    required this.name,
    required this.statName,
    required this.statValue,
    required this.twoPieceDesc,
    required this.fourPieceDesc,
    required this.sixPieceDesc,
    required this.eightPieceDesc,
  });
}

// Unikátní zbraň na úrovni artefaktu, vázaná na konkrétní (třída, specializace) - vyrábí ji
// Runový kovář, ale JEN pokud má hráč specializaci už odemčenou (viz GameState.specialization).
// Na rozdíl od GearSetDef jde o jediný kus (slot zbraně), ne o sadu, a nescáluje s patrem -
// je to jednorázový craft s pevnými staty, podobně jako Prsten Osudu (_createFateRing).
class ArtifactWeaponDef {
  final String id;
  final HeroClass heroClass;
  final int specialization; // 1/2/3 - musí odpovídat GameState.specialization
  final String name;
  final String description;
  const ArtifactWeaponDef({
    required this.id,
    required this.heroClass,
    required this.specialization,
    required this.name,
    required this.description,
  });
}

// ===== HARDCORE SET ITEMY (neonově modrá) =====
// Na rozdíl od GearSetDef (SET vybavení pro normální hru, 8 kusů, plošné % bonusy) - tenhle
// 6-kusový bonus MĚNÍ fungování konkrétních jmenovaných schopností (ne jen plošná čísla).
// 2pc = stat + upraví ability1, 4pc = navíc upraví ability2, 6pc = navíc upraví ability3.
// Sety padají jen v Hardcore Mode.
class HardcoreSetDef {
  final String id;
  final HeroClass heroClass;
  final int specialization; // 1/2/3 - musí odpovídat GameState.specialization, aby set vůbec fungoval
  final String name;
  final String statName; // stat, co set přidává na 2pc (Strength/Agility/Wisdom/Vitality)
  final int statValue;
  final String twoPieceDesc;
  final String fourPieceDesc;
  final String sixPieceDesc;
  final String eightPieceDesc;
  const HardcoreSetDef({
    required this.id,
    required this.heroClass,
    required this.specialization,
    required this.name,
    required this.statName,
    required this.statValue,
    required this.twoPieceDesc,
    required this.fourPieceDesc,
    required this.sixPieceDesc,
    this.eightPieceDesc = "+5 % poškození schopností a útoků, +10 % obrana a max HP.",
  });
}

String slotDisplayName(EquipSlot? slot) {
  switch (slot) {
    case EquipSlot.weapon:
      return "Zbraň";
    case EquipSlot.armor:
      return "Zbroj";
    case EquipSlot.accessory:
      return "Přívěsek";
    case EquipSlot.gloves:
      return "Rukavice";
    case EquipSlot.boots:
      return "Boty";
    case EquipSlot.ring:
      return "Prsten";
    case EquipSlot.helmet:
      return "Přilba";
    case EquipSlot.belt:
      return "Opasek";
    case EquipSlot.cloak:
      return "Plášť";
    case EquipSlot.shoulders:
      return "Ramenní chrániče";
    case EquipSlot.relic:
      return "Relic";
    case null:
      return "";
  }
}

// Návratová hodnota _castDkSigil() (viz GameState) - dmg/heal/shield doplní volající funkce do
// vlastní HP proměnné cíle (arenaOpponentHp/currentEnemyHp/currentLairBossHp/worldBossHp),
// extra je text připojený do combat message.
class _DkSigilResult {
  final int dmg; final int heal; final int shield; final String extra;
  const _DkSigilResult(this.dmg, this.heal, this.shield, this.extra);
}

class StatusEffect {
  final String name;
  final String description;
  int duration; // v kolech / ticích
  final bool isBuff;
  final int dotDamage; // Poškození za kolo (krvácení/zapálení z run) - 0 pro obyčejné efekty.
  // ===== Obecné procentuální modifikátory pro systém nepřátelských schopností (viz
  // enemyAbilityEffects) - záporná hodnota = debuff, kladná = buff. Aplikují se v
  // physAtk/magAtk/armor/critChance/dodgeChance/blockChance getterech (sečtou se přes
  // všechny aktivní heroEffects). 0 = beze změny, takže staré efekty bez těchto polí
  // fungují úplně stejně jako dřív.
  final double physAtkMod;
  final double magAtkMod;
  final double armorMod;
  final double critMod;
  final double dodgeMod;
  final double blockMod;

  StatusEffect({
    required this.name,
    required this.description,
    required this.duration,
    required this.isBuff,
    this.dotDamage = 0,
    this.physAtkMod = 0,
    this.magAtkMod = 0,
    this.armorMod = 0,
    this.critMod = 0,
    this.dodgeMod = 0,
    this.blockMod = 0,
  });

  factory StatusEffect.statDebuff({required String name, required String description, required int duration, required Map<String, double> mods}) {
    return StatusEffect(
      name: name, description: description, duration: duration, isBuff: false,
      physAtkMod: mods['phys'] ?? 0, magAtkMod: mods['mag'] ?? 0, armorMod: mods['armor'] ?? 0,
      critMod: mods['crit'] ?? 0, dodgeMod: mods['dodge'] ?? 0, blockMod: mods['block'] ?? 0,
    );
  }
}

// ===== COMBAT FX (vizuální feedback: dodge/blok/zásah/crit/vznik štítu) =====
// Jednotný event systém pro "juice" efekty v boji - jeden typ eventu pokrývá jak
// létající damage čísla, tak dodge/blok/crit/absorb, protože vizuálně jde vždy
// o totéž (kus textu, co vyletí a zmizí), jen s jiným stylem podle FxKind.
enum FxKind { normalDamage, critDamage, miss, blocked, absorbed, shieldGained, statusApplied, explosionDamage, stunned }
enum FxSide { hero, enemy }
// Velký "hero moment" burst overlay (viz RelicBurstOverlay) - vizuálně odlišený podle DK sigilu / Hunter toulce.
enum RelicBurstKind { iceShatter, plagueApocalypse, bloodEmperor, executionShot, alphaHowl, ghostLeap, rampage, guardianBreak, warlordCommand, eternalDawn, lastJudgement, apostleZeal, flashover, absoluteZero, paradoxEcho, thousandStrikes, mountainStrike, perfectBalance, starfall, forestBurst, natureHeart, boneLord, plagueFall, immortalRitual, nemesisJudgement, bladeDance, lightningStorm, faithBurst, finalVerdict, divineGrace, doomVerdict, abyssRitual, abyssFall }

// ===== SPELL FX (unikátní epický vizuál pro KAŽDÝ cast spellu) - na rozdíl od RelicBurstKind
// výš, který je jen recolor jednoho sdíleného shockwave+shard efektu pro relic finishery.
// Tohle jsou vlastní, per-spell odlišné tvary (viz _SpellFxPainter ve screens.dart).
// Postupně doplňováno napříč třídami - zatím Death Knight (jeho jediné 2 aktivní spelly).
// SpellFxKind: dkCursedStrike/dkCurseExplosion/healerBlessing/healerJudgment mají vlastní ručně
// malovaný CustomPainter (viz _SpellFxPainter v screens.dart). Všechny ostatní níž jedou přes
// generický "archetyp" systém (_paintArchetype + kSpecTheme v screens.dart) - barvy + tvarový
// motiv podle specializace, ať má KAŽDÁ zbývající specializace ve hře vlastní odlišný vizuál,
// aniž by pro každou musel existovat ručně psaný painter.
enum SpellFxKind {
  dkCursedStrike, dkCurseExplosion, healerBlessing, healerJudgment,
  // Warrior
  berserk, warlord, valhallaWarrior,
  // Hunter
  assassin, shadowMaster, voidStalker,
  // Healer (zbývající tier - Priest/Prorok už mají vlastní výš)
  lightBearer,
  // Death Knight (zbývající tier - DarkKnight/PlagueLord už mají vlastní výš)
  deathReaper,
  // Mage
  elementalist, arcanist, archmage,
  // Duelist
  bladeDancer, bladeMaster, stormblade,
  // Monk
  disciple, grandmaster, enlightened,
  // Druid
  astralDruid, moonfury, elderTreant,
  // Paladin
  faithGuardian, retributor, crusader,
  // Demon Hunter
  felBlade, demonSlayer, abyssWalker,
  // Necromancer
  boneLord, deathSovereign, graveWarden,
  // ===== Nepřátelská schopnost (EnemyAbilityKind, viz enemyAbilityEffects) - seskupeno
  // tematicky, ne 1:1 na kind, protože 19 kindů je hlavně mechanika, ne unikátní vizuál. =====
  lairBossStrike, lairBossCurse, lairBossPlague, lairBossBind, lairBossEmpower, lairBossDrain,
}

class CombatFxEvent {
  final int id;
  final FxKind kind;
  final FxSide side;
  final int value; // dmg/shield hodnota, 0 pro miss
  final double jitter; // -0.5..0.5, horizontální rozptyl aby se čísla nepřekrývala 1:1
  final String? label; // volitelný vlastní text (statusApplied/stunned) - viz _castDkSigil()
  final RelicBurstKind? burstKind; // pokud nastaveno, CombatFxOverlay k tomu navíc spustí RelicBurstOverlay
  final SpellFxKind? spellFxKind; // pokud nastaveno, CombatFxOverlay k tomu navíc spustí SpellFxOverlay
  CombatFxEvent({required this.id, required this.kind, required this.side, this.value = 0, required this.jitter, this.label, this.burstKind, this.spellFxKind});
}

class Companion {
  final String name;
  final CompanionRole role;
  int level;
  bool isRecruited;

  Companion({
    required this.name,
    required this.role,
    this.level = 1,
    this.isRecruited = false,
  });

  int get powerBonus => name == "Thorin" ? level * 10 : (name == "Henry" ? level * 20 : (name == "Anri" ? level * 20 : level * 15));
}

class Quest {
  final String id;
  final String title;
  final String description;
  final int targetFloor;
  final int rewardDust;
  final int rewardGold;
  final HeroClass? requiredClass;
  final QuestType type;
  final int targetKills;
  int currentKills;
  bool isCompleted = false;
  // Rozšířené podmínky pro endgame questy (Lair/Paragon/Hardcore/specializace/společník/Rift).
  // 0/false = podmínka se nekontroluje.
  final int requiredLairFloor;
  final int requiredParagonLevel;
  final bool requiresSpecialization;
  final bool requiresHardcore;
  final bool requiresCompanion;
  final int requiredRiftTier;
  final bool requiresCurse;
  // Opakovatelná varianta requiredRiftTier - pro daily/weekly/monthly questy: kolik Trhlin je
  // třeba zdolat V TOMTO OBDOBÍ (kontroluje se proti riftClearsToday/ThisWeek/ThisMonth podle q.type),
  // ne permanentní tier-rekord. Použij tohle pro opakovatelné questy, requiredRiftTier jen pro
  // jednorázové (standard) questy typu "dosáhni tieru X poprvé".
  final int requiredRiftClears;
  // Krystalová odměna (0 = žádná - většina starších questů dává jen Dust/Gold). Přidáno pro
  // měsíční "grind" questy vázané na Normal obtížnost, viz requiresNormalDifficulty.
  final int rewardCrystals;
  // Pokud je nastaveno, počítají se jen zabití TOHOTO konkrétního nepřítele (currentEnemyName),
  // ne libovolného. null = počítá se každé zabití (jako dřív).
  final String? requiredEnemyName;
  // Pokud true, zabití se počítá jen na Normal obtížnosti (ne Hardcore/Předpeklí/Peklo) - typicky
  // pro měsíční questy cílené na hráče, co ještě normal obtížnost "farmí"/procházejí.
  final bool requiresNormalDifficulty;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    this.targetFloor = 0,
    required this.rewardDust,
    required this.rewardGold,
    this.requiredClass,
    this.type = QuestType.standard,
    this.targetKills = 0,
    this.currentKills = 0,
    this.requiredLairFloor = 0,
    this.requiredParagonLevel = 0,
    this.requiresSpecialization = false,
    this.requiresHardcore = false,
    this.requiresCompanion = false,
    this.requiredRiftTier = 0,
    this.requiresCurse = false,
    this.requiredRiftClears = 0,
    this.rewardCrystals = 0,
    this.requiredEnemyName,
    this.requiresNormalDifficulty = false,
  });
}

// ===== ACHIEVEMENTY =====
// Trvalé, nereseuje se smrtí (jako Paragon/classRanks). Odemčený achievement uděluje
// titul (kosmetika) a jednorázovou odměnu. Definice viz GameState._achievementDefs.
enum AchievementId {
  firstBlood,
  floor20,
  floor50,
  towerConqueror, // floor 100 ve věži
  lairFloor35,
  lairFloor70,
  lairFloor85,
  lairFloorFinal, // Lair 100 boss
  paragon100,
  paragon500,
  paragon1000,
  firstSpecialization,
  fullSquad, // všech 5 společníků povoláno
  firstLegendary,
  firstSet,
  hardcoreAwakened,
  curseChosen,
  allCursesTried,
  gemSocketed,
  riftPusher10,
  riftPusher50,
  riftPusher100,
  // ===== ROZŠÍŘENÍ =====
  magePioneer, // patro 5 s Mágem
  duelistPioneer, // patro 5 se Šermířem
  survivor20, // 20 úmrtí (= odemyká Offline Progress)
  survivor100, // 100 úmrtí
  promoRedeemer, // první uplatněný promo kód
  masterSmith, // blacksmith rank 50
  masterAlchemist, // alchemist rank 50
  fullyUpgradedItem, // item vylepšený na max úroveň (+10)
  setEquipped, // plný 4-kusový SET nasazený najednou
  questVeteran, // 20 splněných questů celkem (napříč historií, ne jen aktuálně aktivní)
  monthlyChampion, // první splněný monthly quest
  adSupporter, // shlédnuta první rewarded reklama za Rift pokus
  companionVeteran, // libovolný společník na levelu 10+
  predpekliOpened, // odemčeno a poprvé aktivováno Předpeklí
  pekloOpened, // odemčeno a poprvé aktivováno Peklo
  // (odstraněno: gatekeeperDefeated - Strážce Brány/patro 101 shortcut byl z Lairu odstraněn)
  // ===== ARÉNA =====
  arenaLeagueDrevo,
  arenaLeagueOcel,
  arenaLeagueBronz,
  arenaLeagueStribro,
  arenaLeagueZlato,
  arenaLeaguePlatina,
  arenaLeagueDiamant,
  arenaLeagueMistr,
  arenaLeagueLegendarni,
  arenaLeagueMyticka,
  arenaGladiator, // vstup do endless Gladiátorské ligy
  arenaRating2500, // Gladiátor rating 2500 - titul "Nezničitelný"
  arenaRating5000, // Gladiátor rating 5000 - titul "God of Arena"
  // ===== ASCENSION / ENDLESS SCALE / ARTEFAKT FORGE / ELITNÍ SETY 8pc =====
  ascensionHardcore, // Ascension I - poražen Lair 100 v Normal, odemčen Hardcore
  ascensionPredpekli, // Ascension II - odemčeno Předpeklí
  ascensionPeklo, // Ascension III - odemčeno Peklo
  ascensionComplete, // Ascension IV - Peklo patro 100 poraženo, odemčen Endless Scale
  soulDemonFirstBlood, // první poražený Soul Demon v Endless Scale
  soulDemonSlayer, // 50 poražených Soul Demonů
  artifactForged, // artefaktová zbraň vylepšena aspoň 1× v Runovém kováři
  // Kompletní SET nasazený najednou - zvlášť pro každou úroveň (klasický 8pc, Hardcore/Předpeklí/Peklo 8pc).
  setFull8pcClassic,
  hardcoreSetFull8pc,
  predpekliSetFull8pc,
  pekloSetFull8pc,
}

class AchievementDef {
  final AchievementId id;
  final String name;
  final String description;
  final String title; // kosmetický titul udělený po odemčení
  final int rewardGold;
  final int rewardDust;
  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.title,
    this.rewardGold = 0,
    this.rewardDust = 0,
  });
}

// ===== PROMO KÓDY =====
// Klientská (offline) hra bez backendu - katalog je natvrdo v appce a validuje se proti
// hodinám zařízení. To znamená: nový/změněný kód vyžaduje nové vydání appky (nejde přidat
// za běhu ze serveru), a časové omezení jde jen tak přísně, jak důvěryhodné jsou hodiny
// hráčova zařízení (jde je posunout zpátky). Pro čistě kosmetické/menší odměny je to v pořádku;
// pro cokoliv cenného by to jednou chtělo skutečný backend.
class PromoCodeDef {
  final String code; // porovnává se case-insensitive, bez okolních mezer
  final String description;
  final DateTime? validUntil; // pevné kalendářní datum expirace, null = použij floatingExpiry (nebo bez expirace, pokud je taky null)
  // Plovoucí expirace: platnost neběží od pevného data, ale od okamžiku, kdy hráč SPLNIL
  // requiredLevel (viz GameState.levelMilestoneReachedAt). Skutečné datum expirace je tedy
  // pro každého hráče jiné - počítá se jako "kdy dosáhl requiredLevel" + floatingExpiry.
  // Má přednost před validUntil, pokud je nastavené.
  final Duration? floatingExpiry;
  final int rewardGold;
  final int rewardCrystals;
  final int rewardDust;
  final int rewardLegendaryEssence;
  final int rewardMaterials;
  final int rewardConquerorCoins;
  final int requiredLevel; // 0 = bez omezení, jinak minimální level hrdiny pro uplatnění
  const PromoCodeDef({
    required this.code,
    required this.description,
    this.validUntil,
    this.floatingExpiry,
    this.rewardGold = 0,
    this.rewardCrystals = 0,
    this.rewardDust = 0,
    this.rewardLegendaryEssence = 0,
    this.rewardMaterials = 0,
    this.rewardConquerorCoins = 0,
    this.requiredLevel = 0,
  });
}

// ===== RUNOVÝ ČARODĚJ — DATOVÉ MODELY =====
// End-game systém odemčený po zabití bosse na patře 20+. Runy nesou jména
// ze starého severského runového písma (Elder Futhark) - žádná spojitost
// čistě vlastní severský runový koncept.

// ===== ARÉNA (PvE 1:1, mirror-match) =====
// 10 lig, 5 hvězd na postup do další. Soupeř = náhodná třída/specializace se staty odvozenými
// z HRÁČOVÝCH vlastních statů (ne z floor/tier jako Tower/Lair/Rift) × mírný ligový bonus
// (+1 % za ligu, tzn. liga 1 = ×1,01 ... liga 10 = ×1,10). Win = +1 hvězda, Loss = -1 hvězda
// (floor na 0, žádná degradace zpět do nižší ligy).
enum ArenaLeague { drevo, ocel, bronz, stribro, zlato, platina, diamant, mistr, legendarni, myticka }

extension ArenaLeagueLabel on ArenaLeague {
  String get label {
    switch (this) {
      case ArenaLeague.drevo: return "Dřevo";
      case ArenaLeague.ocel: return "Ocel";
      case ArenaLeague.bronz: return "Bronz";
      case ArenaLeague.stribro: return "Stříbro";
      case ArenaLeague.zlato: return "Zlato";
      case ArenaLeague.platina: return "Platina";
      case ArenaLeague.diamant: return "Diamant";
      case ArenaLeague.mistr: return "Mistr";
      case ArenaLeague.legendarni: return "Legendární";
      case ArenaLeague.myticka: return "Mýtická";
    }
  }

  // Titulové slovo udělené za DOKONČENÍ dané ligy (všech 5 úrovní) - kombinuje se s názvem
  // aktuální sezóny do finálního titulu, např. "Rival od Chaos" (viz GameState.seasonalArenaTitle).
  String get titleWord {
    switch (this) {
      case ArenaLeague.drevo: return "Nováček";
      case ArenaLeague.ocel: return "Bojovník";
      case ArenaLeague.bronz: return "Zocelený";
      case ArenaLeague.stribro: return "Vyzývatel";
      case ArenaLeague.zlato: return "Šampion";
      case ArenaLeague.platina: return "Rival";
      case ArenaLeague.diamant: return "Elitní";
      case ArenaLeague.mistr: return "Mistr Arény";
      case ArenaLeague.legendarni: return "Legenda";
      case ArenaLeague.myticka: return "Mytický Šampion";
    }
  }

  AchievementId get achievementId {
    switch (this) {
      case ArenaLeague.drevo: return AchievementId.arenaLeagueDrevo;
      case ArenaLeague.ocel: return AchievementId.arenaLeagueOcel;
      case ArenaLeague.bronz: return AchievementId.arenaLeagueBronz;
      case ArenaLeague.stribro: return AchievementId.arenaLeagueStribro;
      case ArenaLeague.zlato: return AchievementId.arenaLeagueZlato;
      case ArenaLeague.platina: return AchievementId.arenaLeaguePlatina;
      case ArenaLeague.diamant: return AchievementId.arenaLeagueDiamant;
      case ArenaLeague.mistr: return AchievementId.arenaLeagueMistr;
      case ArenaLeague.legendarni: return AchievementId.arenaLeagueLegendarni;
      case ArenaLeague.myticka: return AchievementId.arenaLeagueMyticka;
    }
  }
}

String heroClassLabel(HeroClass c) {
  switch (c) {
    case HeroClass.warrior: return "Válečník";
    case HeroClass.hunter: return "Lovec";
    case HeroClass.healer: return "Léčitel";
    case HeroClass.deathknight: return "Rytíř Smrti";
    case HeroClass.mage: return "Mág";
    case HeroClass.duelist: return "Šermíř";
    case HeroClass.monk: return "Mnich";
    case HeroClass.druid: return "Druid";
    case HeroClass.paladin: return "Paladin";
    case HeroClass.demonhunter: return "Lovec Démonů";
    case HeroClass.necromancer: return "Nekromant";
    case HeroClass.none: return "?";
  }
}

enum RuneBranch { defense, offense, piercing }

enum RuneEffectType {
  critChance,
  critDamage,
  blockChance,
  dodgeChance,
  damageReduction,
  armorPen,
  bossDamage,
  bleedChance,
  burnChance,
  lifesteal,
}

extension RuneEffectTypeLabel on RuneEffectType {
  String get label {
    switch (this) {
      case RuneEffectType.critChance: return 'Kritická šance';
      case RuneEffectType.critDamage: return 'Kritické poškození';
      case RuneEffectType.blockChance: return 'Šance na blok';
      case RuneEffectType.dodgeChance: return 'Šance na úhyb';
      case RuneEffectType.damageReduction: return 'Snížení obdrženého poškození';
      case RuneEffectType.armorPen: return 'Průraz obrany';
      case RuneEffectType.bossDamage: return 'Poškození bossům';
      case RuneEffectType.bleedChance: return 'Šance na krvácení';
      case RuneEffectType.burnChance: return 'Šance na zapálení';
      case RuneEffectType.lifesteal: return 'Odčerpání života';
    }
  }
}

extension RuneBranchLabel on RuneBranch {
  String get label {
    switch (this) {
      case RuneBranch.defense: return 'Obranná větev';
      case RuneBranch.offense: return 'Útočná větev';
      case RuneBranch.piercing: return 'Průrazná větev';
    }
  }
}

class RuneNode {
  final String id;
  final RuneBranch branch;
  final int tier; // 1-4 = běžná runa, 5 = master runa
  final String name; // jméno runy ze starého severského písma
  final String description;
  final RuneEffectType effectType;
  final double value;
  final bool isMaster;
  const RuneNode({
    required this.id,
    required this.branch,
    required this.tier,
    required this.name,
    required this.description,
    required this.effectType,
    required this.value,
    this.isMaster = false,
  });
}

class RuneTree {
  static const List<RuneNode> allNodes = [
    // ----- OBRANNÁ VĚTEV -----
    RuneNode(id: 'def1', branch: RuneBranch.defense, tier: 1, name: 'Algiz', description: 'Runa ochrany. +1 % šance na blok.', effectType: RuneEffectType.blockChance, value: 0.01),
    RuneNode(id: 'def2', branch: RuneBranch.defense, tier: 2, name: 'Isa', description: 'Runa ledového klidu. +1 % šance na úhyb.', effectType: RuneEffectType.dodgeChance, value: 0.01),
    RuneNode(id: 'def3', branch: RuneBranch.defense, tier: 3, name: 'Berkano', description: 'Runa obnovy. -2 % obdrženého poškození.', effectType: RuneEffectType.damageReduction, value: 0.02),
    RuneNode(id: 'def4', branch: RuneBranch.defense, tier: 4, name: 'Othala', description: 'Runa dědictví předků. +2 % šance na blok.', effectType: RuneEffectType.blockChance, value: 0.02),
    RuneNode(id: 'def5', branch: RuneBranch.defense, tier: 5, name: 'Mannaz', description: 'Runa lidství. +3 % šance na úhyb.', effectType: RuneEffectType.dodgeChance, value: 0.03),
    RuneNode(id: 'def6', branch: RuneBranch.defense, tier: 6, name: 'Ingwaz', description: 'Runa plodnosti a růstu. -3 % obdrženého poškození.', effectType: RuneEffectType.damageReduction, value: 0.03),
    RuneNode(id: 'def7', branch: RuneBranch.defense, tier: 7, name: 'Perthro', description: 'Master runa osudu. Dva náhodné efekty z obranné větve.', effectType: RuneEffectType.damageReduction, value: 0.0, isMaster: true),

    // ----- ÚTOČNÁ VĚTEV -----
    RuneNode(id: 'off1', branch: RuneBranch.offense, tier: 1, name: 'Thurisaz', description: 'Runa trnu. +1 % kritická šance.', effectType: RuneEffectType.critChance, value: 0.01),
    RuneNode(id: 'off2', branch: RuneBranch.offense, tier: 2, name: 'Uruz', description: 'Runa pralesního tura. +8 % šance vyvolat krvácení při zásahu.', effectType: RuneEffectType.bleedChance, value: 0.08),
    RuneNode(id: 'off3', branch: RuneBranch.offense, tier: 3, name: 'Kenaz', description: 'Runa pochodně. +8 % šance zapálit nepřítele při zásahu.', effectType: RuneEffectType.burnChance, value: 0.08),
    RuneNode(id: 'off4', branch: RuneBranch.offense, tier: 4, name: 'Tiwaz', description: 'Runa vítězství. +15 % kritické poškození.', effectType: RuneEffectType.critDamage, value: 0.15),
    RuneNode(id: 'off5', branch: RuneBranch.offense, tier: 5, name: 'Gebo', description: 'Runa daru. +10 % šance vyvolat krvácení při zásahu.', effectType: RuneEffectType.bleedChance, value: 0.10),
    RuneNode(id: 'off6', branch: RuneBranch.offense, tier: 6, name: 'Wunjo', description: 'Runa radosti z vítězství. +20 % kritické poškození.', effectType: RuneEffectType.critDamage, value: 0.20),
    RuneNode(id: 'off7', branch: RuneBranch.offense, tier: 7, name: 'Sowilo', description: 'Master runa slunce. Dva náhodné efekty z útočné větve.', effectType: RuneEffectType.critChance, value: 0.0, isMaster: true),

    // ----- PRŮRAZNÁ VĚTEV -----
    RuneNode(id: 'pi1', branch: RuneBranch.piercing, tier: 1, name: 'Raidho', description: 'Runa cesty. +5 % průraz obrany nepřítele.', effectType: RuneEffectType.armorPen, value: 0.05),
    RuneNode(id: 'pi2', branch: RuneBranch.piercing, tier: 2, name: 'Hagalaz', description: 'Runa krupobití. +5 % poškození bossům.', effectType: RuneEffectType.bossDamage, value: 0.05),
    RuneNode(id: 'pi3', branch: RuneBranch.piercing, tier: 3, name: 'Nauthiz', description: 'Runa nutnosti. +8 % průraz obrany nepřítele.', effectType: RuneEffectType.armorPen, value: 0.08),
    RuneNode(id: 'pi4', branch: RuneBranch.piercing, tier: 4, name: 'Ansuz', description: 'Runa boží moudrosti. +8 % poškození bossům.', effectType: RuneEffectType.bossDamage, value: 0.08),
    RuneNode(id: 'pi5', branch: RuneBranch.piercing, tier: 5, name: 'Eihwaz', description: 'Runa tisu. +10 % průraz obrany nepřítele.', effectType: RuneEffectType.armorPen, value: 0.10),
    RuneNode(id: 'pi6', branch: RuneBranch.piercing, tier: 6, name: 'Jera', description: 'Runa úrody. +10 % poškození bossům.', effectType: RuneEffectType.bossDamage, value: 0.10),
    RuneNode(id: 'pi7', branch: RuneBranch.piercing, tier: 7, name: 'Dagaz', description: 'Master runa úsvitu. Dva náhodné efekty z průrazné větve.', effectType: RuneEffectType.armorPen, value: 0.0, isMaster: true),
  ];

  static RuneNode? byId(String id) {
    for (final n in allNodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  static List<RuneNode> branchNodes(RuneBranch b) => allNodes.where((n) => n.branch == b).toList()..sort((a, b) => a.tier.compareTo(b.tier));

  static RuneNode masterFor(RuneBranch b) => allNodes.firstWhere((n) => n.branch == b && n.isMaster);
}

/// Vytvořená Master runa - dva náhodné efekty vybrané z odemčených run dané větve.
class MasterRuneData {
  final RuneBranch branch;
  final List<RuneEffectType> effects;
  final List<double> values;
  MasterRuneData({required this.branch, required this.effects, required this.values});

  Map<String, dynamic> toJson() => {
        "branch": branch.name,
        "effects": effects.map((e) => e.name).toList(),
        "values": values,
      };

  factory MasterRuneData.fromJson(Map<String, dynamic> json) => MasterRuneData(
        branch: RuneBranch.values.firstWhere((b) => b.name == json["branch"], orElse: () => RuneBranch.defense),
        effects: (json["effects"] as List).map((e) => RuneEffectType.values.firstWhere((t) => t.name == e, orElse: () => RuneEffectType.critChance)).toList(),
        values: (json["values"] as List).map((v) => (v as num).toDouble()).toList(),
      );
}


/// ===== STROM SCHOPNOSTÍ ARTEFAKTOVÉ ZBRANĚ (Runový kovář) =====
/// 7 větví: jedna za každý ze 6 typů gemů z Prstenu Osudu (tematicky sladěná s efektem
/// daného gemu) + jedna neutrální (univerzální, nezávislá na gemech). Každá větev má 7 tierů,
/// odemykané lineárně (tier 2 vyžaduje odemčený tier 1 atd.) - stejný princip jako RuneTree,
/// jen bez master uzlu. Efekty recyklují RuneEffectType a sčítají se v GameState.runeEffect(),
/// takže se automaticky projeví ve všech bojových vzorcích, které už runy používají.
enum WeaponSkillBranch { poison, revival, darkness, bloodbath, fragmentation, reflection, neutral }

extension WeaponSkillBranchLabel on WeaponSkillBranch {
  String get label {
    switch (this) {
      case WeaponSkillBranch.poison: return 'Větev Jedu';
      case WeaponSkillBranch.revival: return 'Větev Oživení';
      case WeaponSkillBranch.darkness: return 'Větev Temnoty';
      case WeaponSkillBranch.bloodbath: return 'Větev Krvavé lázně';
      case WeaponSkillBranch.fragmentation: return 'Větev Roztříštění';
      case WeaponSkillBranch.reflection: return 'Větev Odrazu';
      case WeaponSkillBranch.neutral: return 'Neutrální větev';
    }
  }
}

class WeaponSkillNode {
  final String id;
  final WeaponSkillBranch branch;
  final int tier; // 1-7
  final String name;
  final String description;
  final RuneEffectType effectType;
  final double value;
  final bool isMaster; // jen neutrální větev, tier 7 - viz GameState.craftArtifactMasterRune()
  const WeaponSkillNode({
    required this.id,
    required this.branch,
    required this.tier,
    required this.name,
    required this.description,
    required this.effectType,
    required this.value,
    this.isMaster = false,
  });
}

class WeaponSkillTree {
  static const List<WeaponSkillNode> allNodes = [
    // ----- VĚTEV JEDU (posiluje magnitude Gemu Jedu - šance/síla DoT) -----
    // Hodnoty jsou ABSOLUTNÍ bonus k activeGemMagnitude, ne přírůstek - platí vždy jen
    // nejvyšší odemčený tier, ne součet (viz GameState.weaponSkillGemBonus).
    WeaponSkillNode(id: 'ws_poison1', branch: WeaponSkillBranch.poison, tier: 1, name: 'Zkažené ostří', description: '+2 % k síle Gemu Jedu.', effectType: RuneEffectType.bleedChance, value: 0.02),
    WeaponSkillNode(id: 'ws_poison2', branch: WeaponSkillBranch.poison, tier: 2, name: 'Leptavý jed', description: '+4 % k síle Gemu Jedu.', effectType: RuneEffectType.bleedChance, value: 0.04),
    WeaponSkillNode(id: 'ws_poison3', branch: WeaponSkillBranch.poison, tier: 3, name: 'Smrtící nákaza', description: '+6 % k síle Gemu Jedu.', effectType: RuneEffectType.bleedChance, value: 0.06),
    WeaponSkillNode(id: 'ws_poison4', branch: WeaponSkillBranch.poison, tier: 4, name: 'Rozkladný dotek', description: '+9 % k síle Gemu Jedu.', effectType: RuneEffectType.bleedChance, value: 0.09),
    WeaponSkillNode(id: 'ws_poison5', branch: WeaponSkillBranch.poison, tier: 5, name: 'Virulentní kmen', description: '+12 % k síle Gemu Jedu.', effectType: RuneEffectType.bleedChance, value: 0.12),
    WeaponSkillNode(id: 'ws_poison6', branch: WeaponSkillBranch.poison, tier: 6, name: 'Jedová nádoba', description: '+16 % k síle Gemu Jedu.', effectType: RuneEffectType.bleedChance, value: 0.16),
    WeaponSkillNode(id: 'ws_poison7', branch: WeaponSkillBranch.poison, tier: 7, name: 'Mor tisíce ran (Master)', description: 'Master runa - aktivuje synergii s odpovídajícím gemem v Prstenu Osudu (efekt záleží na tvé třídě).', effectType: RuneEffectType.bleedChance, value: 0.0, isMaster: true),
    // ----- VĚTEV OŽIVENÍ (posiluje magnitude Gemu Oživení - šance přežít smrtelnou ránu) -----
    WeaponSkillNode(id: 'ws_revival1', branch: WeaponSkillBranch.revival, tier: 1, name: 'Druhý dech', description: '+2 % k síle Gemu Oživení.', effectType: RuneEffectType.blockChance, value: 0.02),
    WeaponSkillNode(id: 'ws_revival2', branch: WeaponSkillBranch.revival, tier: 2, name: 'Vzdorující duch', description: '+4 % k síle Gemu Oživení.', effectType: RuneEffectType.blockChance, value: 0.04),
    WeaponSkillNode(id: 'ws_revival3', branch: WeaponSkillBranch.revival, tier: 3, name: 'Nezdolná vůle', description: '+6 % k síle Gemu Oživení.', effectType: RuneEffectType.blockChance, value: 0.06),
    WeaponSkillNode(id: 'ws_revival4', branch: WeaponSkillBranch.revival, tier: 4, name: 'Poslední výdech', description: '+9 % k síle Gemu Oživení.', effectType: RuneEffectType.blockChance, value: 0.09),
    WeaponSkillNode(id: 'ws_revival5', branch: WeaponSkillBranch.revival, tier: 5, name: 'Neochvějná kůže', description: '+12 % k síle Gemu Oživení.', effectType: RuneEffectType.blockChance, value: 0.12),
    WeaponSkillNode(id: 'ws_revival6', branch: WeaponSkillBranch.revival, tier: 6, name: 'Přízrak úniku', description: '+16 % k síle Gemu Oživení.', effectType: RuneEffectType.blockChance, value: 0.16),
    WeaponSkillNode(id: 'ws_revival7', branch: WeaponSkillBranch.revival, tier: 7, name: 'Nesmrtelná vůle (Master)', description: 'Master runa - aktivuje synergii s odpovídajícím gemem v Prstenu Osudu (efekt záleží na tvé třídě).', effectType: RuneEffectType.blockChance, value: 0.0, isMaster: true),
    // ----- VĚTEV TEMNOTY (posiluje magnitude Gemu Temnoty - bonus k heal/blok/úhyb/absorb) -----
    WeaponSkillNode(id: 'ws_darkness1', branch: WeaponSkillBranch.darkness, tier: 1, name: 'Stínový nádech', description: '+2 % k síle Gemu Temnoty.', effectType: RuneEffectType.lifesteal, value: 0.02),
    WeaponSkillNode(id: 'ws_darkness2', branch: WeaponSkillBranch.darkness, tier: 2, name: 'Závoj temnoty', description: '+4 % k síle Gemu Temnoty.', effectType: RuneEffectType.lifesteal, value: 0.04),
    WeaponSkillNode(id: 'ws_darkness3', branch: WeaponSkillBranch.darkness, tier: 3, name: 'Hlubinný hlad', description: '+6 % k síle Gemu Temnoty.', effectType: RuneEffectType.lifesteal, value: 0.06),
    WeaponSkillNode(id: 'ws_darkness4', branch: WeaponSkillBranch.darkness, tier: 4, name: 'Temný pakt', description: '+9 % k síle Gemu Temnoty.', effectType: RuneEffectType.lifesteal, value: 0.09),
    WeaponSkillNode(id: 'ws_darkness5', branch: WeaponSkillBranch.darkness, tier: 5, name: 'Vysávající stín', description: '+12 % k síle Gemu Temnoty.', effectType: RuneEffectType.lifesteal, value: 0.12),
    WeaponSkillNode(id: 'ws_darkness6', branch: WeaponSkillBranch.darkness, tier: 6, name: 'Noční clona', description: '+16 % k síle Gemu Temnoty.', effectType: RuneEffectType.lifesteal, value: 0.16),
    WeaponSkillNode(id: 'ws_darkness7', branch: WeaponSkillBranch.darkness, tier: 7, name: 'Absolutní temnota (Master)', description: 'Master runa - aktivuje synergii s odpovídajícím gemem v Prstenu Osudu (efekt záleží na tvé třídě).', effectType: RuneEffectType.lifesteal, value: 0.0, isMaster: true),
    // ----- VĚTEV KRVAVÉ LÁZNĚ (posiluje magnitude Gemu Krvavé lázně - execute bonus pod 30 % HP) -----
    WeaponSkillNode(id: 'ws_bloodbath1', branch: WeaponSkillBranch.bloodbath, tier: 1, name: 'Krvežíznivost', description: '+3 % k síle Gemu Krvavé lázně.', effectType: RuneEffectType.critDamage, value: 0.03),
    WeaponSkillNode(id: 'ws_bloodbath2', branch: WeaponSkillBranch.bloodbath, tier: 2, name: 'Poprava', description: '+6 % k síle Gemu Krvavé lázně.', effectType: RuneEffectType.critDamage, value: 0.06),
    WeaponSkillNode(id: 'ws_bloodbath3', branch: WeaponSkillBranch.bloodbath, tier: 3, name: 'Krvavá lázeň', description: '+9 % k síle Gemu Krvavé lázně.', effectType: RuneEffectType.critDamage, value: 0.09),
    WeaponSkillNode(id: 'ws_bloodbath4', branch: WeaponSkillBranch.bloodbath, tier: 4, name: 'Žíznivá čepel', description: '+13 % k síle Gemu Krvavé lázně.', effectType: RuneEffectType.critDamage, value: 0.13),
    WeaponSkillNode(id: 'ws_bloodbath5', branch: WeaponSkillBranch.bloodbath, tier: 5, name: 'Rozsudek smrti', description: '+17 % k síle Gemu Krvavé lázně.', effectType: RuneEffectType.critDamage, value: 0.17),
    WeaponSkillNode(id: 'ws_bloodbath6', branch: WeaponSkillBranch.bloodbath, tier: 6, name: 'Krvavý rituál', description: '+22 % k síle Gemu Krvavé lázně.', effectType: RuneEffectType.critDamage, value: 0.22),
    WeaponSkillNode(id: 'ws_bloodbath7', branch: WeaponSkillBranch.bloodbath, tier: 7, name: 'Konečná poprava (Master)', description: 'Master runa - aktivuje synergii s odpovídajícím gemem v Prstenu Osudu (efekt záleží na tvé třídě).', effectType: RuneEffectType.critDamage, value: 0.0, isMaster: true),
    // ----- VĚTEV ROZTŘÍŠTĚNÍ (posiluje magnitude Gemu Roztříštění - šance na dvojitý zásah) -----
    WeaponSkillNode(id: 'ws_fragmentation1', branch: WeaponSkillBranch.fragmentation, tier: 1, name: 'Roztříštěný úder', description: '+2 % k síle Gemu Roztříštění.', effectType: RuneEffectType.critChance, value: 0.02),
    WeaponSkillNode(id: 'ws_fragmentation2', branch: WeaponSkillBranch.fragmentation, tier: 2, name: 'Ozvěna čepele', description: '+4 % k síle Gemu Roztříštění.', effectType: RuneEffectType.critChance, value: 0.04),
    WeaponSkillNode(id: 'ws_fragmentation3', branch: WeaponSkillBranch.fragmentation, tier: 3, name: 'Roztříštění duše', description: '+6 % k síle Gemu Roztříštění.', effectType: RuneEffectType.critChance, value: 0.06),
    WeaponSkillNode(id: 'ws_fragmentation4', branch: WeaponSkillBranch.fragmentation, tier: 4, name: 'Dvojitá ozvěna', description: '+9 % k síle Gemu Roztříštění.', effectType: RuneEffectType.critChance, value: 0.09),
    WeaponSkillNode(id: 'ws_fragmentation5', branch: WeaponSkillBranch.fragmentation, tier: 5, name: 'Plamenná ozvěna', description: '+12 % k síle Gemu Roztříštění.', effectType: RuneEffectType.critChance, value: 0.12),
    WeaponSkillNode(id: 'ws_fragmentation6', branch: WeaponSkillBranch.fragmentation, tier: 6, name: 'Rezonance zlomu', description: '+16 % k síle Gemu Roztříštění.', effectType: RuneEffectType.critChance, value: 0.16),
    WeaponSkillNode(id: 'ws_fragmentation7', branch: WeaponSkillBranch.fragmentation, tier: 7, name: 'Nekonečná ozvěna (Master)', description: 'Master runa - aktivuje synergii s odpovídajícím gemem v Prstenu Osudu (efekt záleží na tvé třídě).', effectType: RuneEffectType.critChance, value: 0.0, isMaster: true),
    // ----- VĚTEV ODRAZU (posiluje magnitude Gemu Odrazu - % vráceného poškození) -----
    WeaponSkillNode(id: 'ws_reflection1', branch: WeaponSkillBranch.reflection, tier: 1, name: 'Zrcadlový povrch', description: '+2 % k síle Gemu Odrazu.', effectType: RuneEffectType.damageReduction, value: 0.02),
    WeaponSkillNode(id: 'ws_reflection2', branch: WeaponSkillBranch.reflection, tier: 2, name: 'Odražený úder', description: '+4 % k síle Gemu Odrazu.', effectType: RuneEffectType.damageReduction, value: 0.04),
    WeaponSkillNode(id: 'ws_reflection3', branch: WeaponSkillBranch.reflection, tier: 3, name: 'Věčný odraz', description: '+6 % k síle Gemu Odrazu.', effectType: RuneEffectType.damageReduction, value: 0.06),
    WeaponSkillNode(id: 'ws_reflection4', branch: WeaponSkillBranch.reflection, tier: 4, name: 'Zrcadlová clona', description: '+9 % k síle Gemu Odrazu.', effectType: RuneEffectType.damageReduction, value: 0.09),
    WeaponSkillNode(id: 'ws_reflection5', branch: WeaponSkillBranch.reflection, tier: 5, name: 'Trnitý štít', description: '+12 % k síle Gemu Odrazu.', effectType: RuneEffectType.damageReduction, value: 0.12),
    WeaponSkillNode(id: 'ws_reflection6', branch: WeaponSkillBranch.reflection, tier: 6, name: 'Pomsta zrcadla', description: '+16 % k síle Gemu Odrazu.', effectType: RuneEffectType.damageReduction, value: 0.16),
    WeaponSkillNode(id: 'ws_reflection7', branch: WeaponSkillBranch.reflection, tier: 7, name: 'Dokonalý odraz (Master)', description: 'Master runa - aktivuje synergii s odpovídajícím gemem v Prstenu Osudu (efekt záleží na tvé třídě).', effectType: RuneEffectType.damageReduction, value: 0.0, isMaster: true),
    // ----- NEUTRÁLNÍ VĚTEV -----
    // Dřív duplikovala jména/efekty čarodějových run (Mannaz/Ingwaz/Gebo/Wunjo/Eihwaz/Jera) jako
    // samostatné placené uzly - to je teď zbytečné, protože "Runy v artefaktu" (viz UI výše)
    // umožňuje vsadit KAŽDOU odemčenou čarodějovu runu přímo, zdarma. Zůstává jen Master runa,
    // dostupná hned na tier 1 (nemá po odstranění duplicit už na čem stavět prerekvizitu).
    WeaponSkillNode(id: 'ws_neutral7', branch: WeaponSkillBranch.neutral, tier: 1, name: 'Artefaktová Master runa', description: 'Po vykování: dva náhodné efekty ze VŠECH běžných run čaroděje (silnější, ×1,5).', effectType: RuneEffectType.critChance, value: 0.0, isMaster: true),
  ];

  static WeaponSkillNode? byId(String id) {
    for (final n in allNodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  static List<WeaponSkillNode> branchNodes(WeaponSkillBranch b) => allNodes.where((n) => n.branch == b).toList()..sort((a, b) => a.tier.compareTo(b.tier));
}


class Item {
  final String id;
  final String name;
  final int value;
  final Map<String, int> stats;
  final Rarity rarity;
  final bool isConsumable;
  bool isActive;
  int stackCount;
  final EquipSlot? slot; // Slot vybavení (zbraň/zbroj/přívěsek/rukavice/boty/prsten) - null pro lektvary
  final String? setId; // Pokud je nenull, jde o kus setu (zelená barva)
  int upgradeLevel; // Úroveň vylepšení (0-10), viz GameState.upgradeItem()
  int materialUpgradeLevel; // Úroveň vylepšení statu za suroviny (0-10), jen SET vybavení - viz GameState.upgradeSetMaterial()
  bool isLocked; // Zamčený předmět přežije smrt, i když není zrovna nasazen - viz GameState.toggleItemLock()
  final bool isArtifact; // Prsten Osudu z Lair 100 - nelze zničit/prodat/roztavit, viz GameState.salvageItem()
  List<String?> gemSlots; // Gem sloty (Prsten Osudu má 6) - null = prázdný, jinak jméno osazeného gemu
  final String? hardcoreSetId; // Hardcore-exkluzivní SET (neonově modrá) - odlišné od setId (zelené standardní sety)
                                // Vázané na konkrétní (class, specializace) - viz HardcoreSetDef.
  final String? predpekliSetId; // Předpeklí-exkluzivní SET (fialová) - padá jen v Předpeklí/Peklo -
                                 // viz GameState.predpekliSets.
  final String? pekloSetId; // Peklo-exkluzivní SET (ohnivě rudá) - nejvyšší tier, padá jen v Peklo -
                             // viz GameState.pekloSets.
  final String? specRelicKey; // Pokud nenull, jde o arénový Specializační Relic item (11. slot) -
                               // klíč odpovídá GameState.currentSpecRelicKey, viz equipSlot .relic.
  int artifactWeaponForgeLevel; // Runový kovář: vylepšení artefaktové zbraně obětováním silnější
                                 // zbraně z batohu (+1000 surovin) - viz GameState.forgeArtifactWeapon().
                                 // NEMÁ strop (na rozdíl od upgradeLevel/materialUpgradeLevel výše).

  static const int maxUpgradeLevel = 10;
  static const double upgradeBonusPerLevel = 0.08; // +8 % ke statům za úroveň
  static const int maxMaterialUpgradeLevel = 10;
  static const double materialUpgradeBonusPerLevel = 0.06; // +6 % ke statům za úroveň (jen SET)

  Item({
    required this.name,
    required this.value,
    required this.stats,
    required this.rarity,
    this.isConsumable = false,
    this.isActive = false,
    this.stackCount = 1,
    this.slot,
    this.setId,
    this.upgradeLevel = 0,
    this.materialUpgradeLevel = 0,
    this.isLocked = false,
    this.isArtifact = false,
    int gemSlotCount = 0,
    this.hardcoreSetId,
    this.predpekliSetId,
    this.pekloSetId,
    this.specRelicKey,
    this.artifactWeaponForgeLevel = 0,
  })  : gemSlots = List<String?>.filled(gemSlotCount, null),
        id = DateTime.now().microsecondsSinceEpoch.toString() + Random().nextInt(1000).toString();

  // Konstruktor pro obnovení ze save souboru - zachová původní id.
  Item._raw({
    required this.id,
    required this.name,
    required this.value,
    required this.stats,
    required this.rarity,
    required this.isConsumable,
    required this.isActive,
    required this.stackCount,
    this.slot,
    this.setId,
    this.upgradeLevel = 0,
    this.materialUpgradeLevel = 0,
    this.isLocked = false,
    this.isArtifact = false,
    List<String?>? gemSlots,
    this.hardcoreSetId,
    this.predpekliSetId,
    this.pekloSetId,
    this.specRelicKey,
    this.artifactWeaponForgeLevel = 0,
  }) : gemSlots = gemSlots ?? [];

  // Kolik gem slotů má tento předmět celkem (obsazených i prázdných).
  int get gemSlotCount => gemSlots.length;
  // Vloží gem do prvního prázdného slotu. Vrací true při úspěchu.
  bool insertGem(String gemName) {
    final freeIdx = gemSlots.indexWhere((g) => g == null);
    if (freeIdx == -1) return false;
    gemSlots[freeIdx] = gemName;
    return true;
  }

  // Násobitel statů podle úrovně vylepšení. Vylepšovat lze pouze legendary/SET vybavení.
  double get upgradeMultiplier => 1 + (upgradeLevel * upgradeBonusPerLevel);
  bool get isUpgradable => rarity == Rarity.legendary;

  // Runový kovář: vylepšení artefaktové zbraně (obětováním silnější zbraně z batohu). Bez
  // stropu - +5 % ke statům za každou úroveň, do nekonečna. Platí jen na artefaktovou zbraň
  // (isArtifact && slot==weapon) - viz GameState.forgeArtifactWeapon().
  static const double artifactForgeBonusPerLevel = 0.05;
  double get artifactForgeMultiplier => 1 + (artifactWeaponForgeLevel * artifactForgeBonusPerLevel);

  // Druhý, nezávislý násobitel statů za suroviny (ocel/kůže/dřevo) - jen na SET vybavení
  // (setId != null). Kombinuje se multiplikativně s upgradeMultiplier (Esence), takže naplno
  // vylepšený SET item (+80 % Esence × +60 % materiál) reálně předčí i legendary kus od kováře,
  // který žádný z těchto dvou systémů nemá.
  double get materialUpgradeMultiplier => 1 + (materialUpgradeLevel * materialUpgradeBonusPerLevel);
  bool get isMaterialUpgradable => setId != null;

  // Zobrazovaná hodnota statu na kartě předmětu - MUSÍ zahrnovat oba multiplikátory (Esence
  // i materiál), jinak vylepšení v UI vypadá, že se vůbec neprojevilo, i když se do celkových
  // statů postavy správně počítá (viz totalStrength/totalAgility/.../maxHp v GameState).
  int displayStatValue(String statName) => ((stats[statName] ?? 0) * upgradeMultiplier * materialUpgradeMultiplier).round();
  String get statsDisplayText => stats.keys.map((k) => "$k +${displayStatValue(k)}").join(', ');

  // Ikona podle typu předmětu - lektvary podle konkrétního jména, vybavení podle slotu.
  FantasyIconType get iconType {
    if (isConsumable) {
      switch (name) {
        case "Léčivý lektvar":
          return FantasyIconType.potionHealing;
        case "Upíří Lektvar":
          return FantasyIconType.potionVampiric;
        case "Lektvar Síly":
          return FantasyIconType.potionStrength;
        case "Lektvar Kamenné kůže":
          return FantasyIconType.potionStoneskin;
        case "Lektvar Moudrosti":
          return FantasyIconType.potionWisdom;
        case "Elixír Fénixe":
          return FantasyIconType.potionHealing;
        default:
          return FantasyIconType.potionHealing;
      }
    }
    if (setId != null) return FantasyIconType.markSetItem;
    switch (slot) {
      case EquipSlot.weapon:
        return FantasyIconType.slotWeapon;
      case EquipSlot.armor:
        return FantasyIconType.slotArmor;
      case EquipSlot.accessory:
        return FantasyIconType.slotAmulet;
      case EquipSlot.gloves:
        return FantasyIconType.slotGloves;
      case EquipSlot.boots:
        return FantasyIconType.slotBoots;
      case EquipSlot.ring:
        return FantasyIconType.slotRing;
      case EquipSlot.helmet:
        return FantasyIconType.slotHelmet;
      case EquipSlot.belt:
        return FantasyIconType.slotBelt;
      case EquipSlot.cloak:
        return FantasyIconType.slotCloak;
      case EquipSlot.shoulders:
        return FantasyIconType.slotShoulder;
      case EquipSlot.relic:
        return FantasyIconType.slotRelic;
      case null:
        return FantasyIconType.chest;
    }
  }

  FantasyRarity get rarityVisual {
    if (isArtifact) return FantasyRarity.artifact;
    if (setId != null) return FantasyRarity.setItem;
    switch (rarity) {
      case Rarity.common:
        return FantasyRarity.common;
      case Rarity.rare:
        return FantasyRarity.rare;
      case Rarity.epic:
        return FantasyRarity.epic;
      case Rarity.legendary:
        return FantasyRarity.legendary;
      case Rarity.artifact:
        return FantasyRarity.artifact;
    }
  }

  Color get rarityColor {
    if (isArtifact) return const Color(0xFFFF1744); // Artefakt - krvavě prizmatická
    if (pekloSetId != null) return const Color(0xFFFF3D00); // Peklo SET - ohnivě rudá (nejvyšší tier)
    if (predpekliSetId != null) return const Color(0xFFB026FF); // Předpeklí SET - pekelná fialová
    if (hardcoreSetId != null) return const Color(0xFF00F0FF); // Hardcore SET - neonově modrá
    if (setId != null) return const Color(0xFF00E676); // Set předmět - zelená
    switch (rarity) {
      case Rarity.common:
        return Colors.white70;
      case Rarity.rare:
        return const Color(0xFF0070DD); // vzácný stupeň - modrá
      case Rarity.epic:
        return const Color(0xFFA335EE); // epický stupeň - fialová
      case Rarity.legendary:
        return const Color(0xFFFF8000); // legendární stupeň - oranžová
      case Rarity.artifact:
        return const Color(0xFFFF1744); // Artefakt Osudu
    }
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "value": value,
        "stats": stats,
        "rarity": rarity.name,
        "isConsumable": isConsumable,
        "isActive": isActive,
        "stackCount": stackCount,
        "slot": slot?.name,
        "setId": setId,
        "upgradeLevel": upgradeLevel,
        "materialUpgradeLevel": materialUpgradeLevel,
        "isLocked": isLocked,
        "isArtifact": isArtifact,
        "gemSlots": gemSlots,
        "hardcoreSetId": hardcoreSetId,
        "predpekliSetId": predpekliSetId,
        "pekloSetId": pekloSetId,
        "specRelicKey": specRelicKey,
        "artifactWeaponForgeLevel": artifactWeaponForgeLevel,
      };

  factory Item.fromJson(Map<String, dynamic> json) {
    final specRelicKey = json["specRelicKey"] as String?;
    // Migrace starších save souborů: Relic itemy dřív padaly jako Legendary/zničitelné - teď
    // jsou Artefakt/nezničitelné (viz tryDropCurrentSpecRelic()), vynutí se i na už uložených kusech.
    final isRelic = specRelicKey != null;
    return Item._raw(
        id: json["id"] as String,
        name: json["name"] as String,
        value: json["value"] as int,
        stats: Map<String, int>.from(json["stats"] as Map),
        rarity: isRelic ? Rarity.artifact : Rarity.values.firstWhere((r) => r.name == json["rarity"], orElse: () => Rarity.common),
        isConsumable: json["isConsumable"] as bool,
        isActive: json["isActive"] as bool,
        stackCount: json["stackCount"] as int,
        slot: json["slot"] != null ? EquipSlot.values.firstWhere((s) => s.name == json["slot"], orElse: () => EquipSlot.weapon) : null,
        setId: json["setId"] as String?,
        upgradeLevel: json["upgradeLevel"] as int? ?? 0,
        materialUpgradeLevel: json["materialUpgradeLevel"] as int? ?? 0,
        isLocked: json["isLocked"] as bool? ?? false,
        isArtifact: isRelic ? true : (json["isArtifact"] as bool? ?? false),
        gemSlots: json["gemSlots"] != null ? List<String?>.from(json["gemSlots"] as List) : [],
        hardcoreSetId: json["hardcoreSetId"] as String?,
        predpekliSetId: json["predpekliSetId"] as String?,
        pekloSetId: json["pekloSetId"] as String?,
        specRelicKey: specRelicKey,
        artifactWeaponForgeLevel: json["artifactWeaponForgeLevel"] as int? ?? 0,
      );
  }
}


// =============================================================================
// AGREED SYSTEMS 2026-08-24: ARMOR, EXTRA ATTACK, CLASS FRAME, ARENA RELIC
// =============================================================================
// =============================================================================
// COMPLETE SPECIALIZATION RELICS: 21 UNIQUE CLASS/SPEC ARTIFACTS
// =============================================================================
enum DamageKind { physical, magical, trueDamage }
enum RelicMechanic { blood, chi, command, dawn, echo, fire, frost, guard, harmony, iceWard, judgement, liturgy, mark, momentum, nemesis, pet, plague, rage, riposte, shadow, stone }
enum SpecRelicKind { warriorBerserkBanner, warriorGuardianBanner, warriorWarlordBanner, hunterMarksmanQuiver, hunterBeastQuiver, hunterGhostQuiver, healerDawnSymbol, healerJudgementSymbol, healerBattleSymbol, deathKnightFrostSigil, deathKnightBloodSigil, deathKnightPlagueSigil, mageFireTome, mageFrostTome, mageArcaneTome, duelistNemesisCrest, duelistDanceCrest, duelistLightningCrest, monkStormMala, monkStoneMala, monkHarmonyMala, druidBalanceTotem, druidWildTotem, druidRestoTotem, paladinGuardianSeal, paladinJudgementSeal, paladinDawnSeal, demonHunterHavocGlaive, demonHunterVengeanceGlaive, demonHunterShadowGlaive, necromancerBoneTome, necromancerPlagueTome, necromancerBloodTome }
class RelicEffectDef { final int level; final String name; final String description; const RelicEffectDef(this.level,this.name,this.description); }
class SpecRelicDef { final SpecRelicKind kind; final HeroClass heroClass; final int specialization; final String name; final String form; final String spell; final IconData icon; final Color color; final RelicMechanic mechanic; final List<RelicEffectDef> effects; const SpecRelicDef({required this.kind,required this.heroClass,required this.specialization,required this.name,required this.form,required this.spell,required this.icon,required this.color,required this.mechanic,required this.effects}); }
const Map<SpecRelicKind, SpecRelicDef> kSpecRelics = {
SpecRelicKind.warriorBerserkBanner: SpecRelicDef(kind:SpecRelicKind.warriorBerserkBanner,heroClass:HeroClass.warrior,specialization:1,name:'Standarta nespoutané zuřivosti',form:'Bojová standarta',spell:'Krvavé běsnění',icon:Icons.local_fire_department,color:Color(0xFFE64A19),mechanic:RelicMechanic.rage,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Fyzický úder udělí stack Nespoutané zuřivosti.'), RelicEffectDef(10,'Rudý příliv','Spell generuje dodatečný Rage.'), RelicEffectDef(20,'Kritické běsnění','Critical hit přidá dva stacky.'), RelicEffectDef(30,'Zrychlený masakr','Stacky zvyšují Extra Attack Chance.'), RelicEffectDef(40,'Neutuchající zuřivost','Extra Attack jednou za kolo prodlouží buff.'), RelicEffectDef(50,'Rampage','Pět stacků spustí okamžitý dodatečný útok.'), RelicEffectDef(60,'Lovec titánů','Rampage způsobuje vyšší damage bossům.'), RelicEffectDef(70,'Na hraně smrti','Pod 40 % HP se zesílí ofenzivní bonus bez dalšího postihu.'), RelicEffectDef(80,'Dědictví hněvu','Ve Věži se část Rage přenese do dalšího boje.'), RelicEffectDef(90,'Avatar zuřivosti','Při maximu stacků dostane základní útok garantovaný nerekurzivní Extra Attack.')]),
SpecRelicKind.warriorGuardianBanner: SpecRelicDef(kind:SpecRelicKind.warriorGuardianBanner,heroClass:HeroClass.warrior,specialization:2,name:'Standarta nezdolné hradby',form:'Bojová standarta',spell:'Výzva železné zdi',icon:Icons.shield,color:Color(0xFF78909C),mechanic:RelicMechanic.guard,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Vytvoří absorb podle Armor a označí nepřítele.'), RelicEffectDef(10,'Živá hradba','Štít se škáluje také z Vitality.'), RelicEffectDef(20,'Zpevněný postoj','Aktivní štít zvyšuje Block Chance.'), RelicEffectDef(30,'Ocelová odveta','Block poškodí útočníka.'), RelicEffectDef(40,'Prasklina v pancíři','Protiútok sníží Armor nepřítele.'), RelicEffectDef(50,'Výbuch bašty','Rozbitý štít exploduje podle absorbovaného damage.'), RelicEffectDef(60,'Mistrovský blok','Přebytečný Block zesiluje protiútok.'), RelicEffectDef(70,'Umlčená hrozba','Označený nepřítel způsobuje nižší damage.'), RelicEffectDef(80,'Pochod pevnosti','Ve Věži se část štítu přenese do dalšího boje.'), RelicEffectDef(90,'Nedobytná pevnost','První smrtelný zásah v boji ponechá 1 HP a vytvoří nouzový štít.')]),
SpecRelicKind.warriorWarlordBanner: SpecRelicDef(kind:SpecRelicKind.warriorWarlordBanner,heroClass:HeroClass.warrior,specialization:3,name:'Standarta dobyvatele',form:'Bojová standarta',spell:'Rozkaz k útoku',icon:Icons.flag,color:Color(0xFFFFA000),mechanic:RelicMechanic.command,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Následující schopnost získá bonus podle svého typu.'), RelicEffectDef(10,'Povzbudivý rozkaz','Spell generuje část Rage.'), RelicEffectDef(20,'Průrazný rozkaz','První spell ignoruje část Armor.'), RelicEffectDef(30,'Taktická úspora','Critical spell vrátí část resource.'), RelicEffectDef(40,'Dvojitý povel','Rozkaz ovlivní dva následující útoky.'), RelicEffectDef(50,'Taktická převaha','Dva různé spelly aktivují bonus damage.'), RelicEffectDef(60,'Velitel bossů','Převaha zvyšuje boss damage.'), RelicEffectDef(70,'Řetěz velení','Extra Attack nespotřebuje účinek Rozkazu.'), RelicEffectDef(80,'Vítězný pokřik','Zabití cíle zkrátí cooldown Relicu.'), RelicEffectDef(90,'Válečný vládce','Střídání rozdílných schopností zesiluje další útok až do bezpečného capu.')]),
SpecRelicKind.hunterMarksmanQuiver: SpecRelicDef(kind:SpecRelicKind.hunterMarksmanQuiver,heroClass:HeroClass.hunter,specialization:1,name:'Toulec neomylné vendety',form:'Toulec',spell:'Smrtící zaměření',icon:Icons.gps_fixed,color:Color(0xFF9CCC65),mechanic:RelicMechanic.mark,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Aplikuje Záměrný bod a buduje stacky Přesnosti.'), RelicEffectDef(10,'Pevný cíl','Označený nepřítel má snížený Dodge.'), RelicEffectDef(20,'Kritická přesnost','Crit přidá dva stacky.'), RelicEffectDef(30,'Průrazná Vendeta','Vendeta Shot ignoruje část Armor.'), RelicEffectDef(40,'Rychlá korekce','Extra Attack může přidat stack.'), RelicEffectDef(50,'Popravčí střela','Vendeta má execute bonus pod 30 % HP.'), RelicEffectDef(60,'Dokonalá optika','Přebytečná Crit Chance se mění na Crit Damage.'), RelicEffectDef(70,'Úsporný zásah','Crit Vendety vrátí část resource.'), RelicEffectDef(80,'Další terč','Ve Věži označení po zabití přejde na další cíl.'), RelicEffectDef(90,'Dokonalá poprava','První Vendeta pod 20 % HP má garantovaný kritický zásah.')]),
SpecRelicKind.hunterBeastQuiver: SpecRelicDef(kind:SpecRelicKind.hunterBeastQuiver,heroClass:HeroClass.hunter,specialization:2,name:'Toulec tesáků alfy',form:'Toulec',spell:'Povel alfy',icon:Icons.pets,color:Color(0xFF66BB6A),mechanic:RelicMechanic.pet,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Hunter a companion provedou společný útok.'), RelicEffectDef(10,'Kořist smečky','Alpha Strike aplikuje Mark.'), RelicEffectDef(20,'Sdílená krev','Útok proti Marku léčí companiona a hráče.'), RelicEffectDef(30,'Lovecký doskok','Extra Attack vyvolá slabší pet follow-up.'), RelicEffectDef(40,'Zastrašení','Pet útok sníží damage nepřítele.'), RelicEffectDef(50,'Lovecká horečka','Každý třetí společný útok aktivuje buff.'), RelicEffectDef(60,'Rychlost smečky','Horečka zvyšuje Extra Attack Chance.'), RelicEffectDef(70,'Trhající tesák','Pet crit prodlouží Mark.'), RelicEffectDef(80,'Hostina vítězů','Zabití cíle obnoví HP companiona.'), RelicEffectDef(90,'Pravý alfa','Hunter a pet sdílejí část critu, lifestealu a boss damage.')]),
SpecRelicKind.hunterGhostQuiver: SpecRelicDef(kind:SpecRelicKind.hunterGhostQuiver,heroClass:HeroClass.hunter,specialization:3,name:'Toulec přízračných šípů',form:'Toulec',spell:'Přízračná rána',icon:Icons.visibility_off,color:Color(0xFF26A69A),mechanic:RelicMechanic.shadow,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Udělí Ve stínu; Dodge vyvolá přízračnou odvetu.'), RelicEffectDef(10,'Toxický stín','Odveta aplikuje poison.'), RelicEffectDef(20,'Kluzká kořist','Poison zvyšuje Dodge proti nakaženému cíli.'), RelicEffectDef(30,'Vytrvalý jed','Dodge prodlouží poison.'), RelicEffectDef(40,'Smrtící odraz','Odveta má vyšší Crit Chance.'), RelicEffectDef(50,'Stínový skok','Tři odvety spustí silný skok.'), RelicEffectDef(60,'Přízračné sání','Stínový skok léčí podle damage.'), RelicEffectDef(70,'Oslabená kořist','Nakažený cíl způsobuje nižší damage.'), RelicEffectDef(80,'Putující jed','Ve Věži poison po zabití přejde dále.'), RelicEffectDef(90,'Živý přízrak','První Dodge v kole vyvolá zesílenou odvetu.')]),
SpecRelicKind.healerDawnSymbol: SpecRelicDef(kind:SpecRelicKind.healerDawnSymbol,heroClass:HeroClass.healer,specialization:1,name:'Symbol prvního úsvitu',form:'Symbol Light',spell:'Paprsek obnovy',icon:Icons.wb_sunny,color:Color(0xFFFFD54F),mechanic:RelicMechanic.dawn,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Silný heal; overheal se ukládá jako Světlo úsvitu.'), RelicEffectDef(10,'Ochranný přebytek','Overheal vytvoří absorb štít.'), RelicEffectDef(20,'Zářivá péče','Aktivní štít zvyšuje healing power.'), RelicEffectDef(30,'Svatý přenos','Útočný spell spotřebuje světlo na Holy Damage.'), RelicEffectDef(40,'Kritický úsvit','Critical heal uloží více světla.'), RelicEffectDef(50,'Nouzová záře','Pod 30 % HP se světlo automaticky spotřebuje.'), RelicEffectDef(60,'Očista','Heal odstraní negativní efekt s cooldownem.'), RelicEffectDef(70,'Magická záštita','Štít zvyšuje magickou redukci.'), RelicEffectDef(80,'Přenesené světlo','Ve Věži se část světla přenese dál.'), RelicEffectDef(90,'Věčný úsvit','Overheal se průběžně mění mezi štítem a Holy Damage.')]),
SpecRelicKind.healerJudgementSymbol: SpecRelicDef(kind:SpecRelicKind.healerJudgementSymbol,heroClass:HeroClass.healer,specialization:2,name:'Symbol nezvratného soudu',form:'Symbol Light',spell:'Rozsudek světla',icon:Icons.gavel,color:Color(0xFFFFB300),mechanic:RelicMechanic.judgement,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Poškodí cíl a aplikuje Rozsudek; útoky proti němu léčí.'), RelicEffectDef(10,'Odhalená vina','Rozsudek sníží Armor.'), RelicEffectDef(20,'Kritické vykoupení','Crit proti cíli poskytne větší heal.'), RelicEffectDef(30,'Zázračný rozsudek','Heal z Rozsudku může critnout.'), RelicEffectDef(40,'Pokora','Odsouzený cíl způsobuje nižší damage.'), RelicEffectDef(50,'Vykoupení','Po sérii zásahů nastane burst heal a Holy Damage.'), RelicEffectDef(60,'Aegis vykoupení','Overheal vytvoří štít.'), RelicEffectDef(70,'Soud titánů','Boss dostává vyšší Holy Damage.'), RelicEffectDef(80,'Putující rozsudek','Ve Věži přejde Rozsudek na další cíl.'), RelicEffectDef(90,'Poslední soud','Vykoupení zesílí následující heal i útočný spell.')]),
SpecRelicKind.healerBattleSymbol: SpecRelicDef(kind:SpecRelicKind.healerBattleSymbol,heroClass:HeroClass.healer,specialization:3,name:'Symbol válečné liturgie',form:'Symbol Light',spell:'Posvěcený úder',icon:Icons.flash_on,color:Color(0xFFFF8F00),mechanic:RelicMechanic.liturgy,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Úder přidá stack Liturgie a zahájí střídání útoku a healu.'), RelicEffectDef(10,'Útok k modlitbě','Útočný spell zesílí další heal.'), RelicEffectDef(20,'Modlitba k útoku','Heal zesílí další útočný spell.'), RelicEffectDef(30,'Plynulá liturgie','Správné střídání generuje resource.'), RelicEffectDef(40,'Ochranný verš','Třetí správný krok vytvoří štít.'), RelicEffectDef(50,'Svatá extáze','Pět správných kroků aktivuje silný buff.'), RelicEffectDef(60,'Bojová extáze','Buff zvyšuje Extra Attack i healing.'), RelicEffectDef(70,'Kritický verš','Crit přidá bonusový stack a nepřeruší řetězec.'), RelicEffectDef(80,'Udržená modlitba','Chyba nesmaže všechny stacky.'), RelicEffectDef(90,'Válečný apoštol','Maximální Liturgie spustí útočný i léčivý účinek současně.')]),
SpecRelicKind.deathKnightFrostSigil: SpecRelicDef(kind:SpecRelicKind.deathKnightFrostSigil,heroClass:HeroClass.deathknight,specialization:2,name:'Sigil věčné zimy',form:'Frost Sigil',spell:'Mrazivá duše',icon:Icons.ac_unit,color:Color(0xFF70D7FF),mechanic:RelicMechanic.frost,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Frost hit aplikuje stack Frozen Soul.'), RelicEffectDef(10,'Ledová ostrost','Vyšší damage spellu a stacku.'), RelicEffectDef(20,'Křehkost','Frost spelly mají vyšší Crit Chance proti Frozen Soul.'), RelicEffectDef(30,'Praskající zbroj','Frozen Soul snižuje Armor cíle.'), RelicEffectDef(40,'Hluboký mráz','Frozen Soul může mít dva stacky.'), RelicEffectDef(50,'Shatter','Maximum stacků exploduje v burst damage.'), RelicEffectDef(60,'Kritické tříštění','Shatter může critnout.'), RelicEffectDef(70,'Freeze','Shatter může připravit běžného nepřítele o akci; boss dostane jen bonus damage.'), RelicEffectDef(80,'Putující zima','Ve Věži přejde stack po zabití na další cíl.'), RelicEffectDef(90,'Avatar zimy','Po Shatter získá DK Frost Damage, Crit a Extra Attack Chance.')]),
SpecRelicKind.deathKnightBloodSigil: SpecRelicDef(kind:SpecRelicKind.deathKnightBloodSigil,heroClass:HeroClass.deathknight,specialization:1,name:'Sigil krvavého trůnu',form:'Blood Sigil',spell:'Krvavý parazit',icon:Icons.bloodtype,color:Color(0xFFC62828),mechanic:RelicMechanic.blood,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Aplikuje Blood Parasite, který způsobuje damage.'), RelicEffectDef(10,'Sání života','Část damage léčí hráče.'), RelicEffectDef(20,'Mocná transfúze','Zvyšuje heal z parazita.'), RelicEffectDef(30,'Oslabená krev','Parazit snižuje damage nepřítele.'), RelicEffectDef(40,'Blood Shield','Část healu se mění na absorb.'), RelicEffectDef(50,'Pevnost krve','Blood Shield se škáluje z Vitality.'), RelicEffectDef(60,'Kritické sání','Heal může kritnout.'), RelicEffectDef(70,'Hostina','Zabití nakaženého cíle obnoví HP.'), RelicEffectDef(80,'Krvavá zbroj','Stacky parazita zvyšují Armor.'), RelicEffectDef(90,'Crimson Emperor','Pod 35 % HP se jednou za boj vytvoří velký Blood Shield.')]),
SpecRelicKind.deathKnightPlagueSigil: SpecRelicDef(kind:SpecRelicKind.deathKnightPlagueSigil,heroClass:HeroClass.deathknight,specialization:3,name:'Sigil nekonečné nákazy',form:'Plague Sigil',spell:'Nekrotická hniloba',icon:Icons.coronavirus,color:Color(0xFF8BC34A),mechanic:RelicMechanic.plague,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Způsobí damage a aplikuje novou DoT.'), RelicEffectDef(10,'Rostoucí rozklad','Zvyšuje damage DoT.'), RelicEffectDef(20,'Parazitická nákaza','DoT léčí hráče.'), RelicEffectDef(30,'Rozklad zbroje','DoT snižuje Armor cíle.'), RelicEffectDef(40,'Nakažená kořist','Hráč způsobuje vyšší damage cíli pod DoT.'), RelicEffectDef(50,'Zhoubný krit','DoT získá vyšší Crit Chance.'), RelicEffectDef(60,'Vytrvalá nákaza','Tick má šanci prodloužit DoT o kolo.'), RelicEffectDef(70,'Množení','DoT může mít až tři stacky.'), RelicEffectDef(80,'Přenos epidemie','Ve Věži DoT po zabití přeskočí na další cíl.'), RelicEffectDef(90,'Necrotic Apocalypse','Při vypršení exploduje za každý stack.')]),
SpecRelicKind.mageFireTome: SpecRelicDef(kind:SpecRelicKind.mageFireTome,heroClass:HeroClass.mage,specialization:1,name:'Grimoár hladového plamene',form:'Kniha kouzel',spell:'Živý plamen',icon:Icons.local_fire_department,color:Color(0xFFFF5722),mechanic:RelicMechanic.fire,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Aplikuje Burning; další Fire spelly zvyšují Žár.'), RelicEffectDef(10,'Hladový oheň','Zvyšuje Burning damage.'), RelicEffectDef(20,'Kritický žár','Fire crit přidá stack Žáru.'), RelicEffectDef(30,'Roztavený pancíř','Burning snižuje Armor.'), RelicEffectDef(40,'Stoupající teplota','Žár zvyšuje damage Fire spellů.'), RelicEffectDef(50,'Flashover','Maximum Žáru spustí okamžitý tick všech Burning efektů.'), RelicEffectDef(60,'Kritické hoření','Burning může critnout.'), RelicEffectDef(70,'Nevyhasínající plamen','Burning se může prodloužit.'), RelicEffectDef(80,'Šíření požáru','Ve Věži se Burning po zabití přenese.'), RelicEffectDef(90,'Inferno','Burning při vypršení exploduje a část stacků obnoví.')]),
SpecRelicKind.mageFrostTome: SpecRelicDef(kind:SpecRelicKind.mageFrostTome,heroClass:HeroClass.mage,specialization:2,name:'Kodex zamrzlého času',form:'Kniha kouzel',spell:'Ledové vězení',icon:Icons.severe_cold,color:Color(0xFF4FC3F7),mechanic:RelicMechanic.iceWard,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Aplikuje Chlad a vytvoří Ice Ward.'), RelicEffectDef(10,'Ledová slabost','Chlad snižuje damage nepřítele.'), RelicEffectDef(20,'Mocný ward','Ward se škáluje z Wisdom a Vitality.'), RelicEffectDef(30,'Křehký cíl','Útok proti Chladu má vyšší Crit Chance.'), RelicEffectDef(40,'Zamrznutí','Crit přidá stack Zamrznutí.'), RelicEffectDef(50,'Shatter','Tři stacky spustí tříštivý burst.'), RelicEffectDef(60,'Obnovený led','Shatter obnoví část Ward.'), RelicEffectDef(70,'Permafrost','Chlad lze prodloužit.'), RelicEffectDef(80,'Putující mráz','Ve Věži se jeden stack přenese.'), RelicEffectDef(90,'Absolutní nula','První Shatter oslabí akci cíle; boss utrpí pouze bonus damage.')]),
SpecRelicKind.mageArcaneTome: SpecRelicDef(kind:SpecRelicKind.mageArcaneTome,heroClass:HeroClass.mage,specialization:3,name:'Kronika roztříštěné hodiny',form:'Kniha kouzel',spell:'Arkánová ozvěna',icon:Icons.hourglass_bottom,color:Color(0xFFAB47BC),mechanic:RelicMechanic.echo,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Uloží a zopakuje slabší kopii posledního spellu.'), RelicEffectDef(10,'Úsporná ozvěna','Ozvěna stojí méně resource.'), RelicEffectDef(20,'Kritická ozvěna','Kopie může samostatně critnout.'), RelicEffectDef(30,'Zrychlený čas','Ozvěna zkrátí cooldown.'), RelicEffectDef(40,'Prodloužený okamžik','Kopie buffu prodlouží jeho trvání.'), RelicEffectDef(50,'Časový zlom','Každá třetí Ozvěna aktivuje bonus.'), RelicEffectDef(60,'Navrácená mana','Časový zlom vrátí resource.'), RelicEffectDef(70,'Průrazný paradox','Útočná Ozvěna ignoruje část Armor.'), RelicEffectDef(80,'Uložený okamžik','Ve Věži zůstane jeden stack zlomu.'), RelicEffectDef(90,'Paradox','Zopakuje dva poslední rozdílné spelly a nemůže opakovat sám sebe.')]),
SpecRelicKind.duelistNemesisCrest: SpecRelicDef(kind:SpecRelicKind.duelistNemesisCrest,heroClass:HeroClass.duelist,specialization:1,name:'Erb neúprosné Nemesis',form:'Duelist Crest',spell:'Označení pomsty',icon:Icons.gps_fixed,color:Color(0xFFE0E0E0),mechanic:RelicMechanic.nemesis,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Označí cíl a buduje stacky Odplaty.'), RelicEffectDef(10,'Rostoucí pomsta','Každý zásah přidá stack.'), RelicEffectDef(20,'Odhalená obrana','Označení snižuje Armor.'), RelicEffectDef(30,'Kritická odplata','Crit přidá dva stacky.'), RelicEffectDef(40,'Blížící se konec','Damage roste s chybějícím HP cíle.'), RelicEffectDef(50,'Rozsudek Nemesis','Maximum stacků odemkne silný útok.'), RelicEffectDef(60,'Poprava','Rozsudek má execute bonus.'), RelicEffectDef(70,'Vrácená síla','Zabití Rozsudkem vrátí resource.'), RelicEffectDef(80,'Další viník','Ve Věži značka přejde dále.'), RelicEffectDef(90,'Neodvratná pomsta','První Rozsudek pod 20 % HP má garantovaný crit.')]),
SpecRelicKind.duelistDanceCrest: SpecRelicDef(kind:SpecRelicKind.duelistDanceCrest,heroClass:HeroClass.duelist,specialization:2,name:'Erb stříbrného tance',form:'Duelist Crest',spell:'Krok mezi čepelemi',icon:Icons.switch_access_shortcut,color:Color(0xFF90CAF9),mechanic:RelicMechanic.riposte,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Zvýší Dodge; vyhnutí aktivuje Riposte.'), RelicEffectDef(10,'Lehký krok','Zvyšuje Dodge během postoje.'), RelicEffectDef(20,'Dokonalá odpověď','Dodge vyvolá Riposte.'), RelicEffectDef(30,'Léčivá elegance','Riposte léčí část způsobeného damage.'), RelicEffectDef(40,'Tempo','Střídání útoku a Riposte přidává Tempo.'), RelicEffectDef(50,'Tanec ostří','Maximum Tempa spustí sérii zásahů.'), RelicEffectDef(60,'Kritický tanec','Tanec zvyšuje Crit Chance.'), RelicEffectDef(70,'Rychlý krok','Extra Attack přidá Tempo bez rekurze.'), RelicEffectDef(80,'Neúnavná elegance','Zabití během Tance obnoví jeho část.'), RelicEffectDef(90,'Dokonalý duel','První Dodge v kole vyvolá zesílenou Riposte.')]),
SpecRelicKind.duelistLightningCrest: SpecRelicDef(kind:SpecRelicKind.duelistLightningCrest,heroClass:HeroClass.duelist,specialization:3,name:'Erb rozťatého blesku',form:'Duelist Crest',spell:'Blesková sekvence',icon:Icons.bolt,color:Color(0xFFFFEE58),mechanic:RelicMechanic.momentum,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Provede dva rychlé zásahy.'), RelicEffectDef(10,'Přesný druhý řez','Druhý zásah má vyšší Crit Chance.'), RelicEffectDef(20,'Hybnost','Extra Attack přidá stack Hybnosti.'), RelicEffectDef(30,'Nabitá čepel','Hybnost zesiluje další spell.'), RelicEffectDef(40,'Zkrácený okamžik','Maximum Hybnosti zkrátí cooldown.'), RelicEffectDef(50,'Blesková smršť','Maximum spustí vícenásobný útok.'), RelicEffectDef(60,'Navrácený dech','Smršť vrátí resource.'), RelicEffectDef(70,'Kritická smršť','Každý hit může critnout samostatně.'), RelicEffectDef(80,'Nesená rychlost','Ve Věži část Hybnosti zůstane.'), RelicEffectDef(90,'Mimo čas','První basic po spellu získá garantovaný nerekurzivní Extra Attack.')]),
SpecRelicKind.monkStormMala: SpecRelicDef(kind:SpecRelicKind.monkStormMala,heroClass:HeroClass.monk,specialization:1,name:'Mála dunícího nebe',form:'Mála',spell:'Úder hromového srdce',icon:Icons.thunderstorm,color:Color(0xFFFFB74D),mechanic:RelicMechanic.chi,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Způsobí damage a generuje Chi.'), RelicEffectDef(10,'Hromové Chi','Spell generuje více Chi.'), RelicEffectDef(20,'Kritické kombo','Crit přidá další Combo stack.'), RelicEffectDef(30,'Rychlé dlaně','Extra Attack generuje menší Chi.'), RelicEffectDef(40,'Rostoucí bouře','Combo stacky zvyšují damage.'), RelicEffectDef(50,'Tisíc úderů','Maximum stacků spustí údernou sérii.'), RelicEffectDef(60,'Kritická série','Každý zásah může critnout.'), RelicEffectDef(70,'Lámající dlaň','Série snižuje Armor.'), RelicEffectDef(80,'Nesené kombo','Ve Věži se část stacků přenese.'), RelicEffectDef(90,'Bouře v jediném úderu','Série končí explozí podle počtu critů.')]),
SpecRelicKind.monkStoneMala: SpecRelicDef(kind:SpecRelicKind.monkStoneMala,heroClass:HeroClass.monk,specialization:2,name:'Mála nepohnutelné hory',form:'Mála',spell:'Postoj hory',icon:Icons.landscape,color:Color(0xFF8D6E63),mechanic:RelicMechanic.stone,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Vytvoří Kamenný štít podle Armor.'), RelicEffectDef(10,'Živá hora','Štít se škáluje z Vitality.'), RelicEffectDef(20,'Pevný postoj','Aktivní štít zvyšuje Block.'), RelicEffectDef(30,'Pevnost','Block přidá stack Pevnosti.'), RelicEffectDef(40,'Rostoucí Armor','Pevnost zvyšuje Armor.'), RelicEffectDef(50,'Úder hory','Maximum stacků odemkne damage podle Armor.'), RelicEffectDef(60,'Tvrdé jádro','Rozbití štítu nesmaže všechny stacky.'), RelicEffectDef(70,'Pochod hory','Ve Věži se část štítu přenese.'), RelicEffectDef(80,'Drtivá tíha','Úder hory sníží damage nepřítele.'), RelicEffectDef(90,'Nehybný svět','Jednou za boj smrtelný zásah spotřebuje stacky a ponechá 1 HP.')]),
SpecRelicKind.monkHarmonyMala: SpecRelicDef(kind:SpecRelicKind.monkHarmonyMala,heroClass:HeroClass.monk,specialization:3,name:'Mála tisíce nádechů',form:'Mála',spell:'Dech harmonie',icon:Icons.blur_circular,color:Color(0xFF80CBC4),mechanic:RelicMechanic.harmony,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Střídá Yin heal/absorb a Yang damage/resource.'), RelicEffectDef(10,'Hlubší Yin','Yin vytvoří silnější štít.'), RelicEffectDef(20,'Prudší Yang','Yang způsobí vyšší damage.'), RelicEffectDef(30,'Harmonie','Správné střídání přidá stack.'), RelicEffectDef(40,'Dokonalý dech','Harmonie zvyšuje heal i damage.'), RelicEffectDef(50,'Probuzení ducha','Maximum spustí silný kombinovaný buff.'), RelicEffectDef(60,'Očistný nádech','Probuzení odstraní debuff.'), RelicEffectDef(70,'Přeměna energie','Overheal zesílí další Yang.'), RelicEffectDef(80,'Nesený klid','Ve Věži zůstane stack Harmonie.'), RelicEffectDef(90,'Dokonalá rovnováha','Při maximu se Yin a Yang spustí současně.')]),
SpecRelicKind.druidBalanceTotem: SpecRelicDef(kind:SpecRelicKind.druidBalanceTotem,heroClass:HeroClass.druid,specialization:1,name:'Totem hvězdného rozkladu',form:'Přírodní Totem',spell:'Astrální rozklad',icon:Icons.blur_on,color:Color(0xFF66BB6A),mechanic:RelicMechanic.plague,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Nasadí Astrální rozklad - DoT postupného přírodního poškození.'), RelicEffectDef(10,'Hlubší kořeny','DoT způsobuje více poškození za kolo.'), RelicEffectDef(20,'Šeptající hvězdy','DoT má šanci se rozšířit na delší dobu.'), RelicEffectDef(30,'Uvadající síla','Zasažený cíl je zranitelnější vůči magii.'), RelicEffectDef(40,'Rozkladná spirála','Po 40. úrovni DoT navíc snižuje Armor cíle.'), RelicEffectDef(50,'Astrální příliv','Aktivní DoT zvyšuje tvůj magický útok.'), RelicEffectDef(60,'Zrychlený rozklad','Crit útoky zkracují dobu do dalšího tiku.'), RelicEffectDef(70,'Trvalé uvadnutí','DoT trvá o kolo déle.'), RelicEffectDef(80,'Kořeny Věže','Ve Věži část DoT přežije do dalšího boje.'), RelicEffectDef(90,'Hvězdný pád','Vyprchání DoT způsobí finální explozi podle zbývajícího poškození.')]),
SpecRelicKind.druidWildTotem: SpecRelicDef(kind:SpecRelicKind.druidWildTotem,heroClass:HeroClass.druid,specialization:2,name:'Totem prastaré kůry',form:'Přírodní Totem',spell:'Kůra prastarého stromu',icon:Icons.park,color:Color(0xFF66BB6A),mechanic:RelicMechanic.guard,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Vytvoří absorb štít podle Armor a Vitality.'), RelicEffectDef(10,'Živoucí kůra','Štít se škáluje silněji z Vitality.'), RelicEffectDef(20,'Pevný kmen','Aktivní štít zvyšuje Block Chance.'), RelicEffectDef(30,'Trnitá odveta','Block poškodí útočníka.'), RelicEffectDef(40,'Praskliny v kůře','Protiútok sníží Armor nepřítele.'), RelicEffectDef(50,'Výbuch lesa','Rozbitý štít exploduje podle absorbovaného damage.'), RelicEffectDef(60,'Mistrovský kořen','Přebytečný Block zesiluje protiútok.'), RelicEffectDef(70,'Umlčující réva','Označený nepřítel způsobuje nižší damage.'), RelicEffectDef(80,'Pochod lesa','Ve Věži se část štítu přenese do dalšího boje.'), RelicEffectDef(90,'Srdce pralesa','První smrtelný zásah v boji ponechá 1 HP a vytvoří nouzový štít.')]),
SpecRelicKind.druidRestoTotem: SpecRelicDef(kind:SpecRelicKind.druidRestoTotem,heroClass:HeroClass.druid,specialization:3,name:'Totem šeptajícího pramene',form:'Přírodní Totem',spell:'Pramen obnovy',icon:Icons.water_drop,color:Color(0xFF66BB6A),mechanic:RelicMechanic.dawn,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Vyléčí HP a vytvoří absorb štít z části healu.'), RelicEffectDef(10,'Hlubší pramen','Heal je silnější.'), RelicEffectDef(20,'Čistá voda','Štít z healu je větší.'), RelicEffectDef(30,'Proudící síla','Heal navíc zvyšuje magický útok na 2 kola.'), RelicEffectDef(40,'Věčný pramen','Heal škáluje i z chybějícího HP.'), RelicEffectDef(50,'Rozkvět','Vysoký heal odstraní jeden debuff.'), RelicEffectDef(60,'Symbióza','Štít z pramene trvá o kolo déle.'), RelicEffectDef(70,'Obnovující vlna','Overheal se přemění na dodatečný štít.'), RelicEffectDef(80,'Nesený pramen','Ve Věži zůstane část štítu do dalšího boje.'), RelicEffectDef(90,'Srdce přírody','Pod 30 % HP se spell automaticky zesílí na dvojnásobek.')]),
SpecRelicKind.paladinGuardianSeal: SpecRelicDef(kind:SpecRelicKind.paladinGuardianSeal,heroClass:HeroClass.paladin,specialization:1,name:'Pečeť posledního světla',form:'Svatá Pečeť',spell:'Val víry',icon:Icons.shield,color:Color(0xFFFFD700),mechanic:RelicMechanic.guard,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Vytvoří posvátný absorb štít podle Armor.'), RelicEffectDef(10,'Živoucí víra','Štít se škáluje také z Vitality.'), RelicEffectDef(20,'Pevný postoj','Aktivní štít zvyšuje Block Chance.'), RelicEffectDef(30,'Odplata štítu','Block poškodí útočníka svatým ohněm.'), RelicEffectDef(40,'Prasklina v temnotě','Protiútok sníží Armor nepřítele.'), RelicEffectDef(50,'Výbuch víry','Rozbitý štít exploduje podle absorbovaného damage.'), RelicEffectDef(60,'Mistrovský blok','Přebytečný Block zesiluje protiútok.'), RelicEffectDef(70,'Umlčující světlo','Označený nepřítel způsobuje nižší damage.'), RelicEffectDef(80,'Pochod víry','Ve Věži se část štítu přenese do dalšího boje.'), RelicEffectDef(90,'Nezdolná hradba','První smrtelný zásah v boji ponechá 1 HP a vytvoří nouzový štít.')]),
SpecRelicKind.paladinJudgementSeal: SpecRelicDef(kind:SpecRelicKind.paladinJudgementSeal,heroClass:HeroClass.paladin,specialization:2,name:'Pečeť svatého rozsudku',form:'Svatá Pečeť',spell:'Boží rozsudek',icon:Icons.gavel,color:Color(0xFFFFD700),mechanic:RelicMechanic.judgement,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Uvalí Rozsudek - útoky proti cíli léčí a oslabují jeho Armor.'), RelicEffectDef(10,'Ostřejší rozsudek','Rozsudek trvá o kolo déle.'), RelicEffectDef(20,'Posvěcené ostří','Útoky proti Rozsudku mají vyšší Crit Chance.'), RelicEffectDef(30,'Očistný plamen','Rozsudek navíc mírně poškozuje v čase.'), RelicEffectDef(40,'Svatá odplata','Heal z Rozsudku je silnější.'), RelicEffectDef(50,'Nezvratný verdikt','Rozsudek nelze na cíli přerušit.'), RelicEffectDef(60,'Boží hlas','Vyvolání Rozsudku sníží cooldown Schopnosti 1.'), RelicEffectDef(70,'Trestající světlo','Crit proti Rozsudku aplikuje krátké oslepení (snížený dodge cíle).'), RelicEffectDef(80,'Věčný verdikt','Ve Věži Rozsudek přežije do dalšího boje.'), RelicEffectDef(90,'Poslední soud','Zabití cíle pod Rozsudkem plně obnoví cooldown Relicu.')]),
SpecRelicKind.paladinDawnSeal: SpecRelicDef(kind:SpecRelicKind.paladinDawnSeal,heroClass:HeroClass.paladin,specialization:3,name:'Pečeť posvěceného úsvitu',form:'Svatá Pečeť',spell:'Úsvit milosti',icon:Icons.wb_sunny,color:Color(0xFFFFD700),mechanic:RelicMechanic.dawn,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Vyléčí HP a vytvoří absorb štít z části healu.'), RelicEffectDef(10,'Jasnější úsvit','Heal je silnější.'), RelicEffectDef(20,'Zlatý paprsek','Štít z healu je větší.'), RelicEffectDef(30,'Milost světla','Heal navíc zvyšuje fyzický útok na 2 kola.'), RelicEffectDef(40,'Věčné světlo','Heal škáluje i z chybějícího HP.'), RelicEffectDef(50,'Rozbřesk','Vysoký heal odstraní jeden debuff.'), RelicEffectDef(60,'Posvěcení','Štít z úsvitu trvá o kolo déle.'), RelicEffectDef(70,'Zářivá vlna','Overheal se přemění na dodatečný štít.'), RelicEffectDef(80,'Nesené světlo','Ve Věži zůstane část štítu do dalšího boje.'), RelicEffectDef(90,'Boží milost','Pod 30 % HP se spell automaticky zesílí na dvojnásobek.')]),
SpecRelicKind.demonHunterHavocGlaive: SpecRelicDef(kind:SpecRelicKind.demonHunterHavocGlaive,heroClass:HeroClass.demonhunter,specialization:1,name:'Fel Glaive Zkázy',form:'Fel Glaive',spell:'Znamení Zkázy',icon:Icons.gps_fixed,color:Color(0xFF7B2FBE),mechanic:RelicMechanic.nemesis,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Označí cíl a buduje stacky Zkázy.'), RelicEffectDef(10,'Rostoucí zkáza','Každý zásah přidá stack.'), RelicEffectDef(20,'Fel trhlina','Označení snižuje Armor.'), RelicEffectDef(30,'Kritická zkáza','Crit přidá dva stacky.'), RelicEffectDef(40,'Blížící se konec','Damage roste s chybějícím HP cíle.'), RelicEffectDef(50,'Rozsudek Zkázy','Maximum stacků odemkne silný útok.'), RelicEffectDef(60,'Poprava','Rozsudek Zkázy má execute bonus.'), RelicEffectDef(70,'Vrácená zuřivost','Zabití Rozsudkem vrátí resource.'), RelicEffectDef(80,'Šířící se zkáza','Ve Věži značka přejde na dalšího nepřítele.'), RelicEffectDef(90,'Neodvratná zkáza','První Rozsudek pod 20 % HP má garantovaný crit.')]),
SpecRelicKind.demonHunterVengeanceGlaive: SpecRelicDef(kind:SpecRelicKind.demonHunterVengeanceGlaive,heroClass:HeroClass.demonhunter,specialization:2,name:'Fel Glaive Pomsty',form:'Fel Glaive',spell:'Krvavý řez Propasti',icon:Icons.bloodtype,color:Color(0xFF7B2FBE),mechanic:RelicMechanic.blood,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Fel řez, co vyléčí část způsobeného poškození.'), RelicEffectDef(10,'Hlubší řez','Lifesteal je silnější.'), RelicEffectDef(20,'Propastná výdrž','Lifesteal roste ještě víc na vysoké úrovni.'), RelicEffectDef(30,'Fel regenerace','Část healu navíc obnoví resource.'), RelicEffectDef(40,'Krvavý pakt','Lifesteal funguje i proti více zásahům za kolo.'), RelicEffectDef(50,'Propastný štít','Vysoký heal vytvoří malý absorb štít.'), RelicEffectDef(60,'Neustálý hlad','Štít z Propastného štítu je silnější.'), RelicEffectDef(70,'Fel odolnost','Aktivní štít zvyšuje redukci poškození.'), RelicEffectDef(80,'Nesená krev','Ve Věži část lifestealu přežije do dalšího boje.'), RelicEffectDef(90,'Nesmrtelná Pomsta','Pod 30 % HP se lifesteal dočasně zdvojnásobí.')]),
SpecRelicKind.demonHunterShadowGlaive: SpecRelicDef(kind:SpecRelicKind.demonHunterShadowGlaive,heroClass:HeroClass.demonhunter,specialization:3,name:'Fel Glaive Stínu',form:'Fel Glaive',spell:'Stín propasti',icon:Icons.visibility_off,color:Color(0xFF7B2FBE),mechanic:RelicMechanic.shadow,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Nasadí Fel oheň - DoT postupného temného poškození.'), RelicEffectDef(10,'Hlubší stín','DoT způsobuje více poškození za kolo.'), RelicEffectDef(20,'Plíživá temnota','DoT má šanci se rozšířit na delší dobu.'), RelicEffectDef(30,'Fel zranitelnost','Zasažený cíl je zranitelnější vůči fyzickému poškození.'), RelicEffectDef(40,'Propastná spirála','Po 40. úrovni DoT navíc snižuje Armor cíle.'), RelicEffectDef(50,'Stínový příliv','Aktivní DoT zvyšuje tvůj fyzický útok.'), RelicEffectDef(60,'Zrychlený rozklad','Crit útoky zkracují dobu do dalšího tiku.'), RelicEffectDef(70,'Trvalý stín','DoT trvá o kolo déle.'), RelicEffectDef(80,'Kořeny Propasti','Ve Věži část DoT přežije do dalšího boje.'), RelicEffectDef(90,'Propastný pád','Vyprchání DoT způsobí finální explozi podle zbývajícího poškození.')]),
SpecRelicKind.necromancerBoneTome: SpecRelicDef(kind:SpecRelicKind.necromancerBoneTome,heroClass:HeroClass.necromancer,specialization:1,name:'Kniha kostěného trůnu',form:'Nekromantova Kniha',spell:'Rozkaz kostěnému sluhovi',icon:Icons.person_outline,color:Color(0xFF6A1B9A),mechanic:RelicMechanic.pet,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Nekromant a kostěný sluha provedou společný útok.'), RelicEffectDef(10,'Kořist hrobky','Rozkaz aplikuje Znamení smrti.'), RelicEffectDef(20,'Sdílená esence','Útok proti Znamení léčí sluhu i nekromanta.'), RelicEffectDef(30,'Rychlý povel','Extra Attack vyvolá slabší útok sluhy.'), RelicEffectDef(40,'Zastrašující kosti','Útok sluhy sníží damage nepřítele.'), RelicEffectDef(50,'Nekromantická horečka','Každý třetí společný útok aktivuje buff.'), RelicEffectDef(60,'Rychlost hrobky','Horečka zvyšuje Extra Attack Chance.'), RelicEffectDef(70,'Trhající kost','Crit sluhy prodlouží Znamení smrti.'), RelicEffectDef(80,'Hostina duší','Zabití cíle obnoví HP nekromanta.'), RelicEffectDef(90,'Vládce Kostí','Nekromant a sluha sdílejí část critu, lifestealu a boss damage.')]),
SpecRelicKind.necromancerPlagueTome: SpecRelicDef(kind:SpecRelicKind.necromancerPlagueTome,heroClass:HeroClass.necromancer,specialization:2,name:'Kniha morového rozkladu',form:'Nekromantova Kniha',spell:'Morová kletba',icon:Icons.coronavirus,color:Color(0xFF6A1B9A),mechanic:RelicMechanic.plague,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Nasadí Morovou kletbu - DoT postupného rozkladu.'), RelicEffectDef(10,'Hlubší mor','DoT způsobuje více poškození za kolo.'), RelicEffectDef(20,'Šířící se nákaza','DoT má šanci se rozšířit na delší dobu.'), RelicEffectDef(30,'Rozkladná krev','Zasažený cíl je zranitelnější vůči magii.'), RelicEffectDef(40,'Morová spirála','Po 40. úrovni DoT navíc snižuje Armor cíle.'), RelicEffectDef(50,'Kletebný příliv','Aktivní DoT zvyšuje tvůj magický útok.'), RelicEffectDef(60,'Zrychlený rozklad','Crit útoky zkracují dobu do dalšího tiku.'), RelicEffectDef(70,'Trvalá nákaza','DoT trvá o kolo déle.'), RelicEffectDef(80,'Kletba Věže','Ve Věži část DoT přežije do dalšího boje.'), RelicEffectDef(90,'Morový pád','Vyprchání DoT způsobí finální explozi podle zbývajícího poškození.')]),
SpecRelicKind.necromancerBloodTome: SpecRelicDef(kind:SpecRelicKind.necromancerBloodTome,heroClass:HeroClass.necromancer,specialization:3,name:'Kniha krvavého paktu',form:'Nekromantova Kniha',spell:'Krvavý pakt',icon:Icons.opacity,color:Color(0xFF6A1B9A),mechanic:RelicMechanic.blood,effects:<RelicEffectDef>[RelicEffectDef(1,'Nový spell','Rituální úder, co vyléčí část způsobeného poškození.'), RelicEffectDef(10,'Hlubší pakt','Lifesteal je silnější.'), RelicEffectDef(20,'Krevní vazba','Lifesteal roste ještě víc na vysoké úrovni.'), RelicEffectDef(30,'Nekrotická regenerace','Část healu navíc obnoví resource.'), RelicEffectDef(40,'Pakt s Podsvětím','Lifesteal funguje i proti více zásahům za kolo.'), RelicEffectDef(50,'Krvavý štít','Vysoký heal vytvoří malý absorb štít.'), RelicEffectDef(60,'Neustálý hlad','Štít z Krvavého štítu je silnější.'), RelicEffectDef(70,'Nekrotická odolnost','Aktivní štít zvyšuje redukci poškození.'), RelicEffectDef(80,'Nesená krev','Ve Věži část lifestealu přežije do dalšího boje.'), RelicEffectDef(90,'Nesmrtelný Rituál','Pod 30 % HP se lifesteal dočasně zdvojnásobí.')]),
};
SpecRelicDef relicFor(HeroClass c,int spec)=>kSpecRelics.values.firstWhere((r)=>r.heroClass==c&&r.specialization==spec,orElse:()=>kSpecRelics.values.firstWhere((r)=>r.heroClass==c,orElse:()=>kSpecRelics[SpecRelicKind.warriorBerserkBanner]!));

// Globální překladová funkce - lze volat kdekoli v souboru (widgety, herní logika,
// generování textu combat logu apod.), bez nutnosti mít po ruce Provider/context.
// Používej jen pro čistě zobrazovaný text - NIKDY pro řetězce, které slouží zároveň
// jako interní identifikátor (např. porovnávání jmen efektů přes .name ==), protože
// by se za běhu mohly rozjet podle aktuálního jazyka.
String tr(String cs, String en) => GameState._currentLang == "en" ? en : cs;

// Interní datové klíče statů ("Strength"/"Agility"/"Wisdom"/"Vitality") se používají napříč
// stovkami míst v kódu (itemy, relikvie, sety...) - přejmenovat by bylo extrémně riskantní.
// Tahle funkce je jen pro ZOBRAZENÍ, mapuje stejně jako _stats() panel (Síla/Hbitost/Moudrost/Vitalita).
String statLabel(String key) {
  switch (key) {
    case "Strength": return tr("Síla", "Strength");
    case "Agility": return tr("Hbitost", "Agility");
    case "Wisdom": return tr("Moudrost", "Wisdom");
    case "Vitality": return tr("Vitalita", "Vitality");
    case "Attack Speed": return tr("Rychlost útoku", "Attack Speed");
    default: return key;
  }
}

String lootPriorityModeName(LootPriorityMode m) {
  switch (m) {
    case LootPriorityMode.balanced: return tr("Vyvážené", "Balanced");
    case LootPriorityMode.offensive: return tr("Ofenzivní", "Offensive");
    case LootPriorityMode.defensive: return tr("Přežití", "Survival");
  }
}

String lootPriorityModeDescription(LootPriorityMode m) {
  switch (m) {
    case LootPriorityMode.balanced:
      return tr("Standardní hodnocení podle tvé aktuální specializace - hlavní stat plnou váhou, vedlejší stat úměrně, Tank build z Armoru/Blocku těží víc. Doporučeno pro běžný postup.",
          "Standard scoring based on your current specialization - main stat full weight, secondary stat proportionally, Tank builds get more from Armor/Block. Recommended for normal progress.");
    case LootPriorityMode.offensive:
      return tr("Upřednostní čistý damage (hlavní/vedlejší stat, Crit, Attack Speed) na úkor přežití (Armor, Vitalita, Block sníženy). Pro rychlé farmy a speedrun postup, kde risk stojí za to.",
          "Prioritizes pure damage (main/secondary stat, Crit, Attack Speed) at the cost of survival (Armor, Vitality, Block reduced). For fast farming and speedrun progress where the risk is worth it.");
    case LootPriorityMode.defensive:
      return tr("Upřednostní přežití (Armor, Vitalita, Block) na úkor damage. Pro bezpečný postup na vyšších obtížnostech (Hardcore+) nebo AFK/casual hraní bez rizika smrti.",
          "Prioritizes survival (Armor, Vitality, Block) at the cost of damage. For safe progress on higher difficulties (Hardcore+) or AFK/casual play without death risk.");
  }
}

// Globální bonus na drop krystalů - platí na VŠECHNY zdroje (Denní Cache, Lair první-clear,
// Aréna liga truhla, Rift dokončení, Rift Poklad-skřet truhla, Tower šance za kill 100+).
// Promo kódy (redeemPromoCode) záměrně NEjsou škálované - je to fixní admin-definovaná odměna
// na kód, ne součást běžné drop ekonomiky.
const double kCrystalDropBonus = 1.15;

// ===== NEPŘÁTELSKÉ SCHOPNOSTI - REÁLNÉ EFEKTY (viz proposal doc odsouhlasený s Ondřejem) =====
// Každá schopnost nepřítele/bosse teď má skutečný mechanický dopad místo čistě kosmetické
// hlášky. Trigger je deterministický: VŽDY na 2. kole boje (viz _resolveCombatRound), ne
// náhodná šance jako dřív. Čísla jsou placeholder-balance, ploché napříč patry (odsouhlaseno).
enum EnemyAbilityKind {
  statDebuff, stackingDebuff, dot, trueDamage, ignoreArmor, ignoreBlockDodge,
  guaranteedCrit, doubleAttack, stun, blockSpell, bossBuff, bossArmorBuff,
  bossShield, bossHeal, bossLifesteal, resourceDrain, goldDrain, cancelShield, cancelBuff,
}

class EnemyAbilityDef {
  final EnemyAbilityKind kind;
  final Map<String, double> mods; // pro statDebuff/stackingDebuff: 'phys'/'mag'/'armor'/'crit'/'dodge'/'block' -> záporná frakce
  final double amount; // % max HP / resource / gold / atk bonus / armor bonus podle kind
  final int duration;
  const EnemyAbilityDef(this.kind, {this.mods = const {}, this.amount = 0, this.duration = 2});
}

const Map<String, EnemyAbilityDef> enemyAbilityEffects = {
  // ===== Běžní nepřátelé (12) =====
  'Rychlé bodnutí': EnemyAbilityDef(EnemyAbilityKind.doubleAttack),
  'Drtivý úder kostí': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'block': -0.10}, duration: 2),
  'Leptavý sliz': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'armor': -0.15}, duration: 3),
  'Stínové prokletí': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'crit': -0.10}, duration: 2),
  'Kovová pěst': EnemyAbilityDef(EnemyAbilityKind.ignoreArmor, amount: 0.15),
  'Šeptající hrůza': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'dodge': -0.10}, duration: 2),
  'Ostrý odraz': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.10, duration: 2),
  'Popáleninový plivanec': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.02, duration: 3),
  'Mrazivý dotek': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'dodge': -0.10}, duration: 2),
  'Toxické kousnutí': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.02, duration: 4),
  'Neviditelný šíp': EnemyAbilityDef(EnemyAbilityKind.ignoreBlockDodge),
  'Škrábavý vír': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'phys': -0.10}, duration: 2),

  // ===== Lore mini-bossové (8) =====
  'Vzkříšení mrtvých vojáků': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.20, duration: 3),
  'Pohlcení prostoru': EnemyAbilityDef(EnemyAbilityKind.resourceDrain, amount: 0.15),
  'Runová exploze': EnemyAbilityDef(EnemyAbilityKind.ignoreArmor, amount: 0.20),
  'Mezidimenzionální trhlina': EnemyAbilityDef(EnemyAbilityKind.blockSpell, duration: 1),
  'Krvavý příliv': EnemyAbilityDef(EnemyAbilityKind.bossLifesteal, amount: 0.25),
  'Sopečná erupce': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.03, duration: 3),
  'Mentální zhroucení': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'crit': -0.15}, duration: 3),
  'Uzamčení osudu': EnemyAbilityDef(EnemyAbilityKind.blockSpell, duration: 1),

  // ===== Patrální bossové 1-100 (Doupě bosse) =====
  'Ohnivý chřtán (Plošný žár a snížení Armor)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'armor': -0.15}, duration: 2),
  'Drtivý úder (Ignoruje část zbroje)': EnemyAbilityDef(EnemyAbilityKind.ignoreArmor, amount: 0.30),
  'Stínový závoj (Vysávání životů a uhýbání)': EnemyAbilityDef(EnemyAbilityKind.bossLifesteal, amount: 0.20),
  'Krystalová kůže (Masivní absorpční štít)': EnemyAbilityDef(EnemyAbilityKind.bossShield, amount: 0.25),
  'Erupce prázdnoty (Strhává procento HP)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.06),
  'Bleskový výpad (Omezuje účinnost lektvarů)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'armor': -0.10}, duration: 2),
  'Astrální ohlušení (Blokuje magické útoky)': EnemyAbilityDef(EnemyAbilityKind.blockSpell, duration: 1),
  'Zuřivost titána (Síla roste s klesajícími HP)': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.25, duration: 3),
  'Bouřná vichřice (Snižuje šanci na kritický zásah)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'crit': -0.15}, duration: 2),
  'Božské kataklyzma (Test maximální odolnosti)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.25),
  'Oceánský tlak (Zpomaluje reakce hrdiny)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'dodge': -0.15}, duration: 2),
  'Nákaza duše (Trvalé otrávení v čase)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.03, duration: 4),
  'Absolutní mraz (Zmražení a snížení rychlosti)': EnemyAbilityDef(EnemyAbilityKind.stun, duration: 1),
  'Pekelný plamen (Popálení prorážející štíty)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.04, duration: 2),
  'Rázová vlna (Ničí bonusovou obranu)': EnemyAbilityDef(EnemyAbilityKind.cancelShield),
  'Trnitý oplet (Vrací část fyzického poškození)': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.10, duration: 2),
  'Krvavá hostina (Uzdravuje se z útoků)': EnemyAbilityDef(EnemyAbilityKind.bossLifesteal, amount: 0.25),
  'Laserový paprsek (Přesný a kritický zásah)': EnemyAbilityDef(EnemyAbilityKind.guaranteedCrit),
  'Temná halucinace (Zákeřný psychický útok)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'crit': -0.15, 'dodge': -0.15}, duration: 2),
  'Časová smyčka (Resetuje cooldowny schopností)': EnemyAbilityDef(EnemyAbilityKind.doubleAttack),
  'Kousnutí Behemota (Masivní drtivé zranění)': EnemyAbilityDef(EnemyAbilityKind.ignoreArmor, amount: 0.50),
  'Svatý hněv (Olepující paprsek světla)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'armor': -0.20}, duration: 2),
  'Zkamenění (Obranná stěna z monolitu)': EnemyAbilityDef(EnemyAbilityKind.bossArmorBuff, amount: 0.40, duration: 3),
  'Bleskový úder (Dvojitý bleskový útok)': EnemyAbilityDef(EnemyAbilityKind.doubleAttack),
  'Temný portál (Vyvolává iluze nepřátel)': EnemyAbilityDef(EnemyAbilityKind.doubleAttack),
  'Vodní vír (Pohltí část hrdinovy many/útoku)': EnemyAbilityDef(EnemyAbilityKind.resourceDrain, amount: 0.20),
  'Bleskový hrom (Omračující elektrický výboj)': EnemyAbilityDef(EnemyAbilityKind.stun, duration: 1),
  'Spontánní vznícení (Plošné hoření)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.04, duration: 3),
  'Ocelový pancíř (Extrémní Armor)': EnemyAbilityDef(EnemyAbilityKind.bossArmorBuff, amount: 0.60, duration: 3),
  'Hadesova ruka (Sahá po hrdinově životě)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.08),
  'Krvavá stopa (Rychlý skok a roztrhání)': EnemyAbilityDef(EnemyAbilityKind.doubleAttack),
  'Gravitační anomálie (Přitažení a zhmoždění)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'block': -0.20, 'dodge': -0.20}, duration: 2),
  'Regenerace hlav (Obnova ztraceného zdraví)': EnemyAbilityDef(EnemyAbilityKind.bossHeal, amount: 0.15),
  'Pád z nebes (Sebevražedný nálet)': EnemyAbilityDef(EnemyAbilityKind.ignoreArmor, amount: 0.60),
  'Ledová lavina (Zasype hrdinu mrazem)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'phys': -0.20, 'mag': -0.20}, duration: 2),
  'Tentoklové sevření (Zadržení v hlubinách)': EnemyAbilityDef(EnemyAbilityKind.blockSpell, duration: 1),
  'Mrazivá aura (Vysávání životní síly)': EnemyAbilityDef(EnemyAbilityKind.bossLifesteal, amount: 0.20),
  'Labyrintová zuřivost (Divoký nekontrolovaný náraz)': EnemyAbilityDef(EnemyAbilityKind.doubleAttack),
  'Kořenový mor (Podkopání hrdinových statistik)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'phys': -0.15, 'mag': -0.15, 'armor': -0.15, 'crit': -0.15, 'dodge': -0.15, 'block': -0.15}, duration: 2),
  'Iluzorní matení (Mění pozice v boji)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'crit': -0.20}, duration: 2),
  'Aura paniky (Snižuje úspěch útoků)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'crit': -0.20, 'block': -0.20}, duration: 2),
  'Nebeský dech (Jedovatý bleskový opar)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.04, duration: 3),
  'Konec světa (Hrozivý kataklyzmatický úder)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.30),
  'Mentální hádanka (Omezení akcí hrdiny)': EnemyAbilityDef(EnemyAbilityKind.blockSpell, duration: 1),
  'Oheň a síra (Živelná bouře)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.03, duration: 3),
  'Nekonečný kruh (Vrací čas zpět v boji)': EnemyAbilityDef(EnemyAbilityKind.cancelBuff),
  'Oštěp Valhaly (Prostřelující božský oštěp)': EnemyAbilityDef(EnemyAbilityKind.ignoreArmor, amount: 0.40),
  'Kyselý plivanec (Rozleptání zbroje)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'armor': -0.25}, duration: 3),
  'Imperiální rozkaz (Vynucené oslabení)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'phys': -0.20, 'mag': -0.20}, duration: 2),
  'Prvotní stvoření (Masivní zemětřesení)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.20),
  'Blesk z čistého nebe (Kritický úder bleskem)': EnemyAbilityDef(EnemyAbilityKind.guaranteedCrit),
  'Váha duší (Porovnání síly a zkáza)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.15),
  'Temný rituál (Oběť za obří sílu)': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.40, duration: 3),
  'Trojité kousnutí (Útok třemi hlavami naráz)': EnemyAbilityDef(EnemyAbilityKind.doubleAttack),
  'Zvrácené přání (Otočení efektů proti hrdinovi)': EnemyAbilityDef(EnemyAbilityKind.cancelBuff),
  'Zrození hnízda (Přivolání menších příšer)': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.15, duration: 3),
  'Zlatá chamtivost (Vysává zlato a krystaly)': EnemyAbilityDef(EnemyAbilityKind.goldDrain, amount: 0.05),
  'Kámen z praku (Drtivá dálková rána)': EnemyAbilityDef(EnemyAbilityKind.ignoreBlockDodge),
  'Trojitá kletba (Magická oslabení)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'mag': -0.15, 'crit': -0.15, 'dodge': -0.15}, duration: 2),
  'Kletba faraona (Vysávání magické energie)': EnemyAbilityDef(EnemyAbilityKind.resourceDrain, amount: 0.25),
  'Mořský jed (Rozšířená otrava patra)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.05, duration: 4),
  'Zpěv nymfy (Zmatení hrdinových smyslů)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'crit': -0.25, 'dodge': -0.25}, duration: 2),
  'Pohled očí (Postupné zatuhnutí hrdiny)': EnemyAbilityDef(EnemyAbilityKind.stackingDebuff, mods: {'phys': -0.10, 'mag': -0.10, 'armor': -0.10, 'crit': -0.10, 'dodge': -0.10, 'block': -0.10}, duration: 3),
  'Odplata (Vrací část zranění zpět)': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.10, duration: 2),
  'Otočení osudu (Obnova vlastního zdraví)': EnemyAbilityDef(EnemyAbilityKind.bossHeal, amount: 0.20),
  'Panická hrůza (Rozklepání hrdiny)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'block': -0.20}, duration: 3),
  'Solární erupce (Olepující žár slunce)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.05, duration: 3),
  'Písečná bouře (Odebrání přesnosti útoků)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'crit': -0.20}, duration: 3),
  'Koska smrti (Okamžitý vysoký úhoz)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.35),
  'Uragánový vír (Odvátí části štítů)': EnemyAbilityDef(EnemyAbilityKind.cancelShield),
  'Válečná vřava (Hrubá síla a destrukce)': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.30, duration: 2),
  'Taktická analýza (Proniknutí do obrany)': EnemyAbilityDef(EnemyAbilityKind.ignoreArmor, amount: 0.35),
  'Zastavení času (Zamrznutí akcí v čase)': EnemyAbilityDef(EnemyAbilityKind.stun, duration: 1),
  'Kořeny země (Přišpendlení k zemi)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'dodge': -0.25}, duration: 3),
  'Brána podsvětí (Přivolání stínových klonů)': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.25, duration: 3),
  'Žhavý paprsek (Nepřetržitý magický žár)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.05, duration: 4),
  'Královský rozkaz (Snížení efektivity útoků)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'phys': -0.20, 'mag': -0.20}, duration: 3),
  'Rychlost blesku (Dvojitý útok za sebou)': EnemyAbilityDef(EnemyAbilityKind.doubleAttack),
  'Tsunami (Záplava vodní energie)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.20),
  'Mjölnirovský úder (Kladivo hromu a blesku)': EnemyAbilityDef(EnemyAbilityKind.guaranteedCrit),
  'Klamná iluze (Zaměnění reálného poškození)': EnemyAbilityDef(EnemyAbilityKind.doubleAttack),
  'Moudrost run (Speciální magická bariéra)': EnemyAbilityDef(EnemyAbilityKind.bossShield, amount: 0.30),
  'Očarování (Zmatení mysli hrdiny)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'crit': -0.25}, duration: 3),
  'Bifrostová duha (Magický duhový paprsek)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'armor': -0.30}, duration: 2),
  'Meč z plamene (Roztavení zbroje a štítů)': EnemyAbilityDef(EnemyAbilityKind.cancelShield),
  'Mízová obnova (Konstantní pasivní léčení)': EnemyAbilityDef(EnemyAbilityKind.bossHeal, amount: 0.08),
  'Kousnutí temnoty (Lokální toxický útok)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.04, duration: 3),
  'Rychlý skok (Nepředvídatelný úder ze zálohy)': EnemyAbilityDef(EnemyAbilityKind.guaranteedCrit),
  'Ledový šíp (Přesný průstřel zbroje)': EnemyAbilityDef(EnemyAbilityKind.ignoreArmor, amount: 0.30),
  'Fjordová vlna (Mohutný slapový úder)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.25),
  'Svaté světlo (Olepující božský paprsek)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.04, duration: 3),
  'Spravedlivá rána (Rána plná čestné síly)': EnemyAbilityDef(EnemyAbilityKind.bossBuff, amount: 0.50),
  'Mlčenlivá smrt (Nezastavitelný tichý úder)': EnemyAbilityDef(EnemyAbilityKind.ignoreBlockDodge),
  'Hvězdný šíp (Přesný zásah na dálku)': EnemyAbilityDef(EnemyAbilityKind.guaranteedCrit),
  'Píseň osudu (Magická rezonance duše)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'phys': -0.20, 'mag': -0.20, 'armor': -0.20, 'crit': -0.20, 'dodge': -0.20, 'block': -0.20}, duration: 3),
  'Zlatá jablka (Rychlá obnova zdraví bosse)': EnemyAbilityDef(EnemyAbilityKind.bossHeal, amount: 0.25),
  'Poloviční chlad (Zmražení poloviny síly)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'phys': -0.30, 'mag': -0.30}, duration: 3),
  'Trhání masa (Brutální fyzické roztrhání)': EnemyAbilityDef(EnemyAbilityKind.dot, amount: 0.06, duration: 4),
  'Otočení světa (Kataklyzmatické stlačení)': EnemyAbilityDef(EnemyAbilityKind.trueDamage, amount: 0.35),
  'Zánik Vesmíru (Finální božská destrukce)': EnemyAbilityDef(EnemyAbilityKind.statDebuff, mods: {'phys': -0.20, 'mag': -0.20, 'armor': -0.20, 'crit': -0.20, 'dodge': -0.20, 'block': -0.20}, duration: 3),
};

// ===== TUTORIAL / NÁPOVĚDA - postupné vysvětlování hry, jak pro úplného nováčka, tak pro
// pokročilého/min-max hráče. Každý tip má krátké "co to dělá" vysvětlení vždy viditelné +
// skrytý "Pro-tip" (optimalizační rada), který se rozbalí tlačítkem - viz TutorialTipContent
// ve screens.dart. Lineární úvodní sekvence (kTutorialIntroSteps) proběhne jednou, hned po
// výběru třídy u úplně první postavy na účtu (viz GameState.selectClass). Ostatní tipy jsou
// kontextové - spustí se jednorázově, jakmile si hráč danou mechaniku poprvé odemkne (viz
// GameState._queueContextTip, volané z míst jako unlock specializace/run/artefaktu/Lairu/Arény).
enum TutorialTipId {
  introWelcome, introCombat, introGoldXp, introEquip, introFloors, introWhatsNext,
  tipSpecialization, tipRune, tipArtifactWeapon, tipLairUnlocked, tipArenaUnlocked,
  tipWorldBossUnlocked, tipRiftUnlocked, tipCompanionsUnlocked, tipAscension, tipEndlessScale,
  tipHardcoreUnlocked, tipPredpekliUnlocked, tipPekloUnlocked, tipArtifactForge,
}

class TutorialTipDef {
  final IconData icon;
  final String titleCz, titleEn;
  final String basicCz, basicEn; // vždy viditelné - pro casual hráče
  final String advancedCz, advancedEn; // za tlačítkem "Zobrazit pokročilé" - pro min-maxera
  const TutorialTipDef({required this.icon, required this.titleCz, required this.titleEn, required this.basicCz, required this.basicEn, required this.advancedCz, required this.advancedEn});
}

// Pořadí lineárního úvodního tutoriálu (viz GameState.introTutorialStep).
const List<TutorialTipId> kTutorialIntroSteps = [
  TutorialTipId.introWelcome, TutorialTipId.introCombat, TutorialTipId.introGoldXp,
  TutorialTipId.introEquip, TutorialTipId.introFloors, TutorialTipId.introWhatsNext,
];

const Map<TutorialTipId, TutorialTipDef> kTutorialTips = {
  TutorialTipId.introWelcome: TutorialTipDef(
    icon: Icons.auto_awesome,
    titleCz: 'Vítej ve Věži!', titleEn: 'Welcome to the Tower!',
    basicCz: 'Tohle je idle-RPG: tvůj hrdina bojuje ve Věži (klidně i automaticky), sbírá zlato, předměty a zkušenosti. Ty ho postupně posouváš výš a výš, sbíráš lepší vybavení a odemykáš nové systémy.',
    basicEn: 'This is an idle RPG: your hero fights in the Tower (even automatically), collecting gold, items, and experience. You push them higher and higher, gathering better gear and unlocking new systems.',
    advancedCz: 'Pro-tip: nespěchej do hloubky jednoho systému. Nejrychlejší dlouhodobý postup vzniká z vyváženého rozvoje - útok, výdrž i vybavení současně, ne jedno na úkor druhého.',
    advancedEn: "Pro-tip: don't rush to max out one system. The fastest long-term progress comes from balanced growth — attack, survivability, and gear together, not one at the expense of another.",
  ),
  TutorialTipId.introCombat: TutorialTipDef(
    icon: Icons.local_fire_department,
    titleCz: 'Jak funguje boj', titleEn: 'How combat works',
    basicCz: 'Věž bojuje sama (Auto-boj), nebo si útoky spouštíš ručně. Poškození ovlivňuje tvůj Fyzický/Magický útok proti Armoru nepřítele, plus náhodné šance na Crit (víc dmg), Dodge (uhnutí) a Block (snížené dmg).',
    basicEn: 'The Tower fights on its own (Auto-fight), or you trigger attacks manually. Damage depends on your Physical/Magic attack vs the enemy Armor, plus random chances for Crit (more dmg), Dodge (avoid), and Block (reduced dmg).',
    advancedCz: 'Pro-tip: Crit/Dodge/Block mají klesající návratnost (rating/(rating+konstanta)) - první body do statu jsou nejsilnější, přehnané stackování jednoho statu je neefektivní. Sázej na vyvážený build.',
    advancedEn: 'Pro-tip: Crit/Dodge/Block follow diminishing returns (rating/(rating+constant)) — the first points are the strongest, over-stacking one stat is inefficient. Favor a balanced build.',
  ),
  TutorialTipId.introGoldXp: TutorialTipDef(
    icon: Icons.paid,
    titleCz: 'Zlato a zkušenosti', titleEn: 'Gold and experience',
    basicCz: 'Za poražené nepřátele dostáváš Zlato (na nákup vybavení a vylepšení) a Zkušenosti (level up = víc statů).',
    basicEn: 'Defeating enemies gives you Gold (for buying gear and upgrades) and Experience (leveling up = more stats).',
    advancedCz: 'Pro-tip: neshromažďuj zlato zbytečně - samo o sobě nezesiluje postavu. Radši ho průběžně investuj (vybavení, rychlost auto-boje, respec specializace).',
    advancedEn: "Pro-tip: don't hoard gold — it does nothing for your power on its own. Keep investing it (gear, auto-fight speed, specialization respec).",
  ),
  TutorialTipId.introEquip: TutorialTipDef(
    icon: Icons.shield,
    titleCz: 'Výbava', titleEn: 'Gear',
    basicCz: 'V Inventáři si nasazuj zbraně, brnění a doplňky - každý slot přidává staty. Vyšší vzácnost (rarity) znamená lepší staty.',
    basicEn: "Equip weapons, armor, and accessories from your Inventory — each slot adds stats. Higher rarity means better stats.",
    advancedCz: 'Pro-tip: sleduj i sety (bonusy za 2/4/6 kusů) - kompletní set se souvislou synergií často předčí náhodně nejlepší jednotlivé kusy bez ní.',
    advancedEn: 'Pro-tip: watch for sets too (2/4/6-piece bonuses) — a complete set with real synergy often beats randomly "best" individual pieces without one.',
  ),
  TutorialTipId.introFloors: TutorialTipDef(
    icon: Icons.stairs,
    titleCz: 'Patra Věže', titleEn: 'Tower floors',
    basicCz: 'Věž má patra - každé 5. patro je boss. Postup výš znamená silnější nepřátele, ale i lepší odměny.',
    basicEn: 'The Tower has floors — every 5th floor is a boss. Going higher means tougher enemies, but also better rewards.',
    advancedCz: 'Pro-tip: pokud opakovaně umíráš na stejném patře, není ostuda se vrátit níž a dofarmit staty/vybavení - Věž na tebe počká, nic tím neztrácíš.',
    advancedEn: "Pro-tip: if you keep dying on the same floor, there's no shame in stepping back to farm stats/gear — the Tower waits, you lose nothing by doing so.",
  ),
  TutorialTipId.introWhatsNext: TutorialTipDef(
    icon: Icons.explore,
    titleCz: 'Co dál', titleEn: "What's next",
    basicCz: 'Postupem hry odemkneš specializace, runy, Doupě (Lair), Arénu, Trhliny (Rift) a další systémy. Hra ti každý z nich krátce představí, jakmile ho odemkneš.',
    basicEn: "As you progress you'll unlock specializations, runes, the Lair, the Arena, Rifts, and more. The game will briefly introduce each one as soon as you unlock it.",
    advancedCz: 'Pro-tip: klidně nech Auto-boj běžet na pozadí a mezitím si prozkoumej menu - nic ti neuteče a odemykání systémů se řídí tvým postupem, ne časem.',
    advancedEn: "Pro-tip: feel free to let Auto-fight run in the background while you explore the menus — nothing is missed, and unlocks are tied to your progress, not to time.",
  ),
  TutorialTipId.tipSpecialization: TutorialTipDef(
    icon: Icons.account_tree,
    titleCz: 'Specializace odemčena!', titleEn: 'Specialization unlocked!',
    basicCz: 'Od teď si můžeš vybrat jednu ze 3 specializací své třídy - každá mění styl hraní (např. útočná/obranná/podpůrná).',
    basicEn: 'You can now choose one of your class\'s 3 specializations — each changes your playstyle (e.g. offensive/defensive/support).',
    advancedCz: 'Pro-tip: specializaci lze později změnit (respec) za zlato, takže klidně vyzkoušej víc stylů - není to nevratné rozhodnutí.',
    advancedEn: "Pro-tip: you can respec your specialization later for gold, so feel free to try different styles — it's not an irreversible choice.",
  ),
  TutorialTipId.tipRune: TutorialTipDef(
    icon: Icons.blur_circular,
    titleCz: 'Runy odemčeny!', titleEn: 'Runes unlocked!',
    basicCz: 'Runy dávají pasivní bonusy navíc k vybavení. Umisťují se do Runového stromu u Runového Čaroděje a postupně je vylepšuješ.',
    basicEn: 'Runes grant passive bonuses on top of your gear. Place them in the Rune Tree at the Rune Wizard and upgrade them over time.',
    advancedCz: 'Pro-tip: řeš nejdřív runy, co škálují s tím, co už máš silné (např. crit build → crit runy) - synergie s buildem má větší cenu než rozptýlené menší bonusy.',
    advancedEn: 'Pro-tip: prioritize runes that scale with what you already have (e.g. a crit build → crit runes) — synergy with your build beats scattered small bonuses.',
  ),
  TutorialTipId.tipArtifactWeapon: TutorialTipDef(
    icon: Icons.auto_fix_high,
    titleCz: 'Artefaktová zbraň odemčena!', titleEn: 'Artifact weapon unlocked!',
    basicCz: 'Artefaktová zbraň roste s tebou napříč celou hrou a dá se donekonečna vylepšovat (forge). Je to tvá "věčná" zbraň.',
    basicEn: 'Your artifact weapon grows with you throughout the whole game and can be upgraded (forged) indefinitely. It\'s your "forever" weapon.',
    advancedCz: 'Pro-tip: forge stojí materiály + obětování silnější zbraně z inventáře - nevyhazuj silné zbraně, dokud tě artefakt nedožene silou.',
    advancedEn: "Pro-tip: forging costs materials plus sacrificing a stronger weapon from your inventory — don't sell strong weapons until your artifact catches up in power.",
  ),
  TutorialTipId.tipLairUnlocked: TutorialTipDef(
    icon: Icons.castle,
    titleCz: 'Doupě (Lair) odemčeno!', titleEn: 'The Lair unlocked!',
    basicCz: 'Lair je samostatný herní mód s vlastními patry a bossy, nezávislý na tvém postupu ve Věži.',
    basicEn: "The Lair is a separate game mode with its own floors and bosses, independent of your Tower progress.",
    advancedCz: 'Pro-tip: Lair je hlavní zdroj Hardcore/Předpeklí/Peklo gear setů - je klíčový pro dlouhodobý progres, ne jen vedlejší aktivita.',
    advancedEn: 'Pro-tip: the Lair is the main source of Hardcore/Předpeklí/Peklo gear sets — it matters for long-term progress, not just a side activity.',
  ),
  TutorialTipId.tipArenaUnlocked: TutorialTipDef(
    icon: Icons.sports_kabaddi,
    titleCz: 'Aréna odemčena!', titleEn: 'The Arena unlocked!',
    basicCz: 'V Aréně bojuješ proti jiným hrdinům (AI) o žebříček a odměny.',
    basicEn: 'In the Arena you fight other heroes (AI) for ranking and rewards.',
    advancedCz: 'Pro-tip: Aréna odměňuje jiný build než PvE (odolnost/burst proti jinému hrdinovi) - klidně měj druhou sadu vybavení/specializace jen pro ni.',
    advancedEn: 'Pro-tip: the Arena rewards a different build than PvE (survivability/burst vs another hero) — consider keeping a second gear/spec loadout just for it.',
  ),
  TutorialTipId.tipWorldBossUnlocked: TutorialTipDef(
    icon: Icons.dangerous,
    titleCz: 'World Boss odemčen!', titleEn: 'World Boss unlocked!',
    basicCz: 'World Boss je extra silný soupeř na denní bázi - poraž ho pro bonusové odměny navíc k tomu, co farmíš ve Věži.',
    basicEn: "The World Boss is an extra-tough daily encounter — defeat it for bonus rewards on top of what you farm in the Tower.",
    advancedCz: 'Pro-tip: World Boss má vlastní sadu schopností nezávislou na Věži/Lairu - vyplatí se ho zkusit i s buildem, co by na běžný postup nesázel.',
    advancedEn: "Pro-tip: the World Boss uses its own ability set separate from the Tower/Lair — worth attempting even with a build you wouldn't normally use for regular progress.",
  ),
  TutorialTipId.tipRiftUnlocked: TutorialTipDef(
    icon: Icons.blur_on,
    titleCz: 'Trhlina (Rift) odemčena!', titleEn: 'The Rift unlocked!',
    basicCz: 'Trhlina staví tvé schopnosti proti Guardianovi ve vlnách rostoucí obtížnosti (tier). Postup dál = lepší odměny za Rift.',
    basicEn: 'The Rift pits your abilities against a Guardian across waves of rising difficulty (tier). Going further means better Rift rewards.',
    advancedCz: 'Pro-tip: v Riftu se schopnosti castují automaticky (auto-cast) - sleduj hlavně cooldowny a pořadí, ne ruční mačkání jako jinde.',
    advancedEn: 'Pro-tip: abilities in the Rift auto-cast — focus on cooldowns and sequencing rather than manual input like elsewhere.',
  ),
  TutorialTipId.tipCompanionsUnlocked: TutorialTipDef(
    icon: Icons.groups,
    titleCz: 'První společník odemčen!', titleEn: 'First companion unlocked!',
    basicCz: 'Společníci bojují po tvém boku a mají vlastní kouzla. Do družiny jich můžeš mít současně max. 2.',
    basicEn: 'Companions fight alongside you and have their own spells. You can have at most 2 in your party at once.',
    advancedCz: 'Pro-tip: propuštění společníka není trvalá ztráta - jednou odemčeného ho můžeš kdykoliv znovu přijmout zdarma, jen výběr dvou aktivních stojí za zvážení podle role (dmg/tank/heal).',
    advancedEn: "Pro-tip: dismissing a companion isn't a permanent loss — once unlocked, you can re-recruit them for free anytime; just weigh which two you keep active by role (dmg/tank/heal).",
  ),
  TutorialTipId.tipAscension: TutorialTipDef(
    icon: Icons.upgrade,
    titleCz: 'Ascension!', titleEn: 'Ascension!',
    basicCz: 'Za poražení bosse na patře 100 v Lairu na dané obtížnosti tvá postava "ascenduje" - staty se sníží (squish), ale dostaneš trvalý bonus a otevře se další, těžší vrstva obtížnosti.',
    basicEn: 'Defeating the floor-100 Lair boss on a given difficulty makes your character "ascend" — stats are reduced (squish), but you gain a permanent bonus and the next, harder difficulty layer opens up.',
    advancedCz: 'Pro-tip: squish je navržen tak, aby sis na patře 1 nové vrstvy zase musel bojovat - neboj se ho, dlouhodobě je to čistý zisk, ne krok zpátky.',
    advancedEn: "Pro-tip: the squish is designed so floor 1 of the new layer takes effort again — don't fear it, it's a net long-term gain, not a step backward.",
  ),
  TutorialTipId.tipEndlessScale: TutorialTipDef(
    icon: Icons.all_inclusive,
    titleCz: 'Endless Scale odemčen!', titleEn: 'Endless Scale unlocked!',
    basicCz: 'Peklo je poraženo! Odemkl se nový nekonečný mód - opakovaně farmíš Soul Demona, který po každém zabití trochu zesílí. Cíl: dojít co nejdál.',
    basicEn: "Hell has been defeated! A new endless mode has opened up — repeatedly farm the Soul Demon, who gets a bit stronger with each kill. The goal: go as far as you can.",
    advancedCz: 'Pro-tip: Soul Demon sílí v HP/Armoru, ne v Atk - build na přežití (Armor/Vitality) se s postupem vyplatí čím dál víc, čistě damage build narazí na strop rychleji.',
    advancedEn: "Pro-tip: the Soul Demon scales HP/Armor, not Atk — a survival build (Armor/Vitality) pays off more and more over time, a pure damage build hits a wall sooner.",
  ),
  TutorialTipId.tipHardcoreUnlocked: TutorialTipDef(
    icon: Icons.warning_amber,
    titleCz: 'Hardcore Mode odemčen!', titleEn: 'Hardcore Mode unlocked!',
    basicCz: 'Vše, co jsi dosud hrál, byla Normal obtížnost. Hardcore je první ze tří tvrdších vrstev - přináší silnější nepřátele, ale i lepší odměny a vlastní gear sety.',
    basicEn: "Everything you've played so far was Normal difficulty. Hardcore is the first of three tougher layers — stronger enemies, but better rewards and its own gear sets.",
    advancedCz: 'Pro-tip: v Hardcore módu je aktivní náhodné Prokletí (Curse), co mění pravidla boje. Přepnutí obtížnosti restartuje patro Věže na 1 - neboj se, staty a vybavení zůstávají.',
    advancedEn: "Pro-tip: Hardcore Mode runs an active random Curse that changes combat rules. Switching difficulty resets the Tower floor to 1 — don't worry, your stats and gear stay.",
  ),
  TutorialTipId.tipPredpekliUnlocked: TutorialTipDef(
    icon: Icons.local_fire_department,
    titleCz: 'Předpeklí odemčeno!', titleEn: 'The Netherworld unlocked!',
    basicCz: 'Druhá, tvrdší vrstva obtížnosti nad Hardcore. Silnější nepřátelé, silnější gear sety.',
    basicEn: 'The second, tougher difficulty layer above Hardcore. Stronger enemies, stronger gear sets.',
    advancedCz: 'Pro-tip: nemusíš spěchat nahoru hned - Předpeklí sety jsou navrženy jako 1.5× silnější než Hardcore, takže dofarmení Hardcore setu napřed dává smysl.',
    advancedEn: "Pro-tip: no need to rush up immediately — Netherworld sets are designed to be 1.5× stronger than Hardcore ones, so finishing your Hardcore set first is a reasonable choice.",
  ),
  TutorialTipId.tipPekloUnlocked: TutorialTipDef(
    icon: Icons.whatshot,
    titleCz: 'Peklo odemčeno!', titleEn: 'Hell unlocked!',
    basicCz: 'Třetí a nejtvrdší obtížnostní vrstva. Poražení bosse na patře 100 tady otevírá endgame mód Endless Scale.',
    basicEn: 'The third and toughest difficulty layer. Defeating the floor-100 boss here unlocks the Endless Scale endgame mode.',
    advancedCz: 'Pro-tip: Peklo je poslední krok před Ascension IV - shromáždi nejsilnější dostupný build (gear set + runy + artefakt), než se do něj pustíš naplno.',
    advancedEn: 'Pro-tip: Hell is the last step before Ascension IV — assemble the strongest build available to you (gear set + runes + artifact) before committing to it fully.',
  ),
  TutorialTipId.tipArtifactForge: TutorialTipDef(
    icon: Icons.construction,
    titleCz: 'Vylepšení artefaktu (Forge)!', titleEn: 'Artifact upgrade (Forge)!',
    basicCz: 'Právě jsi poprvé vylepšil svou artefaktovou zbraň obětováním silnější zbraně z batohu. Dá se to opakovat donekonečna - artefakt tak zůstane navždy nejsilnější zbraní.',
    basicEn: "You just upgraded your artifact weapon for the first time by sacrificing a stronger weapon from your bag. This can be repeated indefinitely — the artifact stays the strongest weapon forever.",
    advancedCz: 'Pro-tip: nevyhazuj/neprodávej silné zbraně z batohu předčasně - jsou to budoucí forge materiály. Vždy potřebuješ zbraň silnější než aktuální artefakt.',
    advancedEn: "Pro-tip: don't discard or sell strong weapons from your bag prematurely — they're future forge material. You always need a weapon stronger than your current artifact.",
  ),
};
