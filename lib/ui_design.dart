part of 'main.dart';

class FantasyColors {
  static const abyss = Color(0xFF0D0B09);
  static const panel = Color(0xFF1A1511);
  static const panelLight = Color(0xFF2B2118);
  static const gold = Color(0xFFD4AF37);
  static const bronze = Color(0xFF7A552C);
  static const parchment = Color(0xFFF0DFC0);
  static const button = Color(0xFF352516);
  static const hp = Color(0xFF9D1010);
  static const mana = Color(0xFF155AB6);
  static const rune = Color(0xFF7137A8);
}

// ===== MODERN MOBILE UI — DESIGN SYSTEM v2 =====
// Obsidian + jantarové zlato + arkánová fialová/tyrkys. Vlastní stylizované
// liniové ikony (žádné emoji, žádné externí assety třetích stran).

class FantasyColors2 {
  static const obsidian = Color(0xFF0A0710);
  static const panel = Color(0xFF1A1422);
  static const panelLight = Color(0xFF2B2038);
  static const border = Color(0xFF4A3A5E);
  static const emberGold = Color(0xFFF3C869);
  static const arcaneViolet = Color(0xFFB79CFF);
  static const teal = Color(0xFF3FD6C2);
  static const hp = Color(0xFFE4463F);
  static const parchment = Color(0xFFF0E6D2);
  static const muted = Color(0xFF9A8560);
  // Severská ledová paleta - vyhrazená pro Runového Čaroděje, aby se vizuálně odlišil
  // od teplé jantarové palety zbytku "Světa".
  static const runeIce = Color(0xFF7FD8FF);
  static const runeStone = Color(0xFF8A93A6);
  static const runeBg = Color(0xFF0D1117);
  static const runeBgLight = Color(0xFF16202B);
  static const runePanel = Color(0xFF141C25);
  static const runeText = Color(0xFFE7F3FA);
  static const runeMuted = Color(0xFF9AAABF);
}

TextTheme fantasyTextTheme(TextTheme base) => base.copyWith(
      titleLarge: GoogleFonts.cinzel(fontWeight: FontWeight.w700, letterSpacing: .3, color: FantasyColors2.parchment),
      titleMedium: GoogleFonts.cinzel(fontWeight: FontWeight.w600, color: FantasyColors2.parchment),
      titleSmall: GoogleFonts.cinzel(fontWeight: FontWeight.w600, color: FantasyColors2.parchment),
      bodyLarge: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: FantasyColors2.parchment),
      bodyMedium: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: FantasyColors2.parchment),
      labelSmall: GoogleFonts.manrope(fontWeight: FontWeight.w800, letterSpacing: 1.1, color: FantasyColors2.muted),
    );

// =============================================================================
// FANTASY ICON SYSTEM v2 — AAA fantasy RPG redesign
// Nahrazuje: FantasyGlyphs (thin line-art SVG) a Item.icon (Material Icons).
//
// Architektura:
//   FantasyIconType     - taxonomie všech ikon ve hře (enum, rozšiřitelné)
//   FantasyRarity       - 5 rarity úrovní + jejich vizuální styl
//   FantasyIconAsset    - buď cesta k SVG assetu, nebo procedurální painter (fallback)
//   FantasyIconRegistry - mapování typ -> asset
//   FantasyIconFrame    - hlavní widget: plát + ikona + rarity rám + glow + hover
//
// Použití:
//   FantasyIconFrame(type: FantasyIconType.classDeathKnight, rarity: FantasyRarity.legendary, size: 64)
// =============================================================================


// =============================================================================
// 1. TAXONOMIE
// =============================================================================

enum FantasyIconType {
  // --- Hero classy ---
  classWarrior, classHunter, classPriest, classDruid,
  classDeathKnight, classNecromancer, classMonk, classDuelist, classMage, classPaladin, classDemonHunter,

  // --- Herní systémy (Hub dlaždice) ---
  systemBossLair, systemGuild, systemQuests, systemForge,
  systemAlchemy, systemMarket, systemRuneWizard, systemInventory, systemTower, systemRift,

  // --- Equipment sloty ---
  slotWeapon, slotArmor, slotHelmet, slotGloves, slotBoots, slotRing, slotAmulet, slotBelt, slotCloak, slotRelic, slotShoulder,

  // --- Rarity markery ---
  markLegendary, markSetItem,

  // --- Konzumovatelné ---
  potionHealing, potionVampiric, potionStrength, potionStoneskin, potionWisdom,

  // --- Materiály ---
  materialSteel, materialLeather, materialWood, materialMagicDust, materialLegendaryEssence,

  // --- Runy ---
  runeBleed, runeFire, runeFrost, runeArmorPen, runeCritChance, runeDodge, runeBlock, runeBossDamage,

  // --- Měna ---
  currencyGold, currencyCrystal, currencyEssence,

  // --- UI / staty ---
  statHeart, statBolt, statShieldDef, statSword, questScroll, questExclaim, chest,
}

// =============================================================================
// 2. RARITY SYSTÉM
// =============================================================================

enum FantasyRarity { common, rare, epic, legendary, setItem, artifact }

class RarityStyle {
  final Color borderColor;
  final Color glowColor;
  final double borderWidth;
  final double glowBlur;
  final double glowAlpha;
  final bool animatedGlow; // "dýchající" pulse (jen legendary)
  final int cornerOrnaments; // kolik rohů má runový ornament (0 = žádný)
  final double hoverScale;
  const RarityStyle({
    required this.borderColor,
    required this.glowColor,
    required this.borderWidth,
    required this.glowBlur,
    required this.glowAlpha,
    this.animatedGlow = false,
    this.cornerOrnaments = 0,
    this.hoverScale = 1.0,
  });
}

const Map<FantasyRarity, RarityStyle> kRarityStyles = {  FantasyRarity.common: RarityStyle(
    borderColor: Color(0xFF9D9D9D),
    glowColor: Colors.transparent,
    borderWidth: 1.5,
    glowBlur: 0,
    glowAlpha: 0,
    hoverScale: 1.02,
  ),
  FantasyRarity.rare: RarityStyle(
    borderColor: Color(0xFF0070DD),
    glowColor: Color(0xFF0070DD),
    borderWidth: 2.0,
    glowBlur: 6,
    glowAlpha: 0.35,
    cornerOrnaments: 2,
    hoverScale: 1.04,
  ),
  FantasyRarity.epic: RarityStyle(
    borderColor: Color(0xFFA335EE),
    glowColor: Color(0xFFA335EE),
    borderWidth: 2.5,
    glowBlur: 10,
    glowAlpha: 0.45,
    cornerOrnaments: 4,
    hoverScale: 1.05,
  ),
  FantasyRarity.legendary: RarityStyle(
    borderColor: Color(0xFFFF8000),
    glowColor: Color(0xFFFF8000),
    borderWidth: 3.0,
    glowBlur: 14,
    glowAlpha: 0.6,
    animatedGlow: true,
    cornerOrnaments: 4,
    hoverScale: 1.06,
  ),
  FantasyRarity.setItem: RarityStyle(
    borderColor: Color(0xFF00CC66),
    glowColor: Color(0xFF00CC66),
    borderWidth: 2.5,
    glowBlur: 10,
    glowAlpha: 0.5,
    cornerOrnaments: 1, // set-symbol vpravo dole
    hoverScale: 1.05,
  ),
  // Artefakt (Prsten Osudu z Lair 100) - nad Legendary, krvavě prizmatický, nejsilnější glow ve hře.
  FantasyRarity.artifact: RarityStyle(
    borderColor: Color(0xFFFF1744),
    glowColor: Color(0xFFFF1744),
    borderWidth: 3.5,
    glowBlur: 20,
    glowAlpha: 0.75,
    animatedGlow: true,
    cornerOrnaments: 4,
    hoverScale: 1.08,
  ),
};

// Sdílený glow (box-shadow) pro celé karty/řádky v seznamech (inventář, atd.) - odděleno od
// FantasyIconFrame, který glowuje jen samotnou ikonu. Common nemá žádný glow (glowAlpha 0),
// rare/epic/legendary/artifact dostanou postupně silnější "aura" kolem celé karty, aby vyšší
// rarity vizuálně vyskočily ze seznamu i mimo samotnou ikonu (viz bod 2 grafického review).
List<BoxShadow> rarityCardGlow(FantasyRarity rarity) {
  final style = kRarityStyles[rarity]!;
  if (style.glowAlpha <= 0) return const [];
  return [BoxShadow(color: style.glowColor.withOpacity(style.glowAlpha * 0.45), blurRadius: style.glowBlur * 0.8, spreadRadius: 0.5)];
}

// Pomocná paleta pro procedurální ikony (viz sekce design docu).
class FantasyPalette {
  static const obsidian = Color(0xFF1A1410);
  static const ironDark = Color(0xFF3A3238);
  static const bronze = Color(0xFF6B5D52);
  static const oldGold = Color(0xFFC9A96E);
  static const bloodRed = Color(0xFF8B0E0E);
  static const frostBlue = Color(0xFF4FC3F7);
  static const holyGold = Color(0xFFFFD700);
  static const natureGreen = Color(0xFF4CAF50);
  static const shadowPurple = Color(0xFF7B2FBE);
  static const parchment = Color(0xFFD8C39A);
}

// =============================================================================
// 3. REGISTRY (typ -> asset cesta ANEBO procedurální fallback painter)
// =============================================================================

class FantasyIconAsset {
  /// Cesta k reálnému SVG assetu (assets/icons/...). Null = použij fallback.
  final String? svgAssetPath;
  /// Procedurální vektorový fallback (a zároveň dnešní produkční renderer,
  /// dokud reálné assety nejsou naimportované).
  final CustomPainter Function(Color tint) proceduralPainter;
  /// Přirozený tón ikony nezávislý na rarity (použije se pro tint kovu/detailů).
  final Color accentColor;
  const FantasyIconAsset({
    this.svgAssetPath,
    required this.proceduralPainter,
    this.accentColor = FantasyPalette.oldGold,
  });
}

class FantasyIconRegistry {
  static final Map<FantasyIconType, FantasyIconAsset> _assets = {
    // --- Classy ---
    FantasyIconType.classWarrior: FantasyIconAsset(
      proceduralPainter: (t) => _WarriorPainter(t),
      accentColor: FantasyPalette.oldGold,
    ),
    FantasyIconType.classHunter: FantasyIconAsset(
      proceduralPainter: (t) => _HunterPainter(t),
      accentColor: FantasyPalette.natureGreen,
    ),
    FantasyIconType.classPriest: FantasyIconAsset(
      proceduralPainter: (t) => _PriestPainter(t),
      accentColor: FantasyPalette.holyGold,
    ),
    FantasyIconType.classPaladin: FantasyIconAsset(
      proceduralPainter: (t) => _PaladinPainter(t),
      accentColor: FantasyPalette.holyGold,
    ),
    FantasyIconType.classDemonHunter: FantasyIconAsset(
      proceduralPainter: (t) => _DemonHunterPainter(t),
      accentColor: FantasyPalette.shadowPurple,
    ),
    FantasyIconType.classDruid: FantasyIconAsset(
      proceduralPainter: (t) => _DruidPainter(t),
      accentColor: FantasyPalette.natureGreen,
    ),
    FantasyIconType.classDeathKnight: FantasyIconAsset(
      proceduralPainter: (t) => _DeathKnightPainter(t),
      accentColor: FantasyPalette.frostBlue,
    ),
    FantasyIconType.classNecromancer: FantasyIconAsset(
      proceduralPainter: (t) => _NecromancerPainter(t),
      accentColor: FantasyPalette.shadowPurple,
    ),
    FantasyIconType.classMonk: FantasyIconAsset(
      proceduralPainter: (t) => _MonkPainter(t),
      accentColor: FantasyPalette.holyGold,
    ),
    FantasyIconType.classDuelist: FantasyIconAsset(
      proceduralPainter: (t) => _DuelistPainter(t),
      accentColor: FantasyPalette.oldGold,
    ),
    FantasyIconType.classMage: FantasyIconAsset(
      proceduralPainter: (t) => _MagePainter(t),
      accentColor: FantasyPalette.frostBlue,
    ),

    // --- Systémy ---
    FantasyIconType.systemBossLair: FantasyIconAsset(proceduralPainter: (t) => _BossLairPainter(t), accentColor: FantasyPalette.bloodRed),
    FantasyIconType.systemGuild: FantasyIconAsset(proceduralPainter: (t) => _GuildPainter(t), accentColor: FantasyPalette.oldGold),
    FantasyIconType.systemQuests: FantasyIconAsset(proceduralPainter: (t) => _QuestsPainter(t), accentColor: FantasyPalette.parchment),
    FantasyIconType.systemForge: FantasyIconAsset(proceduralPainter: (t) => _ForgePainter(t), accentColor: FantasyPalette.bloodRed),
    FantasyIconType.systemAlchemy: FantasyIconAsset(proceduralPainter: (t) => _AlchemyPainter(t), accentColor: FantasyPalette.shadowPurple),
    FantasyIconType.systemMarket: FantasyIconAsset(proceduralPainter: (t) => _MarketPainter(t), accentColor: FantasyPalette.oldGold),
    FantasyIconType.systemRuneWizard: FantasyIconAsset(proceduralPainter: (t) => _RuneWizardPainter(t), accentColor: FantasyPalette.frostBlue),
    FantasyIconType.systemInventory: FantasyIconAsset(proceduralPainter: (t) => _InventoryPainter(t), accentColor: FantasyPalette.bronze),
    FantasyIconType.systemTower: FantasyIconAsset(proceduralPainter: (t) => _TowerPainter(t), accentColor: FantasyPalette.shadowPurple),
    FantasyIconType.systemRift: FantasyIconAsset(proceduralPainter: (t) => _RiftPainter(t), accentColor: FantasyPalette.shadowPurple),

    // --- Equipment sloty (jednoduché, ale plné siluety) ---
    FantasyIconType.slotWeapon: FantasyIconAsset(proceduralPainter: (t) => _WeaponSlotPainter(t)),
    FantasyIconType.slotArmor: FantasyIconAsset(proceduralPainter: (t) => _ArmorSlotPainter(t)),
    FantasyIconType.slotShoulder: FantasyIconAsset(proceduralPainter: (t) => _ShoulderSlotPainter(t)), // Vlastní ikonka (pauldrony) - dřív sdíleno se zbrojí.
    FantasyIconType.slotHelmet: FantasyIconAsset(proceduralPainter: (t) => _HelmetSlotPainter(t)),
    FantasyIconType.slotGloves: FantasyIconAsset(proceduralPainter: (t) => _GlovesSlotPainter(t)),
    FantasyIconType.slotBoots: FantasyIconAsset(proceduralPainter: (t) => _BootsSlotPainter(t)),
    FantasyIconType.slotBelt: FantasyIconAsset(proceduralPainter: (t) => _BeltSlotPainter(t)),
    FantasyIconType.slotCloak: FantasyIconAsset(proceduralPainter: (t) => _CloakSlotPainter(t)),
    FantasyIconType.slotRing: FantasyIconAsset(proceduralPainter: (t) => _RingSlotPainter(t)),
    FantasyIconType.slotAmulet: FantasyIconAsset(proceduralPainter: (t) => _AmuletSlotPainter(t)),

    // --- Rarity markery ---
    FantasyIconType.markLegendary: FantasyIconAsset(proceduralPainter: (t) => _LegendaryMarkPainter(t), accentColor: const Color(0xFFFF8000)),
    FantasyIconType.slotRelic: FantasyIconAsset(proceduralPainter: (t) => _LegendaryMarkPainter(t), accentColor: const Color(0xFFFF8000)),
    FantasyIconType.markSetItem: FantasyIconAsset(proceduralPainter: (t) => _SetMarkPainter(t), accentColor: const Color(0xFF00CC66)),

    // --- Potiony ---
    FantasyIconType.potionHealing: FantasyIconAsset(proceduralPainter: (t) => _PotionPainter(t, const Color(0xFFE23B3B))),
    FantasyIconType.potionVampiric: FantasyIconAsset(proceduralPainter: (t) => _PotionPainter(t, const Color(0xFF7A0E2C))),
    FantasyIconType.potionStrength: FantasyIconAsset(proceduralPainter: (t) => _PotionPainter(t, const Color(0xFFE07B1E))),
    FantasyIconType.potionStoneskin: FantasyIconAsset(proceduralPainter: (t) => _PotionPainter(t, const Color(0xFF8A8A8A))),
    FantasyIconType.potionWisdom: FantasyIconAsset(proceduralPainter: (t) => _PotionPainter(t, FantasyPalette.frostBlue)),

    // --- Materiály ---
    FantasyIconType.materialSteel: FantasyIconAsset(proceduralPainter: (t) => _MaterialIngotPainter(t, const Color(0xFF9DA3AB))),
    FantasyIconType.materialLeather: FantasyIconAsset(proceduralPainter: (t) => _MaterialHidePainter(t, const Color(0xFF7A4E2D))),
    FantasyIconType.materialWood: FantasyIconAsset(proceduralPainter: (t) => _MaterialLogPainter(t, const Color(0xFF6B4423))),
    FantasyIconType.materialMagicDust: FantasyIconAsset(proceduralPainter: (t) => _SparkleDustPainter(t)),
    FantasyIconType.materialLegendaryEssence: FantasyIconAsset(proceduralPainter: (t) => _EssenceOrbPainter(t)),

    // --- Runy ---
    FantasyIconType.runeBleed: FantasyIconAsset(proceduralPainter: (t) => _RuneStonePainter(t, const Color(0xFF8B0E0E))),
    FantasyIconType.runeFire: FantasyIconAsset(proceduralPainter: (t) => _RuneStonePainter(t, const Color(0xFFE07B1E))),
    FantasyIconType.runeFrost: FantasyIconAsset(proceduralPainter: (t) => _RuneStonePainter(t, FantasyPalette.frostBlue)),
    FantasyIconType.runeArmorPen: FantasyIconAsset(proceduralPainter: (t) => _RuneStonePainter(t, const Color(0xFF9D9D9D))),
    FantasyIconType.runeCritChance: FantasyIconAsset(proceduralPainter: (t) => _RuneStonePainter(t, const Color(0xFFA335EE))),
    FantasyIconType.runeDodge: FantasyIconAsset(proceduralPainter: (t) => _RuneStonePainter(t, FantasyPalette.natureGreen)),
    FantasyIconType.runeBlock: FantasyIconAsset(proceduralPainter: (t) => _RuneStonePainter(t, FantasyPalette.oldGold)),
    FantasyIconType.runeBossDamage: FantasyIconAsset(proceduralPainter: (t) => _RuneStonePainter(t, const Color(0xFFFF8000))),

    // --- Měna ---
    FantasyIconType.currencyGold: FantasyIconAsset(proceduralPainter: (t) => _CoinPainter(t, FantasyPalette.oldGold)),
    FantasyIconType.currencyCrystal: FantasyIconAsset(proceduralPainter: (t) => _GemPainter(t, FantasyPalette.frostBlue)),
    FantasyIconType.currencyEssence: FantasyIconAsset(proceduralPainter: (t) => _GemPainter(t, FantasyPalette.shadowPurple)),

    // --- UI / staty ---
    FantasyIconType.statHeart: FantasyIconAsset(proceduralPainter: (t) => _HeartPainter(t)),
    FantasyIconType.statBolt: FantasyIconAsset(proceduralPainter: (t) => _BoltPainter(t)),
    FantasyIconType.statShieldDef: FantasyIconAsset(proceduralPainter: (t) => _ShieldPainter(t)),
    FantasyIconType.statSword: FantasyIconAsset(proceduralPainter: (t) => _SwordGlyphPainter(t)),
    FantasyIconType.questScroll: FantasyIconAsset(proceduralPainter: (t) => _ScrollPainter(t)),
    FantasyIconType.questExclaim: FantasyIconAsset(proceduralPainter: (t) => _ExclaimSealPainter(t)),
    FantasyIconType.chest: FantasyIconAsset(proceduralPainter: (t) => _ChestPainter(t)),
  };

  static FantasyIconAsset of(FantasyIconType type) {
    final asset = _assets[type];
    assert(asset != null, 'FantasyIconType.$type nemá zaregistrovaný asset — doplň FantasyIconRegistry._assets.');
    return asset!;
  }
}

// =============================================================================
// 4. CACHE / PRELOAD
// =============================================================================

// =============================================================================
// 5. HLAVNÍ WIDGET — FantasyIconFrame
// =============================================================================

/// Kompletní "loot ikona": kovový plát pozadí + procedurální/SVG ikona +
/// rarity rám + glow + rohové ornamenty + hover/press animace.
class FantasyIconFrame extends StatefulWidget {
  final FantasyIconType type;
  final FantasyRarity rarity;
  final double size;
  final bool interactive;
  final VoidCallback? onTap;

  const FantasyIconFrame({
    super.key,
    required this.type,
    this.rarity = FantasyRarity.common,
    this.size = 48,
    this.interactive = true,
    this.onTap,
  });

  @override
  State<FantasyIconFrame> createState() => _FantasyIconFrameState();
}

class _FantasyIconFrameState extends State<FantasyIconFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = kRarityStyles[widget.rarity]!;
    final asset = FantasyIconRegistry.of(widget.type);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: (widget.interactive && _hover) ? style.hoverScale : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final pulseT = style.animatedGlow ? (0.6 + 0.4 * _pulse.value) : 1.0;
              final hoverBoost = (widget.interactive && _hover) ? 1.5 : 1.0;
              return SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _IconFrameBackdropPainter(style: style, glowT: pulseT * hoverBoost),
                  child: Center(
                    child: SizedBox(
                      width: widget.size * 0.62,
                      height: widget.size * 0.62,
                      child: asset.svgAssetPath != null
                          ? SvgPicture.asset(asset.svgAssetPath!, colorFilter: null)
                          : CustomPaint(painter: asset.proceduralPainter(asset.accentColor)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Vykresluje kovový plát pozadí + rarity border + glow + rohové ornamenty.
/// Odděleno od hlavní ikony, aby glow/border byly vždy konzistentní napříč
/// celou hrou bez ohledu na to, co je uvnitř (SVG nebo procedurální).
class _IconFrameBackdropPainter extends CustomPainter {
  final RarityStyle style;
  final double glowT; // 0..1.5 - intenzita glow (hover/pulse)
  _IconFrameBackdropPainter({required this.style, required this.glowT});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;

    // Glow (za rámem)
    if (style.glowBlur > 0) {
      final glowPaint = Paint()
        ..color = style.glowColor.withOpacity((style.glowAlpha * glowT).clamp(0, 1))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.glowBlur);
      canvas.drawCircle(center, radius * 0.92, glowPaint);
    }

    // Kovový plát pozadí (radial gradient - obsidian střed, bronz okraj)
    final plateShader = RadialGradient(
      colors: [FantasyPalette.ironDark, FantasyPalette.obsidian],
      stops: const [0.0, 1.0],
    ).createShader(rect);
    canvas.drawCircle(center, radius * 0.88, Paint()..shader = plateShader);

    // Rarity border
    canvas.drawCircle(
      center,
      radius * 0.88,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.borderWidth
        ..color = style.borderColor,
    );
    // Vnitřní jemný highlight rim (metal bevel)
    canvas.drawCircle(
      center,
      radius * 0.88 - style.borderWidth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withOpacity(0.12),
    );

    // Rohové runové ornamenty
    if (style.cornerOrnaments > 0) {
      final ornamentPaint = Paint()
        ..color = style.borderColor.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      final positions = <Offset>[
        Offset(radius * 0.3, radius * 0.3),
        Offset(size.width - radius * 0.3, radius * 0.3),
        Offset(radius * 0.3, size.height - radius * 0.3),
        Offset(size.width - radius * 0.3, size.height - radius * 0.3),
      ];
      final count = style.cornerOrnaments == 1 ? 1 : style.cornerOrnaments;
      for (var i = 0; i < count && i < positions.length; i++) {
        final p = style.cornerOrnaments == 1 ? positions[3] : positions[i];
        canvas.drawLine(p - const Offset(3, 0), p + const Offset(3, 0), ornamentPaint);
        canvas.drawLine(p - const Offset(0, 3), p + const Offset(0, 3), ornamentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IconFrameBackdropPainter old) =>
      old.style != style || old.glowT != glowT;
}

// =============================================================================
// 6. POMOCNÉ FUNKCE PRO PROCEDURÁLNÍ PAINTERY
// =============================================================================

Paint _fillMetal(Color base) => Paint()
  ..shader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.lerp(base, Colors.white, 0.25)!, base, Color.lerp(base, Colors.black, 0.35)!],
    stops: const [0.0, 0.5, 1.0],
  ).createShader(const Rect.fromLTWH(0, 0, 24, 24));

Paint _rim(Color c, [double w = 1.1]) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..color = Color.lerp(c, Colors.white, 0.5)!;

Paint _glowPaint(Color c, double blur, double alpha) => Paint()
  ..color = c.withOpacity(alpha)
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

// =============================================================================
// 7. PROCEDURÁLNÍ IKONY — HERO CLASSY
// (viewBox konvence 24x24, těžké vyplněné siluety, glow podle identity)
// =============================================================================

/// Warrior: zkřížené sekery + těžký štít vzadu.
class _WarriorPainter extends CustomPainter {
  final Color tint;
  _WarriorPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9, _glowPaint(tint, 4, .3));

    // Štít vzadu (silueta)
    final shield = Path()
      ..moveTo(12, 3)
      ..lineTo(18, 6)
      ..cubicTo(18, 13, 15.5, 18, 12, 20)
      ..cubicTo(8.5, 18, 6, 13, 6, 6)
      ..close();
    canvas.drawPath(shield, _fillMetal(FantasyPalette.ironDark));
    canvas.drawPath(shield, _rim(FantasyPalette.oldGold, 1.0));

    // Sekera 1
    void axe(double angleDeg, Color bladeColor) {
      canvas.save();
      canvas.translate(12, 12);
      canvas.rotate(angleDeg * math.pi / 180);
      final handle = Rect.fromCenter(center: const Offset(0, 3), width: 1.6, height: 14);
      canvas.drawRRect(RRect.fromRectAndRadius(handle, const Radius.circular(1)), _fillMetal(const Color(0xFF4A3222)));
      final blade = Path()
        ..moveTo(-6, -6)
        ..quadraticBezierTo(-8, -2, -5, 1)
        ..lineTo(0, -1.5)
        ..quadraticBezierTo(-2, -5, -6, -6)
        ..close();
      canvas.drawPath(blade, _fillMetal(bladeColor));
      canvas.drawPath(blade, _rim(FantasyPalette.oldGold));
      canvas.restore();
    }

    axe(-35, const Color(0xFFB8BEC6));
    axe(35 + 180, const Color(0xFFB8BEC6));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Hunter: robustní recurve luk s napjatou tětivou a nasazeným šípem (kosočtvercový hrot,
/// dvouvaná opeření) - dřív jen tenká oblá čára s plochým trojúhelníkem, působilo dětsky.
class _HunterPainter extends CustomPainter {
  final Color tint;
  _HunterPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);

    canvas.drawCircle(const Offset(11, 12), 9, _glowPaint(tint, 5, .35));

    // Tělo luku - silná zakřivená silueta (ne jen linka), špičky se vyklánějí ven (recurve).
    final bow = Path()
      ..moveTo(6.4, 2.0)
      ..quadraticBezierTo(3.4, 7.2, 5.3, 12)
      ..quadraticBezierTo(3.4, 16.8, 6.4, 22.0)
      ..quadraticBezierTo(8.0, 21.2, 7.3, 19.2)
      ..quadraticBezierTo(5.5, 15.6, 7.0, 12)
      ..quadraticBezierTo(5.5, 8.4, 7.3, 4.8)
      ..quadraticBezierTo(8.0, 2.8, 6.4, 2.0)
      ..close();
    canvas.drawPath(bow, _fillMetal(const Color(0xFF6B4423)));
    canvas.drawPath(bow, _rim(tint, 1.0));

    // Tětiva svítí barvou třídy.
    canvas.drawLine(const Offset(6.6, 2.4), const Offset(6.6, 21.6), Paint()..strokeWidth = 0.9..color = tint.withOpacity(.9));

    // Kožený úchop uprostřed.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5.1, 10.6, 2.3, 2.8), const Radius.circular(1)), _fillMetal(const Color(0xFF3A2418)));

    // Napjatý šíp přes celou šířku ikony.
    canvas.drawLine(const Offset(2.2, 12), const Offset(20.5, 12), Paint()..strokeWidth = 1.3..color = const Color(0xFF8A6D3F));

    // Kosočtvercový broadhead s hřebenem uprostřed.
    final head = Path()..moveTo(21.6, 12)..lineTo(17.4, 9.6)..lineTo(18.6, 12)..lineTo(17.4, 14.4)..close();
    canvas.drawPath(head, _fillMetal(const Color(0xFFD7DBE0)));
    canvas.drawPath(head, _rim(Colors.white, .7));

    // Dvouvané opeření pod úhlem místo jednoho plochého trojúhelníku.
    final fl1 = Path()..moveTo(2.2, 12)..lineTo(5.4, 9.3)..lineTo(4.1, 12)..close();
    final fl2 = Path()..moveTo(2.2, 12)..lineTo(5.4, 14.7)..lineTo(4.1, 12)..close();
    canvas.drawPath(fl1, _fillMetal(tint));
    canvas.drawPath(fl2, _fillMetal(Color.lerp(tint, Colors.black, .3)!));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Priest: svatý medailon - ostré trojúhelníkové paprsky (ne tenké čáry), reliéfní kříž.
class _PriestPainter extends CustomPainter {
  final Color tint;
  _PriestPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    const c = Offset(12, 12);

    canvas.drawCircle(c, 9, _glowPaint(tint, 5, .5));

    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final dir = Offset(math.cos(a), math.sin(a));
      final perp = Offset(-dir.dy, dir.dx);
      final base = c + dir * 7.3;
      final tip = c + dir * 11.5;
      final ray = Path()
        ..moveTo(base.dx + perp.dx * 0.9, base.dy + perp.dy * 0.9)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(base.dx - perp.dx * 0.9, base.dy - perp.dy * 0.9)
        ..close();
      canvas.drawPath(ray, Paint()..color = tint.withOpacity(.85));
    }

    canvas.drawCircle(c, 7, _fillMetal(FantasyPalette.holyGold));
    canvas.drawCircle(c, 7, _rim(Colors.white, 1.2));
    canvas.drawCircle(c, 5.2, Paint()..style = PaintingStyle.stroke..strokeWidth = .6..color = Colors.white.withOpacity(.5));

    // Kříž - reliéfní (tmavý stín + světlý hřeben) místo ploché plné výplně.
    canvas.drawRect(Rect.fromCenter(center: c, width: 2.2, height: 9.5), Paint()..color = FantasyPalette.obsidian);
    canvas.drawRect(Rect.fromCenter(center: c, width: 9.5, height: 2.2), Paint()..color = FantasyPalette.obsidian);
    canvas.drawRect(Rect.fromCenter(center: c, width: 1.0, height: 8.5), Paint()..color = Colors.white.withOpacity(.18));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paladin: kite štít s vyříznutým křížem, zlatý glow - hybrid Warrior/Priest identita.
class _PaladinPainter extends CustomPainter {
  final Color tint;
  _PaladinPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    const c = Offset(12, 12);

    canvas.drawCircle(c, 8, _glowPaint(FantasyPalette.holyGold, 4, 0.4));

    final shield = Path()
      ..moveTo(12, 3)
      ..lineTo(19, 6)
      ..lineTo(19, 12)
      ..cubicTo(19, 17, 15.5, 20, 12, 22)
      ..cubicTo(8.5, 20, 5, 17, 5, 12)
      ..lineTo(5, 6)
      ..close();
    canvas.drawPath(shield, _fillMetal(FantasyPalette.oldGold));
    canvas.drawPath(shield, _rim(Colors.white, 1.2));

    canvas.drawRect(Rect.fromCenter(center: c, width: 2.0, height: 10), Paint()..color = FantasyPalette.obsidian);
    canvas.drawRect(Rect.fromCenter(center: c, width: 10, height: 2.0), Paint()..color = FantasyPalette.obsidian);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Demon Hunter: zkřížené dvojité čepele + démonické rohy nad nimi, fel-fialový glow.
class _DemonHunterPainter extends CustomPainter {
  final Color tint;
  _DemonHunterPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    const c = Offset(12, 13);

    canvas.drawCircle(c, 8, _glowPaint(FantasyPalette.shadowPurple, 4, 0.45));

    // Rohy
    final hornL = Path()..moveTo(9, 6)..quadraticBezierTo(6, 3, 7, 1)..quadraticBezierTo(9, 3, 10, 6)..close();
    final hornR = Path()..moveTo(15, 6)..quadraticBezierTo(18, 3, 17, 1)..quadraticBezierTo(15, 3, 14, 6)..close();
    canvas.drawPath(hornL, _fillMetal(const Color(0xFF3A2038)));
    canvas.drawPath(hornR, _fillMetal(const Color(0xFF3A2038)));

    // Dvojité čepele zkřížené
    void blade(double angleDeg) {
      canvas.save();
      canvas.translate(12, 13);
      canvas.rotate(angleDeg * math.pi / 180);
      final b = Path()
        ..moveTo(0, -9)
        ..lineTo(2.2, -2)
        ..lineTo(0.8, 9)
        ..lineTo(-0.8, 9)
        ..lineTo(-2.2, -2)
        ..close();
      canvas.drawPath(b, _fillMetal(FantasyPalette.shadowPurple));
      canvas.drawPath(b, _rim(const Color(0xFFE0C2FF), 1.0));
      canvas.restore();
    }

    blade(-30);
    blade(30);
    canvas.drawCircle(c, 1.3, Paint()..color = FantasyPalette.bloodRed);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Druid: strom života - kmen + koruna z listů, zelený glow.
class _DruidPainter extends CustomPainter {
  final Color tint;
  _DruidPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);

    canvas.drawCircle(const Offset(12, 10), 7, _glowPaint(FantasyPalette.natureGreen, 4, 0.4));

    final trunk = Path()..moveTo(11, 21)..lineTo(11.3, 13)..lineTo(12.7, 13)..lineTo(13, 21)..close();
    canvas.drawPath(trunk, _fillMetal(const Color(0xFF5A3A1E)));

    for (final o in [const Offset(12, 7), const Offset(8, 11), const Offset(16, 11), const Offset(12, 12)]) {
      canvas.drawCircle(o, 4.2, _fillMetal(FantasyPalette.natureGreen));
    }
    canvas.drawCircle(const Offset(12, 9), 1.1, Paint()..color = FantasyPalette.holyGold.withOpacity(0.9));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Death Knight: dominantní runová dvouruční čepel (zubatá záštita, svítící rytina) zaražená
/// před propadlou lebkou - dřív malý zdiagonálněný meč přes obyčejnou oválnou hlavu, teď má
/// meč skutečnou váhu a lebka ostřejší, hrozivější siluetu.
class _DeathKnightPainter extends CustomPainter {
  final Color tint;
  _DeathKnightPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);

    canvas.drawCircle(const Offset(12, 13), 9.5, _glowPaint(tint, 6, 0.5));

    // Lebka - hranatější silueta s bradou a stínovanými očními důlky, ne plochý ovál.
    final skull = Path()
      ..moveTo(12, 7.5)
      ..cubicTo(8.6, 7.5, 7, 10, 7, 12.6)
      ..cubicTo(7, 14.6, 7.8, 15.8, 8.6, 16.6)
      ..lineTo(9.2, 19.4)
      ..lineTo(10.4, 17.2)
      ..lineTo(11.1, 19.6)
      ..lineTo(12, 17.4)
      ..lineTo(12.9, 19.6)
      ..lineTo(13.6, 17.2)
      ..lineTo(14.8, 19.4)
      ..lineTo(15.4, 16.6)
      ..cubicTo(16.2, 15.8, 17, 14.6, 17, 12.6)
      ..cubicTo(17, 10, 15.4, 7.5, 12, 7.5)
      ..close();
    canvas.drawPath(skull, _fillMetal(const Color(0xFFDCDCDC)));
    canvas.drawPath(skull, _rim(Colors.black26, .6));
    // Stín pod čelní kostí pro objem.
    canvas.drawPath(
      Path()..moveTo(8.3, 10.2)..quadraticBezierTo(12, 8.8, 15.7, 10.2)..lineTo(15.2, 11.6)..quadraticBezierTo(12, 10.4, 8.8, 11.6)..close(),
      Paint()..color = Colors.black.withOpacity(.16),
    );
    // Svítící oční důlky.
    canvas.drawOval(const Rect.fromLTWH(8.6, 11.4, 3, 3.4), _glowPaint(tint, 2.5, .9));
    canvas.drawOval(const Rect.fromLTWH(12.4, 11.4, 3, 3.4), _glowPaint(tint, 2.5, .9));
    canvas.drawOval(const Rect.fromLTWH(9.1, 11.9, 2, 2.6), Paint()..color = tint);
    canvas.drawOval(const Rect.fromLTWH(12.9, 11.9, 2, 2.6), Paint()..color = tint);

    // Dominantní runová čepel - široká u záštity, zúžená ke hrotu, svislá přes celou ikonu.
    canvas.save();
    canvas.translate(12, 12.5);
    final blade = Path()..moveTo(-2.2, 6.5)..lineTo(-1.1, -10.5)..lineTo(0, -13)..lineTo(1.1, -10.5)..lineTo(2.2, 6.5)..close();
    canvas.drawPath(blade, _fillMetal(const Color(0xFFC9DCE6)));
    canvas.drawPath(blade, _rim(tint, 1.0));
    // Svítící runový žlábek uprostřed čepele.
    canvas.drawLine(const Offset(0, -11.5), const Offset(0, 5.5), Paint()..strokeWidth = .8..color = tint.withOpacity(.85));
    for (double y = -9; y < 4; y += 3.2) {
      canvas.drawLine(Offset(-0.6, y), Offset(0.6, y + 1.1), Paint()..strokeWidth = .5..color = tint.withOpacity(.6));
    }
    // Zubatá záštita.
    final guard = Path()
      ..moveTo(-5.5, 5.5)
      ..lineTo(-2.6, 7)
      ..lineTo(2.6, 7)
      ..lineTo(5.5, 5.5)
      ..lineTo(4.6, 8.2)
      ..lineTo(-4.6, 8.2)
      ..close();
    canvas.drawPath(guard, _fillMetal(const Color(0xFF4A3A2A)));
    canvas.drawPath(guard, _rim(tint, .8));
    // Omotaná rukojeť + hlavice s drahokamem.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-1.1, 8.2, 2.2, 4.6), const Radius.circular(1)), _fillMetal(const Color(0xFF2B2118)));
    canvas.drawCircle(const Offset(0, 13.6), 1.4, _fillMetal(tint));
    canvas.drawCircle(const Offset(0, 13.6), 1.4, _rim(Colors.white, .6));
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Necromancer: lebka + kostěné ornamenty, temná fialová magie.
class _NecromancerPainter extends CustomPainter {
  final Color tint;
  _NecromancerPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);

    canvas.drawCircle(const Offset(12, 12), 8.5, _glowPaint(FantasyPalette.shadowPurple, 6, 0.5));

    final skull = Path()..addOval(const Rect.fromLTWH(6.5, 6, 11, 10));
    canvas.drawPath(skull, _fillMetal(const Color(0xFFDCD4CC)));
    canvas.drawCircle(const Offset(9.5, 10.5), 1.4, Paint()..color = FantasyPalette.shadowPurple);
    canvas.drawCircle(const Offset(14.5, 10.5), 1.4, Paint()..color = FantasyPalette.shadowPurple);

    // Zkřížené kosti pod lebkou
    canvas.save();
    canvas.translate(12, 18);
    for (final angle in [-0.5, 0.5]) {
      canvas.save();
      canvas.rotate(angle);
      canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), Paint()..strokeWidth = 1.8..color = const Color(0xFFDCD4CC));
      canvas.drawCircle(const Offset(-6, 0), 1.4, Paint()..color = const Color(0xFFDCD4CC));
      canvas.drawCircle(const Offset(6, 0), 1.4, Paint()..color = const Color(0xFFDCD4CC));
      canvas.restore();
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Monk: pěst se zpevněnými klouby a omotávkou na zápěstí, obklopená vlnami chi energie.
class _MonkPainter extends CustomPainter {
  final Color tint;
  _MonkPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    const c = Offset(12, 12);

    canvas.drawCircle(c, 10, _glowPaint(tint, 6, .35));
    for (var r = 5.0; r <= 10; r += 2.5) {
      canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..color = tint.withOpacity((0.55 - r * 0.03).clamp(0.0, 1.0)));
    }

    final fist = Path()
      ..moveTo(8.2, 9.3)
      ..lineTo(15.8, 9.3)
      ..quadraticBezierTo(16.7, 9.3, 16.7, 11)
      ..lineTo(16.7, 14.2)
      ..quadraticBezierTo(16.7, 15.8, 15, 15.8)
      ..lineTo(9, 15.8)
      ..quadraticBezierTo(7.3, 15.8, 7.3, 14.2)
      ..lineTo(7.3, 11)
      ..quadraticBezierTo(7.3, 9.3, 8.2, 9.3)
      ..close();
    canvas.drawPath(fist, _fillMetal(const Color(0xFFC98A5A)));
    canvas.drawPath(fist, _rim(tint, 1.1));
    for (final x in [9.7, 12.0, 14.3]) {
      canvas.drawLine(Offset(x, 9.5), Offset(x, 15.6), Paint()..strokeWidth = .5..color = Colors.black26);
    }

    // Omotávka na zápěstí.
    canvas.drawRect(const Rect.fromLTWH(7.5, 16.4, 9, 2.4), Paint()..color = tint.withOpacity(.85));
    canvas.drawRect(const Rect.fromLTWH(7.5, 16.4, 9, 2.4), Paint()..style = PaintingStyle.stroke..strokeWidth = .5..color = Colors.white54);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Duelist: elegantní rapír s plnou košovou záštitou, zúženou čepelí a omotanou rukojetí -
/// dřív jen tenké čáry + prázdný oblouk, teď má skutečný objem a detail.
class _DuelistPainter extends CustomPainter {
  final Color tint;
  _DuelistPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.save();
    canvas.translate(12, 12);
    canvas.rotate(-math.pi / 4);

    canvas.drawCircle(const Offset(0, 0), 7, _glowPaint(tint, 4, .35));

    // Zúžená čepel s viditelným žlábkem (fuller).
    final blade = Path()..moveTo(-0.9, -11)..lineTo(0.9, -11)..lineTo(0.5, 4)..lineTo(-0.5, 4)..close();
    canvas.drawPath(blade, _fillMetal(const Color(0xFFE7E7E7)));
    canvas.drawLine(const Offset(0, -10.5), const Offset(0, 3.5), Paint()..strokeWidth = .4..color = Colors.black26);

    // Plná košová záštita (mísa), ne jen oblý obrys.
    final guard = Path()..addArc(const Rect.fromLTWH(-4, 2.5, 8, 7), 0, math.pi);
    canvas.drawPath(guard, _fillMetal(tint));
    canvas.drawPath(guard, _rim(Colors.white, .8));

    // Rukojeť omotaná drátem.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-0.9, 5.5, 1.8, 5), const Radius.circular(1)), _fillMetal(const Color(0xFF3A2418)));
    for (double y = 6.2; y < 10; y += 1.2) {
      canvas.drawLine(Offset(-0.9, y), Offset(0.9, y), Paint()..strokeWidth = .5..color = FantasyPalette.oldGold.withOpacity(.7));
    }

    // Hlavice.
    canvas.drawCircle(const Offset(0, 11), 1.3, _fillMetal(tint));
    canvas.drawCircle(const Offset(0, 11), 1.3, _rim(Colors.white, .6));
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mage: arkánová hůl s levitujícím krystalem, modrý glow.
class _MagePainter extends CustomPainter {
  final Color tint;
  _MagePainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    // Hůl
    canvas.drawLine(const Offset(9, 21), const Offset(15, 4), Paint()..strokeWidth = 1.6..color = const Color(0xFF5A3A1E));
    // Krystal na vrcholu hole
    canvas.drawCircle(const Offset(15.5, 4), 4.5, _glowPaint(FantasyPalette.frostBlue, 5, 0.6));
    final gem = Path()..moveTo(15.5, 1)..lineTo(18, 4)..lineTo(15.5, 7)..lineTo(13, 4)..close();
    canvas.drawPath(gem, _fillMetal(FantasyPalette.frostBlue));
    canvas.drawPath(gem, _rim(Colors.white, .8));
    // Arkánové jiskry okolo
    for (final o in [const Offset(6, 8), const Offset(9, 5), const Offset(5, 14)]) {
      canvas.drawCircle(o, 0.8, Paint()..color = FantasyPalette.frostBlue.withOpacity(.8));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// 8. PROCEDURÁLNÍ IKONY — HERNÍ SYSTÉMY
// =============================================================================

/// Doupě bosse: démonická lebka s rohy, žhnoucí červené oči.
class _BossLairPainter extends CustomPainter {
  final Color tint;
  _BossLairPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9, _glowPaint(FantasyPalette.bloodRed, 6, 0.55));

    // Rohy
    for (final side in [-1, 1]) {
      final horn = Path()
        ..moveTo(12 + side * 5.0, 8)
        ..quadraticBezierTo(12 + side * 9.0, 3, 12 + side * 6.0, 1)
        ..quadraticBezierTo(12 + side * 7.5, 5.5, 12 + side * 3.5, 8.5)
        ..close();
      canvas.drawPath(horn, _fillMetal(const Color(0xFF3A2418)));
    }
    // Lebka
    final skull = Path()..addOval(const Rect.fromLTWH(6, 7, 12, 10));
    canvas.drawPath(skull, _fillMetal(const Color(0xFF2B2118)));
    canvas.drawPath(skull, _rim(FantasyPalette.bloodRed, 1.0));
    canvas.drawCircle(const Offset(9.5, 12), 1.6, _glowPaint(const Color(0xFFFF3B3B), 3, 0.9));
    canvas.drawCircle(const Offset(14.5, 12), 1.6, _glowPaint(const Color(0xFFFF3B3B), 3, 0.9));
    canvas.drawCircle(const Offset(9.5, 12), 0.8, Paint()..color = const Color(0xFFFFD0D0));
    canvas.drawCircle(const Offset(14.5, 12), 0.8, Paint()..color = const Color(0xFFFFD0D0));
    // Tesáky
    final fangL = Path()..moveTo(9.5, 16)..lineTo(10.3, 19)..lineTo(11, 16);
    final fangR = Path()..moveTo(14.5, 16)..lineTo(13.7, 19)..lineTo(13, 16);
    canvas.drawPath(fangL, Paint()..color = const Color(0xFFE7E7E7));
    canvas.drawPath(fangR, Paint()..color = const Color(0xFFE7E7E7));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Družina: erb se zkříženými zbraněmi.
class _GuildPainter extends CustomPainter {
  final Color tint;
  _GuildPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final crest = Path()
      ..moveTo(12, 2)
      ..lineTo(19, 5)
      ..cubicTo(19, 12, 16, 18, 12, 21)
      ..cubicTo(8, 18, 5, 12, 5, 5)
      ..close();
    canvas.drawPath(crest, _fillMetal(const Color(0xFF2B2340)));
    canvas.drawPath(crest, _rim(FantasyPalette.oldGold, 1.4));

    canvas.save();
    canvas.clipPath(crest);
    canvas.translate(12, 12);
    for (final ang in [-40.0, 40.0]) {
      canvas.save();
      canvas.rotate(ang * math.pi / 180);
      canvas.drawLine(const Offset(0, -8), const Offset(0, 6), Paint()..strokeWidth = 1.6..color = const Color(0xFFE7E7E7));
      final blade = Path()..moveTo(-2.4, -8)..lineTo(2.4, -8)..lineTo(0, -11)..close();
      canvas.drawPath(blade, _fillMetal(const Color(0xFFB8BEC6)));
      canvas.restore();
    }
    canvas.restore();
    // Malá hvězda uprostřed erbu
    canvas.drawCircle(const Offset(12, 12), 1.6, Paint()..color = FantasyPalette.holyGold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Questy: svinutý pergamen s voskovou pečetí a vykřičníkem.
class _QuestsPainter extends CustomPainter {
  final Color tint;
  _QuestsPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final scroll = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 6, 16, 13), const Radius.circular(2));
    canvas.drawRRect(scroll, _fillMetal(FantasyPalette.parchment));
    canvas.drawRRect(scroll, _rim(const Color(0xFF6B4423), 1.0));
    for (final y in [10.0, 13.0, 16.0]) {
      canvas.drawLine(Offset(7, y), Offset(17, y), Paint()..strokeWidth = 0.8..color = const Color(0xFF6B4423).withOpacity(0.5));
    }
    // Vosková pečeť s vykřičníkem
    canvas.drawCircle(const Offset(17, 6), 4, _glowPaint(FantasyPalette.bloodRed, 3, 0.5));
    canvas.drawCircle(const Offset(17, 6), 3.4, _fillMetal(FantasyPalette.bloodRed));
    canvas.drawLine(const Offset(17, 4.2), const Offset(17, 6.3), Paint()..strokeWidth = 1.1..color = FantasyPalette.parchment);
    canvas.drawCircle(const Offset(17, 7.6), 0.5, Paint()..color = FantasyPalette.parchment);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kovárna: kovadlina, žhnoucí kov, jiskry.
class _ForgePainter extends CustomPainter {
  final Color tint;
  _ForgePainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    // Kovadlina
    final body = Path()
      ..moveTo(3, 12)
      ..lineTo(19, 12)
      ..lineTo(16, 15)
      ..lineTo(13, 15)
      ..lineTo(13, 19)
      ..lineTo(7, 19)
      ..lineTo(7, 15)
      ..lineTo(6, 15)
      ..close();
    canvas.drawPath(body, _fillMetal(const Color(0xFF2E2E33)));
    canvas.drawPath(body, _rim(const Color(0xFF8A8A8A), 1.0));
    canvas.drawRect(const Rect.fromLTWH(5, 20, 14, 1.6), _fillMetal(const Color(0xFF1A1410)));

    // Žhnoucí kov na kovadlině
    canvas.drawOval(const Rect.fromLTWH(9.5, 9.5, 5, 2.4), _glowPaint(const Color(0xFFFF7A1E), 4, 0.8));
    canvas.drawOval(const Rect.fromLTWH(10, 10, 4, 1.6), Paint()..color = const Color(0xFFFFD27A));

    // Jiskry
    final sparkColors = [const Color(0xFFFFD27A), const Color(0xFFFF9A3E)];
    final rnd = [const Offset(15, 6), const Offset(17, 9), const Offset(13, 5), const Offset(7, 7)];
    for (var i = 0; i < rnd.length; i++) {
      canvas.drawCircle(rnd[i], 0.7, Paint()..color = sparkColors[i % 2]);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Alchymie: mystická lahvička bublající fialovou magií, runy okolo.
class _AlchemyPainter extends CustomPainter {
  final Color tint;
  _AlchemyPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 14), 7, _glowPaint(FantasyPalette.shadowPurple, 5, 0.5));

    final flask = Path()
      ..moveTo(10, 3)
      ..lineTo(14, 3)
      ..lineTo(14, 8)
      ..lineTo(18, 16)
      ..cubicTo(19, 19, 17, 21, 14, 21)
      ..lineTo(10, 21)
      ..cubicTo(7, 21, 5, 19, 6, 16)
      ..lineTo(10, 8)
      ..close();
    final flaskPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [FantasyPalette.shadowPurple.withOpacity(.9), FantasyPalette.obsidian],
      ).createShader(const Rect.fromLTWH(0, 0, 24, 24));
    canvas.drawPath(flask, flaskPaint);
    canvas.drawPath(flask, _rim(FantasyPalette.shadowPurple, 1.2));
    canvas.drawRect(const Rect.fromLTWH(9.5, 2, 5, 2), _fillMetal(const Color(0xFFB8BEC6)));

    for (final o in [const Offset(10.5, 17), const Offset(13.5, 15), const Offset(12, 19)]) {
      canvas.drawCircle(o, 0.9, Paint()..color = Colors.white.withOpacity(0.7));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tržiště: měšec zlata s mincemi.
class _MarketPainter extends CustomPainter {
  final Color tint;
  _MarketPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final pouch = Path()
      ..moveTo(9, 9)
      ..cubicTo(6, 11, 5, 15, 6.5, 18)
      ..cubicTo(7.5, 20.5, 16.5, 20.5, 17.5, 18)
      ..cubicTo(19, 15, 18, 11, 15, 9)
      ..close();
    canvas.drawPath(pouch, _fillMetal(const Color(0xFF7A4E2D)));
    canvas.drawPath(pouch, _rim(FantasyPalette.oldGold, 1.0));
    canvas.drawLine(const Offset(9, 9), const Offset(15, 9), Paint()..strokeWidth = 1.6..color = FantasyPalette.oldGold);

    for (final o in [const Offset(10, 6), const Offset(13.5, 5.5), const Offset(12, 4)]) {
      canvas.drawCircle(o, 1.6, _fillMetal(FantasyPalette.oldGold));
      canvas.drawCircle(o, 1.6, _rim(Colors.white, .6));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Runový čaroděj: severský monolit s runami, modrá ledová magie.
class _RuneWizardPainter extends CustomPainter {
  final Color tint;
  _RuneWizardPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9, _glowPaint(FantasyPalette.frostBlue, 6, 0.45));

    final monolith = Path()..moveTo(9, 21)..lineTo(9, 6)..lineTo(12, 2)..lineTo(15, 6)..lineTo(15, 21)..close();
    canvas.drawPath(monolith, _fillMetal(const Color(0xFF3A424C)));
    canvas.drawPath(monolith, _rim(FantasyPalette.frostBlue, 1.1));

    // Runy vyryté (jednoduché nordic-like tvary)
    final runePaint = Paint()..strokeWidth = 1.0..color = FantasyPalette.frostBlue..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(10.5, 9), const Offset(13.5, 9), runePaint);
    canvas.drawLine(const Offset(12, 9), const Offset(12, 13), runePaint);
    canvas.drawLine(const Offset(10.5, 13), const Offset(13.5, 11), runePaint);
    canvas.drawLine(const Offset(10.5, 17), const Offset(13.5, 17), runePaint);
    canvas.drawLine(const Offset(10.5, 15), const Offset(13.5, 19), runePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Inventář: truhla dobrodruha s kovovými přezkami.
class _InventoryPainter extends CustomPainter {
  final Color tint;
  _InventoryPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final lid = Path()..moveTo(4, 11)..quadraticBezierTo(12, 5, 20, 11)..lineTo(20, 13)..lineTo(4, 13)..close();
    canvas.drawPath(lid, _fillMetal(const Color(0xFF6B4423)));
    canvas.drawPath(lid, _rim(FantasyPalette.oldGold, 1.0));
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 13, 16, 7), const Radius.circular(1.5));
    canvas.drawRRect(body, _fillMetal(const Color(0xFF5A3A1E)));
    canvas.drawRRect(body, _rim(FantasyPalette.oldGold, 1.0));
    // Přezky
    for (final x in [7.0, 17.0]) {
      canvas.drawRect(Rect.fromCenter(center: Offset(x, 13), width: 2.4, height: 4), _fillMetal(FantasyPalette.oldGold));
    }
    // Zámek
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10.5, 14.5, 3, 3), const Radius.circular(1)), _fillMetal(FantasyPalette.oldGold));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Věž: gotická temná věž, fialový dungeon glow.
class _TowerPainter extends CustomPainter {
  final Color tint;
  _TowerPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9, _glowPaint(FantasyPalette.shadowPurple, 5, 0.4));

    final tower = Path()
      ..moveTo(9, 21)
      ..lineTo(9, 10)
      ..lineTo(7.5, 10)
      ..lineTo(7.5, 7)
      ..lineTo(9.5, 7)
      ..lineTo(9.5, 5)
      ..lineTo(11, 5)
      ..lineTo(12, 2)
      ..lineTo(13, 5)
      ..lineTo(14.5, 5)
      ..lineTo(14.5, 7)
      ..lineTo(16.5, 7)
      ..lineTo(16.5, 10)
      ..lineTo(15, 10)
      ..lineTo(15, 21)
      ..close();
    canvas.drawPath(tower, _fillMetal(const Color(0xFF2B2340)));
    canvas.drawPath(tower, _rim(FantasyPalette.shadowPurple, 1.0));
    canvas.drawCircle(const Offset(12, 14), 1.6, _glowPaint(FantasyPalette.shadowPurple, 3, 0.9));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Trhlina Osudu: rozeklaný fialový portál, spirálovité arkánové víry.
class _RiftPainter extends CustomPainter {
  final Color tint;
  _RiftPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9.5, _glowPaint(FantasyPalette.shadowPurple, 6, 0.6));

    final rift = Path()
      ..moveTo(12, 3)
      ..cubicTo(17, 5, 19, 9, 16, 13)
      ..cubicTo(19, 16, 16, 20, 12, 21)
      ..cubicTo(8, 20, 5, 16, 8, 13)
      ..cubicTo(5, 9, 7, 5, 12, 3)
      ..close();
    canvas.drawPath(rift, _fillMetal(const Color(0xFF1A1030)));
    canvas.drawPath(rift, _rim(FantasyPalette.shadowPurple, 1.2));

    // Vnitřní vír
    canvas.drawOval(const Rect.fromLTWH(9, 9, 6, 7), _glowPaint(const Color(0xFFB794F6), 4, 0.8));
    canvas.drawOval(const Rect.fromLTWH(10, 10.5, 4, 4.5), Paint()..color = const Color(0xFFB794F6).withOpacity(.7));

    for (final o in [const Offset(6, 8), const Offset(18, 9), const Offset(7, 17)]) {
      canvas.drawCircle(o, 0.8, Paint()..color = FantasyPalette.shadowPurple.withOpacity(.9));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// =============================================================================

class _WeaponSlotPainter extends CustomPainter {
  final Color tint;
  _WeaponSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.save();
    canvas.translate(12, 12);
    canvas.rotate(-math.pi / 4);
    final blade = Path()..moveTo(-1.6, -10)..lineTo(1.6, -10)..lineTo(1.2, 6)..lineTo(0, 9)..lineTo(-1.2, 6)..close();
    canvas.drawPath(blade, _fillMetal(const Color(0xFFB8BEC6)));
    canvas.drawPath(blade, _rim(FantasyPalette.oldGold));
    canvas.drawLine(const Offset(-3.5, 6), const Offset(3.5, 6), Paint()..strokeWidth = 1.6..color = FantasyPalette.oldGold);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArmorSlotPainter extends CustomPainter {
  final Color tint;
  _ArmorSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final chest = Path()
      ..moveTo(12, 3)
      ..lineTo(18, 6)
      ..lineTo(18, 12)
      ..cubicTo(18, 17, 15, 20, 12, 21)
      ..cubicTo(9, 20, 6, 17, 6, 12)
      ..lineTo(6, 6)
      ..close();
    canvas.drawPath(chest, _fillMetal(const Color(0xFF5A626C)));
    canvas.drawPath(chest, _rim(FantasyPalette.oldGold));
    canvas.drawLine(const Offset(12, 6), const Offset(12, 18), Paint()..strokeWidth = 0.8..color = Colors.black.withOpacity(.4));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Ramenní chrániče (pauldrony) - dřív sdílely ikonu se zbrojí (_ArmorSlotPainter), takže
// u 8-kusových hardcore/předpeklí/peklo setů vypadaly Zbroj a Ramenní chrániče identicky.
// Vlastní silueta: dva symetrické zahrocené pláty s mezerou pro krk uprostřed.
class _ShoulderSlotPainter extends CustomPainter {
  final Color tint;
  _ShoulderSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final left = Path()
      ..moveTo(3, 9)
      ..cubicTo(3, 5.5, 6, 3.5, 9.5, 4)
      ..lineTo(10.5, 9)
      ..cubicTo(10.5, 12.5, 8, 14.5, 5, 14.5)
      ..cubicTo(3.5, 14.5, 3, 12, 3, 9)
      ..close();
    final right = Path()
      ..moveTo(21, 9)
      ..cubicTo(21, 5.5, 18, 3.5, 14.5, 4)
      ..lineTo(13.5, 9)
      ..cubicTo(13.5, 12.5, 16, 14.5, 19, 14.5)
      ..cubicTo(20.5, 14.5, 21, 12, 21, 9)
      ..close();
    canvas.drawPath(left, _fillMetal(const Color(0xFF5A626C)));
    canvas.drawPath(left, _rim(FantasyPalette.oldGold));
    canvas.drawPath(right, _fillMetal(const Color(0xFF5A626C)));
    canvas.drawPath(right, _rim(FantasyPalette.oldGold));
    canvas.drawPath(Path()..moveTo(6.2, 4.2)..lineTo(7.2, 1)..lineTo(8.2, 4.4)..close(), _fillMetal(FantasyPalette.oldGold));
    canvas.drawPath(Path()..moveTo(17.8, 4.2)..lineTo(16.8, 1)..lineTo(15.8, 4.4)..close(), _fillMetal(FantasyPalette.oldGold));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HelmetSlotPainter extends CustomPainter {
  final Color tint;
  _HelmetSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final helm = Path()..moveTo(6, 15)..cubicTo(6, 6, 18, 6, 18, 15)..lineTo(15, 15)..lineTo(15, 12)..lineTo(9, 12)..lineTo(9, 15)..close();
    canvas.drawPath(helm, _fillMetal(const Color(0xFFB8BEC6)));
    canvas.drawPath(helm, _rim(FantasyPalette.oldGold));
    canvas.drawRect(const Rect.fromLTWH(11, 4, 2, 4), _fillMetal(FantasyPalette.bloodRed));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlovesSlotPainter extends CustomPainter {
  final Color tint;
  _GlovesSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(7, 10, 10, 9), const Radius.circular(3)), _fillMetal(const Color(0xFF7A4E2D)));
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(7.5 + i * 2.3, 4, 1.8, 7), const Radius.circular(1)), _fillMetal(const Color(0xFF7A4E2D)));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BootsSlotPainter extends CustomPainter {
  final Color tint;
  _BootsSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final boot = Path()..moveTo(9, 3)..lineTo(15, 3)..lineTo(15, 14)..lineTo(20, 17)..lineTo(20, 21)..lineTo(6, 21)..lineTo(6, 15)..lineTo(9, 14)..close();
    canvas.drawPath(boot, _fillMetal(const Color(0xFF3A2418)));
    canvas.drawPath(boot, _rim(FantasyPalette.oldGold));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BeltSlotPainter extends CustomPainter {
  final Color tint;
  _BeltSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final strap = Path()..moveTo(3, 10)..lineTo(21, 10)..lineTo(21, 15)..lineTo(3, 15)..close();
    canvas.drawPath(strap, _fillMetal(const Color(0xFF3A2418)));
    canvas.drawPath(strap, _rim(FantasyPalette.oldGold));
    final buckle = Path()..moveTo(9.5, 8.5)..lineTo(14.5, 8.5)..lineTo(14.5, 16.5)..lineTo(9.5, 16.5)..close();
    canvas.drawPath(buckle, _fillMetal(FantasyPalette.oldGold));
    canvas.drawPath(buckle, _rim(const Color(0xFF7A5A20), 1.0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CloakSlotPainter extends CustomPainter {
  final Color tint;
  _CloakSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final cloak = Path()
      ..moveTo(12, 3)
      ..lineTo(19, 6)
      ..lineTo(17, 21)
      ..lineTo(12, 18)
      ..lineTo(7, 21)
      ..lineTo(5, 6)
      ..close();
    canvas.drawPath(cloak, _fillMetal(const Color(0xFF3A1E4A)));
    canvas.drawPath(cloak, _rim(FantasyPalette.shadowPurple));
    canvas.drawCircle(const Offset(12, 5), 1.4, _glowPaint(FantasyPalette.oldGold, 2, 0.8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingSlotPainter extends CustomPainter {
  final Color tint;
  _RingSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 14), 6.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 3.2..color = FantasyPalette.oldGold);
    canvas.drawCircle(const Offset(12, 6.5), 2.6, _glowPaint(FantasyPalette.frostBlue, 3, 0.7));
    canvas.drawCircle(const Offset(12, 6.5), 2.2, _fillMetal(FantasyPalette.frostBlue));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AmuletSlotPainter extends CustomPainter {
  final Color tint;
  _AmuletSlotPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawArc(const Rect.fromLTWH(6, 2, 12, 10), 0, math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = FantasyPalette.oldGold);
    final gem = Path()..moveTo(12, 12)..lineTo(16, 16)..lineTo(12, 22)..lineTo(8, 16)..close();
    canvas.drawPath(gem, _glowPaint(FantasyPalette.shadowPurple, 4, 0.6));
    canvas.drawPath(gem, _fillMetal(FantasyPalette.shadowPurple));
    canvas.drawPath(gem, _rim(Colors.white, .8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendaryMarkPainter extends CustomPainter {
  final Color tint;
  _LegendaryMarkPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9, _glowPaint(const Color(0xFFFF8000), 6, 0.6));
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final r = i.isEven ? 8.0 : 3.5;
      final p = Offset(12 + r * math.cos(a - math.pi / 2), 12 + r * math.sin(a - math.pi / 2));
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(star, _fillMetal(const Color(0xFFFF8000)));
    canvas.drawPath(star, _rim(Colors.white, .8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SetMarkPainter extends CustomPainter {
  final Color tint;
  _SetMarkPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(9, 12), 5.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..color = const Color(0xFF00CC66));
    canvas.drawCircle(const Offset(15, 12), 5.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..color = const Color(0xFF00CC66));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PotionPainter extends CustomPainter {
  final Color tint;
  final Color liquid;
  _PotionPainter(this.tint, this.liquid);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final flask = Path()
      ..moveTo(10, 2)
      ..lineTo(14, 2)
      ..lineTo(14, 7)
      ..cubicTo(17, 10, 18, 14, 17, 17)
      ..cubicTo(16, 21, 8, 21, 7, 17)
      ..cubicTo(6, 14, 7, 10, 10, 7)
      ..close();
    canvas.drawCircle(const Offset(12, 15), 6, _glowPaint(liquid, 4, 0.5));
    canvas.drawPath(flask, _fillMetal(const Color(0xFFDCEAF0).withOpacity(.9)));
    canvas.drawPath(flask, _rim(const Color(0xFF6B5D52), 1.0));
    canvas.save();
    canvas.clipPath(flask);
    canvas.drawRect(const Rect.fromLTWH(5, 12, 14, 10), _fillMetal(liquid));
    canvas.restore();
    canvas.drawRect(const Rect.fromLTWH(9.5, 1, 5, 2), _fillMetal(const Color(0xFF6B4423)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MaterialIngotPainter extends CustomPainter {
  final Color tint;
  final Color base;
  _MaterialIngotPainter(this.tint, this.base);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final ingot = Path()..moveTo(5, 15)..lineTo(7, 9)..lineTo(17, 9)..lineTo(19, 15)..lineTo(17, 18)..lineTo(7, 18)..close();
    canvas.drawPath(ingot, _fillMetal(base));
    canvas.drawPath(ingot, _rim(Colors.white, .8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MaterialHidePainter extends CustomPainter {
  final Color tint;
  final Color base;
  _MaterialHidePainter(this.tint, this.base);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final hide = Path()..moveTo(12, 3)..cubicTo(17, 4, 20, 9, 18, 14)..cubicTo(20, 17, 17, 21, 13, 20)..cubicTo(9, 22, 4, 18, 6, 14)..cubicTo(3, 10, 7, 4, 12, 3)..close();
    canvas.drawPath(hide, _fillMetal(base));
    canvas.drawPath(hide, _rim(Colors.white, .6));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MaterialLogPainter extends CustomPainter {
  final Color tint;
  final Color base;
  _MaterialLogPainter(this.tint, this.base);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 9, 16, 8), const Radius.circular(3)), _fillMetal(base));
    canvas.drawCircle(const Offset(6, 13), 3.2, _fillMetal(const Color(0xFFD8B58C)));
    canvas.drawCircle(const Offset(6, 13), 1.4, _fillMetal(base));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparkleDustPainter extends CustomPainter {
  final Color tint;
  _SparkleDustPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    Path star(Offset c, double r) {
      final p = Path();
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2;
        final tip = c + Offset(math.cos(a), math.sin(a)) * r;
        final side1 = c + Offset(math.cos(a + math.pi / 4), math.sin(a + math.pi / 4)) * (r * 0.35);
        i == 0 ? p.moveTo(tip.dx, tip.dy) : p.lineTo(tip.dx, tip.dy);
        p.lineTo(side1.dx, side1.dy);
      }
      p.close();
      return p;
    }

    canvas.drawPath(star(const Offset(12, 10), 7), _glowPaint(FantasyPalette.shadowPurple, 4, 0.6));
    canvas.drawPath(star(const Offset(12, 10), 6.5), _fillMetal(FantasyPalette.shadowPurple));
    canvas.drawPath(star(const Offset(6, 17), 3), _fillMetal(FantasyPalette.frostBlue));
    canvas.drawPath(star(const Offset(18, 16), 2.5), _fillMetal(FantasyPalette.holyGold));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EssenceOrbPainter extends CustomPainter {
  final Color tint;
  _EssenceOrbPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9, _glowPaint(const Color(0xFFFF8000), 6, 0.6));
    canvas.drawCircle(const Offset(12, 12), 7, _fillMetal(const Color(0xFFFFB84D)));
    canvas.drawCircle(const Offset(10, 10), 2, Paint()..color = Colors.white.withOpacity(.6));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RuneStonePainter extends CustomPainter {
  final Color tint;
  final Color glow;
  _RuneStonePainter(this.tint, this.glow);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 8, _glowPaint(glow, 4, 0.5));
    final stone = Path()..moveTo(7, 21)..lineTo(7, 7)..lineTo(12, 3)..lineTo(17, 7)..lineTo(17, 21)..close();
    canvas.drawPath(stone, _fillMetal(const Color(0xFF3A3238)));
    canvas.drawPath(stone, _rim(glow, 1.0));
    canvas.drawLine(const Offset(9, 11), const Offset(15, 11), Paint()..strokeWidth = 1.0..color = glow);
    canvas.drawLine(const Offset(9, 15), const Offset(12, 12), Paint()..strokeWidth = 1.0..color = glow);
    canvas.drawLine(const Offset(15, 15), const Offset(12, 12), Paint()..strokeWidth = 1.0..color = glow);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoinPainter extends CustomPainter {
  final Color tint;
  final Color base;
  _CoinPainter(this.tint, this.base);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9, _fillMetal(base));
    canvas.drawCircle(const Offset(12, 12), 9, _rim(Colors.white, 1.0));
    canvas.drawCircle(const Offset(12, 12), 6.2, Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = Colors.black.withOpacity(.35));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GemPainter extends CustomPainter {
  final Color tint;
  final Color base;
  _GemPainter(this.tint, this.base);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9, _glowPaint(base, 5, 0.55));
    final gem = Path()..moveTo(4, 9)..lineTo(12, 3)..lineTo(20, 9)..lineTo(12, 21)..close();
    canvas.drawPath(gem, _fillMetal(base));
    canvas.drawPath(gem, _rim(Colors.white, .8));
    canvas.drawLine(const Offset(4, 9), const Offset(20, 9), Paint()..strokeWidth = .8..color = Colors.white.withOpacity(.4));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeartPainter extends CustomPainter {
  final Color tint;
  _HeartPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final heart = Path()
      ..moveTo(12, 20)
      ..cubicTo(4, 14, 4, 8, 9, 6)
      ..cubicTo(11, 5, 12, 7, 12, 8)
      ..cubicTo(12, 7, 13, 5, 15, 6)
      ..cubicTo(20, 8, 20, 14, 12, 20)
      ..close();
    canvas.drawPath(heart, _glowPaint(FantasyPalette.bloodRed, 3, 0.5));
    canvas.drawPath(heart, _fillMetal(FantasyPalette.bloodRed));
    canvas.drawPath(heart, _rim(Colors.white, .6));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BoltPainter extends CustomPainter {
  final Color tint;
  _BoltPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final bolt = Path()..moveTo(13, 2)..lineTo(4, 14)..lineTo(10, 14)..lineTo(9, 22)..lineTo(19, 10)..lineTo(13, 10)..close();
    canvas.drawPath(bolt, _glowPaint(FantasyPalette.frostBlue, 3, 0.6));
    canvas.drawPath(bolt, _fillMetal(FantasyPalette.frostBlue));
    canvas.drawPath(bolt, _rim(Colors.white, .6));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShieldPainter extends CustomPainter {
  final Color tint;
  _ShieldPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final shield = Path()..moveTo(12, 2)..lineTo(19, 5)..cubicTo(19, 13, 16, 19, 12, 21)..cubicTo(8, 19, 5, 13, 5, 5)..close();
    canvas.drawPath(shield, _fillMetal(const Color(0xFF6B5D52)));
    canvas.drawPath(shield, _rim(FantasyPalette.oldGold, 1.2));
    canvas.drawCircle(const Offset(12, 11), 2.2, _fillMetal(FantasyPalette.oldGold));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SwordGlyphPainter extends CustomPainter {
  final Color tint;
  _SwordGlyphPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.save();
    canvas.translate(12, 12);
    canvas.rotate(-math.pi / 4);
    final blade = Path()..moveTo(-1.5, -10)..lineTo(1.5, -10)..lineTo(1.1, 6)..lineTo(0, 9)..lineTo(-1.1, 6)..close();
    canvas.drawPath(blade, _fillMetal(const Color(0xFFB8BEC6)));
    canvas.drawPath(blade, _rim(FantasyPalette.oldGold));
    canvas.drawLine(const Offset(-3, 6), const Offset(3, 6), Paint()..strokeWidth = 1.4..color = FantasyPalette.oldGold);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScrollPainter extends CustomPainter {
  final Color tint;
  _ScrollPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 6, 16, 13), const Radius.circular(2)), _fillMetal(FantasyPalette.parchment));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 6, 16, 13), const Radius.circular(2)), _rim(const Color(0xFF6B4423), 1.0));
    for (final y in [10.0, 13.0, 16.0]) {
      canvas.drawLine(Offset(7, y), Offset(17, y), Paint()..strokeWidth = .8..color = const Color(0xFF6B4423).withOpacity(.5));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExclaimSealPainter extends CustomPainter {
  final Color tint;
  _ExclaimSealPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    canvas.drawCircle(const Offset(12, 12), 9, _glowPaint(FantasyPalette.bloodRed, 5, 0.55));
    canvas.drawCircle(const Offset(12, 12), 8, _fillMetal(FantasyPalette.bloodRed));
    canvas.drawCircle(const Offset(12, 12), 8, _rim(FantasyPalette.oldGold, 1.2));
    canvas.drawLine(const Offset(12, 7), const Offset(12, 14), Paint()..strokeWidth = 2.2..strokeCap = StrokeCap.round..color = FantasyPalette.parchment);
    canvas.drawCircle(const Offset(12, 17), 1.1, Paint()..color = FantasyPalette.parchment);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChestPainter extends CustomPainter {
  final Color tint;
  _ChestPainter(this.tint);
  @override
  void paint(Canvas canvas, Size s) {
    final sc = s.width / 24;
    canvas.save();
    canvas.scale(sc);
    final lid = Path()..moveTo(4, 11)..quadraticBezierTo(12, 5, 20, 11)..lineTo(20, 13)..lineTo(4, 13)..close();
    canvas.drawPath(lid, _fillMetal(const Color(0xFF6B4423)));
    canvas.drawPath(lid, _rim(FantasyPalette.oldGold, 1.0));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 13, 16, 7), const Radius.circular(1.5)), _fillMetal(const Color(0xFF5A3A1E)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10.5, 14.5, 3, 3), const Radius.circular(1)), _fillMetal(FantasyPalette.oldGold));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


/// Šestihranný odznak (jako vyřezávaná pečeť) používaný v dlaždicích na
/// domovské obrazovce (HubScreen) místo kulatých emoji ikon.
/// "Živý" portrét třídy - animovaný obal kolem statického Image.asset, ať artwork nepůsobí jako
/// plochá fotka. Dva režimy podle toho, KDE se portrét zobrazuje (viz rozhodnutí v konverzaci):
/// - `subtle` (v boji) - jen skoro podprahové "dýchání" (scale ±0.0075), NIC jiného. Combat
///   portrét soutěží o pozornost s HP/dmg čísly/ikonami spellů, takže musí zůstat v pozadí.
/// - `full` (výběr povolání, Profil - tam, kde je portrét TA hlavní věc na obrazovce a nic jiného
///   o pozornost nesoutěží) - znatelnější dýchání + pomalý Ken Burns posun/zoom + jemné
///   vzhůru stoupající ambientní tečky v barvě třídy (accent).
enum PortraitLifeMode { subtle, full }

class LivingPortrait extends StatefulWidget {
  final String assetPath;
  final Color accent;
  final PortraitLifeMode mode;
  final BorderRadius borderRadius;
  const LivingPortrait({super.key, required this.assetPath, required this.accent, required this.mode, this.borderRadius = BorderRadius.zero});

  @override
  State<LivingPortrait> createState() => _LivingPortraitState();
}

class _AmbientMote {
  final double dx; // -1..1, vodorovná pozice (Alignment)
  final double delay; // 0..1, fázový posun ať tečky nestoupají všechny najednou
  const _AmbientMote(this.dx, this.delay);
}

class _LivingPortraitState extends State<LivingPortrait> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_AmbientMote> _motes;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Duration(seconds: widget.mode == PortraitLifeMode.full ? 10 : 5))..repeat();
    final rnd = Random(widget.assetPath.hashCode);
    _motes = widget.mode == PortraitLifeMode.full ? List.generate(5, (i) => _AmbientMote(rnd.nextDouble() * 1.6 - 0.8, rnd.nextDouble())) : const [];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        double scale;
        Offset pan = Offset.zero;
        if (widget.mode == PortraitLifeMode.subtle) {
          scale = 1.0 + sin(t * 2 * pi) * 0.0075;
        } else {
          scale = 1.06 + sin(t * 2 * pi) * 0.02;
          pan = Offset(sin(t * 2 * pi * 0.5) * 6, cos(t * 2 * pi * 0.4) * 4);
        }
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: pan,
                child: Transform.scale(scale: scale, child: Image.asset(widget.assetPath, fit: BoxFit.cover)),
              ),
              for (final m in _motes) _mote(m, t),
            ],
          ),
        );
      },
    );
  }

  Widget _mote(_AmbientMote m, double t) {
    final localT = (t + m.delay) % 1.0;
    final y = 1.0 - localT * 2; // 1 (dole) -> -1 (nahoře) - stoupá směrem vzhůru portrétem
    final opacity = sin(localT * pi).clamp(0.0, 1.0); // fade in na startu, fade out na konci dráhy
    return Align(
      alignment: Alignment(m.dx, y),
      child: Opacity(
        opacity: opacity * 0.65,
        child: Container(
          width: 4, height: 4,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accent, boxShadow: [BoxShadow(color: widget.accent.withOpacity(.85), blurRadius: 5)]),
        ),
      ),
    );
  }
}


class HexBadgePainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  const HexBadgePainter({required this.fill, required this.stroke});

  Path _hex(Size size, double inset) {
    // Vrcholy odpovídají poměru 31,2 / 58,16 / 58,43 / 31,66 / 4,43 / 4,16
    // z reference view-boxu 62x68, mírně zúžené o [inset] px.
    const vb = Size(62, 68);
    final pts = <Offset>[
      const Offset(31, 2), const Offset(58, 16), const Offset(58, 43),
      const Offset(31, 66), const Offset(4, 43), const Offset(4, 16),
    ];
    final cx = vb.width / 2, cy = vb.height / 2;
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final dx = (p.dx - cx), dy = (p.dy - cy);
      final scale = inset == 0 ? 1.0 : 1 - (inset / 30);
      final sx = (cx + dx * scale) / vb.width * size.width;
      final sy = (cy + dy * scale) / vb.height * size.height;
      if (i == 0) {
        path.moveTo(sx, sy);
      } else {
        path.lineTo(sx, sy);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _hex(size, 0);
    canvas.drawPath(outer, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(outer, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 1.6);
    final inner = _hex(size, 4);
    canvas.drawPath(inner, Paint()..color = stroke.withOpacity(.5)..style = PaintingStyle.stroke..strokeWidth = .8);
  }

  @override
  bool shouldRepaint(covariant HexBadgePainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.stroke != stroke;
}

/// Jedna dlaždice na domovské obrazovce (HubScreen): hex odznak + ikona +
/// popisek + volitelný červený počítadlo-badge (např. počet nových questů).
// ===== CELEBRATION OVERLAY — power fantasy flash pro level up / milestone momenty =====
// Obaluje CELOU appku (viz main()), takže funguje bez ohledu na to, na jaké obrazovce
// Rotující paprsky za "velkým" celebration popupem (level up / achievement / atd.) - dodává
// tomu pocit dramatického momentu, ne jen tichou kartičku. Čistě procedurální (žádné assety).
class _CelebrationBurstPainter extends CustomPainter {
  final double t; // 0..1 animační fáze (řízeno _controller)
  final Color color;
  _CelebrationBurstPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    // Jemná pulzující záře v pozadí.
    canvas.drawCircle(center, maxR, Paint()..shader = RadialGradient(colors: [color.withOpacity(.30 * t), color.withOpacity(0)]).createShader(Rect.fromCircle(center: center, radius: maxR)));
    // 12 rotujících paprsků.
    const rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * pi + t * pi * 0.6;
      final path = Path();
      final innerR = maxR * 0.35;
      final outerR = maxR * (0.75 + 0.15 * t);
      final halfWidth = 0.09;
      path.moveTo(center.dx + cos(angle - halfWidth) * innerR, center.dy + sin(angle - halfWidth) * innerR);
      path.lineTo(center.dx + cos(angle) * outerR, center.dy + sin(angle) * outerR);
      path.lineTo(center.dx + cos(angle + halfWidth) * innerR, center.dy + sin(angle + halfWidth) * innerR);
      path.close();
      canvas.drawPath(path, Paint()..color = color.withOpacity(.22 * t));
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationBurstPainter old) => old.t != t || old.color != color;
}

// zrovna hráč je. Sleduje GameState.celebrationTitle - jakmile se objeví, ukáže krátkou
// animovanou kartu (scale-in + fade), po chvíli sama zmizí a zavolá dismissCelebration().
class CelebrationOverlayHost extends StatefulWidget {
  final Widget child;
  const CelebrationOverlayHost({super.key, required this.child});
  @override
  State<CelebrationOverlayHost> createState() => _CelebrationOverlayHostState();
}

class _CelebrationOverlayHostState extends State<CelebrationOverlayHost> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final AnimationController _burstController;
  String? _shownTitle;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _burstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  }

  @override
  void dispose() {
    _controller.dispose();
    _burstController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _handleNewCelebration(GameState state) {
    if (state.celebrationTitle == null || state.celebrationTitle == _shownTitle) return;
    _shownTitle = state.celebrationTitle;
    _controller.forward(from: 0);
    _burstController.forward(from: 0);
    HapticFeedback.mediumImpact();
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _controller.reverse().then((_) {
        _shownTitle = null;
        state.dismissCelebration();
      });
    });
  }

  bool _maTusDialogShowing = false;
  // Ma-Túš (mentor Runového Čaroděje) se hráči jednorázově představí popupem hned při prvním
  // přechodu do Hardcore Mode - viz GameState.setDifficultyTier/maTusIntroPending. Kontroluje se
  // tady (globální wrapper nad celou appkou), aby fungovalo bez ohledu na to, na jaké obrazovce
  // zrovna hráč přechod na Hardcore udělal.
  void _handleMaTusIntro(BuildContext context, GameState state) {
    if (!state.maTusIntroPending || _maTusDialogShowing) return;
    _maTusDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E28),
        shape: RoundedRectangleBorder(side: const BorderSide(color: FantasyColors2.runeIce, width: 1.5), borderRadius: BorderRadius.circular(12)),
        title: Row(children: [
          FantasyIconFrame(type: FantasyIconType.systemRuneWizard, rarity: FantasyRarity.epic, size: 40, interactive: false),
          const SizedBox(width: 10),
          Expanded(child: Text(tr('Ma-Túš', 'Ma-Túš'), style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold, fontSize: 18))),
        ]),
        content: Text(
          tr(
            'Vkročil jsi do Hardcore Mode - teprve teď si zasloužíš znát mé jméno. Jsem Ma-Túš, strážce Runové svatyně. Zajdi za mnou v sekci Runový Čaroděj - mám pro tebe druhou cestu k moci: Runy osudové volby.',
            'You have stepped into Hardcore Mode - only now do you deserve to know my name. I am Ma-Túš, keeper of the Rune Sanctum. Visit me under Rune Wizard - I have a second path to power for you: the Runes of Fate.',
          ),
          style: const TextStyle(color: FantasyColors2.runeText),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.runeIce),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _maTusDialogShowing = false;
              state.dismissMaTusIntro();
            },
            child: Text(tr('Rozumím', 'Understood'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  bool _tutorialDialogShowing = false;
  // Lineární úvodní tutoriál (viz GameState.introTutorialActive/currentIntroTutorialTip) - jeden
  // krok = jeden dialog s krokoměrem a Zpět/Další/Přeskočit. Po zavření dialogu GameState
  // posune introTutorialStep a notifyListeners() spustí rebuild, který (díky _tutorialDialogShowing
  // resetnutému na false) rovnou otevře další krok - stejný mechanismus jako u _handleMaTusIntro.
  void _handleIntroTutorial(BuildContext context, GameState state) {
    if (!state.introTutorialActive || _tutorialDialogShowing) return;
    _tutorialDialogShowing = true;
    final tipId = state.currentIntroTutorialTip;
    final def = kTutorialTips[tipId]!;
    final stepIndex = state.introTutorialStep;
    final totalSteps = kTutorialIntroSteps.length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E28),
        shape: RoundedRectangleBorder(side: const BorderSide(color: FantasyColors2.runeIce, width: 1.5), borderRadius: BorderRadius.circular(12)),
        title: Row(children: [
          Icon(def.icon, color: FantasyColors2.runeIce, size: 26),
          const SizedBox(width: 10),
          Expanded(child: Text(tr(def.titleCz, def.titleEn), style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold, fontSize: 17))),
          Text('${stepIndex + 1}/$totalSteps', style: TextStyle(color: FantasyColors2.runeIce.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(child: TutorialTipContent(def: def, color: FantasyColors2.runeIce)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _tutorialDialogShowing = false;
              state.skipIntroTutorial();
            },
            child: Text(tr('Přeskočit', 'Skip'), style: const TextStyle(color: Colors.grey)),
          ),
          if (stepIndex > 0)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _tutorialDialogShowing = false;
                state.previousIntroTutorialStep();
              },
              child: Text(tr('Zpět', 'Back'), style: const TextStyle(color: FantasyColors2.runeIce)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.runeIce),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _tutorialDialogShowing = false;
              state.advanceIntroTutorial();
            },
            child: Text(stepIndex >= totalSteps - 1 ? tr('Dokončit', 'Finish') : tr('Další', 'Next'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool _contextTipDialogShowing = false;
  // Kontextové tipy (Runy/Lair/Aréna/Specializace/Artefakt atd. - viz GameState._queueContextTip)
  // se ukazují jednorázově, po jednom, hned jak si je hráč odemkne. Fronta (pendingContextTip)
  // zajistí, že se víc tipů odemčených najednou (např. skokem levelu) ukáže postupně, ne přes sebe.
  void _handleContextTip(BuildContext context, GameState state) {
    final tipId = state.pendingContextTip;
    if (tipId == null || _contextTipDialogShowing) return;
    _contextTipDialogShowing = true;
    final def = kTutorialTips[tipId]!;
    showFantasyInfoDialog(
      context,
      icon: def.icon,
      title: tr(def.titleCz, def.titleEn),
      color: const Color(0xFFFFD700),
      content: TutorialTipContent(def: def, color: const Color(0xFFFFD700)),
    ).then((_) {
      _contextTipDialogShowing = false;
      state.dismissContextTip(tipId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      Consumer<GameState>(builder: (context, state, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleNewCelebration(state));
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleMaTusIntro(context, state));
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleIntroTutorial(context, state));
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleContextTip(context, state));
        if (state.celebrationTitle == null && _controller.value == 0) return const SizedBox.shrink();
        final color = state.celebrationColor ?? FantasyColors.gold;
        return IgnorePointer(
          child: Align(
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _burstController,
                      builder: (context, _) => SizedBox(
                        width: 280, height: 280,
                        child: CustomPaint(painter: _CelebrationBurstPainter(t: 1 - _burstController.value, color: color)),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(.35), const Color(0xFF14100A)]),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color, width: 2.6),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(.65), blurRadius: 36, spreadRadius: 4),
                          BoxShadow(color: color.withOpacity(.35), blurRadius: 60, spreadRadius: 10),
                        ],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(state.celebrationIcon ?? Icons.auto_awesome, color: color, size: 56),
                        const SizedBox(height: 10),
                        Text(
                          state.celebrationTitle ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 1.6, shadows: [Shadow(color: color.withOpacity(.9), blurRadius: 18)]),
                        ),
                        if (state.celebrationSubtitle != null) ...[
                          const SizedBox(height: 5),
                          Text(state.celebrationSubtitle!, textAlign: TextAlign.center, style: const TextStyle(color: FantasyColors.parchment, fontSize: 15)),
                        ],
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    ]);
  }
}

// ===== SDÍLENÝ "FANTASY" INFO DIALOG — ornamentální rám s glow okrajem a rohovými zdobeními,
// jednotný vizuální jazyk pro popisky (resource bar, Hub dlaždice, Runový Čaroděj). Nahrazuje
// obyčejné AlertDialogy hezčím, tematičtějším oknem, ale zůstává lehký (žádné animace navíc).
Future<void> showFantasyInfoDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required Color color,
  required Widget content,
  Widget? iconWidget,
  Color bgA = const Color(0xFF1B1B22),
  Color bgB = const Color(0xFF0B0B0F),
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(1.6),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withOpacity(.25)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(.45), blurRadius: 22, spreadRadius: 1)],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          decoration: BoxDecoration(
            gradient: RadialGradient(center: Alignment.topLeft, radius: 1.4, colors: [bgA, bgB]),
            borderRadius: BorderRadius.circular(14.5),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final a in const [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
                Align(
                  alignment: a,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.diamond_outlined, size: 9, color: color.withOpacity(.55)),
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [color.withOpacity(.32), Colors.transparent]),
                          border: Border.all(color: color, width: 1.4),
                          boxShadow: [BoxShadow(color: color.withOpacity(.5), blurRadius: 8)],
                        ),
                        child: iconWidget ?? Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: .3))),
                    ]),
                    const SizedBox(height: 6),
                    Container(height: 1, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(.6), Colors.transparent]))),
                    content,
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(tr('Zavřít', 'Close'), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HubTile extends StatelessWidget {
  final FantasyIconType iconType;
  final Color accent;
  final Color fill;
  final String label;
  final int? badgeCount;
  final VoidCallback onTap;
  final bool locked;
  final String? lockedHint;
  final String description;
  final double? unlockProgress; // 0..1 - jak blízko je hráč odemčení (null = neznázorňovat prstenec, např. odemyká se smrtí, ne číselným prahem)
  final bool isNew; // právě odemčeno a hráč tuhle dlaždici ještě neotevřel - viz GameState.seenHubTiles/markHubTileSeen
  const HubTile({
    super.key,
    required this.iconType,
    required this.accent,
    required this.fill,
    required this.label,
    this.badgeCount,
    required this.onTap,
    this.locked = false,
    this.lockedHint,
    this.description = '',
    this.unlockProgress,
    this.isNew = false,
  });

  // Dřív se u zamčených dlaždic ukazoval SnackBar PŘI KAŽDÉM ťuknutí - u opakovaného ťukání
  // to působilo nešikovně/spamovalo. Teď info (co to je + k čemu to slouží + kdy se odemkne)
  // ukazuje jen podržení (dlouhý tap), krátký tap na zamčené dlaždici už nic nedělá.
  void _showInfo(BuildContext context) {
    HapticFeedback.mediumImpact();
    final color = locked ? Colors.grey.shade400 : accent;
    showFantasyInfoDialog(
      context,
      icon: Icons.info_outline,
      iconWidget: SizedBox(width: 22, height: 22, child: CustomPaint(painter: FantasyIconRegistry.of(iconType).proceduralPainter(color))),
      title: label,
      color: color,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) Text(description, style: const TextStyle(color: Color(0xFFF1E6D0), height: 1.35)),
          if (locked && lockedHint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFC69214).withOpacity(.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFC69214).withOpacity(.5))),
              child: Row(children: [
                const Icon(Icons.lock, color: Color(0xFFC69214), size: 15),
                const SizedBox(width: 8),
                Expanded(child: Text(lockedHint!, style: const TextStyle(color: Color(0xFFC69214), fontWeight: FontWeight.bold, fontSize: 12.5))),
              ]),
            ),
            if (unlockProgress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: unlockProgress!.clamp(0, 1), minHeight: 6, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(Color(0xFFC69214))),
              ),
              const SizedBox(height: 3),
              Text('${(unlockProgress!.clamp(0, 1) * 100).round()} %', style: const TextStyle(color: Color(0xFFC69214), fontSize: 10.5)),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccent = locked ? Colors.grey.shade600 : accent;
    final Color effectiveFill = locked ? const Color(0xFF1C1C22) : fill;
    final bool nearUnlock = locked && unlockProgress != null && unlockProgress! >= 0.7;
    final bool showNewGlow = isNew && !locked;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: locked ? null : onTap,
      onLongPress: () => _showInfo(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 62,
            height: 68,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (nearUnlock)
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFC69214).withOpacity(.45), blurRadius: 14, spreadRadius: 1)]),
                  ),
                if (showNewGlow)
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: FantasyColors.gold.withOpacity(.6), blurRadius: 18, spreadRadius: 2)]),
                  ),
                if (locked && unlockProgress != null)
                  SizedBox(
                    width: 66,
                    height: 66,
                    child: CircularProgressIndicator(
                      value: unlockProgress!.clamp(0, 1),
                      strokeWidth: 2.4,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(nearUnlock ? const Color(0xFFC69214) : Colors.grey.shade700),
                    ),
                  ),
                CustomPaint(size: const Size(62, 68), painter: HexBadgePainter(fill: effectiveFill, stroke: effectiveAccent)),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CustomPaint(painter: FantasyIconRegistry.of(iconType).proceduralPainter(effectiveAccent)),
                ),
                if (showNewGlow)
                  Positioned(
                    top: -4,
                    left: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: FantasyColors.gold,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: FantasyColors2.obsidian, width: 1.2),
                        boxShadow: [BoxShadow(color: FantasyColors.gold.withOpacity(.7), blurRadius: 6)],
                      ),
                      child: Text(tr('NOVÉ', 'NEW'), style: const TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: .3)),
                    ),
                  ),
                if (locked)
                  Positioned(
                    top: -4,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C22),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade600, width: 1.5),
                      ),
                      child: Icon(Icons.lock, size: 11, color: Colors.grey.shade400),
                    ),
                  )
                else if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: -4,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: FantasyColors2.hp,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FantasyColors2.obsidian, width: 1.5),
                      ),
                      child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 88,
            height: 30,
            child: Text(
              locked && lockedHint != null ? lockedHint! : label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: locked ? Colors.grey.shade600 : const Color(0xFFC9BDA0), height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

/// Otevře libovolnou existující obrazovku (LairScreen, CompanionsScreen, ...)
/// v samostatné stránce s vlastní AppBar (šipka zpět), aby ji šlo volat
/// z dlaždice na HubScreen bez nutnosti upravovat danou obrazovku.
void openWorldScreen(BuildContext context, String title, Widget screen, {Color? theme}) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: theme == null
          ? screen
          : Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: Alignment.topCenter, radius: 1.4, colors: [theme.withOpacity(.16), FantasyColors.abyss]),
              ),
              child: screen,
            ),
    ),
  ));
}

/// ===== SCÉNICKÁ MAPA (Město/Dobrodružství) =====
/// Nahrazuje dřívější HubScreen (jedna scrollovací obrazovka se dvěma GridView sekcemi) dvěma
/// samostatnými záložkami ve spodní navigaci - "Dobrodružství" a "Město" - z nichž každá teď
/// vypadá jako skutečná malovaná mapa/scéna s budovami rozmístěnými na svých pozicích místo
/// řady hexagonových dlaždic v mřížce. Klik na budovu NEnaviguje rovnou (jako dřív HubTile) -
/// otevře menu (bottom sheet) se jménem/popisem/stavem odemčení a tlačítkem "Vstoupit", které
/// teprve provede skutečnou navigaci. Datový model (SceneBuildingSpot) i byznys logika
/// (unlock/isNew/badge/onTap) jsou 1:1 převzaté z bývalého HubTile/HubScreen - mění se jen to,
/// jak jsou budovy rozmístěné a jak se na ně kliká.
class SceneBuildingSpot {
  final FantasyIconType iconType;
  final Color accent;
  final Color fill;
  final String label;
  final int? badgeCount;
  final VoidCallback onTap;
  final bool locked;
  final String? lockedHint;
  final String description;
  final double? unlockProgress;
  final bool isNew;
  final double dx; // 0..1 - horizontální pozice na scéně
  final double dy; // 0..1 - vertikální pozice (0 = v dálce/nahoře, 1 = vpředu/dole - blíž hráči)
  final double prominence; // relativní velikost budovy na mapě (1.0 = základ)
  const SceneBuildingSpot({
    required this.iconType,
    required this.accent,
    required this.fill,
    required this.label,
    this.badgeCount,
    required this.onTap,
    this.locked = false,
    this.lockedHint,
    this.description = '',
    this.unlockProgress,
    this.isNew = false,
    required this.dx,
    required this.dy,
    this.prominence = 1.0,
  });
}

/// Malovaná podkladová scéna - obloha + vzdálené siluety + zem + spojovací cestičky ke každé
/// budově z jednoho centrálního bodu vpředu. `danger` přepíná mezi teplou/klidnou paletou
/// (Město) a temnější/nebezpečnou paletou (Dobrodružství).
class _SceneBackdropPainter extends CustomPainter {
  final bool danger;
  final List<Offset> nodePositions;
  _SceneBackdropPainter({required this.danger, required this.nodePositions});

  @override
  void paint(Canvas canvas, Size size) {
    final skyColors = danger
        ? [const Color(0xFF2A0E0E), const Color(0xFF120608)]
        : [const Color(0xFF2E2416), const Color(0xFF16110A)];
    canvas.drawRect(Offset.zero & size, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: skyColors).createShader(Offset.zero & size));

    // Vzdálené siluety - zubaté hory (Dobrodružství) nebo měkčí střechy/hradby (Město).
    final silPaint = Paint()..color = (danger ? const Color(0xFF421414) : const Color(0xFF3A2E1C)).withOpacity(.55);
    final sil = Path()..moveTo(0, size.height * 0.34);
    final rnd = Random(danger ? 7 : 3);
    double x = 0;
    while (x < size.width) {
      final peakH = danger ? (0.10 + rnd.nextDouble() * 0.16) : (0.04 + rnd.nextDouble() * 0.08);
      x += size.width * (danger ? 0.10 : 0.07);
      sil.lineTo(x, size.height * (0.34 - peakH));
      x += size.width * (danger ? 0.05 : 0.04);
      sil.lineTo(x, size.height * 0.34);
    }
    sil.lineTo(size.width, size.height * 0.34);
    sil.lineTo(size.width, 0);
    sil.lineTo(0, 0);
    sil.close();
    canvas.drawPath(sil, silPaint);

    // Zem/plocha.
    final groundColors = danger
        ? [const Color(0xFF2B1210), const Color(0xFF1A0A08)]
        : [const Color(0xFF3E3320), const Color(0xFF241D12)];
    final groundRect = Rect.fromLTWH(0, size.height * 0.30, size.width, size.height * 0.70);
    canvas.drawRect(groundRect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: groundColors).createShader(groundRect));

    // Spojovací cestičky - ze společného bodu vpředu uprostřed ke každé budově. Dává mapě pocit
    // propojeného místa, ne nahodile poházených ikon.
    final hub = Offset(size.width * 0.5, size.height * 0.97);
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = (danger ? const Color(0xFF6B2E2E) : const Color(0xFFC9A96E)).withOpacity(.35)
      ..strokeCap = StrokeCap.round;
    for (final n in nodePositions) {
      final p = Offset(n.dx * size.width, n.dy * size.height);
      final mid = Offset((p.dx + hub.dx) / 2, (p.dy + hub.dy) / 2 + 14);
      canvas.drawPath(Path()..moveTo(hub.dx, hub.dy)..quadraticBezierTo(mid.dx, mid.dy, p.dx, p.dy), pathPaint);
    }

    // Jemné hvězdy/jiskry na obloze.
    final starRnd = Random(danger ? 11 : 5);
    for (int i = 0; i < 40; i++) {
      final p = Offset(starRnd.nextDouble() * size.width, starRnd.nextDouble() * size.height * 0.32);
      canvas.drawCircle(p, 0.8 + starRnd.nextDouble() * 1.0, Paint()..color = Colors.white.withOpacity(0.15 + starRnd.nextDouble() * 0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _SceneBackdropPainter old) => false;
}

/// Menu po kliknutí na budovu - jméno/ikona/popis/stav odemčení + tlačítko "Vstoupit", které
/// teprve zavolá skutečné onTap (navigaci). Vizuálně navazuje na dřívější HubTile._showInfo,
/// jen navíc přidává akční tlačítko pro odemčené budovy.
void _showSceneBuildingMenu(BuildContext context, SceneBuildingSpot spot) {
  HapticFeedback.mediumImpact();
  final color = spot.locked ? Colors.grey.shade400 : spot.accent;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FantasyColors2.panelLight, FantasyColors2.panel]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(.6)),
          boxShadow: [BoxShadow(color: color.withOpacity(.25), blurRadius: 24, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 46, height: 46, padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(.35), FantasyColors2.obsidian]), border: Border.all(color: color)),
                child: CustomPaint(painter: FantasyIconRegistry.of(spot.iconType).proceduralPainter(color)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(spot.label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))),
            ]),
            const SizedBox(height: 14),
            if (spot.description.isNotEmpty) Text(spot.description, style: const TextStyle(color: Color(0xFFF1E6D0), height: 1.35)),
            if (spot.locked && spot.lockedHint != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFC69214).withOpacity(.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFC69214).withOpacity(.5))),
                child: Row(children: [
                  const Icon(Icons.lock, color: Color(0xFFC69214), size: 15),
                  const SizedBox(width: 8),
                  Expanded(child: Text(spot.lockedHint!, style: const TextStyle(color: Color(0xFFC69214), fontWeight: FontWeight.bold, fontSize: 12.5))),
                ]),
              ),
              if (spot.unlockProgress != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: spot.unlockProgress!.clamp(0, 1), minHeight: 6, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(Color(0xFFC69214))),
                ),
                const SizedBox(height: 3),
                Text('${(spot.unlockProgress!.clamp(0, 1) * 100).round()} %', style: const TextStyle(color: Color(0xFFC69214), fontSize: 10.5)),
              ],
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(tr('Vstoupit', 'Enter'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    spot.onTap();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Vizuální marker jedné budovy na scéně - stejný hex-badge jazyk jako dřívější HubTile (glow za
/// odemčení blízko, prstenec progresu, "NOVÉ" štítek, zámek/badge v rohu), jen umístěný přes
/// Positioned na scéně místo v GridView buňce, a tap otevírá menu místo přímé navigace.
class _SceneBuildingMarker extends StatelessWidget {
  final SceneBuildingSpot spot;
  const _SceneBuildingMarker({required this.spot});

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccent = spot.locked ? Colors.grey.shade600 : spot.accent;
    final Color effectiveFill = spot.locked ? const Color(0xFF1C1C22) : spot.fill;
    final bool nearUnlock = spot.locked && spot.unlockProgress != null && spot.unlockProgress! >= 0.7;
    final bool showNewGlow = spot.isNew && !spot.locked;
    final double w = 62 * spot.prominence;
    final double h = 68 * spot.prominence;
    return GestureDetector(
      onTap: () => _showSceneBuildingMenu(context, spot),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: w + 8,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (nearUnlock)
                  Container(width: w + 4, height: w + 4, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFC69214).withOpacity(.45), blurRadius: 14, spreadRadius: 1)])),
                if (showNewGlow)
                  Container(width: w + 6, height: w + 6, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: FantasyColors.gold.withOpacity(.6), blurRadius: 18, spreadRadius: 2)])),
                if (spot.locked && spot.unlockProgress != null)
                  SizedBox(width: w + 4, height: w + 4, child: CircularProgressIndicator(value: spot.unlockProgress!.clamp(0, 1), strokeWidth: 2.4, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(nearUnlock ? const Color(0xFFC69214) : Colors.grey.shade700))),
                CustomPaint(size: Size(w, h), painter: HexBadgePainter(fill: effectiveFill, stroke: effectiveAccent)),
                SizedBox(width: 30 * spot.prominence, height: 30 * spot.prominence, child: CustomPaint(painter: FantasyIconRegistry.of(spot.iconType).proceduralPainter(effectiveAccent))),
                if (showNewGlow)
                  Positioned(
                    top: -4, left: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: FantasyColors.gold, borderRadius: BorderRadius.circular(6), border: Border.all(color: FantasyColors2.obsidian, width: 1.2), boxShadow: [BoxShadow(color: FantasyColors.gold.withOpacity(.7), blurRadius: 6)]),
                      child: Text(tr('NOVÉ', 'NEW'), style: const TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: .3)),
                    ),
                  ),
                if (spot.locked)
                  Positioned(
                    top: -4, right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: const Color(0xFF1C1C22), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade600, width: 1.5)),
                      child: Icon(Icons.lock, size: 11, color: Colors.grey.shade400),
                    ),
                  )
                else if (spot.badgeCount != null && spot.badgeCount! > 0)
                  Positioned(
                    top: -4, right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: FantasyColors2.hp, borderRadius: BorderRadius.circular(8), border: Border.all(color: FantasyColors2.obsidian, width: 1.5)),
                      child: Text('${spot.badgeCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 84),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.black.withOpacity(.55), borderRadius: BorderRadius.circular(6)),
            child: Text(
              spot.locked && spot.lockedHint != null ? spot.lockedHint! : spot.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: spot.locked ? Colors.grey.shade500 : const Color(0xFFF1E6D0), height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sdílený "rám" scény - nadpis sekce + malovaná mapa s budovami umístěnými na svých dx/dy
/// pozicích (zlomek 0..1 šířky/výšky). Použito jak CityScreen (Město), tak AdventureScreen
/// (Dobrodružství) níž.
class SceneMapView extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Color titleAccent;
  final bool danger;
  final List<SceneBuildingSpot> buildings;
  // Ambientní "živá" vrstva navrch pozadí - funguje stejně nad procedurálním painterem i nad
  // reálným obrázkem. `smokePoints`/`glowPoints` jsou frakční pozice (0..1) komínů a
  // rozsvícených oken/luceren - jednotlivé scény si je dají podle toho, co mají na obrázku.
  final List<Offset> smokePoints;
  final List<Offset> glowPoints;
  // Cesta ke skutečné vygenerované ilustraci scény (viz konverzace o Copilot promptech) - pokud
  // je zadaná, nahradí procedurální _SceneBackdropPainter. Zůstává null, dokud daná scéna nemá
  // hotový obrázek - pak se použije starý procedurální fallback, nic dalšího se měnit nemusí.
  final String? backgroundImage;
  const SceneMapView({super.key, required this.title, required this.titleIcon, required this.titleAccent, required this.danger, required this.buildings, this.smokePoints = const [], this.glowPoints = const [], this.backgroundImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [Color(0xFF241C30), FantasyColors2.obsidian]),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: Row(children: [
                Icon(titleIcon, color: titleAccent, size: 20),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.cinzel(color: titleAccent, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 1.2)),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 1, color: titleAccent.withOpacity(.35))),
              ]),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 560,
                decoration: BoxDecoration(border: Border.all(color: titleAccent.withOpacity(.35))),
                child: LayoutBuilder(builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: backgroundImage != null
                            ? Image.asset(backgroundImage!, fit: BoxFit.cover)
                            : CustomPaint(painter: _SceneBackdropPainter(danger: danger, nodePositions: buildings.map((b) => Offset(b.dx, b.dy)).toList())),
                      ),
                      Positioned.fill(child: _SceneLifeOverlay(danger: danger, smokePoints: smokePoints, glowPoints: glowPoints)),
                      for (final b in buildings)
                        Positioned(
                          left: (b.dx * size.width - (35 * b.prominence)).clamp(0.0, size.width - 70 * b.prominence),
                          top: (b.dy * size.height - (37 * b.prominence)).clamp(0.0, size.height - 74 * b.prominence),
                          child: _SceneBuildingMarker(spot: b),
                        ),
                      // Mlha nad ještě neodemčenými lokacemi - hustota vychází přímo z
                      // unlockProgress dané budovy, takže řídne sama, jak se hráč blíží
                      // odemykacímu levelu, a úplně zmizí v okamžiku odemčení (spot.locked
                      // přestane platit → vypadne z filtru níž). Nad markerem, ne pod ním -
                      // aby lokaci vizuálně "zahalovala", ale IgnorePointer uvnitř nechá tap
                      // proklouznout na budovu pod ní.
                      Positioned.fill(
                        child: _SceneFogOverlay(
                          patches: [
                            for (final b in buildings)
                              if (b.locked)
                                _FogPatch(pos: Offset(b.dx, b.dy), density: (1 - (b.unlockProgress ?? 0).clamp(0.0, 1.0) * 0.7).clamp(0.0, 1.0), prominence: b.prominence),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ambientní "živá" vrstva scény - kouř z komínů, blikající světla (okna/lucerny) a poletující
/// světlušky/prach napříč celou mapou. Vlastní nekonečně opakující se AnimationController, žádná
/// závislost na herním stavu - jede sama na pozadí, dokud je scéna zobrazená.
class _SceneLifeOverlay extends StatefulWidget {
  final bool danger;
  final List<Offset> smokePoints;
  final List<Offset> glowPoints;
  const _SceneLifeOverlay({required this.danger, required this.smokePoints, required this.glowPoints});

  @override
  State<_SceneLifeOverlay> createState() => _SceneLifeOverlayState();
}

class _SceneLifeOverlayState extends State<_SceneLifeOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.smokePoints.isEmpty && widget.glowPoints.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _SceneLifePainter(t: _c.value, danger: widget.danger, smokePoints: widget.smokePoints, glowPoints: widget.glowPoints),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SceneLifePainter extends CustomPainter {
  final double t;
  final bool danger;
  final List<Offset> smokePoints;
  final List<Offset> glowPoints;
  _SceneLifePainter({required this.t, required this.danger, required this.smokePoints, required this.glowPoints});

  @override
  void paint(Canvas canvas, Size size) {
    // Kouř z komínů - 3 částice na komín, každá s jinou fází, stoupá a rozplývá se.
    for (int p = 0; p < smokePoints.length; p++) {
      final base = Offset(smokePoints[p].dx * size.width, smokePoints[p].dy * size.height);
      for (int i = 0; i < 3; i++) {
        final phase = (t + i / 3 + p * 0.37) % 1.0;
        final dy = -phase * 46;
        final dx = sin(phase * pi * 2 + p) * 6;
        final r = 3 + phase * 6;
        final opacity = (1 - phase) * 0.30;
        canvas.drawCircle(base + Offset(dx, dy), r, Paint()..color = Colors.white.withOpacity(opacity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }
    // Blikající světla (okna/lucerny) - teplá záře, jas jemně kolísá v různé fázi u každého.
    for (int i = 0; i < glowPoints.length; i++) {
      final base = Offset(glowPoints[i].dx * size.width, glowPoints[i].dy * size.height);
      final flicker = 0.5 + 0.5 * sin(t * 2 * pi * (1.3 + i * 0.21) + i);
      canvas.drawCircle(base, 5 + flicker * 2, Paint()..color = const Color(0xFFFFD37A).withOpacity(0.22 + flicker * 0.33)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
    // Poletující světlušky/jiskry napříč celou scénou - teplá barva u Města, ohnivější u Dobrodružství.
    final rnd = Random(danger ? 99 : 42);
    final motColor = danger ? const Color(0xFFFF8A65) : const Color(0xFFFFF3B0);
    for (int i = 0; i < 14; i++) {
      final seed = rnd.nextDouble();
      final speedSeed = rnd.nextDouble();
      final phase = (t * (0.3 + speedSeed * 0.4) + seed) % 1.0;
      final x = (seed * 1.3 - 0.15 + sin(phase * pi * 2) * 0.03) * size.width;
      final y = (1 - phase) * size.height;
      final opacity = sin(phase * pi).clamp(0.0, 1.0) * 0.5;
      canvas.drawCircle(Offset(x, y), 1.6, Paint()..color = motColor.withOpacity(opacity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }
  }

  @override
  bool shouldRepaint(covariant _SceneLifePainter old) => old.t != t;
}

/// Mlha nad ještě neodemčenou lokací na mapě. `density` (0..1) řídne přímo podle
/// unlockProgress dané budovy (viz volání v SceneMapView výš) - hustá daleko od odemčení,
/// skoro průhledná těsně před ním, a úplně zmizí v okamžiku odemčení (locked přestane platit).
class _FogPatch {
  final Offset pos; // frakční pozice 0..1
  final double density; // 0..1
  final double prominence;
  const _FogPatch({required this.pos, required this.density, required this.prominence});
}

class _SceneFogOverlay extends StatefulWidget {
  final List<_FogPatch> patches;
  const _SceneFogOverlay({required this.patches});

  @override
  State<_SceneFogOverlay> createState() => _SceneFogOverlayState();
}

class _SceneFogOverlayState extends State<_SceneFogOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // Pomalý cyklus (20s) - mlha se má nenápadně vlnit, ne "bublat".
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.patches.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _SceneFogPainter(t: _c.value, patches: widget.patches), size: Size.infinite),
      ),
    );
  }
}

class _SceneFogPainter extends CustomPainter {
  final double t;
  final List<_FogPatch> patches;
  _SceneFogPainter({required this.t, required this.patches});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in patches) {
      final base = Offset(p.pos.dx * size.width, p.pos.dy * size.height);
      final baseR = 46 * p.prominence;
      // 4 překrývající se měkké mlžné shluky, pomalu driftující kolem pozice budovy - "živá"
      // mlha místo statické šedé skvrny, ladí to s ostatní ambientní vrstvou (kouř/světla).
      for (int i = 0; i < 4; i++) {
        final phase = t * 2 * pi + i * (pi / 2);
        final dx = sin(phase) * 10 * p.prominence;
        final dy = cos(phase * 0.7) * 6 * p.prominence;
        final r = baseR * (0.75 + 0.25 * sin(phase * 1.3));
        canvas.drawCircle(
          base + Offset(dx, dy),
          r,
          Paint()
            ..color = const Color(0xFFC7CDD6).withOpacity(0.22 * p.density)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * p.prominence),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SceneFogPainter old) => old.t != t || old.patches.length != patches.length;
}

/// Záložka "Dobrodružství" ve spodní navigaci - dřív horní sekce v HubScreen. Stejná byznys
/// logika (isHubTileRevealed/unlocked/badge/onTap) jako dřív, jen budovy mají pevnou pozici na
/// malované mapě místo místa v mřížce.
class AdventureScreen extends StatelessWidget {
  const AdventureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      final buildings = <SceneBuildingSpot>[
        SceneBuildingSpot(
          // Věž Osudu - hlavní herní smyčka, dřív permanentní bottom-nav tab, teď nejvýraznější
          // (a vždy odemčená) budova hned vpředu uprostřed mapy Dobrodružství. Pozice
          // přepočítaná podle skutečného obrázku dobrodruzstvi.png - vstup do věže je cca v
          // polovině výšky scény, ne úplně vepředu (věž samotná sahá až k obloze).
          iconType: FantasyIconType.systemTower, accent: const Color(0xFF1E88E5), fill: const Color(0xFF0D2A42),
          label: tr('Věž Osudu', 'Tower of Fate'),
          description: tr('Hlavní věž - postupuj patro po patře, bojuj s nepřáteli a bossy, sbírej vybavení a levuj postavu. Tvůj hlavní zdroj postupu ve hře, dostupný od začátku.',
              'The main tower - climb floor by floor, fight enemies and bosses, collect gear and level up your character. Your main source of progress in the game, available from the start.'),
          dx: 0.50, dy: 0.50, prominence: 1.4,
          onTap: () => openWorldScreen(context, tr('Věž Osudu', 'Tower of Fate'), const TowerScreen(), theme: const Color(0xFF1E88E5)),
        ),
        if (state.isHubTileRevealed(GameState.lairUnlockLevel))
          SceneBuildingSpot(
            // Lebkovitá jeskyně vlevo nahoře na obrázku.
            iconType: FantasyIconType.systemBossLair, accent: FantasyColors2.hp, fill: const Color(0xFF331414),
            label: tr('Doupě bosse', 'Boss Lair'),
            locked: !state.lairUnlocked,
            isNew: state.lairUnlocked && !state.seenHubTiles.contains('lair'),
            unlockProgress: state.level / GameState.lairUnlockLevel,
            lockedHint: tr('Odemyká se na levelu ${GameState.lairUnlockLevel}', 'Unlocks at level ${GameState.lairUnlockLevel}'),
            description: tr('Řada čím dál těžších bossů se stoupající obtížností (Normal → Hardcore → Předpeklí → Peklo). Poražení bosse dává Zlato, Krystaly a Suroviny - od patra 30 i Esenci Moci na vylepšení legendárního vybavení.',
                'A series of increasingly tough bosses across rising difficulties (Normal → Hardcore → Předpeklí → Peklo). Defeating a boss gives Gold, Crystals and Materials - from floor 30 also Power Essence for upgrading legendary gear.'),
            dx: 0.16, dy: 0.30, prominence: 1.05,
            onTap: () {
              if (!state.lairUnlocked) return;
              state.markHubTileSeen('lair');
              openWorldScreen(context, tr('Doupě bosse', 'Boss Lair'), const LairScreen(), theme: const Color(0xFF8B0E0E));
            },
          ),
        if (state.isHubTileRevealed(GameState.arenaUnlockLevel))
          SceneBuildingSpot(
            // Kamenná aréna s kruhovými tribunami vpravo nahoře.
            iconType: FantasyIconType.systemBossLair, accent: const Color(0xFFFFD700), fill: const Color(0xFF2A2308),
            label: tr('Aréna', 'Arena'),
            locked: !state.arenaUnlocked,
            isNew: state.arenaUnlocked && !state.seenHubTiles.contains('arena'),
            unlockProgress: state.level / GameState.arenaUnlockLevel,
            lockedHint: tr('Odemyká se na levelu ${GameState.arenaUnlockLevel}', 'Unlocks at level ${GameState.arenaUnlockLevel}'),
            description: tr('Souboj proti AI generovanému soupeři tvé třídy za Zlato, Magický prach a truhly. Dobrý zdroj postupu, i když jsi zrovna zaseklý na patře ve Věži.',
                'Fight an AI-generated opponent of your class for Gold, Magic Dust and chests. A solid source of progress even when you are stuck on a Tower floor.'),
            dx: 0.82, dy: 0.38, prominence: 1.0,
            onTap: () {
              if (!state.arenaUnlocked) return;
              state.markHubTileSeen('arena');
              openWorldScreen(context, tr('Aréna', 'Arena'), const ArenaScreen(), theme: const Color(0xFFFF8000));
            },
          ),
        if (state.isHubTileRevealed(GameState.worldBossUnlockLevel))
          SceneBuildingSpot(
            // Žhavá rohatá příšera napůl vynořená ze země, přímo uprostřed cest.
            iconType: FantasyIconType.systemBossLair, accent: const Color(0xFFFF5A36), fill: const Color(0xFF301008),
            label: 'World Boss',
            badgeCount: state.worldBossUnlocked && state.worldBossAvailable ? 1 : null,
            locked: !state.worldBossUnlocked,
            isNew: state.worldBossUnlocked && !state.seenHubTiles.contains('worldboss'),
            unlockProgress: state.level / GameState.worldBossUnlockLevel,
            lockedHint: tr('Odemyká se na levelu ${GameState.worldBossUnlockLevel}', 'Unlocks at level ${GameState.worldBossUnlockLevel}'),
            description: tr('Jednou denně dostupný extrémně silný boss. Poražení dává velkou odměnu (Zlato, Esenci Moci, Runové kameny) - pokusy navíc jdou získat za rewarded reklamu.',
                'An extremely tough boss available once per day. Defeating it gives a big reward (Gold, Power Essence, Rune Stones) - extra attempts can be earned via a rewarded ad.'),
            dx: 0.50, dy: 0.62, prominence: 1.15,
            onTap: () {
              if (!state.worldBossUnlocked) return;
              state.markHubTileSeen('worldboss');
              openWorldScreen(context, 'World Boss', const WorldBossScreen(), theme: const Color(0xFFB71C1C));
            },
          ),
        if (state.isHubTileRevealed(GameState.riftUnlockLevel))
          SceneBuildingSpot(
            // Fialový krystalický útvar s blesky vlevo dole.
            iconType: FantasyIconType.systemRift, accent: const Color(0xFF8B5CF6), fill: const Color(0xFF1A1030),
            label: tr('Trhlina Osudu', 'Rift of Fate'),
            badgeCount: state.riftUnlocked && state.riftAttemptsToday < state.riftEffectiveDailyLimit ? (state.riftEffectiveDailyLimit - state.riftAttemptsToday) : null,
            locked: !state.riftUnlocked,
            isNew: state.riftUnlocked && !state.seenHubTiles.contains('rift'),
            unlockProgress: state.level / GameState.riftUnlockLevel,
            lockedHint: tr('Odemyká se na levelu ${GameState.riftUnlockLevel}', 'Unlocks at level ${GameState.riftUnlockLevel}'),
            description: tr('Náhodně generované výzvy s modifikátory a omezeným počtem pokusů denně. Odměnou jsou truhly s Magickým prachem/Krystaly a šance na vzácné vybavení.',
                'Randomly generated challenges with modifiers and a limited number of daily attempts. Rewards are chests with Magic Dust/Crystals and a chance at rare gear.'),
            dx: 0.15, dy: 0.78, prominence: 0.95,
            onTap: () {
              if (!state.riftUnlocked) return;
              state.markHubTileSeen('rift');
              openWorldScreen(context, tr('Trhlina Osudu', 'Rift of Fate'), const RiftScreen(), theme: const Color(0xFF8B5CF6));
            },
          ),
        if (state.endlessScaleUnlocked)
          SceneBuildingSpot(
            // Fialové plovoucí kamenné schodiště mizející do propasti vpravo dole.
            iconType: FantasyIconType.systemBossLair, accent: Colors.deepPurpleAccent, fill: const Color(0xFF1A0A2A),
            label: 'Endless Scale',
            isNew: !state.seenHubTiles.contains('endlessscale'),
            description: tr('Nekonečně škálující souboj bez stropu obtížnosti - test toho, jak daleko tvůj build dokáže zajít.',
                'An endlessly scaling fight with no difficulty cap - a test of how far your build can go.'),
            dx: 0.78, dy: 0.83, prominence: 0.9,
            onTap: () {
              state.markHubTileSeen('endlessscale');
              openWorldScreen(context, 'Endless Scale', const EndlessScaleScreen(), theme: Colors.deepPurpleAccent);
            },
          ),
      ];
      return SceneMapView(
        title: tr('DOBRODRUŽSTVÍ', 'ADVENTURE'),
        titleIcon: Icons.terrain,
        titleAccent: const Color(0xFFFF8000),
        danger: true,
        buildings: buildings,
        backgroundImage: 'assets/images/scenes/adventure_bg.png',
        // Přepočítáno podle skutečného obrázku: zářivý paprsek na vrcholu Věže, žhavá záře
        // World Bosse, doutnající vchod do Doupěte.
        glowPoints: const [Offset(0.50, 0.06), Offset(0.50, 0.64), Offset(0.15, 0.40)],
      );
    });
  }
}

/// Záložka "Město" ve spodní navigaci - dřív spodní sekce v HubScreen. Stejná byznys logika,
/// jen na malované mapě místo mřížky.
class CityScreen extends StatelessWidget {
  const CityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      final buildings = <SceneBuildingSpot>[
        SceneBuildingSpot(
          // Dřevěná chalupa s praporcem vlevo nahoře.
          iconType: FantasyIconType.systemGuild, accent: FantasyColors2.arcaneViolet, fill: const Color(0xFF241A38),
          label: tr('Družina', 'Companions'),
          locked: state.companionsTileLocked,
          isNew: !state.companionsTileLocked && !state.seenHubTiles.contains('companions'),
          lockedHint: tr('Odemyká se po první smrti', 'Unlocks after your first death'),
          description: tr('Najímej a levelu společníky, kteří ti dávají trvalý bonus síly i mimo boj. Odemkne se po tvé první smrti jako útěcha do dalšího pokusu.',
              'Recruit and level up companions that give you a permanent power bonus outside combat too. Unlocks after your first death as a consolation for the next run.'),
          dx: 0.20, dy: 0.22, prominence: 0.9,
          onTap: () {
            if (state.companionsTileLocked) return;
            state.markHubTileSeen('companions');
            openWorldScreen(context, tr('Družina', 'Companions'), const CompanionsScreen());
          },
        ),
        SceneBuildingSpot(
          // Dřevěná nástěnka s pergameny uprostřed vpravo.
          iconType: FantasyIconType.systemQuests, accent: FantasyColors2.emberGold, fill: const Color(0xFF3A2B12),
          label: tr('Questy', 'Quests'),
          description: tr('Denní a týdenní úkoly za Zlato, Magický prach a další odměny. Pravidelný zdroj postupu, aniž bys musel celý den aktivně bojovat.',
              'Daily and weekly tasks for Gold, Magic Dust and other rewards. A steady source of progress without needing to actively fight all day.'),
          dx: 0.68, dy: 0.31, prominence: 0.85,
          onTap: () => openWorldScreen(context, tr('Questy', 'Quests'), const QuestScreen()),
        ),
        SceneBuildingSpot(
          // Kovárna s velkým komínem a kovadlinou uprostřed - dominanta scény.
          iconType: FantasyIconType.systemForge, accent: FantasyColors2.teal, fill: const Color(0xFF122824),
          label: tr('Kovárna', 'Forge'),
          locked: !state.blacksmithUnlocked,
          isNew: state.blacksmithUnlocked && !state.seenHubTiles.contains('blacksmith'),
          unlockProgress: state.level / GameState.blacksmithUnlockLevel,
          lockedHint: tr('Odemyká se na levelu ${GameState.blacksmithUnlockLevel}', 'Unlocks at level ${GameState.blacksmithUnlockLevel}'),
          description: tr('Kup si vygenerované vybavení podle ranku Kováře, nebo si ho nech vykovat. Rank kováře roste s používáním a zlepšuje jak staty, tak ceny na Tržišti.',
              'Buy gear generated according to the Blacksmith rank, or have a piece forged. The rank grows with use and improves both stats and Market prices.'),
          dx: 0.48, dy: 0.62, prominence: 1.15,
          onTap: () {
            if (!state.blacksmithUnlocked) return;
            state.markHubTileSeen('blacksmith');
            openWorldScreen(context, tr('Kovárna', 'Forge'), const BlacksmithScreen());
          },
        ),
        SceneBuildingSpot(
          // Chalupa se zeleným kouřem z komína a svítícími lahvičkami v okně vlevo.
          iconType: FantasyIconType.systemAlchemy, accent: FantasyColors2.arcaneViolet, fill: const Color(0xFF241A38),
          label: tr('Alchymie', 'Alchemy'),
          description: tr('Vař lektvary a elixíry z nasbíraných surovin - léčení, dočasné buffy a další efekty do boje.',
              'Brew potions and elixirs from gathered materials - healing, temporary buffs and other combat effects.'),
          dx: 0.13, dy: 0.50, prominence: 0.95,
          onTap: () => openWorldScreen(context, tr('Alchymie', 'Alchemy'), const AlchemistScreen()),
        ),
        SceneBuildingSpot(
          // Pruhované tržní stánky s lucerničkami vpravo.
          iconType: FantasyIconType.systemMarket, accent: FantasyColors2.emberGold, fill: const Color(0xFF3A2B12),
          label: tr('Tržiště', 'Market'),
          locked: !state.marketUnlocked,
          isNew: state.marketUnlocked && !state.seenHubTiles.contains('market'),
          unlockProgress: state.level / GameState.marketUnlockLevel,
          lockedHint: tr('Odemyká se na levelu ${GameState.marketUnlockLevel}', 'Unlocks at level ${GameState.marketUnlockLevel}'),
          description: tr('Nakupuj základní vybavení a lektvary za Zlato, plus dvě Speciální nabídky (Rare/Epic/Legendary/SET), které se obnovují každou hodinu.',
              'Buy basic gear and potions with Gold, plus two Featured Offers (Rare/Epic/Legendary/SET) that refresh every hour.'),
          dx: 0.80, dy: 0.46, prominence: 1.0,
          onTap: () {
            if (!state.marketUnlocked) return;
            state.markHubTileSeen('market');
            openWorldScreen(context, tr('Tržiště', 'Market'), const MarketScreen());
          },
        ),
        if (state.isHubTileRevealed(GameState.runeWizardTileUnlockLevel))
          SceneBuildingSpot(
            // Modře zářící runová věž vlevo dole.
            iconType: FantasyIconType.systemRuneWizard, accent: FantasyColors2.runeIce, fill: const Color(0xFF0F1E28),
            label: tr('Runový Čaroděj', 'Rune Wizard'),
            badgeCount: state.runeWizardTileUnlocked && state.runeWizardUnlocked && state.runeTalentPoints > 0 ? state.runeTalentPoints : null,
            locked: !state.runeWizardTileUnlocked,
            isNew: state.runeWizardTileUnlocked && !state.seenHubTiles.contains('runewizard'),
            unlockProgress: state.level / GameState.runeWizardTileUnlockLevel,
            lockedHint: tr('Odemyká se na levelu ${GameState.runeWizardTileUnlockLevel}', 'Unlocks at level ${GameState.runeWizardTileUnlockLevel}'),
            description: tr('Endgame talentový strom za Runové kameny získané z bossů - trvalé pasivní bonusy nezávislé na aktuálním vybavení.',
                'An endgame talent tree paid for with Rune Stones earned from bosses - permanent passive bonuses independent of your current gear.'),
            dx: 0.14, dy: 0.86, prominence: 1.0,
            onTap: () {
              if (!state.runeWizardTileUnlocked) return;
              state.markHubTileSeen('runewizard');
              openWorldScreen(context, tr('Runový Čaroděj', 'Rune Wizard'), const RuneWizardScreen());
            },
          ),
        if (state.isHubTileRevealed(GameState.runeBlacksmithUnlockLevel))
          SceneBuildingSpot(
            // Rudě zářící runová kovárna vpravo dole.
            iconType: FantasyIconType.systemForge, accent: const Color(0xFFFF1744), fill: const Color(0xFF1F0F14),
            label: tr('Runový Kovář', 'Rune Blacksmith'),
            badgeCount: state.runeBlacksmithTileUnlocked && state.specialization != 0 && !state.hasCraftedActiveArtifactWeapon ? 1 : null,
            locked: !state.runeBlacksmithTileUnlocked,
            isNew: state.runeBlacksmithTileUnlocked && !state.seenHubTiles.contains('runeblacksmith'),
            unlockProgress: state.level / GameState.runeBlacksmithUnlockLevel,
            lockedHint: tr('Odemyká se na levelu ${GameState.runeBlacksmithUnlockLevel}', 'Unlocks at level ${GameState.runeBlacksmithUnlockLevel}'),
            description: tr('Vykovej si osobní Artefaktovou zbraň a postupně ji vylepšuj Esencí Moci a silnějšími zbraněmi z batohu. Zbraň roste s tebou po celou hru, bez stropu.',
                'Forge your own Artifact Weapon and gradually upgrade it with Power Essence and stronger weapons from your bag. It grows with you for the whole game, with no cap.'),
            dx: 0.85, dy: 0.88, prominence: 1.0,
            onTap: () {
              if (!state.runeBlacksmithTileUnlocked) return;
              state.markHubTileSeen('runeblacksmith');
              openWorldScreen(context, tr('Runový Kovář', 'Rune Blacksmith'), const RuneBlacksmithScreen());
            },
          ),
        SceneBuildingSpot(
          // Vzdálený kamenný chrám s modře zářícími dveřmi, úplně vzadu uprostřed.
          iconType: FantasyIconType.systemMarket, accent: const Color(0xFF64B5F6), fill: const Color(0xFF0F1F2E),
          label: tr('Banka', 'Bank'),
          badgeCount: state.bankUnlocked && state.bankItems.isNotEmpty ? state.bankItems.length : null,
          locked: !state.bankUnlocked,
          isNew: state.bankUnlocked && !state.seenHubTiles.contains('bank'),
          unlockProgress: state.level / GameState.bankUnlockLevel,
          lockedHint: tr('Odemyká se na levelu ${GameState.bankUnlockLevel}', 'Unlocks at level ${GameState.bankUnlockLevel}'),
          description: tr('Trvalé úložiště mimo inventář - ulož si vybavení jiné třídy nebo buildu, místo abys ho prodal nebo roztavil, když zrovna nesedí k aktuální specializaci.',
              'Permanent storage outside your inventory - stash gear from another class or build instead of selling or salvaging it when it does not fit your current spec.'),
          dx: 0.50, dy: 0.15, prominence: 0.7,
          onTap: () {
            if (!state.bankUnlocked) return;
            state.markHubTileSeen('bank');
            openWorldScreen(context, tr('Banka', 'Bank'), const BankScreen());
          },
        ),
        if (state.isHubTileRevealed(GameState.kronikaUnlockLevel))
          SceneBuildingSpot(
            // Kulatá věž s velkým prosvětleným ciferníkem/oknem vpravo nahoře.
            iconType: FantasyIconType.systemQuests, accent: const Color(0xFF8B5CF6), fill: const Color(0xFF241A38),
            label: tr('Kronika', 'Chronicle'),
            locked: !state.kronikaUnlocked,
            isNew: state.kronikaUnlocked && !state.seenHubTiles.contains('kronika'),
            unlockProgress: state.level / GameState.kronikaUnlockLevel,
            lockedHint: tr('Odemyká se na levelu ${GameState.kronikaUnlockLevel}', 'Unlocks at level ${GameState.kronikaUnlockLevel}'),
            description: tr('Denní/týdenní/měsíční přehled cílů a odměn (Chronicle coin) a trvalé úložiště vybavení napříč třídami.',
                'A daily/weekly/monthly overview of goals and rewards (Chronicle coin), plus permanent cross-class gear storage.'),
            dx: 0.90, dy: 0.20, prominence: 0.9,
            onTap: () {
              if (!state.kronikaUnlocked) return;
              state.markHubTileSeen('kronika');
              openWorldScreen(context, tr('Kronika', 'Chronicle'), const KronikaScreen());
            },
          ),
      ];
      return SceneMapView(
        title: tr('MĚSTO', 'TOWN'),
        titleIcon: Icons.location_city,
        titleAccent: const Color(0xFFC9A96E),
        danger: false,
        buildings: buildings,
        backgroundImage: 'assets/images/scenes/town_bg.png',
        // Kouř z komína Kovárny (černý/žhavý) + zelenkavý dým Alchymie - přesně jak jsou
        // namalované na skutečném obrázku.
        smokePoints: const [Offset(0.48, 0.58), Offset(0.13, 0.42)],
        // Blikající okénka podle skutečných světel na obrázku - Runový Čaroděj (modrá záře),
        // Runový Kovář (rudá záře), Banka (modré dveře vzadu), Kronika (prosvětlené okno věže),
        // tržní lucerničky.
        glowPoints: const [Offset(0.14, 0.80), Offset(0.85, 0.80), Offset(0.50, 0.13), Offset(0.90, 0.18), Offset(0.80, 0.42)],
      );
    });
  }
}


/// Obrazovka Runového Čaroděje - end-game systém run v severském stylu
/// (Elder Futhark jména, ledově modrá/kamenná paleta). Vizuálně záměrně
/// odlišná od teplé jantarové palety zbytku hry, aby působila jako
/// samostatná "mrazivá svatyně" endgame obsahu.
class RuneWizardScreen extends StatefulWidget {
  const RuneWizardScreen({super.key});

  @override
  State<RuneWizardScreen> createState() => _RuneWizardScreenState();
}

class _RuneWizardScreenState extends State<RuneWizardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      if (!state.runeWizardUnlocked) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [FantasyColors2.runeBgLight, FantasyColors2.runeBg]),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FantasyIconFrame(type: FantasyIconType.systemRuneWizard, rarity: FantasyRarity.epic, size: 72, interactive: false),
              const SizedBox(height: 18),
              Text(tr('Runový Čaroděj', 'Rune Wizard'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FantasyColors2.runeText, letterSpacing: 1)),
              const SizedBox(height: 10),
              Text(
                tr('Tato svatyně se probudí, až porazíš bosse na patře 20 nebo výše - ve Věži, nebo v Doupěti bosse.', 'This sanctum awakens once you defeat a boss on floor 20 or higher - in the Tower, or in the Boss Lair.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: FantasyColors2.runeMuted),
              ),
            ],
          ),
        );
      }
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [FantasyColors2.runeBgLight, FantasyColors2.runeBg]),
        ),
        child: Column(
          children: [
            // Dekorativní hlavička svatyně - jemný "frost" pruh nad záložkami, ať obrazovka
            // nezačíná rovnou technickým TabBarem.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [FantasyColors2.runeIce.withOpacity(.10), Colors.transparent]),
                border: const Border(bottom: BorderSide(color: FantasyColors2.runeIce, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [FantasyColors2.runeIce.withOpacity(.35), Colors.transparent]),
                      border: Border.all(color: FantasyColors2.runeIce, width: 1.3),
                      boxShadow: [BoxShadow(color: FantasyColors2.runeIce.withOpacity(.5), blurRadius: 10)],
                    ),
                    child: FantasyIconFrame(type: FantasyIconType.systemRuneWizard, rarity: FantasyRarity.epic, size: 24, interactive: false),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.metMaTus ? tr('Ma-Túš, Runová svatyně', "Ma-Túš's Rune Sanctum") : tr('Runová svatyně', "Rune Sanctum"),
                      style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: .5),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: FantasyColors2.runeMuted,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [FantasyColors2.runeIce, Color(0xFF6FD8FF)]),
                  boxShadow: [BoxShadow(color: FantasyColors2.runeIce.withOpacity(.55), blurRadius: 10, spreadRadius: .5)],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                tabs: [
                  Tab(icon: const Icon(Icons.auto_awesome, size: 16), text: tr('Runy', 'Runes')),
                  Tab(icon: Icon(state.metMaTus ? Icons.auto_stories : Icons.lock, size: 16), text: state.metMaTus ? tr('Osudové volby', 'Fate Choices') : '???'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _statusPanel(state),
                      const SizedBox(height: 12),
                      _weeklyQuestPanel(state),
                      const SizedBox(height: 12),
                      _branchPanel(context, state, RuneBranch.defense, FantasyIconType.statShieldDef),
                      const SizedBox(height: 12),
                      _branchPanel(context, state, RuneBranch.offense, FantasyIconType.statSword),
                      const SizedBox(height: 12),
                      _branchPanel(context, state, RuneBranch.piercing, FantasyIconType.runeArmorPen),
                      const SizedBox(height: 12),
                      _slotsAndLibraryPanel(context, state),
                      const SizedBox(height: 12),
                    ],
                  ),
                  _osudoveVolbyTab(context, state),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ===== ZÁLOŽKA "OSUDOVÉ VOLBY" (Ma-Túš) =====
  // Fáze 1: jednorázové odemčení celé záložky za Dust. Fáze 2: mřížka 6 řádků × 3 sloupce -
  // každý řádek se odemyká zvlášť za Krystaly (postupně shora dolů), pak si hráč v odemčeném
  // řádku zvolí přesně jednu ze tří možností. Konkrétní obsah voleb (co sloupce znamenají) je
  // zatím placeholder - viz GameState.osudovaVolbaRowCosts.
  Widget _osudoveVolbyTab(BuildContext context, GameState state) {
    if (!state.metMaTus) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, color: FantasyColors2.runeMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              tr('Zatím neznámé.', 'Not yet known.'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FantasyColors2.runeText),
            ),
            const SizedBox(height: 8),
            Text(
              tr('Tahle cesta se odhalí, až vkročíš do Hardcore Mode.', 'This path will reveal itself once you step into Hardcore Mode.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: FantasyColors2.runeMuted),
            ),
          ],
        ),
      );
    }
    if (!state.osudoveVolbyUnlocked) {
      final canAfford = state.magicDust >= GameState.osudoveVolbyUnlockDustCost;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: RadialGradient(center: Alignment.topCenter, radius: 1.1, colors: [FantasyColors2.arcaneViolet.withOpacity(.18), Colors.transparent]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FantasyColors2.arcaneViolet.withOpacity(.5)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [FantasyColors2.arcaneViolet.withOpacity(.4), Colors.transparent]),
                      border: Border.all(color: FantasyColors2.arcaneViolet, width: 1.6),
                      boxShadow: [BoxShadow(color: FantasyColors2.arcaneViolet.withOpacity(.55), blurRadius: 24, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.auto_stories, color: FantasyColors2.arcaneViolet, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(tr('RUNY OSUDOVÉ VOLBY', 'RUNES OF FATE'), style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _panel(
              icon: Icons.menu_book,
              title: tr('MA-TÚŠOVA NABÍDKA', "MA-TÚŠ'S OFFER"),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      'Ma-Túš ti nabízí druhou cestu k moci, nezávislou na běžných talentech. Jednorázově odemkni tuto záložku a pak postupně odemykej jednotlivé řádky osudových voleb za Krystaly.',
                      'Ma-Túš offers you a second path to power, independent of the regular talents. Unlock this tab once, then gradually unlock individual rows of fate choices with Crystals.',
                    ),
                    style: const TextStyle(color: FantasyColors2.runeText, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: canAfford ? [BoxShadow(color: FantasyColors2.arcaneViolet.withOpacity(.55), blurRadius: 16, spreadRadius: 1)] : [],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAfford ? FantasyColors2.arcaneViolet : Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: canAfford ? state.unlockOsudoveVolby : null,
                        icon: Icon(Icons.lock_open, color: canAfford ? Colors.white : Colors.grey.shade500, size: 18),
                        label: Text(
                          tr('Odemknout (${GameState.osudoveVolbyUnlockDustCost} ✨ Dust)', 'Unlock (${GameState.osudoveVolbyUnlockDustCost} ✨ Dust)'),
                          style: TextStyle(color: canAfford ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: Text(tr('Máš: ${state.magicDust} ✨', 'You have: ${state.magicDust} ✨'), style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12))),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (int row = 0; row < GameState.osudovaVolbaRowCount; row++) ...[
            _osudovaVolbaRow(context, state, row),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  static const List<String> _osudovaVolbaRowNamesCz = ['DEFENZIVA', 'ÚTOK', 'UTILITY / ZDROJ', 'ZÁKLADNÍ ÚTOK ↔ SPELL', 'CLASS PASIVKA', 'SPEC RELIC'];
  static const List<String> _osudovaVolbaRowNamesEn = ['DEFENSE', 'OFFENSE', 'UTILITY / RESOURCE', 'BASIC ATTACK ↔ SPELL', 'CLASS PASSIVE', 'SPEC RELIC'];
  static const List<IconData> _osudovaVolbaRowIcons = [Icons.shield, Icons.gavel, Icons.bolt, Icons.swap_horiz, Icons.auto_awesome, Icons.diamond];

  Widget _osudovaVolbaRow(BuildContext context, GameState state, int row) {
    final unlocked = state.osudovaVolbaRowUnlocked[row];
    final canUnlock = !unlocked && (row == 0 || state.osudovaVolbaRowUnlocked[row - 1]);
    final cost = GameState.osudovaVolbaRowCosts[row];
    final chosen = state.osudovaVolbaChoice[row];
    return _panel(
      title: tr(_osudovaVolbaRowNamesCz[row], _osudovaVolbaRowNamesEn[row]),
      icon: unlocked ? _osudovaVolbaRowIcons[row] : Icons.lock,
      child: unlocked
          ? Row(
              children: [
                for (int col = 0; col < 3; col++) ...[
                  Expanded(child: _osudovaVolbaOption(state, row, col, chosen == col)),
                  if (col < 2) const SizedBox(width: 8),
                ],
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(canUnlock ? Icons.lock_open : Icons.lock, color: canUnlock ? FantasyColors2.arcaneViolet : Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      canUnlock
                          ? tr('Tři možnosti se odemknou spolu s tímto řádkem.', 'Three options unlock together with this row.')
                          : tr('Nejdřív odemkni předchozí řádek.', 'Unlock the previous row first.'),
                      style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: canUnlock ? [BoxShadow(color: FantasyColors2.arcaneViolet.withOpacity(.5), blurRadius: 10)] : [],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: canUnlock ? FantasyColors2.arcaneViolet : Colors.grey.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: canUnlock ? () => state.unlockOsudovaVolbaRow(row) : null,
                      child: Text(
                        canUnlock ? tr('Odemknout ($cost 💎)', 'Unlock ($cost 💎)') : tr('Zamčeno', 'Locked'),
                        style: TextStyle(color: canUnlock ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Placeholder karta jedné volby (sloupec) v řádku - Ondřej dodá skutečná jména/efekty voleb
  // později, teď jde jen o funkční UI: výběr, zvýraznění vybrané, přepnutí mezi třemi.
  Widget _osudovaVolbaOption(GameState state, int row, int col, bool selected) {
    final classTable = runeTalentTable[state.heroClass];
    final opt = classTable != null && row < classTable.length && col < classTable[row].length ? classTable[row][col] : null;
    final label = opt?.name ?? '?';
    final isChange = !selected && state.osudovaVolbaChoice[row] != -1;
    return GestureDetector(
      onLongPress: opt == null
          ? null
          : () => showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: const Color(0xFF0F1E28),
                  shape: RoundedRectangleBorder(side: const BorderSide(color: FantasyColors2.runeIce), borderRadius: BorderRadius.circular(10)),
                  title: Text(opt.name, style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold)),
                  content: Text(opt.description, style: const TextStyle(color: FantasyColors2.runeMuted)),
                  actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(tr('Zavřít', 'Close')))],
                ),
              ),
      onTap: () {
        if (!isChange) {
          state.chooseOsudovaVolba(row, col);
          return;
        }
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF0F1E28),
            shape: RoundedRectangleBorder(side: const BorderSide(color: FantasyColors2.runeIce), borderRadius: BorderRadius.circular(10)),
            title: Text(tr('Změnit volbu?', 'Change choice?'), style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold)),
            content: Text(
              tr('Přehození už zvolené volby v řádku ${row + 1} stojí ${GameState.osudovaVolbaChangeCost} 🪙 Zlata (máš: ${state.gold}).',
                  'Switching an already-made choice in row ${row + 1} costs ${GameState.osudovaVolbaChangeCost} 🪙 Gold (you have: ${state.gold}).'),
              style: const TextStyle(color: FantasyColors2.runeMuted),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(tr('Zrušit', 'Cancel'))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.runeIce),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  state.chooseOsudovaVolba(row, col);
                },
                child: Text(tr('Potvrdit', 'Confirm'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? FantasyColors2.runeIce.withOpacity(.18) : const Color(0xFF0F161E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? FantasyColors2.runeIce : const Color(0xFF23303C), width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: FantasyColors2.runeIce.withOpacity(.45), blurRadius: 10, spreadRadius: .5)] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? FantasyColors2.runeIce : const Color(0xFF5B6772), size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: selected ? FantasyColors2.runeText : FantasyColors2.runeMuted, fontSize: 10.5, fontWeight: FontWeight.bold, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({String? title, IconData? icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FantasyColors2.runePanel, Color(0xFF0E1B24)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FantasyColors2.runeIce.withOpacity(.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 10, offset: const Offset(0, 4)),
          BoxShadow(color: FantasyColors2.runeIce.withOpacity(.06), blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [FantasyColors2.runeIce.withOpacity(.14), Colors.transparent]),
                border: const Border(bottom: BorderSide(color: FantasyColors2.runeIce)),
              ),
              child: Row(children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [FantasyColors2.runeIce.withOpacity(.3), Colors.transparent]),
                      border: Border.all(color: FantasyColors2.runeIce.withOpacity(.7), width: 1),
                    ),
                    child: Icon(icon, color: FantasyColors2.runeIce, size: 14),
                  ),
                  const SizedBox(width: 9),
                ],
                Expanded(child: Text(title, style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12.5))),
              ]),
            ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) => Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: FantasyColors2.runeMuted)),
        ],
      );

  Widget _statusPanel(GameState state) {
    final progressInCycle = state.post20BossKills % 5;
    return _panel(
      title: tr('RUNOVÝ ČARODĚJ', 'RUNE WIZARD'),
      icon: Icons.auto_awesome,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statChip(tr('Mastery Lv.', 'Mastery Lv.'), '${state.runicMasteryLevel}', FantasyColors2.runeIce),
              _statChip(tr('Talent body', 'Talent points'), '${state.runeTalentPoints}', FantasyColors2.emberGold),
              _statChip(tr('Runové kameny', 'Rune Stones'), '${state.runeStones}', FantasyColors2.arcaneViolet),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(tr('Další talentový bod', 'Next talent point'), style: const TextStyle(fontSize: 11, color: FantasyColors2.runeMuted)),
              const Spacer(),
              Text(tr('$progressInCycle / 5 bossů', '$progressInCycle / 5 bosses'), style: const TextStyle(fontSize: 11, color: FantasyColors2.runeMuted, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressInCycle / 5,
              minHeight: 8,
              backgroundColor: const Color(0xFF1B2733),
              valueColor: const AlwaysStoppedAnimation(FantasyColors2.emberGold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => state.buyRuneStone(),
              style: OutlinedButton.styleFrom(foregroundColor: FantasyColors2.runeIce, side: const BorderSide(color: FantasyColors2.runeIce)),
              child: Text(tr('Koupit Runový kámen (${state.runeStoneCost} ✨ Magic Dust)', 'Buy Rune Stone (${state.runeStoneCost} ✨ Magic Dust)')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyQuestPanel(GameState state) {
    final ready = state.weeklyRuneBossKills >= state.weeklyRuneBossTarget && !state.weeklyRuneQuestClaimed;
    final progress = (state.weeklyRuneBossKills / state.weeklyRuneBossTarget).clamp(0.0, 1.0);
    return _panel(
      title: tr('TÝDENNÍ VÝZVA', 'WEEKLY CHALLENGE'),
      icon: Icons.calendar_month,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(tr('Poraz ${state.weeklyRuneBossTarget} bossů na patře 20+ tento týden', 'Defeat ${state.weeklyRuneBossTarget} bosses on floor 20+ this week'), style: const TextStyle(color: FantasyColors2.runeText)),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFF1B2733),
              valueColor: AlwaysStoppedAnimation(state.weeklyRuneQuestClaimed ? FantasyColors2.runeStone : FantasyColors2.runeIce),
            ),
          ),
          const SizedBox(height: 6),
          Text('${state.weeklyRuneBossKills} / ${state.weeklyRuneBossTarget}', style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12)),
          const SizedBox(height: 10),
          if (state.weeklyRuneQuestClaimed)
            Text(tr('✓ Odměna vyzvednuta', '✓ Reward claimed'), style: const TextStyle(color: Colors.greenAccent))
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ready ? () => state.claimWeeklyRuneQuest() : null,
                style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.runeIce, foregroundColor: Colors.black),
                child: Text(tr('Vyzvednout (+1 Runic Mastery Level)', 'Claim (+1 Runic Mastery Level)')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _branchPanel(BuildContext context, GameState state, RuneBranch branch, FantasyIconType headerIcon) {
    final nodes = RuneTree.branchNodes(branch);
    return _panel(
      title: branch.label.toUpperCase(),
      child: Column(children: [for (final node in nodes) _runeNodeRow(context, state, node)]),
    );
  }

  Widget _runeNodeRow(BuildContext context, GameState state, RuneNode node) {
    final unlocked = state.unlockedRuneNodeIds.contains(node.id);
    final canUnlock = state.canUnlockRuneNode(node);
    final activated = state.runeLibrary.contains(node.id);
    final masterCrafted = node.isMaster && state.masterRune != null && state.masterRune!.branch == node.branch;
    final equipped = state.weaponRuneSlots.contains(node.id) || (node.isMaster && state.weaponRuneSlots.contains('MASTER') && masterCrafted);

    final stateColor = unlocked ? FantasyColors2.runeIce : FantasyColors2.runeStone;
    final ready = activated || masterCrafted;

    return InkWell(
      onTap: () => _showRuneDetail(context, state, node),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0F161E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: stateColor.withOpacity(unlocked ? .8 : .3)),
        ),
        child: Row(
          children: [
            Icon(unlocked ? (ready ? Icons.check_circle : Icons.lock_open) : Icons.lock, color: stateColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${node.isMaster ? "★ " : ""}${node.name}',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: .6, color: unlocked ? FantasyColors2.runeText : const Color(0xFF5B6772)),
                  ),
                  Text(node.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: FantasyColors2.runeMuted)),
                ],
              ),
            ),
            if (canUnlock)
              const Icon(Icons.add_circle_outline, color: Colors.amber, size: 20)
            else if (equipped)
              const Icon(Icons.bolt, color: Colors.greenAccent, size: 18),
          ],
        ),
      ),
    );
  }

  void _showRuneDetail(BuildContext context, GameState state, RuneNode node) {
    final unlocked = state.unlockedRuneNodeIds.contains(node.id);
    final canUnlock = state.canUnlockRuneNode(node);
    final activated = state.runeLibrary.contains(node.id);
    final hasMatchingMaster = node.isMaster && state.masterRune != null && state.masterRune!.branch == node.branch;

    showModalBottomSheet(
      context: context,
      backgroundColor: FantasyColors2.runePanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${node.isMaster ? "★ Master runa: " : "Runa: "}${node.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FantasyColors2.runeText),
            ),
            const SizedBox(height: 6),
            Text(node.description, style: const TextStyle(color: FantasyColors2.runeMuted)),
            const SizedBox(height: 18),
            if (!unlocked)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canUnlock
                      ? () {
                          state.unlockRuneNode(node);
                          Navigator.pop(ctx);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.runeIce, foregroundColor: Colors.black),
                  child: Text(canUnlock ? tr('Odemknout (1 talentový bod)', 'Unlock (1 talent point)') : (node.tier == 1 ? tr('Nedostatek talentových bodů', 'Not enough talent points') : tr('Nejdřív odemkni předchozí úroveň', 'Unlock the previous tier first'))),
                ),
              )
            else if (node.isMaster) ...[
              if (!hasMatchingMaster)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.runeStones >= 4
                        ? () {
                            state.craftMasterRune(node.branch);
                            Navigator.pop(ctx);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.runeIce, foregroundColor: Colors.black),
                    child: Text(tr('Vytvořit Master runu (4 Runové kameny)', 'Craft Master Rune (4 Rune Stones)')),
                  ),
                )
              else ...[
                Text(tr('Aktivní efekty:', 'Active effects:'), style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold)),
                for (int i = 0; i < state.masterRune!.effects.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• ${state.masterRune!.effects[i].label}: +${(state.masterRune!.values[i] * 100).toStringAsFixed(1)} %', style: const TextStyle(color: FantasyColors2.runeMuted)),
                  ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.runicMasteryLevel >= 2 && state.runeStones >= state.masterRuneRerollCost
                          ? () {
                              state.rerollMasterRune();
                              Navigator.pop(ctx);
                            }
                          : null,
                      style: OutlinedButton.styleFrom(foregroundColor: FantasyColors2.runeIce, side: const BorderSide(color: FantasyColors2.runeIce)),
                      child: Text(state.runicMasteryLevel < 2 ? tr('Reroll (Mastery Lv. 2)', 'Reroll (Mastery Lv. 2)') : tr('Reroll (${state.masterRuneRerollCost} kameny)', 'Reroll (${state.masterRuneRerollCost} stones)')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showSlotPicker(context, state, 'MASTER');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.runeIce, foregroundColor: Colors.black),
                      child: Text(tr('Vsadit do zbraně', 'Socket into weapon')),
                    ),
                  ),
                ]),
              ],
            ] else ...[
              Text(tr('Efekt:', 'Effect:') + ' ${node.effectType.label} +${(node.value * 100).toStringAsFixed(1)} %', style: const TextStyle(color: FantasyColors2.runeMuted)),
              const SizedBox(height: 16),
              if (!activated)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.runeStones >= 1
                        ? () {
                            state.activateRune(node);
                            Navigator.pop(ctx);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.runeIce, foregroundColor: Colors.black),
                    child: Text(tr('Aktivovat runou (1 Runový kámen)', 'Activate with rune (1 Rune Stone)')),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSlotPicker(context, state, node.id);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.runeIce, foregroundColor: Colors.black),
                    child: Text(tr('Vsadit do zbraně', 'Socket into weapon')),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSlotPicker(BuildContext context, GameState state, String runeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FantasyColors2.runePanel,
        shape: RoundedRectangleBorder(side: BorderSide(color: FantasyColors2.runeIce.withOpacity(.5)), borderRadius: BorderRadius.circular(10)),
        title: Text(tr('Vyber slot ve zbrani', 'Choose a weapon slot'), style: const TextStyle(color: FantasyColors2.runeText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 3; i++)
              ListTile(
                enabled: i < state.unlockedRuneSlotCount,
                title: Text(
                  i < state.unlockedRuneSlotCount ? 'Slot ${i + 1}: ${_slotLabel(state.weaponRuneSlots[i])}' : tr('Slot ${i + 1}: zamčený', 'Slot ${i + 1}: locked'),
                  style: TextStyle(color: i < state.unlockedRuneSlotCount ? FantasyColors2.runeText : const Color(0xFF5B6772)),
                ),
                onTap: i < state.unlockedRuneSlotCount
                    ? () {
                        state.equipRune(i, runeId);
                        Navigator.pop(ctx);
                      }
                    : null,
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Zavřít', 'Close'), style: const TextStyle(color: FantasyColors2.runeMuted)))],
      ),
    );
  }

  String _slotLabel(String? id) {
    if (id == null) return tr('prázdný', 'empty');
    if (id == 'MASTER') return tr('★ Master runa', '★ Master rune');
    return RuneTree.byId(id)?.name ?? id;
  }

  Widget _slotsAndLibraryPanel(BuildContext context, GameState state) {
    return _panel(
      title: tr('RUNY VE ZBRANI', 'RUNES IN WEAPON'),
      icon: Icons.construction,
      child: Column(
        children: [
          for (int i = 0; i < 3; i++) _slotRow(state, i),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF23303C)),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(tr('Knihovna aktivovaných run', 'Library of activated runes'), style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: .6)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in state.runeLibrary)
                if (!state.weaponRuneSlots.contains(id))
                  ActionChip(
                    label: Text(RuneTree.byId(id)?.name ?? id),
                    backgroundColor: const Color(0xFF1B2733),
                    labelStyle: const TextStyle(color: FantasyColors2.runeText),
                    side: BorderSide(color: FantasyColors2.runeIce.withOpacity(.4)),
                    onPressed: () => _showSlotPicker(context, state, id),
                  ),
              if (state.masterRune != null && !state.weaponRuneSlots.contains('MASTER'))
                ActionChip(
                  label: Text('★ ${RuneTree.masterFor(state.masterRune!.branch).name}'),
                  backgroundColor: const Color(0xFF1B2733),
                  labelStyle: const TextStyle(color: Colors.amberAccent),
                  side: const BorderSide(color: Colors.amberAccent),
                  onPressed: () => _showSlotPicker(context, state, 'MASTER'),
                ),
              if (state.runeLibrary.isEmpty && state.masterRune == null)
                Text(tr('Zatím žádné aktivované runy.', 'No activated runes yet.'), style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slotRow(GameState state, int index) {
    final locked = index >= state.unlockedRuneSlotCount;
    final runeId = state.weaponRuneSlots[index];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0F161E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: locked ? const Color(0xFF23303C) : FantasyColors2.runeIce.withOpacity(.5)),
      ),
      child: Row(
        children: [
          Icon(locked ? Icons.lock : Icons.bolt, size: 16, color: locked ? const Color(0xFF4A5563) : FantasyColors2.runeIce),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Slot ${index + 1}: ${locked ? tr("zamčený", "locked") : _slotLabel(runeId)}',
              style: TextStyle(color: locked ? const Color(0xFF5B6772) : FantasyColors2.runeText),
            ),
          ),
          if (!locked && runeId != null) IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => state.unequipRune(index)),
        ],
      ),
    );
  }
}


/// Obrazovka Runového kováře - kove JEDNU unikátní artefaktovou zbraň pro aktuální
/// (třídu, specializaci) hráče. Vyžaduje odemčenou specializaci. Vizuálně sdílí paletu
/// s Runovým čarodějem (ledově modrá/kamenná), ale je to samostatný systém - čaroděj řeší
/// runy a jejich osazení, kovář řeší tuhle jednu unikátní zbraň.
class RuneBlacksmithScreen extends StatelessWidget {
  const RuneBlacksmithScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      final def = state.activeArtifactWeaponDef;
      final crafted = state.hasCraftedActiveArtifactWeapon;
      final canAfford = state.magicDust >= GameState.artifactWeaponDustCost &&
          state.legendaryEssence >= state.currentArtifactWeaponEssenceCost &&
          state.materials >= GameState.artifactWeaponMaterialsCost;
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [Color(0xFF14212B), FantasyColors2.obsidian]),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  FantasyIconFrame(type: FantasyIconType.systemForge, rarity: FantasyRarity.artifact, size: 72, interactive: false),
                  const SizedBox(height: 10),
                  Text(tr('Runový Kovář', 'Rune Blacksmith'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FantasyColors2.runeText, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    tr('Vykove jedinou unikátní zbraň na úrovni artefaktu, spjatou s tvou zvolenou specializací.', 'Forges a single unique artifact-tier weapon, tied to your chosen specialization.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: FantasyColors2.runeMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (def == null)
              FantasyPanel(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    tr('Nejprve si zvol specializaci u své třídy - Runový kovář bez ní neví, jakou zbraň kovat.', 'First choose a specialization for your class - the Rune Blacksmith needs it to know which weapon to forge.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: FantasyColors2.runeMuted),
                  ),
                ),
              )
            else
              FantasyPanel(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(def.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF1744))),
                      const SizedBox(height: 4),
                      Text(def.description, style: const TextStyle(color: FantasyColors2.runeMuted, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                      if (crafted)
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                            const SizedBox(width: 6),
                            Text(tr('Už vykováno - najdeš ji ve svém inventáři.', 'Already forged - you can find it in your inventory.'), style: const TextStyle(color: Colors.greenAccent)),
                          ],
                        )
                      else ...[
                        Text(
                          tr('Cena: ${GameState.artifactWeaponDustCost} ✨ Dust, ${state.currentArtifactWeaponEssenceCost} 🔥 Esence${state.craftedArtifactWeaponIds.isNotEmpty ? ' (poloviční - první zbraň už máš vykovanou)' : ''}, ${GameState.artifactWeaponMaterialsCost} ⚒️ Surovin', 'Price: ${GameState.artifactWeaponDustCost} ✨ Dust, ${state.currentArtifactWeaponEssenceCost} 🔥 Essence${state.craftedArtifactWeaponIds.isNotEmpty ? ' (half - you already forged your first weapon)' : ''}, ${GameState.artifactWeaponMaterialsCost} ⚒️ Materials'),
                          style: TextStyle(color: canAfford ? FantasyColors2.runeText : Colors.redAccent),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('Máš: ${state.magicDust} ✨ Dust, ${state.legendaryEssence} 🔥 Esence, ${state.materials} ⚒️ Surovin', 'You have: ${state.magicDust} ✨ Dust, ${state.legendaryEssence} 🔥 Essence, ${state.materials} ⚒️ Materials'),
                          style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1744), padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: canAfford ? state.craftArtifactWeapon : null,
                            child: Text(tr('Vykovat unikátní zbraň', 'Forge unique weapon')),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (def != null && crafted) _artifactForgePanel(context, state),
            const SizedBox(height: 24),
            if (def != null && crafted) ...[
              Text(tr('Runy v artefaktu', 'Runes in the artifact'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FantasyColors2.runeText)),
              const SizedBox(height: 4),
              Text(
                tr('Sem jde vsadit KAŽDÁ už odemčená runa u Runového čaroděje - na rozdíl od běžné zbraně tu netřeba Runový kámen na výrobu. Runy i strom schopností dole platí jen dokud máš artefakt skutečně nasazený (ne jinou zbraň).', 'Any rune already unlocked at the Rune Wizard can be socketed here - unlike a regular weapon, no Rune Stone is needed to craft it. The runes and the skill tree below only apply while the artifact is actually equipped (not another weapon).'),
                style: TextStyle(color: FantasyColors2.runeMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < state.artifactRuneSlots.length; i++) _artifactRuneSlotRow(context, state, i),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr('Strom schopností zbraně', 'Weapon skill tree'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FantasyColors2.runeText)),
                  Text(
                    tr('Další uzel: ${state.nextWeaponSkillNodeCost} 🔥', 'Next node: ${state.nextWeaponSkillNodeCost} 🔥'),
                    style: TextStyle(color: state.legendaryEssence >= state.nextWeaponSkillNodeCost ? Colors.amber : Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tr('Neutrální větev jde odemykat hned. Gemové větve (Jed/Oživení/.../Odraz) navíc vyžadují Hardcore Mode a odpovídající gem fyzicky vsazený v Prstenu Osudu. Cena uzlu roste s každým odemčeným (10, 15, 20...). Máš: ${state.legendaryEssence} 🔥 Esence.', 'The Neutral branch can be unlocked right away. Gem branches (Poison/Revival/.../Reflect) additionally require Hardcore Mode and the matching gem physically socketed in the Ring of Fate. Node cost rises with each unlock (10, 15, 20...). You have: ${state.legendaryEssence} 🔥 Essence.'),
                style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              for (final branch in WeaponSkillBranch.values) _weaponSkillBranchPanel(context, state, branch),
            ] else if (def != null && !crafted)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  tr('Runy do artefaktu a strom schopností se odemknou, jakmile vykováš unikátní zbraň výše.', 'Runes for the artifact and the skill tree unlock once you forge the unique weapon above.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FantasyColors2.runeMuted, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ===== VYLEPŠENÍ ARTEFAKTOVÉ ZBRANĚ (obětování silnější zbraně z batohu + 1000 Surovin) =====
  Widget _artifactForgePanel(BuildContext context, GameState state) {
    final artifact = state.equippedArtifactWeapon;
    final candidates = state.artifactForgeCandidates;
    return FantasyPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Vylepšit artefaktovou zbraň', 'Upgrade the artifact weapon'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FantasyColors2.runeText)),
            const SizedBox(height: 4),
            Text(
              tr('Obětuj z batohu zbraň, která je silnější než tvůj artefakt (+ ${GameState.artifactForgeMaterialsCost} ⚒️ Surovin) - zbraň se zničí, artefakt dostane +1 Forge úroveň (+5 % ke statům). Bez stropu - artefakt tak zůstane VŽDY tvá nejsilnější zbraň.', 'Sacrifice a weapon from your bag that is stronger than your artifact (+ ${GameState.artifactForgeMaterialsCost} ⚒️ Materials) - the weapon is destroyed, the artifact gains +1 Forge level (+5% to stats). No cap - the artifact will ALWAYS stay your strongest weapon.'),
              style: TextStyle(color: FantasyColors2.runeMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (artifact == null)
              Text(tr('Nejprve si nasaď svou artefaktovou zbraň.', 'First equip your artifact weapon.'), style: const TextStyle(color: Colors.redAccent, fontSize: 12))
            else ...[
              Text(tr('Aktuální Forge úroveň: ${artifact.artifactWeaponForgeLevel} (+${(artifact.artifactWeaponForgeLevel * Item.artifactForgeBonusPerLevel * 100).round()} % ke statům)', 'Current Forge level: ${artifact.artifactWeaponForgeLevel} (+${(artifact.artifactWeaponForgeLevel * Item.artifactForgeBonusPerLevel * 100).round()}% to stats)'),
                  style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(tr('Máš: ${state.materials} ⚒️ Surovin', 'You have: ${state.materials} ⚒️ Materials'), style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12)),
              const SizedBox(height: 10),
              if (candidates.isEmpty)
                Text(tr('V batohu nemáš žádnou zbraň silnější než tvůj artefakt.', 'You have no weapon in your bag stronger than your artifact.'), style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12, fontStyle: FontStyle.italic))
              else
                for (final w in candidates)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF0F161E), borderRadius: BorderRadius.circular(8), border: Border.all(color: FantasyColors2.runeIce.withOpacity(.5))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(w.name, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1744), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          onPressed: state.materials >= GameState.artifactForgeMaterialsCost ? () => state.forgeArtifactWeapon(w.id) : null,
                          child: Text(tr('Obětovat', 'Sacrifice'), style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _artifactRuneSlotRow(BuildContext context, GameState state, int index) {
    final runeId = state.artifactRuneSlots[index];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0F161E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FantasyColors2.runeIce.withOpacity(.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, size: 16, color: FantasyColors2.runeIce),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Slot ${index + 1}: ${_artifactSlotLabel(runeId)}', style: const TextStyle(color: FantasyColors2.runeText)),
          ),
          if (runeId != null)
            IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => state.unequipArtifactRune(index))
          else
            TextButton(onPressed: () => _showArtifactRunePicker(context, state, index), child: Text(tr('Vybrat', 'Select'))),
        ],
      ),
    );
  }

  String _artifactSlotLabel(String? id) {
    if (id == null) return tr('prázdný', 'empty');
    if (id == 'MASTER') return tr('★ Master runa', '★ Master rune');
    return RuneTree.byId(id)?.name ?? id;
  }

  void _showArtifactRunePicker(BuildContext context, GameState state, int slot) {
    final options = state.unlockedRuneNodeIds.where((id) => RuneTree.byId(id) != null).toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FantasyColors2.runePanel,
        shape: RoundedRectangleBorder(side: BorderSide(color: FantasyColors2.runeIce.withOpacity(.5)), borderRadius: BorderRadius.circular(10)),
        title: Text(tr('Vyber odemčenou runu', 'Choose an unlocked rune'), style: const TextStyle(color: FantasyColors2.runeText)),
        content: SizedBox(
          width: double.maxFinite,
          child: options.isEmpty && state.masterRune == null
              ? Text(tr('Zatím nemáš odemčenou žádnou runu u Runového čaroděje.', 'You have no runes unlocked at the Rune Wizard yet.'), style: const TextStyle(color: FantasyColors2.runeMuted))
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final id in options)
                      ListTile(
                        title: Text(RuneTree.byId(id)?.name ?? id, style: const TextStyle(color: FantasyColors2.runeText)),
                        subtitle: Text(RuneTree.byId(id)?.description ?? '', style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 11)),
                        onTap: () {
                          state.equipArtifactRune(slot, id);
                          Navigator.pop(ctx);
                        },
                      ),
                    if (state.masterRune != null)
                      ListTile(
                        title: Text('★ ${RuneTree.masterFor(state.masterRune!.branch).name}', style: const TextStyle(color: FantasyColors2.runeText)),
                        subtitle: Text(tr('Master runa', 'Master rune'), style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 11)),
                        onTap: () {
                          state.equipArtifactRune(slot, 'MASTER');
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Zavřít', 'Close'), style: const TextStyle(color: FantasyColors2.runeMuted)))],
      ),
    );
  }

  Widget _weaponSkillBranchPanel(BuildContext context, GameState state, WeaponSkillBranch branch) {
    final nodes = WeaponSkillTree.branchNodes(branch);
    final isGemBranch = branch != WeaponSkillBranch.neutral;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FantasyPanel(
        title: branch.label.toUpperCase(),
        accent: FantasyColors2.runeIce,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isGemBranch)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  tr('Odemykání vyžaduje Hardcore Mode + odpovídající gem v Prstenu. Platí jen nejvyšší odemčený tier (upgrade, ne součet) - posiluje sílu odpovídajícího gemu, jen když je zrovna aktivní.', 'Unlocking requires Hardcore Mode + the matching gem in the Ring. Only the highest unlocked tier applies (upgrade, not additive) - it boosts the strength of the matching gem, only while it is currently active.'),
                  style: TextStyle(color: FantasyColors2.runeMuted, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            for (final node in nodes) _weaponSkillNodeRow(context, state, node),
          ],
        ),
      ),
    );
  }

  Widget _weaponSkillNodeRow(BuildContext context, GameState state, WeaponSkillNode node) {
    final unlocked = state.unlockedWeaponSkillNodeIds.contains(node.id);
    final canUnlock = state.canUnlockWeaponSkillNode(node);
    final isNeutralMaster = node.isMaster && node.branch == WeaponSkillBranch.neutral;
    final isGemMaster = node.isMaster && !isNeutralMaster;
    final stateColor = unlocked ? FantasyColors2.runeIce : FantasyColors2.runeStone;
    return InkWell(
      onTap: canUnlock
          ? () => state.unlockWeaponSkillNode(node)
          : (isNeutralMaster && unlocked
              ? () => _showArtifactMasterRuneDialog(context, state)
              : (isGemMaster && unlocked ? () => _showGemMasterSynergyDialog(context, state, node) : null)),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0F161E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (node.isMaster ? Colors.amber : stateColor).withOpacity(unlocked ? .8 : .3)),
        ),
        child: Row(
          children: [
            Icon(
              unlocked ? (isNeutralMaster ? (state.artifactMasterRune != null ? Icons.auto_awesome : Icons.build) : (node.isMaster ? Icons.hourglass_empty : Icons.check_circle)) : Icons.lock,
              color: node.isMaster && unlocked ? Colors.amber : stateColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${node.isMaster ? "★ " : ""}${node.name}',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: .6, color: unlocked ? FantasyColors2.runeText : const Color(0xFF5B6772)),
                  ),
                  Text(
                    isNeutralMaster && unlocked && state.artifactMasterRune != null
                        ? tr('Vykováno: ${state.artifactMasterRune!.effects.map((e) => e.label).join(', ')}', 'Forged: ${state.artifactMasterRune!.effects.map((e) => e.label).join(', ')}')
                        : node.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: FantasyColors2.runeMuted),
                  ),
                ],
              ),
            ),
            if (canUnlock)
              const Icon(Icons.add_circle_outline, color: Colors.amber, size: 20)
            else if (node.isMaster && unlocked)
              const Icon(Icons.touch_app, color: Colors.amber, size: 18),
          ],
        ),
      ),
    );
  }

  void _showGemMasterSynergyDialog(BuildContext context, GameState state, WeaponSkillNode node) {
    final gemName = _gemBranchDisplayName(node.branch);
    final classEffect = _gemSynergyEffectText(node.branch, state.heroClass);
    final hasArtifact = state.equippedWeapon?.isArtifact == true;
    final hasRing = state.equipment.any((i) => i.isArtifact && i.slot == EquipSlot.ring);
    final hasGem = gemName.isNotEmpty && state.gemCountOf(gemName) > 0;
    final active = hasArtifact && hasRing && hasGem;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FantasyColors2.runePanel,
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(10)),
        title: Text('★ ${node.name}', style: const TextStyle(color: FantasyColors2.runeText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Synergie: $gemName × tato Master runa × tvá třída.\nPodmínka: nasazený artefakt (zbraň), nasazený Prsten Osudu s alespoň 1 kusem "$gemName" fyzicky vsazeným (nemusí být aktivní gem) a tento uzel odemčený.', 'Synergy: $gemName × this Master rune × your class.\nRequirement: artifact (weapon) equipped, Ring of Fate equipped with at least 1 piece of "$gemName" physically socketed (does not need to be the active gem), and this node unlocked.'),
              style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(tr('Tvá třída (${state.heroClass.name.toUpperCase()}):', 'Your class (${state.heroClass.name.toUpperCase()}):'), style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold)),
            Text(classEffect.isEmpty ? tr('Efekt se doplní po volbě třídy.', 'The effect will appear once you choose a class.') : classEffect, style: const TextStyle(color: FantasyColors2.runeMuted)),
            const SizedBox(height: 10),
            Row(children: [
              Icon(active ? Icons.check_circle : Icons.info_outline, color: active ? Colors.greenAccent : Colors.grey, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(active ? tr('Synergie je právě aktivní.', 'Synergy is currently active.') : tr('Synergie zatím neaktivní - chybí artefakt zbraň, Prsten Osudu, nebo $gemName vsazený v Prstenu.', 'Synergy not active yet - missing the artifact weapon, Ring of Fate, or $gemName socketed in the Ring.'), style: TextStyle(color: active ? Colors.greenAccent : Colors.grey, fontSize: 12))),
            ]),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Zavřít', 'Close'), style: const TextStyle(color: FantasyColors2.runeMuted)))],
      ),
    );
  }

  String _gemBranchDisplayName(WeaponSkillBranch b) {
    switch (b) {
      case WeaponSkillBranch.poison: return "Gem Jedu";
      case WeaponSkillBranch.revival: return "Gem Oživení";
      case WeaponSkillBranch.darkness: return "Gem Temnoty";
      case WeaponSkillBranch.bloodbath: return "Gem Krvavé lázně";
      case WeaponSkillBranch.fragmentation: return "Gem Roztříštění";
      case WeaponSkillBranch.reflection: return "Gem Odrazu";
      default: return "";
    }
  }

  String _gemSynergyEffectText(WeaponSkillBranch b, HeroClass c) {
    final warriorLike = c == HeroClass.warrior || c == HeroClass.duelist;
    final healLike = c == HeroClass.monk || c == HeroClass.healer;
    final casterLike = c == HeroClass.mage || c == HeroClass.deathknight;
    switch (b) {
      case WeaponSkillBranch.poison:
        if (warriorLike) return "Otrávené ostří: " + tr("při každém zásahu uvalíš fyzický DoT (20 % P.Atk, 2 kola).", "on every hit you apply a physical DoT (20% P.Atk, 2 rounds).");
        if (casterLike) return "Temný mor: " + tr("při každém zásahu uvalíš magický DoT (20 % M.Atk, 2 kola).", "on every hit you apply a magic DoT (20% M.Atk, 2 rounds).");
        if (c == HeroClass.hunter) return "Jedový hrot: " + tr("při každém zásahu uvalíš DoT (30 % P.Atk, 1 kolo).", "on every hit you apply a DoT (30% P.Atk, 1 round).");
        if (healLike) return "Neutralizace jedu: " + tr("každý tvůj heal/lifesteal z tebe navíc odstraní jed.", "every heal/lifesteal of yours additionally removes poison.");
        if (c == HeroClass.druid) return "Trní rozkladu: " + tr("při každém zásahu uvalíš DoT (25 % M.Atk, 3 kola).", "on every hit you apply a DoT (25% M.Atk, 3 rounds).");
        if (c == HeroClass.paladin) return "Svaté spálení: " + tr("při každém zásahu uvalíš DoT (20 % M.Atk, 2 kola).", "on every hit you apply a DoT (20% M.Atk, 2 rounds).");
        if (c == HeroClass.demonhunter) return "Fel oheň: " + tr("při každém zásahu uvalíš DoT (25 % P.Atk, 2 kola).", "on every hit you apply a DoT (25% P.Atk, 2 rounds).");
        if (c == HeroClass.necromancer) return "Morová kletba: " + tr("při každém zásahu uvalíš DoT (28 % M.Atk, 3 kola).", "on every hit you apply a DoT (28% M.Atk, 3 rounds).");
        return "";
      case WeaponSkillBranch.bloodbath:
        if (warriorLike) return "Poprava: " + tr("proti cíli pod 30 % HP +25 % dmg.", "against targets below 30% HP, +25% dmg.");
        if (healLike) return "Dorážející milost: " + tr("proti cíli pod 30 % HP se vyléčíš o 15 % M.Atk.", "against targets below 30% HP, you heal for 15% M.Atk.");
        if (casterLike) return "Temný dozvuk: " + tr("proti cíli pod 30 % HP +25 % dmg.", "against targets below 30% HP, +25% dmg.");
        if (c == HeroClass.hunter) return "Lovecký instinkt: " + tr("proti cíli pod 30 % HP +25 % dmg.", "against targets below 30% HP, +25% dmg.");
        if (c == HeroClass.druid) return "Divoký hlad: " + tr("proti cíli pod 30 % HP +15 % dmg a heal 5 % M.Atk.", "against targets below 30% HP, +15% dmg and heal 5% M.Atk.");
        if (c == HeroClass.paladin) return "Boží soud: " + tr("proti cíli pod 30 % HP +25 % dmg.", "against targets below 30% HP, +25% dmg.");
        if (c == HeroClass.demonhunter) return "Rozsudek Zkázy: " + tr("proti cíli pod 30 % HP +25 % dmg.", "against targets below 30% HP, +25% dmg.");
        if (c == HeroClass.necromancer) return "Hostina duší: " + tr("proti cíli pod 30 % HP +20 % dmg a heal 8 % ze způsobeného dmg.", "against targets below 30% HP, +20% dmg and heal 8% of damage dealt.");
        return "";
      case WeaponSkillBranch.fragmentation:
        if (warriorLike) return "Zesílená ozvěna: " + tr("echo zásah gemu +15 % dmg.", "the gem's echo hit +15% dmg.");
        if (healLike) return "Ozvěna léčení: " + tr("echo zásah tě vyléčí o 10 % M.Atk.", "the echo hit heals you for 10% M.Atk.");
        if (casterLike) return "Dvojitý dozvuk: " + tr("echo zásah gemu +20 % dmg.", "the gem's echo hit +20% dmg.");
        if (c == HeroClass.hunter) return "Volný šíp: " + tr("echo zásah gemu +20 % dmg.", "the gem's echo hit +20% dmg.");
        if (c == HeroClass.druid) return "Šeptající kořeny: " + tr("echo zásah navíc uvalí slabý DoT.", "the echo hit additionally applies a weak DoT.");
        if (c == HeroClass.paladin) return "Ozvěna světla: " + tr("echo zásah gemu +15 % dmg.", "the gem's echo hit +15% dmg.");
        if (c == HeroClass.demonhunter) return "Šířící se zkáza: " + tr("echo zásah gemu +15 % dmg.", "the gem's echo hit +15% dmg.");
        if (c == HeroClass.necromancer) return "Rozkaz sluhovi: " + tr("echo zásah přidá +20 % dmg navíc.", "the echo hit adds an extra +20% dmg.");
        return "";
      case WeaponSkillBranch.reflection:
        if (warriorLike) return "Odrazový štít: " + tr("po odražení dmg +10 % šance na blok (2 kola).", "after reflecting damage, +10% chance to block (2 rounds).");
        if (healLike) return "Odražené milosrdenství: " + tr("vyléčíš se o 30 % odraženého dmg.", "you heal for 30% of the reflected damage.");
        if (casterLike) return "Zrcadlový mor: " + tr("odražený dmg navíc uvalí DoT (50 % odraženého dmg, 2 kola).", "the reflected damage additionally applies a DoT (50% of reflected dmg, 2 rounds).");
        if (c == HeroClass.hunter) return "Protistřela: " + tr("navíc udělíš 25 % P.Atk dmg.", "you additionally deal 25% P.Atk dmg.");
        if (c == HeroClass.druid) return "Kůra stromu: " + tr("50 % odraženého dmg se navíc promění ve štít.", "50% of the reflected damage is additionally converted into a shield.");
        if (c == HeroClass.paladin) return "Val víry: " + tr("+10 % šance na blok (2 kola).", "+10% chance to block (2 rounds).");
        if (c == HeroClass.demonhunter) return "Fel odolnost: " + tr("navíc udělíš 25 % P.Atk dmg.", "you additionally deal 25% P.Atk dmg.");
        if (c == HeroClass.necromancer) return "Nekrotická odolnost: " + tr("+10 % redukce poškození (2 kola).", "+10% damage reduction (2 rounds).");
        return "";
      case WeaponSkillBranch.revival:
        if (warriorLike) return "Bojový vztek: " + tr("příští útok +50 % kritické poškození.", "next attack +50% critical damage.");
        if (healLike) return "Vlna obnovy: " + tr("navíc se vyléčíš o 20 % M.Atk.", "you additionally heal for 20% M.Atk.");
        if (casterLike) return "Nouzový štít: " + tr("získáš štít 30 % M.Atk (2 kola).", "you gain a shield of 30% M.Atk (2 rounds).");
        if (c == HeroClass.hunter) return "Druhý dech: " + tr("volný výstřel za 50 % P.Atk dmg.", "a free shot for 50% P.Atk dmg.");
        if (c == HeroClass.druid) return "Srdce pralesa: " + tr("navíc získáš štít 10 % max HP.", "you additionally gain a shield of 10% max HP.");
        if (c == HeroClass.paladin) return "Nezdolná hradba: " + tr("navíc získáš štít 10 % max HP.", "you additionally gain a shield of 10% max HP.");
        if (c == HeroClass.demonhunter) return "Nesmrtelná Pomsta: " + tr("lifesteal je na 2 kola zdvojnásoben.", "lifesteal is doubled for 2 rounds.");
        if (c == HeroClass.necromancer) return "Vládce Kostí: " + tr("sluha vstřebá dmg jako štít (30 % M.Atk).", "the servant absorbs damage as a shield (30% M.Atk).");
        return "";
      case WeaponSkillBranch.darkness:
        if (warriorLike) return "Temný nádech: " + tr("každý zásah tě vyléčí o 10 % způsobeného dmg.", "every hit heals you for 10% of damage dealt.");
        if (casterLike) return "Temné sání: " + tr("každý zásah tě vyléčí o 8 % způsobeného dmg.", "every hit heals you for 8% of damage dealt.");
        if (c == HeroClass.hunter) return "Značka temnoty: " + tr("zásah tě vyléčí o 5 % dmg za každý stack Hunter's Mark.", "a hit heals you for 5% dmg per Hunter's Mark stack.");
        if (healLike) return "Temný závoj: " + tr("25 % z každého healu/lifestealu se navíc promění ve štít.", "25% of every heal/lifesteal is additionally converted into a shield.");
        if (c == HeroClass.druid) return "Symbióza: " + tr("15 % z každého healu/lifestealu se navíc promění ve štít.", "15% of every heal/lifesteal is additionally converted into a shield.");
        if (c == HeroClass.paladin) return "Světlo v temnotě: " + tr("15 % z každého healu/lifestealu se navíc promění ve štít.", "15% of every heal/lifesteal is additionally converted into a shield.");
        if (c == HeroClass.demonhunter) return "Fel hlad: " + tr("každý zásah tě vyléčí o 9 % způsobeného dmg.", "every hit heals you for 9% of damage dealt.");
        if (c == HeroClass.necromancer) return "Krvavý pakt: " + tr("každý zásah tě vyléčí o 9 % způsobeného dmg.", "every hit heals you for 9% of damage dealt.");
        return "";
      default:
        return "";
    }
  }

  void _showArtifactMasterRuneDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FantasyColors2.runePanel,
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(10)),
        title: Text(tr('★ Artefaktová Master runa', '★ Artifact Master Rune'), style: const TextStyle(color: FantasyColors2.runeText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Dva náhodné efekty ze VŠECH běžných run Runového čaroděje (napříč obrannou, útočnou i průraznou větví), o 50 % silnější.', 'Two random effects from ALL regular Rune Wizard runes (across the defense, offense, and piercing branches), 50% stronger.'),
              style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            if (state.artifactMasterRune != null) ...[
              Text(tr('Aktuální efekty:', 'Current effects:'), style: const TextStyle(color: FantasyColors2.runeText, fontWeight: FontWeight.bold)),
              for (int i = 0; i < state.artifactMasterRune!.effects.length; i++)
                Text('• ${state.artifactMasterRune!.effects[i].label}: +${(state.artifactMasterRune!.values[i] * 100).toStringAsFixed(1)} %', style: const TextStyle(color: FantasyColors2.runeMuted)),
              const SizedBox(height: 10),
            ],
            Text(tr('Cena: 6 Runové kameny (máš ${state.runeStones}).', 'Price: 6 Rune Stones (you have ${state.runeStones}).'), style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 12)),
          ],
        ),
        actions: [
          if (state.artifactMasterRune != null)
            TextButton(
              onPressed: state.runeStones >= 6 ? () { state.rerollArtifactMasterRune(); Navigator.pop(ctx); } : null,
              child: Text(tr('Reroll (6 kamenů)', 'Reroll (6 stones)')),
            ),
          ElevatedButton(
            onPressed: state.runeStones >= 6 ? () { state.craftArtifactMasterRune(); Navigator.pop(ctx); } : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: Text(state.artifactMasterRune == null ? tr('Vykovat', 'Forge') : tr('Vykovat znovu', 'Re-forge')),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Zavřít', 'Close'), style: const TextStyle(color: FantasyColors2.runeMuted))),
        ],
      ),
    );
  }
}


// =============================================================================
// SPELL VISUALS — jméno/ikona/barva pro každý spell podle třídy a tieru.
// Extrahováno z textů zpráv v useActiveAbility/useSecondAbility/useThirdAbility/
// useFourthAbility, aby ikonková tlačítka všude ve hře ukazovala konzistentní,
// tematicky sedící ikonu místo generického "Schopnost 1/2/3/4".
// =============================================================================
class SpellVisual {
  final String name;
  final IconData icon;
  final Color color;
  const SpellVisual(this.name, this.icon, this.color);
}

// Jednotná signální barva pro danou třídu — používá se pro VŠECHNY její
// spell sloty (základní útok, tier1-4), aby tlačítka schopností na jedné
// postavě měla konzistentní barevné téma místo pestré škály barev.
Color classSignatureColor(HeroClass c) {
  switch (c) {
    case HeroClass.warrior: return const Color(0xFFE64A19);
    case HeroClass.hunter: return const Color(0xFF558B2F);
    case HeroClass.healer: return const Color(0xFFFFA000);
    case HeroClass.deathknight: return const Color(0xFF29B6F6);
    case HeroClass.mage: return const Color(0xFFAB47BC);
    case HeroClass.duelist: return const Color(0xFFB0BEC5);
    case HeroClass.monk: return const Color(0xFFFF8A65);
    case HeroClass.druid: return const Color(0xFF26A69A);
    case HeroClass.paladin: return const Color(0xFFFFD700);
    case HeroClass.demonhunter: return const Color(0xFF7B2FBE);
    case HeroClass.necromancer: return const Color(0xFF8E24AA);
    default: return Colors.grey;
  }
}

// Tier 1 — Paragon 10, "Pokročilá třída" (isBerserk/isAssassin/...).
SpellVisual spellVisualTier1(HeroClass c) {
  switch (c) {
    case HeroClass.warrior: return SpellVisual('Mocný úder', Icons.fitness_center, classSignatureColor(HeroClass.warrior));
    case HeroClass.hunter: return SpellVisual('Skrytý úder', Icons.visibility_off, classSignatureColor(HeroClass.hunter));
    case HeroClass.healer: return SpellVisual('Boží požehnání', Icons.wb_sunny, classSignatureColor(HeroClass.healer));
    case HeroClass.deathknight: return SpellVisual('Prokletý úder', Icons.dark_mode, classSignatureColor(HeroClass.deathknight));
    case HeroClass.mage: return SpellVisual('Elementální výbuch', Icons.local_fire_department, classSignatureColor(HeroClass.mage));
    case HeroClass.duelist: return SpellVisual('Rychlé combo', Icons.flash_on, classSignatureColor(HeroClass.duelist));
    case HeroClass.monk: return SpellVisual('Úder tisíce dlaní', Icons.sports_martial_arts, classSignatureColor(HeroClass.monk));
    case HeroClass.druid: return SpellVisual('Divoký spár', Icons.eco, classSignatureColor(HeroClass.druid));
    case HeroClass.paladin: return SpellVisual('Úder Spravedlnosti', Icons.gavel, classSignatureColor(HeroClass.paladin));
    case HeroClass.demonhunter: return SpellVisual('Rozseknutí čepelemi', Icons.content_cut, classSignatureColor(HeroClass.demonhunter));
    case HeroClass.necromancer: return SpellVisual('Kostěný Sluha', Icons.person_outline, classSignatureColor(HeroClass.necromancer));
    default: return const SpellVisual('Schopnost 1', Icons.auto_awesome, Colors.grey);
  }
}

// Tier 2 — Paragon 40, "Ultimátní třída" (isWarlord/isShadowMaster/...).
SpellVisual spellVisualTier2(HeroClass c) {
  switch (c) {
    case HeroClass.warrior: return SpellVisual('Rozdrcení světa', Icons.public, classSignatureColor(HeroClass.warrior));
    case HeroClass.hunter: return SpellVisual('Stínová poprava', Icons.gps_fixed, classSignatureColor(HeroClass.hunter));
    case HeroClass.healer: return SpellVisual('Boží soud', Icons.gavel, classSignatureColor(HeroClass.healer));
    case HeroClass.deathknight: return SpellVisual('Exploze prokletí', Icons.whatshot, classSignatureColor(HeroClass.deathknight));
    case HeroClass.mage: return SpellVisual('Arkánový nával', Icons.blur_on, classSignatureColor(HeroClass.mage));
    case HeroClass.duelist: return SpellVisual('Precizní výpad', Icons.gps_not_fixed, classSignatureColor(HeroClass.duelist));
    case HeroClass.monk: return SpellVisual('Dračí kop', Icons.sports_kabaddi, classSignatureColor(HeroClass.monk));
    case HeroClass.druid: return SpellVisual('Hvězdný pád', Icons.nightlight_round, classSignatureColor(HeroClass.druid));
    case HeroClass.paladin: return SpellVisual('Boží Trest', Icons.flash_on, classSignatureColor(HeroClass.paladin));
    case HeroClass.demonhunter: return SpellVisual('Metamorfóza', Icons.auto_fix_high, classSignatureColor(HeroClass.demonhunter));
    case HeroClass.necromancer: return SpellVisual('Volání Nemrtvých', Icons.groups, classSignatureColor(HeroClass.necromancer));
    default: return const SpellVisual('Schopnost 2', Icons.auto_awesome, Colors.grey);
  }
}

// Tier 3 — Paragon 75, "Boží třída" (isValhallaWarrior/isVoidStalker/...).
SpellVisual spellVisualTier3(HeroClass c) {
  switch (c) {
    case HeroClass.warrior: return SpellVisual('Boží hněv', Icons.flash_on, classSignatureColor(HeroClass.warrior));
    case HeroClass.hunter: return SpellVisual('Prázdnotová bouře', Icons.blur_circular, classSignatureColor(HeroClass.hunter));
    case HeroClass.healer: return SpellVisual('Nebeský rozsudek', Icons.brightness_7, classSignatureColor(HeroClass.healer));
    case HeroClass.deathknight: return SpellVisual('Úder smrti', Icons.favorite_border, classSignatureColor(HeroClass.deathknight));
    case HeroClass.mage: return SpellVisual('Archmágův příval', Icons.auto_awesome, classSignatureColor(HeroClass.mage));
    case HeroClass.duelist: return SpellVisual('Bouře čepelí', Icons.change_history, classSignatureColor(HeroClass.duelist));
    case HeroClass.monk: return SpellVisual('Nebeská Harmonie', Icons.spa, classSignatureColor(HeroClass.monk));
    case HeroClass.druid: return SpellVisual('Srdce Lesa', Icons.forest, classSignatureColor(HeroClass.druid));
    case HeroClass.paladin: return SpellVisual('Posvátný Val', Icons.security, classSignatureColor(HeroClass.paladin));
    case HeroClass.demonhunter: return SpellVisual('Pekelný Žár', Icons.local_fire_department, classSignatureColor(HeroClass.demonhunter));
    case HeroClass.necromancer: return SpellVisual('Rituál Krve a Kostí', Icons.bloodtype, classSignatureColor(HeroClass.necromancer));
    default: return const SpellVisual('Schopnost 3', Icons.auto_awesome, Colors.grey);
  }
}

// Tier 4 — Rank 100, tři volby (rank100Choice 1/2/3) na třídu.
SpellVisual spellVisualTier4(HeroClass c, int choice) {
  switch (c) {
    case HeroClass.warrior:
      if (choice == 1) return SpellVisual('Patář světa', Icons.terrain, classSignatureColor(HeroClass.warrior));
      if (choice == 2) return SpellVisual('Nezničitelný úder', Icons.security, classSignatureColor(HeroClass.warrior));
      return SpellVisual('Válečný vládce', Icons.shield, classSignatureColor(HeroClass.warrior));
    case HeroClass.hunter:
      if (choice == 1) return SpellVisual('Mistrovská poprava', Icons.gps_fixed, classSignatureColor(HeroClass.hunter));
      if (choice == 2) return SpellVisual('Přízračný skok', Icons.visibility_off, classSignatureColor(HeroClass.hunter));
      return SpellVisual('Kosmická bouře', Icons.rocket_launch, classSignatureColor(HeroClass.hunter));
    case HeroClass.healer:
      if (choice == 1) return SpellVisual('Astrální výbuch', Icons.auto_awesome, classSignatureColor(HeroClass.healer));
      if (choice == 2) return SpellVisual('Věčný život', Icons.favorite, classSignatureColor(HeroClass.healer));
      return SpellVisual('Boží paprsek', Icons.wb_sunny, classSignatureColor(HeroClass.healer));
    case HeroClass.deathknight:
      if (choice == 1) return SpellVisual('Kostěný Lich', Icons.dark_mode, classSignatureColor(HeroClass.deathknight));
      if (choice == 2) return SpellVisual('Temný Reaper', Icons.dangerous, classSignatureColor(HeroClass.deathknight));
      return SpellVisual('Pán Duší', Icons.blur_on, classSignatureColor(HeroClass.deathknight));
    case HeroClass.mage:
      if (choice == 1) return SpellVisual('Pyromancer', Icons.local_fire_department, classSignatureColor(HeroClass.mage));
      if (choice == 2) return SpellVisual('Cryomancer', Icons.severe_cold, classSignatureColor(HeroClass.mage));
      return SpellVisual('Chronomancer', Icons.hourglass_bottom, classSignatureColor(HeroClass.mage));
    case HeroClass.duelist:
      if (choice == 1) return SpellVisual('Nemesis', Icons.gps_fixed, classSignatureColor(HeroClass.duelist));
      if (choice == 2) return SpellVisual('Tanečník Čepelí', Icons.switch_access_shortcut, classSignatureColor(HeroClass.duelist));
      return SpellVisual('Bleskový Mistr', Icons.bolt, classSignatureColor(HeroClass.duelist));
    case HeroClass.monk:
      if (choice == 1) return SpellVisual('Pěst tisíce bouří', Icons.sports_martial_arts, classSignatureColor(HeroClass.monk));
      if (choice == 2) return SpellVisual('Kamenný Strážce', Icons.shield, classSignatureColor(HeroClass.monk));
      return SpellVisual('Probuzení Ducha', Icons.spa, classSignatureColor(HeroClass.monk));
    case HeroClass.druid:
      if (choice == 1) return SpellVisual('Avatar Rovnováhy', Icons.brightness_4, classSignatureColor(HeroClass.druid));
      if (choice == 2) return SpellVisual('Forma Medvěda', Icons.pets, classSignatureColor(HeroClass.druid));
      return SpellVisual('Zázrak Přírody', Icons.local_florist, classSignatureColor(HeroClass.druid));
    case HeroClass.paladin:
      if (choice == 1) return SpellVisual('Věčný Strážce', Icons.shield_moon, classSignatureColor(HeroClass.paladin));
      if (choice == 2) return SpellVisual('Boží Meč', Icons.gavel, classSignatureColor(HeroClass.paladin));
      return SpellVisual('Posvěcení', Icons.wb_sunny, classSignatureColor(HeroClass.paladin));
    case HeroClass.demonhunter:
      if (choice == 1) return SpellVisual('Čepele Zkázy', Icons.content_cut, classSignatureColor(HeroClass.demonhunter));
      if (choice == 2) return SpellVisual('Pomsta Propasti', Icons.shield, classSignatureColor(HeroClass.demonhunter));
      return SpellVisual('Fel Zúčtování', Icons.whatshot, classSignatureColor(HeroClass.demonhunter));
    case HeroClass.necromancer:
      if (choice == 1) return SpellVisual('Armáda Nemrtvých', Icons.groups_2, classSignatureColor(HeroClass.necromancer));
      if (choice == 2) return SpellVisual('Vládce Rozkladu', Icons.coronavirus, classSignatureColor(HeroClass.necromancer));
      return SpellVisual('Pakt s Podsvětím', Icons.dark_mode, classSignatureColor(HeroClass.necromancer));
    default:
      return const SpellVisual('Rank 100', Icons.auto_awesome, Colors.grey);
  }
}

// Základní útok - ikona/barva podle typu útoku, nebo signature (Paragon 150).
SpellVisual basicAttackVisual(GameState s) {
  if (s.hasParagon150) return SpellVisual(s.signatureAttackLabel, Icons.auto_awesome, classSignatureColor(s.heroClass));
  return s.classIsMagicAttack
      ? SpellVisual('Magický útok', Icons.flash_on, classSignatureColor(s.heroClass))
      : SpellVisual('Fyzický útok', Icons.gavel, classSignatureColor(s.heroClass));
}

// Krátký (1 věta) popis, co spell dělá - pro Spellbook. Stejné tiery jako spellVisualTierX.
String spellShortDesc(HeroClass c, int tier, {int choice = 1}) {
  switch (tier) {
    case 1:
      switch (c) {
        case HeroClass.warrior: return 'Silný fyzický úder s bonusovým poškozením.';
        case HeroClass.hunter: return 'Masivní úder, který tě navíc vyléčí za polovinu způsobeného poškození.';
        case HeroClass.healer: return 'Vyléčí 50 % max HP a přidá absorb štít.';
        case HeroClass.deathknight: return 'Fyzický úder + nasadí Prokletí (magický DoT na 4 kola).';
        case HeroClass.mage: return 'Masivní jednorázový magický výbuch.';
        case HeroClass.duelist: return 'Rychlá kombinace úderů.';
        case HeroClass.monk: return 'Úder, který navíc vyléčí část způsobeného poškození.';
        case HeroClass.druid: return 'Magický úder, který nasadí přírodní DoT (Uvadnutí) na 3 kola.';
        case HeroClass.paladin: return 'Fyzický úder + malý absorb štít (větší u tank specializace).';
        case HeroClass.demonhunter: return 'Fyzický úder, který nasadí Fel oheň (DoT na 3 kola).';
        case HeroClass.necromancer: return 'Magický úder + přivolaný kostěný sluha přidá bonusové poškození.';
        default: return '';
      }
    case 2:
      switch (c) {
        case HeroClass.warrior: return 'Těžký úder + velký absorb štít.';
        case HeroClass.hunter: return 'Brutální poprava s vysokým poškozením.';
        case HeroClass.healer: return 'Vyléčí plné HP a udeří nepřítele svatým úderem.';
        case HeroClass.deathknight: return 'Odpálí nastřádané Prokletí za okamžité poškození - čím déle kletba tikala, tím větší štít dostaneš.';
        case HeroClass.mage: return 'Silný magický nával, část many se vrátí.';
        case HeroClass.duelist: return 'Přesný, cílený výpad.';
        case HeroClass.monk: return 'Dračí kop s poškozením a štítem.';
        case HeroClass.druid: return 'Silný magický burst z astrální energie.';
        case HeroClass.paladin: return 'Silný fyzický burst z posvátného hněvu.';
        case HeroClass.demonhunter: return 'Masivní fyzický burst v démonické podobě.';
        case HeroClass.necromancer: return 'Přivolá vlnu nemrtvých za silný magický burst.';
        default: return '';
      }
    case 3:
      switch (c) {
        case HeroClass.warrior: return 'Extrémní fyzická erupce + obří štít.';
        case HeroClass.hunter: return 'Smrtící útok s plným obnovením HP.';
        case HeroClass.healer: return 'Božská sprcha poškození + plné HP + štít.';
        case HeroClass.deathknight: return 'Fyzický i magický úder - magická složka se mění na heal (nebo štít při plném HP).';
        case HeroClass.mage: return 'Masivní arkánový příval + magický ward.';
        case HeroClass.duelist: return 'Bouře čepelí, po které máš plné HP.';
        case HeroClass.monk: return 'Poškození, plné HP a štít najednou.';
        case HeroClass.druid: return 'Magický úder, plné HP a velký štít najednou.';
        case HeroClass.paladin: return 'Fyzický úder, plné HP a velký štít najednou.';
        case HeroClass.demonhunter: return 'Fyzický úder + silný dlouhotrvající lifesteal.';
        case HeroClass.necromancer: return 'Obětuje kostěné sluhy za magický úder, plné HP a dlouhý lifesteal.';
        default: return '';
      }
    case 4:
      switch (c) {
        case HeroClass.warrior:
          if (choice == 1) return 'Extrémní poškození + obří štít.';
          if (choice == 2) return 'Nejvyšší jednorázové poškození ze všech tvých spellů.';
          return 'Plné HP + masivní štít, žádné poškození.';
        case HeroClass.hunter:
          if (choice == 1) return 'Mistrovská poprava s velmi vysokým poškozením.';
          if (choice == 2) return 'Poškození + dlouhotrvající lifesteal.';
          return 'Poškození + plné obnovení HP.';
        case HeroClass.healer:
          if (choice == 1) return 'Plné HP + poškození + štít najednou.';
          if (choice == 2) return 'Plné HP + trvalý lifesteal na dlouho.';
          return 'Čistě ofenzivní - masivní poškození bez healu.';
        case HeroClass.deathknight:
          if (choice == 1) return 'Okamžitě odpálí Prokletí za masivní poškození.';
          if (choice == 2) return 'Masivní úder + silný lifesteal.';
          return 'Poškození + plné HP + velký štít, reset Soul Runes.';
        case HeroClass.mage:
          if (choice == 1) return 'Ohnivý příval + zapálení (DoT).';
          if (choice == 2) return 'Mrazivý úder + ledový absorb štít.';
          return 'Poškození + vynuluje cooldowny ostatních schopností.';
        case HeroClass.duelist:
          if (choice == 1) return 'Poprava s bonusem, pokud má soupeř pod 30 % HP.';
          if (choice == 2) return 'Poškození + plné HP.';
          return 'Poškození + vynuluje cooldowny ostatních schopností.';
        case HeroClass.monk:
          if (choice == 1) return 'Drtivý úder s vysokým poškozením.';
          if (choice == 2) return 'Poškození + obří štít + 1 kolo naprosté nezranitelnosti.';
          return 'Poškození + plné HP + posílený heal/obrana na 3 kola.';
        case HeroClass.druid:
          if (choice == 1) return 'Nejvyšší jednorázové magické poškození ze všech Druidových spellů.';
          if (choice == 2) return 'Menší poškození + obří štít (tank volba).';
          return 'Čistě podpůrné - plné HP + dlouhý lifesteal, žádné poškození.';
        case HeroClass.paladin:
          if (choice == 1) return 'Poškození + obří štít (tank volba).';
          if (choice == 2) return 'Nejvyšší jednorázové poškození ze všech Paladinových spellů.';
          return 'Plné HP + velký štít, žádné poškození (heal volba).';
        case HeroClass.demonhunter:
          if (choice == 1) return 'Nejvyšší jednorázové poškození ze všech spellů Lovce Démonů.';
          if (choice == 2) return 'Poškození + obří štít + lifesteal (tank volba).';
          return 'Poškození + silný Fel oheň (DoT).';
        case HeroClass.necromancer:
          if (choice == 1) return 'Nejvyšší jednorázové poškození ze všech Nekromantových spellů.';
          if (choice == 2) return 'Poškození + velmi silný Rozklad (DoT).';
          return 'Poškození + plné HP + dlouhý lifesteal.';
        default: return '';
      }
    default:
      return '';
  }
}

// Krátký (1-2 věty) tip na rotaci/synergii mezi spelly pro danou třídu.
String spellRotationTip(HeroClass c) {
  switch (c) {
    case HeroClass.warrior: return 'Základní útoky generují Rage. Šetři schopnosti na chvíli, kdy máš Rage vysoko - Hněv šampiona (Paragon 150) ho doplňuje s každým zásahem.';
    case HeroClass.hunter: return 'Základní útoky budují staky Znamení lovce, které zvyšují poškození. Kombinuj je se Skrytým úderem pro maximální DPS.';
    case HeroClass.healer: return 'Léčivé spelly čistí jed a přebytečný heal se mění na štít. Použij Boží požehnání, když je HP nízko - zachrání tě i posílí obranu.';
    case HeroClass.deathknight: return 'Klíčová rotace: nejdřív Prokletý úder (nasadí DoT), pak Exploze prokletí ho detonuje za bonus poškození a štít - čím déle kletba tikala, tím větší odměna.';
    case HeroClass.mage: return 'Arkánová specializace: základní útoky a Elementální výbuch budují Arcane Charge staky, které umocní tvůj Arkánový nával.';
    case HeroClass.duelist: return 'Rychlé combo a základní útoky (Elegantní výpad) zvyšují úhyb. Střídej je, aby sis udržel vysoký dodge proti silným bossům.';
    case HeroClass.monk: return 'Základní útoky budují staky Plynoucí Čchi, které umocní tvůj Úder tisíce dlaní a Dračí kop.';
    case HeroClass.druid: return 'Divoký spár nasadí Uvadnutí (DoT) - nech ho tikat a dobíjej Hvězdným pádem, než sáhneš po Srdci Lesa jako záchranné brzdě.';
    case HeroClass.paladin: return 'Ochránce Víry: drž Úder Spravedlnosti pro štít, než zatlačíš Božím Trestem. Posvátný Val je záchranná brzda - dmg, plné HP a štít najednou.';
    case HeroClass.demonhunter: return 'Rozseknutí čepelemi nasadí Fel oheň (DoT) - nech ho tikat, dobíjej Metamorfózou, a Pekelný Žár použij na dlouhý lifesteal v těžkém boji.';
    case HeroClass.necromancer: return 'Kostěný Sluha přidává bonusové poškození za každý zásah - kombinuj s Voláním Nemrtvých pro burst a Rituálem Krve a Kostí jako záchrannou brzdou.';
    default: return '';
  }
}

// ===== IKONKOVÉ TLAČÍTKO SPELLU — jednotný styl napříč Věží/Lairem/Riftem/Arénou =====
// Čtvercový rám s ikonou spellu (barva podle SpellVisual), malý popisek pod ním a
// překryv (šedý + text) při "použito"/cooldownu. Cena zdroje je v tooltipu i popisku.
// Barva karty Hrdiny v boji = barva jeho třídy - stejná paleta, jaká už definuje spellVisualTier1
// pro spelly té třídy (žádná nová barva, jen ji recykluje pro celý panel).
Color heroClassAccent(HeroClass c) {
  switch (c) {
    case HeroClass.warrior: return const Color(0xFFE64A19);
    case HeroClass.hunter: return const Color(0xFF9CCC65);
    case HeroClass.healer: return const Color(0xFFFFD54F);
    case HeroClass.deathknight: return const Color(0xFF70D7FF);
    case HeroClass.mage: return const Color(0xFFFF5722);
    case HeroClass.duelist: return const Color(0xFFE0E0E0);
    case HeroClass.monk: return const Color(0xFFFFB74D);
    case HeroClass.druid: return const Color(0xFF66BB6A);
    case HeroClass.paladin: return const Color(0xFFFFD700);
    case HeroClass.demonhunter: return const Color(0xFF7B2FBE);
    case HeroClass.necromancer: return const Color(0xFF6A1B9A);
    default: return const Color(0xFF1E88E5);
  }
}

// Kompaktní ikonkový stat-čip pro combat karty (Atk/Def/Crit/...) - barevný "badge" za ikonou
// místo textové zkratky typu "P.Atk:", šetří šířku a vejde se jich víc do 2sloupcové mřížky.
class CombatStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color badgeColor;
  final Color badgeIconColor;
  final String name;
  final String description;
  const CombatStatChip({super.key, required this.icon, required this.value, required this.badgeColor, required this.badgeIconColor, required this.name, required this.description});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showFantasyInfoDialog(
          context,
          icon: icon,
          title: name,
          color: badgeIconColor,
          content: Text(description, style: const TextStyle(color: Color(0xFFF1E6D0), height: 1.35)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(color: Colors.black.withOpacity(.28), borderRadius: BorderRadius.circular(7), border: Border.all(color: Colors.white.withOpacity(.06))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.center,
            child: Icon(icon, size: 10, color: badgeIconColor),
          ),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDCCFAF))),
        ]),
      ),
    );
  }
}

FantasyIconType heroClassIconType(HeroClass c) {
  switch (c) {
    case HeroClass.warrior: return FantasyIconType.classWarrior;
    case HeroClass.hunter: return FantasyIconType.classHunter;
    case HeroClass.healer: return FantasyIconType.classPriest;
    case HeroClass.deathknight: return FantasyIconType.classDeathKnight;
    case HeroClass.mage: return FantasyIconType.classMage;
    case HeroClass.duelist: return FantasyIconType.classDuelist;
    case HeroClass.monk: return FantasyIconType.classMonk;
    case HeroClass.druid: return FantasyIconType.classDruid;
    case HeroClass.paladin: return FantasyIconType.classPaladin;
    case HeroClass.demonhunter: return FantasyIconType.classDemonHunter;
    case HeroClass.necromancer: return FantasyIconType.classNecromancer;
    default: return FantasyIconType.classWarrior;
  }
}

// ===== DEATHKNIGHT: Vysátí duše - vizuální segmentovaný progress bar místo holého textu.
// Podržení (long-press) zobrazí vysvětlení, co pasivka dělá a jak se plní - stejný vzor jako
// u buff/debuff chipů a Hub dlaždic (showFantasyInfoDialog).
class SoulRuneBar extends StatelessWidget {
  final GameState state;
  const SoulRuneBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFCC66FF);
    final ready = state.nextSpellTriple;
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showFantasyInfoDialog(
          context,
          icon: Icons.dark_mode,
          title: tr('Vysátí duše', 'Soul Drain'),
          color: accent,
          content: Text(
            tr(
              'Pasivní schopnost Rytíře Smrti. Za útok, obdržené poškození, zabití nepřítele nebo crit z DoTu získáš 1 duši (max 7). Při 7 duších se okamžitě spotřebují a tvůj příští aktivní spell způsobí 3× efekt.',
              "The Death Knight's passive. Attacking, taking damage, killing an enemy, or a DoT crit each grant 1 soul rune (max 7). At 7 runes they're instantly consumed and your next active spell deals 3× effect.",
            ),
            style: const TextStyle(color: Color(0xFFF1E6D0), height: 1.35),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: ready ? [const Color(0xFF4A0A5C), const Color(0xFF2A0430)] : [const Color(0xFF2A0430), const Color(0xFF1A0220)]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withOpacity(ready ? 1 : .5), width: ready ? 1.6 : 1),
          boxShadow: ready ? [BoxShadow(color: accent.withOpacity(.6), blurRadius: 14, spreadRadius: 1)] : [],
        ),
        child: Row(
          children: [
            Icon(Icons.dark_mode, color: accent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: ready
                  ? Text(tr('✨ PŘÍŠTÍ SPELL = 3× EFEKT!', '✨ NEXT SPELL = 3× EFFECT!'), style: const TextStyle(color: Color(0xFFFFE082), fontWeight: FontWeight.bold, fontSize: 12.5))
                  : Row(
                      children: List.generate(7, (i) {
                        final filled = i < state.soulRunes;
                        return Expanded(
                          child: Container(
                            height: 10,
                            margin: EdgeInsets.only(right: i < 6 ? 3 : 0),
                            decoration: BoxDecoration(
                              color: filled ? accent : Colors.white10,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: filled ? [BoxShadow(color: accent.withOpacity(.7), blurRadius: 5)] : [],
                            ),
                          ),
                        );
                      }),
                    ),
            ),
            const SizedBox(width: 8),
            Text(ready ? '' : '${state.soulRunes}/7', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ===== OBECNÝ "STACK" PASIVNÍ PROGRESS BAR — Lovec (Znamení lovce), Mág (Arkánové nabití),
// Mnich (Plynoucí Čchi). Stejný princip jako SoulRuneBar (segmenty + long-press vysvětlení),
// ale bez "spotřebuj vše najednou" mechaniky - jen postupně rostoucí bonus poškození.
class StackPassiveBar extends StatelessWidget {
  final String name;
  final String description;
  final Color accent;
  final int current;
  final int max;
  const StackPassiveBar({super.key, required this.name, required this.description, required this.accent, required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    final full = max > 0 && current >= max;
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showFantasyInfoDialog(
          context,
          icon: Icons.auto_awesome,
          title: name,
          color: accent,
          content: Text(description, style: const TextStyle(color: Color(0xFFF1E6D0), height: 1.35)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withOpacity(full ? 1 : .5), width: full ? 1.6 : 1),
          boxShadow: full ? [BoxShadow(color: accent.withOpacity(.55), blurRadius: 12, spreadRadius: 1)] : [],
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: accent, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: List.generate(max, (i) {
                  final filled = i < current;
                  return Expanded(
                    child: Container(
                      height: 10,
                      margin: EdgeInsets.only(right: i < max - 1 ? 3 : 0),
                      decoration: BoxDecoration(
                        color: filled ? accent : Colors.white10,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: filled ? [BoxShadow(color: accent.withOpacity(.7), blurRadius: 5)] : [],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            Text('$current/$max', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ===== JEDNODUCHÝ INFORMAČNÍ PASIVNÍ PRUH — pro třídy, kde "pasivka" není rostoucí zásobník,
// ale tiché modifikátory schované ve specAbilityDamageMod/basicAttackRoleMod/applyAbilityExecute
// apod. (např. Paladin). Vizuálně stejný jazyk jako StackPassiveBar (glow okraj, long-press
// vysvětlení), ale bez segmentů - čistě informační štítek, ať hráč ví, že něco má, i když se to
// nikde jinde v UI neprojeví číselně.
class PassiveInfoBar extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final Color accent;
  const PassiveInfoBar({super.key, required this.icon, required this.name, required this.description, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showFantasyInfoDialog(
          context,
          icon: icon,
          title: name,
          color: accent,
          content: Text(description, style: const TextStyle(color: Color(0xFFF1E6D0), height: 1.35)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withOpacity(.5), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name, style: TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.bold)),
            ),
            Icon(Icons.touch_app, color: accent.withOpacity(.6), size: 14),
          ],
        ),
      ),
    );
  }
}

// Vybere odpovídající pasivní progress bar podle aktuální třídy hráče (nebo null, pokud daná
// třída žádnou takovou viditelnou pasivku nemá). Jedno místo pravdy pro všechny bojové
// obrazovky (Věž/Aréna/Doupě/World Boss/Trhlina/Endless Scale) místo kopírování switch(class)
// na 6 místech zvlášť.
Widget? classPassiveBar(GameState state) {
  switch (state.heroClass) {
    case HeroClass.deathknight:
      return SoulRuneBar(state: state);
    case HeroClass.hunter:
      return StackPassiveBar(
        name: tr('Znamení lovce', "Hunter's Mark"),
        description: tr(
          'Pasivní schopnost Lovce. Zásahy nabíjí stack (max ${state.huntersMarkMaxStacks}), každý dává +${(state.huntersMarkPerStack * 100).round()} % poškození a menší léčení z způsobeného dmg. Na plný počet stacků má specializace Přeživší navíc +15 % poškození proti bossům.',
          "The Hunter's passive. Hits build stacks (max ${state.huntersMarkMaxStacks}), each giving +${(state.huntersMarkPerStack * 100).round()}% damage and minor healing from damage dealt. At full stacks, the Survival spec also gets +15% damage against bosses.",
        ),
        accent: const Color(0xFF9CCC65),
        current: state.huntersMarkStacks,
        max: state.huntersMarkMaxStacks,
      );
    case HeroClass.mage:
      return StackPassiveBar(
        name: tr('Arkánové nabití', 'Arcane Charge'),
        description: tr(
          'Pasivní schopnost Mága. Zásahy nabíjí stack (max ${state.arcaneChargeMaxStacks}), každý dává +${(state.arcaneChargePerStack * 100).round()} % poškození dalších kouzel.',
          "The Mage's passive. Hits build stacks (max ${state.arcaneChargeMaxStacks}), each giving +${(state.arcaneChargePerStack * 100).round()}% damage to further spells.",
        ),
        accent: const Color(0xFFFF5722),
        current: state.arcaneChargeStacks,
        max: state.arcaneChargeMaxStacks,
      );
    case HeroClass.monk:
      return StackPassiveBar(
        name: tr('Plynoucí Čchi', 'Flowing Chi'),
        description: tr(
          'Pasivní schopnost Mnicha. Zásahy nabíjí stack (max ${state.flowingChiMaxStacks}), každý dává +${(state.flowingChiPerStack * 100).round()} % poškození.',
          "The Monk's passive. Hits build stacks (max ${state.flowingChiMaxStacks}), each giving +${(state.flowingChiPerStack * 100).round()}% damage.",
        ),
        accent: const Color(0xFFFFB74D),
        current: state.flowingChiStacks,
        max: state.flowingChiMaxStacks,
      );
    case HeroClass.paladin:
      return PassiveInfoBar(
        icon: Icons.shield_moon,
        name: tr('Svatá Kázeň', 'Holy Discipline'),
        accent: const Color(0xFFFFD700),
        description: state.specialization == 1
            ? tr(
                'Pasivní schopnost Paladina (Ochránce Víry). Základní útok má -12 % dmg výměnou za mnohem větší štíty ze schopností - typický tank kompromis.',
                "The Paladin's passive (Guardian of Faith). Basic attack deals -12% dmg in exchange for much larger shields from abilities - the classic tank trade-off.",
              )
            : state.specialization == 2
                ? tr(
                    'Pasivní schopnost Paladina (Trestající). Schopnosti způsobují +15 % dmg a navíc +10 % dmg proti cílům pod 35 % HP - specializace na dorážení oslabeného nepřítele.',
                    "The Paladin's passive (Retributor). Abilities deal +15% dmg, plus +10% dmg against targets below 35% HP - built for finishing off weakened enemies.",
                  )
                : state.specialization == 3
                    ? tr(
                        'Pasivní schopnost Paladina (Posvěcený). Žádný skrytý bojový modifikátor - síla téhle větve je čistě ve vyváženém poměru healu a štítu ze schopností.',
                        "The Paladin's passive (Sanctified). No hidden combat modifier - this branch's strength comes purely from a balanced heal/shield ratio on abilities.",
                      )
                    : tr(
                        'Pasivní schopnost Paladina se odemkne výběrem specializace (Ochránce Víry / Trestající / Posvěcený) - každá dává jiný tichý bojový bonus.',
                        "The Paladin's passive unlocks once you pick a specialization (Guardian of Faith / Retributor / Sanctified) - each grants a different hidden combat bonus.",
                      ),
      );
    case HeroClass.warrior:
      return PassiveInfoBar(
        icon: Icons.fitness_center,
        name: tr('Bojový Instinkt', 'Battle Instinct'),
        accent: classSignatureColor(HeroClass.warrior),
        description: state.specialization == 1
            ? tr(
                'Pasivní schopnost Válečníka (Berserk). Schopnosti +20 % dmg, ale heal/štít z nich -25 % - čistě útočný kompromis.',
                "The Warrior's passive (Berserk). Abilities deal +20% dmg, but heal/shield from them -25% - a purely offensive trade-off.",
              )
            : state.specialization == 2
                ? tr(
                    'Pasivní schopnost Válečníka (Ochránce). Základní útok -12 % dmg, schopnosti -15 % dmg, ale heal/štít z nich +50 % a +5 % šance na blok - klasický tank.',
                    "The Warrior's passive (Guardian). Basic attack -12% dmg, abilities -15% dmg, but heal/shield from them +50% and +5% block chance - the classic tank.",
                  )
                : state.specialization == 3
                    ? tr(
                        'Pasivní schopnost Válečníka (Krvežíznivý). Fyzické schopnosti navíc uvalí krvácení (DoT) na nepřítele - stálý přídavný dmg navrch k útoku.',
                        "The Warrior's passive (Bloodthirsty). Physical abilities additionally apply bleed (DoT) to the enemy - steady extra damage on top of the hit.",
                      )
                    : tr(
                        'Pasivní schopnost Válečníka se odemkne výběrem specializace (Berserk / Ochránce / Krvežíznivý) - každá dává jiný tichý bojový bonus.',
                        "The Warrior's passive unlocks once you pick a specialization (Berserk / Guardian / Bloodthirsty) - each grants a different hidden combat bonus.",
                      ),
      );
    case HeroClass.healer:
      return PassiveInfoBar(
        icon: Icons.wb_sunny,
        name: tr('Boží Odplata', 'Divine Retribution'),
        accent: classSignatureColor(HeroClass.healer),
        description: state.specialization == 1
            ? tr(
                'Pasivní schopnost Léčitele (Světlo). Heal/štít ze schopností +30 % a odražené poškození se z 15 % promění ve vlastní heal - čistý support.',
                "The Healer's passive (Light). Heal/shield from abilities +30%, and 15% of reflected damage converts into self-healing - pure support.",
              )
            : state.specialization == 2
                ? tr(
                    'Pasivní schopnost Léčitele (Odplata). Heal/štít ze schopností -15 %, ale odražené poškození se z 25 % promění ve vlastní heal - agresivnější, protiútočná větev.',
                    "The Healer's passive (Retribution). Heal/shield from abilities -15%, but 25% of reflected damage converts into self-healing - a more aggressive, counter-attack branch.",
                  )
                : state.specialization == 3
                    ? tr(
                        'Pasivní schopnost Léčitele (Battle Priest). Schopnosti +15 % dmg - jediná Léčitelova větev, co umí i pořádně útočit.',
                        "The Healer's passive (Battle Priest). Abilities deal +15% dmg - the only Healer branch that can also hit hard.",
                      )
                    : tr(
                        'Pasivní schopnost Léčitele se odemkne výběrem specializace (Světlo / Odplata / Battle Priest) - každá dává jiný tichý bojový bonus.',
                        "The Healer's passive unlocks once you pick a specialization (Light / Retribution / Battle Priest) - each grants a different hidden combat bonus.",
                      ),
      );
    case HeroClass.druid:
      return PassiveInfoBar(
        icon: Icons.eco,
        name: tr('Rovnováha Přírody', "Nature's Balance"),
        accent: classSignatureColor(HeroClass.druid),
        description: state.specialization == 1
            ? tr(
                'Pasivní schopnost Druida (Rovnováha). Schopnosti +10 % dmg a navíc +10 % dmg proti bossům - vyhraněná útočná větev.',
                "The Druid's passive (Balance). Abilities deal +10% dmg, plus +10% dmg against bosses - a dedicated damage branch.",
              )
            : state.specialization == 2
                ? tr(
                    'Pasivní schopnost Druida (Forma Medvěda). Základní útok -12 % dmg výměnou za výrazně vyšší obranu z Armoru - tank forma.',
                    "The Druid's passive (Bear Form). Basic attack -12% dmg in exchange for much higher defense from Armor - the tank form.",
                  )
                : state.specialization == 3
                    ? tr(
                        'Pasivní schopnost Druida (Zázrak Přírody). Žádný skrytý bojový modifikátor - síla téhle větve je čistě ve vyváženém poměru healu a štítu ze schopností.',
                        "The Druid's passive (Nature's Miracle). No hidden combat modifier - this branch's strength comes purely from a balanced heal/shield ratio on abilities.",
                      )
                    : tr(
                        'Pasivní schopnost Druida se odemkne výběrem specializace (Rovnováha / Forma Medvěda / Zázrak Přírody) - každá dává jiný tichý bojový bonus.',
                        "The Druid's passive unlocks once you pick a specialization (Balance / Bear Form / Nature's Miracle) - each grants a different hidden combat bonus.",
                      ),
      );
    case HeroClass.duelist:
      return PassiveInfoBar(
        icon: Icons.flash_on,
        name: tr('Ostří Instinktu', 'Blade Instinct'),
        accent: classSignatureColor(HeroClass.duelist),
        description: state.specialization == 1
            ? tr(
                'Pasivní schopnost Duelisty (Vendetta). Schopnosti +20 % dmg - čistě útočná větev.',
                "The Duelist's passive (Vendetta). Abilities deal +20% dmg - a purely offensive branch.",
              )
            : state.specialization == 2
                ? tr(
                    'Pasivní schopnost Duelisty (Grácie). Schopnosti -15 % dmg, ale +10 % úhyb a úspěšný úhyb dává šanci na protiútok - vyhýbavý styl.',
                    "The Duelist's passive (Grace). Abilities deal -15% dmg, but +10% dodge and a successful dodge grants a chance to counter-attack - an evasive style.",
                  )
                : state.specialization == 3
                    ? tr(
                        'Pasivní schopnost Duelisty (Virtuóz). +15 % kritické šance a schopnosti mají o 25 % nižší náklad many/víry a o 20 % kratší cooldown - rychlý, technický styl.',
                        "The Duelist's passive (Virtuoso). +15% crit chance and abilities have 25% lower mana/faith cost and 20% shorter cooldown - a fast, technical style.",
                      )
                    : tr(
                        'Pasivní schopnost Duelisty se odemkne výběrem specializace (Vendetta / Grácie / Virtuóz) - každá dává jiný tichý bojový bonus.',
                        "The Duelist's passive unlocks once you pick a specialization (Vendetta / Grace / Virtuoso) - each grants a different hidden combat bonus.",
                      ),
      );
    case HeroClass.demonhunter:
      return PassiveInfoBar(
        icon: Icons.content_cut,
        name: tr('Fel Krev', 'Fel Blood'),
        accent: classSignatureColor(HeroClass.demonhunter),
        description: state.specialization == 1
            ? tr(
                'Pasivní schopnost Lovce Démonů (Čepele Zkázy). Žádný skrytý bojový modifikátor - čistě agresivní, vyvážená DPS větev.',
                "The Demon Hunter's passive (Blades of Doom). No hidden combat modifier - a purely aggressive, balanced DPS branch.",
              )
            : state.specialization == 2
                ? tr(
                    'Pasivní schopnost Lovce Démonů (Pomsta Propasti). Základní útok -12 % dmg výměnou za výrazně vyšší obranu z Armoru - tank větev.',
                    "The Demon Hunter's passive (Abyssal Vengeance). Basic attack -12% dmg in exchange for much higher defense from Armor - the tank branch.",
                  )
                : state.specialization == 3
                    ? tr(
                        'Pasivní schopnost Lovce Démonů (Fel Zúčtování). Fel oheň (DoT) drží o 2 kola déle než u ostatních specializací - dlouhodobější poškození v čase.',
                        "The Demon Hunter's passive (Fel Reckoning). Fel fire (DoT) lasts 2 rounds longer than for other specializations - longer-lasting damage over time.",
                      )
                    : tr(
                        'Pasivní schopnost Lovce Démonů se odemkne výběrem specializace (Čepele Zkázy / Pomsta Propasti / Fel Zúčtování) - každá dává jiný tichý bojový bonus.',
                        "The Demon Hunter's passive unlocks once you pick a specialization (Blades of Doom / Abyssal Vengeance / Fel Reckoning) - each grants a different hidden combat bonus.",
                      ),
      );
    case HeroClass.necromancer:
      return PassiveInfoBar(
        icon: Icons.person_outline,
        name: tr('Pouto se Smrtí', 'Bond with Death'),
        accent: classSignatureColor(HeroClass.necromancer),
        description: state.specialization == 1
            ? tr(
                'Pasivní schopnost Nekromanta (Armáda Nemrtvých). Žádný skrytý bojový modifikátor - čistě agresivní, vyvážená DPS větev.',
                "The Necromancer's passive (Undead Army). No hidden combat modifier - a purely aggressive, balanced DPS branch.",
              )
            : state.specialization == 2
                ? tr(
                    'Pasivní schopnost Nekromanta (Vládce Rozkladu). Poškození z DoT efektů (jed, krvácení, kletby) je o 15 % silnější - specializace na poškození v čase.',
                    "The Necromancer's passive (Master of Decay). Damage from DoT effects (poison, bleed, curses) is 15% stronger - a damage-over-time specialization.",
                  )
                : state.specialization == 3
                    ? tr(
                        'Pasivní schopnost Nekromanta (Pakt s Podsvětím). Žádný skrytý bojový modifikátor - síla téhle větve je čistě ve vyváženém poměru healu a štítu ze schopností.',
                        "The Necromancer's passive (Pact with the Underworld). No hidden combat modifier - this branch's strength comes purely from a balanced heal/shield ratio on abilities.",
                      )
                    : tr(
                        'Pasivní schopnost Nekromanta se odemkne výběrem specializace (Armáda Nemrtvých / Vládce Rozkladu / Pakt s Podsvětím) - každá dává jiný tichý bojový bonus.',
                        "The Necromancer's passive unlocks once you pick a specialization (Undead Army / Master of Decay / Pact with the Underworld) - each grants a different hidden combat bonus.",
                      ),
      );
    default:
      return null;
  }
}

// Kompaktní ikonkové tlačítko pro lektvary a Auto-boj toggle - stejný vizuální jazyk jako
// SpellIconButton (diagonální gradient, barevný okraj, dvojitý glow), ale bez textového popisku
// pod ikonou (jméno se ukáže na dlouhé podržení jako tooltip) - šetří to hodně výšky, protože
// dřív to byly samostatné full-width řádky pod spelly.
class ConsumableIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int? count; // null = bez badge (např. Auto-boj toggle)
  final bool active; // true = zvýrazněný stav (zapnuto/dostupné)
  final String tooltip;
  final String? overlayText; // cooldown číslo přes ikonu (stejný vzor jako u SpellIconButton)
  final VoidCallback? onPressed;
  const ConsumableIconButton({super.key, required this.icon, required this.color, this.count, this.active = true, required this.tooltip, this.overlayText, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || (count != null && count! <= 0);
    // Stejné pravidlo jako u SpellIconButton: ready = plná barva + glow, not-ready = plochá šedá
    // bez glow vůbec - žádné půlené 40% Opacity, co dřív dělalo ready/not-ready těžko odlišitelné.
    final Color effColor = (disabled || !active) ? Colors.grey.shade600 : color;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [effColor.withOpacity(disabled ? .16 : .38), const Color(0xFF1A1511)]),
                  border: Border.all(color: effColor, width: disabled ? 1.4 : 2.2),
                  boxShadow: disabled
                      ? []
                      : [
                          BoxShadow(color: effColor.withOpacity(.55), blurRadius: 10, spreadRadius: -1),
                          BoxShadow(color: effColor.withOpacity(.22), blurRadius: 20, spreadRadius: -2),
                        ],
                ),
                child: Icon(icon, color: disabled ? Colors.grey.shade400 : Colors.white, size: 22),
              ),
              if (count != null)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFF1A1511), borderRadius: BorderRadius.circular(8), border: Border.all(color: effColor, width: 1)),
                    child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: effColor)),
                  ),
                ),
              if (overlayText != null)
                Positioned.fill(child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(.6), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(overlayText!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                )),
            ],
        ),
      ),
    );
  }
}

// ===== ZAMČENÉ SLOTY SCHOPNOSTÍ — dřív se tier2/3/4 spell a Relic tlačítko vůbec nevykreslilo,
// dokud nebylo odemčené (mezera v gridu). Teď se zobrazují VŽDY, jen v uzamčeném stavu (šedé, bez
// glow, s tooltipem co přesně chybí) - hráč tak vidí, co ho čeká, ne prázdné díry v layoutu.
Widget lockedAbilitySlot(GameState state, SpellVisual visual, int requiredRank) {
  final currentRank = state.classRanks[state.heroClass] ?? 0;
  return SpellIconButton(
    visual: visual,
    disabled: true,
    costLabel: tr('Odemyká se na Rank $requiredRank (nyní: $currentRank)', 'Unlocks at Rank $requiredRank (now: $currentRank)'),
    onPressed: null,
  );
}

Widget lockedTier4Slot(GameState state) {
  final currentRank = state.classRanks[state.heroClass] ?? 0;
  final visual = spellVisualTier4(state.heroClass, state.rank100Choice > 0 ? state.rank100Choice : 1);
  return SpellIconButton(
    visual: visual,
    disabled: true,
    costLabel: currentRank < 100
        ? tr('Odemyká se na Rank 100 (nyní: $currentRank)', 'Unlocks at Rank 100 (now: $currentRank)')
        : tr('Zvol cestu v Profilu (BUILD → Rank 100)', 'Choose a path in Profile (BUILD → Rank 100)'),
    onPressed: null,
  );
}

Widget lockedRelicSlot() {
  return SpellIconButton(
    visual: const SpellVisual('Relic', Icons.auto_awesome, Colors.grey),
    disabled: true,
    costLabel: tr('Odemyká se výběrem specializace', 'Unlocks by choosing a specialization'),
    onPressed: null,
  );
}

// Sdílený layout: 2 řady po 4 - řádek 1 [základní útok, tier1, tier2, tier3], řádek 2 [Léčivý
// lektvar, tier4, relic, Upíří lektvar]. Léčivý lektvar je tak vždy přímo pod základním útokem
// (levý horní roh → levý dolní roh) a Upíří lektvar v protějším (pravém dolním) rohu. Případné
// další lektvary (Síla/Kamenná kůže/...) jdou do volitelné 3. řady pod tím.
Widget combatActionGrid({
  required Widget basicAttack,
  required Widget tier1,
  required Widget tier2,
  required Widget tier3,
  required Widget tier4,
  required Widget relic,
  required Widget healPotion,
  required Widget vampirePotion,
  List<Widget> extraPotions = const [],
}) {
  return Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [basicAttack, tier1, tier2, tier3]),
    const SizedBox(height: 10),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [healPotion, tier4, relic, vampirePotion]),
    if (extraPotions.isNotEmpty) ...[
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, children: extraPotions),
    ],
  ]);
}

class SpellIconButton extends StatelessWidget {
  final SpellVisual visual;
  final String? costLabel;
  final bool disabled;
  final String? overlayText; // "Použito" nebo číslo cooldownu ("5")
  final VoidCallback? onPressed;
  final double size;
  const SpellIconButton({super.key, required this.visual, this.costLabel, this.disabled = false, this.overlayText, required this.onPressed, this.size = 58});

  @override
  Widget build(BuildContext context) {
    // Ready/not-ready musí být na první pohled jasně odlišitelné - dřív se disabled stav řešil
    // jen 45% Opacity na CELÉM tlačítku (barva i glow zůstávaly, jen ztlumené), takže hlavně u
    // tmavších barev (necromancer fialová) šlo těžko poznat, jestli spell čeká na cooldown, nebo
    // je připravený. Teď: ready = plná barva + glow, not-ready = plochá šedá BEZ glow vůbec.
    final Color effColor = disabled ? const Color(0xFF4A4A52) : visual.color;
    return Tooltip(
      message: costLabel != null ? '${visual.name}\n$costLabel' : visual.name,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.center, children: [
              Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [effColor.withOpacity(disabled ? .18 : .38), const Color(0xFF1A1511)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: effColor, width: disabled ? 1.4 : 2.2),
                  // Dvojitý glow (těsný + rozptýlený) JEN u připravených spellů - stejný vizuální
                  // jazyk jako legendary rarity rám u itemů (viz kRarityStyles). Nepřipravené
                  // (cooldown/použito/chybí zdroj) nemají žádný glow, ať je okamžitě jasné, že
                  // teď nejdou použít.
                  boxShadow: disabled ? [] : [
                    BoxShadow(color: effColor.withOpacity(.55), blurRadius: 10, spreadRadius: 0.5),
                    BoxShadow(color: effColor.withOpacity(.22), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Icon(visual.icon, color: effColor, size: size * 0.46),
                  // Rohové ornamenty (echo FantasyIconFrame legendary/artifact stylu) - taky jen
                  // u ready spellů, ať not-ready působí opravdu "vypnutě".
                  if (!disabled)
                    for (final a in const [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
                      Align(
                        alignment: a,
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            width: 4, height: 4,
                            decoration: BoxDecoration(color: effColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: effColor.withOpacity(.8), blurRadius: 3)]),
                          ),
                        ),
                      ),
                ]),
              ),
              if (overlayText != null)
                Positioned.fill(child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(.6), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(overlayText!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                )),
            ]),
            const SizedBox(height: 3),
            SizedBox(width: size + 10, child: Text(visual.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: disabled ? Colors.grey.shade600 : Colors.grey.shade300))),
          ]),
      ),
    );
  }
}

/// Aréna - PvE 1:1 mirror-match. Soupeř je náhodná třída/specializace se staty odvozenými
/// z hráčových vlastních statů (× mírný ligový bonus), ne z floor/tier škálování.
class ArenaScreen extends StatelessWidget {
  final int initialTab;
  const ArenaScreen({super.key, this.initialTab = 0});

  Widget _effects(String title, List<StatusEffect> effects) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 4),
      StatusEffectsListWidget(effects: effects),
    ],
  );

  Widget _combatantCard({
    required String title,
    required Color accent,
    required int hp,
    required int maxHp,
    required int attack,
    required int defense,
    required List<StatusEffect> effects,
    String? subtitle,
    int shield = 0,
    String? chances,
    int? resourceValue,
    int? resourceMax,
    Color? resourceColor,
    String? resourceLabel,
  }) => Card(
    color: const Color(0xFF1E1E24),
    shape: RoundedRectangleBorder(side: BorderSide(color: accent, width: 1.3), borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accent)),
        if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.amberAccent)),
        const Divider(),
        BarWidget(value: hp.clamp(0, maxHp).toDouble(), max: max(1, maxHp).toDouble(), color: Colors.green, label: 'HP'),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Visibility(
            visible: shield > 0,
            maintainSize: true, maintainAnimation: true, maintainState: true,
            child: BarWidget(value: shield.toDouble(), max: max(1, maxHp * 1.5).toDouble(), color: const Color(0xFF64B5F6), label: tr('Štít', 'Shield')),
          ),
        ),
        if (resourceValue != null) Padding(padding: const EdgeInsets.only(top: 5), child: BarWidget(value: resourceValue.toDouble(), max: max(1, resourceMax ?? 1).toDouble(), color: resourceColor ?? Colors.blueAccent, label: resourceLabel ?? 'Resource')),
        const SizedBox(height: 7),
        Text('ATK: ${formatCompactNumber(attack)}', style: const TextStyle(fontSize: 11)),
        Text('ARMOR: ${formatCompactNumber(defense)}', style: const TextStyle(fontSize: 11)),
        if (chances != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(chances, style: const TextStyle(fontSize: 10, color: Colors.tealAccent))),
        const SizedBox(height: 8),
        _effects(tr('Buffy / Debuffy:', 'Buffs / Debuffs:'), effects),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      if (state.heroClass == HeroClass.none) return Center(child: Text(tr('Nejprve zvol hrdinu.', 'First choose a hero.')));
      if (!state.arenaUnlocked) return Center(child: Text(tr('Aréna se odemkne na levelu ${GameState.arenaUnlockLevel}.', 'The Arena unlocks at level ${GameState.arenaUnlockLevel}.')));
      if (state.arenaChestPending) {
        return SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedTreasureChest(
                title: tr('Truhla za dokončenou ligu', 'League completion chest'),
                subtitle: tr('Ťukni na truhlu pro otevření a vyzvednutí kořisti.', 'Tap the chest to open it and collect the loot.'),
                accent: const Color(0xFFFFD700),
                onOpen: () => state.openArenaChest(),
              ),
            ),
          ),
        );
      }
      if (state.arenaChestLoot.isNotEmpty) {
        return SingleChildScrollView(
          child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFFD700).withOpacity(.35), Colors.transparent]), boxShadow: const [BoxShadow(color: Color(0x66FFD700), blurRadius: 26, spreadRadius: 2)]),
                  child: const Icon(Icons.auto_awesome, size: 48, color: Color(0xFFFFD700)),
                ),
                const SizedBox(height: 14),
                Text(tr('Získaná kořist', 'Loot obtained'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                const SizedBox(height: 12),
                for (int i = 0; i < state.arenaChestLoot.length; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 350 + i * 120),
                    curve: Curves.easeOut,
                    builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child)),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFD700).withOpacity(.35))),
                      child: Text(state.arenaChestLoot[i], style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => state.dismissArenaChestLoot(),
                  child: Text(tr('Pokračovat', 'Continue')),
                ),
              ],
            ),
          ),
          ),
        );
      }
      return DefaultTabController(
        length: 2,
        initialIndex: initialTab,
        child: Column(
          children: [
            Material(
              color: const Color(0xFF18181D),
              child: TabBar(
                labelColor: const Color(0xFFFFD700),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFFD700),
                tabs: [
                  Tab(icon: const Icon(Icons.sports_mma), text: tr('Souboj', 'Battle')),
                  Tab(icon: const Icon(Icons.auto_awesome), text: tr('Relic', 'Relic')),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _combatTab(context, state),
                  ArenaRelicTab(state: state),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _combatTab(BuildContext context, GameState state) {
      final league = state.arenaIsGladiator ? tr('Gladiátor • rating ${state.arenaRating}', 'Gladiator • rating ${state.arenaRating}') : tr('${state.arenaLeague.label} • úroveň ${state.arenaLevelIndex + 1}/5 • ⭐ ${state.arenaStars}/5', '${state.arenaLeague.label} • level ${state.arenaLevelIndex + 1}/5 • ⭐ ${state.arenaStars}/5');
      // Čerstvý vstup do Arény (žádný předchozí soupeř v tomhle sezení) se spustí rovnou -
      // potvrzení se ptá jen MEZI souboji, viz arenaAwaitingConfirm nastavené v _handleArenaWin/Loss.
      if (state.arenaOpponentClass == null && !state.arenaAwaitingConfirm) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state.arenaOpponentClass == null && !state.arenaAwaitingConfirm) state.generateArenaOpponent();
        });
        return const Center(child: CircularProgressIndicator());
      }
      if (state.arenaOpponentClass == null) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            FantasyPanel(title: tr('ARÉNA', 'ARENA'), titleIcon: Icons.sports_mma, accent: Colors.deepOrangeAccent, child: Column(children: [
              Text(league, style: const TextStyle(fontWeight: FontWeight.bold, color: FantasyColors.gold)),
              const SizedBox(height: 4),
              Text(tr('Výhry ${state.arenaWins} • Prohry ${state.arenaLosses}', 'Wins ${state.arenaWins} • Losses ${state.arenaLosses}'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            const SizedBox(height: 40),
            const Icon(Icons.sports_mma, size: 72, color: Colors.deepOrangeAccent),
            const SizedBox(height: 16),
            Text(tr('Chceš další souboj?', 'Ready for another fight?'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FantasyColors.parchment)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
              icon: const Icon(Icons.play_arrow),
              label: Text(tr('Další souboj', 'Next battle')),
              onPressed: () => state.confirmNextArenaFight(),
            ),
          ]),
        );
      }
      final opponentName = heroClassLabel(state.arenaOpponentClass!);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          FantasyPanel(title: tr('ARÉNA', 'ARENA'), titleIcon: Icons.sports_mma, accent: Colors.deepOrangeAccent, child: Column(children: [
            Text(league, style: const TextStyle(fontWeight: FontWeight.bold, color: FantasyColors.gold)),
            const SizedBox(height: 4),
            Text(tr('Výhry ${state.arenaWins} • Prohry ${state.arenaLosses} • Kolo ${state.arenaCombatRoundCount}', 'Wins ${state.arenaWins} • Losses ${state.arenaLosses} • Round ${state.arenaCombatRoundCount}'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _combatantCard(
              title: state.heroName.isEmpty ? heroClassLabel(state.heroClass) : state.heroName,
              subtitle: '${heroClassLabel(state.heroClass)} • ${state.specializationName}',
              accent: const Color(0xFF64B5F6), hp: state.hp, maxHp: state.maxHp,
              attack: state.classIsMagicAttack ? state.magAtk : state.physAtk,
              defense: state.armor, shield: state.bonusShield, effects: state.heroEffects,
              chances: tr('Crit ${(state.critChance * 100).toStringAsFixed(1)} % • Dodge ${(state.dodgeChance * 100).toStringAsFixed(1)} % • Block ${(state.blockChance * 100).toStringAsFixed(1)} %', 'Crit ${(state.critChance * 100).toStringAsFixed(1)}% • Dodge ${(state.dodgeChance * 100).toStringAsFixed(1)}% • Block ${(state.blockChance * 100).toStringAsFixed(1)}%'),
              resourceValue: state.currentResourceValue, resourceMax: state.maxResourceValue, resourceColor: state.resourceColor, resourceLabel: state.resourceName,
            )),
            const Padding(padding: EdgeInsets.fromLTRB(5, 54, 5, 0), child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent))),
            Expanded(child: _combatantCard(
              title: opponentName, subtitle: tr('Specializace ${state.arenaOpponentSpec}', 'Specialization ${state.arenaOpponentSpec}'), accent: Colors.redAccent,
              hp: state.arenaOpponentHp, maxHp: state.arenaOpponentMaxHp, attack: state.arenaOpponentAtk,
              defense: state.arenaOpponentDef, shield: state.arenaOpponentShield, effects: state.enemyEffects,
              chances: state.arenaOpponentIsMagic ? tr('Magický protivník', 'Magic opponent') : tr('Fyzický protivník', 'Physical opponent'),
            )),
          ]),
          const SizedBox(height: 10),
          CombatLogSection(state: state, message: state.message, type: classifyCombatMessage(state.message)),
          const SizedBox(height: 10),
          if (classPassiveBar(state) != null) ...[
            classPassiveBar(state)!,
            const SizedBox(height: 8),
          ],
          Builder(builder: (context) {
            final healingPotionsCount = state.consumables.where((i) => i.name == "Léčivý lektvar").fold<int>(0, (sum, i) => sum + i.stackCount);
            final vampirePotionsCount = state.consumables.where((i) => i.name == "Upíří Lektvar").fold<int>(0, (sum, i) => sum + i.stackCount);
            return combatActionGrid(
              basicAttack: SpellIconButton(
                visual: basicAttackVisual(state), size: 62,
                costLabel: tr('Základní útok', 'Basic Attack'),
                onPressed: state.arenaOpponentClass == null ? null : () => state.fightArenaOpponent(state.classIsMagicAttack),
              ),
              tier1: state.hasAdvancedClass
                  ? SpellIconButton(
                      visual: spellVisualTier1(state.heroClass),
                      costLabel: '${state.ability1Cost} ${state.resourceName}',
                      disabled: state.currentResourceValue < state.ability1Cost,
                      onPressed: state.useArenaActiveAbility,
                    )
                  : lockedAbilitySlot(state, spellVisualTier1(state.heroClass), 15),
              tier2: state.hasUltimateClass
                  ? SpellIconButton(
                      visual: spellVisualTier2(state.heroClass),
                      costLabel: '${state.ability2Cost} ${state.resourceName}',
                      disabled: state.currentResourceValue < state.ability2Cost,
                      onPressed: state.useArenaSecondAbility,
                    )
                  : lockedAbilitySlot(state, spellVisualTier2(state.heroClass), 40),
              tier3: state.hasGodClass
                  ? SpellIconButton(
                      visual: spellVisualTier3(state.heroClass),
                      costLabel: '${state.ability3Cost} ${state.resourceName}',
                      disabled: state.currentResourceValue < state.ability3Cost,
                      onPressed: state.useArenaThirdAbility,
                    )
                  : lockedAbilitySlot(state, spellVisualTier3(state.heroClass), 75),
              tier4: state.hasRank100Class
                  ? SpellIconButton(
                      visual: spellVisualTier4(state.heroClass, state.rank100Choice),
                      costLabel: '${state.ability4Cost} ${state.resourceName}',
                      disabled: state.currentResourceValue < state.ability4Cost,
                      onPressed: state.useArenaFourthAbility,
                    )
                  : lockedTier4Slot(state),
              relic: state.currentSpecRelicUnlocked
                  ? SpellIconButton(
                      visual: SpellVisual('Relic: ${state.currentSpecRelic.spell}', state.currentSpecRelic.icon, state.currentSpecRelic.color),
                      costLabel: state.isSpecRelicEquipped
                          ? (state.heroClass == HeroClass.deathknight ? tr('Uvolnit duše', 'Release Souls') : 'Relic spell')
                          : tr('Nutno nasadit v Inventáři!', 'Must be equipped in Inventory!'),
                      disabled: !state.isSpecRelicEquipped || state.specRelicUsedArena,
                      overlayText: !state.isSpecRelicEquipped ? tr('Nenasazen', 'Not equipped') : (state.specRelicUsedArena ? tr('Použito', 'Used') : null),
                      onPressed: state.useSpecRelicArenaSpell,
                    )
                  : lockedRelicSlot(),
              healPotion: ConsumableIconButton(
                icon: Icons.medical_services, color: Colors.greenAccent, count: healingPotionsCount,
                tooltip: tr('Léčivé lektvary nelze v Aréně použít.', 'Healing potions cannot be used in the Arena.'),
                active: false,
                onPressed: null,
              ),
              vampirePotion: ConsumableIconButton(
                icon: Icons.water_drop, color: Colors.purpleAccent, count: vampirePotionsCount,
                tooltip: tr('Upíří lektvary nelze v Aréně použít.', 'Vampiric potions cannot be used in the Arena.'),
                active: false,
                onPressed: null,
              ),
            );
          }),
          const SizedBox(height:10),
          _relicQuickCard(context, state),
          const SizedBox(height: 5),
          TextButton.icon(
            onPressed: state.conquerorCoins >= state.arenaRerollCost ? state.rerollArenaOpponent : null,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(tr('Nový soupeř (${state.arenaRerollCost} 🏅)', 'New opponent (${state.arenaRerollCost} 🏅)')),
          ),
        ]),
      );
  }

  // Kompaktní karta v souboji: jen ikona/název/level relicu a odkaz na plnou Relic obrazovku
  // (druhý tab), kde je level-up, mastery efekty a lore. Spell tlačítko je teď u ostatních
  // schopností výše (Schopnost 1-4), ne tady - jedno místo pro všechny bojové akce.
  Widget _relicQuickCard(BuildContext context, GameState state) {
    final r = state.currentSpecRelic;
    return FantasyPanel(
      title: tr('SPECIALIZAČNÍ RELIC', 'SPECIALIZATION RELIC'), titleIcon: Icons.auto_awesome, accent: r.color,
      child: Row(children: [
        Icon(r.icon, color: r.color, size: 28),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            state.currentSpecRelicUnlocked
                ? (state.isSpecRelicEquipped ? tr('Lv ${state.currentSpecRelicLevel} • nasazen', 'Lv ${state.currentSpecRelicLevel} • equipped') : tr('Lv ${state.currentSpecRelicLevel} • ⚠ NENASAZEN (Inventář)', 'Lv ${state.currentSpecRelicLevel} • ⚠ NOT EQUIPPED (Inventory)'))
                : tr('Nezískán - padá po výhře v Aréně', 'Not obtained - drops from winning in the Arena'),
            style: TextStyle(fontSize: 11, color: state.currentSpecRelicUnlocked && !state.isSpecRelicEquipped ? Colors.orangeAccent : Colors.grey),
          ),
        ])),
        TextButton.icon(
          onPressed: () => DefaultTabController.of(context)?.animateTo(1),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(tr('Detail', 'Details')),
        ),
      ]),
    );
  }
}

// ===== VLASTNÍ OBRAZOVKA RELICU (2. tab Arény) =====
// Plná verze specializačního Relicu: velký header, progress k dalšímu levelu,
// staty, spell tlačítko a kompletní seznam masteries s vizuálním odlišením
// odemčeno/zamčeno + zvýrazněním dalšího nejbližšího levelu.
class ArenaRelicTab extends StatelessWidget {
  final GameState state;
  const ArenaRelicTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final r = state.currentSpecRelic;
    final unlocked = state.currentSpecRelicUnlocked;
    final level = state.currentSpecRelicLevel;
    // Nejbližší ještě neodemčený efekt - zvýrazní se v seznamu jako "další cíl".
    final nextEffect = r.effects.where((e) => e.level > level).isEmpty ? null : r.effects.where((e) => e.level > level).first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // ===== HLAVIČKA =====
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [r.color.withOpacity(.25), const Color(0xFF1A1511)]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: r.color, width: 1.6),
          ),
          child: Column(children: [
            Icon(r.icon, color: r.color, size: 56),
            const SizedBox(height: 8),
            Text(r.name, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: r.color)),
            Text(r.form, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('${heroClassLabel(state.heroClass)} • ${state.specializationName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            if (!unlocked) ...[
              const Icon(Icons.lock, color: Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(tr('Nezískán. Šance na drop roste s ligou Arény - poraz soupeře a zkus štěstí.', 'Not obtained. Drop chance increases with Arena league - defeat opponents and try your luck.'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
              const SizedBox(height: 8),
              Text(
                tr('Pity: ${state.specRelicPityCounter[state.currentSpecRelicKey] ?? 0}/${GameState.specRelicPityThreshold} výher bez dropu (garantováno na ${GameState.specRelicPityThreshold})', 'Pity: ${state.specRelicPityCounter[state.currentSpecRelicKey] ?? 0}/${GameState.specRelicPityThreshold} wins without a drop (guaranteed at ${GameState.specRelicPityThreshold})'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
              ),
            ] else ...[
              const SizedBox(height: 6),
              FantasyProgressBar(value: level.toDouble(), max: GameState.maxSpecRelicLevel.toDouble(), color: r.color, label: tr('LEVEL', 'LEVEL'), segmented: true, segments: 10),
              if (!state.isSpecRelicEquipped) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orangeAccent)),
                  child: Row(children: [
                    const Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tr('Relic je v Inventáři, ale NENÍ nasazen - bonus ani spell nefungují, dokud ho nenasadíš do 11. slotu (Relic).', 'The Relic is in your Inventory, but is NOT equipped - the bonus and spell do not work until you equip it in the 11th slot (Relic).'), style: const TextStyle(fontSize: 12, color: Colors.orangeAccent))),
                  ]),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                    onPressed: () => openWorldScreen(context, tr('Inventář', 'Inventory'), const InventoryScreen()),
                    icon: const Icon(Icons.backpack),
                    label: Text(tr('Otevřít Inventář a nasadit', 'Open Inventory and equip')),
                  ),
                ),
              ],
            ],
          ]),
        ),
        const SizedBox(height: 12),

        // ===== STATY & MĚNA =====
        if (unlocked) FantasyPanel(
          title: tr('BONUSY & VYLEPŠENÍ', 'BONUSES & UPGRADES'), titleIcon: Icons.trending_up, accent: r.color,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _statChip('Main stat', '+${state.specRelicMainStatBonus}', Icons.fitness_center, r.color)),
              const SizedBox(width: 8),
              Expanded(child: _statChip(tr('Vitalita', 'Vitality'), '+${state.specRelicVitalityBonus}', Icons.favorite, r.color)),
            ]),
            const SizedBox(height: 10),
            Text(tr('Mince dobyvatele: ${state.conquerorCoins} 🏅', 'Conqueror Coins: ${state.conquerorCoins} 🏅'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
            if (level < GameState.maxSpecRelicLevel) Text(tr('Cena dalšího levelu: ${state.currentSpecRelicUpgradeCost} 🏅', 'Next level cost: ${state.currentSpecRelicUpgradeCost} 🏅'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: r.color, foregroundColor: Colors.black),
                onPressed: level < GameState.maxSpecRelicLevel ? state.levelCurrentSpecRelic : null,
                icon: const Icon(Icons.upgrade),
                label: Text(level >= GameState.maxSpecRelicLevel ? tr('Maximální level', 'Maximum level') : tr('Vylepšit Relic', 'Upgrade Relic')),
              ),
            ),
            const SizedBox(height: 8),
            // Spell se aktivuje v boji - viz tlačítko "Relic: ${spell}" vedle ostatních
            // schopností na tabu Souboj. Tady jen informace, co spell dělá.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(8), border: Border.all(color: r.color.withOpacity(.4))),
              child: Row(children: [
                Icon(r.icon, color: r.color, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(tr('Spell „${r.spell}“ se používá v boji vedle ostatních schopností.', 'The spell "${r.spell}" is used in combat alongside your other abilities.'), style: const TextStyle(fontSize: 11, color: Colors.grey))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ===== MASTERY / EFEKTY =====
        FantasyPanel(
          title: tr('MASTERY', 'MASTERY') + ' ${unlocked ? "$level" : "0"}/${GameState.maxSpecRelicLevel}', titleIcon: Icons.auto_stories, accent: r.color,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final e in r.effects)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(
                    e.level <= level ? Icons.check_circle : (e == nextEffect ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    size: 16,
                    color: e.level <= level ? r.color : (e == nextEffect ? Colors.amberAccent : Colors.grey.shade700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('Lv ${e.level}: ${e.name}', 'Lv ${e.level}: ${e.name}'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: e.level <= level ? Colors.white : (e == nextEffect ? Colors.amberAccent : Colors.grey))),
                      Text(e.description, style: TextStyle(fontSize: 11, color: e.level <= level ? Colors.grey.shade300 : Colors.grey.shade600)),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _statChip(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(.5))),
    child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );
}

class _SpellbookEntry {
  final SpellVisual visual;
  final String desc;
  const _SpellbookEntry(this.visual, this.desc);
}

// ===== KNIHA KOUZEL (Spellbook) — vysvětluje spelly AKTUÁLNÍHO buildu hráče a jejich
// synergie mezi sebou (rotace) a se sety (Hardcore Set popisky jsou už vázané na jmenovité
// spelly, takže se dají znovupoužít 1:1 - žádný duplicitní text). =====
class SpellbookScreen extends StatelessWidget {
  const SpellbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      if (state.heroClass == HeroClass.none) return const Center(child: Text('Nejprve zvol hrdinu.'));
      final c = state.heroClass;
      final hcSet = state.activeHardcoreSetDef;
      final gearSet = state.activeGearSetDef;

      final spells = <_SpellbookEntry>[
        _SpellbookEntry(basicAttackVisual(state), 'Základní útok - používá se v každém kole boje. (${state.spellLiveEffectText(0)})'),
        if (state.hasAdvancedClass) _SpellbookEntry(spellVisualTier1(c), '${spellShortDesc(c, 1)} (${state.spellLiveEffectText(1)})'),
        if (state.hasUltimateClass) _SpellbookEntry(spellVisualTier2(c), '${spellShortDesc(c, 2)} (${state.spellLiveEffectText(2)})'),
        if (state.hasGodClass) _SpellbookEntry(spellVisualTier3(c), '${spellShortDesc(c, 3)} (${state.spellLiveEffectText(3)})'),
        if (state.hasRank100Class) _SpellbookEntry(spellVisualTier4(c, state.rank100Choice), '${spellShortDesc(c, 4, choice: state.rank100Choice)} (${state.spellLiveEffectText(4, choice: state.rank100Choice)})'),
        if (state.currentSpecRelicUnlocked) _SpellbookEntry(
          SpellVisual('Relic: ${state.currentSpecRelic.spell}', state.currentSpecRelic.icon, state.currentSpecRelic.color),
          state.currentSpecRelic.effects.isNotEmpty ? state.currentSpecRelic.effects.first.description : 'Speciální spell ze specializačního Relicu.',
        ),
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF241C30), FantasyColors2.obsidian]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FantasyColors.gold, width: 1.3),
            ),
            child: Column(children: [
              const Text('KNIHA KOUZEL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FantasyColors.gold, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text('${heroClassLabel(c)} • ${state.specializationName}', style: const TextStyle(color: Colors.grey)),
            ]),
          ),
          const SizedBox(height: 14),

          FantasyPanel(
            title: 'TVÉ SPELLY', titleIcon: Icons.auto_stories, accent: FantasyColors.gold,
            child: Column(children: [
              for (final e in spells)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SpellIconButton(visual: e.visual, onPressed: null, size: 46),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.visual.name, style: TextStyle(fontWeight: FontWeight.bold, color: e.visual.color)),
                      const SizedBox(height: 2),
                      Text(e.desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ])),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 12),

          FantasyPanel(
            title: 'SYNERGIE MEZI SPELLY', titleIcon: Icons.hub, accent: Colors.tealAccent,
            child: Text(spellRotationTip(c), style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
          const SizedBox(height: 12),

          FantasyPanel(
            title: 'SYNERGIE SE SETY', titleIcon: Icons.checkroom, accent: Colors.cyanAccent,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (hcSet != null) ...[
                Text(hcSet.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                const SizedBox(height: 4),
                Text('2 ks: +${hcSet.statValue} ${hcSet.statName} × tvůj level × nasazené kusy (živě, ne napevno).', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('4 ks: ${hcSet.fourPieceDesc}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('6 ks: ${hcSet.sixPieceDesc}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('8 ks: ${hcSet.eightPieceDesc}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Text('Aktuálně nasazeno: ${state.equippedHardcoreSetCounts[hcSet.id] ?? 0}/8 ks', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ] else
                const Text('Pro tvou třídu/specializaci zatím nemáš Hardcore set - padá jen v Hardcore Mode a mění fungování konkrétních spellů.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              if (gearSet != null) ...[
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 4),
                Text(gearSet.name, style: const TextStyle(fontWeight: FontWeight.bold, color: FantasyColors.gold)),
                const SizedBox(height: 4),
                Text('2 ks: +${gearSet.statValue} ${gearSet.statName} × tvůj level (aktuálně +${gearSet.statValue * state.level}).', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('4 ks: ${gearSet.fourPieceDesc}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('6 ks: ${gearSet.sixPieceDesc}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('8 ks: ${gearSet.eightPieceDesc}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Text('Aktuálně nasazeno: ${state.activeGearSetTier} ks', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ]),
          ),
        ]),
      );
    });
  }
}

class FantasyPanel extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color accent;
  const FantasyPanel({super.key, this.title, this.titleIcon, required this.child, this.padding = const EdgeInsets.all(12), this.accent = FantasyColors.bronze});
  @override Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FantasyColors.panelLight, FantasyColors.panel, Color(0xFF100D0B)]),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: accent, width: 1.6),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.75), blurRadius: 14, offset: const Offset(0, 6)), BoxShadow(color: accent.withOpacity(.10), blurRadius: 8, spreadRadius: 1)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (title != null) Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(gradient: LinearGradient(colors:[accent.withOpacity(.42), const Color(0xFF21170F), accent.withOpacity(.20)]), border: Border(bottom: BorderSide(color: accent))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children:[if(titleIcon!=null)...[Icon(titleIcon,color:FantasyColors.gold,size:20),const SizedBox(width:8)], Flexible(child:Text(title!,textAlign:TextAlign.center,style: GoogleFonts.cinzel(color:FantasyColors.parchment,fontWeight:FontWeight.w700,fontSize:17,letterSpacing:1.0)))]),
      ),
      Padding(padding: padding, child: child),
    ]),
  );
}

class FantasyButton extends StatelessWidget {
  final String text; final VoidCallback? onPressed; final IconData icon; final Color accent;
  const FantasyButton({super.key, required this.text, required this.onPressed, this.icon=Icons.auto_awesome, this.accent=FantasyColors.gold});
  @override Widget build(BuildContext context)=>ElevatedButton.icon(onPressed:onPressed,icon:Icon(icon,size:18,color:accent),label:Text(text),style:ElevatedButton.styleFrom(backgroundColor:FantasyColors.button,foregroundColor:FantasyColors.parchment,side:BorderSide(color:accent),padding:const EdgeInsets.symmetric(horizontal:14,vertical:13)));
}

class LootPriorityPanel extends StatelessWidget {
  const LootPriorityPanel({super.key});
  @override Widget build(BuildContext context) => Consumer<GameState>(builder: (context, state, _) => FantasyPanel(
    title: tr('LOOT PRIORITA', 'LOOT PRIORITY'),
    titleIcon: Icons.filter_list,
    accent: FantasyColors.gold,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
        tr('Určuje, podle čeho hra vyhodnocuje "SÍLA X" u itemů a které vybavení navrhne jako lepší při sundání/nasazení. Nemění staty na itemech, jen jak moc si jich hra cení pro tvůj konkrétní playstyle.',
            'Determines what the game scores "POWER X" against on items and which gear it suggests as better when swapping. Doesn\'t change stats on items, just how much the game values them for your playstyle.'),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      const SizedBox(height: 12),
      for (final mode in LootPriorityMode.values) ...[
        _lootPriorityCard(context, state, mode),
        if (mode != LootPriorityMode.values.last) const SizedBox(height: 10),
      ],
    ]),
  ));

  Widget _lootPriorityCard(BuildContext context, GameState state, LootPriorityMode mode) {
    final selected = state.lootPriorityMode == mode;
    final icon = switch (mode) {
      LootPriorityMode.balanced => Icons.balance,
      LootPriorityMode.offensive => Icons.local_fire_department,
      LootPriorityMode.defensive => Icons.shield,
    };
    final accent = switch (mode) {
      LootPriorityMode.balanced => FantasyColors.gold,
      LootPriorityMode.offensive => Colors.redAccent,
      LootPriorityMode.defensive => const Color(0xFF3B82F6),
    };
    return InkWell(
      onTap: () => state.setLootPriorityMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(.14) : const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? accent : Colors.grey.shade800, width: selected ? 1.6 : 1),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lootPriorityModeName(mode), style: TextStyle(color: selected ? accent : const Color(0xFFF1E6D0), fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(lootPriorityModeDescription(mode), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          if (selected) Icon(Icons.check_circle, color: accent, size: 20),
        ]),
      ),
    );
  }
}

/// Zkrátí velká čísla (HP, XP, ...) na čitelný tvar s K/M/B příponou, aby staty
/// v pozdní hře (statisíce až miliony HP) zůstaly na obrazovce čitelné.
/// Pod 1000 vrací přesné celé číslo, nad tím 1 desetinné místo (0 od 10 dané jednotky výš).
String formatCompactNumber(num n) {
  final v = n.toDouble();
  final a = v.abs();
  if (a >= 1e9) return '${(v / 1e9).toStringAsFixed(a >= 1e10 ? 0 : 1)}B';
  if (a >= 1e6) return '${(v / 1e6).toStringAsFixed(a >= 1e7 ? 0 : 1)}M';
  if (a >= 1e3) return '${(v / 1e3).toStringAsFixed(a >= 1e4 ? 0 : 1)}K';
  return v.toInt().toString();
}

class FantasyProgressBar extends StatefulWidget {
  final double value; final double max; final Color color; final String label; final IconData? icon;
  // segmented: pro "level" typ progresu (XP, mastery, relic level) místo plynulého HP/resource
  // baru - vykreslí tenké oddělovací zářezy přes celou šířku, aby šlo na první pohled poznat
  // "roste po krocích" (level) od "plyne kontinuálně" (HP/resource). Viz bod 6 grafického review.
  final bool segmented; final int segments;
  const FantasyProgressBar({super.key,required this.value,required this.max,required this.color,required this.label,this.icon,this.segmented=false,this.segments=10});
  @override
  State<FantasyProgressBar> createState() => _FantasyProgressBarState();
}

class _FantasyProgressBarState extends State<FantasyProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  // Pulzuje jen u HP baru, a jen když je hráč pod 20 % zdraví (a ještě žije).
  bool get _isLowHp => widget.label == 'HP' && widget.max > 0 && widget.value > 0 && (widget.value / widget.max) < 0.2;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.max <= 0 ? 0.0 : (widget.value / widget.max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          if (widget.icon != null) ...[Icon(widget.icon, color: widget.color, size: 16), const SizedBox(width: 5)],
          Text(widget.label, style: const TextStyle(color: FantasyColors.parchment, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 3),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = _isLowHp ? _pulseController.value : 0.0;
            final borderColor = _isLowHp ? Color.lerp(FantasyColors.bronze, Colors.redAccent, pulse)! : FantasyColors.bronze;
            final glowColor = _isLowHp ? Colors.redAccent : widget.color;
            final glowOpacity = _isLowHp ? 0.18 + pulse * 0.5 : 0.18;
            final glowBlur = _isLowHp ? 6 + pulse * 8 : 6.0;
            return Container(
              height: 25,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: _isLowHp ? 1.4 + pulse : 1.4),
                boxShadow: [BoxShadow(color: glowColor.withOpacity(glowOpacity), blurRadius: glowBlur)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(children: [
                  // "Duch" HP baru: zpožděně dojíždí za skutečnou hodnotou (klasický JRPG trik) -
                  // hlavní bar skočí okamžitě, tenhle světlejší pruh za ním "dobíhá" ~500ms, takže
                  // oko čte přesně tolik, kolik se právě ztratilo. Jen u HP bar (label obsahuje "HP").
                  if (widget.label.contains('HP'))
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: widget.value, end: widget.value),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, shadowValue, child) {
                        final sf = widget.max <= 0 ? 0.0 : (shadowValue / widget.max).clamp(0.0, 1.0);
                        return FractionallySizedBox(widthFactor: sf, child: Container(color: Colors.white.withOpacity(0.30)));
                      },
                    ),
                  FractionallySizedBox(
                    widthFactor: f,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color.lerp(widget.color, Colors.white, .22)!, widget.color, Color.lerp(widget.color, Colors.black, .30)!],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${formatCompactNumber(widget.value)} / ${formatCompactNumber(widget.max)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, shadows: [Shadow(color: Colors.black, blurRadius: 3)]),
                    ),
                  ),
                  if (widget.segmented)
                    Positioned.fill(
                      child: Row(
                        children: List.generate(widget.segments, (i) => Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(right: BorderSide(color: Colors.black.withOpacity(i == widget.segments - 1 ? 0 : 0.4), width: 1.5)),
                            ),
                          ),
                        )),
                      ),
                    ),
                ]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class FantasyStatTile extends StatelessWidget {
  final IconData icon; final Color color; final String label; final String value;
  const FantasyStatTile({super.key,required this.icon,required this.color,required this.label,required this.value});
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(vertical:8,horizontal:8),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0xFF49341F),width:.7))),child:Row(children:[Container(width:31,height:31,decoration:BoxDecoration(shape:BoxShape.circle,color:color.withOpacity(.18),border:Border.all(color:color.withOpacity(.65))),child:Icon(icon,color:color,size:19)),const SizedBox(width:10),Expanded(child:Text(label,style:const TextStyle(color:FantasyColors.parchment,fontSize:15))),Text(value,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:16))]));
}

enum CombatLogType { damage, critical, heal, rune, boss, loot, system }

// Sdílená klasifikace zprávy podle klíčových slov - stejná napříč všemi combat obrazovkami,
// ať CombatLogSection barví konzistentně bez ohledu na to, odkud zpráva přišla.
CombatLogType classifyCombatMessage(String msg) {
  if (msg.contains('Kritický') || msg.contains('kriticky') || msg.contains('Critical') || msg.contains('critical')) return CombatLogType.critical;
  if (msg.contains('vyléč') || msg.contains('heal') || msg.contains('Heal')) return CombatLogType.heal;
  if (msg.contains('odplata') || msg.contains('Odplata') || msg.contains('retribution') || msg.contains('Retribution')) return CombatLogType.rune;
  if (msg.contains('Výhra') || msg.contains('Victory') || msg.contains('victory')) return CombatLogType.loot;
  if (msg.contains('Prohra') || msg.contains('Defeat') || msg.contains('defeat')) return CombatLogType.damage;
  if (msg.contains('Boss') || msg.contains('boss')) return CombatLogType.boss;
  return CombatLogType.system;
}

class FantasyCombatLogEntry { final String text; final CombatLogType type; const FantasyCombatLogEntry(this.text,this.type); Color get color=>switch(type){CombatLogType.critical=>FantasyColors.gold,CombatLogType.heal=>Colors.greenAccent,CombatLogType.rune=>Colors.purpleAccent,CombatLogType.boss=>Colors.deepOrangeAccent,CombatLogType.loot=>Colors.amber,CombatLogType.damage=>FantasyColors.parchment,CombatLogType.system=>Colors.blueGrey.shade200}; }
class FantasyCombatLog extends StatelessWidget {
  final List<FantasyCombatLogEntry> entries; const FantasyCombatLog({super.key,required this.entries});
  @override Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final e = entries.last;
    return Container(
      width: double.infinity,
      height: 38, // Pevná výška - text se ořízne na 1 řádek (dřív maxLines:3 měnilo výšku podle
                  // délky zprávy, což posouvalo spelly/lektvary pod tím). Sdíleno napříč Věží/
                  // Arénou/Lair/World Bossem/Riftem/Endless Scale (viz CombatLogSection).
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FantasyColors.panelLight, FantasyColors.panel, Color(0xFF100D0B)]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FantasyColors.bronze, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, color: FantasyColors.gold, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(e.text, style: TextStyle(color: e.color, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// Univerzální obal pro combat log napříč Věží/Arénou/Lair/World Bossem/Riftem/Endless Scale:
// vlevo samotný log (nebo nic, když je vypnutý), vpravo malá ikonka oko/oko-přeškrtnuté pro
// zapnutí/vypnutí. Přepínač je globální (GameState.combatLogEnabled), takže se stav sdílí
// mezi všemi obrazovkami, ale samotné tlačítko je dostupné na každé z nich zvlášť.
class CombatLogSection extends StatelessWidget {
  final GameState state; final String message; final CombatLogType type;
  const CombatLogSection({super.key, required this.state, required this.message, this.type = CombatLogType.system});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: state.combatLogEnabled
              ? FantasyCombatLog(entries: [FantasyCombatLogEntry(message, type)])
              : const SizedBox.shrink(),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          iconSize: 18,
          tooltip: state.combatLogEnabled ? 'Vypnout combat log' : 'Zapnout combat log',
          icon: Icon(state.combatLogEnabled ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
          onPressed: state.toggleCombatLog,
        ),
      ],
    );
  }
}

