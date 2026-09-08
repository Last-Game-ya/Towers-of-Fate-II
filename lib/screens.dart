part of 'main.dart';

class BarWidget extends StatelessWidget {
  final double value; final double max; final Color color; final String label;
  const BarWidget({super.key,required this.value,required this.max,required this.color,required this.label});
  @override Widget build(BuildContext context)=>FantasyProgressBar(value:value,max:max,color:color,label:label,icon:label.contains('HP')?Icons.favorite:label=='XP'?Icons.star:label=='Štít'?Icons.shield:Icons.auto_awesome,segmented:label=='XP');
}

// ===== TUTORIAL TIP CONTENT (viz TutorialTipId/TutorialTipDef v data_models.dart) =====
// Sdílený obsah pro lineární úvodní tutoriál i jednorázové kontextové tipy (Runy/Lair/Aréna/
// atd.) - vždy viditelné krátké "casual" vysvětlení + tlačítko "Zobrazit pokročilé", které
// rozbalí min-max Pro-tip. Použití: showFantasyInfoDialog / vlastní AlertDialog (viz
// CelebrationOverlayHost v ui_design.dart) s content: TutorialTipContent(def: ..., color: ...).
class TutorialTipContent extends StatefulWidget {
  final TutorialTipDef def;
  final Color color;
  const TutorialTipContent({super.key, required this.def, required this.color});
  @override
  State<TutorialTipContent> createState() => _TutorialTipContentState();
}

class _TutorialTipContentState extends State<TutorialTipContent> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.def;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(d.basicCz, d.basicEn), style: const TextStyle(color: FantasyColors2.runeText, fontSize: 14, height: 1.4)),
        const SizedBox(height: 10),
        if (!_showAdvanced)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showAdvanced = true),
              icon: Icon(Icons.insights, size: 16, color: widget.color),
              label: Text(tr('Zobrazit pokročilé', 'Show advanced'), style: TextStyle(color: widget.color, fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: widget.color.withOpacity(0.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: widget.color.withOpacity(0.4))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.insights, size: 16, color: widget.color),
              const SizedBox(width: 8),
              Expanded(child: Text(tr(d.advancedCz, d.advancedEn), style: TextStyle(color: widget.color, fontSize: 13, height: 1.4, fontStyle: FontStyle.italic))),
            ]),
          ),
      ],
    );
  }
}

// ===== COMBAT FX UI (dodge/blok/zásah/crit/vznik štítu - viz CombatFxEvent v GameState) =====
// Styl vylétávajícího textu podle typu eventu - jeden widget pro všechny 6 typů, liší se jen
// barva/text/velikost a u critu navíc krátký "punch" scale-bounce (žádné skutečné zamrznutí
// hry - to by vyžadovalo zdržet notifyListeners() napříč desítkami combat funkcí, riskantní
// zásah do už odladěné logiky; tenhle vizuální "impact" dá skoro stejný pocit bezpečněji).
class _FxVisual {
  final String text; final Color color; final double fontSize; final bool punch;
  const _FxVisual(this.text, this.color, this.fontSize, {this.punch = false});
}

_FxVisual _fxVisualFor(CombatFxEvent e) {
  switch (e.kind) {
    case FxKind.miss:
      return const _FxVisual('UHNUL!', Colors.white70, 15);
    case FxKind.blocked:
      return _FxVisual('🛡️ -${formatCompactNumber(e.value.toDouble())}', Colors.lightBlueAccent, 16);
    case FxKind.absorbed:
      return _FxVisual('🛡️ -${formatCompactNumber(e.value.toDouble())}', Colors.cyanAccent, 15);
    case FxKind.shieldGained:
      return _FxVisual('+${formatCompactNumber(e.value.toDouble())} 🛡️', const Color(0xFFC69214), 16);
    case FxKind.critDamage:
      return _FxVisual('💥 -${formatCompactNumber(e.value.toDouble())}', const Color(0xFFFFD700), 23, punch: true);
    case FxKind.normalDamage:
      return _FxVisual('-${formatCompactNumber(e.value.toDouble())}', Colors.white, 17);
    case FxKind.statusApplied:
      return _FxVisual(e.label ?? '✦ Efekt', const Color(0xFF80D8FF), 14);
    case FxKind.explosionDamage:
      return _FxVisual('💥💥 -${formatCompactNumber(e.value.toDouble())}', const Color(0xFFFF6E40), 26, punch: true);
    case FxKind.stunned:
      return _FxVisual(e.label ?? '🥶 ZMRAZEN!', const Color(0xFF80D8FF), 18, punch: true);
  }
}

class _CombatFxText extends StatelessWidget {
  final CombatFxEvent event; final VoidCallback onDone;
  const _CombatFxText({required this.event, required this.onDone});
  @override
  Widget build(BuildContext context) {
    final v = _fxVisualFor(event);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOut,
      onEnd: onDone,
      builder: (context, t, child) {
        final dy = -36.0 * t;
        final opacity = (1 - t).clamp(0.0, 1.0);
        double scale = 1.0;
        if (v.punch) {
          scale = t < 0.25 ? (1.0 + (t / 0.25) * 0.45) : (1.45 - ((t - 0.25) / 0.75) * 0.45);
        }
        return Align(
          alignment: Alignment(event.jitter * 1.6, -0.1),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Text(
                  v.text,
                  style: TextStyle(color: v.color, fontSize: v.fontSize, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===== RELIC BURST OVERLAY - velký "hero moment" efekt pro DK sigil finishery (Shatter/
// Apocalypse/Crimson Emperor). Screen flash + expanding shockwave ring + radiální glow +
// rozletující se úlomky (ledové střepy / spory / krvavé kapky podle RelicBurstKind). Jeden
// sdílený painter/engine, jen barvy+tvar střepů se liší podle configu - stejný přístup jako
// _TreasureChestPainter výš (jeden CustomPainter, parametrizovaný přes 0..1 progress).
class _RelicBurstConfig {
  final Color primary; final Color flash; final bool sharpShards; // true=ostré ledové hroty, false=kulaté kapky/spory
  const _RelicBurstConfig({required this.primary, required this.flash, this.sharpShards = true});
}

const Map<RelicBurstKind, _RelicBurstConfig> kRelicBurstConfig = {
  RelicBurstKind.iceShatter: _RelicBurstConfig(primary: Color(0xFF70D7FF), flash: Colors.white, sharpShards: true),
  RelicBurstKind.plagueApocalypse: _RelicBurstConfig(primary: Color(0xFF8BC34A), flash: Color(0xFF4A148C), sharpShards: false),
  RelicBurstKind.bloodEmperor: _RelicBurstConfig(primary: Color(0xFFC62828), flash: Color(0xFF3A0000), sharpShards: false),
  RelicBurstKind.executionShot: _RelicBurstConfig(primary: Color(0xFFFFD700), flash: Color(0xFFFF6E40), sharpShards: true),
  RelicBurstKind.alphaHowl: _RelicBurstConfig(primary: Color(0xFFFF8F00), flash: Color(0xFF3E2412), sharpShards: false),
  RelicBurstKind.ghostLeap: _RelicBurstConfig(primary: Color(0xFF26A69A), flash: Color(0xFF0D0D0D), sharpShards: true),
  RelicBurstKind.rampage: _RelicBurstConfig(primary: Color(0xFFE64A19), flash: Color(0xFFFFD700), sharpShards: true),
  RelicBurstKind.guardianBreak: _RelicBurstConfig(primary: Color(0xFF78909C), flash: Color(0xFFFFD700), sharpShards: true),
  RelicBurstKind.warlordCommand: _RelicBurstConfig(primary: Color(0xFFFFA000), flash: Colors.white, sharpShards: false),
  RelicBurstKind.eternalDawn: _RelicBurstConfig(primary: Color(0xFFFFD54F), flash: Colors.white, sharpShards: false),
  RelicBurstKind.lastJudgement: _RelicBurstConfig(primary: Color(0xFFFFB300), flash: Color(0xFFFFF176), sharpShards: true),
  RelicBurstKind.apostleZeal: _RelicBurstConfig(primary: Color(0xFFFF8F00), flash: Color(0xFFFFECB3), sharpShards: false),
  RelicBurstKind.flashover: _RelicBurstConfig(primary: Color(0xFFFF3D00), flash: Color(0xFFFFD180), sharpShards: false),
  RelicBurstKind.absoluteZero: _RelicBurstConfig(primary: Color(0xFF80D8FF), flash: Colors.white, sharpShards: true),
  RelicBurstKind.paradoxEcho: _RelicBurstConfig(primary: Color(0xFFAB47BC), flash: Color(0xFFE1BEE7), sharpShards: false),
  RelicBurstKind.thousandStrikes: _RelicBurstConfig(primary: Color(0xFFFFB74D), flash: Colors.white, sharpShards: true),
  RelicBurstKind.mountainStrike: _RelicBurstConfig(primary: Color(0xFF8D6E63), flash: Color(0xFFD7CCC8), sharpShards: true),
  RelicBurstKind.perfectBalance: _RelicBurstConfig(primary: Color(0xFF80CBC4), flash: Colors.white, sharpShards: false),
  RelicBurstKind.starfall: _RelicBurstConfig(primary: Color(0xFF66BB6A), flash: Color(0xFFC8E6C9), sharpShards: true),
  RelicBurstKind.forestBurst: _RelicBurstConfig(primary: Color(0xFF388E3C), flash: Color(0xFFA5D6A7), sharpShards: true),
  RelicBurstKind.natureHeart: _RelicBurstConfig(primary: Color(0xFF81C784), flash: Colors.white, sharpShards: false),
  RelicBurstKind.boneLord: _RelicBurstConfig(primary: Color(0xFF6A1B9A), flash: Color(0xFFD1C4E9), sharpShards: true),
  RelicBurstKind.plagueFall: _RelicBurstConfig(primary: Color(0xFF7B1FA2), flash: Color(0xFFCE93D8), sharpShards: false),
  RelicBurstKind.immortalRitual: _RelicBurstConfig(primary: Color(0xFF4A148C), flash: Color(0xFFC62828), sharpShards: false),
  RelicBurstKind.nemesisJudgement: _RelicBurstConfig(primary: Color(0xFFE0E0E0), flash: Color(0xFF37474F), sharpShards: true),
  RelicBurstKind.bladeDance: _RelicBurstConfig(primary: Color(0xFF90CAF9), flash: Colors.white, sharpShards: true),
  RelicBurstKind.lightningStorm: _RelicBurstConfig(primary: Color(0xFFFFEE58), flash: Colors.white, sharpShards: true),
  RelicBurstKind.faithBurst: _RelicBurstConfig(primary: Color(0xFFFFD700), flash: Colors.white, sharpShards: true),
  RelicBurstKind.finalVerdict: _RelicBurstConfig(primary: Color(0xFFFFC107), flash: Color(0xFFFFF9C4), sharpShards: true),
  RelicBurstKind.divineGrace: _RelicBurstConfig(primary: Color(0xFFFFD700), flash: Colors.white, sharpShards: false),
  RelicBurstKind.doomVerdict: _RelicBurstConfig(primary: Color(0xFF7B2FBE), flash: Color(0xFFE1BEE7), sharpShards: true),
  RelicBurstKind.abyssRitual: _RelicBurstConfig(primary: Color(0xFF7B2FBE), flash: Color(0xFF4A148C), sharpShards: false),
  RelicBurstKind.abyssFall: _RelicBurstConfig(primary: Color(0xFF6A1B9A), flash: Color(0xFFCE93D8), sharpShards: false),
};

class _BurstShard {
  final double angle, maxDist, size, spin, spinDir;
  final bool secondary;
  _BurstShard(this.angle, this.maxDist, this.size, this.spin, this.spinDir, this.secondary);
}

class _RelicBurstPainter extends CustomPainter {
  final double t; // 0..1 průběh
  final _RelicBurstConfig cfg;
  final List<_BurstShard> shards;
  _RelicBurstPainter({required this.t, required this.cfg, required this.shards});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));

    // 1) Screen flash - rychle odezní hned na startu (první ~30 % animace).
    final flashT = (t / 0.30).clamp(0.0, 1.0);
    if (flashT < 1.0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = cfg.flash.withOpacity((1 - flashT) * 0.5));
    }

    // 2) Expandující shockwave ring, tenčí a slabší s postupem.
    final ringRadius = size.shortestSide * (0.10 + 0.42 * eased);
    canvas.drawCircle(
      center, ringRadius,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5 * (1 - eased * 0.6)..color = cfg.primary.withOpacity((1 - eased) * 0.85),
    );

    // 3) Centrální radiální záře, zprvu jasná a velká, pak se smrskne a vytratí.
    final glowRadius = size.shortestSide * (0.30 * (1 - eased * 0.7));
    final glowOpacity = (1 - eased).clamp(0.0, 1.0);
    if (glowOpacity > 0) {
      canvas.drawCircle(
        center, glowRadius,
        Paint()..shader = RadialGradient(colors: [cfg.primary.withOpacity(glowOpacity * 0.9), cfg.primary.withOpacity(0)]).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
      );
    }

    // 4) Úlomky letící ven ze středu, rotující, mizející k okraji své dráhy.
    for (final s in shards) {
      final dist = s.maxDist * eased;
      final pos = center + Offset(cos(s.angle), sin(s.angle)) * dist;
      final opacity = (1 - eased).clamp(0.0, 1.0);
      if (opacity <= 0.02) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(s.spin * eased * pi * 2 * s.spinDir);
      final color = (s.secondary ? cfg.flash : cfg.primary).withOpacity(opacity);
      if (cfg.sharpShards) {
        final path = Path()
          ..moveTo(0, -s.size)
          ..lineTo(s.size * 0.42, s.size * 0.55)
          ..lineTo(-s.size * 0.42, s.size * 0.55)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
      } else {
        canvas.drawCircle(Offset.zero, s.size * 0.5, Paint()..color = color);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RelicBurstPainter old) => old.t != t;
}

// Jednorázový burst overlay - spustí se, odehraje ~650 ms a zavolá onDone (rodič ho pak
// odstraní ze stromu). Připni jako Positioned.fill přes celou kartu, kde chceš efekt vidět.
class RelicBurstOverlay extends StatefulWidget {
  final RelicBurstKind kind;
  final VoidCallback onDone;
  const RelicBurstOverlay({super.key, required this.kind, required this.onDone});

  @override
  State<RelicBurstOverlay> createState() => _RelicBurstOverlayState();
}

class _RelicBurstOverlayState extends State<RelicBurstOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_BurstShard> _shards;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    final rnd = Random();
    final n = 16;
    _shards = List.generate(n, (i) {
      final angle = (i / n) * 2 * pi + (rnd.nextDouble() - 0.5) * 0.35;
      return _BurstShard(angle, 46 + rnd.nextDouble() * 46, 7 + rnd.nextDouble() * 9, 0.4 + rnd.nextDouble() * 1.3, rnd.nextBool() ? 1 : -1, rnd.nextBool());
    });
    _c.forward().whenComplete(() { if (mounted) widget.onDone(); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cfg = kRelicBurstConfig[widget.kind]!;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(size: Size.infinite, painter: _RelicBurstPainter(t: _c.value, cfg: cfg, shards: _shards)),
      ),
    );
  }
}

// ===== SPELL FX - unikátní epický vizuál PER SPELL (viz SpellFxKind v data_models.dart).
// Na rozdíl od RelicBurstOverlay výš (jeden sdílený tvar, jen přebarvený) tady má každý spell
// vlastní CustomPainter kresbu, aby cast skutečně "vypadal" jinak (Prokletý úder ≠ Exploze
// prokletí). Malé/běžné spelly jsou rychlé a decentní, epické (finishery/ultimáty) jsou
// pomalejší a razantnější - viz `epic` flag v _SpellFxSpec.
// ===== SPELL FX - unikátní vizuál PER SPELL (viz SpellFxKind v data_models.dart).
// dkCursedStrike/dkCurseExplosion/healerBlessing/healerJudgment mají vlastní ručně malovaný
// CustomPainter (_paintCursedStrike a spol. níž) - byly první a zůstávají nejdetailnější.
// Všechny ostatní (jedna specializace = jeden SpellFxKind, viz komentář u enumu) jedou přes
// generický "archetyp" systém (_SpellFxArchetype + _paintArchetype) - společný tvarový motiv
// (blade_slash/arcane_rune/nature_bloom/...) přebarvený a doladěný podle dvojice primary/
// secondary barev dané specializace, ať má KAŽDÁ z ~30 specializací ve hře vlastní odlišitelný
// vizuál, aniž by pro každou musel existovat samostatný ručně psaný painter (nereálné pro ~30+
// spellů). Malé/běžné spelly (tier 15 "Advanced") jsou rychlé a decentní (epic:false), epické
// (tier 40 "Ultimate" a tier 75 "God") jsou pomalejší a razantnější (epic:true).
enum _SpellFxArchetype { bladeSlash, groundSlam, stormLightning, shadowVoid, holyRadiance, arcaneRune, chiBurst, natureBloom, boneDecay }

class _SpellFxSpec {
  final bool epic;
  final _SpellFxArchetype? archetype; // null = má vlastní bespoke _paint* metodu (viz 4 legacy kindy výš)
  final Color primary;
  final Color secondary;
  const _SpellFxSpec({this.epic = false, this.archetype, this.primary = Colors.white, this.secondary = Colors.white70});
}

const Map<SpellFxKind, _SpellFxSpec> kSpellFxSpec = {
  SpellFxKind.dkCursedStrike: _SpellFxSpec(epic: false),
  SpellFxKind.dkCurseExplosion: _SpellFxSpec(epic: true),
  SpellFxKind.healerBlessing: _SpellFxSpec(epic: false),
  SpellFxKind.healerJudgment: _SpellFxSpec(epic: true),
  // Warrior - čepel/údery, sytá červená.
  SpellFxKind.berserk: _SpellFxSpec(archetype: _SpellFxArchetype.bladeSlash, epic: false, primary: Color(0xFFE53935), secondary: Color(0xFFFF8A65)),
  SpellFxKind.warlord: _SpellFxSpec(archetype: _SpellFxArchetype.groundSlam, epic: true, primary: Color(0xFFC62828), secondary: Color(0xFFFFD54F)),
  SpellFxKind.valhallaWarrior: _SpellFxSpec(archetype: _SpellFxArchetype.stormLightning, epic: true, primary: Color(0xFFFFD700), secondary: Color(0xFFFFF9C4)),
  // Hunter - stín/temnota, fialová.
  SpellFxKind.assassin: _SpellFxSpec(archetype: _SpellFxArchetype.shadowVoid, epic: false, primary: Color(0xFF6A1B9A), secondary: Color(0xFF1A1A2E)),
  SpellFxKind.shadowMaster: _SpellFxSpec(archetype: _SpellFxArchetype.shadowVoid, epic: true, primary: Color(0xFF4A148C), secondary: Color(0xFF26C6DA)),
  SpellFxKind.voidStalker: _SpellFxSpec(archetype: _SpellFxArchetype.shadowVoid, epic: true, primary: Color(0xFF1A1A2E), secondary: Color(0xFF00E5FF)),
  // Healer (LightBearer, tier 75) - chladnější "božské" bílo-zlaté světlo, ať se liší od
  // healerBlessing/healerJudgment (tier 15/40, teplejší žlutá).
  SpellFxKind.lightBearer: _SpellFxSpec(archetype: _SpellFxArchetype.holyRadiance, epic: true, primary: Color(0xFFE1F5FE), secondary: Color(0xFFFFD700)),
  // Death Knight (DeathReaper, tier 75) - temná žnec/rozklad barva odlišná od Prokletí (fialovo-
  // zelené) - hluboká petrolejová + krvavě rudý akcent.
  SpellFxKind.deathReaper: _SpellFxSpec(archetype: _SpellFxArchetype.boneDecay, epic: true, primary: Color(0xFF004D40), secondary: Color(0xFFB71C1C)),
  // Mage - oheň pro Elementalistu, arkánová geometrie pro Arcanist/Archmage.
  SpellFxKind.elementalist: _SpellFxSpec(archetype: _SpellFxArchetype.arcaneRune, epic: false, primary: Color(0xFFFF6F00), secondary: Color(0xFFFFEB3B)),
  SpellFxKind.arcanist: _SpellFxSpec(archetype: _SpellFxArchetype.arcaneRune, epic: true, primary: Color(0xFF3949AB), secondary: Color(0xFFB39DDB)),
  SpellFxKind.archmage: _SpellFxSpec(archetype: _SpellFxArchetype.arcaneRune, epic: true, primary: Color(0xFF1A237E), secondary: Color(0xFFFFD700)),
  // Duelist - čepele (stříbrná/cyan), Stormblade přechází do blesku.
  SpellFxKind.bladeDancer: _SpellFxSpec(archetype: _SpellFxArchetype.bladeSlash, epic: false, primary: Color(0xFFB0BEC5), secondary: Color(0xFF26C6DA)),
  SpellFxKind.bladeMaster: _SpellFxSpec(archetype: _SpellFxArchetype.bladeSlash, epic: true, primary: Color(0xFF90A4AE), secondary: Color(0xFFE53935)),
  SpellFxKind.stormblade: _SpellFxSpec(archetype: _SpellFxArchetype.stormLightning, epic: true, primary: Color(0xFF00BCD4), secondary: Color(0xFFFFFFFF)),
  // Monk - "chi" koncentrické vlny, teal/zlatá.
  SpellFxKind.disciple: _SpellFxSpec(archetype: _SpellFxArchetype.chiBurst, epic: false, primary: Color(0xFF26A69A), secondary: Color(0xFFFFFFFF)),
  SpellFxKind.grandmaster: _SpellFxSpec(archetype: _SpellFxArchetype.chiBurst, epic: true, primary: Color(0xFF00897B), secondary: Color(0xFFFFD54F)),
  SpellFxKind.enlightened: _SpellFxSpec(archetype: _SpellFxArchetype.chiBurst, epic: true, primary: Color(0xFFFFD700), secondary: Color(0xFFFFFFFF)),
  // Druid - přírodní/měsíční organické květy.
  SpellFxKind.astralDruid: _SpellFxSpec(archetype: _SpellFxArchetype.natureBloom, epic: false, primary: Color(0xFF66BB6A), secondary: Color(0xFFA5D6A7)),
  SpellFxKind.moonfury: _SpellFxSpec(archetype: _SpellFxArchetype.natureBloom, epic: true, primary: Color(0xFF7E57C2), secondary: Color(0xFFC5CAE9)),
  SpellFxKind.elderTreant: _SpellFxSpec(archetype: _SpellFxArchetype.natureBloom, epic: true, primary: Color(0xFF4E342E), secondary: Color(0xFF66BB6A)),
  // Paladin - svaté světlo (teplejší/zlatější než Healer).
  SpellFxKind.faithGuardian: _SpellFxSpec(archetype: _SpellFxArchetype.holyRadiance, epic: false, primary: Color(0xFFFFD700), secondary: Color(0xFFFFFFFF)),
  SpellFxKind.retributor: _SpellFxSpec(archetype: _SpellFxArchetype.holyRadiance, epic: true, primary: Color(0xFFFFB300), secondary: Color(0xFFE53935)),
  SpellFxKind.crusader: _SpellFxSpec(archetype: _SpellFxArchetype.holyRadiance, epic: true, primary: Color(0xFFFFFFFF), secondary: Color(0xFFFFD700)),
  // Demon Hunter - fel zelená čepel, Abyss Walker přechází do stínu.
  SpellFxKind.felBlade: _SpellFxSpec(archetype: _SpellFxArchetype.bladeSlash, epic: false, primary: Color(0xFF66BB6A), secondary: Color(0xFF1B1B1B)),
  SpellFxKind.demonSlayer: _SpellFxSpec(archetype: _SpellFxArchetype.bladeSlash, epic: true, primary: Color(0xFF2E7D32), secondary: Color(0xFFE53935)),
  SpellFxKind.abyssWalker: _SpellFxSpec(archetype: _SpellFxArchetype.shadowVoid, epic: true, primary: Color(0xFF1B5E20), secondary: Color(0xFF000000)),
  // Necromancer - rozklad/kosti, sytě jedovatá zelená → fialová → teal napříč tiery.
  SpellFxKind.boneLord: _SpellFxSpec(archetype: _SpellFxArchetype.boneDecay, epic: false, primary: Color(0xFF558B2F), secondary: Color(0xFF212121)),
  SpellFxKind.deathSovereign: _SpellFxSpec(archetype: _SpellFxArchetype.boneDecay, epic: true, primary: Color(0xFF6A1B9A), secondary: Color(0xFF212121)),
  SpellFxKind.graveWarden: _SpellFxSpec(archetype: _SpellFxArchetype.boneDecay, epic: true, primary: Color(0xFF00695C), secondary: Color(0xFF212121)),
  // ===== Nepřátelská schopnost bosse (Doupě/Věž/World Boss - viz enemyAbilityEffects) =====
  // Vždy epic:true - boss ability se odehraje jen jednou za souboj (2. kolo), je to vždy
  // "moment", ne běžný útok, takže si zaslouží tu delší/razantnější verzi.
  // Přímé/posílené útoky (trueDamage/ignoreArmor/ignoreBlockDodge/guaranteedCrit/doubleAttack) -
  // temně karmínová čepel.
  SpellFxKind.lairBossStrike: _SpellFxSpec(archetype: _SpellFxArchetype.bladeSlash, epic: true, primary: Color(0xFF8B0000), secondary: Color(0xFF212121)),
  // Kletby/dispely na hráče (statDebuff/stackingDebuff/cancelBuff/cancelShield) - temně fialový vsát.
  SpellFxKind.lairBossCurse: _SpellFxSpec(archetype: _SpellFxArchetype.shadowVoid, epic: true, primary: Color(0xFF4A148C), secondary: Color(0xFF1A1A2E)),
  // Jed/oheň (dot) - jedovatě zelený rozklad.
  SpellFxKind.lairBossPlague: _SpellFxSpec(archetype: _SpellFxArchetype.boneDecay, epic: true, primary: Color(0xFF33691E), secondary: Color(0xFF1B1B1B)),
  // Ovládací efekty na hráče (stun/blockSpell) - ocelově modrá aranová vazba.
  SpellFxKind.lairBossBind: _SpellFxSpec(archetype: _SpellFxArchetype.arcaneRune, epic: true, primary: Color(0xFF37474F), secondary: Color(0xFF90A4AE)),
  // Boss se posiluje/léčí sám sebe (bossBuff/bossArmorBuff/bossShield/bossHeal/bossLifesteal) -
  // temně karmínová záře (variace na svaté záření, ale zlověstná).
  SpellFxKind.lairBossEmpower: _SpellFxSpec(archetype: _SpellFxArchetype.holyRadiance, epic: true, primary: Color(0xFFB71C1C), secondary: Color(0xFF212121)),
  // Vysátí zdroje/zlata z hráče (resourceDrain/goldDrain) - šedo-černý vsát.
  SpellFxKind.lairBossDrain: _SpellFxSpec(archetype: _SpellFxArchetype.shadowVoid, epic: true, primary: Color(0xFF424242), secondary: Color(0xFF000000)),
};

class _SpellFxPainter extends CustomPainter {
  final double t; // 0..1 průběh
  final SpellFxKind kind;
  final List<_BurstShard> shards; // sdíleno s RelicBurstPainter (jen úlomky letící ven)
  final List<Offset> wisps; // náhodné směrové "semínko" pro kouř/duše, -1..1 v obou osách
  _SpellFxPainter({required this.t, required this.kind, required this.shards, required this.wisps});

  @override
  void paint(Canvas canvas, Size size) {
    final spec = kSpellFxSpec[kind];
    final epic = spec?.epic ?? false;
    _paintVignette(canvas, size, epic);
    switch (kind) {
      case SpellFxKind.dkCursedStrike:
        _paintCursedStrike(canvas, size);
        break;
      case SpellFxKind.dkCurseExplosion:
        _paintCurseExplosion(canvas, size);
        break;
      case SpellFxKind.healerBlessing:
        _paintHealerBlessing(canvas, size);
        break;
      case SpellFxKind.healerJudgment:
        _paintHealerJudgment(canvas, size);
        break;
      default:
        // Zbylých ~30 specializací jede přes generický archetyp systém (viz _SpellFxSpec výš) -
        // společný tvarový motiv přebarvený podle primary/secondary dané specializace.
        if (spec?.archetype != null) {
          _paintArchetype(canvas, size, spec!.archetype!, spec.primary, spec.secondary, epic);
        }
    }
    _paintFilmGrain(canvas, size, epic);
  }

  // ===== "ART" VRSTVA - společná pro všechny spelly, dělá to víc "malovaný"/kinematografický
  // dojem místo čistě geometrických tvarů =====
  // Měkká tmavá viněta po okrajích karty, zesiluje se do poloviny animace a pak zase mizí -
  // dává vizuálu hloubku a soustředí pohled na střed dění, podobně jako filmový "bullet time".
  void _paintVignette(Canvas canvas, Size size, bool epic) {
    final bell = (sin(t.clamp(0.0, 1.0) * pi)).clamp(0.0, 1.0); // 0→1→0 přes celou animaci
    final strength = bell * (epic ? 0.4 : 0.24);
    if (strength <= 0.01) return;
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final maxR = size.longestSide * 0.75;
    canvas.drawRect(rect, Paint()..shader = RadialGradient(
      colors: [Colors.black.withOpacity(0), Colors.black.withOpacity(strength)],
      stops: const [0.45, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: maxR)));
  }

  // Jemné zrnění (film grain) přes celou plochu - pár desítek nahodilých tmavých/světlých
  // tečiček s velmi nízkou opacitou, seed se posouvá s `t`, takže to jemně "žije"/blikotá jako
  // stará filmová surovina, místo aby vizuál působil jako čistá vektorová grafika.
  void _paintFilmGrain(Canvas canvas, Size size, bool epic) {
    final bell = (sin(t.clamp(0.0, 1.0) * pi)).clamp(0.0, 1.0);
    if (bell <= 0.02) return;
    final grainSeed = (t * 37).floor(); // mění se ~1x za pár framů, ne úplně každý frame
    final rnd = Random(grainSeed * 911 + kind.index * 13);
    final count = epic ? 46 : 28;
    for (int i = 0; i < count; i++) {
      final pos = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final light = rnd.nextBool();
      final r = 0.5 + rnd.nextDouble() * 1.1;
      canvas.drawCircle(pos, r, Paint()..color = (light ? Colors.white : Colors.black).withOpacity(bell * 0.05));
    }
  }

  // Malý pomocník: Paint s měkkou září (MaskFilter blur) - používá se napříč všemi spelly
  // níž, aby efekty působily hutněji/"epičtěji" a ne jen jako ploché tvary.
  Paint _glow(Color c, double opacity, double sigma, {PaintingStyle style = PaintingStyle.fill, double strokeWidth = 2}) {
    final p = Paint()
      ..color = c.withOpacity(opacity.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma)
      ..style = style;
    if (style == PaintingStyle.stroke) p.strokeWidth = strokeWidth;
    return p;
  }

  // Prokletý úder: temně fialovo-zelený DVOJITÝ runový hexagram (vnitřní + vnější, rotují proti
  // sobě) se "vypálí" doprostřed cíle (rychlý punch scale-in s krátkou rázovou vlnou), doprovázený
  // 5 zářícími klikatými trhlinami-blesky s vedlejšími výhonky ven ze středu a stoupajícími
  // zářivými kouřovými smítky prokletí. Vše doznívá do ~500 ms - má to být rychlý, časný impact.
  void _paintCursedStrike(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final stampT = (t / 0.35).clamp(0.0, 1.0);
    final scale = Curves.easeOutBack.transform(stampT);
    final fade = (1 - ((t - 0.45) / 0.55).clamp(0.0, 1.0));
    if (fade <= 0.02) return;
    final r = size.shortestSide * 0.15;

    // Krátká rázová vlna při impactu (rychle expanduje a zmizí).
    final shockT = (t / 0.28).clamp(0.0, 1.0);
    if (shockT < 1.0) {
      final shockR = r * (0.6 + shockT * 1.5);
      canvas.drawCircle(center, shockR, _glow(const Color(0xFF7B2FBE), (1 - shockT) * 0.45, 6, style: PaintingStyle.stroke, strokeWidth: 3 * (1 - shockT) + 1));
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale <= 0 ? 0.01 : scale);
    // Vnější hexagram - větší, tlumenější, rotuje opačným směrem = pocit hloubky.
    canvas.save();
    canvas.rotate(-eased * pi * 0.35);
    canvas.drawCircle(Offset.zero, r * 1.35, _glow(const Color(0xFF7B2FBE), fade * 0.35, 4, style: PaintingStyle.stroke, strokeWidth: 1.6));
    Path outerTriangle(double rot) {
      final path = Path();
      for (int i = 0; i < 3; i++) {
        final a = rot + i * (2 * pi / 3) - pi / 2;
        final p = Offset(cos(a) * r * 1.35, sin(a) * r * 1.35);
        if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy);
      }
      path.close();
      return path;
    }
    canvas.drawPath(outerTriangle(0.5), _glow(const Color(0xFF8BC34A), fade * 0.3, 3, style: PaintingStyle.stroke, strokeWidth: 1.4));
    canvas.restore();
    // Vnitřní hexagram - hlavní, ostřejší, se září.
    canvas.rotate(eased * pi * 0.5);
    canvas.drawCircle(Offset.zero, r, _glow(const Color(0xFF7B2FBE), fade * 0.4, 5));
    canvas.drawCircle(Offset.zero, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = const Color(0xFF7B2FBE).withOpacity(fade * 0.9));
    Path triangle(double rot) {
      final path = Path();
      for (int i = 0; i < 3; i++) {
        final a = rot + i * (2 * pi / 3) - pi / 2;
        final p = Offset(cos(a) * r, sin(a) * r);
        if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy);
      }
      path.close();
      return path;
    }
    canvas.drawPath(triangle(0), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..color = const Color(0xFF8BC34A).withOpacity(fade * 0.85));
    canvas.drawPath(triangle(pi), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..color = const Color(0xFF7B2FBE).withOpacity(fade * 0.85));
    // Malé jádro uprostřed hexagramu.
    canvas.drawCircle(Offset.zero, r * 0.12, Paint()..color = const Color(0xFFD1C4E9).withOpacity(fade * 0.9));
    canvas.restore();

    // 5 klikatých trhlin (dřív 3) se zářícími vedlejšími výhonky, vystřelujících ze středu ven.
    for (int i = 0; i < 5; i++) {
      final rnd = Random(i * 97 + 3);
      final a = (i / 5) * 2 * pi + 0.35;
      final len = size.shortestSide * 0.26 * eased;
      final jag = Offset((rnd.nextDouble() - 0.5) * 12, (rnd.nextDouble() - 0.5) * 12);
      final mid = center + Offset(cos(a), sin(a)) * len * 0.55 + jag;
      final end = center + Offset(cos(a), sin(a)) * len;
      final path = Path()..moveTo(center.dx, center.dy)..lineTo(mid.dx, mid.dy)..lineTo(end.dx, end.dy);
      canvas.drawPath(path, _glow(const Color(0xFF8BC34A), fade * 0.5, 3, style: PaintingStyle.stroke, strokeWidth: 3));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = const Color(0xFF8BC34A).withOpacity(fade * 0.8));
      // Malý vedlejší výhonek uprostřed hlavní trhliny.
      final branchA = a + (rnd.nextDouble() - 0.5) * 1.2;
      final branchEnd = mid + Offset(cos(branchA), sin(branchA)) * len * 0.32;
      canvas.drawLine(mid, branchEnd, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0xFF8BC34A).withOpacity(fade * 0.5));
    }
    // Stoupající zářivá smítka temného kouře (s glow).
    for (final w in wisps) {
      final dy = -size.shortestSide * 0.28 * eased * (0.6 + w.dx.abs());
      final dx = w.dx * 22 * eased;
      final pos = center + Offset(dx, dy);
      canvas.drawCircle(pos, 5 * (1 - eased * 0.3), _glow(const Color(0xFF7B2FBE), fade * 0.25, 4));
      canvas.drawCircle(pos, 3.2 * (1 - eased * 0.4), Paint()..color = const Color(0xFF9C7FCE).withOpacity(fade * 0.45));
    }
  }

  // Exploze prokletí: dušičky (soul wisps) se první třetinu animace stahují dovnitř ze všech
  // stran se zářivými kometovými stopami (implode), splynou do jednoho bodu s pulzujícím temným
  // jádrem, a pak to celé vybuchne ven jako tmavě fialová nova - screen flash, DVOJITÁ rázová
  // vlna, radiální blesky, sytý radiální glow a kostěné/zubaté úlomky s dohasínajícím "duchem"
  // za sebou. Delší (~900 ms) a razantnější než Prokletý úder - epický finisher spell.
  void _paintCurseExplosion(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    if (t < 0.32) {
      final p = (t / 0.32).clamp(0.0, 1.0);
      final eased = Curves.easeIn.transform(p);
      final startDist = size.shortestSide * 0.42;
      for (int i = 0; i < wisps.length; i++) {
        final angle = i * (2 * pi / wisps.length);
        final start = center + Offset(cos(angle), sin(angle)) * startDist;
        final pos = Offset.lerp(start, center, eased)!;
        // Kometová stopa - krátký úsek za dušičkou směrem, odkud přiletěla.
        final trailP = (p - 0.06).clamp(0.0, 1.0);
        final trailPos = Offset.lerp(start, center, Curves.easeIn.transform(trailP))!;
        canvas.drawLine(trailPos, pos, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = const Color(0xFF9C27B0).withOpacity(0.15 + eased * 0.3));
        canvas.drawCircle(pos, 4.2, _glow(const Color(0xFF9C27B0), 0.2 + eased * 0.4, 4));
        canvas.drawCircle(pos, 4.2, Paint()..color = const Color(0xFF9C27B0).withOpacity(0.25 + eased * 0.6));
      }
      canvas.drawCircle(center, 4 + eased * 8, _glow(const Color(0xFF4A148C), 0.6 * eased, 6));
      canvas.drawCircle(center, 4 + eased * 8, Paint()..color = const Color(0xFF4A148C).withOpacity(0.5 * eased));
    } else {
      final p = ((t - 0.32) / 0.68).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(p);
      final flashT = (p / 0.22).clamp(0.0, 1.0);
      if (flashT < 1.0) {
        canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF4A148C).withOpacity((1 - flashT) * 0.55));
      }
      // Dvojitá rázová vlna - ostrá vnitřní + měkká vnější se zpožděním pro dojem síly.
      final ringRadius = size.shortestSide * (0.08 + 0.5 * eased);
      canvas.drawCircle(center, ringRadius, _glow(const Color(0xFF9C27B0), (1 - eased) * 0.5, 5, style: PaintingStyle.stroke, strokeWidth: 6));
      canvas.drawCircle(center, ringRadius, Paint()..style = PaintingStyle.stroke..strokeWidth = 4 * (1 - eased * 0.6)..color = const Color(0xFF9C27B0).withOpacity((1 - eased) * 0.9));
      final ring2P = ((p - 0.12).clamp(0.0, 1.0));
      if (ring2P > 0) {
        final ring2Radius = size.shortestSide * (0.05 + 0.4 * Curves.easeOutCubic.transform(ring2P));
        canvas.drawCircle(center, ring2Radius, Paint()..style = PaintingStyle.stroke..strokeWidth = 2 * (1 - ring2P)..color = const Color(0xFFCE93D8).withOpacity((1 - ring2P) * 0.7));
      }
      final glowRadius = size.shortestSide * (0.32 * (1 - eased * 0.7));
      final glowOpacity = (1 - eased).clamp(0.0, 1.0);
      if (glowOpacity > 0) {
        canvas.drawCircle(center, glowRadius, Paint()..shader = RadialGradient(colors: [const Color(0xFF7B2FBE).withOpacity(glowOpacity * 0.9), const Color(0xFF7B2FBE).withOpacity(0)]).createShader(Rect.fromCircle(center: center, radius: glowRadius)));
      }
      // Radiální blesky tryskající ven z jádra exploze (8, se září).
      if (eased < 0.7) {
        final boltFade = (1 - eased / 0.7).clamp(0.0, 1.0);
        for (int i = 0; i < 8; i++) {
          final rnd = Random(i * 53 + 7);
          final a = (i / 8) * 2 * pi;
          final len = size.shortestSide * 0.3 * eased;
          final jag = Offset((rnd.nextDouble() - 0.5) * 14, (rnd.nextDouble() - 0.5) * 14);
          final mid = center + Offset(cos(a), sin(a)) * len * 0.5 + jag;
          final end = center + Offset(cos(a), sin(a)) * len;
          final path = Path()..moveTo(center.dx, center.dy)..lineTo(mid.dx, mid.dy)..lineTo(end.dx, end.dy);
          canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = const Color(0xFFCE93D8).withOpacity(boltFade * 0.6));
        }
      }
      for (final s in shards) {
        final dist = s.maxDist * eased;
        final pos = center + Offset(cos(s.angle), sin(s.angle)) * dist;
        final opacity = (1 - eased).clamp(0.0, 1.0);
        if (opacity <= 0.02) continue;
        // Slabý "duch" úlomku o kousek pozadu - dojem rychlosti/motion-blur.
        final ghostDist = s.maxDist * (eased * 0.86).clamp(0.0, 1.0);
        final ghostPos = center + Offset(cos(s.angle), sin(s.angle)) * ghostDist;
        canvas.drawCircle(ghostPos, s.size * 0.4, Paint()..color = const Color(0xFF9C27B0).withOpacity(opacity * 0.2));
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(s.spin * eased * pi * 2 * s.spinDir);
        // Zubatý "kostěný" úlomek místo obyčejného trojúhelníku/kapky.
        final path = Path()
          ..moveTo(0, -s.size)
          ..lineTo(s.size * 0.35, -s.size * 0.1)
          ..lineTo(s.size * 0.55, s.size * 0.55)
          ..lineTo(0, s.size * 0.3)
          ..lineTo(-s.size * 0.55, s.size * 0.55)
          ..lineTo(-s.size * 0.35, -s.size * 0.1)
          ..close();
        canvas.drawPath(path, _glow((s.secondary ? const Color(0xFF212121) : const Color(0xFF9C27B0)), opacity * 0.5, 3));
        canvas.drawPath(path, Paint()..color = (s.secondary ? const Color(0xFF212121) : const Color(0xFF9C27B0)).withOpacity(opacity));
        canvas.restore();
      }
    }
  }

  // Boží požehnání: teplý zlatý světelný SLOUP stoupá skrz cíl, pulzující dvojité rotující halo
  // z krátkých obloučků (vnitřní + vnější, opačný směr), jemná křížová záře v momentu vrcholu a
  // jiskřičky/hvězdičky stoupající vzhůru jako "vyléčení" - vše prosvětlené a měkké, žádné ostré
  // hrany (na rozdíl od DK efektů výš), rychlé a jemné (~500 ms).
  void _paintHealerBlessing(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final fade = (1 - ((t - 0.4) / 0.6).clamp(0.0, 1.0));
    if (fade <= 0.02) return;

    // Jemný svislý světelný sloup skrz cíl.
    final pillarW = size.width * 0.1 * (0.5 + eased * 0.5);
    final pillarRect = Rect.fromLTRB(center.dx - pillarW / 2, center.dy - size.height * 0.4, center.dx + pillarW / 2, center.dy + size.height * 0.4);
    canvas.drawRect(pillarRect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
      const Color(0xFFFFD700).withOpacity(0),
      const Color(0xFFFFF176).withOpacity(fade * 0.35),
      const Color(0xFFFFD700).withOpacity(0),
    ], stops: const [0.0, 0.5, 1.0]).createShader(pillarRect));

    final glowRadius = size.shortestSide * (0.10 + 0.22 * eased);
    canvas.drawCircle(center, glowRadius, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFF176).withOpacity(fade * 0.55), const Color(0xFFFFD700).withOpacity(0)]).createShader(Rect.fromCircle(center: center, radius: glowRadius)));

    // Křížová záře v momentu vrcholu jasu.
    final crossPeak = (1 - (t - 0.18).abs() / 0.18).clamp(0.0, 1.0);
    if (crossPeak > 0) {
      final crossLen = size.shortestSide * 0.22;
      canvas.drawLine(center - Offset(crossLen, 0), center + Offset(crossLen, 0), _glow(const Color(0xFFFFF9C4), crossPeak * 0.6, 4, style: PaintingStyle.stroke, strokeWidth: 2.5));
      canvas.drawLine(center - Offset(0, crossLen), center + Offset(0, crossLen), _glow(const Color(0xFFFFF9C4), crossPeak * 0.6, 4, style: PaintingStyle.stroke, strokeWidth: 2.5));
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Vnější halo - jemnější, opačný směr rotace (pocit hloubky).
    canvas.save();
    canvas.rotate(-eased * pi * 0.5);
    final haloOuterR = size.shortestSide * 0.19;
    for (int i = 0; i < 6; i++) {
      final a0 = i * (pi / 3) + pi / 6;
      final rect = Rect.fromCircle(center: Offset.zero, radius: haloOuterR);
      canvas.drawArc(rect, a0, pi / 7, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = const Color(0xFFFFF176).withOpacity(fade * 0.5));
    }
    canvas.restore();
    // Vnitřní halo - hlavní.
    canvas.rotate(eased * pi * 0.8);
    final haloR = size.shortestSide * 0.14;
    for (int i = 0; i < 6; i++) {
      final a0 = i * (pi / 3);
      final rect = Rect.fromCircle(center: Offset.zero, radius: haloR);
      canvas.drawArc(rect, a0, pi / 5, false, _glow(const Color(0xFFFFD700), fade * 0.5, 3, style: PaintingStyle.stroke, strokeWidth: 3));
      canvas.drawArc(rect, a0, pi / 5, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = const Color(0xFFFFD700).withOpacity(fade * 0.85));
    }
    canvas.restore();
    // Jiskřičky/hvězdičky stoupající vzhůru (glow + čtyřcípá hvězdička u části z nich).
    for (int i = 0; i < wisps.length; i++) {
      final w = wisps[i];
      final dy = -size.shortestSide * 0.32 * eased * (0.5 + w.dy.abs());
      final dx = w.dx * 18 * eased;
      final pos = center + Offset(dx, dy);
      final twinkle = (sin(t * pi * 6 + w.dx * 10) + 1) / 2;
      canvas.drawCircle(pos, 4 + twinkle * 2, _glow(const Color(0xFFFFF9C4), fade * 0.3, 3));
      if (i.isEven) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(t * pi * 2);
        final sSize = 2.4 + twinkle * 1.6;
        final star = Path()
          ..moveTo(0, -sSize)..lineTo(sSize * 0.3, -sSize * 0.3)..lineTo(sSize, 0)..lineTo(sSize * 0.3, sSize * 0.3)
          ..lineTo(0, sSize)..lineTo(-sSize * 0.3, sSize * 0.3)..lineTo(-sSize, 0)..lineTo(-sSize * 0.3, -sSize * 0.3)..close();
        canvas.drawPath(star, Paint()..color = const Color(0xFFFFF9C4).withOpacity(fade * (0.5 + twinkle * 0.4)));
        canvas.restore();
      } else {
        canvas.drawCircle(pos, 2.4 + twinkle * 1.6, Paint()..color = const Color(0xFFFFF9C4).withOpacity(fade * (0.5 + twinkle * 0.4)));
      }
    }
  }

  // Boží soud: sloup světla (nyní doprovázený dvěma tenčími bočními paprsky a rostoucím
  // světelným kruhem na zemi) dopadne shora na cíl (fáze 1, 0-32 %), pak vybuchne do zlatého
  // "sunburst" nova - DVOJITÝ prstenec, hustší sluneční paprsky proměnlivé délky, křížová záře
  // uprostřed a létající zlatá pírka s jemným zavlněním místo ostrých úlomků (fáze 2). Delší a
  // razantnější (~900 ms) - ultimátní finisher spell léčitele.
  void _paintHealerJudgment(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    if (t < 0.32) {
      final p = (t / 0.32).clamp(0.0, 1.0);
      final eased = Curves.easeIn.transform(p);
      final beamWidth = size.width * 0.16 * (0.6 + eased * 0.4);
      final beamRect = Rect.fromLTRB(center.dx - beamWidth / 2, 0, center.dx + beamWidth / 2, center.dy + size.height * 0.05);
      canvas.drawRect(beamRect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFF9C4).withOpacity(0), const Color(0xFFFFD700).withOpacity(eased * 0.75)]).createShader(beamRect));
      // Dva tenčí boční paprsky lemující hlavní sloup - dojem šířky/mohutnosti.
      for (final side in [-1.0, 1.0]) {
        final sideOffset = beamWidth * 0.9 * side;
        final sideW = beamWidth * 0.3;
        final sideRect = Rect.fromLTRB(center.dx + sideOffset - sideW / 2, 0, center.dx + sideOffset + sideW / 2, center.dy);
        canvas.drawRect(sideRect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFF9C4).withOpacity(0), const Color(0xFFFFD700).withOpacity(eased * 0.35)]).createShader(sideRect));
      }
      // Rostoucí světelný kruh na "zemi" pod cílem - anticipace dopadu.
      final groundR = size.shortestSide * 0.14 * eased;
      canvas.drawOval(Rect.fromCenter(center: center, width: groundR * 2, height: groundR * 0.5), Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFFFD700).withOpacity(eased * 0.5));
      canvas.drawCircle(center, 6 + eased * 10, _glow(const Color(0xFFFFF176), 0.6 * eased, 6));
      canvas.drawCircle(center, 6 + eased * 10, Paint()..color = const Color(0xFFFFF176).withOpacity(0.6 * eased));
    } else {
      final p = ((t - 0.32) / 0.68).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(p);
      final flashT = (p / 0.22).clamp(0.0, 1.0);
      if (flashT < 1.0) {
        canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFF9C4).withOpacity((1 - flashT) * 0.6));
      }
      // Hustší sunburst - 14 paprsků proměnlivé délky (liché delší) pro organičtější tvar.
      final rayCount = 14;
      for (int i = 0; i < rayCount; i++) {
        final a = (i / rayCount) * 2 * pi;
        final lenMul = i.isOdd ? 0.34 : 0.24;
        final len = size.shortestSide * (0.10 + lenMul * eased);
        final end = center + Offset(cos(a), sin(a)) * len;
        final opacity = (1 - eased).clamp(0.0, 1.0);
        canvas.drawLine(center, end, _glow(const Color(0xFFFFD700), opacity * 0.4, 3, style: PaintingStyle.stroke, strokeWidth: 4));
        canvas.drawLine(center, end, Paint()..strokeWidth = 2.5 * (1 - eased * 0.5)..color = const Color(0xFFFFD700).withOpacity(opacity * 0.8));
      }
      // Dvojitý prstenec - vnitřní ostrý + vnější měkký doznívající se zpožděním.
      final ringRadius = size.shortestSide * (0.08 + 0.42 * eased);
      canvas.drawCircle(center, ringRadius, _glow(const Color(0xFFFFF176), (1 - eased) * 0.4, 5, style: PaintingStyle.stroke, strokeWidth: 6));
      canvas.drawCircle(center, ringRadius, Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5 * (1 - eased * 0.6)..color = const Color(0xFFFFF176).withOpacity((1 - eased) * 0.85));
      final ring2P = (p - 0.1).clamp(0.0, 1.0);
      if (ring2P > 0) {
        final ring2Radius = size.shortestSide * (0.05 + 0.3 * Curves.easeOutCubic.transform(ring2P));
        canvas.drawCircle(center, ring2Radius, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8 * (1 - ring2P)..color = const Color(0xFFFFECB3).withOpacity((1 - ring2P) * 0.65));
      }
      // Křížová záře v jádru exploze.
      final crossFade = (1 - eased / 0.5).clamp(0.0, 1.0);
      if (crossFade > 0) {
        final crossLen = size.shortestSide * 0.16 * (0.5 + eased);
        canvas.drawLine(center - Offset(crossLen, 0), center + Offset(crossLen, 0), _glow(const Color(0xFFFFFDE7), crossFade * 0.55, 4, style: PaintingStyle.stroke, strokeWidth: 3));
        canvas.drawLine(center - Offset(0, crossLen), center + Offset(0, crossLen), _glow(const Color(0xFFFFFDE7), crossFade * 0.55, 4, style: PaintingStyle.stroke, strokeWidth: 3));
      }
      for (final s in shards) {
        final dist = s.maxDist * eased;
        final wobble = sin(eased * pi * 4 + s.angle * 3) * 0.15;
        final pos = center + Offset(cos(s.angle + wobble), sin(s.angle + wobble)) * dist;
        final opacity = (1 - eased).clamp(0.0, 1.0);
        if (opacity <= 0.02) continue;
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(s.spin * eased * pi * 2 * s.spinDir + wobble);
        final path = Path()
          ..moveTo(0, -s.size)
          ..quadraticBezierTo(s.size * 0.6, -s.size * 0.2, 0, s.size * 0.7)
          ..quadraticBezierTo(-s.size * 0.6, -s.size * 0.2, 0, -s.size);
        canvas.drawPath(path, _glow((s.secondary ? const Color(0xFFFFF9C4) : const Color(0xFFFFD700)), opacity * 0.4, 2));
        canvas.drawPath(path, Paint()..color = (s.secondary ? const Color(0xFFFFF9C4) : const Color(0xFFFFD700)).withOpacity(opacity));
        canvas.restore();
      }
    }
  }

  // ===== GENERICKÝ "ARCHETYP" SYSTÉM - viz _SpellFxArchetype/_SpellFxSpec výš =====
  // Jeden tvarový motiv sdílený víc specializacemi, vždy přebarvený podle primary/secondary té
  // konkrétní specializace (a měřítko/intenzita podle `epic`) - takhle má KAŽDÁ specializace ve
  // hře viditelně odlišný cast, aniž by musela mít úplně samostatnou ručně malovanou funkci.
  void _paintArchetype(Canvas canvas, Size size, _SpellFxArchetype archetype, Color primary, Color secondary, bool epic) {
    switch (archetype) {
      case _SpellFxArchetype.bladeSlash:
        _paintBladeSlash(canvas, size, primary, secondary, epic);
        break;
      case _SpellFxArchetype.groundSlam:
        _paintGroundSlam(canvas, size, primary, secondary, epic);
        break;
      case _SpellFxArchetype.stormLightning:
        _paintStormLightning(canvas, size, primary, secondary, epic);
        break;
      case _SpellFxArchetype.shadowVoid:
        _paintShadowVoid(canvas, size, primary, secondary, epic);
        break;
      case _SpellFxArchetype.holyRadiance:
        _paintHolyRadianceGeneric(canvas, size, primary, secondary, epic);
        break;
      case _SpellFxArchetype.arcaneRune:
        _paintArcaneRune(canvas, size, primary, secondary, epic);
        break;
      case _SpellFxArchetype.chiBurst:
        _paintChiBurst(canvas, size, primary, secondary, epic);
        break;
      case _SpellFxArchetype.natureBloom:
        _paintNatureBloom(canvas, size, primary, secondary, epic);
        break;
      case _SpellFxArchetype.boneDecay:
        _paintBoneDecayGeneric(canvas, size, primary, secondary, epic);
        break;
    }
  }

  // Čepel/sek: rychlý diagonální "slash" streak přes cíl (jasná stopa co se rozšíří a zmizí),
  // + krátká druhá afterimage čepel se zpožděním, + pár jisker vylétávajících podél řezu.
  void _paintBladeSlash(Canvas canvas, Size size, Color primary, Color secondary, bool epic) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final slashT = (t / (epic ? 0.5 : 0.4)).clamp(0.0, 1.0);
    final eased = Curves.easeOutExpo.transform(slashT);
    final fade = (1 - ((t - 0.4) / 0.6).clamp(0.0, 1.0));
    if (fade <= 0.02) return;
    final len = size.longestSide * (epic ? 0.95 : 0.8);
    void drawSlash(double angleOffset, double delay, double opacityMul, double widthMul) {
      final dt = ((t - delay) / (epic ? 0.5 : 0.4)).clamp(0.0, 1.0);
      if (dt <= 0) return;
      final e = Curves.easeOutExpo.transform(dt);
      final a = pi * 0.22 + angleOffset;
      final dir = Offset(cos(a), sin(a));
      final half = len / 2 * e;
      final p1 = center - dir * half;
      final p2 = center + dir * half;
      final perp = Offset(-dir.dy, dir.dx);
      final bow = perp * (size.shortestSide * 0.06 * (1 - e));
      final path = Path()..moveTo(p1.dx, p1.dy)..quadraticBezierTo(center.dx + bow.dx, center.dy + bow.dy, p2.dx, p2.dy);
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = (epic ? 10 : 7) * widthMul * (1 - e * 0.3)..color = primary.withOpacity(fade * 0.9 * opacityMul)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = (epic ? 3.5 : 2.5) * widthMul..color = secondary.withOpacity(fade * opacityMul));
    }
    drawSlash(0, 0.0, 1.0, 1.0);
    if (epic) drawSlash(0.5, 0.08, 0.5, 0.7); // druhý protisměrný sek u epických verzí
    // Jiskry podél řezu.
    for (final w in wisps) {
      final along = (w.dx + 1) / 2; // 0..1 pozice podél čepele
      final a = pi * 0.22;
      final pos = center + Offset(cos(a), sin(a)) * (len / 2) * (along * 2 - 1) * eased;
      canvas.drawCircle(pos, 2.4 + eased * 1.2, _glow(secondary, fade * 0.5, 3));
      canvas.drawCircle(pos, 1.4, Paint()..color = secondary.withOpacity(fade * 0.8));
    }
  }

  // Dopad do země: rázová vlna od spodního okraje + prasklá zem (cikcak čáry po vodorovné ose)
  // + úlomky/suť vyletující nahoru - "velitelský" úder namísto sekání čepelí.
  void _paintGroundSlam(Canvas canvas, Size size, Color primary, Color secondary, bool epic) {
    final ground = Offset(size.width / 2, size.height * 0.82);
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final fade = (1 - ((t - 0.5) / 0.5).clamp(0.0, 1.0));
    if (fade <= 0.02) return;
    final impactT = (t / 0.22).clamp(0.0, 1.0);
    if (impactT < 1.0) {
      canvas.drawCircle(ground, size.shortestSide * 0.3 * (1 - impactT), Paint()..color = secondary.withOpacity((1 - impactT) * 0.5));
    }
    final ringR = size.shortestSide * (0.06 + 0.55 * eased);
    canvas.drawOval(Rect.fromCenter(center: ground, width: ringR * 2, height: ringR * 0.5), _glow(primary, fade * 0.5, 5, style: PaintingStyle.stroke, strokeWidth: 5));
    canvas.drawOval(Rect.fromCenter(center: ground, width: ringR * 2, height: ringR * 0.5), Paint()..style = PaintingStyle.stroke..strokeWidth = 3 * (1 - eased * 0.5)..color = primary.withOpacity(fade * 0.85));
    for (int i = 0; i < (epic ? 6 : 4); i++) {
      final rnd = Random(i * 71 + 5);
      final dir = rnd.nextBool() ? 1 : -1;
      final len = size.width * (0.15 + rnd.nextDouble() * 0.2) * eased * dir;
      final endX = ground.dx + len;
      final jagY = ground.dy + (rnd.nextDouble() - 0.5) * 8;
      canvas.drawLine(ground, Offset(endX, jagY), Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = secondary.withOpacity(fade * 0.6));
    }
    for (final s in shards) {
      final dist = s.maxDist * 0.6 * eased;
      final pos = ground + Offset(cos(s.angle) * dist, sin(s.angle).abs() * -dist * 0.8);
      final opacity = (1 - eased).clamp(0.0, 1.0) * fade;
      if (opacity <= 0.02) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(s.spin * eased * pi * 2 * s.spinDir);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s.size * 0.7, height: s.size * 0.7), Paint()..color = (s.secondary ? secondary : primary).withOpacity(opacity));
      canvas.restore();
    }
  }

  // Blesk: cikcak paprsek shora dolů (2-3 zablikání), tenké radiální výboje ze středu, krátký
  // bílý flash - rychlé, ostré, elektrizující.
  void _paintStormLightning(Canvas canvas, Size size, Color primary, Color secondary, bool epic) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final fade = (1 - ((t - 0.45) / 0.55).clamp(0.0, 1.0));
    if (fade <= 0.02) return;
    final flicker = (sin(t * pi * (epic ? 14 : 10)).abs());
    final boltPath = Path()..moveTo(center.dx, 0);
    final rnd = Random(kind.index);
    double y = 0;
    double x = center.dx;
    while (y < center.dy) {
      y += size.height * 0.12;
      x += (rnd.nextDouble() - 0.5) * size.width * 0.12;
      boltPath.lineTo(x, y);
    }
    canvas.drawPath(boltPath, Paint()..style = PaintingStyle.stroke..strokeWidth = 6..color = primary.withOpacity(fade * flicker * 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(boltPath, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = secondary.withOpacity(fade * flicker * 0.9));
    for (int i = 0; i < (epic ? 8 : 6); i++) {
      final a = (i / (epic ? 8 : 6)) * 2 * pi;
      final len = size.shortestSide * 0.22 * Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
      canvas.drawLine(center, center + Offset(cos(a), sin(a)) * len, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = secondary.withOpacity(fade * flicker * 0.7));
    }
    canvas.drawCircle(center, size.shortestSide * (0.05 + 0.05 * flicker), _glow(secondary, fade * flicker * 0.6, 6));
  }

  // Stínové vsátí: dušičky implodují do temného portálu (kruh s prstencem), krátký záblesk a
  // rozplynutí v kouři - variace na Explozi prokletí, ale kompaktnější a bez kostěných úlomků.
  void _paintShadowVoid(Canvas canvas, Size size, Color primary, Color secondary, bool epic) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final implodeEnd = epic ? 0.38 : 0.3;
    if (t < implodeEnd) {
      final p = (t / implodeEnd).clamp(0.0, 1.0);
      final eased = Curves.easeIn.transform(p);
      final startDist = size.shortestSide * 0.4;
      for (int i = 0; i < wisps.length; i++) {
        final angle = i * (2 * pi / wisps.length);
        final start = center + Offset(cos(angle), sin(angle)) * startDist;
        final pos = Offset.lerp(start, center, eased)!;
        canvas.drawCircle(pos, 3.6, Paint()..color = primary.withOpacity(0.2 + eased * 0.55));
      }
      canvas.drawCircle(center, 3 + eased * 9, _glow(primary, 0.5 * eased, 5));
    } else {
      final p = ((t - implodeEnd) / (1 - implodeEnd)).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(p);
      final fade = (1 - eased).clamp(0.0, 1.0);
      final flashT = (p / 0.2).clamp(0.0, 1.0);
      if (flashT < 1.0) canvas.drawRect(Offset.zero & size, Paint()..color = primary.withOpacity((1 - flashT) * 0.4));
      final ringR = size.shortestSide * (0.06 + (epic ? 0.4 : 0.3) * eased);
      canvas.drawCircle(center, ringR, _glow(secondary, fade * 0.5, 5, style: PaintingStyle.stroke, strokeWidth: 5));
      canvas.drawCircle(center, ringR, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = secondary.withOpacity(fade * 0.85));
      canvas.drawCircle(center, ringR * 0.5, Paint()..color = primary.withOpacity(fade * 0.4));
      if (epic) {
        for (final s in shards) {
          final dist = s.maxDist * 0.7 * eased;
          final pos = center + Offset(cos(s.angle), sin(s.angle)) * dist;
          final opacity = fade;
          if (opacity <= 0.02) continue;
          canvas.drawCircle(pos, s.size * 0.35, Paint()..color = primary.withOpacity(opacity * 0.6));
        }
      }
    }
  }

  // Svaté záření: variace na _paintHealerBlessing/_paintHealerJudgment, ale s vlastními barvami
  // (Paladin/LightBearer) - měkký glow, rotující halo, stoupající jiskřičky; epické verze navíc
  // dostanou krátký paprsek shora.
  void _paintHolyRadianceGeneric(Canvas canvas, Size size, Color primary, Color secondary, bool epic) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final fade = (1 - ((t - 0.4) / 0.6).clamp(0.0, 1.0));
    if (fade <= 0.02) return;
    if (epic) {
      final beamW = size.width * 0.1 * eased;
      final beamRect = Rect.fromLTRB(center.dx - beamW / 2, 0, center.dx + beamW / 2, center.dy);
      canvas.drawRect(beamRect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primary.withOpacity(0), secondary.withOpacity(fade * 0.5)]).createShader(beamRect));
    }
    final glowRadius = size.shortestSide * (0.10 + 0.22 * eased);
    canvas.drawCircle(center, glowRadius, Paint()..shader = RadialGradient(colors: [primary.withOpacity(fade * 0.55), secondary.withOpacity(0)]).createShader(Rect.fromCircle(center: center, radius: glowRadius)));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(eased * pi * 0.8);
    final haloR = size.shortestSide * 0.14;
    for (int i = 0; i < 6; i++) {
      final a0 = i * (pi / 3);
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: haloR), a0, pi / 5, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = secondary.withOpacity(fade * 0.85));
    }
    canvas.restore();
    for (final w in wisps) {
      final dy = -size.shortestSide * 0.3 * eased * (0.5 + w.dy.abs());
      final pos = center + Offset(w.dx * 18 * eased, dy);
      final twinkle = (sin(t * pi * 6 + w.dx * 10) + 1) / 2;
      canvas.drawCircle(pos, 2.4 + twinkle * 1.6, Paint()..color = secondary.withOpacity(fade * (0.5 + twinkle * 0.4)));
    }
  }

  // Arkánová runa: geometrický rotující kruh s vepsaným čtvercem + 4 orbitující kosočtverce -
  // "chladnější"/přesnější než DK hexagram, hodí se pro Mage linii (Elementalist/Arcanist/
  // Archmage).
  void _paintArcaneRune(Canvas canvas, Size size, Color primary, Color secondary, bool epic) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final stampT = (t / 0.35).clamp(0.0, 1.0);
    final scale = Curves.easeOutBack.transform(stampT);
    final fade = (1 - ((t - 0.45) / 0.55).clamp(0.0, 1.0));
    if (fade <= 0.02) return;
    final r = size.shortestSide * (epic ? 0.18 : 0.14);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale <= 0 ? 0.01 : scale);
    canvas.drawCircle(Offset.zero, r, _glow(primary, fade * 0.4, 5));
    canvas.drawCircle(Offset.zero, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = primary.withOpacity(fade * 0.9));
    canvas.rotate(t * pi * 0.6);
    final sq = Rect.fromCircle(center: Offset.zero, radius: r * 0.85);
    canvas.drawRect(sq, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = secondary.withOpacity(fade * 0.8));
    canvas.restore();
    // Orbitující kosočtverce.
    for (int i = 0; i < (epic ? 6 : 4); i++) {
      final a = (i / (epic ? 6 : 4)) * 2 * pi + t * pi * (epic ? 2 : 1.4);
      final orbitR = r * 1.5;
      final pos = center + Offset(cos(a), sin(a)) * orbitR;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a);
      final d = 5.0;
      final diamond = Path()..moveTo(0, -d)..lineTo(d * 0.7, 0)..lineTo(0, d)..lineTo(-d * 0.7, 0)..close();
      canvas.drawPath(diamond, Paint()..color = secondary.withOpacity(fade * 0.85));
      canvas.restore();
    }
  }

  // "Chi" úder: koncentrické rozšiřující se kruhy (jako tlaková vlna z úderu dlaní), pár
  // radiálních krátkých obloučků a jemné stoupající tečky - čisté, rychlé, meditativní.
  void _paintChiBurst(Canvas canvas, Size size, Color primary, Color secondary, bool epic) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final fade = (1 - ((t - 0.5) / 0.5).clamp(0.0, 1.0));
    if (fade <= 0.02) return;
    void ring(double delay, double maxR, double opacityMul) {
      final p = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (p <= 0) return;
      final eased = Curves.easeOutCubic.transform(p);
      final r = size.shortestSide * maxR * eased;
      canvas.drawCircle(center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 3 * (1 - eased * 0.7)..color = primary.withOpacity((1 - eased) * 0.8 * opacityMul));
    }
    ring(0.0, 0.4, 1.0);
    ring(0.12, 0.32, 0.7);
    if (epic) ring(0.24, 0.5, 0.5);
    canvas.drawCircle(center, size.shortestSide * 0.06 * (1 - (t / 0.3).clamp(0.0, 1.0)), _glow(secondary, fade * 0.6, 4));
    for (final w in wisps) {
      final a = w.dx * pi;
      final dist = size.shortestSide * 0.22 * t;
      final pos = center + Offset(cos(a), sin(a)) * dist;
      canvas.drawCircle(pos, 2, Paint()..color = secondary.withOpacity(fade * 0.6));
    }
  }

  // Přírodní květ: měkké překrývající se "lístky" (blob tvary) expandující ven ze středu + pár
  // stoupajících pylových částic - organický, žádné ostré hrany.
  void _paintNatureBloom(Canvas canvas, Size size, Color primary, Color secondary, bool epic) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final eased = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
    final fade = (1 - ((t - 0.45) / 0.55).clamp(0.0, 1.0));
    if (fade <= 0.02) return;
    final petals = epic ? 7 : 5;
    final r = size.shortestSide * (epic ? 0.16 : 0.12) * eased.clamp(0.0, 1.2);
    for (int i = 0; i < petals; i++) {
      final a = (i / petals) * 2 * pi;
      final pos = center + Offset(cos(a), sin(a)) * r * 0.6;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a);
      final petal = Path()..moveTo(0, 0)..quadraticBezierTo(r * 0.5, -r * 0.35, r * 0.9, 0)..quadraticBezierTo(r * 0.5, r * 0.35, 0, 0);
      canvas.drawPath(petal, Paint()..color = primary.withOpacity(fade * 0.55));
      canvas.restore();
    }
    canvas.drawCircle(center, r * 0.3, Paint()..color = secondary.withOpacity(fade * 0.8));
    for (final w in wisps) {
      final dy = -size.shortestSide * 0.26 * eased.clamp(0.0, 1.0) * (0.5 + w.dy.abs());
      final pos = center + Offset(w.dx * 20 * eased.clamp(0.0, 1.0), dy);
      canvas.drawCircle(pos, 2.2, Paint()..color = secondary.withOpacity(fade * 0.5));
    }
  }

  // Rozklad/kosti: sytě jedovatý implode+burst s "kostěnými" zubatými úlomky (sdílený tvar
  // s _paintCurseExplosion) - kompaktnější verze pro Necromancer/DeathReaper linii.
  void _paintBoneDecayGeneric(Canvas canvas, Size size, Color primary, Color secondary, bool epic) {
    final center = Offset(size.width / 2, size.height * 0.28); // top-biased - karta je teď vyšší (portrét+bary), efekt musí mířit na portrét, ne na střed celé karty
    final stampT = (t / 0.3).clamp(0.0, 1.0);
    final scale = Curves.easeOutBack.transform(stampT);
    final fade = (1 - ((t - 0.45) / 0.55).clamp(0.0, 1.0));
    if (fade <= 0.02) return;
    canvas.drawCircle(center, size.shortestSide * 0.14 * scale, _glow(primary, fade * 0.4, 5));
    for (int i = 0; i < 3; i++) {
      final rnd = Random(i * 61 + 9);
      final a = (i / 3) * 2 * pi + 0.4;
      final len = size.shortestSide * 0.22 * scale;
      final jag = Offset((rnd.nextDouble() - 0.5) * 10, (rnd.nextDouble() - 0.5) * 10);
      final mid = center + Offset(cos(a), sin(a)) * len * 0.5 + jag;
      final end = center + Offset(cos(a), sin(a)) * len;
      canvas.drawPath(Path()..moveTo(center.dx, center.dy)..lineTo(mid.dx, mid.dy)..lineTo(end.dx, end.dy), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = secondary.withOpacity(fade * 0.6));
    }
    for (final s in shards) {
      final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
      final dist = s.maxDist * 0.7 * eased;
      final pos = center + Offset(cos(s.angle), sin(s.angle)) * dist;
      final opacity = (1 - eased).clamp(0.0, 1.0);
      if (opacity <= 0.02) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(s.spin * eased * pi * 2 * s.spinDir);
      final path = Path()..moveTo(0, -s.size * 0.8)..lineTo(s.size * 0.3, -s.size * 0.05)..lineTo(s.size * 0.45, s.size * 0.45)..lineTo(0, s.size * 0.25)..lineTo(-s.size * 0.45, s.size * 0.45)..lineTo(-s.size * 0.3, -s.size * 0.05)..close();
      canvas.drawPath(path, Paint()..color = primary.withOpacity(opacity * 0.85));
      canvas.restore();
    }
    for (final w in wisps) {
      final dy = -size.shortestSide * 0.22 * t * (0.6 + w.dx.abs());
      final pos = center + Offset(w.dx * 16 * t, dy);
      canvas.drawCircle(pos, 3, Paint()..color = primary.withOpacity(fade * 0.3));
    }
  }

  @override
  bool shouldRepaint(covariant _SpellFxPainter old) => old.t != t;
}

// Jednorázový spell-fx overlay - spustí se, odehraje a zavolá onDone. Trvání i počet
// shardů/wispů se odvíjí od toho, jestli je spell "epic" (viz kSpellFxSpec) - běžné spelly
// jsou krátké a skromné, ultimáty/finishery delší a nabité.
class SpellFxOverlay extends StatefulWidget {
  final SpellFxKind kind;
  final VoidCallback onDone;
  const SpellFxOverlay({super.key, required this.kind, required this.onDone});

  @override
  State<SpellFxOverlay> createState() => _SpellFxOverlayState();
}

class _SpellFxOverlayState extends State<SpellFxOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_BurstShard> _shards;
  late final List<Offset> _wisps;

  @override
  void initState() {
    super.initState();
    final epic = kSpellFxSpec[widget.kind]?.epic ?? false;
    // Delší trvání než dřív (bylo 900/500 ms) - půl vteřiny je pro lidské oko málo na to, aby se
    // stihl vizuál "vstřebat". MUSÍ odpovídat _spellFxSlowMoMs v game_state.dart, který podle
    // těchto časů pozastavuje auto-boj (viz isSpellSlowMo) - jinak by se rozjel dřív/později,
    // než animace doopravdy doběhne.
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: epic ? 2200 : 1300));
    final rnd = Random();
    final shardCount = epic ? 14 : 0;
    _shards = List.generate(shardCount, (i) {
      final angle = (i / shardCount) * 2 * pi + (rnd.nextDouble() - 0.5) * 0.3;
      return _BurstShard(angle, 40 + rnd.nextDouble() * 44, 7 + rnd.nextDouble() * 8, 0.4 + rnd.nextDouble() * 1.2, rnd.nextBool() ? 1 : -1, rnd.nextBool());
    });
    _wisps = List.generate(epic ? 8 : 5, (_) => Offset(rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1));
    _c.forward().whenComplete(() { if (mounted) widget.onDone(); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(size: Size.infinite, painter: _SpellFxPainter(t: _c.value, kind: widget.kind, shards: _shards, wisps: _wisps)),
      ),
    );
  }
}

// Tmavá "bullet-time" clona přes CELOU kartu (hero i nepřítel současně), dokud běží
// GameState.isSpellSlowMo okno (viz _pushFx/_spellFxSlowMoMs v game_state.dart) - vizuálně
// prodává pocit, že se čas na chvíli zpomalil/zastavil, ne že hoří jen jedna karta. Vlastní
// lehký Timer (40ms), který se sám spustí při první notifikaci od GameState a sám se ukončí,
// jakmile isSpellSlowMo doběhne - nezávisí na tom, jestli GameState mezitím ještě notifikuje.
class _SlowMoDim extends StatefulWidget {
  final GameState state;
  const _SlowMoDim({required this.state});
  @override
  State<_SlowMoDim> createState() => _SlowMoDimState();
}

class _SlowMoDimState extends State<_SlowMoDim> {
  Timer? _ticker;
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    _maybeStartTicking();
  }

  @override
  void didUpdateWidget(covariant _SlowMoDim old) {
    super.didUpdateWidget(old);
    _maybeStartTicking();
  }

  void _maybeStartTicking() {
    if (_ticker != null) return;
    if (!widget.state.isSpellSlowMo) return;
    _ticker = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) { timer.cancel(); return; }
      final active = widget.state.isSpellSlowMo;
      setState(() { _opacity = active ? 0.24 : 0.0; });
      if (!active) { timer.cancel(); _ticker = null; }
    });
  }

  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_opacity <= 0.001) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedContainer(duration: const Duration(milliseconds: 160), color: Colors.black.withOpacity(_opacity)),
    );
  }
}

// Vrstva vylétávajících textů + velkých burst efektů pro jednu stranu (hero/enemy) - připni
// jako Positioned.fill uvnitř Stacku nad danou kartou. StatefulWidget (ne Stateless jako dřív),
// protože si musí pamatovat, které burstKind/spellFxKind eventy už "odpálil", ať se při
// rebuildu nepřehrají znovu.
class CombatFxOverlay extends StatefulWidget {
  final GameState state; final FxSide side;
  const CombatFxOverlay({super.key, required this.state, required this.side});
  @override
  State<CombatFxOverlay> createState() => _CombatFxOverlayState();
}

class _CombatFxOverlayState extends State<CombatFxOverlay> {
  final Set<int> _shownBurstIds = {};
  final Set<int> _shownSpellFxIds = {};

  @override
  Widget build(BuildContext context) {
    final events = widget.state.combatFx.where((e) => e.side == widget.side).toList();
    final newBurstEvents = events.where((e) => e.burstKind != null && !_shownBurstIds.contains(e.id)).toList();
    for (final e in newBurstEvents) { _shownBurstIds.add(e.id); }
    final newSpellFxEvents = events.where((e) => e.spellFxKind != null && !_shownSpellFxIds.contains(e.id)).toList();
    for (final e in newSpellFxEvents) { _shownSpellFxIds.add(e.id); }
    // Na rozdíl od dřívějška NEvracíme SizedBox.shrink jen podle lokálních eventů - i strana bez
    // vlastního spell efektu (např. nepřítel, když kouzlí hrdina) musí umět zobrazit _SlowMoDim,
    // ať se ztmaví obě karty současně.
    if (events.isEmpty && newBurstEvents.isEmpty && newSpellFxEvents.isEmpty && !widget.state.isSpellSlowMo) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(children: [
          _SlowMoDim(state: widget.state),
          ...events.map((e) => _CombatFxText(event: e, onDone: () => widget.state.removeFx(e.id))),
          ...newSpellFxEvents.map((e) => SpellFxOverlay(key: ValueKey('spellfx_${e.id}'), kind: e.spellFxKind!, onDone: () { if (mounted) setState(() {}); })),
          ...newBurstEvents.map((e) => RelicBurstOverlay(key: ValueKey('burst_${e.id}'), kind: e.burstKind!, onDone: () { if (mounted) setState(() {}); })),
        ]),
      ),
    );
  }
}



// Card flash + mikro-shake při zásahu - poslouchá GameState přímo (ne přes Provider rebuild),
// aby dostal i eventy, co zmizí z fronty dřív, než by widget strom stihl rebuild zachytit.
class ImpactFlashCard extends StatefulWidget {
  final GameState state; final FxSide side; final Widget child;
  const ImpactFlashCard({super.key, required this.state, required this.side, required this.child});
  @override
  State<ImpactFlashCard> createState() => _ImpactFlashCardState();
}

class _ImpactFlashCardState extends State<ImpactFlashCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lastSeenFxId = -1;
  bool _isCritFlash = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final events = widget.state.combatFx;
    if (events.isEmpty) return;
    final maxId = events.map((e) => e.id).reduce(max);
    if (maxId <= _lastSeenFxId) { _lastSeenFxId = maxId; return; }
    final newHits = events.where((e) => e.id > _lastSeenFxId && e.side == widget.side &&
        (e.kind == FxKind.normalDamage || e.kind == FxKind.critDamage || e.kind == FxKind.blocked || e.kind == FxKind.explosionDamage));
    _lastSeenFxId = maxId;
    if (newHits.isNotEmpty) {
      _isCritFlash = newHits.any((e) => e.kind == FxKind.critDamage || e.kind == FxKind.explosionDamage);
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0 = právě zasaženo, 1 = doznělo
        final fade = (1 - t).clamp(0.0, 1.0);
        final shake = fade > 0 ? sin(t * pi * 6) * 3 * fade : 0.0;
        // Hrdina bliká červeně (utrpěl damage), nepřítel oranžově - ladí to s barvou jeho HP baru
        // (Colors.deepOrange) i celkovým fantasy tématem. Colors.white tu dřív působilo jako
        // cizorodý "flashbang" na tmavém pozadí.
        final flashColor = widget.side == FxSide.hero ? Colors.redAccent : Colors.orangeAccent;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Stack(children: [
            child!,
            if (fade > 0.01)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: flashColor.withOpacity(fade * (_isCritFlash ? 0.45 : 0.22))),
                  ),
                ),
              ),
          ]),
        );
      },
      child: widget.child,
    );
  }
}

// "🔥 xN" badge - kolik zásahů za sebou bez uhnutí hráč dal aktuálnímu nepříteli (Tower).
// ===== SDÍLENÁ ANIMOVANÁ TRUHLA — použitá jak pro Poklad-skřeta v Trhlině, tak pro Arénu
// (truhla za dokončenou ligu). Zavřená truhla jemně "dýchá" (idle glow pulse), po ťuknutí se
// víko 3D pootevře (perspektivní rotace), z mezery vyšlehne světlo a vyletí zlaté jiskry.
// Po doběhnutí animace zavolá onOpen (ten teprve vygeneruje/zobrazí konkrétní loot).
class _ChestSpark {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double delay;
  _ChestSpark(int seed)
      : angle = ((seed * 47) % 360) * pi / 180,
        speed = 55 + ((seed * 13) % 45).toDouble(),
        size = 2.5 + (seed % 4),
        color = seed % 3 == 0 ? const Color(0xFFFFD700) : (seed % 3 == 1 ? Colors.white : const Color(0xFFFFA500)),
        delay = (seed % 6) * 0.045;
}

class _TreasureChestPainter extends CustomPainter {
  final double openT; // 0..1 - průběh otevírání víka
  final double idleT; // 0..1 - jemné dýchání glow, dokud je truhla zavřená
  final Color accent;
  _TreasureChestPainter({required this.openT, required this.idleT, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height * 0.80;
    final bodyW = size.width * 0.60;
    final bodyH = size.height * 0.32;
    final bodyRect = Rect.fromCenter(center: Offset(cx, baseY - bodyH / 2), width: bodyW, height: bodyH);

    final glowOpacity = openT > 0 ? (openT < 0.75 ? openT / 0.75 : (1 - (openT - 0.75) / 0.25 * 0.5)) : (0.22 + 0.18 * idleT);
    canvas.drawCircle(
      Offset(cx, baseY - bodyH * 0.65),
      size.width * 0.55,
      Paint()..shader = RadialGradient(colors: [accent.withOpacity(glowOpacity.clamp(0, 1) * 0.55), accent.withOpacity(0)]).createShader(Rect.fromCircle(center: Offset(cx, baseY - bodyH * 0.65), radius: size.width * 0.55)),
    );

    // Tělo truhly
    final bodyRRect = RRect.fromRectAndCorners(bodyRect, bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10), topLeft: const Radius.circular(4), topRight: const Radius.circular(4));
    canvas.drawRRect(bodyRRect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B4226), Color(0xFF3E2412)]).createShader(bodyRect));
    canvas.drawRRect(bodyRRect, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = accent.withOpacity(.9));

    // Dřevěné pruhy (planky)
    final plankPaint = Paint()..color = Colors.black.withOpacity(.22)..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final x = bodyRect.left + bodyRect.width * i / 5;
      canvas.drawLine(Offset(x, bodyRect.top + 3), Offset(x, bodyRect.bottom - 3), plankPaint);
    }

    // Zlaté kovové pásy + nýty
    final bandPaint = Paint()..color = accent;
    final band1 = Rect.fromLTWH(bodyRect.left - 2, bodyRect.top + bodyRect.height * 0.30, bodyRect.width + 4, 5);
    final band2 = Rect.fromLTWH(bodyRect.left - 2, bodyRect.top + bodyRect.height * 0.72, bodyRect.width + 4, 5);
    canvas.drawRect(band1, bandPaint);
    canvas.drawRect(band2, bandPaint);
    final rivetPaint = Paint()..color = accent.withOpacity(.85);
    for (final band in [band1, band2]) {
      for (double fx = 0.08; fx <= 0.92; fx += 0.28) {
        canvas.drawCircle(Offset(band.left + band.width * fx, band.center.dy), 1.7, rivetPaint);
      }
    }

    // Zámek
    final lockCenter = Offset(cx, bodyRect.top - 1);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lockCenter, width: 20, height: 16), const Radius.circular(3)), Paint()..color = accent);
    canvas.drawCircle(lockCenter.translate(0, -2), 3, Paint()..color = const Color(0xFF2A1A0A));

    // Vnitřní záře skrz škvíru (viditelná až se víko pootevře)
    if (openT > 0.15) {
      final gapOpacity = ((openT - 0.15) / 0.85).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(bodyRect.left + 4, bodyRect.top - 40, bodyRect.width - 8, 42),
        Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [accent.withOpacity(gapOpacity * .9), accent.withOpacity(0)]).createShader(Rect.fromLTWH(bodyRect.left, bodyRect.top - 40, bodyRect.width, 50)),
      );
    }

    // Víko - 3D rotace kolem panty na zadní hraně těla (perspektivní matice).
    final lidH = bodyRect.height * 0.62;
    final lidRectClosed = Rect.fromLTWH(bodyRect.left - 4, bodyRect.top - lidH, bodyRect.width + 8, lidH);
    final hinge = Offset(cx, bodyRect.top);
    canvas.save();
    canvas.translate(hinge.dx, hinge.dy);
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0025)
      ..rotateX(-openT * 2.05);
    canvas.transform(matrix.storage);
    canvas.translate(-hinge.dx, -hinge.dy);
    final lidRRect = RRect.fromRectAndCorners(lidRectClosed, topLeft: const Radius.circular(14), topRight: const Radius.circular(14));
    canvas.drawRRect(lidRRect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7A5230), Color(0xFF4A2C16)]).createShader(lidRectClosed));
    canvas.drawRRect(lidRRect, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = accent.withOpacity(.9));
    canvas.drawRect(Rect.fromLTWH(lidRectClosed.left - 2, lidRectClosed.bottom - 6, lidRectClosed.width + 4, 5), bandPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TreasureChestPainter old) => old.openT != openT || old.idleT != idleT;
}

class AnimatedTreasureChest extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onOpen;
  const AnimatedTreasureChest({super.key, required this.title, required this.subtitle, required this.accent, required this.onOpen});

  @override
  State<AnimatedTreasureChest> createState() => _AnimatedTreasureChestState();
}

class _AnimatedTreasureChestState extends State<AnimatedTreasureChest> with TickerProviderStateMixin {
  late final AnimationController _openController;
  late final AnimationController _idleController;
  bool _opening = false;
  final List<_ChestSpark> _sparks = List.generate(16, (i) => _ChestSpark(i * 7 + 3));

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _idleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _openController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_opening) return;
    HapticFeedback.mediumImpact();
    setState(() => _opening = true);
    _idleController.stop();
    _openController.forward(from: 0).whenComplete(() {
      if (mounted) widget.onOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: SizedBox(
            width: 220,
            height: 210,
            child: AnimatedBuilder(
              animation: Listenable.merge([_openController, _idleController]),
              builder: (context, _) {
                final t = _openController.value;
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(size: const Size(220, 210), painter: _TreasureChestPainter(openT: t, idleT: _idleController.value, accent: widget.accent)),
                    if (t > 0.35)
                      for (final s in _sparks)
                        Builder(builder: (context) {
                          final p = ((t - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
                          if (p <= 0) return const SizedBox.shrink();
                          final dist = s.speed * p;
                          final offset = Offset.fromDirection(s.angle - pi / 2, dist);
                          return Positioned(
                            left: 110 + offset.dx - s.size / 2,
                            top: 78 + offset.dy - s.size / 2,
                            child: Opacity(
                              opacity: (1 - p).clamp(0.0, 1.0),
                              child: Container(width: s.size, height: s.size, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: s.color.withOpacity(.8), blurRadius: 4)])),
                            ),
                          );
                        }),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.accent), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          _opening ? tr('Otevírá se...', 'Opening...') : widget.subtitle,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        if (!_opening) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: widget.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            onPressed: _handleTap,
            icon: const Icon(Icons.lock_open),
            label: Text(tr('Otevřít truhlu', 'Open chest')),
          ),
        ],
      ],
    );
  }
}

class ComboStreakBadge extends StatelessWidget {
  final int streak;
  const ComboStreakBadge({super.key, required this.streak});
  @override
  Widget build(BuildContext context) {
    if (streak < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.25), border: Border.all(color: Colors.deepOrangeAccent), borderRadius: BorderRadius.circular(4)),
      child: Text('🔥 x$streak', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
    );
  }
}

// Widget pro zobrazení seznamu buffů a debuffů
class StatusEffectsListWidget extends StatelessWidget {
  final List<StatusEffect> effects;
  const StatusEffectsListWidget({super.key, required this.effects});
  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      children: effects.map((eff) {
        return GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E24),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: eff.isBuff ? Colors.blueAccent : Colors.redAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(
                  eff.name,
                  style: TextStyle(color: eff.isBuff ? Colors.blue.shade100 : Colors.red.shade100, fontWeight: FontWeight.bold),
                ),
                content: Text(
                  eff.description.isNotEmpty ? eff.description : tr("Bez popisu.", "No description."),
                  style: const TextStyle(color: Color(0xFFF1E6D0)),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(tr("Zavřít", "Close"))),
                ],
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: eff.isBuff ? Colors.blue.withOpacity(0.3) : Colors.red.withOpacity(0.3),
              border: Border.all(color: eff.isBuff ? Colors.blueAccent : Colors.redAccent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${eff.name} (${eff.duration})",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: eff.isBuff ? Colors.blue.shade100 : Colors.red.shade100,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// "Uložit a ukončit" - dostupné jak z menu, tak přímo ve hře (viz AppBar v MainLayout).
// Hru uloží a vrátí hráče do hlavního menu (appka zůstává spuštěná, jen se ukončí
// aktuálně rozehraný běh). Toto tlačítko záměrně nesmí fungovat jako bezpečný
// checkpoint, ke kterému by šlo po nepovedeném boji/smrti "reloadnout" a vzít risk
// zpět - proto po uložení vždy rovnou opustí rozehranou hru, místo aby v ní nechalo
// hráče dál pokračovat. Skutečnou ochranu proti zneužití navíc dává průběžný
// automatický autosave v GameState (ukládá se sám i při smrti, ne jen na tomto tlačítku).
void showSaveAndExitDialog(BuildContext context, GameState state) {
  final s = AppStrings(state.language);
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFC69214)), borderRadius: BorderRadius.circular(8)),
      title: Text(s.saveAndExitConfirmTitle, style: const TextStyle(color: Color(0xFFFFB100))),
      content: Text(s.saveAndExitConfirmBody, style: const TextStyle(color: Color(0xFFF1E6D0))),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(s.cancel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69214)),
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            final ok = await state.saveGame();
            if (!context.mounted) return;
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.noSaveFound)));
              return;
            }
            // Ukončí rozehraný běh - vrátí na hlavní menu, appku nezavírá.
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Text(s.confirm),
        ),
      ],
    ),
  );
}

// ===== HLAVNÍ MENU =====
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  bool _checkedSave = false;
  bool _saveExists = false;
  late final AnimationController _glowController;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _checkSave();
    // Jemné "dýchání" glow kolem titulku/erbu - žádné externí assety, jen AnimationController.
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _glowPulse = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkSave() async {
    final state = Provider.of<GameState>(context, listen: false);
    final exists = await state.hasSaveGame();
    if (mounted) {
      setState(() {
        _saveExists = exists;
        _checkedSave = true;
      });
    }
  }

  void _goToGame() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MainLayout()));
  }

  Future<void> _onContinue(GameState state) async {
    final ok = await state.loadGame();
    if (ok) {
      _goToGame();
    } else if (mounted) {
      final s = AppStrings(state.language);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.noSaveFound)));
    }
  }

  void _startFreshAndPromptName(GameState state) {
    state.startCompletelyFresh();
    _nameController.clear();
    setState(() {}); // znovu zobrazí pole pro jméno na téže obrazovce
  }

  void _onNewGame(GameState state) {
    final s = AppStrings(state.language);
    if (!_saveExists && state.heroName.isEmpty) {
      // Ještě nic nebylo rozehráno ani uloženo - není co ztratit.
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text(s.newGameConfirmTitle, style: const TextStyle(color: Color(0xFFFFB100))),
        content: Text(s.newGameConfirmBody, style: const TextStyle(color: Color(0xFFF1E6D0))),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(s.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _startFreshAndPromptName(state);
            },
            child: Text(s.confirm),
          ),
        ],
      ),
    );
  }



  void _showLadder(GameState state) {
    final s = AppStrings(state.language);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFC69214)), borderRadius: BorderRadius.circular(8)),
        title: Text(s.ladder, style: const TextStyle(color: Color(0xFFFFB100), fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: state.ladder.isEmpty
              ? Padding(padding: const EdgeInsets.all(8.0), child: Text(s.ladderEmpty, style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.ladder.length,
                  itemBuilder: (context, index) {
                    final entry = state.ladder[index];
                    return ListTile(
                      leading: Text("#${index + 1}", style: const TextStyle(color: Color(0xFFFFB100), fontWeight: FontWeight.bold)),
                      title: Text(entry.heroName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${entry.heroClass.name.toUpperCase()} • ${entry.date.day}.${entry.date.month}.${entry.date.year}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: Text("${s.ladderFloor} ${entry.floorReached}", style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(s.close)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      final s = AppStrings(state.language);
      final hasName = state.heroName.isNotEmpty;
      if (hasName && _nameController.text.isEmpty) _nameController.text = state.heroName;

      return Scaffold(
        body: Container(
          // Atmosférické pozadí - radiální vinětka + dýchající zlatý glow za erbem.
          // TODO až bude hotový i horský background (backroud.png): přidat Positioned.fill
          // s Image.asset('assets/images/scenes/adventure_bg.png', fit: BoxFit.cover) úplně
          // dole ve Stacku (pod siluetou Věže i pod _SceneLifeOverlay), ať Věž stojí na skutečné
          // krajině místo na gradientu.
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [Color(0xFF241C10), FantasyColors.abyss]),
          ),
          child: Stack(
            children: [
              // Silueta Věže - kotví celou scénu vizuálně (stejná role jako v Dobrodružství mapě,
              // jen zblízka a bez ostatních budov okolo). Umístěná nahoře uprostřed, za obsahem.
              Positioned(
                top: -20, left: 0, right: 0,
                child: Center(
                  child: Opacity(
                    opacity: 0.85,
                    child: Image.asset('assets/images/scenes/tower_silhouette.png', height: 420, fit: BoxFit.contain),
                  ),
                ),
              ),
              // Živá vrstva - poletující jiskry/embery (danger paleta, stejná jako
              // Dobrodružství) + jemně blikající světlo poblíž arkánového okna Věže, ať vstupní
              // obrazovka není jediné mrtvé místo ve hře.
              Positioned.fill(
                child: _SceneLifeOverlay(danger: true, smokePoints: const [], glowPoints: const [Offset(0.5, 0.13)]),
              ),
              SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _glowPulse,
                        builder: (context, child) => Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: const Color(0xFFC69214).withOpacity(0.15 + _glowPulse.value * 0.25), blurRadius: 24 + _glowPulse.value * 16, spreadRadius: 2 + _glowPulse.value * 4)],
                          ),
                          child: child,
                        ),
                        child: const Icon(Icons.castle, size: 64, color: Color(0xFFC69214)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.gameTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF1E6D0),
                          letterSpacing: 1.6,
                          shadows: [Shadow(color: const Color(0xFFC69214).withOpacity(0.7), blurRadius: 16)],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('ARPG • Permadeath • Rank & Paragon navždy', 'ARPG • Permadeath • Rank & Paragon forever'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF9C8B6B), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 28),

                    // Jazyk CZ/EN + Vibrace
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: state.toggleVibration,
                          icon: Icon(state.vibrationEnabled ? Icons.vibration : Icons.mobile_off, color: const Color(0xFFC69214)),
                          label: Text(state.vibrationEnabled ? s.vibrationOn : s.vibrationOff, style: const TextStyle(color: Color(0xFFC69214), fontWeight: FontWeight.bold)),
                        ),
                        TextButton.icon(
                          onPressed: state.toggleLanguage,
                          icon: const Icon(Icons.language, color: Color(0xFFC69214)),
                          label: Text(state.language == "cs" ? "CZ 🇨🇿" : "EN 🇬🇧", style: const TextStyle(color: Color(0xFFC69214), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Jméno hrdiny
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFC69214), width: 1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.heroNameLabel, style: const TextStyle(color: Color(0xFFFFB100), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (hasName)
                            Text(s.heroNameLockedNote(state.heroName), style: const TextStyle(color: Color(0xFFF1E6D0)))
                          else
                            TextField(
                              controller: _nameController,
                              maxLength: 20,
                              style: const TextStyle(color: Color(0xFFF1E6D0)),
                              decoration: InputDecoration(
                                hintText: s.heroNameHint,
                                hintStyle: const TextStyle(color: Colors.grey),
                                counterStyle: const TextStyle(color: Colors.grey),
                                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC69214))),
                              ),
                              onSubmitted: (v) => state.setHeroName(v),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Start / Pokračovat
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69214), padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.play_arrow, color: Colors.black),
                        label: Text(hasName ? s.continueGame : s.startGame, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () {
                          if (!hasName) {
                            if (_nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.nameRequired)));
                              return;
                            }
                            state.setHeroName(_nameController.text);
                            _goToGame();
                          } else {
                            _goToGame();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Nová hra
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.refresh, color: Colors.redAccent),
                        label: Text(s.newGame, style: const TextStyle(color: Colors.redAccent)),
                        onPressed: () => _onNewGame(state),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),

                    // Uložit / Načíst / Žebříček
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.exit_to_app, size: 18),
                            label: Text(s.save, style: const TextStyle(fontSize: 12)),
                            onPressed: () => showSaveAndExitDialog(context, state),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.folder_open, size: 18),
                            label: Text(s.load, style: const TextStyle(fontSize: 12)),
                            onPressed: () => _onContinue(state),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.tealAccent)),
                        icon: const Icon(Icons.leaderboard, color: Colors.tealAccent),
                        label: Text(s.ladder, style: const TextStyle(color: Colors.tealAccent)),
                        onPressed: () => _showLadder(state),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Prominentní pruh měn zobrazený vždy nad HP/XP lištami — nahrazuje
/// původní měnové čipy nacpané do AppBar akcí (na užších telefonech se
/// ořezávaly). Velká čísla se zkracují (12 400 → 12.4K) pro rychlou čitelnost
/// za hraní.
class _ResourceBar extends StatelessWidget {
  final int gold;
  final int crystals;
  final int magicDust;
  final int legendaryEssence;
  const _ResourceBar({required this.gold, required this.crystals, required this.magicDust, required this.legendaryEssence});

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _cell(BuildContext context, FantasyIconType iconType, Color color, int value, String name, String dropInfo, String useInfo) {
    // Každá měna teď má jemný barevný glow za ikonou + větší, výraznější číslo - dřív
    // ploché 13px, teď 16px s textovým stínem odpovídajícím barvě dané měny.
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showFantasyInfoDialog(
          context,
          icon: Icons.info_outline,
          iconWidget: SizedBox(width: 22, height: 22, child: CustomPaint(painter: FantasyIconRegistry.of(iconType).proceduralPainter(color))),
          title: name,
          color: color,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(Icons.arrow_downward, color: color, size: 13), const SizedBox(width: 5), Text(tr("Odkud", "From"), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))]),
              const SizedBox(height: 3),
              Text(dropInfo, style: const TextStyle(color: Color(0xFFF1E6D0), height: 1.35)),
              const SizedBox(height: 12),
              Row(children: [Icon(Icons.bolt, color: color, size: 13), const SizedBox(width: 5), Text(tr("K čemu slouží", "Used for"), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))]),
              const SizedBox(height: 3),
              Text(useInfo, style: const TextStyle(color: Color(0xFFF1E6D0), height: 1.35)),
            ],
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(.45), blurRadius: 6, spreadRadius: .5)]),
            child: SizedBox(width: 16, height: 16, child: CustomPaint(painter: FantasyIconRegistry.of(iconType).proceduralPainter(color))),
          ),
          const SizedBox(width: 6),
          Text(
            _fmt(value),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, shadows: [Shadow(color: color.withOpacity(.6), blurRadius: 8)]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      _cell(
        context, FantasyIconType.currencyGold, FantasyColors2.emberGold, gold,
        tr("Zlato", "Gold"),
        tr("Poráženi nepřátel ve všech bojových módech (Věž, Doupě, Aréna, World Boss, Trhlina), questy a denní odměny.",
            "Defeating enemies in all combat modes (Tower, Lair, Arena, World Boss, Rift), quests and daily rewards."),
        tr("Nákupy v Tržišti - lektvary, základní vybavení a speciální raritní/set nabídky.",
            "Purchases in the Market - potions, basic gear and the special rare/set featured offers."),
      ),
      if (crystals > 0)
        _cell(
          context, FantasyIconType.currencyCrystal, FantasyColors2.arcaneViolet, crystals,
          tr("Krystaly", "Crystals"),
          tr("Prémiová měna - úspěchy, questy, denní odměny, truhly z Arény/Trhliny a příležitostně za shlédnutí reklamy.",
              "Premium currency - achievements, quests, daily rewards, Arena/Rift chests and occasionally rewarded ads."),
          tr("Rankování Kováře (lepší staty a ceny na Tržišti) a další prémiové nákupy/rerolly.",
              "Ranking up the Blacksmith (better Market stats and prices) and other premium purchases/rerolls."),
        ),
      if (magicDust > 0)
        _cell(
          context, FantasyIconType.materialMagicDust, FantasyColors2.teal, magicDust,
          tr("Magický prach", "Magic Dust"),
          tr("Boj, questy, truhly (Aréna/Trhlina) a salvage (rozebrání) nepotřebného vybavení v inventáři.",
              "Combat, quests, chests (Arena/Rift) and salvaging unwanted gear from your inventory."),
          tr("Vylepšování vybavení a runových kamenů u Kováře, craftění a upgrade artefaktové zbraně.",
              "Upgrading gear and rune stones at the Blacksmith, crafting and upgrading the artifact weapon."),
        ),
      if (legendaryEssence > 0)
        _cell(
          context, FantasyIconType.materialLegendaryEssence, FantasyColors2.hp, legendaryEssence,
          tr("Esence Moci", "Power Essence"),
          tr("Od patra 30 ve Věži a Doupěti bosse (Hardcore a vyšší obtížnost dává dvojnásobek) a z World Bosse.",
              "From floor 30 in the Tower and Boss Lair (Hardcore and higher difficulty gives double), and from the World Boss."),
          tr("Vylepšování legendárního vybavení a odemykání uzlů na artefaktové zbrani.",
              "Upgrading legendary gear and unlocking artifact weapon skill nodes."),
        ),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FantasyColors2.panelLight, FantasyColors2.panel]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FantasyColors2.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: cells.map((c) => Expanded(child: c)).toList()),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _navIndex = 0;
  bool _deathDialogShown = false;
  bool _offlineDialogShown = false;
  // Věž Osudu už není permanentní tab (přesunuta jako budova do Dobrodružství - viz
  // AdventureScreen). Nový hráč (bez zvolené třídy) nebo hráč, co ještě neviděl úvod, by ale bez
  // tohohle musel sám uhodnout, že má ťuknout na budovu Věže - takže ji při prvním otevření
  // appky (nebo hned po smrti, viz _showDeathDialog) otevřeme automaticky za něj. Flag zajistí,
  // že se to zkusí jen jednou za život téhle State - když se hráč sám vrátí zpět bez výběru
  // třídy, znovu se mu to nevnucuje, může si Věž kdykoli otevřít ťuknutím na mapě.
  bool _autoOpenedTowerOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoOpenedTowerOnce) return;
      final state = Provider.of<GameState>(context, listen: false);
      if (!state.introSeen || state.heroClass == HeroClass.none) {
        _autoOpenedTowerOnce = true;
        openWorldScreen(context, tr('Věž Osudu', 'Tower of Fate'), const TowerScreen(), theme: const Color(0xFF1E88E5));
      }
    });
  }

  // Pořadí odpovídá spodní navigační liště níže. Věž Osudu (dřív index 0, vlastní tematické
  // pozadí) je teď přesunutá jako budova do Dobrodružství (viz AdventureScreen) - otevírá se
  // přes openWorldScreen (Navigator push), ne jako permanentní tab. Dobrodružství/Město tak
  // posunuly na indexy 0/1, zbytek o 1 dolů oproti dřívějšku.
  static final _navScreens = [
    const AdventureScreen(),
    const CityScreen(),
    Container(
      decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.4, colors: [Color(0x29C9A96E), FantasyColors.abyss])), // bronzová - Inventář/gear
      child: const InventoryScreen(),
    ),
    Container(
      decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.4, colors: [Color(0x297137A8), FantasyColors.abyss])), // fialová - Duše/talenty
      child: const SoulsScreen(),
    ),
    Container(
      decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.4, colors: [Color(0x29FFD700), FantasyColors.abyss])), // zlatá - Achievementy
      child: const AchievementsScreen(),
    ),
    const ProfileScreen(),
  ];

  void _showDeathDialog(BuildContext context, GameState state) {
    _deathDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.redAccent, width: 1.5), borderRadius: BorderRadius.circular(8)),
        title: Text(tr("💀 Padl jsi!", "💀 You have fallen!"), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF141014), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF49341F))),
                child: Text(
                  state.deathEpitaph,
                  style: const TextStyle(color: Color(0xFFC9B896), fontStyle: FontStyle.italic, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  "${state.message}\n\nNasazené a zamčené (🔒) itemy zůstanou zachovány. Ostatní vybavení se přemění na Magic Dust:\n+${state.deathSalvagePreview} ✨\n\nZlato: ${state.gold} → ${(state.gold * 0.5).floor()} (o polovinu přijdeš)",
                  "${state.message}\n\nEquipped and locked (🔒) items are kept. The rest of your gear is converted into Magic Dust:\n+${state.deathSalvagePreview} ✨\n\nGold: ${state.gold} → ${(state.gold * 0.5).floor()} (you lose half)",
                ),
                style: const TextStyle(color: Color(0xFFF1E6D0)),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deathDialogShown = false;
              state.confirmDeath();
              // confirmDeath() vynuluje heroClass na none. Věž Osudu už není permanentní tab
              // (přesunuta do Dobrodružství jako budova) - bez tohohle by hráč po smrti zůstal
              // třeba v Batohu/Profilu a musel by sám najít a ťuknout budovu Věže, aby si mohl
              // vybrat novou třídu. Otevřeme mu ji tedy rovnou.
              setState(() => _navIndex = 0);
              openWorldScreen(context, tr('Věž Osudu', 'Tower of Fate'), const TowerScreen(), theme: const Color(0xFF1E88E5));
            },
            child: Text(tr("Rozumím, pokračovat", "Understood, continue")),
          ),
        ],
      ),
    );
  }

  Widget _navSlot(FantasyIconType iconType, String label, int index, {GameState? state}) {
    final active = _navIndex == index;
    final color = active ? FantasyColors2.emberGold : const Color(0xFF7A6F8A);
    // Dobrodružství (0) a Město (1) - badge "něco nového" se ukazuje na OBOU, dokud hráč jeden z
    // nich neotevře (markWorldTabSeen se volá při vstupu do kteréhokoli z nich - viz onTap níž).
    final bool showNewBadge = (index == 0 || index == 1) && state != null && state.hasUnseenWorldUnlock;
    return InkWell(
      onTap: () => setState(() {
        _navIndex = index;
        if ((index == 0 || index == 1) && state != null) state.markWorldTabSeen();
      }),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: active
                        ? BoxDecoration(color: FantasyColors2.panelLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: FantasyColors2.border))
                        : null,
                    child: SizedBox(width: 20, height: 20, child: CustomPaint(painter: FantasyIconRegistry.of(iconType).proceduralPainter(color))),
                  ),
                  if (showNewBadge)
                    Positioned(
                      top: -2,
                      right: 2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(color: FantasyColors2.hp, shape: BoxShape.circle, border: Border.all(color: FantasyColors2.obsidian, width: 1.5)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineRewardDialog(BuildContext context, GameState state) {
    final duration = state.pendingOfflineDurationText ?? '';
    final baseGold = state.pendingOfflineGold;
    final baseDust = state.pendingOfflineDust;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF00E5A0), width: 1.5), borderRadius: BorderRadius.circular(8)),
        title: Text(tr("👋 Vítej zpět!", "👋 Welcome back!"), style: const TextStyle(color: Color(0xFF00E5A0), fontWeight: FontWeight.bold)),
        content: Text(
          tr("Zatímco jsi byl pryč ($duration), tvá družina vydělala +$baseGold 🪙 a +$baseDust Dust.",
              "While you were away ($duration), your party earned +$baseGold 🪙 and +$baseDust Dust."),
          style: const TextStyle(color: Color(0xFFF1E6D0)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _offlineDialogShown = false;
              state.claimOfflineProgress(doubled: false);
            },
            child: Text(tr("Vzít", "Take it"), style: const TextStyle(color: Color(0xFFF1E6D0))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
            icon: const Icon(Icons.play_circle_fill),
            label: Text(tr("Zdvojnásobit (reklama)", "Double it (ad)")),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _offlineDialogShown = false;
              RewardedAdService.instance.show(onReward: () => state.claimOfflineProgress(doubled: true));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      if (state.isDead && !_deathDialogShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && state.isDead) _showDeathDialog(context, state);
        });
      }
      if ((state.pendingOfflineGold > 0 || state.pendingOfflineDust > 0) && !_offlineDialogShown) {
        _offlineDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && (state.pendingOfflineGold > 0 || state.pendingOfflineDust > 0)) {
            _showOfflineRewardDialog(context, state);
          } else {
            _offlineDialogShown = false;
          }
        });
      }
      String appBarTitle = tr("Věže Osudu", "Towers of Fate");
      if (state.hasRank100Class) {
        if (state.heroClass == HeroClass.warrior) {
          appBarTitle = state.rank100Choice == 1 ? tr("Titan Osudu", "Titan of Fate") : (state.rank100Choice == 2 ? tr("Nezničitelný Juggernaut Osudu", "Indestructible Juggernaut of Fate") : tr("Svořitel Války Osudu", "War-Forger of Fate"));
        } else if (state.heroClass == HeroClass.hunter) {
          appBarTitle = state.rank100Choice == 1 ? tr("Vendeta incarnate Osudu", "Vendetta Incarnate of Fate") : (state.rank100Choice == 2 ? tr("Přízrak Osudu", "Phantom of Fate") : tr("Kosmický Lovec Osudu", "Cosmic Hunter of Fate"));
        } else if (state.heroClass == HeroClass.healer) {
          appBarTitle = state.rank100Choice == 1 ? tr("Vládce magie Osudu", "Magic Lord of Fate") : (state.rank100Choice == 2 ? tr("Mistr Života Osudu", "Life Master of Fate") : tr("Svatý Osvícený Osudu", "Holy Enlightened One of Fate"));
        } else if (state.heroClass == HeroClass.deathknight) {
          appBarTitle = state.rank100Choice == 1 ? tr("Kostěný Lich Osudu", "Bone Lich of Fate") : (state.rank100Choice == 2 ? tr("Temný Reaper Osudu", "Dark Reaper of Fate") : tr("Pán Duší Osudu", "Soul Lord of Fate"));
        } else if (state.heroClass == HeroClass.mage) {
          appBarTitle = state.rank100Choice == 1 ? tr("Pyromancer Osudu", "Pyromancer of Fate") : (state.rank100Choice == 2 ? tr("Cryomancer Osudu", "Cryomancer of Fate") : tr("Chronomancer Osudu", "Chronomancer of Fate"));
        } else if (state.heroClass == HeroClass.duelist) {
          appBarTitle = state.rank100Choice == 1 ? tr("Nemesis Osudu", "Nemesis of Fate") : (state.rank100Choice == 2 ? tr("Tanečník Čepelí Osudu", "Blade Dancer of Fate") : tr("Bleskový Mistr Osudu", "Lightning Master of Fate"));
        } else if (state.heroClass == HeroClass.monk) {
          appBarTitle = state.rank100Choice == 1 ? tr("Pěst tisíce bouří Osudu", "Fist of a Thousand Storms of Fate") : (state.rank100Choice == 2 ? tr("Kamenný Strážce Osudu", "Stone Guardian of Fate") : tr("Probuzený Duch Osudu", "Awakened Spirit of Fate"));
        }
      } else if (state.isDeathReaper) appBarTitle = tr("Žnec Smrti Osudu", "Death Reaper of Fate");
      else if (state.isPlagueLord) appBarTitle = tr("Pán Moru Osudu", "Plague Lord of Fate");
      else if (state.isDarkKnight) appBarTitle = tr("Temný rytíř Osudu", "Dark Knight of Fate");
      else if (state.isValhallaWarrior) appBarTitle = tr("Bojovník Valhaly Osudu", "Valhalla Warrior of Fate");
      else if (state.isVoidStalker) appBarTitle = tr("Pán Prázdnoty Osudu", "Void Lord of Fate");
      else if (state.isLightBearer) appBarTitle = tr("Nositel světla Osudu", "Light Bearer of Fate");
      else if (state.isWarlord) appBarTitle = tr("Vládce války Osudu", "Warlord of Fate");
      else if (state.isShadowMaster) appBarTitle = tr("Mistr stínů Osudu", "Shadow Master of Fate");
      else if (state.isProrok) appBarTitle = tr("Prorok Osudu", "Prophet of Fate");
      else if (state.isBerserk) appBarTitle = tr("Berserk Osudu", "Berserker of Fate");
      else if (state.isAssassin) appBarTitle = tr("Asasín Osudu", "Assassin of Fate");
      else if (state.isPriest) appBarTitle = tr("Kněz Osudu", "Priest of Fate");
      else if (state.isArchmage) appBarTitle = tr("Archmág Osudu", "Archmage of Fate");
      else if (state.isArcanist) appBarTitle = tr("Arcanista Osudu", "Arcanist of Fate");
      else if (state.isElementalist) appBarTitle = tr("Elementalista Osudu", "Elementalist of Fate");
      else if (state.isStormblade) appBarTitle = tr("Ostří Bouře Osudu", "Storm Blade of Fate");
      else if (state.isBladeMaster) appBarTitle = tr("Mistr Čepele Osudu", "Blademaster of Fate");
      else if (state.isBladeDancer) appBarTitle = tr("Šermík Osudu", "Swordsman of Fate");
      return Stack(children: [
        Scaffold(
        backgroundColor: FantasyColors2.obsidian,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 18)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.heroName.isNotEmpty)
                    Text(state.heroName, style: const TextStyle(fontSize: 11, color: Color(0xFFC69214), fontWeight: FontWeight.normal)),
                  if (state.heroName.isNotEmpty) const SizedBox(width: 6),
                  Text('${tr("Lv.", "Lv.")} ${state.level}', style: const TextStyle(fontSize: 11, color: FantasyColors2.emberGold, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: AppStrings(state.language).save,
            onPressed: () => showSaveAndExitDialog(context, state),
          ),
        ],
        ),
        body: Column(
          children: [
            _ResourceBar(
              gold: state.gold,
              crystals: state.crystals,
              magicDust: state.magicDust,
              legendaryEssence: state.legendaryEssence,
            ),
            Expanded(
              child: IndexedStack(
                index: _navIndex,
                children: _navScreens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: FantasyColors2.obsidian,
            border: Border(top: BorderSide(color: FantasyColors2.panelLight)),
          ),
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navSlot(FantasyIconType.systemBossLair, tr('Dobrodružství', 'Adventure'), 0, state: state),
                _navSlot(FantasyIconType.systemGuild, tr('Město', 'Town'), 1, state: state),
                _navSlot(FantasyIconType.systemInventory, tr('Batoh', 'Bag'), 2),
                if (state.soulsTabRevealed) _navSlot(FantasyIconType.currencyEssence, tr('Duše', 'Souls'), 3),
                if (state.unlockedAchievements.isNotEmpty) _navSlot(FantasyIconType.markLegendary, tr('Úspěchy', 'Achievements'), 4),
                _navSlot(state.heroClassIcon, tr('Profil', 'Profile'), 5),
              ],
            ),
          ),
        ),
        ),
        if (state.mustHireFirstCompanion) const _FirstCompanionGateOverlay(),
      ]);
    });
  }

}



class LairScreen extends StatelessWidget {
  const LairScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      if (state.isInLair) {
        int healingPotionsCount = state.consumables.where((i) => i.name == "Léčivý lektvar").fold(0, (sum, i) => sum + i.stackCount);
        int vampirePotionsCount = state.consumables.where((i) => i.name == "Upíří Lektvar").fold(0, (sum, i) => sum + i.stackCount);
        final heroAccent = heroClassAccent(state.heroClass);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(tr("SOUBOJ V LAIR (Patro ${state.lairTargetFloor})", "LAIR BATTLE (Floor ${state.lairTargetFloor})"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ),
                  // Stejné přepínače zobrazení jako ve Věži - portrét/detail a viditelnost statů.
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    iconSize: 18,
                    tooltip: state.portraitCombatMode ? tr('Přepnout na detailní zobrazení', 'Switch to detailed view') : tr('Přepnout na portrét', 'Switch to portrait view'),
                    icon: Icon(state.portraitCombatMode ? Icons.view_list : Icons.portrait, color: Colors.grey),
                    onPressed: state.togglePortraitCombatMode,
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    iconSize: 18,
                    tooltip: state.combatStatsVisible ? tr('Skrýt staty', 'Hide stats') : tr('Zobrazit staty', 'Show stats'),
                    icon: Icon(state.combatStatsVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                    onPressed: state.toggleCombatStats,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF1E88E5), width: 1), borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (state.portraitCombatMode) ...[
                              if (kClassPortraitAssets[state.heroClass] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 170,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        LivingPortrait(assetPath: kClassPortraitAssets[state.heroClass]!, accent: heroAccent, mode: PortraitLifeMode.subtle),
                                        DecoratedBox(decoration: BoxDecoration(border: Border.all(color: heroAccent.withOpacity(.6), width: 2), borderRadius: BorderRadius.circular(12))),
                                        Positioned(
                                          left: 0, right: 0, bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                                            child: Text(state.heroName.isNotEmpty ? state.heroName : tr("Hrdina", "Hero"), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: heroAccent)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Center(
                                  child: Column(children: [
                                    Container(
                                      width: 64, height: 64, padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [heroAccent.withOpacity(.5), const Color(0xFF14181C)]), border: Border.all(color: heroAccent.withOpacity(.7), width: 2), boxShadow: [BoxShadow(color: heroAccent.withOpacity(.6), blurRadius: 14)]),
                                      child: CustomPaint(painter: FantasyIconRegistry.of(heroClassIconType(state.heroClass)).proceduralPainter(heroAccent)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(state.heroName.isNotEmpty ? state.heroName : tr("Hrdina", "Hero"), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: heroAccent)),
                                  ]),
                                ),
                              const SizedBox(height: 8),
                            ] else ...[
                              Row(children: [
                                Container(
                                  width: 26, height: 26, padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [heroAccent.withOpacity(.45), const Color(0xFF14181C)]), boxShadow: [BoxShadow(color: heroAccent.withOpacity(.6), blurRadius: 8)]),
                                  child: kClassPortraitAssets[state.heroClass] != null
                                      ? ClipOval(child: Image.asset(kClassPortraitAssets[state.heroClass]!, width: 16, height: 16, fit: BoxFit.cover))
                                      : CustomPaint(painter: FantasyIconRegistry.of(heroClassIconType(state.heroClass)).proceduralPainter(heroAccent)),
                                ),
                                const SizedBox(width: 7),
                                Expanded(child: Text(state.heroName.isNotEmpty ? state.heroName : tr("Hrdina", "Hero"), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: heroAccent))),
                              ]),
                              const Divider(),
                            ],
                            BarWidget(value: state.hp.toDouble(), max: state.maxHp.toDouble(), color: Colors.green, label: "HP"),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Visibility(
                                visible: state.bonusShield > 0,
                                maintainSize: true, maintainAnimation: true, maintainState: true,
                                child: BarWidget(value: state.bonusShield.toDouble(), max: max(1, state.bonusShield).toDouble(), color: const Color(0xFF1E88E5), label: tr("Štít", "Shield")),
                              ),
                            ),
                            const SizedBox(height: 4),
                            BarWidget(value: state.currentResourceValue.toDouble(), max: max(1, state.maxResourceValue).toDouble(), color: state.resourceColor, label: state.resourceName),
                            const SizedBox(height: 6),
                            if (state.combatStatsVisible && !state.portraitCombatMode) ...[
                              Text("P.Atk: ${formatCompactNumber(state.physAtk)}", style: const TextStyle(fontSize: 12)),
                              Text("M.Atk: ${formatCompactNumber(state.magAtk)}", style: const TextStyle(fontSize: 12)),
                              Text("Armor: ${formatCompactNumber(state.armor)}", style: const TextStyle(fontSize: 12)),
                              Text(tr("Redukce: ${(state.physicalReduction*100).toStringAsFixed(1)} % fyz. / ${(state.magicalReduction*100).toStringAsFixed(1)} % mag.", "Reduction: ${(state.physicalReduction*100).toStringAsFixed(1)}% phys. / ${(state.magicalReduction*100).toStringAsFixed(1)}% mag."), style: const TextStyle(fontSize: 12)),
                              Text(tr("Crit: ${(state.critChance * 100).toStringAsFixed(1)}% | Úhyb: ${(state.dodgeChance * 100).toStringAsFixed(1)}% | Blok: ${(state.blockChance * 100).toStringAsFixed(1)}%", "Crit: ${(state.critChance * 100).toStringAsFixed(1)}% | Dodge: ${(state.dodgeChance * 100).toStringAsFixed(1)}% | Block: ${(state.blockChance * 100).toStringAsFixed(1)}%"), style: const TextStyle(fontSize: 11, color: Colors.tealAccent)),
                              const SizedBox(height: 8),
                            ],
                            Text(tr("Buffy / Debuffy:", "Buffs / Debuffs:"), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 4),
                            StatusEffectsListWidget(effects: state.heroEffects),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.redAccent, width: 1), borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Builder(builder: (context) {
                              final (bossIcon, bossColor) = state.bossThemeIconFor({'name': state.currentLairBossName, 'ability': state.currentLairBossAbility});
                              final bossPortrait = kBossPortraitAssets[state.currentLairBossName];
                              if (state.portraitCombatMode && bossPortrait != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 170,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        LivingPortrait(assetPath: bossPortrait, accent: bossColor, mode: PortraitLifeMode.subtle),
                                        DecoratedBox(decoration: BoxDecoration(border: Border.all(color: bossColor.withOpacity(.6), width: 2), borderRadius: BorderRadius.circular(12))),
                                        Positioned(
                                          left: 0, right: 0, bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                                            child: Text(state.currentLairBossName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              if (state.portraitCombatMode) {
                                return Center(
                                  child: Column(children: [
                                    Container(
                                      width: 64, height: 64, padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [bossColor.withOpacity(.5), const Color(0xFF1E1613)]), border: Border.all(color: bossColor.withOpacity(.7), width: 2), boxShadow: [BoxShadow(color: bossColor.withOpacity(.6), blurRadius: 14)]),
                                      child: Icon(bossIcon, size: 32, color: bossColor),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(state.currentLairBossName, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                  ]),
                                );
                              }
                              return Row(children: [
                                Container(
                                  width: 32, height: 32, padding: bossPortrait != null ? EdgeInsets.zero : const EdgeInsets.all(6),
                                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [bossColor.withOpacity(.5), const Color(0xFF1E1613)]), border: Border.all(color: bossColor.withOpacity(.7), width: 1.5), boxShadow: [BoxShadow(color: bossColor.withOpacity(.6), blurRadius: 10)]),
                                  child: bossPortrait != null
                                      ? ClipOval(child: LivingPortrait(assetPath: bossPortrait, accent: bossColor, mode: PortraitLifeMode.subtle))
                                      : Icon(bossIcon, size: 16, color: bossColor),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(state.currentLairBossName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent))),
                              ]);
                            }),
                            const SizedBox(height: 4),
                            Text(tr("Schopnost: ${state.currentLairBossAbility}", "Ability: ${state.currentLairBossAbility}"), style: const TextStyle(fontSize: 10, color: Colors.amberAccent)),
                            if (state.currentLairBossLore.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(state.currentLairBossLore, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF8A7A5C))),
                            ],
                            const SizedBox(height: 8),
                            BarWidget(value: state.currentLairBossHp.toDouble(), max: state.currentLairBossMaxHp.toDouble(), color: Colors.deepOrange, label: tr("HP Bosse", "Boss HP")),
                            if (state.combatStatsVisible && !state.portraitCombatMode) ...[
                              const SizedBox(height: 6),
                              Text(tr("Atk: ${formatCompactNumber(state.currentLairBossAtk)} | Def: ${formatCompactNumber(state.currentLairBossDef)}", "Atk: ${formatCompactNumber(state.currentLairBossAtk)} | Def: ${formatCompactNumber(state.currentLairBossDef)}"), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                            const SizedBox(height: 8),
                            Text(tr("Buffy / Debuffy:", "Buffs / Debuffs:"), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 4),
                            StatusEffectsListWidget(effects: state.enemyEffects),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              CombatLogSection(state: state, message: state.message, type: classifyCombatMessage(state.message)),
              const SizedBox(height: 10),
              if (classPassiveBar(state) != null) ...[
                classPassiveBar(state)!,
                const SizedBox(height: 8),
              ],
              combatActionGrid(
                basicAttack: SpellIconButton(
                  visual: basicAttackVisual(state), size: 62,
                  costLabel: tr('Základní útok', 'Basic Attack'),
                  onPressed: () => state.fightLairBoss(state.classIsMagicAttack),
                ),
                tier1: state.hasAdvancedClass
                    ? SpellIconButton(
                        visual: spellVisualTier1(state.heroClass),
                        costLabel: '1×, ${state.ability1Cost} ${state.resourceName}',
                        disabled: state.lairAbilityUsed || state.currentResourceValue < state.ability1Cost,
                        overlayText: state.lairAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: state.useLairActiveAbility,
                      )
                    : lockedAbilitySlot(state, spellVisualTier1(state.heroClass), 15),
                tier2: state.hasUltimateClass
                    ? SpellIconButton(
                        visual: spellVisualTier2(state.heroClass),
                        costLabel: '1×, ${state.ability2Cost} ${state.resourceName}',
                        disabled: state.lairSecondAbilityUsed || state.currentResourceValue < state.ability2Cost,
                        overlayText: state.lairSecondAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: state.useLairSecondAbility,
                      )
                    : lockedAbilitySlot(state, spellVisualTier2(state.heroClass), 40),
                tier3: state.hasGodClass
                    ? SpellIconButton(
                        visual: spellVisualTier3(state.heroClass),
                        costLabel: '1×, ${state.ability3Cost} ${state.resourceName}',
                        disabled: state.lairThirdAbilityUsed || state.currentResourceValue < state.ability3Cost,
                        overlayText: state.lairThirdAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: state.useLairThirdAbility,
                      )
                    : lockedAbilitySlot(state, spellVisualTier3(state.heroClass), 75),
                tier4: state.hasRank100Class
                    ? SpellIconButton(
                        visual: spellVisualTier4(state.heroClass, state.rank100Choice),
                        costLabel: '1×, ${state.ability4Cost} ${state.resourceName}',
                        disabled: state.lairFourthAbilityUsed || state.currentResourceValue < state.ability4Cost,
                        overlayText: state.lairFourthAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: state.useLairFourthAbility,
                      )
                    : lockedTier4Slot(state),
                relic: state.currentSpecRelicUnlocked
                    ? SpellIconButton(
                        visual: SpellVisual('Relic: ${state.currentSpecRelic.spell}', state.currentSpecRelic.icon, state.currentSpecRelic.color),
                        costLabel: tr('Relic Lv ${state.currentSpecRelicLevel}', 'Relic Lv ${state.currentSpecRelicLevel}'),
                        disabled: !state.isSpecRelicEquipped || state.specRelicUsedLair,
                        overlayText: !state.isSpecRelicEquipped ? tr('Nenasazen', 'Not equipped') : (state.specRelicUsedLair ? tr('Použito', 'Used') : null),
                        onPressed: state.useSpecRelicLairSpell,
                      )
                    : lockedRelicSlot(),
                healPotion: ConsumableIconButton(
                  icon: Icons.medical_services, color: Colors.greenAccent,
                  count: min(healingPotionsCount, 5 - state.lairPotionsUsed),
                  tooltip: tr('Léčivý lektvar (${5 - state.lairPotionsUsed}/5 použití v tomhle Lairu)', 'Healing Potion (${5 - state.lairPotionsUsed}/5 uses in this Lair)'),
                  onPressed: (healingPotionsCount > 0 && state.lairPotionsUsed < 5) ? state.useLairPotion : null,
                ),
                vampirePotion: ConsumableIconButton(
                  icon: Icons.water_drop, color: Colors.purpleAccent, count: vampirePotionsCount,
                  tooltip: tr('Upíří lektvar', 'Vampiric Potion'),
                  onPressed: vampirePotionsCount > 0 ? state.useLairVampirePotion : null,
                ),
              ),
              const SizedBox(height: 15),
              const SizedBox(height: 10),
              TextButton(
                onPressed: state.exitLair,
                child: Text(tr("Utéct z Lair", "Flee the Lair"), style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      }
      // Patro 101 (Strážce Brány) má vlastní speciální kartu níž - generický seznam je natvrdo 1-100.
      int maxVisibleFloor = 100;
      // Nejdřív nesplněné bosse (v pořadí pater), poražené sesypané dolů na konec seznamu -
      // ať se hráč nemusí prokousávat odškrtnutými patry ke svému aktuálnímu cíli.
      final orderedFloors = List.generate(maxVisibleFloor, (index) => index + 1)
        ..sort((a, b) {
          final aDone = state.isLairRewardClaimed(a);
          final bDone = state.isLairRewardClaimed(b);
          if (aDone != bDone) return aDone ? 1 : -1;
          return a.compareTo(b);
        });
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr("Doupě Bossů (1–100) • ${state.currentDifficultyKey.toUpperCase()} • ${state.activeCurse == CurseOfFate.none ? 'bez prokletí' : state.curseNameFor(state.activeCurse)}", "Boss Lair (1–100) • ${state.currentDifficultyKey.toUpperCase()} • ${state.activeCurse == CurseOfFate.none ? 'no curse' : state.curseNameFor(state.activeCurse)}"), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
          Text(tr("Zde můžeš vyzvat bosse z již dosažených pater. Každý boss dává loot jednou pro každou kombinaci obtížnosti a prokletí.", "Here you can challenge bosses from floors you have already reached. Each boss gives loot once per difficulty and curse combination."), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),
          ...orderedFloors.map((targetFloor) {
            bool isDefeated = state.isLairRewardClaimed(targetFloor);
            bool isUnlocked = targetFloor <= state.floor;
            int rewardDust = state.lairRewardDustFor(targetFloor);
            int rewardCrystals = state.lairRewardCrystalsFor(targetFloor);
            var bossInfo = state.getBossDetails(targetFloor);
            final themeIcon = state.bossThemeIconFor(bossInfo);
            return Card(
              color: isDefeated ? const Color(0xFF1E2F23) : const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isDefeated ? Colors.green : (isUnlocked ? const Color(0xFFC69214) : Colors.grey.shade800), width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(
                  isDefeated ? Icons.check_circle : (isUnlocked ? themeIcon.$1 : Icons.lock),
                  color: isDefeated ? Colors.green : (isUnlocked ? themeIcon.$2 : Colors.grey),
                ),
                title: Text(
                  tr("Patro $targetFloor: ${bossInfo['name']}", "Floor $targetFloor: ${bossInfo['name']}"),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isDefeated ? TextDecoration.lineThrough : null,
                    color: isDefeated ? Colors.grey : Colors.white,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDefeated
                          ? tr("Poraženo v ${state.currentDifficultyKey}${state.activeCurse == CurseOfFate.none ? '' : ' + ${state.curseNameFor(state.activeCurse)}'} | Odměna vyzvednuta", "Defeated on ${state.currentDifficultyKey}${state.activeCurse == CurseOfFate.none ? '' : ' + ${state.curseNameFor(state.activeCurse)}'} | Reward claimed")
                          : (isUnlocked ? tr("Schopnost: ${bossInfo['ability']}\nOdměna: +$rewardDust ✨, +$rewardCrystals 💎", "Ability: ${bossInfo['ability']}\nReward: +$rewardDust ✨, +$rewardCrystals 💎") : tr("Zamčeno (Dosáhni patra $targetFloor)", "Locked (Reach floor $targetFloor)")),
                      style: TextStyle(color: isDefeated ? Colors.greenAccent.shade200 : Colors.grey),
                    ),
                    if (isUnlocked && (bossInfo['lore'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bossInfo['lore']!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Color(0xFF8A7A5C)),
                      ),
                    ],
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDefeated || !isUnlocked ? Colors.grey.shade800 : const Color(0xFF8B0000),
                  ),
                  onPressed: isDefeated || !isUnlocked ? null : () => state.enterLair(targetFloor),
                  child: Text(isDefeated ? tr("Splněno", "Completed") : tr("Vyzvat", "Challenge")),
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}

/// Endless Scale — capstone farm mód po dokončení Pekla (Ascension IV). Opakovatelný boj proti
/// Soul Demonovi, který je při každém spawnu o 10 % silnější (HP/Armor) než ten předchozí.
class EndlessScaleScreen extends StatelessWidget {
  const EndlessScaleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      if (!state.endlessScaleUnlocked) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(tr("Endless Scale je zamčený.", "Endless Scale is locked."), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(tr("Odemyká se poražením bosse na patře 100 v Peklu (poslední ze 4 Ascension stupňů).", "Unlocks by defeating the floor-100 boss in Hell (the last of the 4 Ascension stages)."),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ]),
        );
      }
      if (!state.isInEndlessScale) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.whatshot, color: Colors.deepPurpleAccent, size: 48),
            const SizedBox(height: 12),
            const Text("SOUL DEMON", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
            const SizedBox(height: 8),
            Text(tr("Dosud poraženo: ${state.soulDemonKillCount}×", "Defeated so far: ${state.soulDemonKillCount}×"), style: const TextStyle(color: Colors.grey)),
            Text("👻 Soul Fragment: ${state.soulFragments}", style: const TextStyle(color: Colors.amberAccent)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A0E6E), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              onPressed: state.enterEndlessScale,
              icon: const Icon(Icons.whatshot),
              label: Text(tr("Vyzvat Soul Demona", "Challenge the Soul Demon")),
            ),
          ]),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("ENDLESS SCALE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF1E88E5), width: 1), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.heroName.isNotEmpty ? state.heroName : tr("Hrdina", "Hero"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                          const Divider(),
                          BarWidget(value: state.hp.toDouble(), max: state.maxHp.toDouble(), color: Colors.green, label: "HP"),
                          const SizedBox(height: 6),
                          Text("P.Atk: ${formatCompactNumber(state.physAtk)}", style: const TextStyle(fontSize: 12)),
                          Text("M.Atk: ${formatCompactNumber(state.magAtk)}", style: const TextStyle(fontSize: 12)),
                          Text("Armor: ${formatCompactNumber(state.armor)}", style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(tr("Buffy / Debuffy:", "Buffs / Debuffs:"), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          StatusEffectsListWidget(effects: state.heroEffects),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.deepPurpleAccent, width: 1), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Soul Demon (kill #${state.soulDemonKillCount})", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                          const SizedBox(height: 4),
                          Text(tr("Démonův hněv: +1 % dmg/kolo", "Demon's Wrath: +1% dmg/round"), style: const TextStyle(fontSize: 10, color: Colors.amberAccent)),
                          const SizedBox(height: 8),
                          BarWidget(value: state.soulDemonHp.toDouble(), max: state.soulDemonMaxHp.toDouble(), color: Colors.deepPurple, label: "HP"),
                          const SizedBox(height: 6),
                          Text(tr("Atk: ${formatCompactNumber(state.soulDemonAtk)} | Armor: ${formatCompactNumber(state.soulDemonArmor)}", "Atk: ${formatCompactNumber(state.soulDemonAtk)} | Armor: ${formatCompactNumber(state.soulDemonArmor)}"), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(tr("Kolo: ${state.soulDemonRoundCount}", "Round: ${state.soulDemonRoundCount}"), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(tr("Buffy / Debuffy:", "Buffs / Debuffs:"), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          StatusEffectsListWidget(effects: state.enemyEffects),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
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
                  onPressed: () => state.fightSoulDemon(state.classIsMagicAttack),
                ),
                tier1: state.hasAdvancedClass
                    ? SpellIconButton(
                        visual: spellVisualTier1(state.heroClass),
                        costLabel: '1×, ${state.ability1Cost} ${state.resourceName}',
                        disabled: state.endlessScaleAbilityUsed || state.currentResourceValue < state.ability1Cost,
                        overlayText: state.endlessScaleAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: state.useEndlessScaleActiveAbility,
                      )
                    : lockedAbilitySlot(state, spellVisualTier1(state.heroClass), 15),
                tier2: state.hasUltimateClass
                    ? SpellIconButton(
                        visual: spellVisualTier2(state.heroClass),
                        costLabel: '1×, ${state.ability2Cost} ${state.resourceName}',
                        disabled: state.endlessScaleSecondAbilityUsed || state.currentResourceValue < state.ability2Cost,
                        overlayText: state.endlessScaleSecondAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: state.useEndlessScaleSecondAbility,
                      )
                    : lockedAbilitySlot(state, spellVisualTier2(state.heroClass), 40),
                tier3: state.hasGodClass
                    ? SpellIconButton(
                        visual: spellVisualTier3(state.heroClass),
                        costLabel: '1×, ${state.ability3Cost} ${state.resourceName}',
                        disabled: state.endlessScaleThirdAbilityUsed || state.currentResourceValue < state.ability3Cost,
                        overlayText: state.endlessScaleThirdAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: state.useEndlessScaleThirdAbility,
                      )
                    : lockedAbilitySlot(state, spellVisualTier3(state.heroClass), 75),
                tier4: state.hasRank100Class
                    ? SpellIconButton(
                        visual: spellVisualTier4(state.heroClass, state.rank100Choice),
                        costLabel: '1×, ${state.ability4Cost} ${state.resourceName}',
                        disabled: state.endlessScaleFourthAbilityUsed || state.currentResourceValue < state.ability4Cost,
                        overlayText: state.endlessScaleFourthAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: state.useEndlessScaleFourthAbility,
                      )
                    : lockedTier4Slot(state),
                // Endless Scale zatím nemá vlastní Relic spell backend - slot se zobrazuje
                // konzistentně s ostatními obrazovkami, ale natrvalo uzamčený.
                relic: SpellIconButton(
                  visual: SpellVisual('Relic: ${state.currentSpecRelic.spell}', state.currentSpecRelic.icon, state.currentSpecRelic.color),
                  disabled: true,
                  costLabel: tr('Nedostupné v Endless Scale', 'Unavailable in Endless Scale'),
                  onPressed: null,
                ),
                healPotion: ConsumableIconButton(
                  icon: Icons.medical_services, color: Colors.greenAccent, count: healingPotionsCount,
                  tooltip: tr('Léčivý lektvar (cooldown 1 kolo)', 'Healing Potion (1-round cooldown)'),
                  overlayText: state.healPotionCooldown > 0 ? '${state.healPotionCooldown}' : null,
                  onPressed: (healingPotionsCount > 0 && state.healPotionCooldown <= 0) ? () => state.useItemByName("Léčivý lektvar") : null,
                ),
                vampirePotion: ConsumableIconButton(
                  icon: Icons.water_drop, color: Colors.purpleAccent, count: vampirePotionsCount,
                  tooltip: tr('Upíří lektvar', 'Vampiric Potion'),
                  onPressed: vampirePotionsCount > 0 ? () => state.useItemByName("Upíří Lektvar") : null,
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0E0E)),
                    onPressed: () => state.fightSoulDemon(false),
                    child: Text(tr("⚔ Fyzický útok", "⚔ Physical attack")),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                    onPressed: () => state.fightSoulDemon(true),
                    child: Text(tr("✨ Magický útok", "✨ Magic attack")),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class WorldBossScreen extends StatelessWidget {
  const WorldBossScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, s, _) {
      if (!s.isInWorldBoss) {
        return WorldBossBackdrop(
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FantasyPanel(
              title: tr('WORLD BOSS', 'WORLD BOSS'),
              titleIcon: Icons.public,
              accent: const Color(0xFFFF5A36),
              child: Column(children: [
                Text(tr('Denní boss z Lair', 'Daily boss from the Lair'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(tr('Každý den se vybere jeden boss z Lair poolu. Má 100× HP a upravený útok. Po ${GameState.worldBossEnrageThreshold}. kole se rozzuří (Enrage) a dává čím dál víc damage - prohra tě jen vyžene z boje, můžeš to hned zkusit znovu.', 'Each day one boss is picked from the Lair pool. It has 100× HP and an adjusted attack. After round ${GameState.worldBossEnrageThreshold} it enrages and deals increasingly more damage - a loss only kicks you out of the fight, you can try again right away.')),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: s.worldBossAvailable ? s.enterWorldBoss : null,
                  child: Text(s.worldBossAvailable ? tr('VYZVAT WORLD BOSSE', 'CHALLENGE WORLD BOSS') : tr('DALŠÍ POKUS ZÍTRA', 'NEXT ATTEMPT TOMORROW')),
                ),
                const SizedBox(height: 8),
                Text(tr('Poraženo: ${s.worldBossKills} • Odměna: 10 Amulet XP, 1 Runový kámen, 3 Esence, 1000 zlata', 'Defeated: ${s.worldBossKills} • Reward: 10 Amulet XP, 1 Rune Stone, 3 Essence, 1000 gold'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
          ],
          ),
        );
      }
      return WorldBossBackdrop(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(s.worldBossName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF5A36))),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF1E88E5), width: 1), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.heroName.isNotEmpty ? s.heroName : tr("Hrdina", "Hero"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                          const Divider(),
                          BarWidget(value: s.hp.toDouble(), max: s.maxHp.toDouble(), color: Colors.green, label: "HP"),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Visibility(
                              visible: s.bonusShield > 0,
                              maintainSize: true, maintainAnimation: true, maintainState: true,
                              child: BarWidget(value: s.bonusShield.toDouble(), max: max(1, s.bonusShield).toDouble(), color: const Color(0xFF1E88E5), label: tr("Štít", "Shield")),
                            ),
                          ),
                          const SizedBox(height: 4),
                          BarWidget(value: s.currentResourceValue.toDouble(), max: max(1, s.maxResourceValue).toDouble(), color: s.resourceColor, label: s.resourceName),
                          const SizedBox(height: 6),
                          Text("P.Atk: ${formatCompactNumber(s.physAtk)}", style: const TextStyle(fontSize: 12)),
                          Text("M.Atk: ${formatCompactNumber(s.magAtk)}", style: const TextStyle(fontSize: 12)),
                          Text("Armor: ${formatCompactNumber(s.armor)}", style: const TextStyle(fontSize: 12)),
                          Text(tr("Crit: ${(s.critChance * 100).toStringAsFixed(1)}% | Úhyb: ${(s.dodgeChance * 100).toStringAsFixed(1)}% | Blok: ${(s.blockChance * 100).toStringAsFixed(1)}%", "Crit: ${(s.critChance * 100).toStringAsFixed(1)}% | Dodge: ${(s.dodgeChance * 100).toStringAsFixed(1)}% | Block: ${(s.blockChance * 100).toStringAsFixed(1)}%"), style: const TextStyle(fontSize: 11, color: Colors.tealAccent)),
                          const SizedBox(height: 8),
                          Text(tr("Buffy / Debuffy:", "Buffs / Debuffs:"), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          StatusEffectsListWidget(effects: s.heroEffects),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFFF5A36), width: 1), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.worldBossName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF5A36))),
                          const SizedBox(height: 4),
                          Text(tr("Schopnost: ${s.worldBossAbility}", "Ability: ${s.worldBossAbility}"), style: const TextStyle(fontSize: 10, color: Colors.amberAccent)),
                          const SizedBox(height: 8),
                          BarWidget(value: s.worldBossHp.toDouble(), max: s.worldBossMaxHp.toDouble(), color: Colors.deepOrange, label: tr("HP Bosse", "Boss HP")),
                          const SizedBox(height: 6),
                          Text(tr("Atk: ${formatCompactNumber(s.worldBossAtk)} | Def: ${formatCompactNumber(s.worldBossDef)}", "Atk: ${formatCompactNumber(s.worldBossAtk)} | Def: ${formatCompactNumber(s.worldBossDef)}"), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(tr("Buffy / Debuffy:", "Buffs / Debuffs:"), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          StatusEffectsListWidget(effects: s.enemyEffects),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CombatLogSection(state: s, message: s.message, type: classifyCombatMessage(s.message)),
            const SizedBox(height: 10),
            if (classPassiveBar(s) != null) ...[
              classPassiveBar(s)!,
              const SizedBox(height: 8),
            ],
            Builder(builder: (context) {
              final healingPotionsCount = s.consumables.where((i) => i.name == "Léčivý lektvar").fold<int>(0, (sum, i) => sum + i.stackCount);
              final vampirePotionsCount = s.consumables.where((i) => i.name == "Upíří Lektvar").fold<int>(0, (sum, i) => sum + i.stackCount);
              return combatActionGrid(
                basicAttack: SpellIconButton(
                  visual: basicAttackVisual(s), size: 62,
                  costLabel: tr('Základní útok', 'Basic Attack'),
                  onPressed: s.fightWorldBoss,
                ),
                tier1: s.hasAdvancedClass
                    ? SpellIconButton(
                        visual: spellVisualTier1(s.heroClass),
                        costLabel: '1×, ${s.ability1Cost} ${s.resourceName}',
                        disabled: s.worldBossAbilityUsed || s.currentResourceValue < s.ability1Cost,
                        overlayText: s.worldBossAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: s.useWorldBossActiveAbility,
                      )
                    : lockedAbilitySlot(s, spellVisualTier1(s.heroClass), 15),
                tier2: s.hasUltimateClass
                    ? SpellIconButton(
                        visual: spellVisualTier2(s.heroClass),
                        costLabel: '1×, ${s.ability2Cost} ${s.resourceName}',
                        disabled: s.worldBossSecondAbilityUsed || s.currentResourceValue < s.ability2Cost,
                        overlayText: s.worldBossSecondAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: s.useWorldBossSecondAbility,
                      )
                    : lockedAbilitySlot(s, spellVisualTier2(s.heroClass), 40),
                tier3: s.hasGodClass
                    ? SpellIconButton(
                        visual: spellVisualTier3(s.heroClass),
                        costLabel: '1×, ${s.ability3Cost} ${s.resourceName}',
                        disabled: s.worldBossThirdAbilityUsed || s.currentResourceValue < s.ability3Cost,
                        overlayText: s.worldBossThirdAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: s.useWorldBossThirdAbility,
                      )
                    : lockedAbilitySlot(s, spellVisualTier3(s.heroClass), 75),
                tier4: s.hasRank100Class
                    ? SpellIconButton(
                        visual: spellVisualTier4(s.heroClass, s.rank100Choice),
                        costLabel: '1×, ${s.ability4Cost} ${s.resourceName}',
                        disabled: s.worldBossFourthAbilityUsed || s.currentResourceValue < s.ability4Cost,
                        overlayText: s.worldBossFourthAbilityUsed ? tr('Použito', 'Used') : null,
                        onPressed: s.useWorldBossFourthAbility,
                      )
                    : lockedTier4Slot(s),
                relic: s.currentSpecRelicUnlocked
                    ? SpellIconButton(
                        visual: SpellVisual('Relic: ${s.currentSpecRelic.spell}', s.currentSpecRelic.icon, s.currentSpecRelic.color),
                        costLabel: tr('Relic Lv ${s.currentSpecRelicLevel}', 'Relic Lv ${s.currentSpecRelicLevel}'),
                        disabled: !s.isSpecRelicEquipped || s.specRelicUsedWorldBoss,
                        overlayText: !s.isSpecRelicEquipped ? tr('Nenasazen', 'Not equipped') : (s.specRelicUsedWorldBoss ? tr('Použito', 'Used') : null),
                        onPressed: s.useSpecRelicWorldBossSpell,
                      )
                    : lockedRelicSlot(),
                healPotion: ConsumableIconButton(
                  icon: Icons.medical_services, color: Colors.greenAccent, count: healingPotionsCount,
                  tooltip: tr('Léčivý lektvar (cooldown 1 kolo)', 'Healing Potion (1-round cooldown)'),
                  overlayText: s.healPotionCooldown > 0 ? '${s.healPotionCooldown}' : null,
                  onPressed: (healingPotionsCount > 0 && s.healPotionCooldown <= 0) ? () => s.useItemByName("Léčivý lektvar") : null,
                ),
                vampirePotion: ConsumableIconButton(
                  icon: Icons.water_drop, color: Colors.purpleAccent, count: vampirePotionsCount,
                  tooltip: tr('Upíří lektvar', 'Vampiric Potion'),
                  onPressed: vampirePotionsCount > 0 ? () => s.useItemByName("Upíří Lektvar") : null,
                ),
              );
            }),
            const SizedBox(height: 10),
            if (s.worldBossRoundCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: s.worldBossEnraged ? const Color(0xFF4A0000) : const Color(0xFF241800),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: s.worldBossEnraged ? Colors.redAccent : const Color(0xFFC69214)),
                ),
                child: Text(
                  s.worldBossEnraged
                      ? tr('🔥 ENRAGE! Kolo ${s.worldBossRoundCount} • Boss dává +${((s.worldBossEnrageDmgMult - 1) * 100).round()}% dmg', '🔥 ENRAGE! Round ${s.worldBossRoundCount} • Boss deals +${((s.worldBossEnrageDmgMult - 1) * 100).round()}% dmg')
                      : tr('Kolo ${s.worldBossRoundCount} • Enrage za ${GameState.worldBossEnrageThreshold - s.worldBossRoundCount} kol', 'Round ${s.worldBossRoundCount} • Enrage in ${GameState.worldBossEnrageThreshold - s.worldBossRoundCount} rounds'),
                  style: TextStyle(color: s.worldBossEnraged ? Colors.redAccent : const Color(0xFFC69214), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            Text(tr('Poraženo: ${s.worldBossKills} • Odměna: 10 Amulet XP, 1 Runový kámen, 3 Esence, 1000 zlata', 'Defeated: ${s.worldBossKills} • Reward: 10 Amulet XP, 1 Rune Stone, 3 Essence, 1000 gold'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        ),
      );
    });
  }
}

// ===== TRHLINOVÁ NESTABILITA - VIZUÁLNÍ EFEKTY =====
// Místo obyčejného LinearProgressIndicator je nestabilita "trhlina v realitě" - zubatá,
// svítící prasklina, která se s rostoucí nestabilitou prodlužuje, houstne a barevně přechází
// z fialové (klid) přes oranžovou do červené (blízko zhroucení), s jemným "blikáním" napětí.

class _RiftTearPainter extends CustomPainter {
  final double progress; // 0..1
  final double flicker; // 0..1, animované blikání
  _RiftTearPainter({required this.progress, required this.flicker});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF120A1E));

    final color = Color.lerp(const Color(0xFF8B5CF6), const Color(0xFFFF3D3D), progress.clamp(0.0, 1.0))!;

    // Zubatá "trhlina" - pevně seedovaný zigzag (ne náhodný každý frame, jinak by to jen "cukalo"),
    // vykreslená jen do šířky odpovídající progressu a oříznutá do kulatých rohů baru.
    canvas.save();
    canvas.clipRRect(rrect);
    final path = Path();
    const segments = 16;
    final segW = size.width / segments;
    final rnd = Random(1337);
    path.moveTo(0, size.height / 2 + (rnd.nextDouble() - 0.5) * size.height * 0.3);
    for (int i = 1; i <= segments; i++) {
      final jag = (rnd.nextDouble() - 0.5) * size.height * 0.85;
      path.lineTo(segW * i, size.height / 2 + jag);
    }
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.55 + flicker * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 + flicker * 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.55 + flicker * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.restore();
    canvas.drawRRect(rrect, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = color.withOpacity(.6));
  }

  @override
  bool shouldRepaint(covariant _RiftTearPainter old) => old.progress != progress || old.flicker != flicker;
}

class RiftTearBar extends StatefulWidget {
  final double progress;
  final double height;
  const RiftTearBar({super.key, required this.progress, this.height = 10});

  @override
  State<RiftTearBar> createState() => _RiftTearBarState();
}

class _RiftTearBarState extends State<RiftTearBar> with SingleTickerProviderStateMixin {
  late final AnimationController _flicker;
  @override
  void initState() {
    super.initState();
    _flicker = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flicker,
      builder: (context, _) => SizedBox(
        width: double.infinity,
        height: widget.height,
        child: CustomPaint(painter: _RiftTearPainter(progress: widget.progress, flicker: _flicker.value)),
      ),
    );
  }
}

// Dramatický full-panel "shatter" efekt při zhroucení Trhliny (riftCollapseFlashSeq) - bílo-rudý
// záblesk, prasklinové paprsky z centra a mikro-shake, doznívající přes ~650ms. Poslouchá state
// přímo (stejný vzor jako ImpactFlashCard), ne přes Provider rebuild, ať eventy nezmizí dřív,
// než widget stihne zachytit rebuild.
class RiftCollapseFlash extends StatefulWidget {
  final GameState state;
  final Widget child;
  const RiftCollapseFlash({super.key, required this.state, required this.child});

  @override
  State<RiftCollapseFlash> createState() => _RiftCollapseFlashState();
}

class _RiftCollapseFlashState extends State<RiftCollapseFlash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lastSeenSeq = -1;

  @override
  void initState() {
    super.initState();
    _lastSeenSeq = widget.state.riftCollapseFlashSeq;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (widget.state.riftCollapseFlashSeq != _lastSeenSeq) {
      _lastSeenSeq = widget.state.riftCollapseFlashSeq;
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0 = právě teď, 1 = doznělo
        final fade = (1 - t).clamp(0.0, 1.0);
        final shake = fade > 0 ? sin(t * pi * 10) * 5 * fade : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Stack(children: [
            child!,
            if (fade > 0.01)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _RiftShatterPainter(fade: fade)),
                ),
              ),
          ]),
        );
      },
      child: widget.child,
    );
  }
}

class _RiftShatterPainter extends CustomPainter {
  final double fade; // 1 = plná intenzita, 0 = zmizelo
  _RiftShatterPainter({required this.fade});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Celoplošný bílo-rudý záblesk.
    canvas.drawRect(Offset.zero & size, Paint()..color = Color.lerp(const Color(0xFFFF3D3D), Colors.white, 0.3)!.withOpacity(fade * 0.35));
    // Prasklinové paprsky vystřelující z centra ven, seedované, ať to nemrká náhodně.
    final rnd = Random(7);
    for (int i = 0; i < 10; i++) {
      final angle = rnd.nextDouble() * 2 * pi;
      final len = (size.shortestSide * 0.5) * (0.5 + rnd.nextDouble() * 0.5) * fade;
      final path = Path()..moveTo(center.dx, center.dy);
      double x = center.dx, y = center.dy;
      final segCount = 4;
      for (int s = 1; s <= segCount; s++) {
        final segLen = len / segCount;
        final jitter = (rnd.nextDouble() - 0.5) * 0.6;
        x += cos(angle + jitter) * segLen;
        y += sin(angle + jitter) * segLen;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(fade * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RiftShatterPainter old) => old.fade != fade;
}

class RiftScreen extends StatefulWidget {
  const RiftScreen({super.key});
  @override
  State<RiftScreen> createState() => _RiftScreenState();
}

class _RiftScreenState extends State<RiftScreen> {
  @override
  void initState() {
    super.initState();
    RewardedAdService.instance.preload();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      if (state.riftChestPending) {
        return RiftBackdrop(
          child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedTreasureChest(
                title: tr('Truhla Poklad-skřeta', 'Treasure Goblin Chest'),
                subtitle: tr('Ťukni na truhlu pro otevření a vyzvednutí kořisti.', 'Tap the chest to open it and collect the loot.'),
                accent: const Color(0xFFFFD700),
                onOpen: () => state.openRiftChest(),
              ),
            ),
          ),
          ),
        );
      }
      if (state.riftChestLoot.isNotEmpty) {
        return RiftBackdrop(
          child: SingleChildScrollView(
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
                for (int i = 0; i < state.riftChestLoot.length; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 350 + i * 120),
                    curve: Curves.easeOut,
                    builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child)),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFD700).withOpacity(.35))),
                      child: Text(state.riftChestLoot[i], style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => state.dismissRiftChestLoot(),
                  child: Text(tr('Pokračovat', 'Continue')),
                ),
              ],
            ),
          ),
          ),
          ),
        );
      }
      if (state.isMerchantEncounter) {
        return RiftBackdrop(child: MerchantEncounterView());
      }
      if (state.isInRift) {
        return RiftBackdrop(
          child: RiftCollapseFlash(
          state: state,
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
          FantasyPanel(title:tr('DENNÍ RIFT MUTÁTOR', 'DAILY RIFT MUTATOR'),titleIcon:Icons.storm,accent:Colors.deepPurpleAccent,child:ListTile(leading:const Icon(Icons.storm,color:Colors.deepPurpleAccent),title:Text(state.currentRiftMutator.displayName),subtitle:Text(state.currentRiftMutator.description))),const SizedBox(height:12),
              Text(
                state.isTreasureGoblinFight ? tr("💰 VZÁCNÝ ENCOUNTER!", "💰 RARE ENCOUNTER!") : tr("TRHLINA OSUDU (Tier ${state.currentRiftTier})", "RIFT OF FATE (Tier ${state.currentRiftTier})"),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: state.isTreasureGoblinFight ? const Color(0xFFFFD700) : const Color(0xFF8B5CF6)),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF1E88E5), width: 1), borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.heroName.isNotEmpty ? state.heroName : tr("Hrdina", "Hero"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                            const Divider(),
                            BarWidget(value: state.hp.toDouble(), max: state.maxHp.toDouble(), color: Colors.green, label: "HP"),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Visibility(
                                visible: state.bonusShield > 0,
                                maintainSize: true, maintainAnimation: true, maintainState: true,
                                child: BarWidget(value: state.bonusShield.toDouble(), max: max(1, state.bonusShield).toDouble(), color: const Color(0xFF1E88E5), label: tr("Štít", "Shield")),
                              ),
                            ),
                            const SizedBox(height: 4),
                            BarWidget(value: state.currentResourceValue.toDouble(), max: max(1, state.maxResourceValue).toDouble(), color: state.resourceColor, label: state.resourceName),
                            const SizedBox(height: 6),
                            Text(tr("P.Atk: ${formatCompactNumber(state.physAtk)}  M.Atk: ${formatCompactNumber(state.magAtk)}", "P.Atk: ${formatCompactNumber(state.physAtk)}  M.Atk: ${formatCompactNumber(state.magAtk)}"), style: const TextStyle(fontSize: 12)),
                            Text(tr("Crit: ${(state.critChance * 100).toStringAsFixed(1)}% | Úhyb: ${(state.dodgeChance * 100).toStringAsFixed(1)}% | Blok: ${(state.blockChance * 100).toStringAsFixed(1)}%", "Crit: ${(state.critChance * 100).toStringAsFixed(1)}% | Dodge: ${(state.dodgeChance * 100).toStringAsFixed(1)}% | Block: ${(state.blockChance * 100).toStringAsFixed(1)}%"), style: const TextStyle(fontSize: 11, color: Colors.tealAccent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(side: BorderSide(color: state.isTreasureGoblinFight ? const Color(0xFFFFD700) : const Color(0xFF8B5CF6), width: state.isTreasureGoblinFight ? 2 : 1), borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isTreasureGoblinFight ? tr("💰 Poklad-skřet", "💰 Treasure Goblin") : tr("Strážce Trhliny", "Rift Guardian"),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: state.isTreasureGoblinFight ? const Color(0xFFFFD700) : const Color(0xFF8B5CF6)),
                            ),
                            const SizedBox(height: 8),
                            BarWidget(value: state.currentRiftGuardianHp.toDouble(), max: state.currentRiftGuardianMaxHp.toDouble(), color: state.isTreasureGoblinFight ? const Color(0xFFFFD700) : const Color(0xFF8B5CF6), label: state.isTreasureGoblinFight ? tr("HP Skřeta", "Goblin HP") : tr("HP Strážce", "Guardian HP")),
                            const SizedBox(height: 6),
                            Text(tr("Atk: ${formatCompactNumber(state.currentRiftGuardianAtk)} | Def: ${formatCompactNumber(state.currentRiftGuardianDef)}", "Atk: ${formatCompactNumber(state.currentRiftGuardianAtk)} | Def: ${formatCompactNumber(state.currentRiftGuardianDef)}"), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            if (state.isTreasureGoblinFight) ...[
                              const SizedBox(height: 4),
                              Text(tr("⏱️ Uteče za: ${state.treasureGoblinTurnsLeft} kolo/a", "⏱️ Flees in: ${state.treasureGoblinTurnsLeft} turn(s)"), style: const TextStyle(fontSize: 11, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!state.isTreasureGoblinFight) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1422),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr("🌀 Nestabilita Trhliny", "🌀 Rift Instability"), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB794F6))),
                          Text("${state.riftInstability}/100", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RiftTearBar(progress: state.riftInstability / 100, height: 10),
                      if (state.riftFragmentPending) ...[
                        const SizedBox(height: 10),
                        Text(
                          tr("Trhlina se chvěje - zvol reakci:", "The Rift trembles - choose a reaction:"),
                          style: const TextStyle(fontSize: 12, color: Color(0xFFF1E6D0), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF4FC3F7)), padding: const EdgeInsets.symmetric(vertical: 10)),
                                onPressed: state.sealRiftFragment,
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text(tr("🔒 Uzavřít", "🔒 Seal"), style: const TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(tr("-30 nestab. · 12 % dmg", "-30 instab. · 12% dmg"), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent), padding: const EdgeInsets.symmetric(vertical: 10)),
                                onPressed: state.harnessRiftFragment,
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text(tr("⚡ Využít", "⚡ Harness"), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(tr("+20 nestab. · 22 % dmg", "+20 instab. · 22% dmg"), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              CombatLogSection(state: state, message: state.message, type: classifyCombatMessage(state.message)),
              if (classPassiveBar(state) != null) ...[
                const SizedBox(height: 8),
                classPassiveBar(state)!,
              ],
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final healingPotionsCount = state.consumables.where((i) => i.name == "Léčivý lektvar").fold<int>(0, (sum, i) => sum + i.stackCount);
                final vampirePotionsCount = state.consumables.where((i) => i.name == "Upíří Lektvar").fold<int>(0, (sum, i) => sum + i.stackCount);
                return combatActionGrid(
                  basicAttack: SpellIconButton(
                    visual: basicAttackVisual(state), size: 62,
                    costLabel: tr('Základní útok', 'Basic Attack'),
                    onPressed: () => state.fightRiftGuardian(state.classIsMagicAttack),
                  ),
                  tier1: state.hasAdvancedClass
                      ? SpellIconButton(
                          visual: spellVisualTier1(state.heroClass),
                          costLabel: state.isTreasureGoblinFight ? tr('Nedostupné proti Poklad-skřetovi', 'Unavailable against the Treasure Goblin') : '1×, ${state.ability1Cost} ${state.resourceName}',
                          disabled: state.isTreasureGoblinFight || state.riftAbilityUsed || state.currentResourceValue < state.ability1Cost,
                          overlayText: state.riftAbilityUsed ? tr('Použito', 'Used') : null,
                          onPressed: state.useRiftActiveAbility,
                        )
                      : lockedAbilitySlot(state, spellVisualTier1(state.heroClass), 15),
                  tier2: state.hasUltimateClass
                      ? SpellIconButton(
                          visual: spellVisualTier2(state.heroClass),
                          costLabel: state.isTreasureGoblinFight ? tr('Nedostupné proti Poklad-skřetovi', 'Unavailable against the Treasure Goblin') : '1×, ${state.ability2Cost} ${state.resourceName}',
                          disabled: state.isTreasureGoblinFight || state.riftSecondAbilityUsed || state.currentResourceValue < state.ability2Cost,
                          overlayText: state.riftSecondAbilityUsed ? tr('Použito', 'Used') : null,
                          onPressed: state.useRiftSecondAbility,
                        )
                      : lockedAbilitySlot(state, spellVisualTier2(state.heroClass), 40),
                  tier3: state.hasGodClass
                      ? SpellIconButton(
                          visual: spellVisualTier3(state.heroClass),
                          costLabel: state.isTreasureGoblinFight ? tr('Nedostupné proti Poklad-skřetovi', 'Unavailable against the Treasure Goblin') : '1×, ${state.ability3Cost} ${state.resourceName}',
                          disabled: state.isTreasureGoblinFight || state.riftThirdAbilityUsed || state.currentResourceValue < state.ability3Cost,
                          overlayText: state.riftThirdAbilityUsed ? tr('Použito', 'Used') : null,
                          onPressed: state.useRiftThirdAbility,
                        )
                      : lockedAbilitySlot(state, spellVisualTier3(state.heroClass), 75),
                  tier4: state.hasRank100Class
                      ? SpellIconButton(
                          visual: spellVisualTier4(state.heroClass, state.rank100Choice),
                          costLabel: state.isTreasureGoblinFight ? tr('Nedostupné proti Poklad-skřetovi', 'Unavailable against the Treasure Goblin') : '1×, ${state.ability4Cost} ${state.resourceName}',
                          disabled: state.isTreasureGoblinFight || state.riftFourthAbilityUsed || state.currentResourceValue < state.ability4Cost,
                          overlayText: state.riftFourthAbilityUsed ? tr('Použito', 'Used') : null,
                          onPressed: state.useRiftFourthAbility,
                        )
                      : lockedTier4Slot(state),
                  // Trhlina zatím nemá vlastní Relic spell backend (na rozdíl od ostatních módů) -
                  // slot se zobrazuje konzistentně s ostatními obrazovkami, ale natrvalo uzamčený.
                  relic: SpellIconButton(
                    visual: SpellVisual('Relic: ${state.currentSpecRelic.spell}', state.currentSpecRelic.icon, state.currentSpecRelic.color),
                    disabled: true,
                    costLabel: tr('Nedostupné v Trhlině', 'Unavailable in the Rift'),
                    onPressed: null,
                  ),
                  healPotion: ConsumableIconButton(
                    icon: Icons.medical_services, color: Colors.greenAccent, count: healingPotionsCount,
                    tooltip: state.isTreasureGoblinFight ? tr('Nedostupné proti Poklad-skřetovi', 'Unavailable against the Treasure Goblin') : tr('Léčivý lektvar (cooldown 1 kolo)', 'Healing Potion (1-round cooldown)'),
                    overlayText: state.healPotionCooldown > 0 ? '${state.healPotionCooldown}' : null,
                    onPressed: (!state.isTreasureGoblinFight && healingPotionsCount > 0 && state.healPotionCooldown <= 0) ? () => state.useItemByName("Léčivý lektvar") : null,
                  ),
                  vampirePotion: ConsumableIconButton(
                    icon: Icons.water_drop, color: Colors.purpleAccent, count: vampirePotionsCount,
                    tooltip: state.isTreasureGoblinFight ? tr('Nedostupné proti Poklad-skřetovi', 'Unavailable against the Treasure Goblin') : tr('Upíří lektvar', 'Vampiric Potion'),
                    onPressed: (!state.isTreasureGoblinFight && vampirePotionsCount > 0) ? () => state.useItemByName("Upíří Lektvar") : null,
                  ),
                );
              }),
            ],
          ),
        ),
        ),
        );
      }
      return RiftBackdrop(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr("Trhlina Osudu", "Rift of Fate"), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
          Text(tr("Opakovatelný endless mód. Postupuj tier po tieru - rekord je permanentní, ale denně máš omezený počet pokusů.", "A repeatable endless mode. Progress tier by tier - your record is permanent, but you have a limited number of attempts per day."), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(tr("Dnešní pokusy: ${state.riftAttemptsToday}/${state.riftEffectiveDailyLimit}${state.riftBonusAttemptsToday > 0 ? ' (${state.riftBonusAttemptsToday} bonus z reklam)' : ''}", "Today's attempts: ${state.riftAttemptsToday}/${state.riftEffectiveDailyLimit}${state.riftBonusAttemptsToday > 0 ? ' (${state.riftBonusAttemptsToday} bonus from ads)' : ''}"), style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
          Text(tr("Aktuální rekord: tier ${state.riftTier}", "Current record: tier ${state.riftTier}"), style: const TextStyle(color: Colors.grey)),
          if (state.riftAttemptsToday >= state.riftEffectiveDailyLimit && state.canWatchAdForRiftAttempt) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
              icon: const Icon(Icons.play_circle_fill),
              label: Text(tr("Zhlédnout reklamu za +1 pokus (${state.riftBonusAttemptsToday}/${GameState.riftMaxBonusAdsPerDay} dnes)", "Watch ad for +1 attempt (${state.riftBonusAttemptsToday}/${GameState.riftMaxBonusAdsPerDay} today)")),
              onPressed: () {
                RewardedAdService.instance.show(onReward: () => state.grantRiftAttemptFromAd());
              },
            ),
          ],
          const SizedBox(height: 15),
          ...List.generate(state.riftTier + 5, (index) {
            int tier = index + 1;
            bool isUnlocked = tier <= state.riftTier + 1;
            bool isCleared = tier <= state.riftTier;
            int rewardGold = 30 * tier;
            int rewardDust = 40 * tier;
            return Card(
              color: isCleared ? const Color(0xFF241E2F) : const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isCleared ? const Color(0xFF8B5CF6) : (isUnlocked ? const Color(0xFFC69214) : Colors.grey.shade800), width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(
                  isCleared ? Icons.check_circle : (isUnlocked ? Icons.bolt : Icons.lock),
                  color: isCleared ? const Color(0xFF8B5CF6) : (isUnlocked ? Colors.amberAccent : Colors.grey),
                ),
                title: Text("Tier $tier", style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? Colors.white : Colors.grey)),
                subtitle: Text(
                  isUnlocked ? tr("Odměna: +$rewardGold 🪙, +$rewardDust Dust${isCleared ? ' (opakovatelné)' : ' (nový rekord!)'}", "Reward: +$rewardGold 🪙, +$rewardDust Dust${isCleared ? ' (repeatable)' : ' (new record!)'}") : tr("Zdolej nejdřív tier ${tier - 1}", "Clear tier ${tier - 1} first"),
                  style: TextStyle(color: isUnlocked ? Colors.grey : Colors.grey.shade700),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: !isUnlocked || state.riftAttemptsToday >= state.riftEffectiveDailyLimit ? Colors.grey.shade800 : const Color(0xFF8B5CF6)),
                  onPressed: (!isUnlocked || state.riftAttemptsToday >= state.riftEffectiveDailyLimit) ? null : () => state.enterRift(tier),
                  child: Text(tr("Vstoupit", "Enter")),
                ),
              ),
            );
          }),
        ],
        ),
      );
    });
  }
}

// Tutorial gate po první smrti hráče - viz GameState.mustHireFirstCompanion. Blokuje CELOU hru
// (kromě sebe sama) přes plnoobrazovkový overlay, dokud si hráč nenajme svého prvního společníka.
// Zmizí automaticky (Consumer se přebuildí), jakmile toggleCompanion() poprvé úspěšně najme.
class _FirstCompanionGateOverlay extends StatelessWidget {
  const _FirstCompanionGateOverlay();
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      return Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.88),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups, size: 64, color: FantasyColors2.arcaneViolet),
                    const SizedBox(height: 16),
                    Text(tr('Najmi si prvního společníka', 'Hire your first companion'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF1E6D0))),
                    const SizedBox(height: 10),
                    Text(
                      tr('Tvá první smrt tě naučila cenit si spojenců. Získal jsi 150 🪙 - přesně tolik, kolik stojí první společník v Družině. Než budeš pokračovat dál, musíš si ho najmout.',
                          'Your first death taught you to value allies. You gained 150 🪙 - exactly enough for your first Companion. You must hire one before continuing.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: FantasyColors2.runeMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text('${tr("Zlato", "Gold")}: ${state.gold} 🪙', style: const TextStyle(color: FantasyColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.groups),
                      label: Text(tr('Otevřít Družinu', 'Open Companions')),
                      style: ElevatedButton.styleFrom(backgroundColor: FantasyColors2.arcaneViolet, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: Text(tr('Družina', 'Companions'))),
                          body: const CompanionsScreen(),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class CompanionsScreen extends StatelessWidget {
  const CompanionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr("Sestava družiny", "Party lineup"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
          Text(tr("Společníci bojují po boku hrdiny a pasivně generují bonusy ke statistikám.", "Companions fight alongside the hero and passively generate stat bonuses."), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(tr("✨ Dust: ${state.magicDust}", "✨ Dust: ${state.magicDust}"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
          const SizedBox(height: 10),
          ...state.companions.map((c) {
            String roleDescription = "";
            if (c.role == CompanionRole.tank) {
              roleDescription = tr("Tank: Zvyšuje maximální HP hrdiny a Armor. Thorin občas postaví hradbu (absorb štít).", "Tank: Increases the hero's max HP and Armor. Thorin occasionally raises a wall (absorb shield).");
            } else if (c.role == CompanionRole.archer) {
              roleDescription = tr("Lučištník: Zvyšuje fyzický útok hrdiny (P.Atk) a Henry dává občasný lifesteal.", "Archer: Increases the hero's physical attack (P.Atk) and Henry occasionally grants lifesteal.");
            } else if (c.role == CompanionRole.healer) {
              roleDescription = tr("Léčitel: Zvyšuje magický útok hrdiny (M.Atk), zajišťuje absorpci overhealu a Rawen občas sešle léčivé kouzlo.", "Healer: Increases the hero's magic attack (M.Atk), provides overheal absorption, and Rawen occasionally casts a healing spell.");
            } else if (c.role == CompanionRole.rogue) {
              roleDescription = tr("Rogue: Zvyšuje kritickou šanci hrdiny a Laufer občas zaručí příští útok jako crit.", "Rogue: Increases the hero's crit chance and Laufer occasionally guarantees the next attack as a crit.");
            } else if (c.role == CompanionRole.guardian) {
              roleDescription = tr("Guardian: Zvyšuje šanci na blok hrdiny a Fenwick občas sešle absorb štít.", "Guardian: Increases the hero's block chance and Fenwick occasionally casts an absorb shield.");
            } else if (c.role == CompanionRole.warrior) {
              roleDescription = tr("Válečník: Zvyšuje fyzický útok hrdiny (P.Atk) a Anri každý 10. útok nabije o +10 % dmg.", "Warrior: Increases the hero's physical attack (P.Atk) and Anri charges every 10th attack for +10% dmg.");
            }
            return Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: c.isRecruited ? const Color(0xFFC69214) : Colors.transparent, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${c.name} (${c.role.name.toUpperCase()} - ${tr("Lv.", "Lv.")} ${c.level})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(roleDescription, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(tr("Cena vylepšení: ${c.level * 200} ✨", "Upgrade cost: ${c.level * 200} ✨"), style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => state.upgradeCompanion(c),
                            child: Text(tr("Zlepšit", "Upgrade")),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: c.isRecruited ? Colors.red.shade900 : Colors.green.shade900),
                            onPressed: () => state.toggleCompanion(c),
                            child: Text(
                              c.isRecruited
                                  ? tr("Odebrat", "Dismiss")
                                  : (state.everRecruitedCompanions.contains(c.name)
                                      ? tr("Povolat", "Recall")
                                      : (state.everRecruitedCompanions.isEmpty
                                          ? tr("Odemknout (Zdarma)", "Unlock (Free)")
                                          : tr("Odemknout (${150 * pow(2, state.everRecruitedCompanions.length - 1).toInt()} 🪙)", "Unlock (${150 * pow(2, state.everRecruitedCompanions.length - 1).toInt()} 🪙)"))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}

/// Jedna volba na obrazovce výběru povolání: masivní kruhová ikona (FantasyIconFrame,
/// legendary rám = pulzující glow) s jmenovkou, která "visí" na spodním okraji kruhu
/// (jmenovka se překrývá s kruhem, aby vypadala jako by z něj vycházela).
// ===== POZADÍ VÝBĚRU TŘÍDY — "Síň hrdinů" =====
// Bez skutečných obrázkových assetů (DartPad neumí bundlovat soubory ani stahovat ze sítě) - stejná
// vektorová technika jako všechny ostatní ikony ve hře (CustomPainter). Vylepšená verze: gradientové
// stínování místo plochých barev (dá sloupům skutečný pocit válcovitosti), gotický oblouk jako
// architektonický rámec kolem nadpisu, žebrování na sloupech, vlnící se praporce s erby, světelný
// paprsek shora, kamenná podlaha s odleskem, a jiskry s variabilní jasností pro hloubku.
class _ClassSelectHallPainter extends CustomPainter {
  const _ClassSelectHallPainter();

  // Sloup se skutečným pocitem válcovitosti - gradient tmavá/světlá/tmavá napříč šířkou (ne
  // plochá barva), + svislé žebrování (fluting) pro texturu, + zdobená hlavice a patka.
  void _pillar(Canvas canvas, double x, double w, double h, bool leftSide) {
    final rect = Rect.fromLTWH(x, 0, w, h);
    canvas.drawRect(
      rect,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF0D0906), Color(0xFF2E2416), Color(0xFF17120A)], stops: [0.0, 0.45, 1.0]).createShader(rect),
    );
    // Žebrování - tenké svislé linky simulující kamenné rýhy.
    final flutePaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..strokeWidth = 1.2;
    for (double fx = x + w * 0.18; fx < x + w * 0.95; fx += w * 0.16) {
      canvas.drawLine(Offset(fx, h * 0.08), Offset(fx, h * 0.97), flutePaint);
    }
    // Hlavice (capitel) a patka (base) - o něco širší než dřík sloupu.
    final capPaint = Paint()..shader = const LinearGradient(colors: [Color(0xFF3A2C16), Color(0xFF1C150A)]).createShader(Rect.fromLTWH(x - w * 0.3, 0, w * 1.6, h * 0.05));
    canvas.drawRect(Rect.fromLTWH(x - w * 0.3, h * 0.035, w * 1.6, h * 0.028), capPaint);
    canvas.drawRect(Rect.fromLTWH(x - w * 0.3, h * 0.955, w * 1.6, h * 0.03), capPaint);
  }

  // Praporec s jemným vlněním (zvlněný okraj místo rovné čáry) a malým erbovním symbolem uprostřed.
  void _banner(Canvas canvas, double x, double h, Color color, IconData emblem) {
    final bannerH = h * 0.22;
    final path = Path()
      ..moveTo(x - 15, 0)
      ..lineTo(x + 15, 0)
      ..lineTo(x + 15, bannerH * 0.75)
      ..quadraticBezierTo(x + 8, bannerH * 0.85, x + 9, bannerH)
      ..lineTo(x, bannerH * 0.88)
      ..lineTo(x - 9, bannerH)
      ..quadraticBezierTo(x - 8, bannerH * 0.85, x - 15, bannerH * 0.75)
      ..close();
    canvas.drawPath(
      path,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(0.5), color.withOpacity(0.22)]).createShader(Rect.fromLTWH(x - 15, 0, 30, bannerH)),
    );
    // Zlatý lem praporce
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = const Color(0xFFC69214).withOpacity(0.4));
    // Drobný erbovní symbol na praporci
    final tp = TextPainter(
      text: TextSpan(text: String.fromCharCode(emblem.codePoint), style: TextStyle(fontSize: 14, fontFamily: emblem.fontFamily, color: const Color(0xFFF0DFC0).withOpacity(0.55))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, bannerH * 0.28));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Vinětové pozadí - stejný jazyk jako Main Menu.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [Color(0xFF2A2010), FantasyColors.abyss]).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // Kamenná podlaha dole - jemný přechod, dá scéně "podlahu" místo nekonečné tmy.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.75, w, h * 0.25),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, const Color(0xFF1A140C).withOpacity(0.6)]).createShader(Rect.fromLTWH(0, h * 0.75, w, h * 0.25)),
    );
    // Světelný paprsek shora (jako okno/světlík) - jemný, protínající scénu diagonálně.
    final beamPath = Path()
      ..moveTo(w * 0.42, 0)
      ..lineTo(w * 0.58, 0)
      ..lineTo(w * 0.72, h * 0.9)
      ..lineTo(w * 0.28, h * 0.9)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFF0DFC0).withOpacity(0.10), Colors.transparent]).createShader(Rect.fromLTWH(0, 0, w, h * 0.9)),
    );
    // Gotický oblouk - architektonický rámec kolem nadpisu, ne jen holý glow.
    final archCenter = Offset(w / 2, h * 0.16);
    final archWidth = w * 0.62;
    final archPath = Path()
      ..moveTo(archCenter.dx - archWidth / 2, h * 0.20)
      ..lineTo(archCenter.dx - archWidth / 2, h * 0.10)
      ..quadraticBezierTo(archCenter.dx - archWidth / 2, h * 0.02, archCenter.dx, h * 0.02)
      ..quadraticBezierTo(archCenter.dx + archWidth / 2, h * 0.02, archCenter.dx + archWidth / 2, h * 0.10)
      ..lineTo(archCenter.dx + archWidth / 2, h * 0.20);
    canvas.drawPath(archPath, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFFC69214).withOpacity(0.30));
    canvas.drawPath(archPath, Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = const Color(0xFFC69214).withOpacity(0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // Zlatý glow za nadpisem (uvnitř oblouku)
    canvas.drawCircle(
      archCenter, w * 0.32,
      Paint()..shader = RadialGradient(colors: [const Color(0xFFC69214).withOpacity(0.20), Colors.transparent]).createShader(Rect.fromCircle(center: archCenter, radius: w * 0.32)),
    );
    // Kamenné sloupy po stranách - teď s gradientem/texturou místo ploché barvy.
    final pillarW = (w * 0.09).clamp(20.0, 60.0);
    _pillar(canvas, 0, pillarW, h, true);
    _pillar(canvas, w - pillarW, pillarW, h, false);
    // Praporce visící ze stropu vedle sloupů, s erbovními symboly.
    _banner(canvas, pillarW * 1.8, h, const Color(0xFF8B0E0E), Icons.local_fire_department);
    _banner(canvas, w - pillarW * 1.8, h, const Color(0xFF1E4D8B), Icons.ac_unit);
    // Jiskry s variabilní velikostí i jasností - dá pozadí pocit hloubky, ne jen ploché tečky.
    // Fixní seed, ať se vzor při každém rebuildu nemění (žádné blikání).
    final rnd = Random(42);
    for (int i = 0; i < 55; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h * 0.55;
      final brightness = rnd.nextDouble();
      canvas.drawCircle(
        Offset(x, y),
        brightness * 1.6 + 0.3,
        Paint()..color = const Color(0xFFF0DFC0).withOpacity(0.15 + brightness * 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===== VÝBĚR TŘÍDY: vlastní odznak místo sdíleného "legendary" item rámu. Dřív měly VŠECHNY
// třídy identický oranžový prstenec (protože FantasyIconFrame(rarity: legendary) je jednotný
// pro všechny), takže obrazovka výběru vypadala uniformně bez ohledu na třídu. Teď má každá
// třída vlastní barvu (stejnou, jakou má její ikona v FantasyIconRegistry) - prstenec, glow
// i cedulka se jménem svítí jinak pro Rytíře Smrti (ledová modrá), Lovce (zelená), atd.
class _ClassBadge extends StatefulWidget {
  final FantasyIconType iconType;
  final Color accent;
  final double size;
  final HeroClass? heroClass; // pokud existuje portrét pro tuhle třídu (viz kClassPortraitAssets), zobrazí se místo malé ikony
  const _ClassBadge({required this.iconType, required this.accent, this.size = 104, this.heroClass});

  @override
  State<_ClassBadge> createState() => _ClassBadgeState();
}

class _ClassBadgeState extends State<_ClassBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = FantasyIconRegistry.of(widget.iconType);
    final portraitPath = widget.heroClass != null ? kClassPortraitAssets[widget.heroClass] : null;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glowT = 0.55 + 0.45 * _pulse.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [widget.accent.withOpacity(.22), const Color(0xFF141019)]),
                  border: Border.all(color: widget.accent, width: 2.4),
                  boxShadow: [
                    BoxShadow(color: widget.accent.withOpacity(.55 * glowT), blurRadius: 16, spreadRadius: 1),
                    BoxShadow(color: widget.accent.withOpacity(.25 * glowT), blurRadius: 30, spreadRadius: 4),
                  ],
                ),
              ),
              if (portraitPath != null)
                ClipOval(
                  child: SizedBox(
                    width: widget.size - 6,
                    height: widget.size - 6,
                    child: LivingPortrait(assetPath: portraitPath, accent: widget.accent, mode: PortraitLifeMode.full),
                  ),
                )
              else
                SizedBox(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  child: asset.svgAssetPath != null
                      ? SvgPicture.asset(asset.svgAssetPath!)
                      : CustomPaint(painter: asset.proceduralPainter(widget.accent)),
                ),
              // Rohové diamanty místo dřívějších plochých "+" značek - stejný jazyk jako
              // ostatní zdobené panely (viz showFantasyInfoDialog).
              for (final a in const [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
                Align(
                  alignment: a,
                  child: Icon(Icons.diamond, size: 9, color: widget.accent.withOpacity(.85)),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ===== VÝBĚR TŘÍDY v2 - vodorovný karusel místo mřížky. Každá třída má krátký popis (co ta
// třída je/jak hraje), a po potvrzení výběru obrazovka zčerná a odehraje se krátký úryvek
// příběhu ("probudil ses na podlaze věže..."), než se skutečně zavolá state.selectClass a
// přejde se do boje. =====
class _ClassOption {
  final FantasyIconType iconType;
  final HeroClass heroClass;
  final String name;
  final String description;
  const _ClassOption({required this.iconType, required this.heroClass, required this.name, required this.description});
}

enum _ClassSelectPhase { browsing, fadingOut, story1, story2 }

class _ClassSelectionScreen extends StatefulWidget {
  final GameState state;
  final Widget? bossGuide;
  const _ClassSelectionScreen({required this.state, this.bossGuide});

  @override
  State<_ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<_ClassSelectionScreen> {
  late final PageController _pageController;
  double _page = 0;
  _ClassSelectPhase _phase = _ClassSelectPhase.browsing;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.6);
    _pageController.addListener(() {
      setState(() => _page = _pageController.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_ClassOption> _options() => [
        _ClassOption(iconType: FantasyIconType.classWarrior, heroClass: HeroClass.warrior, name: tr("Válečník", "Warrior"), description: tr("Odolný bojovník v první linii - drtivé fyzické útoky nablízko a dost HP, na které se dá spolehnout.", "A tough frontline fighter - crushing melee attacks and enough HP to lean on.")),
        _ClassOption(iconType: FantasyIconType.classHunter, heroClass: HeroClass.hunter, name: tr("Lovec", "Hunter"), description: tr("Stopař s lukem - stabilní poškození na dálku a pasti, co oslabí nepřítele dřív, než se přiblíží.", "A tracker with a bow - steady ranged damage and traps that weaken foes before they close in.")),
        _ClassOption(iconType: FantasyIconType.classPriest, heroClass: HeroClass.healer, name: tr("Léčitel", "Healer"), description: tr("Podpora s léčivou magií - drží tě naživu v dlouhých soubojích, kde by jiná třída padla.", "Support with healing magic - keeps you alive through long fights that would drop other classes.")),
        _ClassOption(iconType: FantasyIconType.classDeathKnight, heroClass: HeroClass.deathknight, name: tr("Rytíř Smrti", "Death Knight"), description: tr("Temný bojovník hybridního poškození - prokletí, krádež života a útoky, co bolí na dvou frontách zároveň.", "A dark hybrid-damage warrior - curses, life drain and attacks that hurt on two fronts at once.")),
        _ClassOption(iconType: FantasyIconType.classMage, heroClass: HeroClass.mage, name: tr("Mág", "Mage"), description: tr("Křehký, ale ničivý - magické poškození na dálku ve velkých dávkách, pokud přežiješ dost dlouho na to ho seslat.", "Fragile but devastating - big bursts of ranged magic damage, if you survive long enough to cast it.")),
        _ClassOption(iconType: FantasyIconType.classDuelist, heroClass: HeroClass.duelist, name: tr("Šermíř", "Duelist"), description: tr("Rychlá fyzická combo - vysoký crit a riskantní styl boje, kde rychlost rozhoduje víc než síla jednoho úderu.", "Fast physical combos - high crit and a risky style where speed matters more than any single hit.")),
        _ClassOption(iconType: FantasyIconType.classMonk, heroClass: HeroClass.monk, name: tr("Mnich", "Monk"), description: tr("Hybridní bojovník na blízko - rovnováha mezi útokem a přežitím, bez extrémů na kteroukoliv stranu.", "A hybrid melee fighter - balance between offense and survival, without leaning too hard either way.")),
        _ClassOption(iconType: FantasyIconType.classDruid, heroClass: HeroClass.druid, name: tr("Druid", "Druid"), description: tr("Přírodní magie a proměny - flexibilní třída, co se dokáže přizpůsobit mezi útokem a podporou.", "Nature magic and shapeshifting - a flexible class that adapts between offense and support.")),
        _ClassOption(iconType: FantasyIconType.classPaladin, heroClass: HeroClass.paladin, name: tr("Paladin", "Paladin"), description: tr("Svatý ochránce - tank s vlastním léčením, co dokáže vydržet v boji sám, dlouho a bez pomoci.", "A holy protector - a tank with its own healing, able to hold the line alone for a long time.")),
        _ClassOption(iconType: FantasyIconType.classDemonHunter, heroClass: HeroClass.demonhunter, name: tr("Lovec Démonů", "Demon Hunter"), description: tr("Agresivní lovec s démonickou energií - vysoké burst poškození za cenu vlastní zranitelnosti.", "An aggressive hunter fueled by demonic energy - high burst damage at the cost of its own fragility.")),
        _ClassOption(iconType: FantasyIconType.classNecromancer, heroClass: HeroClass.necromancer, name: tr("Nekromant", "Necromancer"), description: tr("Vládce mrtvých - vyvolává poskoky a oslabuje nepřátele, místo aby bojoval čistě vlastníma rukama.", "A master of the dead - summons minions and weakens foes instead of fighting purely with its own hands.")),
      ];

  Future<void> _confirmClass(HeroClass cls) async {
    setState(() => _phase = _ClassSelectPhase.fadingOut);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _phase = _ClassSelectPhase.story1);
    await Future.delayed(const Duration(milliseconds: 4100));
    if (!mounted) return;
    setState(() => _phase = _ClassSelectPhase.story2);
    await Future.delayed(const Duration(milliseconds: 4100));
    if (!mounted) return;
    widget.state.selectClass(cls);
  }

  @override
  Widget build(BuildContext context) {
    final options = _options();
    final int centerIndex = _page.round().clamp(0, options.length - 1);
    final centerOption = options[centerIndex];
    return Stack(
      children: [
        // Skutečná ilustrace (viz konverzace o Copilot promptu "Síň Povolání") nahradila
        // dřívější procedurální _ClassSelectHallPainter - ten zůstává v souboru nepoužitý
        // (neškodí), kdyby bylo někdy potřeba fallback bez obrázku.
        Positioned.fill(child: Image.asset('assets/images/scenes/class_hall.png', fit: BoxFit.cover)),
        // Živá vrstva - přepočítané pozice podle skutečného obrázku class_hall.png (dřív odhad
        // pro procedurální _ClassSelectHallPainter): 4 pochodně na zdi + jemný prach/kadidlo
        // stoupající od run kruhu na podlaze (viz pentagram v popředí obrázku).
        Positioned.fill(
          child: _SceneLifeOverlay(
            danger: false,
            smokePoints: const [Offset(0.5, 0.76)],
            glowPoints: const [Offset(0.15, 0.44), Offset(0.85, 0.44), Offset(0.30, 0.53), Offset(0.70, 0.53)],
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                if (widget.bossGuide != null) ...[widget.bossGuide!, const SizedBox(height: 12)],
                Text(tr("Zvolte si své povolání:", "Choose your class:"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
                const SizedBox(height: 28),
            SizedBox(
              height: 210,
              child: PageView.builder(
                controller: _pageController,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final o = options[i];
                  final accent = FantasyIconRegistry.of(o.iconType).accentColor;
                  final dist = (_page - i).abs().clamp(0.0, 1.0);
                  final scale = 1.0 - dist * 0.24;
                  final opacity = 1.0 - dist * 0.55;
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: GestureDetector(
                          onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 280), curve: Curves.easeOut),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ClassBadge(iconType: o.iconType, accent: accent, size: 130, heroClass: o.heroClass),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Color.lerp(accent, Colors.black, .75)!, const Color(0xFF17110A)]),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: accent, width: 1.6),
                                  boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 8)],
                                ),
                                child: Text(o.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFF0DFC0), letterSpacing: .2)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            // Krátký popis vybrané (nejbližší středu) třídy - mění se s posunem karuselu.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Container(
                  key: ValueKey(centerIndex),
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FantasyIconRegistry.of(centerOption.iconType).accentColor.withOpacity(.5)),
                  ),
                  child: Text(
                    centerOption.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFE6DCC5), fontSize: 12.5, height: 1.35),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 260,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FantasyIconRegistry.of(centerOption.iconType).accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _confirmClass(centerOption.heroClass),
                child: Text(tr('Zvolit: ${centerOption.name}', 'Choose: ${centerOption.name}'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
          ),
        ),
        // ===== ZATMĚNÍ + PŘÍBĚH po potvrzení volby - obrazovka zčerná a odehrají se dvě krátké
        // věty, než se skutečně zavolá state.selectClass (viz _confirmClass výš). =====
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _phase == _ClassSelectPhase.browsing,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 900),
              opacity: _phase == _ClassSelectPhase.browsing ? 0.0 : 1.0,
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: _phase == _ClassSelectPhase.story1
                      ? Text(
                          tr('Probouzíš se na studené kamenné podlaze Věže Osudu. Hlava třeští, vzpomínky mlhavé.',
                              'You wake on the cold stone floor of the Tower of Fate. Your head throbs, memories hazy.'),
                          key: const ValueKey('s1'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFE8D9B0), fontSize: 17, height: 1.5, fontStyle: FontStyle.italic),
                        )
                      : _phase == _ClassSelectPhase.story2
                          ? Text(
                              tr('Vtom zaslechneš kroky blížící se ze tmy chodby - první z mnoha nepřátel, co na tebe uvnitř čekají.',
                                  'Then you hear footsteps approaching from the dark corridor - the first of many enemies waiting inside.'),
                              key: const ValueKey('s2'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFE8D9B0), fontSize: 17, height: 1.5, fontStyle: FontStyle.italic),
                            )
                          : const SizedBox.shrink(key: ValueKey('blank')),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GearScoreBadge extends StatelessWidget {final GameState state;const GearScoreBadge({super.key,required this.state});@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:const Color(0xFF33260F),border:Border.all(color:FantasyColors.gold),borderRadius:BorderRadius.circular(10)),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.military_tech,color:FantasyColors.gold,size:19),const SizedBox(width:6),Text('GEAR SCORE ${state.gearScore}',style:const TextStyle(color:FantasyColors.gold,fontWeight:FontWeight.bold))]));}
class BuildOverviewPanel extends StatelessWidget {final GameState state;const BuildOverviewPanel({super.key,required this.state});@override Widget build(BuildContext context)=>FantasyPanel(title:'MUJ BUILD',titleIcon:Icons.account_tree,accent:const Color(0xFF64B5F6),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(state.buildRoleLabel,style:const TextStyle(fontSize:18,color:Color(0xFF64B5F6),fontWeight:FontWeight.bold)),const SizedBox(height:8),for(final line in state.buildOverview)Padding(padding:const EdgeInsets.symmetric(vertical:2),child:Text(line,style:const TextStyle(color:Colors.grey)))]));}
class AdventureGuidePanel extends StatelessWidget {final GameState state;const AdventureGuidePanel({super.key,required this.state});@override Widget build(BuildContext context)=>FantasyPanel(title:'PRUVODCE DOBRODRUZSTVIM',titleIcon:Icons.menu_book,accent:const Color(0xFFFFB74D),child:Column(children:[for(final c in state.adventureGuideChapters)Card(color:(c['done'] as bool)?const Color(0xFF16351F):const Color(0xFF1E1E24),child:ListTile(leading:Icon((c['done'] as bool)?Icons.check_circle:Icons.radio_button_unchecked,color:(c['done'] as bool)?Colors.greenAccent:Colors.grey),title:Text(c['title'] as String,style:const TextStyle(color:FantasyColors.parchment,fontWeight:FontWeight.bold)),subtitle:Text('${c['progress']}\nOdmena / odemceni: ${c['reward']}',style:const TextStyle(color:Colors.grey,fontSize:12)),isThreeLine:true))]));}

class TowerScreen extends StatelessWidget {
  Widget _bossGuide(GameState s)=>FantasyPanel(title:tr('ANALÝZA BOSSE','BOSS ANALYSIS'),titleIcon:Icons.visibility,accent:Colors.redAccent,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(s.currentEnemyName,style:const TextStyle(color:FantasyColors.parchment,fontWeight:FontWeight.bold,fontSize:18)),const SizedBox(height:5),Text(s.currentEnemyAbility,style:const TextStyle(color:Colors.grey)),const Divider(),Text(tr('Silný proti: ${s.towerBossStrongAgainst}','Strong against: ${s.towerBossStrongAgainst}'),style:const TextStyle(color:Colors.redAccent)),const SizedBox(height:4),Text(tr('Doporučená odpověď: ${s.towerBossCounter}','Recommended response: ${s.towerBossCounter}'),style:const TextStyle(color:Colors.greenAccent)),const SizedBox(height:4),Text(tr('Gear Score ${s.gearScore} (100 = doporučeno pro tvé patro)','Gear Score ${s.gearScore} (100 = recommended for your floor)'),style:const TextStyle(color:Colors.grey,fontSize:12))]));
  const TowerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      if (!state.introSeen && state.heroClass == HeroClass.none) {
        return const IntroScreen();
      }
      if (state.heroClass == HeroClass.none) {
        return _ClassSelectionScreen(state: state, bossGuide: state.isBoss ? _bossGuide(state) : null);
      }
      if (state.isMerchantEncounter) {
        return const MerchantEncounterView();
      }
      int healingPotionsCount = state.consumables.where((i) => i.name == "Léčivý lektvar").fold(0, (sum, i) => sum + i.stackCount);
      int vampirePotionsCount = state.consumables.where((i) => i.name == "Upíří Lektvar").fold(0, (sum, i) => sum + i.stackCount);
      // Ability tlačítka (advanced/ultimate/god/rank100) se sestaví do jednoho seznamu a
      // vykreslí ve 2 sloupcích (viz Wrap níže) místo naskládaných full-width řádků -
      // šetří to hodně výšky na obrazovce s bojem, který má i tak dost dalšího UI pod sebou.
      final basicAttackBtn = SpellIconButton(
        visual: basicAttackVisual(state),
        costLabel: tr('Základní útok', 'Basic Attack'),
        onPressed: () => state.fight(state.classIsMagicAttack),
      );
      final tier1Btn = state.hasAdvancedClass
          ? SpellIconButton(
              visual: spellVisualTier1(state.heroClass),
              costLabel: '${state.ability1Cost} ${state.resourceName}',
              disabled: state.activeAbilityCooldown > 0 || state.currentResourceValue < state.ability1Cost,
              overlayText: state.activeAbilityCooldown > 0 ? '${state.activeAbilityCooldown}' : null,
              onPressed: state.useActiveAbility,
            )
          : lockedAbilitySlot(state, spellVisualTier1(state.heroClass), 15);
      final tier2Btn = state.hasUltimateClass
          ? SpellIconButton(
              visual: spellVisualTier2(state.heroClass),
              costLabel: '${state.ability2Cost} ${state.resourceName}',
              disabled: state.secondAbilityCooldown > 0 || state.currentResourceValue < state.ability2Cost,
              overlayText: state.secondAbilityCooldown > 0 ? '${state.secondAbilityCooldown}' : null,
              onPressed: state.useSecondAbility,
            )
          : lockedAbilitySlot(state, spellVisualTier2(state.heroClass), 40);
      final tier3Btn = state.hasGodClass
          ? SpellIconButton(
              visual: spellVisualTier3(state.heroClass),
              costLabel: '${state.ability3Cost} ${state.resourceName}',
              disabled: state.thirdAbilityCooldown > 0 || state.currentResourceValue < state.ability3Cost,
              overlayText: state.thirdAbilityCooldown > 0 ? '${state.thirdAbilityCooldown}' : null,
              onPressed: state.useThirdAbility,
            )
          : lockedAbilitySlot(state, spellVisualTier3(state.heroClass), 75);
      final tier4Btn = state.hasRank100Class
          ? SpellIconButton(
              visual: spellVisualTier4(state.heroClass, state.rank100Choice),
              costLabel: '${state.ability4Cost} ${state.resourceName}',
              disabled: state.fourthAbilityCooldown > 0 || state.currentResourceValue < state.ability4Cost,
              overlayText: state.fourthAbilityCooldown > 0 ? '${state.fourthAbilityCooldown}' : null,
              onPressed: state.useFourthAbility,
            )
          : lockedTier4Slot(state);
      final relicBtn = state.currentSpecRelicUnlocked
          ? SpellIconButton(
              visual: SpellVisual('Relic: ${state.currentSpecRelic.spell}', state.currentSpecRelic.icon, state.currentSpecRelic.color),
              costLabel: state.isSpecRelicEquipped
                  ? (state.heroClass == HeroClass.deathknight ? tr('Uvolnit duše', 'Release Souls') : 'Relic spell')
                  : tr('Nutno nasadit v Inventáři!', 'Must be equipped in Inventory!'),
              disabled: !state.isSpecRelicEquipped || state.specRelicUsedTower,
              overlayText: !state.isSpecRelicEquipped ? tr('Nenasazen', 'Not equipped') : (state.specRelicUsedTower ? tr('Použito', 'Used') : null),
              onPressed: state.useSpecRelicTowerSpell,
            )
          : lockedRelicSlot();
      final healBtn = ConsumableIconButton(
        icon: Icons.medical_services, color: Colors.greenAccent, count: healingPotionsCount,
        tooltip: tr('Léčivý lektvar (cooldown 1 kolo)', 'Healing Potion (1-round cooldown)'),
        overlayText: state.healPotionCooldown > 0 ? '${state.healPotionCooldown}' : null,
        onPressed: (healingPotionsCount > 0 && state.healPotionCooldown <= 0) ? () => state.useItemByName("Léčivý lektvar") : null,
      );
      final vampireBtn = ConsumableIconButton(
        icon: Icons.water_drop, color: Colors.purpleAccent, count: vampirePotionsCount,
        tooltip: tr('Upíří lektvar', 'Vampiric Potion'),
        onPressed: vampirePotionsCount > 0 ? () => state.useItemByName("Upíří Lektvar") : null,
      );
      final extraPotionButtons = <Widget>[
        for (var potionName in ["Lektvar Síly", "Lektvar Kamenné kůže", "Lektvar Moudrosti", "Elixír Fénixe"])
          if (state.consumables.any((i) => i.name == potionName))
            ConsumableIconButton(
              icon: Icons.science, color: Colors.blueGrey.shade300,
              count: state.consumables.where((i) => i.name == potionName).fold<int>(0, (sum, i) => sum + i.stackCount),
              tooltip: potionName,
              onPressed: () => state.useItemByName(potionName),
            ),
      ];
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ConsumableIconButton(
                  icon: state.autoCombatEnabled ? Icons.pause : Icons.play_arrow,
                  color: Colors.lightGreenAccent,
                  active: state.autoCombatEnabled,
                  tooltip: state.autoCombatEnabled ? tr('Auto-boj: ZAPNUTO (klikni pro vypnutí)', 'Auto-fight: ON (tap to turn off)') : tr('Auto-boj: VYPNUTO (klikni pro zapnutí)', 'Auto-fight: OFF (tap to turn on)'),
                  onPressed: state.toggleAutoCombat,
                ),
                Expanded(
                  child: Text(
                    tr("Patro: ${state.floor} (Nepřátel poraženo: ${state.enemiesDefeatedOnFloor}/5)", "Floor: ${state.floor} (Enemies defeated: ${state.enemiesDefeatedOnFloor}/5)"),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFB100)),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  iconSize: 18,
                  tooltip: state.autoCombatSpeedLevel >= GameState.maxAutoCombatSpeedLevel
                      ? tr('Auto-boj: ${(state.autoCombatIntervalMs / 1000).toStringAsFixed(1)}s/útok (MAX)', 'Auto-fight: ${(state.autoCombatIntervalMs / 1000).toStringAsFixed(1)}s/attack (MAX)')
                      : tr('Auto-boj: ${(state.autoCombatIntervalMs / 1000).toStringAsFixed(1)}s/útok - zaplať ${GameState.autoCombatSpeedUpgradeCost} 🪙 pro -0.1s', 'Auto-fight: ${(state.autoCombatIntervalMs / 1000).toStringAsFixed(1)}s/attack - pay ${GameState.autoCombatSpeedUpgradeCost} 🪙 for -0.1s'),
                  icon: Icon(Icons.bolt, color: state.autoCombatSpeedLevel >= GameState.maxAutoCombatSpeedLevel ? Colors.amberAccent : Colors.grey),
                  onPressed: state.upgradeAutoCombatSpeed,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  iconSize: 18,
                  tooltip: state.portraitCombatMode ? tr('Přepnout na detailní zobrazení', 'Switch to detailed view') : tr('Přepnout na portrét', 'Switch to portrait view'),
                  icon: Icon(state.portraitCombatMode ? Icons.view_list : Icons.portrait, color: Colors.grey),
                  onPressed: state.togglePortraitCombatMode,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  iconSize: 18,
                  tooltip: state.combatStatsVisible ? tr('Skrýt staty', 'Hide stats') : tr('Zobrazit staty', 'Show stats'),
                  icon: Icon(state.combatStatsVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: state.toggleCombatStats,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final heroAccent = heroClassAccent(state.heroClass);
              final enemyAccent = state.isBoss ? Colors.purpleAccent : const Color(0xFFE4463F);
              return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ImpactFlashCard(
                    state: state,
                    side: FxSide.hero,
                    child: Stack(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(center: Alignment.topLeft, radius: 1.3, colors: [heroAccent.withOpacity(.16), const Color(0xFF141019)]),
                      border: Border.all(color: heroAccent.withOpacity(.5)),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [BoxShadow(color: heroAccent.withOpacity(.35), blurRadius: 18, spreadRadius: -6)],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.portraitCombatMode) ...[
                            if (state.specialization != 0)
                              Center(
                                child: Column(children: [
                                  Container(
                                    width: 64, height: 64, padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [state.currentSpecRelic.color.withOpacity(.5), const Color(0xFF14181C)]), border: Border.all(color: state.currentSpecRelic.color.withOpacity(.7), width: 2), boxShadow: [BoxShadow(color: state.currentSpecRelic.color.withOpacity(.6), blurRadius: 14)]),
                                    child: Icon(state.currentSpecRelic.icon, size: 32, color: state.currentSpecRelic.color),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(state.heroName.isNotEmpty ? state.heroName : tr("Hrdina", "Hero"), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: heroAccent)),
                                  Text(state.currentSpecRelic.form, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: heroAccent.withOpacity(.75))),
                                ]),
                              )
                            else if (kClassPortraitAssets[state.heroClass] != null)
                              // Velký obdélníkový portrét přes celou šířku karty místo dřívějšího
                              // malého 64px kulatého avataru (min. 2x větší) - skutečná ilustrace
                              // třídy jako dominantní vizuál karty, jméno přes gradientní scrim
                              // dole na obrázku místo pod ním. Jen `subtle` dýchání - v boji
                              // portrét soutěží o pozornost s HP/dmg čísly, takže nic víc (žádný
                              // zoom navíc, žádné částice - na to je class picker/Profil, viz
                              // PortraitLifeMode.full tam).
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 170,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      LivingPortrait(assetPath: kClassPortraitAssets[state.heroClass]!, accent: heroAccent, mode: PortraitLifeMode.subtle),
                                      DecoratedBox(
                                        decoration: BoxDecoration(border: Border.all(color: heroAccent.withOpacity(.6), width: 2), borderRadius: BorderRadius.circular(12)),
                                      ),
                                      Positioned(
                                        left: 0, right: 0, bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                                          child: Text(state.heroName.isNotEmpty ? state.heroName : tr("Hrdina", "Hero"), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: heroAccent)),
                                        ),
                                      ),
                                      // Kosmetický rám z Battle Passu (viz CustomizationScreen) - 'default' nekreslí nic.
                                      if (state.equippedFrame != 'default') Positioned.fill(child: CustomPaint(painter: BattlePassFramePainter(frameId: state.equippedFrame))),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Center(
                                child: Column(children: [
                                  Container(
                                    width: 64, height: 64, padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [heroAccent.withOpacity(.5), const Color(0xFF14181C)]), border: Border.all(color: heroAccent.withOpacity(.7), width: 2), boxShadow: [BoxShadow(color: heroAccent.withOpacity(.6), blurRadius: 14)]),
                                    child: CustomPaint(painter: FantasyIconRegistry.of(heroClassIconType(state.heroClass)).proceduralPainter(heroAccent)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(state.heroName.isNotEmpty ? state.heroName : tr("Hrdina", "Hero"), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: heroAccent)),
                                ]),
                              ),
                            const SizedBox(height: 8),
                          ] else
                          Row(children: [
                            Container(
                              width: 26, height: 26, padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [heroAccent.withOpacity(.45), const Color(0xFF14181C)]), boxShadow: [BoxShadow(color: heroAccent.withOpacity(.6), blurRadius: 8)]),
                              child: kClassPortraitAssets[state.heroClass] != null
                                  ? ClipOval(
                                      child: Image.asset(
                                        kClassPortraitAssets[state.heroClass]!,
                                        width: 16, height: 16, fit: BoxFit.cover,
                                      ),
                                    )
                                  : CustomPaint(painter: FantasyIconRegistry.of(heroClassIconType(state.heroClass)).proceduralPainter(heroAccent)),
                            ),
                            const SizedBox(width: 7),
                            Expanded(child: Text(state.heroName.isNotEmpty ? state.heroName : tr("Hrdina", "Hero"), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: heroAccent))),
                          ]),
                          const SizedBox(height: 8),
                          BarWidget(value: state.hp.toDouble(), max: state.maxHp.toDouble(), color: Colors.green, label: "HP"),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Visibility(
                              visible: state.bonusShield > 0,
                              maintainSize: true, maintainAnimation: true, maintainState: true,
                              child: BarWidget(value: state.bonusShield.toDouble(), max: max(1, state.bonusShield).toDouble(), color: heroAccent, label: tr("Štít", "Shield")),
                            ),
                          ),
                          const SizedBox(height: 4),
                          BarWidget(value: state.currentResourceValue.toDouble(), max: max(1, state.maxResourceValue).toDouble(), color: state.resourceColor, label: state.resourceName),
                          const SizedBox(height: 8),
                          if (state.combatStatsVisible && !state.portraitCombatMode) Wrap(spacing: 4, runSpacing: 4, children: [
                            CombatStatChip(
                              icon: Icons.gavel, value: formatCompactNumber(state.physAtk), badgeColor: const Color(0xFF4A1B0C), badgeIconColor: const Color(0xFFF0997B),
                              name: tr('Fyzický útok', 'Physical Attack'),
                              description: tr('Základ pro poškození fyzických (nekouzelných) útoků a schopností. Škáluje se z výbavy a Síly.', 'The base for damage from physical (non-spell) attacks and abilities. Scales from gear and Strength.'),
                            ),
                            CombatStatChip(
                              icon: Icons.auto_fix_high, value: formatCompactNumber(state.magAtk), badgeColor: const Color(0xFF26215C), badgeIconColor: const Color(0xFFAFA9EC),
                              name: tr('Magický útok', 'Magic Attack'),
                              description: tr('Základ pro poškození kouzelných schopností. Škáluje se z výbavy a Moudrosti.', 'The base for damage from magic abilities. Scales from gear and Wisdom.'),
                            ),
                            CombatStatChip(
                              icon: Icons.shield, value: formatCompactNumber(state.armor), badgeColor: const Color(0xFF04342C), badgeIconColor: const Color(0xFF5DCAA5),
                              name: tr('Obrana (Armor)', 'Armor'),
                              description: tr('Snižuje fyzické poškození, které dostaneš. Vyšší Armor = menší dmg z nekouzelných útoků nepřítele.', 'Reduces the physical damage you take. Higher Armor = less damage from the enemy\'s non-spell attacks.'),
                            ),
                            CombatStatChip(
                              icon: Icons.flash_on, value: "${(state.critChance * 100).toStringAsFixed(1)}%", badgeColor: const Color(0xFF412402), badgeIconColor: const Color(0xFFEF9F27),
                              name: tr('Kritický zásah', 'Critical Strike'),
                              description: tr('Šance, že tvůj útok nebo spell způsobí zvýšené (kritické) poškození.', 'Chance that your attack or spell deals increased (critical) damage.'),
                            ),
                            CombatStatChip(
                              icon: Icons.directions_run, value: "${(state.dodgeChance * 100).toStringAsFixed(1)}%", badgeColor: const Color(0xFF042C53), badgeIconColor: const Color(0xFF85B7EB),
                              name: tr('Úhyb (Dodge)', 'Dodge'),
                              description: tr('Šance, že se zcela vyhneš nepřátelskému útoku a neutrpíš žádné poškození.', 'Chance to fully evade an enemy attack and take no damage from it.'),
                            ),
                            CombatStatChip(
                              icon: Icons.security, value: "${(state.blockChance * 100).toStringAsFixed(1)}%", badgeColor: const Color(0xFF4B1528), badgeIconColor: const Color(0xFFED93B1),
                              name: tr('Blok', 'Block'),
                              description: tr('Šance, že část poškození nepřátelského útoku pohltíš štítem/blokem místo abys ji dostal celou.', 'Chance to absorb part of an incoming attack\'s damage with a block instead of taking it in full.'),
                            ),
                          ]),
                        ],
                    ),
                  ),
                      CombatFxOverlay(state: state, side: FxSide.hero),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ImpactFlashCard(
                    state: state,
                    side: FxSide.enemy,
                    child: Stack(children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child)),
                    child: Container(
                    key: ValueKey(state.enemySpawnSeq),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(center: Alignment.topLeft, radius: 1.3, colors: [enemyAccent.withOpacity(.16), const Color(0xFF1E1613)]),
                      border: Border.all(color: enemyAccent.withOpacity(.5)),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [BoxShadow(color: enemyAccent.withOpacity(.35), blurRadius: 18, spreadRadius: -6)],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.portraitCombatMode) ...[
                            Builder(builder: (context) {
                              final (bossIcon, bossColor) = state.bossThemeIconFor({'name': state.currentEnemyName, 'ability': state.currentEnemyAbility});
                              final bossPortrait = kBossPortraitAssets[state.currentEnemyName] ?? (state.isBoss ? null : kRegularEnemyPortraitAssets[state.currentEnemyName]);
                              // Stejné měřítko jako hráčův portrét níž (velký obdélník přes celou
                              // šířku karty, jméno vypálené na gradientním scrimu dole) - dřív měl
                              // nepřítel jen malé 64px kolečko, i když měl skutečnou ilustraci.
                              // Fallback na malé kolečko s procedurální ikonou zůstává pro
                              // nepřátele, co ještě nemají portrét (bossPortrait == null).
                              if (bossPortrait != null) {
                                return Column(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 170,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          LivingPortrait(assetPath: bossPortrait, accent: bossColor, mode: PortraitLifeMode.subtle),
                                          DecoratedBox(
                                            decoration: BoxDecoration(border: Border.all(color: bossColor.withOpacity(.6), width: 2), borderRadius: BorderRadius.circular(12)),
                                          ),
                                          Positioned(
                                            left: 0, right: 0, bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                Flexible(child: Text(state.currentEnemyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: enemyAccent))),
                                                const SizedBox(width: 4),
                                                ComboStreakBadge(streak: state.comboStreak),
                                              ]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(tr("Schopnost: ${state.currentEnemyAbility}", "Ability: ${state.currentEnemyAbility}"), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.amberAccent)),
                                ]);
                              }
                              return Center(
                                child: Column(children: [
                                  Container(
                                    width: 64, height: 64, padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [bossColor.withOpacity(.5), const Color(0xFF1E1613)]), border: Border.all(color: bossColor.withOpacity(.7), width: 2), boxShadow: [BoxShadow(color: bossColor.withOpacity(.6), blurRadius: 14)]),
                                    child: Icon(bossIcon, size: 32, color: bossColor),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    Flexible(child: Text(state.currentEnemyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: enemyAccent))),
                                    const SizedBox(width: 4),
                                    ComboStreakBadge(streak: state.comboStreak),
                                  ]),
                                  Text(tr("Schopnost: ${state.currentEnemyAbility}", "Ability: ${state.currentEnemyAbility}"), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.amberAccent)),
                                ]),
                              );
                            }),
                            const SizedBox(height: 8),
                          ] else ...[
                          Row(children: [
                            Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [enemyAccent.withOpacity(.45), const Color(0xFF1E1613)]), boxShadow: [BoxShadow(color: enemyAccent.withOpacity(.6), blurRadius: 8)]),
                              alignment: Alignment.center,
                              child: (kBossPortraitAssets[state.currentEnemyName] ?? (state.isBoss ? null : kRegularEnemyPortraitAssets[state.currentEnemyName])) != null
                                  ? ClipOval(child: Image.asset(kBossPortraitAssets[state.currentEnemyName] ?? kRegularEnemyPortraitAssets[state.currentEnemyName]!, width: 26, height: 26, fit: BoxFit.cover))
                                  : Icon(state.isBoss ? Icons.local_fire_department : Icons.pest_control, size: 13, color: enemyAccent),
                            ),
                            const SizedBox(width: 7),
                            Expanded(child: Text(state.currentEnemyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: enemyAccent))),
                            ComboStreakBadge(streak: state.comboStreak),
                          ]),
                          const SizedBox(height: 4),
                          Text(tr("Schopnost: ${state.currentEnemyAbility}", "Ability: ${state.currentEnemyAbility}"), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.amberAccent)),
                          ],
                          const SizedBox(height: 6),
                          BarWidget(value: state.currentEnemyHp.toDouble(), max: state.currentEnemyMaxHp.toDouble(), color: Colors.deepOrange, label: tr("HP Nepřítele", "Enemy HP")),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Visibility(
                              visible: state.currentEnemyShield > 0,
                              maintainSize: true, maintainAnimation: true, maintainState: true,
                              child: BarWidget(value: state.currentEnemyShield.toDouble(), max: max(1, state.currentEnemyShield).toDouble(), color: const Color(0xFFC69214), label: tr("Štít", "Shield")),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (state.combatStatsVisible && !state.portraitCombatMode) Wrap(spacing: 4, runSpacing: 4, children: [
                            CombatStatChip(
                              icon: Icons.gavel, value: formatCompactNumber(state.currentEnemyAtk), badgeColor: const Color(0xFF4A1B0C), badgeIconColor: const Color(0xFFF0997B),
                              name: tr('Útok nepřítele', "Enemy Attack"),
                              description: tr('Základ pro poškození, které ti nepřítel způsobí svými útoky.', "The base for the damage the enemy deals you with its attacks."),
                            ),
                            CombatStatChip(
                              icon: Icons.shield, value: formatCompactNumber(state.currentEnemyDef), badgeColor: const Color(0xFF04342C), badgeIconColor: const Color(0xFF5DCAA5),
                              name: tr('Obrana nepřítele', "Enemy Defense"),
                              description: tr('Snižuje poškození, které mu způsobíš - vyšší hodnota = musíš mít víc útoku, aby to bolelo stejně.', "Reduces the damage you deal to it - a higher value means you need more attack to hurt it the same amount."),
                            ),
                            CombatStatChip(
                              icon: state.currentEnemyIsMagical ? Icons.auto_fix_high : Icons.sports_martial_arts, value: state.currentEnemyIsMagical ? tr('Mag.', 'Mag.') : tr('Fyz.', 'Phys.'), badgeColor: const Color(0xFF2C2C2A), badgeIconColor: const Color(0xFFB4B2A9),
                              name: tr('Typ útoku', "Attack Type"),
                              description: tr('Jestli nepřítel útočí Magicky nebo Fyzicky - určuje, jestli proti němu víc pomáhá tvoje Armor (fyzický) nebo magická obrana (magický).', "Whether the enemy attacks Magically or Physically - determines whether your Armor (physical) or magic defense (magic) helps more against it."),
                            ),
                            if (state.enemyCritChance > 0) CombatStatChip(
                              icon: Icons.flash_on, value: "${(state.enemyCritChance * 100).toStringAsFixed(0)}%", badgeColor: const Color(0xFF412402), badgeIconColor: const Color(0xFFEF9F27),
                              name: tr('Kritický zásah nepřítele', "Enemy Critical Strike"),
                              description: tr('Šance, že nepřítel proti tobě udělí kritický (zvýšený) zásah.', "Chance the enemy lands a critical (increased) hit against you."),
                            ),
                            if (state.enemyDodgeChance > 0) CombatStatChip(
                              icon: Icons.directions_run, value: "${(state.enemyDodgeChance * 100).toStringAsFixed(0)}%", badgeColor: const Color(0xFF042C53), badgeIconColor: const Color(0xFF85B7EB),
                              name: tr('Úhyb nepřítele', "Enemy Dodge"),
                              description: tr('Šance, že se nepřítel zcela vyhne tvému útoku.', "Chance the enemy fully evades your attack."),
                            ),
                            if (state.enemyBlockChance > 0) CombatStatChip(
                              icon: Icons.security, value: "${(state.enemyBlockChance * 100).toStringAsFixed(0)}%", badgeColor: const Color(0xFF4B1528), badgeIconColor: const Color(0xFFED93B1),
                              name: tr('Blok nepřítele', "Enemy Block"),
                              description: tr('Šance, že nepřítel část tvého poškození zablokuje/pohltí.', "Chance the enemy blocks/absorbs part of your damage."),
                            ),
                          ]),
                        ],
                    ),
                  ),
                  ),
                      CombatFxOverlay(state: state, side: FxSide.enemy),
                    ]),
                  ),
                ),
              ],
              );
            }),
            const SizedBox(height: 8),
            // FIXNÍ ZÓNA (vždy 34px, i když jsou efekty prázdné): buffy/debuffy z obou stran
            // spojené do jednoho horizontálně scrollovatelného pruhu. Dřív byly zvlášť uvnitř
            // každé karty (Wrap s proměnnou výškou) a posouvaly spelly/lektvary pod sebou podle
            // toho, kolik jich zrovna bylo aktivních - teď mají pevné místo bez ohledu na počet.
            SizedBox(
              height: 34,
              child: (state.heroEffects.isEmpty && state.enemyEffects.isEmpty)
                  ? null
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: StatusEffectsListWidget(effects: [...state.heroEffects, ...state.enemyEffects]),
                    ),
            ),
            const SizedBox(height: 8),
            CombatLogSection(state: state, message: state.message, type: classifyCombatMessage(state.message)),
            const SizedBox(height: 10),
            // Deathknight: Vysátí duše counter
            if (classPassiveBar(state) != null) ...[
              classPassiveBar(state)!,
              const SizedBox(height: 8),
            ],
            // Pevná mřížka 2×4: základní útok+tier1-3 nahoře, Léčivý lektvar pod základním
            // útokem (levý dolní roh) + tier4/relic uprostřed + Upíří lektvar v pravém dolním
            // rohu (viz combatActionGrid) - dřív to byl volný Wrap bez pevných "rohů".
            combatActionGrid(
              basicAttack: basicAttackBtn,
              tier1: tier1Btn,
              tier2: tier2Btn,
              tier3: tier3Btn,
              tier4: tier4Btn,
              relic: relicBtn,
              healPotion: healBtn,
              vampirePotion: vampireBtn,
              extraPotions: extraPotionButtons,
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }
}

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  String _resetCountdown(QuestType type, GameState state) {
    if (type == QuestType.daily) {
      final diff = state.nextDailyReset.difference(DateTime.now());
      return tr("\nReset za: ${diff.inHours}h ${diff.inMinutes % 60}m", "\nResets in: ${diff.inHours}h ${diff.inMinutes % 60}m");
    } else if (type == QuestType.weekly) {
      final diff = state.nextWeeklyReset.difference(DateTime.now());
      return tr("\nReset za: ${diff.inDays}d ${diff.inHours % 24}h", "\nResets in: ${diff.inDays}d ${diff.inHours % 24}h");
    } else if (type == QuestType.monthly) {
      final diff = state.nextMonthlyReset.difference(DateTime.now());
      return tr("\nReset za: ${diff.inDays}d", "\nResets in: ${diff.inDays}d");
    }
    return "";
  }

  @override
  Widget build(BuildContext context) => Consumer<GameState>(
        builder: (context, state, _) {
          // Splněné questy se řadí až na konec seznamu, pořadí v rámci obou skupin
          // (nesplněné / splněné) zůstává zachované.
          final sortedQuests = [
            ...state.quests.where((q) => !q.isCompleted),
            ...state.quests.where((q) => q.isCompleted),
          ];
          return Column(
            children: [
              _BattlePassBanner(state: state),
              Expanded(
                child: ListView.builder(
          itemCount: sortedQuests.length,
          itemBuilder: (context, index) {
            final q = sortedQuests[index];
            bool isEligible = q.requiredClass == null || q.requiredClass == state.heroClass;
            String progressText = q.targetKills > 0 ? tr(" | Pokrok: ${q.currentKills}/${q.targetKills}", " | Progress: ${q.currentKills}/${q.targetKills}") : "";
            if (q.requiredRiftClears > 0) {
              final clearsThisPeriod = q.type == QuestType.daily
                  ? state.riftClearsToday
                  : q.type == QuestType.weekly
                      ? state.riftClearsThisWeek
                      : q.type == QuestType.monthly
                          ? state.riftClearsThisMonth
                          : 0;
              progressText += tr(" | Trhliny: ${clearsThisPeriod.clamp(0, q.requiredRiftClears)}/${q.requiredRiftClears}", " | Rifts: ${clearsThisPeriod.clamp(0, q.requiredRiftClears)}/${q.requiredRiftClears}");
            }
            String resetText = _resetCountdown(q.type, state);

            return Card(
              color: q.isCompleted ? const Color(0xFF1E2F23) : (isEligible ? const Color(0xFF1E1E24) : Colors.black26),
              child: ListTile(
                leading: Icon(q.isCompleted ? Icons.check_circle : (isEligible ? Icons.list : Icons.lock), color: q.isCompleted ? Colors.green : (isEligible ? const Color(0xFFFFB100) : Colors.grey)),
                title: Text("[${q.type.name.toUpperCase()}] ${q.title}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${q.description}$progressText\n${tr("Odměna:", "Reward:")} ${q.rewardDust} Dust, ${q.rewardGold} Gold${q.rewardCrystals > 0 ? ', ${q.rewardCrystals} 💎' : ''}${q.requiredClass != null ? '\n${tr("Požadavek:", "Requirement:")} ${q.requiredClass!.name}' : ''}$resetText", style: const TextStyle(color: Colors.grey)),
                trailing: Text(q.isCompleted ? tr("Hotovo", "Done") : tr("Aktivní", "Active"), style: TextStyle(color: q.isCompleted ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)),
              ),
            );
          },
                ),
              ),
            ],
          );
        },
      );
}

// Kompaktní banner Battle Passu nahoře v Questech - úroveň, progress bar do dalšího levelu,
// dny do konce sezóny, a tlačítko dovnitř. Tap kamkoliv na banner otevře BattlePassScreen.
class _BattlePassBanner extends StatelessWidget {
  final GameState state;
  const _BattlePassBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = state.battlePassLevel >= GameState.battlePassMaxLevel ? 1.0 : state.battlePassRenownIntoLevel / state.battlePassRenownForNextLevel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BattlePassScreen())),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3A2B12), Color(0xFF1E1E24)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFB100).withOpacity(.6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.military_tech, color: Color(0xFFFFB100), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(tr('Battle Pass - Úroveň ${state.battlePassLevel}', 'Battle Pass - Level ${state.battlePassLevel}'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
                        const Spacer(),
                        if (state.battlePassHasUnclaimedRewards)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                            child: Text(tr('Odměny!', 'Rewards!'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 6, backgroundColor: Colors.black38, color: const Color(0xFFFFB100)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tr('Zbývá ${state.battlePassDaysLeft} dní sezóny', '${state.battlePassDaysLeft} days left in the season'),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Obrazovka Battle Passu - dřív jen banner s odkazem, samotná obrazovka chyběla. Vrstva na
/// GameState logice (renown/level/free+premium claim/nákup premium), co už existovala hotová -
/// tohle je jen UI nad ní. Sezóna 30 dní, 40 úrovní, renown se plní přes denní/týdenní/měsíční
/// questy (viz _checkQuests).
class BattlePassScreen extends StatelessWidget {
  const BattlePassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      final progress = state.battlePassLevel >= GameState.battlePassMaxLevel ? 1.0 : state.battlePassRenownIntoLevel / state.battlePassRenownForNextLevel;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== HLAVIČKA - úroveň, progress bar do dalšího levelu, dny do konce sezóny =====
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3A2B12), Color(0xFF1E1E24)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFB100).withOpacity(.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.military_tech, color: Color(0xFFFFB100), size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('Battle Pass - Úroveň ${state.battlePassLevel}/${GameState.battlePassMaxLevel}', 'Battle Pass - Level ${state.battlePassLevel}/${GameState.battlePassMaxLevel}'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFFFFB100)),
                    ),
                  ),
                  Text(tr('${state.battlePassDaysLeft} dní', '${state.battlePassDaysLeft} days'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 10, backgroundColor: Colors.black38, color: const Color(0xFFFFB100)),
                ),
                const SizedBox(height: 4),
                Text(
                  state.battlePassLevel >= GameState.battlePassMaxLevel
                      ? tr('Maximální úroveň dosažena!', 'Max level reached!')
                      : tr('${state.battlePassRenownIntoLevel}/${state.battlePassRenownForNextLevel} renown do další úrovně', '${state.battlePassRenownIntoLevel}/${state.battlePassRenownForNextLevel} renown to next level'),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ===== PREMIUM ODEMČENÍ / STAV =====
          if (!state.battlePassPremium)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.workspace_premium),
                onPressed: state.buyBattlePassPremium,
                label: Text(tr('Odemknout Premium (${GameState.battlePassPremiumCost} 💎)', 'Unlock Premium (${GameState.battlePassPremiumCost} 💎)'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF8B5CF6))),
              child: Text(tr('✨ Premium aktivní pro tuto sezónu', '✨ Premium active for this season'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.done_all, size: 18),
              onPressed: state.claimAllBattlePassRewards,
              label: Text(tr('Vyzvednout vše', 'Claim all')),
            ),
          ),
          const SizedBox(height: 16),
          // ===== SLOUPCE FREE / PREMIUM =====
          Row(children: [
            const Expanded(child: SizedBox()),
            Expanded(child: Text(tr('FREE', 'FREE'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(child: Text(tr('PREMIUM', 'PREMIUM'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12))),
          ]),
          const SizedBox(height: 6),
          // ===== ŽEBŘÍK ÚROVNÍ - od 1 do battlePassMaxLevel, každá s free i premium buňkou =====
          for (int level = 1; level <= GameState.battlePassMaxLevel; level++) ...[
            _BattlePassLevelRow(state: state, level: level),
            const SizedBox(height: 6),
          ],
        ],
      );
    });
  }
}

class _BattlePassLevelRow extends StatelessWidget {
  final GameState state;
  final int level;
  const _BattlePassLevelRow({required this.state, required this.level});

  @override
  Widget build(BuildContext context) {
    final bool reached = level <= state.battlePassLevel;
    final bool isCurrent = level == state.battlePassLevel + 1 && !reached;
    final freeReward = state.battlePassRewardFor(level, false);
    final premiumReward = state.battlePassRewardFor(level, true);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFFFB100).withOpacity(.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrent ? Border.all(color: const Color(0xFFFFB100).withOpacity(.5)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('$level', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: reached ? const Color(0xFFFFB100) : Colors.grey)),
          ),
          Expanded(child: _rewardCell(context, freeReward, premium: false, reached: reached)),
          const SizedBox(width: 6),
          Expanded(child: _rewardCell(context, premiumReward, premium: true, reached: reached)),
        ],
      ),
    );
  }

  Widget _rewardCell(BuildContext context, BattlePassReward reward, {required bool premium, required bool reached}) {
    final claimed = premium ? state.battlePassPremiumClaimed.contains(level) : state.battlePassFreeClaimed.contains(level);
    final bool locked = premium && !state.battlePassPremium;
    final accent = premium ? const Color(0xFF8B5CF6) : const Color(0xFFFFB100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (reached && !locked ? accent : Colors.grey).withOpacity(.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reward.cosmeticFrameId != null)
            const Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 18)
          else if (reward.cosmeticAttackSkinId != null)
            const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 18)
          else if (reward.isChest)
            Icon(Icons.card_giftcard, color: accent, size: 16),
          if (reward.cosmeticFrameId != null || reward.cosmeticAttackSkinId != null || reward.isChest) const SizedBox(height: 3),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              if (reward.gold > 0) Text('🪙${reward.gold}', style: const TextStyle(fontSize: 11)),
              if (reward.dust > 0) Text('✨${reward.dust}', style: const TextStyle(fontSize: 11)),
              if (reward.crystals > 0) Text('💎${reward.crystals}', style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          if (locked)
            const Icon(Icons.lock, size: 16, color: Colors.grey)
          else if (!reached)
            const Icon(Icons.lock_clock, size: 16, color: Colors.grey)
          else if (claimed)
            const Icon(Icons.check_circle, size: 18, color: Colors.greenAccent)
          else
            SizedBox(
              height: 26,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () => state.claimBattlePassReward(level, premium),
                child: Text(tr('Vyzvednout', 'Claim'), style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Obrazovka, kde si hráč vybírá nasazený rám portrétu a skin základního útoku z toho, co má
/// odemčené (zatím jen z Battle Passu, level 40 obou větví - viz claimBattlePassReward). Zamčené
/// položky jsou vidět taky (šedě, se zámkem), ať hráč ví, co ho čeká a odkud to jde odemknout.
class CustomizationScreen extends StatelessWidget {
  const CustomizationScreen({super.key});

  static const List<(String, String, String)> _frames = [
    ('default', 'Žádný', 'No frame'),
    ('battlepass_frame', 'Zlatý rám', 'Golden frame'),
  ];
  static const List<(String, String, String)> _attackSkins = [
    ('default', 'Žádný', 'No skin'),
    ('battlepass_attack_skin', 'Sezónní čepel/aura', 'Season blade/aura'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Kosmetika', 'Cosmetics'))),
      body: Consumer<GameState>(builder: (context, state, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(tr('RÁM PORTRÉTU', 'PORTRAIT FRAME'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: _frames.map((f) {
                final id = f.$1;
                final unlocked = state.unlockedFrames.contains(id);
                final equipped = state.equippedFrame == id;
                return _cosmeticTile(
                  label: tr(f.$2, f.$3),
                  unlocked: unlocked,
                  equipped: equipped,
                  accent: const Color(0xFFFFD54F),
                  preview: EquippedFrameOverlay(
                    frameId: id,
                    child: Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [FantasyColors.gold.withOpacity(.25), FantasyColors2.obsidian]))),
                  ),
                  onTap: unlocked ? () => state.equipFrame(id) : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(tr('SKIN ZÁKLADNÍHO ÚTOKU', 'BASIC ATTACK SKIN'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
            const SizedBox(height: 4),
            Text(tr('Vizuál se přizpůsobí typu tvého útoku - fyzický, nebo magický.', 'The visual adapts to your attack type - physical or magical.'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: _attackSkins.map((sDef) {
                final id = sDef.$1;
                final unlocked = state.unlockedAttackSkins.contains(id);
                final equipped = state.equippedAttackSkin == id;
                return _cosmeticTile(
                  label: tr(sDef.$2, sDef.$3),
                  unlocked: unlocked,
                  equipped: equipped,
                  accent: const Color(0xFF8B5CF6),
                  preview: id == 'default'
                      ? Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: FantasyColors2.obsidian))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 30, height: 60, child: CustomPaint(painter: const AttackSkinIconPainter(physical: true))),
                            SizedBox(width: 30, height: 60, child: CustomPaint(painter: const AttackSkinIconPainter(physical: false))),
                          ],
                        ),
                  onTap: unlocked ? () => state.equipAttackSkin(id) : null,
                );
              }).toList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _cosmeticTile({required String label, required bool unlocked, required bool equipped, required Color accent, required Widget preview, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: equipped ? accent : Colors.grey.withOpacity(.3), width: equipped ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(opacity: unlocked ? 1.0 : 0.35, child: preview),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: unlocked ? const Color(0xFFF1E6D0) : Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (equipped)
              const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent)
            else if (!unlocked)
              const Icon(Icons.lock, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Pomocná funkce mimo třídu: vykreslí dlaždici lektvaru v tržišti.
// Pokud hráč nemá dost vysoký rank alchymisty, dlaždice je zamčená (šedá, se zámkem).
Widget buildPotionTile({
  required GameState state,
  required String name,
  required int requiredRank,
  required int basePrice,
  required String description,
}) {
  final bool unlocked = state.alchemistRank >= requiredRank;
  final int price = state.getPotionPrice(basePrice);
  return ListTile(
    title: Text(
      name,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: unlocked ? const Color(0xFFF1E6D0) : Colors.grey,
      ),
    ),
    subtitle: Text(
      unlocked
          ? tr("$description Cena: $price 🪙"
              "${state.potionDiscount > 0 ? ' (-${(state.potionDiscount * 100).toInt()}%)' : ''}",
              "$description Price: $price 🪙"
              "${state.potionDiscount > 0 ? ' (-${(state.potionDiscount * 100).toInt()}%)' : ''}")
          : tr("Odemkne se na Ranku $requiredRank alchymisty.", "Unlocks at Alchemist Rank $requiredRank."),
      style: TextStyle(
        color: Colors.grey,
        fontStyle: unlocked ? FontStyle.normal : FontStyle.italic,
      ),
    ),
    trailing: unlocked
        ? ElevatedButton(
            onPressed: () => state.buyItem(name, {}, price, isConsumable: true),
            child: Text(tr("Koupit", "Buy")),
          )
        : const Icon(Icons.lock, color: Colors.grey),
  );
}

class _MarketFeaturedSection extends StatelessWidget {
  final GameState state;
  const _MarketFeaturedSection({required this.state});

  String _countdownText() {
    final diff = state.nextMarketRefresh.difference(DateTime.now());
    if (diff.isNegative) return tr("brzy...", "soon...");
    return "${diff.inMinutes}m ${diff.inSeconds % 60}s";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        border: Border.all(color: const Color(0xFFFFB100), width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr("✨ Speciální nabídky", "✨ Featured Offers"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFFB100))),
              Text(tr("Refresh za: ${_countdownText()}", "Refreshes in: ${_countdownText()}"), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr("Zdarma reroll: ${state.marketFreeRerollsUsed}/${GameState.marketFreeRerollsPerCycle} • Za reklamu: ${state.marketAdRerollsUsed}/${GameState.marketMaxAdRerollsPerCycle}",
                "Free rerolls: ${state.marketFreeRerollsUsed}/${GameState.marketFreeRerollsPerCycle} • Ad rerolls: ${state.marketAdRerollsUsed}/${GameState.marketMaxAdRerollsPerCycle}"),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < state.marketFeaturedSlots.length; i++) ...[
            _marketOfferTile(context, i),
            if (i < state.marketFeaturedSlots.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _marketOfferTile(BuildContext context, int index) {
    final item = state.marketFeaturedSlots[index];
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade800), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.remove_shopping_cart, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(tr("Vyprodáno - čekej na refresh.", "Sold out - wait for refresh."), style: const TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }
    final statsText = item.stats.entries.map((e) => "${statLabel(e.key)} +${e.value}").join(", ");
    final rarityLabel = item.setId != null ? tr("SET", "SET") : item.rarity.name.toUpperCase();
    final canAfford = state.gold >= item.value;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: item.rarityColor, width: 1.4), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("${item.name} [$rarityLabel]", style: TextStyle(fontWeight: FontWeight.bold, color: item.rarityColor)),
              ),
              Text("${item.value} 🪙", style: TextStyle(color: canAfford ? Colors.white : Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text("[${slotDisplayName(item.slot)}] $statsText", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: canAfford ? () => state.buyMarketFeaturedItem(index) : null,
                  child: Text(tr("Koupit", "Buy")),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: state.canFreeRerollMarket
                    ? () => state.rerollMarketSlot(index)
                    : (state.canWatchAdForMarketReroll
                        ? () {
                            RewardedAdService.instance.preload();
                            RewardedAdService.instance.show(onReward: () => state.rerollMarketSlotFromAd(index));
                          }
                        : null),
                child: Icon(
                  state.canFreeRerollMarket ? Icons.refresh : Icons.smart_display,
                  size: 20,
                  color: state.canFreeRerollMarket ? Colors.white : (state.canWatchAdForMarketReroll ? const Color(0xFFFFB100) : Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr("Tržiště", "Market"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFB100), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🪙", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      "${state.gold}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFB100)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MarketFeaturedSection(state: state),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.medical_services, color: Colors.white70),
            title: const Text("Léčivý lektvar", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              tr("Obnoví HP dle ranku alchymisty. Cena: ${state.getPotionPrice(20)} 🪙"
              "${state.potionDiscount > 0 ? ' (-${(state.potionDiscount * 100).toInt()}%)' : ''}",
              "Restores HP based on alchemist rank. Price: ${state.getPotionPrice(20)} 🪙"
              "${state.potionDiscount > 0 ? ' (-${(state.potionDiscount * 100).toInt()}%)' : ''}"),
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: ElevatedButton(
              onPressed: () => state.buyItem("Léčivý lektvar", {"HP": 0}, state.getPotionPrice(20), isConsumable: true),
              child: Text(tr("Koupit", "Buy")),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.water_drop, color: Colors.white70),
            title: const Text("Upíří Lektvar", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              tr("Lifesteal na 10+ tahů. Cena: ${state.getPotionPrice(50)} 🪙"
              "${state.potionDiscount > 0 ? ' (-${(state.potionDiscount * 100).toInt()}%)' : ''}",
              "Lifesteal for 10+ turns. Price: ${state.getPotionPrice(50)} 🪙"
              "${state.potionDiscount > 0 ? ' (-${(state.potionDiscount * 100).toInt()}%)' : ''}"),
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: ElevatedButton(
              onPressed: () => state.buyItem("Upíří Lektvar", {}, state.getPotionPrice(50), isConsumable: true),
              child: Text(tr("Koupit", "Buy")),
            ),
          ),
          const Divider(),
          Text(tr("Pokročilé lektvary alchymisty:", "Advanced alchemist potions:"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent)),
          const SizedBox(height: 8),
          buildPotionTile(
            state: state,
            name: "Lektvar Síly",
            requiredRank: 2,
            basePrice: 40,
            description: tr("+15% Fyzický útok na 5 kol.", "+15% Physical attack for 5 turns."),
          ),
          buildPotionTile(
            state: state,
            name: "Lektvar Kamenné kůže",
            requiredRank: 4,
            basePrice: 60,
            description: tr("+25% Obrana (fyzická i magická) na 5 kol.", "+25% Defense (physical and magic) for 5 turns."),
          ),
          buildPotionTile(
            state: state,
            name: "Lektvar Moudrosti",
            requiredRank: 6,
            basePrice: 40,
            description: tr("+15% Magický útok na 5 kol.", "+15% Magic attack for 5 turns."),
          ),
          buildPotionTile(
            state: state,
            name: "Elixír Fénixe",
            requiredRank: 8,
            basePrice: 150,
            description: tr("Při smrti tě jednou obnoví na 50% HP místo Game Overu.", "On death, revives you once at 50% HP instead of Game Over."),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(tr("Automatický nákup lektvarů", "Automatic potion buying")),
            subtitle: Text(tr("Automaticky dokupuje lektvary, pokud klesnou pod 5.", "Automatically restocks potions when they drop below 5."), style: const TextStyle(color: Colors.grey)),
            value: state.autoBuyPotionsEnabled,
            onChanged: (_) => state.toggleAutoBuyPotions(),
          ),
        ],
      );
    });
  }
}

class BlacksmithScreen extends StatelessWidget {
  const BlacksmithScreen({super.key});

  Widget _header(GameState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr("Kovář Theodor (Rank ${state.blacksmithRank})", "Blacksmith Theodor (Rank ${state.blacksmithRank})"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
          const SizedBox(height: 4),
          Text(
            tr("Vyšší rank = silnější vykované vybavení a lepší staty featured nabídek na Tržišti.", "Higher rank = stronger forged gear and better stats on the Market's featured offers."),
            style: const TextStyle(fontSize: 12, color: Colors.tealAccent),
          ),
          const SizedBox(height: 4),
          Text(tr("✨ Dust: ${state.magicDust}", "✨ Dust: ${state.magicDust}"), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.upgradeBlacksmith,
              child: Text(tr("Vylepšit kováře (Cena: ${state.blacksmithRank * 400} Dust)", "Upgrade blacksmith (Price: ${state.blacksmithRank * 400} Dust)")),
            ),
          ),
        ],
      );

  Widget _craftIconButton(BuildContext context, {required String label, required Color color, required IconData icon, required bool unlocked, required String subtitle, required VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: unlocked ? color.withOpacity(.18) : const Color(0xFF1A1A1E),
            border: Border.all(color: unlocked ? color : Colors.grey.shade800, width: 1.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: unlocked ? color : Colors.grey, size: 26),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: unlocked ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _craftTab(BuildContext context, GameState state) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr("Suroviny:", "Materials:"), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("${state.materials} ⚒️", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          if (!state.resourceDropUnlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.magicDust >= 1000 ? state.unlockResourceDrop : null,
                  child: Text(tr("Odemknout sběr surovin (1000 Dust)", "Unlock material gathering (1000 Dust)")),
                ),
              ),
            ),
          Text(tr("Crafting vybavení:", "Gear crafting:"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _craftIconButton(context,
                  label: "RARE", color: const Color(0xFF0070DD), icon: Icons.stars, unlocked: state.blacksmithRank >= 5,
                  subtitle: tr("5x Ocel/Kůže/Dřevo", "5x Steel/Leather/Wood"), onTap: state.blacksmithRank >= 5 ? () => state.craftItem("rare") : null),
              const SizedBox(width: 8),
              _craftIconButton(context,
                  label: "EPIC", color: const Color(0xFFA335EE), icon: Icons.auto_awesome, unlocked: state.blacksmithRank >= 10,
                  subtitle: state.blacksmithRank >= 10 ? tr("15x Ocel/Kůže/Dřevo", "15x Steel/Leather/Wood") : "Rank 10", onTap: state.blacksmithRank >= 10 ? () => state.craftItem("epic") : null),
              const SizedBox(width: 8),
              _craftIconButton(context,
                  label: "LEGENDARY", color: const Color(0xFFFF8000), icon: Icons.whatshot, unlocked: state.blacksmithRank >= 15,
                  subtitle: state.blacksmithRank >= 15 ? tr("80x materiál", "80x material") : "Rank 15", onTap: state.blacksmithRank >= 15 ? () => state.craftItem("legendary") : null),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tr("• RARE: 2 staty (10×, 5× úroveň kováře)\n• EPIC: 3 staty (15×, 8×, 7× úroveň kováře)\n• LEGENDARY: 3 staty (30×, 25×, 20× úroveň kováře)", "• RARE: 2 stats (10×, 5× blacksmith level)\n• EPIC: 3 stats (15×, 8×, 7× blacksmith level)\n• LEGENDARY: 3 stats (30×, 25×, 20× blacksmith level)"),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );

  Widget _upgradeTab(BuildContext context, GameState state) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr("Vylepšení legendárního vybavení:", "Legendary gear upgrades:"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF8000))),
              Text("🔥 ${state.legendaryEssence}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8000))),
            ],
          ),
          const SizedBox(height: 4),
          Text(tr("Esence Moci padá z bossů na patře 30+ (ve věži i v Doupěti Bosse). Každá úroveň přidá +8 % ke statům předmětu, max +10.", "Essence of Power drops from bosses on floor 30+ (in the Tower and the Boss Lair). Each level adds +8% to the item stats, max +10."), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final upgradableItems = state.inventory.where((i) => i.isUpgradable).toList();
            if (upgradableItems.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(tr("Zatím nemáš žádné legendární ani SET vybavení k vylepšení.", "You do not have any legendary or SET gear to upgrade yet."), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              );
            }
            return Column(
              children: upgradableItems.map((item) {
                final maxed = item.upgradeLevel >= Item.maxUpgradeLevel;
                final essenceCost = state.upgradeEssenceCost(item);
                final goldCost = state.upgradeGoldCost(item);
                final canAfford = state.legendaryEssence >= essenceCost && state.gold >= goldCost;
                return Card(
                  color: const Color(0xFF1E1E24),
                  shape: RoundedRectangleBorder(side: BorderSide(color: item.rarityColor, width: 1.2), borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: FantasyIconFrame(type: item.iconType, rarity: item.rarityVisual, size: 40, interactive: false),
                    title: Text(
                      "${item.name}${item.upgradeLevel > 0 ? ' +${item.upgradeLevel}' : ''}${item.isActive ? ' [Nasazeno]' : ''}",
                      style: TextStyle(color: item.rarityColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      maxed ? tr("Maximální úroveň (+${Item.maxUpgradeLevel}) dosažena!", "Maximum level (+${Item.maxUpgradeLevel}) reached!") : tr("Úroveň ${item.upgradeLevel}/${Item.maxUpgradeLevel} • Cena dalšího levelu: $essenceCost 🔥, $goldCost 🪙", "Level ${item.upgradeLevel}/${Item.maxUpgradeLevel} • Next level cost: $essenceCost 🔥, $goldCost 🪙"),
                      style: TextStyle(color: maxed ? Colors.greenAccent : Colors.grey, fontSize: 12),
                    ),
                    trailing: maxed
                        ? const Icon(Icons.star, color: Color(0xFFFF8000))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: canAfford ? const Color(0xFFFF8000) : Colors.grey.shade800),
                            onPressed: canAfford ? () => state.upgradeItem(item) : null,
                            child: Text(tr("Vylepšit", "Upgrade")),
                          ),
                  ),
                );
              }).toList(),
            );
          }),
          const Divider(),
          Text(tr("Vylepšení SET vybavení materiálem:", "SET gear material upgrades:"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00E676))),
          const SizedBox(height: 4),
          Text(tr("Ocel/kůže/dřevo (stejné suroviny jako crafting). Každá úroveň přidá +6 % ke statům setu, max +10 - kombinuje se s vylepšením Esencí, takže plně vylepšený SET item předčí i legendary z kovárny.", "Steel/leather/wood (same materials as crafting). Each level adds +6% to the set stats, max +10 - combines with the Essence upgrade, so a fully upgraded SET item can surpass even a legendary from the blacksmith."), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final setItems = state.inventory.where((i) => i.setId != null || i.hardcoreSetId != null || i.predpekliSetId != null || i.pekloSetId != null).toList();
            if (setItems.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(tr("Zatím nemáš žádné SET vybavení k vylepšení.", "You do not have any SET gear to upgrade yet."), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              );
            }
            return Column(
              children: setItems.map((item) {
                final maxed = state.setSlotUpgradeLevel(item) >= Item.maxMaterialUpgradeLevel;
                final cost = state.materialUpgradeCost(item);
                final canAfford = state.materials >= cost;
                return Card(
                  color: const Color(0xFF1E1E24),
                  shape: RoundedRectangleBorder(side: BorderSide(color: item.rarityColor, width: 1.2), borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: FantasyIconFrame(type: item.iconType, rarity: item.rarityVisual, size: 40, interactive: false),
                    title: Text(
                      "${item.name}${state.setSlotUpgradeLevel(item) > 0 ? ' (mat +${state.setSlotUpgradeLevel(item)})' : ''}${item.isActive ? ' [Nasazeno]' : ''}",
                      style: TextStyle(color: item.rarityColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      maxed ? tr("Maximální úroveň (+${Item.maxMaterialUpgradeLevel}) dosažena!", "Maximum level (+${Item.maxMaterialUpgradeLevel}) reached!") : tr("Úroveň ${state.setSlotUpgradeLevel(item)}/${Item.maxMaterialUpgradeLevel} • Cena: ${cost}x suroviny", "Level ${state.setSlotUpgradeLevel(item)}/${Item.maxMaterialUpgradeLevel} • Price: ${cost}x materials"),
                      style: TextStyle(color: maxed ? Colors.greenAccent : Colors.grey, fontSize: 12),
                    ),
                    trailing: maxed
                        ? const Icon(Icons.star, color: Color(0xFF00E676))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: canAfford ? const Color(0xFF00E676) : Colors.grey.shade800),
                            onPressed: canAfford ? () => state.upgradeSetMaterial(item) : null,
                            child: Text(tr("Vylepšit", "Upgrade")),
                          ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      );

  Widget _destroyTab(BuildContext context, GameState state) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr("Roztavit vybavení na suroviny:", "Salvage gear into materials:"), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in [Rarity.common, Rarity.rare, Rarity.epic, Rarity.legendary])
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: state.countInactiveByRarity(r) > 0 ? Colors.red.shade900 : Colors.grey.shade800),
                  onPressed: state.countInactiveByRarity(r) > 0 ? () => state.salvageAllByRarity(r) : null,
                  icon: const Icon(Icons.local_fire_department, size: 16),
                  label: Text(tr("Vše", "All") + " ${r.name.toUpperCase()} (${state.countInactiveByRarity(r)})"),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.inactiveEquipment.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(tr("Nic k roztavení - všechno vybavení je buď nasazené, nebo zamčené.", "Nothing to salvage - all gear is either equipped or locked."), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
          ...state.inactiveEquipment.map((item) => ListTile(
                leading: FantasyIconFrame(type: item.iconType, rarity: item.rarityVisual, size: 40, interactive: false),
                title: Text(item.name, style: TextStyle(color: item.rarityColor, fontWeight: FontWeight.bold)),
                subtitle: Text(item.statsDisplayText, style: const TextStyle(color: Colors.grey)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                  onPressed: () => state.salvageItem(item),
                  child: Text(tr("Roztavit", "Salvage")),
                ),
              )),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      if (state.blacksmithRank < 5) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [_header(state), const Divider(), Text(tr("Sběr surovin a crafting se odemknou při dosažení Ranku 5.", "Material gathering and crafting unlock at Rank 5."), style: const TextStyle(color: Colors.grey))],
        );
      }
      return DefaultTabController(
        length: 3,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(children: [
              _header(state),
              const SizedBox(height: 10),
              TabBar(
                labelColor: const Color(0xFFFFB100),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFFB100),
                tabs: [const Tab(text: 'CRAFT'), Tab(text: tr('VYLEPŠIT', 'UPGRADE')), Tab(text: tr('ZNIČIT', 'DESTROY'))],
              ),
            ]),
          ),
          Expanded(
            child: TabBarView(children: [
              _craftTab(context, state),
              _upgradeTab(context, state),
              _destroyTab(context, state),
            ]),
          ),
        ]),
      );
    });
  }
}

class AlchemistScreen extends StatelessWidget {
  const AlchemistScreen({super.key});
  static const Color _accent = Color(0xFFAB47BC); // fialová - stejná paleta jako ikona/kouř Alchymie na mapě

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== HLAVIČKA - portrét Ellinor přes celou šířku (stejný jazyk jako combat karty a
          // rám v Duši: velký obdélník, jméno + rank vypálené na gradientu dole), místo
          // dřívějšího holého textového nadpisu. =====
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: double.infinity,
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LivingPortrait(assetPath: 'assets/images/npc/alchemist.png', accent: _accent, mode: PortraitLifeMode.subtle),
                  DecoratedBox(decoration: BoxDecoration(border: Border.all(color: _accent.withOpacity(.6), width: 2), borderRadius: BorderRadius.circular(14))),
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr('Alchymistka Ellinor', 'Alchemist Ellinor'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _accent)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _accent.withOpacity(.25), borderRadius: BorderRadius.circular(20), border: Border.all(color: _accent)),
                            child: Text('Rank ${state.alchemistRank}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF1E6D0))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              onPressed: state.upgradeAlchemist,
              child: Text(tr("Vylepšit alchymistu (Cena: ${state.alchemistRank * 500} Dust)", "Upgrade alchemist (Price: ${state.alchemistRank * 500} Dust)")),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.tealAccent.withOpacity(.4))),
            child: Text(
              tr(
                "Léčivý lektvar: ${(40 + state.alchemistRank).toString()}% HP\n"
                "Upíří lektvar: ${10 + state.alchemistRank} kol lifestealu\n"
                "Sleva na lektvary v tržišti: ${(state.potionDiscount * 100).toInt()}%",
                "Health Potion: ${(40 + state.alchemistRank).toString()}% HP\n"
                "Vampire Potion: ${10 + state.alchemistRank} turns of lifesteal\n"
                "Market potion discount: ${(state.potionDiscount * 100).toInt()}%",
              ),
              style: const TextStyle(color: Colors.tealAccent, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          Text(tr("Odemykané lektvary:", "Unlockable potions:"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1E6D0))),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var entry in {
                  "Lektvar Síly": 2,
                  "Lektvar Kamenné kůže": 4,
                  "Lektvar Moudrosti": 6,
                  "Elixír Fénixe": 8,
                }.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "${state.alchemistRank >= entry.value ? '✅' : '🔒'} ${entry.key} (${tr('Rank', 'Rank')} ${entry.value})",
                      style: TextStyle(color: state.alchemistRank >= entry.value ? Colors.greenAccent : Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!state.autoHealUnlocked)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
                onPressed: state.unlockAutoHeal,
                child: Text(tr("Odemknout Auto-Léčení (1000 Dust)", "Unlock Auto-Heal (1000 Dust)")),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(10)),
              child: SwitchListTile(
                title: Text(tr("Auto-Léčení Aktivní", "Auto-Heal Active")),
                value: state.autoHealEnabled,
                activeColor: _accent,
                onChanged: (_) => state.toggleAutoHeal(),
              ),
            ),
        ],
      );
    });
  }
}

// Zobrazované jméno + FantasyIconType pro každou třídu - sdílené mezi karuselem výběru a
// velkým rámem postavy níž v SoulsScreen (stejné páry jako u _ClassPickerOption na obrazovce
// výběru třídy).
const Map<HeroClass, FantasyIconType> _soulsClassIcon = {
  HeroClass.warrior: FantasyIconType.classWarrior,
  HeroClass.hunter: FantasyIconType.classHunter,
  HeroClass.healer: FantasyIconType.classPriest,
  HeroClass.deathknight: FantasyIconType.classDeathKnight,
  HeroClass.mage: FantasyIconType.classMage,
  HeroClass.duelist: FantasyIconType.classDuelist,
  HeroClass.monk: FantasyIconType.classMonk,
  HeroClass.druid: FantasyIconType.classDruid,
  HeroClass.paladin: FantasyIconType.classPaladin,
  HeroClass.demonhunter: FantasyIconType.classDemonHunter,
  HeroClass.necromancer: FantasyIconType.classNecromancer,
};

class SoulsScreen extends StatefulWidget {
  const SoulsScreen({super.key});
  @override
  State<SoulsScreen> createState() => _SoulsScreenState();
}

class _SoulsScreenState extends State<SoulsScreen> {
  // Ručně vybraná třída v karuselu - null dokud se hráč nedotkne karuselu, pak se defaultuje
  // na jeho aktuální hranou třídu (viz build níž).
  HeroClass? _selected;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      final classes = HeroClass.values.where((c) => c != HeroClass.none).toList();
      final HeroClass selected = _selected ?? (state.heroClass != HeroClass.none ? state.heroClass : classes.first);
      final classNames = <HeroClass, String>{
        HeroClass.warrior: tr("Válečník", "Warrior"),
        HeroClass.hunter: tr("Lovec", "Hunter"),
        HeroClass.healer: tr("Léčitel", "Healer"),
        HeroClass.deathknight: tr("Rytíř Smrti", "Death Knight"),
        HeroClass.mage: tr("Mág", "Mage"),
        HeroClass.duelist: tr("Šermíř", "Duelist"),
        HeroClass.monk: tr("Mnich", "Monk"),
        HeroClass.druid: tr("Druid", "Druid"),
        HeroClass.paladin: tr("Paladin", "Paladin"),
        HeroClass.demonhunter: tr("Lovec Démonů", "Demon Hunter"),
        HeroClass.necromancer: tr("Nekromant", "Necromancer"),
      };
      final int rank = state.classRanks[selected] ?? 1;
      final bool isCurrent = state.heroClass == selected;
      final accent = FantasyIconRegistry.of(_soulsClassIcon[selected]!).accentColor;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr("Vylepšení tříd za krystaly", "Class Upgrades with Crystals"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
          const SizedBox(height: 10),
          // ===== NPC HLAVIČKA - Strážkyně Duší, kompaktní karta (malý kulatý portrét + jméno +
          // jedna promluvená věta) místo dřívější neutrální instrukce. Záměrně malá a nahoře,
          // ne velká - hlavní pozornost patří rámu vybrané třídy níž, tohle je jen "uvítání". =====
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF1E1424), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF9C6ADE).withOpacity(.4))),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0x559C6ADE), Color(0xFF14101C)]), border: Border.all(color: const Color(0xFF9C6ADE))),
                  child: ClipOval(child: LivingPortrait(assetPath: 'assets/images/npc/soul_keeper.png', accent: const Color(0xFF9C6ADE), mode: PortraitLifeMode.subtle)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tr('Nyx, Strážkyně Duší', 'Nyx, Keeper of Souls'), style: const TextStyle(color: Color(0xFF9C6ADE), fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        tr('„Projeď postavy vlevo a vpravo, a řekni mi, čí duši mám posílit."', '"Scroll the characters left and right, and tell me whose soul to strengthen."'),
                        style: const TextStyle(color: Color(0xFFE6DCF0), fontSize: 12, fontStyle: FontStyle.italic, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ===== VODOROVNÝ KARUSEL TŘÍD - stejné portréty/odznaky jako u výběru třídy
          // (_ClassBadge), jen místo mřížky jako scrollovací pás. Tap/scroll na postavu ji
          // vybere - zvýrazní se (větší, plná opacity), ostatní ztlumí. =====
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final c = classes[i];
                final cIconType = _soulsClassIcon[c]!;
                final cAccent = FantasyIconRegistry.of(cIconType).accentColor;
                final cRank = state.classRanks[c] ?? 1;
                final bool isSel = c == selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = c),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSel ? 1.0 : 0.5,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: isSel ? 1.0 : 0.86,
                      child: SizedBox(
                        width: 78,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ClassBadge(iconType: cIconType, accent: cAccent, size: 72, heroClass: c),
                            const SizedBox(height: 4),
                            Text('Rank $cRank', style: TextStyle(color: cAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          // ===== RÁM POSTAVY - velký portrét vybrané třídy na pozadí síně s NPC (Strážkyně
          // Duší), stejný jazyk jako ostatní malované scény (WorldBossBackdrop/RiftBackdrop).
          // Pozadí (souls_bg.png) zatím není vygenerované - stejný postup jako u ostatních scén
          // (Copilot prompt → assets/images/scenes/), do té doby padá na tmavou barvu.
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 260,
              decoration: BoxDecoration(border: Border.all(color: accent.withOpacity(.5), width: 1.5)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/scenes/souls_bg.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.3, colors: [Color(0xFF241C30), Color(0xFF120A18)])),
                    ),
                  ),
                  Positioned.fill(child: Container(color: Colors.black.withOpacity(.25))),
                  Center(
                    child: Container(
                      width: 150, height: 150,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [accent.withOpacity(.35), const Color(0xFF141019)]),
                        border: Border.all(color: accent, width: 3),
                        boxShadow: [BoxShadow(color: accent.withOpacity(.6), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: kClassPortraitAssets[selected] != null
                          ? ClipOval(child: LivingPortrait(assetPath: kClassPortraitAssets[selected]!, accent: accent, mode: PortraitLifeMode.full))
                          : CustomPaint(painter: FantasyIconRegistry.of(_soulsClassIcon[selected]!).proceduralPainter(accent)),
                    ),
                  ),
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                      child: Text(classNames[selected]!, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ===== INFO + TLAČÍTKA pro vybranou třídu - stejná logika jako dřív, jen teď platí
          // pro "selected" z karuselu místo procházení celého seznamu. =====
          Text(tr("Rank $rank", "Rank $rank"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            (rank >= 100
                    ? tr("Rank 100 odemčen!", "Rank 100 unlocked!")
                    : (rank >= 75
                        ? tr("Božská evoluce (Rank 100 pro volbu cesty)", "Divine evolution (Rank 100 for path choice)")
                        : (rank >= 40
                            ? tr("Ultimate schopnost (Rank 75 pro 3. spell)", "Ultimate ability (Rank 75 for 3rd spell)")
                            : (rank >= 15 ? tr("1. schopnost aktivní (Rank 40, 75, 100)", "1st ability active (Rank 40, 75, 100)") : tr("Rank 15, 40, 75, 100 pro spelly", "Rank 15, 40, 75, 100 for spells"))))) +
                (isCurrent && state.paragonLevel > 0 ? tr("\nParagon ${state.paragonLevel} (+${state.paragonLevel * 10}% na klíčové staty z itemů)", "\nParagon ${state.paragonLevel} (+${state.paragonLevel * 10}% to key stats from items)") : "") +
                (state.rankGainMultiplierFor(selected) > 1.0 ? tr("\n⚡ Alt catch-up: rank roste +${((state.rankGainMultiplierFor(selected) - 1) * 100).round()}% rychleji (za každých 100 Paragon dosažených na libovolné třídě účtu)", "\n⚡ Alt catch-up: rank grows +${((state.rankGainMultiplierFor(selected) - 1) * 100).round()}% faster (for every 100 Paragon reached on any class on this account)") : ""),
            style: TextStyle(color: rank >= 100 ? Colors.redAccent : (rank >= 75 ? Colors.purpleAccent : (rank >= 40 ? Colors.purple : (rank >= 15 ? Colors.green : Colors.grey)))),
          ),
          const SizedBox(height: 8),
          // ===== 1×/10×/Max vedle sebe - dřív jen "Vylepšit" (1×) a "Max" nad sebou. 10× nemá
          // vlastní GameState metodu, takže volá upgradeClass v cyklu (stejně jako by to dělal
          // hráč 10× po sobě), s kontrolou krystalů před každým voláním. =====
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  onPressed: state.crystals >= 50 ? () => state.upgradeClass(selected) : null,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('1×', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('50 💎', style: TextStyle(fontSize: 11)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent.shade700, padding: const EdgeInsets.symmetric(vertical: 10)),
                  onPressed: state.crystals >= 500
                      ? () {
                          for (int i = 0; i < 10 && state.crystals >= 50; i++) {
                            state.upgradeClass(selected);
                          }
                        }
                      : null,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('10×', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    const Text('500 💎', style: TextStyle(fontSize: 11, color: Colors.black)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69214), padding: const EdgeInsets.symmetric(vertical: 10)),
                  onPressed: state.crystals >= 50 ? () => state.upgradeClassMax(selected) : null,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Max', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('(${state.crystals ~/ 50}×)', style: const TextStyle(fontSize: 11, color: Colors.black)),
                  ]),
                ),
              ),
            ],
          ),
          if (isCurrent && rank >= 100) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                border: Border.all(color: const Color(0xFFFF8000)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.military_tech, color: Color(0xFFFF8000)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.rank100Choice > 0
                          ? tr('Rank 100 cesta zvolena: ${spellVisualTier4(selected, state.rank100Choice).name} (viz Profil).', 'Rank 100 path chosen: ${spellVisualTier4(selected, state.rank100Choice).name} (see Profile).')
                          : tr('Rank 100 odemčeno! Volbu pokročilé cesty najdeš v Profilu vedle specializace.', 'Rank 100 unlocked! You can choose your advanced path in Profile next to your specialization.'),
                      style: const TextStyle(color: Color(0xFFFF8000), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool showPotions = false; // false = záložka Vybavení, true = záložka Lektvary
  String selectedRarity = "Vše";
  EquipSlot? selectedSlot; // null = Vše - filtr na konkrétní slot (např. jen zbraně)
  bool setOnly = false; // jen SET (zelené i hardcore) vybavení
  String sortBy = "Nejnovější"; // řazení seznamu - viz _sortItems()
  int gridColumns = 4; // počet sloupců gridu v Batohu (4 nebo 5) - viz _gearGrid
  bool useGridView = true; // true = nový grid ikon, false = původní seznam - přepínatelné hráčem

  List<Item> _sortItems(GameState state, List<Item> items) {
    final sorted = List<Item>.from(items);
    switch (sortBy) {
      case "Síla":
        sorted.sort((a, b) => state.itemPowerScore(b).compareTo(state.itemPowerScore(a)));
        break;
      case "Hodnota":
        sorted.sort((a, b) => b.value.compareTo(a.value));
        break;
      case "Vzácnost":
        sorted.sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
        break;
      default:
        break; // "Nejnovější" = pořadí beze změny (inventář je přirozeně řazen dle získání)
    }
    return sorted;
  }

  // Odznak "je tohle lepší než co mám nasazené ve stejném slotu?" - hlavní důvod celé úpravy:
  // hráč dřív musel ručně počítat staty, aby zjistil, jestli se vyplatí item vyměnit.
  Widget? _comparisonBadge(GameState state, Item item) {
    if (item.isConsumable || item.slot == null || item.isActive) return null;
    final myScore = state.itemPowerScore(item);
    final equippedScore = state.weakestEquippedScoreForSlot(item.slot);
    if (equippedScore == null) {
      return _badge(tr('NOVÝ SLOT', 'NEW SLOT'), Colors.lightBlueAccent, Icons.fiber_new);
    }
    final diff = myScore - equippedScore;
    if (diff > 0) return _badge(tr('LEPŠÍ (+$diff)', 'BETTER (+$diff)'), Colors.greenAccent, Icons.arrow_upward);
    if (diff < 0) return _badge(tr('HORŠÍ ($diff)', 'WORSE ($diff)'), Colors.redAccent.shade100, Icons.arrow_downward);
    return _badge(tr('STEJNÉ', 'SAME'), Colors.grey, Icons.horizontal_rule);
  }

  Widget _badge(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color, width: 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      );

  // Popis set bonusu přímo na itemu - jen pro běžné (zelené) SET vybavení (viz GameState.gearSets).
  // Hardcore SET má vlastní panel v Profilu, tady zůstává jen textová nálepka (HARDCORE SET).
  Widget _setBonusInfo(GameState state, Item item) {
    if (item.setId == null) return const SizedBox.shrink();
    final matches = state.gearSets.where((s) => s.id == item.setId);
    if (matches.isEmpty) return const SizedBox.shrink();
    final def = matches.first;
    final count = state.equippedSetCounts[def.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        "${def.name} ($count/8) — (2) ${def.twoPieceDesc} (4) ${def.fourPieceDesc} (6) ${def.sixPieceDesc} (8) ${def.eightPieceDesc}",
        style: const TextStyle(color: Color(0xFF00E676), fontSize: 11),
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) => Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: active ? const Color(0xFFC69214) : Colors.grey.shade800),
          onPressed: onTap,
          child: Text(label, style: TextStyle(color: active ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      List<Item> filteredItems = state.inventory.where((item) {
        if (item.isConsumable != showPotions) return false;
        if (item.isActive) return false; // nasazené vybavení nezabírá místo v Batohu, viz "Nasazené vybavení" jinde
        if (!showPotions) {
          if (selectedRarity == "Common" && item.rarity != Rarity.common) return false;
          if (selectedRarity == "Rare" && item.rarity != Rarity.rare) return false;
          if (selectedRarity == "Epic" && item.rarity != Rarity.epic) return false;
          if (selectedRarity == "Legendary" && item.rarity != Rarity.legendary) return false;
          if (selectedSlot != null && item.slot != selectedSlot) return false;
          if (setOnly && item.setId == null && item.hardcoreSetId == null && item.predpekliSetId == null && item.pekloSetId == null) return false;
        }
        return true;
      }).toList();
      if (!showPotions) filteredItems = _sortItems(state, filteredItems);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== HLAVIČKA: kapacita + tlačítko zvětšit vedle sebe (dřív odděleně - číslo
          // nahoře, tlačítko až pod scénou s postavou). Číslo a akce, co ho mění, patří k
          // sobě, takže je hráč vidí naráz bez scrollování. =====
          Row(
            children: [
              Expanded(
                child: Text(
                  tr("Batoh (${state.bagItemCount}/${state.maxInventorySize})", "Bag (${state.bagItemCount}/${state.maxInventorySize})"),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFB100)),
                ),
              ),
              Tooltip(
                message: tr("Zvětšit batoh (+5 míst, ${(state.maxInventorySize - 15) * 50} 🪙)", "Expand bag (+5 slots, ${(state.maxInventorySize - 15) * 50} 🪙)"),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.add_box_outlined, color: Color(0xFFFFB100), size: 22),
                  onPressed: state.upgradeInventoryCapacity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ===== ZÁLOŽKY: Vybavení / Lektvary (samostatná záložka, ne společný filtr) =====
          Row(children: [
            _tabButton(tr("⚔ Vybavení", "⚔ Gear"), !showPotions, () => setState(() => showPotions = false)),
            const SizedBox(width: 8),
            _tabButton(tr("🧪 Lektvary", "🧪 Potions"), showPotions, () => setState(() => showPotions = true)),
          ]),
          const SizedBox(height: 15),
          if (!showPotions) ...[
          // Malovaná scéna postavy s 12 ornamentálními rámy (inventory_bg.png) místo dřívějšího
          // vodorovného seznamu ikon - viz konverzace o Copilot promptu pro Batoh. Nahrazuje
          // "NASAZENÉ VYBAVENÍ" i pro prázdný stav (rámy jsou vidět prázdné přímo na obrázku,
          // takže tady na rozdíl od dřívějška netřeba `if (equippedItems.isEmpty) return...`).
          EquippedGearScene(state: state, onItemTap: (ctx, item) => _showItemDetailDialog(ctx, state, item)),
          const SizedBox(height: 15),
          // ===== AUTO-OBLÉKNUTÍ + ZÁMKY - zkompaktněné na dvě tlačítka vedle sebe (dřív dva
          // velké boxy s trvale vypsaným popisem). Popis teď nese tooltip (podržení/hover),
          // hlavní akce je pořád jedno ťuknutí. =====
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: tr("Nasadí nejsilnější kusy z batohu do každého slotu.", "Equips the strongest pieces from your bag into each slot."),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.tealAccent, side: const BorderSide(color: Colors.tealAccent), padding: const EdgeInsets.symmetric(vertical: 10)),
                    icon: const Icon(Icons.bolt, size: 18),
                    onPressed: state.autoEquipBestGear,
                    label: Text(tr("Auto-obléknutí", "Auto-equip"), overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: tr("Chrání i item v batohu, co zrovna nemáš nasazený.", "Also protects a bag item you don't currently have equipped."),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC69214), side: const BorderSide(color: Color(0xFFC69214)), padding: const EdgeInsets.symmetric(vertical: 10)),
                    icon: const Icon(Icons.lock, size: 18),
                    onPressed: state.unlockedLockSlots < GameState.maxLockSlots ? () => state.unlockLockSlot() : null,
                    label: Text(
                      state.unlockedLockSlots < GameState.maxLockSlots
                          ? tr("Zámky ${state.lockedItemCount}/${state.unlockedLockSlots} (${state.nextLockSlotCost} 🪙)", "Locks ${state.lockedItemCount}/${state.unlockedLockSlots} (${state.nextLockSlotCost} 🪙)")
                          : tr("Zámky ${state.lockedItemCount}/${state.unlockedLockSlots} (max)", "Locks ${state.lockedItemCount}/${state.unlockedLockSlots} (max)"),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ], // konec "if (!showPotions)" bloku pro nasazené vybavení + batoh akce
          const Divider(height: 30, thickness: 2),
          if (!showPotions) ...[
            // ===== FILTRY - zkompaktněné na jeden vodorovně scrollovatelný pruh chipů
            // (rarity + SET, nejčastěji používané), zbytek (slot, řazení, sloupce, zobrazení)
            // je za ikonou "více filtrů" v bottom sheetu - dřív to všechno bylo v jednom Wrap,
            // co se na mobilu lámal do 2-3 řádků. =====
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final r in ["Vše", "Common", "Rare", "Epic", "Legendary"])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(r == "Vše" ? tr("Vše", "All") : r),
                              selected: selectedRarity == r,
                              onSelected: (_) => setState(() => selectedRarity = r),
                              selectedColor: const Color(0xFFFFB100),
                              labelStyle: TextStyle(color: selectedRarity == r ? Colors.black : const Color(0xFFF1E6D0), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(tr("Jen SET", "SET only")),
                            selected: setOnly,
                            onSelected: (v) => setState(() => setOnly = v),
                            selectedColor: const Color(0xFF00E676),
                            checkmarkColor: Colors.black,
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tr("Více filtrů", "More filters"),
                  icon: const Icon(Icons.tune, color: Color(0xFFFFB100)),
                  onPressed: () => _showMoreFiltersSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (showPotions)
            ...filteredItems.map((item) => _potionListTile(context, state, item))
          else if (useGridView)
            _gearGrid(context, state, filteredItems)
          else
            ...filteredItems.map((item) => _gearListTile(context, state, item)),
        ],
      );
    });
  }

  // ===== Bottom sheet s méně používanými filtry/zobrazovacími volbami (slot, řazení, počet
  // sloupců, grid/list) - přesunuté sem z hlavního Wrap, aby nebyly pořád vidět. StatefulBuilder
  // uvnitř, protože sheet žije mimo stromu _InventoryScreenState.build (setState by ho jinak
  // nepřekreslil, dokud by se znovu neotevřel). =====
  void _showMoreFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr("Více filtrů", "More filters"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFB100))),
              const SizedBox(height: 16),
              Text(tr("Slot:", "Slot:"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1E6D0))),
              const SizedBox(height: 6),
              DropdownButton<EquipSlot?>(
                isExpanded: true,
                value: selectedSlot,
                dropdownColor: const Color(0xFF1E1E24),
                style: const TextStyle(color: Color(0xFFFFB100)),
                items: [
                  DropdownMenuItem<EquipSlot?>(value: null, child: Text(tr("Vše (sloty)", "All (slots)"))),
                  ...EquipSlot.values.map((s) => DropdownMenuItem<EquipSlot?>(value: s, child: Text(slotDisplayName(s)))),
                ],
                onChanged: (EquipSlot? v) {
                  setState(() => selectedSlot = v);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 14),
              Text(tr("Řadit:", "Sort:"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1E6D0))),
              const SizedBox(height: 6),
              DropdownButton<String>(
                isExpanded: true,
                value: sortBy,
                dropdownColor: const Color(0xFF1E1E24),
                style: const TextStyle(color: Color(0xFFFFB100)),
                items: ["Nejnovější", "Síla", "Hodnota", "Vzácnost"].map((String r) {
                  const labels = {"Nejnovější": "Newest", "Síla": "Power", "Hodnota": "Value", "Vzácnost": "Rarity"};
                  return DropdownMenuItem<String>(value: r, child: Text(tr(r, labels[r]!)));
                }).toList(),
                onChanged: (String? v) {
                  if (v == null) return;
                  setState(() => sortBy = v);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(tr("Sloupců:", "Columns:"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF1E6D0))),
                  const SizedBox(width: 10),
                  ToggleButtons(
                    isSelected: [gridColumns == 4, gridColumns == 5],
                    onPressed: (i) {
                      setState(() => gridColumns = i == 0 ? 4 : 5);
                      setSheetState(() {});
                    },
                    borderRadius: BorderRadius.circular(6),
                    selectedColor: Colors.black,
                    fillColor: const Color(0xFFFFB100),
                    color: const Color(0xFFF1E6D0),
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 30),
                    children: const [Text('4'), Text('5')],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: useGridView ? tr("Přepnout na seznam", "Switch to list") : tr("Přepnout na grid", "Switch to grid"),
                    icon: Icon(useGridView ? Icons.view_list : Icons.grid_view, color: const Color(0xFFFFB100)),
                    onPressed: () {
                      setState(() => useGridView = !useGridView);
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ===== BATOH: LEKTVARY (zůstává jako seznam - málo typů, tlačítko "Použít" chce být hned vidět) =====
  Widget _potionListTile(BuildContext context, GameState state, Item item) {
    String statsText = tr("Počet: ${item.stackCount}", "Count: ${item.stackCount}");
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: rarityCardGlow(item.rarityVisual)),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: item.rarityColor, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: FantasyIconFrame(type: item.iconType, rarity: item.rarityVisual, size: 40, interactive: false),
          title: Text("${item.name} (x${item.stackCount})", style: TextStyle(color: item.rarityColor, fontWeight: FontWeight.bold)),
          subtitle: Text(statsText, style: const TextStyle(color: Colors.grey)),
          trailing: ElevatedButton(
            onPressed: () => state.useItem(item),
            child: Text(tr("Použít", "Use")),
          ),
        ),
      ),
    );
  }

  // ===== BATOH: VYBAVENÍ - PŮVODNÍ ZOBRAZENÍ (plný řádek se vším rovnou vypsaným, beze
  // stavu grid/dialog) - zachováno jako alternativa pro hráče, kterým grid nevyhovuje.
  Widget _gearListTile(BuildContext context, GameState state, Item item) {
    String statsText = item.stats.keys.map((k) => "${statLabel(k)} +${((item.stats[k] ?? 0) * item.upgradeMultiplier * state.setSlotUpgradeMultiplier(item)).round()}").join(", ");
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: rarityCardGlow(item.rarityVisual)),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: item.isLocked ? const Color(0xFFC69214) : item.rarityColor, width: item.isLocked ? 2 : 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: FantasyIconFrame(type: item.iconType, rarity: item.rarityVisual, size: 40, interactive: false),
          title: Text(
            "${item.isLocked ? '🔒 ' : ''}${item.name}${item.upgradeLevel > 0 ? ' +${item.upgradeLevel}' : ''}${state.setSlotUpgradeLevel(item) > 0 ? ' (mat +${state.setSlotUpgradeLevel(item)})' : ''}"
            "${item.pekloSetId != null ? ' (${state.equippedPekloSetCounts[item.pekloSetId] ?? 0}/8)' : (item.predpekliSetId != null ? ' (${state.equippedPredpekliSetCounts[item.predpekliSetId] ?? 0}/8)' : (item.hardcoreSetId != null ? ' (${state.equippedHardcoreSetCounts[item.hardcoreSetId] ?? 0}/8)' : ''))}",
            style: TextStyle(color: item.rarityColor, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${item.slot != null ? '[${slotDisplayName(item.slot)}]${item.setId != null ? ' (SET)' : ''}${item.pekloSetId != null ? ' (PEKLO SET)' : (item.predpekliSetId != null ? ' (PŘEDPEKLÍ SET)' : (item.hardcoreSetId != null ? ' (HARDCORE SET)' : ''))} ' : ''}$statsText | Hodnota: ${item.value}"
                "${item.gemSlotCount > 0 ? ' | Gemy: ${item.gemSlots.where((g) => g != null).length}/${item.gemSlotCount} (${item.gemSlots.where((g) => g != null).join(', ')})' : ''}",
                style: TextStyle(color: item.pekloSetId != null ? const Color(0xFFFF3D00) : (item.predpekliSetId != null ? const Color(0xFFB026FF) : (item.hardcoreSetId != null ? const Color(0xFF00F0FF) : (item.setId != null ? const Color(0xFF00E676) : Colors.grey)))),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if (item.slot == EquipSlot.relic) ...[
                    _badge('Relic Lv ${state.specRelicLevels[item.specRelicKey] ?? 0}', Colors.amberAccent, Icons.bolt),
                    _badge('Dmg +${((state.specRelicLevels[item.specRelicKey] ?? 0) * 2.5).round()} %', Colors.lightBlueAccent, Icons.stairs),
                  ] else ...[
                    _badge('SÍLA ${state.itemPowerScore(item)}', Colors.amberAccent, Icons.bolt),
                    _badge('iLvl ${state.itemLevelScore(item)}', Colors.lightBlueAccent, Icons.stairs),
                    if (_comparisonBadge(state, item) != null) _comparisonBadge(state, item)!,
                  ],
                ]),
              ),
              _setBonusInfo(state, item),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: item.isLocked ? tr("Odemknout", "Unlock") : tr("Uzamknout (ochrání před smrtí)", "Lock (protects from death)"),
                icon: Icon(item.isLocked ? Icons.lock : Icons.lock_open, color: item.isLocked ? const Color(0xFFC69214) : Colors.grey),
                onPressed: () => state.toggleItemLock(item),
              ),
              IconButton(
                icon: Icon(item.isActive ? Icons.check_box : Icons.check_box_outline_blank, color: item.rarityColor),
                onPressed: () => state.toggleItemActive(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== BATOH: VYBAVENÍ (grid ikon - řeší dlouhé rolování při 100+ itemech). 4 nebo 5 sloupců
  // (přepínatelné, viz gridColumns), dvojklik/dlouhý tap otevře detail se všemi staty (stejný
  // obsah, jaký dřív ukazoval rozbalený ListTile).
  Widget _gearGrid(BuildContext context, GameState state, List<Item> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text(tr("Žádné předměty v batohu.", "No items in the bag."), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridColumns, crossAxisSpacing: 10, mainAxisSpacing: 12, childAspectRatio: 1),
      itemBuilder: (context, index) => _gearGridTile(context, state, items[index]),
    );
  }

  Widget _gearGridTile(BuildContext context, GameState state, Item item) {
    int? diff;
    if (item.slot != null && !item.isActive) {
      final myScore = state.itemPowerScore(item);
      final equippedScore = state.weakestEquippedScoreForSlot(item.slot);
      if (equippedScore != null) diff = myScore - equippedScore;
    }
    return GestureDetector(
      onDoubleTap: () => _showItemDetailDialog(context, state, item),
      onLongPress: () => _showItemDetailDialog(context, state, item), // pohodlnější na mobilu než přesný dvojklik
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: item.isLocked ? const Color(0xFFC69214) : item.rarityColor, width: item.isLocked ? 2 : 1.2),
          boxShadow: rarityCardGlow(item.rarityVisual),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: FantasyIconFrame(type: item.iconType, rarity: item.rarityVisual, size: 44, interactive: false)),
            if (item.isActive)
              const Positioned(top: 3, left: 3, child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 14)),
            if (item.isLocked)
              const Positioned(bottom: 3, left: 3, child: Icon(Icons.lock, color: Color(0xFFC69214), size: 13)),
            // Srovnání se stejným nasazeným slotem: zelená šipka nahoru vpravo nahoře (upgrade),
            // červená šipka dolů vpravo dole (downgrade). Bez šipky = stejná síla nebo nový slot.
            if (diff != null && diff > 0) const Positioned(top: -5, right: -5, child: _GridCompareArrow(up: true)),
            if (diff != null && diff < 0) const Positioned(bottom: -5, right: -5, child: _GridCompareArrow(up: false)),
          ],
        ),
      ),
    );
  }

  // Detail itemu z gridu - stejné informace, jaké dřív zobrazoval plný ListTile (staty, síla,
  // set bonus, zámek/nasazení), teď v dialogu na dvojklik/podržení místo věčně vypsaného řádku.
  void _showItemDetailDialog(BuildContext context, GameState state, Item item) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer<GameState>(
        builder: (context, liveState, _) {
          String statsText = item.stats.keys.map((k) => "${statLabel(k)} +${((item.stats[k] ?? 0) * item.upgradeMultiplier * liveState.setSlotUpgradeMultiplier(item)).round()}").join(", ");
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E24),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: item.isLocked ? const Color(0xFFC69214) : item.rarityColor, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            title: Row(
              children: [
                FantasyIconFrame(type: item.iconType, rarity: item.rarityVisual, size: 40, interactive: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${item.name}${item.upgradeLevel > 0 ? ' +${item.upgradeLevel}' : ''}${liveState.setSlotUpgradeLevel(item) > 0 ? ' (mat +${liveState.setSlotUpgradeLevel(item)})' : ''}",
                    style: TextStyle(color: item.rarityColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${item.slot != null ? '[${slotDisplayName(item.slot)}]${item.setId != null ? ' (SET)' : ''}${item.pekloSetId != null ? ' (PEKLO SET)' : (item.predpekliSetId != null ? ' (PŘEDPEKLÍ SET)' : (item.hardcoreSetId != null ? ' (HARDCORE SET)' : ''))} ' : ''}$statsText | Hodnota: ${item.value}"
                    "${item.gemSlotCount > 0 ? ' | Gemy: ${item.gemSlots.where((g) => g != null).length}/${item.gemSlotCount} (${item.gemSlots.where((g) => g != null).join(', ')})' : ''}",
                    style: TextStyle(color: item.pekloSetId != null ? const Color(0xFFFF3D00) : (item.predpekliSetId != null ? const Color(0xFFB026FF) : (item.hardcoreSetId != null ? const Color(0xFF00F0FF) : (item.setId != null ? const Color(0xFF00E676) : Colors.grey)))),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      if (item.slot == EquipSlot.relic) ...[
                        _badge('Relic Lv ${liveState.specRelicLevels[item.specRelicKey] ?? 0}', Colors.amberAccent, Icons.bolt),
                        _badge('Dmg +${((liveState.specRelicLevels[item.specRelicKey] ?? 0) * 2.5).round()} %', Colors.lightBlueAccent, Icons.stairs),
                      ] else ...[
                        _badge('SÍLA ${liveState.itemPowerScore(item)}', Colors.amberAccent, Icons.bolt),
                        _badge('iLvl ${liveState.itemLevelScore(item)}', Colors.lightBlueAccent, Icons.stairs),
                        if (_comparisonBadge(liveState, item) != null) _comparisonBadge(liveState, item)!,
                      ],
                    ]),
                  ),
                  _setBonusInfo(liveState, item),
                ],
              ),
            ),
            actions: [
              IconButton(
                tooltip: item.isLocked ? tr("Odemknout", "Unlock") : tr("Uzamknout (ochrání před smrtí)", "Lock (protects from death)"),
                icon: Icon(item.isLocked ? Icons.lock : Icons.lock_open, color: item.isLocked ? const Color(0xFFC69214) : Colors.grey),
                onPressed: () => liveState.toggleItemLock(item),
              ),
              IconButton(
                tooltip: item.isActive ? tr("Sundat", "Unequip") : tr("Nasadit", "Equip"),
                icon: Icon(item.isActive ? Icons.check_box : Icons.check_box_outline_blank, color: item.rarityColor),
                onPressed: () => liveState.toggleItemActive(item),
              ),
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(tr("Zavřít", "Close"))),
            ],
          );
        },
      ),
    );
  }
}

// "Je tohle lepší/horší než co mám nasazené?" - malý kroužek se šipkou přes roh ikony v gridu
// batohu. Zelená nahoru vpravo NAHOŘE = upgrade, červená dolů vpravo DOLE = downgrade.
class _GridCompareArrow extends StatelessWidget {
  final bool up;
  const _GridCompareArrow({required this.up});
  @override
  Widget build(BuildContext context) {
    final color = up ? Colors.greenAccent : Colors.redAccent;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: const Color(0xFF15151A), shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)),
      child: Icon(up ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 12),
    );
  }
}

// ===== BANKA — trvalé úložiště napříč buildem/třídou. Dvě záložky: co jde ULOŽIT (z inventáře)
// a co jde VYTÁHNOUT (z banky zpět do inventáře). Řeší "přerolloval jsem z DK na Mnicha a
// DK vybavení je najednou k ničemu" - místo prodeje/roztavení jde uložit stranou.
class KronikaScreen extends StatefulWidget {
  const KronikaScreen({super.key});
  @override
  State<KronikaScreen> createState() => _KronikaScreenState();
}

class _KronikaScreenState extends State<KronikaScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _diffLabels = ['Normal', 'Hardcore', 'Předpeklí', 'Peklo'];
  static const List<Color> _diffColors = [Colors.grey, Color(0xFFFF7043), Color(0xFFAB47BC), Color(0xFFD32F2F)];
  static List<String> get _dailyGoalLabels => [tr('Poraz/vyzvi World Bosse', 'Defeat/challenge World Bosses'), tr('Dokonči jeden Rift', 'Complete one Rift'), tr('Dokonči Daily Quest', 'Complete Daily Quest'), tr('Poraz bosse pro Runovou výzvu', 'Defeat a boss for the Rune Challenge')];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    RewardedAdService.instance.preload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _kronikaTab(GameState state) {
    final floors = List.generate(100, (i) => i + 1);
    final discovered = floors.where((f) => state.chronicleUnlockedCount(f) > 0).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          tr("Sbírka útržků příběhů bossů z Doupěte. Poraz bosse na dané obtížnosti, ať je útržek "
          "rollovatelný (záložka Roll) - celý příběh (4/4) sesbíráš, jen když ho vyrolluješ ze všech 4 obtížností. Čistě k přečtení - žádný vliv na postup.",
          "A collection of boss story fragments from the Lair. Defeat a boss on a given difficulty to make its "
          "fragment rollable (Roll tab) - you only collect the full story (4/4) once you roll it from all 4 difficulties. Purely for reading - no effect on progress."),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF241A38), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF8B5CF6))),
          child: Text(
            tr("Kompletní příběhy: ${state.chronicleCompletedBossCount} / ${state.chronicleTotalBossCount} • Objeveno: ${discovered.length} / ${state.chronicleTotalBossCount}", "Complete stories: ${state.chronicleCompletedBossCount} / ${state.chronicleTotalBossCount} • Discovered: ${discovered.length} / ${state.chronicleTotalBossCount}"),
            style: const TextStyle(color: Color(0xFFB794F6), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        if (discovered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(tr("Zatím nemáš žádný útržek. Poraz bosse v Doupěti a zkus roll v druhé záložce.", "You do not have any fragments yet. Defeat a boss in the Lair and try rolling in the second tab."), style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ),
        ...discovered.map((floor) {
          final bossInfo = state.getBossDetails(floor);
          final unlockedCount = state.chronicleUnlockedCount(floor);
          final isComplete = unlockedCount == 4;
          return Card(
            color: isComplete ? const Color(0xFF241A38) : const Color(0xFF1E1E24),
            shape: RoundedRectangleBorder(side: BorderSide(color: isComplete ? const Color(0xFF8B5CF6) : const Color(0xFF49341F)), borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => KronikaReaderScreen(discoveredFloors: discovered, initialFloor: floor),
              )),
              leading: Icon(Icons.menu_book, color: isComplete ? const Color(0xFFB794F6) : const Color(0xFF8A7A5C)),
              title: Text(tr("Patro $floor: ${bossInfo['name']}", "Floor $floor: ${bossInfo['name']}"), style: TextStyle(fontWeight: FontWeight.bold, color: isComplete ? const Color(0xFFB794F6) : Colors.white)),
              subtitle: Text(isComplete ? tr("Příběh kompletní ✨ · klepni pro čtení", "Story complete ✨ · tap to read") : tr("$unlockedCount / 4 částí · klepni pro čtení", "$unlockedCount / 4 parts · tap to read"), style: TextStyle(color: isComplete ? const Color(0xFF00E676) : Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          );
        }),
      ],
    );
  }

  Widget _rollTab(GameState state) {
    final rolledFloor = state.lastRolledFloor;
    final rolledDiff = state.lastRolledDifficultyIndex;
    String? revealText;
    String? revealBossName;
    if (rolledFloor != null && rolledDiff != null) {
      final parts = state.bossChronicleParts(rolledFloor);
      if (parts != null && rolledDiff < parts.length) {
        revealText = parts[rolledDiff];
        revealBossName = tr("Patro $rolledFloor: ${state.getBossDetails(rolledFloor)['name']} (${_diffLabels[rolledDiff]})", "Floor $rolledFloor: ${state.getBossDetails(rolledFloor)['name']} (${_diffLabels[rolledDiff]})");
      }
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF241A38), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF8B5CF6))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Text(tr("🪙 ${state.fateCoins} Mincí Osudu", "🪙 ${state.fateCoins} Coins of Fate"), style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              const SizedBox(height: 6),
              Text(tr("Čeká na vyrollování: ${state.chronicleRollablePartsCount} útržků", "Waiting to be rolled: ${state.chronicleRollablePartsCount} fragments"), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (revealText != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFD700), width: 1.4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📜 $revealBossName", style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Text(revealText, style: const TextStyle(color: Color(0xFFF1E6D0), fontStyle: FontStyle.italic, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: state.canRollChronicle ? state.rollChronicle : null,
            icon: const Icon(Icons.casino),
            label: Text(tr("Roll (1 🪙)", "Roll (1 🪙)"), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        if (!state.canRollChronicle)
          Text(
            state.chronicleRollablePartsCount == 0
                ? tr("Nemáš co rollovat - poraz dalšího bosse v Doupěti.", "Nothing to roll - defeat another boss in the Lair.")
                : tr("Nemáš dost Mincí Osudu - přejdi na záložku Mince Osudu.", "Not enough Coins of Fate - go to the Coins of Fate tab."),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
      ],
    );
  }

  Widget _coinsTab(GameState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF241A38), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF8B5CF6))),
          child: Text(tr("🪙 Máš ${state.fateCoins} Mincí Osudu", "🪙 You have ${state.fateCoins} Coins of Fate"), style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 20),
        Text(tr("Sledování reklamy", "Watching ads"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFB100), fontSize: 15)),
        const SizedBox(height: 4),
        Text(tr("Neomezené - kolikrát chceš, tolikrát +1 Mince Osudu.", "Unlimited - as many times as you want, +1 Coin of Fate each time."), style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => RewardedAdService.instance.show(onReward: () => state.grantFateCoinFromAd()),
            icon: const Icon(Icons.play_circle_fill),
            label: Text(tr("Zhlédnout reklamu (+1 🪙)", "Watch ad (+1 🪙)"), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
        Text(tr("Denní cíle", "Daily goals"), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFB100), fontSize: 15)),
        const SizedBox(height: 4),
        Text(tr("Za každý poprvé splněný denní cíl +1 Mince Osudu.", "You get +1 Coin of Fate for each daily goal completed for the first time."), style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        ...List.generate(4, (i) {
          final done = [state.dailyWorldBossDone, state.dailyRiftDone, state.dailyQuestDone, state.dailyRuneDone][i];
          final claimed = state.dailyGoalCoinsClaimed.contains(i);
          return Card(
            color: const Color(0xFF1E1E24),
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: Icon(claimed ? Icons.monetization_on : (done ? Icons.check_circle : Icons.radio_button_unchecked), color: claimed ? const Color(0xFFFFD700) : (done ? Colors.greenAccent : Colors.grey)),
              title: Text(_dailyGoalLabels[i], style: const TextStyle(fontSize: 13)),
              trailing: Text(claimed ? tr("+1 🪙 vyzvednuto", "+1 🪙 claimed") : (done ? tr("čeká na odečet", "waiting to be claimed") : tr("nesplněno", "not completed")), style: TextStyle(color: claimed ? const Color(0xFFFFD700) : Colors.grey, fontSize: 11)),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      return Column(
        children: [
          Container(
            color: const Color(0xFF1A1424),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFFB100),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFFB100),
              tabs: [
                Tab(text: tr("Kronika", "Chronicle")),
                const Tab(text: "Roll"),
                Tab(text: tr("Mince Osudu", "Coins of Fate")),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _kronikaTab(state),
                _rollTab(state),
                _coinsTab(state),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ===== KRONIKA - READING MODE =====
// Plnohodnotná, knižně stylizovaná obrazovka pro čtení jednoho příběhu - odděleně od
// přehledového seznamu v KronikaScreen (ten slouží jen jako rozcestník/stav sbírky).
// Navigace: šipky nahoře přepínají mezi objevenými bossy, barevné "kapitoly" pod jménem
// bosse přepínají mezi 4 obtížnostmi/díly aktuálního příběhu.
class KronikaReaderScreen extends StatefulWidget {
  final List<int> discoveredFloors;
  final int initialFloor;
  const KronikaReaderScreen({super.key, required this.discoveredFloors, required this.initialFloor});

  @override
  State<KronikaReaderScreen> createState() => _KronikaReaderScreenState();
}

class _KronikaReaderScreenState extends State<KronikaReaderScreen> {
  late int _bossIndex;
  late int _chapterIndex;

  static const List<String> _diffLabels = ['Normal', 'Hardcore', 'Předpeklí', 'Peklo'];
  static const List<Color> _diffColors = [Colors.grey, Color(0xFFFF7043), Color(0xFFAB47BC), Color(0xFFD32F2F)];

  @override
  void initState() {
    super.initState();
    _bossIndex = widget.discoveredFloors.indexOf(widget.initialFloor);
    if (_bossIndex < 0) _bossIndex = 0;
    _chapterIndex = 0;
  }

  void _goToBoss(int newIndex, GameState state) {
    if (newIndex < 0 || newIndex >= widget.discoveredFloors.length) return;
    setState(() {
      _bossIndex = newIndex;
      final floor = widget.discoveredFloors[_bossIndex];
      // Otevři rovnou na první přečtené kapitole toho nového bosse, ne vždycky na Normal.
      int firstOwned = 0;
      for (int i = 0; i < 4; i++) {
        if (state.isChroniclePartOwned(floor, i)) { firstOwned = i; break; }
      }
      _chapterIndex = firstOwned;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      final floor = widget.discoveredFloors[_bossIndex];
      final bossInfo = state.getBossDetails(floor);
      final parts = state.bossChronicleParts(floor) ?? const [];
      final owned = state.isChroniclePartOwned(floor, _chapterIndex);
      final eligible = state.isChroniclePartEligible(floor, _chapterIndex);
      final String pageText;
      if (owned && _chapterIndex < parts.length) {
        pageText = parts[_chapterIndex];
      } else if (eligible) {
        pageText = tr("Tahle stránka ještě čeká na roll v Kronice. Útržek už máš rozlousknutý porážkou bosse - jen ho zatím nemáš v ruce.", "This page is still waiting to be rolled in the Chronicle. You have already unlocked the fragment by defeating the boss - you just do not have it in hand yet.");
      } else {
        pageText = tr("Tahle stránka je prázdná. Aby se popsala, musíš bosse nejdřív porazit na obtížnosti ${_diffLabels[_chapterIndex]}.", "This page is empty. To fill it in, you must first defeat the boss on ${_diffLabels[_chapterIndex]} difficulty.");
      }
      return Scaffold(
        backgroundColor: const Color(0xFF120D18),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(center: Alignment.topCenter, radius: 1.6, colors: [Color(0xFF2A1E38), Color(0xFF120D18)]),
            ),
            child: Column(
              children: [
                // Horní lišta: zavřít + přepínání bosse
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.of(context).pop()),
                      Expanded(
                        child: Text(tr("${_bossIndex + 1} / ${widget.discoveredFloors.length} objevených", "${_bossIndex + 1} / ${widget.discoveredFloors.length} discovered"), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                      const SizedBox(width: 48), // vizuální vyvážení proti close ikoně
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    child: Column(
                      children: [
                        Text(tr("PATRO $floor", "FLOOR $floor"), style: GoogleFonts.cinzel(color: const Color(0xFF8A7A5C), fontSize: 12, letterSpacing: 3)),
                        const SizedBox(height: 6),
                        Text(
                          (bossInfo['name'] ?? '').toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(color: const Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 16),
                        // Kapitoly (obtížnosti) - barevné pilulky, klepnutím se přepne stránka
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: List.generate(4, (i) {
                            final isOwned = state.isChroniclePartOwned(floor, i);
                            final isSelected = i == _chapterIndex;
                            return InkWell(
                              onTap: () => setState(() => _chapterIndex = i),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? _diffColors[i].withOpacity(0.35) : Colors.black.withOpacity(0.25),
                                  border: Border.all(color: isSelected ? _diffColors[i] : Colors.grey.shade800, width: isSelected ? 1.6 : 1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  if (isOwned) Icon(Icons.menu_book, size: 12, color: _diffColors[i]) else const Icon(Icons.lock, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(_diffLabels[i], style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                ]),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        // Samotná "stránka" - pergamenová kartička s textem
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 220),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1520),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _diffColors[_chapterIndex].withOpacity(owned ? 0.9 : 0.3), width: 1.2),
                            boxShadow: [BoxShadow(color: _diffColors[_chapterIndex].withOpacity(owned ? 0.18 : 0), blurRadius: 20, spreadRadius: 1)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(owned ? Icons.auto_stories : Icons.lock_outline, color: owned ? _diffColors[_chapterIndex] : Colors.grey, size: 16),
                                const SizedBox(width: 6),
                                Text(_diffLabels[_chapterIndex], style: TextStyle(color: owned ? _diffColors[_chapterIndex] : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                              ]),
                              const SizedBox(height: 14),
                              Text(
                                pageText,
                                style: GoogleFonts.crimsonText(
                                  color: owned ? const Color(0xFFF1E6D0) : Colors.grey.shade500,
                                  fontStyle: owned ? FontStyle.italic : FontStyle.normal,
                                  fontSize: 19,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Spodní lišta: přepínání mezi bossy (jako listování v knize kapitol)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _bossIndex > 0 ? () => _goToBoss(_bossIndex - 1, state) : null,
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: Text(tr("Předchozí", "Previous")),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _bossIndex < widget.discoveredFloors.length - 1 ? () => _goToBoss(_bossIndex + 1, state) : null,
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: Text(tr("Další", "Next")),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});
  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  final TextEditingController _goldController = TextEditingController();

  @override
  void dispose() {
    _goldController.dispose();
    super.dispose();
  }

  Widget _itemRow(BuildContext context, GameState state, Item item, {required bool inBank}) {
    final statsText = item.stats.entries.map((e) => "${statLabel(e.key)} +${(e.value * item.upgradeMultiplier * state.setSlotUpgradeMultiplier(item)).round()}").join(', ');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: FantasyIconFrame(type: item.iconType, rarity: item.rarityVisual, size: 40, interactive: false),
        title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, color: item.pekloSetId != null ? const Color(0xFFFF3D00) : (item.predpekliSetId != null ? const Color(0xFFB026FF) : (item.hardcoreSetId != null ? const Color(0xFF00F0FF) : (item.setId != null ? const Color(0xFF00E676) : FantasyColors.parchment))))),
        subtitle: Text(
          "${item.slot != null ? '[${slotDisplayName(item.slot)}] ' : ''}$statsText | iLvl ${state.itemLevelScore(item)}",
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        trailing: IconButton(
          icon: Icon(inBank ? Icons.arrow_upward : Icons.arrow_downward, color: inBank ? Colors.greenAccent : Colors.lightBlueAccent),
          tooltip: inBank ? tr('Vytáhnout do inventáře', 'Withdraw to inventory') : tr('Uložit do Banky', 'Deposit to Bank'),
          onPressed: () => inBank ? state.withdrawFromBank(item) : state.depositToBank(item),
        ),
      ),
    );
  }

  // ===== ODEMYKÁNÍ SLOTŮ — vidět nahoře na obou item-tabech (ULOŽIT/VYTÁHNOUT), protože kapacita
  // je relevantní pro obě akce zároveň. Progress bar + tlačítko s cenou dalšího slotu.
  Widget _slotUnlockHeader(GameState state) {
    final full = state.bankUnlockedSlots >= GameState.bankMaxSize;
    final nextCost = full ? 0 : state.bankSlotUnlockCost(state.bankUnlockedSlots + 1);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8), border: Border.all(color: FantasyColors.bronze)),
      child: Column(children: [
        FantasyProgressBar(value: state.bankUnlockedSlots.toDouble(), max: GameState.bankMaxSize.toDouble(), color: FantasyColors.gold, label: tr('ODEMČENÉ SLOTY', 'UNLOCKED SLOTS'), icon: Icons.lock_open),
        const SizedBox(height: 4),
        Text(tr('Platí se z uloženého zlata v trezoru (V trezoru: ${state.bankGold} 🪙)', 'Paid from gold stored in the vault (In vault: ${state.bankGold} 🪙)'), style: const TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.lock_open, size: 16),
            label: Text(full ? tr('Vše odemčeno', 'All unlocked') : tr('Odemknout další slot ($nextCost 🪙 z trezoru)', 'Unlock another slot ($nextCost 🪙 from vault)')),
            onPressed: full || state.bankGold < nextCost ? null : state.unlockNextBankSlot,
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      return DefaultTabController(length: 3, child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Text(
            tr('Trvalé úložiště nezávislé na tvojí aktuální třídě/buildu - itemy i zlato.', 'Permanent storage independent of your current class/build - items and gold.'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        TabBar(
          labelColor: FantasyColors.gold,
          unselectedLabelColor: Colors.grey,
          indicatorColor: FantasyColors.gold,
          tabs: [Tab(text: tr('ULOŽIT (${state.inventory.where((i) => !i.isActive && !i.isConsumable).length})', 'DEPOSIT (${state.inventory.where((i) => !i.isActive && !i.isConsumable).length})')), Tab(text: tr('VYTÁHNOUT (${state.bankItems.length})', 'WITHDRAW (${state.bankItems.length})')), Tab(text: tr('ZLATO', 'GOLD'))],
        ),
        Expanded(child: TabBarView(children: [
          // Co jde uložit - nenasazené, nekonzumovatelné kusy z inventáře.
          Builder(builder: (context) {
            final items = state.inventory.where((i) => !i.isActive && !i.isConsumable).toList();
            return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
              _slotUnlockHeader(state),
              if (items.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(tr('Nic v inventáři, co by šlo uložit.', 'Nothing in your inventory to deposit.'), style: const TextStyle(color: Colors.grey))))
              else
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(children: items.map((i) => _itemRow(context, state, i, inBank: false)).toList())),
            ]);
          }),
          // Co je v Bance - jde vytáhnout zpět do inventáře.
          Builder(builder: (context) {
            return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
              _slotUnlockHeader(state),
              if (state.bankItems.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(tr('Banka je prázdná.', 'The Bank is empty.'), style: const TextStyle(color: Colors.grey))))
              else
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(children: state.bankItems.map((i) => _itemRow(context, state, i, inBank: true)).toList())),
            ]);
          }),
          // Zlatý trezor - deposit/withdraw + pasivní úrok (1 %/den, se stropem).
          Builder(builder: (context) {
            return ListView(padding: const EdgeInsets.all(16), children: [
              FantasyPanel(
                title: tr('ZLATÝ TREZOR', 'GOLD VAULT'), titleIcon: Icons.savings, accent: FantasyColors.gold,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('V trezoru', 'In vault'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${state.bankGold} 🪙', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: FantasyColors.gold)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(tr('U sebe', 'On hand'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${state.gold} 🪙', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    ]),
                  ]),
                  const SizedBox(height: 10),
                  Text(tr('Pasivní úrok: +${(GameState.bankInterestRatePerDay * 100).toStringAsFixed(0)} %/den (strop ${GameState.bankInterestMaxDays} dní) - platí se automaticky při návratu do hry.', 'Passive interest: +${(GameState.bankInterestRatePerDay * 100).toStringAsFixed(0)}%/day (cap ${GameState.bankInterestMaxDays} days) - paid automatically when you return to the game.'), style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _goldController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(border: const OutlineInputBorder(), labelText: tr('Částka', 'Amount'), isDense: true),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_upward, size: 16),
                        label: Text(tr('Uložit', 'Deposit')),
                        onPressed: () {
                          final amount = int.tryParse(_goldController.text) ?? 0;
                          state.depositGold(amount);
                          _goldController.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: Text(tr('Vytáhnout', 'Withdraw')),
                        onPressed: () {
                          final amount = int.tryParse(_goldController.text) ?? 0;
                          state.withdrawGold(amount);
                          _goldController.clear();
                        },
                      ),
                    ),
                  ]),
                ]),
              ),
            ]);
          }),
        ])),
      ]));
    });
  }
}

class BuildInspectorPanel extends StatelessWidget {
 final GameState s; const BuildInspectorPanel({super.key,required this.s});
 @override Widget build(BuildContext context)=>FantasyPanel(title:'ANALÝZA BUILDU',titleIcon:Icons.analytics,accent:const Color(0xFF64B5F6),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Row(children:[
    Expanded(child:_inspectorStatCard('GEAR SCORE',formatCompactNumber(s.inspectorGearScore),Icons.military_tech,const Color(0xFFFFD700))),
    const SizedBox(width:8),
    Expanded(child:_inspectorStatCard('DAMAGE',s.inspectorPrimaryDamage,Icons.whatshot,const Color(0xFFFF5252))),
    const SizedBox(width:8),
    Expanded(child:_inspectorStatCard('OBRANA',s.inspectorPrimaryDefense,Icons.shield,const Color(0xFF64B5F6))),
  ]),
  const SizedBox(height:10),const Text('Doporučení',style:TextStyle(color:Color(0xFF64B5F6),fontWeight:FontWeight.bold)),
  for(final x in s.buildInspectorRecommendations)Padding(padding:const EdgeInsets.only(top:6),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.arrow_right,color:Color(0xFF64B5F6)),Expanded(child:Text(x,style:const TextStyle(color:Colors.grey)))])),
 ]));

 // "Velké číslo" karta pro klíčové staty buildu (Gear Score/Damage/Obrana) - dřív obyčejné
 // výchozí Flutter Chip widgety bez jakéhokoliv fantasy stylu. Teď: barevný rám + glow + výrazné
 // velké číslo, aby tahle 3 čísla, na kterých hráči nejvíc záleží, vypadala odpovídajícím způsobem.
 Widget _inspectorStatCard(String label, String value, IconData icon, Color color) => Container(
   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
   decoration: BoxDecoration(
     gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(.18), const Color(0xFF1A1511)]),
     borderRadius: BorderRadius.circular(10),
     border: Border.all(color: color.withOpacity(.7), width: 1.3),
     boxShadow: [BoxShadow(color: color.withOpacity(.25), blurRadius: 10, spreadRadius: .5)],
   ),
   child: Column(children: [
     Icon(icon, color: color, size: 18),
     const SizedBox(height: 4),
     Text(
       value,
       textAlign: TextAlign.center,
       maxLines: 2,
       overflow: TextOverflow.ellipsis,
       style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: value.length > 6 ? 13 : 20, shadows: [Shadow(color: color.withOpacity(.6), blurRadius: 10)]),
     ),
     const SizedBox(height: 2),
     Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: .5)),
   ]),
 );
}
class DailyGoalsPanel extends StatelessWidget {
 final GameState s; const DailyGoalsPanel({super.key,required this.s});
 Widget row(String t,bool d)=>ListTile(dense:true,leading:Icon(d?Icons.check_circle:Icons.radio_button_unchecked,color:d?Colors.greenAccent:Colors.grey),title:Text(t),trailing:Text(d?'HOTOVO':'ČEKÁ',style:TextStyle(color:d?Colors.greenAccent:Colors.orangeAccent,fontSize:11)));
 Widget _cacheRow() {
   final claimed = s.dailyCacheClaimed;
   final ready = s.dailyCacheReady;
   return InkWell(
     onTap: ready ? s.claimDailyCache : null,
     borderRadius: BorderRadius.circular(8),
     child: Container(
       padding: const EdgeInsets.all(10),
       decoration: BoxDecoration(
         color: claimed ? const Color(0xFF16351F) : (ready ? const Color(0xFF3A2E08) : const Color(0xFF242029)),
         borderRadius: BorderRadius.circular(8),
       ),
       child: Row(children: [
         Icon(claimed ? Icons.check_circle : Icons.inventory_2, color: claimed ? Colors.greenAccent : (ready ? Colors.orangeAccent : Colors.grey)),
         const SizedBox(width: 8),
         Expanded(child: Text(claimed ? 'Denní Cache vyzvednuta' : (ready ? 'Denní Cache připravena - klikni pro vyzvednutí' : 'Dokonči 3 ze 4 cílů pro Denní Cache'))),
       ]),
     ),
   );
 }
 @override Widget build(BuildContext context)=>FantasyPanel(title:'DNEŠNÍ CÍLE ${s.dailyGoalsDone}/4',titleIcon:Icons.today,accent:Colors.orangeAccent,child:Column(children:[row('Poraz nebo vyzvi World Bosse',s.dailyWorldBossDone),row('Dokonči jeden Rift',s.dailyRiftDone),row('Dokonči Daily Quest',s.dailyQuestDone),row('Poraz bosse pro Runovou výzvu',s.dailyRuneDone),_cacheRow()]));
}
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Malý wrapper, co dá panelu odsazení nahoře - používá se uvnitř seznamů jednotlivých tabů
  // místo ruční SizedBox(height:12) mezi každým panelem jako dřív.
  Widget _p(Widget child) => Padding(padding: const EdgeInsets.only(top: 12), child: child);

  @override Widget build(BuildContext context)=>Consumer<GameState>(builder:(context,state,_){
    // ===== TIME GATE PRO ZÁLOŽKY =====
    // BUILD a VYBAVENÍ jsou pro nováčka jen stěna "zamčeno"/"zvol si nejdřív X" panelů - schované,
    // dokud se hráč fakticky nepřibližuje jejich obsahu (stejné reveal-okno jako Hub dlaždice,
    // viz GameState.isHubTileRevealed). PŘEHLED/LOOT/OSTATNÍ zůstávají vždy viditelné - OSTATNÍ
    // musí zůstat dostupné vždy, protože v něm žije zadávání promo kódu.
    final bool buildTabVisible = state.isHubTileRevealed(GameState.specializationUnlockLevel);
    final bool gearTabVisible = state.isHubTileRevealed(GameState.lairUnlockLevel);

    final tabs = <Tab>[Tab(text: tr('PŘEHLED', 'OVERVIEW'))];
    final tabViews = <Widget>[
      // PŘEHLED - co si hráč kontroluje nejčastěji: staty, talenty, průvodce dobrodružstvím,
      // souhrn buildu, denní cíle. Průvodce dobrodružstvím je sem přesunutý z BUILD tabu - je to
      // nováčkovský checklist "co dělat dál", takže musí být vidět, i když BUILD tab ještě není.
      ListView(padding: const EdgeInsets.all(16), children: [
        LayoutBuilder(builder:(context,c)=>c.maxWidth>760?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:_stats(state)),const SizedBox(width:12),Expanded(child:_talents(state))]):Column(children:[_stats(state),const SizedBox(height:12),_talents(state)])),
        _p(AdventureGuidePanel(state:state)),
        _p(BuildOverviewPanel(state:state)),
        _p(BuildInspectorPanel(s:state)),
        _p(DailyGoalsPanel(s:state)),
      ]),
    ];

    if (buildTabVisible) {
      tabs.add(Tab(text: tr('BUILD', 'BUILD')));
      tabViews.add(
        // BUILD - volby, co formují postavu: specializace, rank100, relicy, spellbook.
        ListView(padding: const EdgeInsets.all(16), children: [
          _ascensionPanel(state),
          _p(_rank100Choice(context,state)),
          _p(_specialization(context,state)),
          _p(_spellbookLinkPanel(context,state)),
          _p(_arenaRelicLinkPanel(context,state)),
          _p(_relicPanel(context,state)),
        ]),
      );
    }

    tabs.add(Tab(text: tr('LOOT', 'LOOT')));
    tabViews.add(
      // LOOT - priorita hodnocení itemů (viz LootPriorityMode/itemPowerScore).
      ListView(padding: const EdgeInsets.all(16), children: [
        const LootPriorityPanel(),
      ]),
    );

    if (gearTabVisible) {
      tabs.add(Tab(text: tr('VYBAVENÍ', 'GEAR')));
      tabViews.add(
        // VYBAVENÍ - sety, gemy, hardcore status. Jednotlivé panely už samy o sobě umí ukázat
        // "zamčeno, tady je jak na to" (viz _hardcorePanel/_gearSetPanel/_gemPanel) - tab-level
        // gate jen řeší, aby na tuhle "zeď zamčeného" nováček nenarazil hned od levelu 1.
        ListView(padding: const EdgeInsets.all(16), children: [
          _hardcorePanel(context,state),
          _p(_gearSetPanel(context,state)),
          _p(_hardcoreSetPanel(context,state)),
          _p(_predpekliSetPanel(context,state)),
          _p(_pekloSetPanel(context,state)),
          _p(_gemPanel(context,state)),
        ]),
      );
    }

    tabs.add(Tab(text: tr('OSTATNÍ', 'OTHER')));
    tabViews.add(
      // OSTATNÍ - sezónní/systémové věci, co se kontrolují jen občas. Tenhle tab NESMÍ jít
      // schovat celý - žije v něm zadávání promo kódu, které musí jít vždy. Rift Season a Alt
      // Catch-up (oboje irelevantní pro nováčka) se gatují jen jednotlivě, panel po panelu.
      ListView(padding: const EdgeInsets.all(16), children: [
        _p(_cosmeticsPanel(context, state)),
        if (state.isHubTileRevealed(GameState.riftUnlockLevel)) _riftSeasonPanel(state),
        if (state.totalDeaths > 0) _p(_altCatchUpPanel(context,state)),
        _p(const PromoCodePanel()),
        _p(FantasyPanel(
          title:tr('OFFLINE PROGRESS', 'OFFLINE PROGRESS'),
          titleIcon: state.offlineProgressUnlocked ? Icons.bedtime : Icons.lock,
          accent: state.offlineProgressUnlocked ? const Color(0xFF00E5A0) : Colors.grey,
          child: Text(
            state.offlineProgressUnlocked
                ? tr("Odemčeno! Když se vrátíš po delší pauze, čeká tě malý bonus zlata/dustu.", "Unlocked! When you come back after a longer break, you'll get a small gold/dust bonus.")
                : tr("Zamčeno. Odemkne se po ${GameState.offlineUnlockDeaths} úmrtích (aktuálně: ${state.totalDeaths}/${GameState.offlineUnlockDeaths}).", "Locked. Unlocks after ${GameState.offlineUnlockDeaths} deaths (currently: ${state.totalDeaths}/${GameState.offlineUnlockDeaths})."),
            style: TextStyle(color: state.offlineProgressUnlocked ? Colors.grey : Colors.grey.shade600, fontStyle: state.offlineProgressUnlocked ? FontStyle.normal : FontStyle.italic),
          ),
        )),
        _p(_saveExportImportPanel(context, state)),
        _p(_errorLogPanel(context)),
      ]),
    );

    return Container(
    decoration:const BoxDecoration(gradient:RadialGradient(center:Alignment.topCenter,radius:1.3,colors:[Color(0xFF332215),FantasyColors.abyss])),
    // 21 panelů v jednom lineárním scrollu bylo neúnosně dlouhé - rozděleno do tabů podle účelu.
    // Jméno/třída/level se nezobrazují znovu tady - jsou už vidět v horní liště nad taby.
    // Gear Score a XP bar zůstávají VŽDY viditelné nahoře, nezávisle na tom, který tab je otevřený.
    child: DefaultTabController(length: tabs.length, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0), child: Column(children: [
        Align(alignment:Alignment.centerLeft,child:GearScoreBadge(state:state)),
        const SizedBox(height:8),
        BarWidget(value: state.xp.toDouble(), max: state.xpToLevel.toDouble(), color: FantasyColors2.emberGold, label: "XP"),
        const SizedBox(height:8),
        TabBar(
          isScrollable: true,
          labelColor: FantasyColors.gold,
          unselectedLabelColor: Colors.grey,
          indicatorColor: FantasyColors.gold,
          labelStyle: GoogleFonts.cinzel(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: tabs,
        ),
      ])),
      Expanded(child: TabBarView(children: tabViews)),
    ])));
  });

  // ===== EXPORT/IMPORT POSTUPU — "chudák cloud save" bez nutnosti Google Play Games/Game
  // Center účtu. Export otevře dialog s textovým kódem + tlačítkem "Kopírovat". Import je
  // DESTRUKTIVNÍ (přepíše aktuální postup), takže vyžaduje explicitní potvrzení přes dialog
  // s varováním, ne jen prosté vložení textu.
  // ===== ASCENSION — 4 automatické stupně (Hardcore/Předpeklí/Peklo odemčení + Peklo patro
  // 100 poraženo), zobrazuje se v Build tabu. Level 4 = odemčen Endless Scale (Soul Demon).
  Widget _ascensionPanel(GameState state) {
    final lvl = state.ascensionLevel;
    final labels = ['Normal', 'Hardcore', tr('Předpeklí', 'Netherworld'), tr('Peklo', 'Hell'), 'Endless Scale'];
    return FantasyPanel(
      title: tr('ASCENSION', 'ASCENSION'),
      titleIcon: Icons.auto_awesome,
      accent: Colors.deepPurpleAccent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('Stupeň $lvl / 4 — ${labels[lvl]}', 'Stage $lvl / 4 — ${labels[lvl]}'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        Row(children: List.generate(4, (i) => Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(color: i < lvl ? Colors.deepPurpleAccent : Colors.grey.shade800, borderRadius: BorderRadius.circular(4)),
          ),
        ))),
        const SizedBox(height: 10),
        Text(
          lvl >= 4
              ? tr('👑 Peklo poraženo! Endless Scale (Soul Demon) je odemčený - opakovatelný capstone boj.', '👑 Hell defeated! Endless Scale (Soul Demon) is unlocked - a repeatable capstone fight.')
              : tr('Automaticky roste s postupem v Lairu: poražením bosse na patře 100 v Normal, Hardcore, Předpeklí a Peklu. Každý stupeň udrží čísla nepřátel v rozumném rozsahu (nesmaže obtížnost, jen zabrání overflow).', 'Grows automatically as you progress in the Lair: by defeating the floor-100 boss in Normal, Hardcore, Netherworld, and Hell. Each stage keeps enemy numbers in a sane range (it doesn\'t reduce difficulty, just prevents overflow).'),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ]),
    );
  }

  Widget _saveExportImportPanel(BuildContext context, GameState state) {
    return FantasyPanel(
      title: tr('EXPORT / IMPORT POSTUPU', 'EXPORT / IMPORT PROGRESS'), titleIcon: Icons.import_export, accent: Colors.lightBlueAccent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          tr('Bez cloud save systému. Zkopíruj si textový kód postupu a na jiném zařízení (nebo po přeinstalaci appky) ho vlož zpět, ať o postup nepřijdeš.', 'No cloud save system. Copy your progress code and paste it back on another device (or after reinstalling the app) so you don\'t lose your progress.'),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload, size: 16),
              label: Text(tr('Exportovat kód', 'Export code')),
              onPressed: () => _showExportDialog(context, state),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: Text(tr('Importovat kód', 'Import code')),
              onPressed: () => _showImportDialog(context, state),
            ),
          ),
        ]),
      ]),
    );
  }

  void _showExportDialog(BuildContext context, GameState state) {
    final code = state.exportSaveCode();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text(tr('Kód postupu', 'Progress code')),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Zkopíruj tenhle kód a ulož si ho (např. do poznámek) - na jiném zařízení ho vlož přes "Importovat kód".', 'Copy this code and save it somewhere (e.g. notes) - on another device paste it via "Import code".'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(child: SelectableText(code, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Zavřít')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: Text(tr('Kopírovat', 'Copy')),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Kód zkopírován do schránky.', 'Code copied to clipboard.'))));
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, GameState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text(tr('Importovat kód postupu', 'Import progress code')),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('⚠️ Tohle PŘEPÍŠE tvůj aktuální postup na tomhle zařízení. Nedá se vrátit zpět.', '⚠️ This will OVERWRITE your current progress on this device. This cannot be undone.'), style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 5,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            decoration: InputDecoration(border: const OutlineInputBorder(), hintText: tr('Sem vlož kód postupu...', 'Paste your progress code here...')),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tr('Zrušit', 'Cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final error = await state.importSaveCode(controller.text);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? tr('Postup úspěšně importován!', 'Progress imported successfully!'))));
            },
            child: Text(tr('Přepsat postup', 'Overwrite progress')),
          ),
        ],
      ),
    );
  }

  // ===== LOG CHYB (Krok 1 crash reportingu) - hráč může zkopírovat posledních 20 chyb do
  // schránky a poslat vývojáři (Discord/email/support formulář). Read-only, žádné odesílání
  // na server - to je Krok 2 (Sentry/Firebase), viz komentář u CrashReporter výše v souboru.
  Widget _errorLogPanel(BuildContext context) {
    return StatefulBuilder(builder: (context, setLocalState) {
      final errors = CrashReporter.recentErrors;
      return FantasyPanel(
        title: tr('LOG CHYB', 'ERROR LOG'), titleIcon: Icons.bug_report, accent: errors.isEmpty ? Colors.grey : Colors.orangeAccent,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            errors.isEmpty ? tr('Žádné zaznamenané chyby. Pokud appka spadne nebo se chová divně, tady se objeví záznam k nahlášení.', 'No errors recorded. If the app crashes or behaves strangely, a report will appear here.') : tr('Posledních ${errors.length} zaznamenaných chyb. Zkopíruj a pošli vývojáři, ať to může opravit.', 'The last ${errors.length} recorded errors. Copy and send them to the developer so they can fix it.'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(tr('Kopírovat log', 'Copy log')),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: errors.join('\n\n')));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Log chyb zkopírován do schránky.', 'Error log copied to clipboard.'))));
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(tr('Smazat', 'Clear')),
                onPressed: () async {
                  await CrashReporter.clear();
                  setLocalState(() {});
                },
              ),
            ]),
          ],
        ]),
      );
    });
  }
  Widget _stats(GameState s)=>FantasyPanel(title:tr('STATY','STATS'),titleIcon:Icons.sports_martial_arts,child:Column(children:[
    FantasyStatTile(icon:Icons.fitness_center,color:Colors.redAccent,label:tr('Síla','Strength'),value:s.totalStrength.round().toString()),FantasyStatTile(icon:Icons.directions_run,color:Colors.lightGreenAccent,label:tr('Hbitost','Agility'),value:s.totalAgility.round().toString()),FantasyStatTile(icon:Icons.auto_awesome,color:Colors.lightBlueAccent,label:tr('Moudrost','Wisdom'),value:s.totalWisdom.round().toString()),FantasyStatTile(icon:Icons.favorite,color:Colors.red,label:tr('Vitalita','Vitality'),value:s.totalVitality.round().toString()),FantasyStatTile(icon:Icons.gps_fixed,color:FantasyColors.gold,label:tr('Kritická šance','Crit Chance'),value:'${(s.critChance*100).toStringAsFixed(1)} %'),FantasyStatTile(icon:Icons.air,color:Colors.cyan,label:tr('Úhyb','Dodge'),value:'${(s.dodgeChance*100).toStringAsFixed(1)} %'),FantasyStatTile(icon:Icons.shield,color:Colors.blueGrey,label:tr('Blok','Block'),value:'${(s.blockChance*100).toStringAsFixed(1)} %'),]));
  Widget _talents(GameState s)=>FantasyPanel(title:tr('TALENTY','TALENTS'),titleIcon:Icons.account_tree,child:Column(children:[
    // Výrazný badge s počtem volných bodů - dřív bylo číslo jen schované v nadpisu panelu
    // (mohlo se ztratit/přeříznout na užších obrazovkách). Zlatě svítí, když je co utratit;
    // zešedne, když je 0 (typicky s "Automatické talenty" zapnutými, kdy se body sypou hned).
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: s.talentPoints > 0 ? const Color(0xFF332508) : const Color(0xFF201C16),
          border: Border.all(color: s.talentPoints > 0 ? FantasyColors.gold : Colors.grey.shade700, width: 1.4),
          borderRadius: BorderRadius.circular(10),
          boxShadow: s.talentPoints > 0 ? [BoxShadow(color: FantasyColors.gold.withOpacity(.4), blurRadius: 12, spreadRadius: 1)] : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.stars, color: s.talentPoints > 0 ? FantasyColors.gold : Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            s.talentPoints > 0
                ? tr('${s.talentPoints} bodů k rozdání', '${s.talentPoints} points to spend')
                : tr('Žádné body k rozdání', 'No points to spend'),
            style: TextStyle(color: s.talentPoints > 0 ? FantasyColors.gold : Colors.grey, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ]),
      ),
    ),
    SwitchListTile(title:Text(tr('Automatické talenty','Auto talents')),value:s.autoTalentsEnabled,onChanged:(_)=>s.toggleAutoTalents()),
    // Do čeho automatické talenty sypou nové body - dřív šlo natvrdo jen do Strength bez
    // možnosti volby, i pro Wisdom/Agility třídy. Viditelné jen když je auto-mód zapnutý.
    if (s.autoTalentsEnabled) Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 8, runSpacing: 6,
        children: s.talents.keys.map((stat) => ChoiceChip(
          label: Text(statLabel(stat)),
          selected: s.preferredAutoTalent == stat,
          onSelected: (_) => s.setPreferredAutoTalent(stat),
          selectedColor: FantasyColors.gold,
          backgroundColor: const Color(0xFF2A241C),
          labelStyle: TextStyle(color: s.preferredAutoTalent == stat ? Colors.black : FantasyColors.parchment, fontWeight: FontWeight.bold),
        )).toList(),
      ),
    ),
    ...s.talents.entries.map((e)=>ListTile(title:Text('${statLabel(e.key)}  ${e.value}',style:const TextStyle(color:FantasyColors.parchment,fontWeight:FontWeight.bold)),trailing:FantasyButton(text:'+',icon:Icons.add,onPressed:s.talentPoints>0?()=>s.addTalent(e.key):null))).toList()
  ]));

  // ===== ODKAZ NA SPECIALIZAČNÍ RELIC (vlastní obrazovka - 2. tab Arény) =====
  Widget _arenaRelicLinkPanel(BuildContext context, GameState s) {
    final r = s.currentSpecRelic;
    return FantasyPanel(
      title: tr('SPECIALIZAČNÍ RELIC', 'SPECIALIZATION RELIC'), titleIcon: r.icon, accent: r.color,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(r.icon, color: r.color, size: 32),
        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(s.currentSpecRelicUnlocked ? '${r.form} • Lv ${s.currentSpecRelicLevel}/${GameState.maxSpecRelicLevel}' : tr('${r.form} • nezískán (padá po výhře v Aréně)', '${r.form} • not obtained (drops from winning in the Arena)'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: r.color, foregroundColor: Colors.black),
          onPressed: () => openWorldScreen(context, tr('Aréna', 'Arena'), const ArenaScreen(initialTab: 1), theme: const Color(0xFFFF8000)),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(tr('Otevřít', 'Open')),
        ),
      ),
    );
  }

  // ===== ODKAZ NA KNIHU KOUZEL (Spellbook) - vysvětlení spellů aktuálního buildu a synergií =====
  Widget _spellbookLinkPanel(BuildContext context, GameState s) {
    return FantasyPanel(
      title: tr('KNIHA KOUZEL', 'SPELLBOOK'), titleIcon: Icons.auto_stories, accent: Colors.tealAccent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.auto_stories, color: Colors.tealAccent, size: 32),
        title: Text(tr('Spelly a synergie tvého buildu', 'Spells and synergies of your build'), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tr('Co dělá který spell, jak spolu spelly kombinují a co ti dávají sety.', 'What each spell does, how spells combine, and what your sets grant.'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
          onPressed: () => openWorldScreen(context, tr('Kniha kouzel', 'Spellbook'), const SpellbookScreen()),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(tr('Otevřít', 'Open')),
        ),
      ),
    );
  }

  // ===== PARAGON 50 — SPECIALIZACE (Berserk/Ochránce/Krvežíznivý pro Warriora, atd.) =====
  Widget _relicPanel(BuildContext context,GameState s)=>FantasyPanel(title:tr('PARAGON • AMULETY A MASTERY (${s.unlockedRelicIds.length}/${LegendaryRelic.values.length})','PARAGON • AMULETS AND MASTERY (${s.unlockedRelicIds.length}/${LegendaryRelic.values.length})'),titleIcon:Icons.auto_awesome,accent:const Color(0xFFFFC857),child:Column(children:[for(final r in LegendaryRelic.values)Card(color:s.activeRelic==r?const Color(0xFF3A2A12):const Color(0xFF1E1E24),child:ListTile(leading:Icon(s.relicUnlocked(r)?Icons.auto_awesome:Icons.lock,color:const Color(0xFFFFC857)),title:Text(r.displayName),subtitle:Text(s.relicUnlocked(r)?'${r.description}\nLv ${s.relicLevel(r)}/10 • XP ${s.relicXpInLevel(r)}/100 • Mastery ${s.relicMasteryLevel(r)}':'${r.description}\nDrop: Tower 1 %, Rift 3 %, Lair 5 %'),trailing:!s.relicUnlocked(r)?null:s.activeRelic==r?Chip(label:Text(tr('AKTIVNÍ','ACTIVE'))):ElevatedButton(onPressed:()=>s.equipRelic(r),child:Text(tr('Aktivovat','Activate')))))]));
  // Vstup do Kosmetiky - náhled aktuálně nasazeného rámu/skinu + tlačítko na CustomizationScreen.
  // Odemyká se přes Battle Pass (level 40 free = rám, level 40 premium = skin útoku).
  Widget _cosmeticsPanel(BuildContext context, GameState state) => FantasyPanel(
        title: tr('KOSMETIKA', 'COSMETICS'),
        titleIcon: Icons.auto_awesome,
        accent: const Color(0xFFFFD54F),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: EquippedFrameOverlay(
            frameId: state.equippedFrame,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [FantasyColors.gold.withOpacity(.3), FantasyColors2.obsidian])),
              child: state.equippedAttackSkin != 'default' ? CustomPaint(painter: AttackSkinIconPainter(physical: state.physAtk >= state.magAtk)) : null,
            ),
          ),
          title: Text(tr('Rám a skin útoku', 'Frame and attack skin'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(tr('Odemyká se z Battle Passu (úroveň 40).', 'Unlocked from the Battle Pass (level 40).'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomizationScreen())),
        ),
      );

  Widget _riftSeasonPanel(GameState s)=>FantasyPanel(title:tr('RIFT SEASON','RIFT SEASON'),titleIcon:Icons.storm,accent:Colors.deepPurpleAccent,child:ListTile(title:Text(s.currentRiftSeason.displayName),subtitle:Text(tr('${s.currentRiftSeason.description}\nSezóna #${s.currentRiftSeasonNumber}','${s.currentRiftSeason.description}\nSeason #${s.currentRiftSeasonNumber}')),leading:const Icon(Icons.storm,color:Colors.deepPurpleAccent)));

  Widget _specDetailRow(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 8),
      Expanded(child: RichText(text: TextSpan(style: const TextStyle(fontSize: 12, height: 1.35), children: [
        TextSpan(text: '$label: ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        TextSpan(text: value, style: const TextStyle(color: Colors.grey)),
      ]))),
    ]);
  }

  Widget _specialization(BuildContext context, GameState s) {
    if (s.heroClass == HeroClass.none) return const SizedBox.shrink();
    if (!s.canChooseSpecialization) {
      return FantasyPanel(
        title: tr('SPECIALIZACE', 'SPECIALIZATION'),
        titleIcon: Icons.hub,
        accent: Colors.grey,
        child: Text(
          tr('Odemyká se na level 25 a Paragon 10 (aktuálně: level ${s.level}, Paragon ${s.paragonLevel}). Umožní zvolit jednu ze 3 specializací, která upraví všechny tvé schopnosti.', 'Unlocks at level 25 and Paragon 10 (currently: level ${s.level}, Paragon ${s.paragonLevel}). Lets you choose one of 3 specializations that reshapes all your abilities.'),
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    return FantasyPanel(
      title: tr('SPECIALIZACE', 'SPECIALIZATION'),
      titleIcon: Icons.hub,
      accent: const Color(0xFFFF8000),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.specialization != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tr('Aktivní: ${s.specializationName}', 'Active: ${s.specializationName}'),
                style: const TextStyle(color: Color(0xFFFF8000), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          for (final spec in [1, 2, 3])
            Card(
              color: s.specialization == spec ? const Color(0xFF3A2418) : const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: s.specialization == spec ? const Color(0xFFFF8000) : Colors.grey.shade800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                initiallyExpanded: s.specialization == spec,
                leading: CircleAvatar(
                  backgroundColor: s.specialization == spec ? const Color(0xFFFF8000) : Colors.grey.shade800,
                  child: Text('$spec', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(s.specializationNameFor(spec), style: const TextStyle(fontWeight: FontWeight.bold, color: FantasyColors.parchment)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(s.specializationRoleFor(spec), style: const TextStyle(color: Color(0xFFFFB15C), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                ),
                trailing: s.specialization == spec
                    ? const Icon(Icons.check_circle, color: Color(0xFFFF8000))
                    : const Icon(Icons.expand_more, color: Colors.grey),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text(s.specializationFantasyFor(spec), style: const TextStyle(color: FantasyColors.parchment, fontSize: 13, height: 1.35))),
                  const SizedBox(height: 10),
                  _specDetailRow(Icons.auto_awesome, tr('Mechaniky', 'Mechanics'), s.specializationDescriptionFor(spec), const Color(0xFFB794F6)),
                  const SizedBox(height: 7),
                  _specDetailRow(Icons.trending_up, tr('Silné stránky', 'Strengths'), s.specializationStrengthsFor(spec), Colors.greenAccent),
                  const SizedBox(height: 7),
                  _specDetailRow(Icons.warning_amber, tr('Slabiny', 'Weaknesses'), s.specializationWeaknessesFor(spec), Colors.orangeAccent),
                  const SizedBox(height: 7),
                  _specDetailRow(Icons.build, tr('Doporučený build', 'Recommended build'), s.specializationRecommendedBuildFor(spec), const Color(0xFF64B5F6)),
                  const SizedBox(height: 12),
                  if (s.specialization != spec)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.hub),
                        onPressed: () => s.specialization == 0 ? s.chooseSpecialization(spec) : s.respecSpecialization(spec),
                        label: Text(s.specialization == 0 ? tr('ZVOLIT ${s.specializationNameFor(spec).toUpperCase()}', 'CHOOSE ${s.specializationNameFor(spec).toUpperCase()}') : tr('RESPEC ZA ${s.respecCost} 🪙', 'RESPEC FOR ${s.respecCost} 🪙')),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===== HARDCORE MODE + PROKLETÍ OSUDU =====
  // Hardcore/Předpeklí/Peklo jsou exkluzivní volba obtížnosti (viz GameState.setDifficultyTier) -
  // vykreslené jako jeden seznam se 4 řádky (Normal + 3 vyšší tiery), vybraný právě jeden.
  Widget _difficultyTierRow(GameState s, {required int tier, required String label, required Color color, required String desc, required bool unlocked}) {
    final selected = s.difficultyTier == tier;
    return Card(
      color: selected ? const Color(0xFF3A1414) : const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: selected ? color : Colors.grey.shade800),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: unlocked ? color : Colors.grey)),
        subtitle: Text(desc, style: TextStyle(color: unlocked ? Colors.grey : Colors.grey.shade700, fontSize: 12, fontStyle: unlocked ? FontStyle.normal : FontStyle.italic)),
        trailing: selected
            ? Icon(Icons.check_circle, color: color)
            : (unlocked
                ? ElevatedButton(onPressed: () => s.setDifficultyTier(tier), child: Text(tr('Zvolit', 'Choose')))
                : const Icon(Icons.lock, color: Colors.grey)),
      ),
    );
  }

  // ===== RANK 100 — POKROČILÁ CESTA (jednorázová volba 4. spellu, na rozdíl od specializace
  // se NEDÁ respecovat) - stejný vizuální vzor jako _specialization(), ikony/jména/popisky
  // sdílené se Spellbookem (spellVisualTier4 / spellShortDesc), žádný duplicitní text. =====
  Widget _rank100Choice(BuildContext context, GameState s) {
    if (s.heroClass == HeroClass.none) return const SizedBox.shrink();
    if (!s.isRank100Unlocked) {
      return FantasyPanel(
        title: tr('RANK 100 • POKROČILÁ CESTA', 'RANK 100 • ADVANCED PATH'),
        titleIcon: Icons.military_tech,
        accent: Colors.grey,
        child: Text(
          tr('Odemyká se na Rank 100 aktuální třídy (aktuálně: Rank ${s.classRanks[s.heroClass] ?? 1}). Umožní zvolit jednu ze 3 cest, která dá unikátní 4. spell.', 'Unlocks at Rank 100 of your current class (currently: Rank ${s.classRanks[s.heroClass] ?? 1}). Lets you choose one of 3 paths that grants a unique 4th spell.'),
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    final c = s.heroClass;
    return FantasyPanel(
      title: tr('RANK 100 • POKROČILÁ CESTA', 'RANK 100 • ADVANCED PATH'),
      titleIcon: Icons.military_tech,
      accent: const Color(0xFFFF1744),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.rank100Choice != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tr('Zvolena cesta: ${spellVisualTier4(c, s.rank100Choice).name}', 'Path chosen: ${spellVisualTier4(c, s.rank100Choice).name}'),
                style: TextStyle(color: spellVisualTier4(c, s.rank100Choice).color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tr('⚠ Tahle volba je jednorázová a NA ROZDÍL od specializace se NEDÁ respecovat - vyber pečlivě.', '⚠ This choice is one-time and, UNLIKE specialization, CANNOT be respecced - choose carefully.'),
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          for (final choice in [1, 2, 3])
            Card(
              color: s.rank100Choice == choice ? const Color(0xFF3A1418) : const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: s.rank100Choice == choice ? const Color(0xFFFF1744) : Colors.grey.shade800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(spellVisualTier4(c, choice).icon, color: spellVisualTier4(c, choice).color, size: 28),
                title: Text(spellVisualTier4(c, choice).name, style: const TextStyle(fontWeight: FontWeight.bold, color: FantasyColors.parchment)),
                subtitle: Text(spellShortDesc(c, 4, choice: choice), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: s.rank100Choice == choice
                    ? const Icon(Icons.check_circle, color: Color(0xFFFF1744))
                    : (s.rank100Choice == 0
                        ? ElevatedButton(onPressed: () => s.chooseRank100Path(choice), child: Text(tr('ZVOLIT', 'CHOOSE')))
                        : null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hardcorePanel(BuildContext context, GameState s) {
    if (s.heroClass == HeroClass.none) return const SizedBox.shrink();
    if (!s.hardcoreUnlocked) {
      return FantasyPanel(
        title: tr('OBTÍŽNOST', 'DIFFICULTY'),
        titleIcon: Icons.dangerous,
        accent: Colors.grey,
        child: Text(
          tr('Zamčeno. Poraz bosse v Lair 100 - dostaneš Prsten Osudu (artefakt, 6 gem slotů) a odemkneš Hardcore Mode.', 'Locked. Defeat the boss in Lair 100 - you\'ll get the Ring of Fate (artifact, 6 gem slots) and unlock Hardcore Mode.'),
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    return FantasyPanel(
      title: tr('OBTÍŽNOST', 'DIFFICULTY'),
      titleIcon: Icons.dangerous,
      accent: const Color(0xFFFF1744),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Jde mít aktivní vždy jen jednu obtížnost.', 'Only one difficulty can be active at a time.'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          _difficultyTierRow(s, tier: 0, label: 'Normal', color: Colors.grey, desc: tr('Základní obtížnost.', 'Base difficulty.'), unlocked: true),
          _difficultyTierRow(
            s,
            tier: 1,
            label: tr('☠ Hardcore', '☠ Hardcore'),
            color: const Color(0xFFFF1744),
            desc: tr('Nepřátelé jsou o ${(50 * s.hardcoreTier)} % silnější (tier ${s.hardcoreTier}). Poraz bosse v Lair 100 s aktivním prokletím → gem do Prstenu Osudu + vyšší tier + nové prokletí.', 'Enemies are ${(50 * s.hardcoreTier)}% stronger (tier ${s.hardcoreTier}). Defeat the boss in Lair 100 with an active curse → gem for the Ring of Fate + higher tier + new curse.'),
            unlocked: true,
          ),
          _difficultyTierRow(
            s,
            tier: 2,
            label: tr('🔥 Předpeklí', '🔥 Netherworld'),
            color: const Color(0xFFFF6A00),
            desc: s.predpekliUnlocked
                ? tr("×${GameState.predpekliDifficultyMult} obtížnější než Hardcore, odměna +${(GameState.predpekliRewardBonus * 100).round().toString()} % gold/dust/xp, +${(GameState.predpekliLootBonus * 100).round().toString()} % loot chance.", "×${GameState.predpekliDifficultyMult} harder than Hardcore, reward +${(GameState.predpekliRewardBonus * 100).round().toString()}% gold/dust/xp, +${(GameState.predpekliLootBonus * 100).round().toString()}% loot chance.")
                : tr("Zamčeno. Odemkni na Hardcore tieru ${GameState.predpekliUnlockHardcoreTier} (aktuálně: tier ${s.hardcoreTier}).", "Locked. Unlock at Hardcore tier ${GameState.predpekliUnlockHardcoreTier} (currently: tier ${s.hardcoreTier})."),
            unlocked: s.predpekliUnlocked,
          ),
          _difficultyTierRow(
            s,
            tier: 3,
            label: tr('😈 Peklo', '😈 Hell'),
            color: const Color(0xFFB71C1C),
            desc: s.pekloUnlocked
                ? tr("×${GameState.pekloDifficultyMult} obtížnější než Předpeklí (a to je navrch Hardcore), odměna +${(GameState.pekloRewardBonus * 100).round().toString()} % gold/dust/xp, +${(GameState.pekloLootBonus * 100).round().toString()} % loot chance.", "×${GameState.pekloDifficultyMult} harder than Netherworld (on top of Hardcore), reward +${(GameState.pekloRewardBonus * 100).round().toString()}% gold/dust/xp, +${(GameState.pekloLootBonus * 100).round().toString()}% loot chance.")
                : tr("Zamčeno. Odemkni na Hardcore tieru ${GameState.pekloUnlockHardcoreTier} (aktuálně: tier ${s.hardcoreTier}).", "Locked. Unlock at Hardcore tier ${GameState.pekloUnlockHardcoreTier} (currently: tier ${s.hardcoreTier})."),
            unlocked: s.pekloUnlocked,
          ),
          if (s.atLeastHardcore) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(tr("Prokletí Osudu (volitelné, jen jedno): +${25 * s.hardcoreTier} % zlato/dust/xp, +${s.hardcoreTier} % loot chance (roste s tierem).", "Curse of Fate (optional, only one): +${25 * s.hardcoreTier}% gold/dust/xp, +${s.hardcoreTier}% loot chance (grows with tier)."), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            for (final curse in CurseOfFate.values)
              Card(
                color: s.activeCurse == curse ? const Color(0xFF3A1414) : const Color(0xFF1E1E24),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: s.activeCurse == curse ? const Color(0xFFFF1744) : Colors.grey.shade800),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(s.curseNameFor(curse), style: const TextStyle(fontWeight: FontWeight.bold, color: FantasyColors.parchment)),
                  subtitle: curse == CurseOfFate.none ? null : Text(s.curseDescriptionFor(curse), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: s.activeCurse == curse
                      ? const Icon(Icons.check_circle, color: Color(0xFFFF1744))
                      : ElevatedButton(
                          onPressed: () => s.selectCurse(curse),
                          child: Text(tr('Zvolit', 'Choose')),
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ===== SET BONUSY — SET vybavení vázané na (třída, specializace), viz GameState.gearSets /
  // activeGearSetDef / activeGearSetTier. 8 kusů (bez zbraně a prstenu), prahy 2/4/6/8. =====
  Widget _gearSetPanel(BuildContext context, GameState s) {
    final def = s.activeGearSetDef;
    if (def == null) {
      return FantasyPanel(
        title: tr('SET BONUSY', 'SET BONUSES'),
        titleIcon: Icons.diamond_outlined,
        accent: Colors.grey,
        child: Text(
          s.heroClass == HeroClass.none
              ? tr('Nejdřív si zvol povolání.', 'First choose your class.')
              : (s.specialization == 0
                  ? tr('Nejdřív si zvol specializaci - SET vybavení (8 kusů, bez zbraně a prstenu) je vázané na (třída, specializace).', 'First choose your specialization - SET gear (8 pieces, excluding weapon and ring) is tied to (class, specialization).')
                  : tr('Pro tuhle kombinaci třídy a specializace zatím žádný SET neexistuje.', 'No SET exists yet for this class and specialization combination.')),
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    final count = s.equippedSetCounts[def.id] ?? 0;
    final tier = s.activeGearSetTier;
    Widget tierRow(int threshold, String desc) {
      final active = tier >= threshold;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(active ? Icons.check_circle : Icons.circle_outlined, color: active ? const Color(0xFF00E676) : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "($threshold) $desc",
                style: TextStyle(color: active ? FantasyColors.parchment : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          ],
        ),
      );
    }

    return FantasyPanel(
      title: tr('SET BONUSY', 'SET BONUSES'),
      titleIcon: Icons.diamond,
      accent: const Color(0xFF00E676),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(def.name, style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),
          Text(tr("Nasazeno: $count/8 kusů", "Equipped: $count/8 pieces"), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(),
          tierRow(2, def.twoPieceDesc),
          tierRow(4, def.fourPieceDesc),
          tierRow(6, def.sixPieceDesc),
          tierRow(8, def.eightPieceDesc),
        ],
      ),
    );
  }

  // ===== HARDCORE SET — zobrazí aktivní set pro aktuální (třída, specializace) a co dělá =====
  Widget _hardcoreSetPanel(BuildContext context, GameState s) {
    final def = s.activeHardcoreSetDef;
    if (def == null) {
      return FantasyPanel(
        title: tr('HARDCORE SET', 'HARDCORE SET'),
        titleIcon: Icons.diamond_outlined,
        accent: Colors.grey,
        child: Text(
          s.specialization == 0
              ? tr("Nejdřív si zvol specializaci - každá má vlastní Hardcore set (2/4/6/8 kusů, neonově modrá).", "First choose your specialization - each has its own Hardcore set (2/4/6/8 pieces, neon blue).")
              : tr("Pro tuhle kombinaci třídy a specializace zatím žádný Hardcore set neexistuje.", "No Hardcore set exists yet for this class and specialization combination."),
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    final count = s.equippedHardcoreSetCounts[def.id] ?? 0;
    final tier = s.activeHardcoreSetTier;
    Widget tierRow(int threshold, String desc) {
      final active = tier >= threshold;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(active ? Icons.check_circle : Icons.circle_outlined, color: active ? const Color(0xFF00F0FF) : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "($threshold) $desc",
                style: TextStyle(color: active ? FantasyColors.parchment : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          ],
        ),
      );
    }

    return FantasyPanel(
      title: tr('HARDCORE SET', 'HARDCORE SET'),
      titleIcon: Icons.diamond,
      accent: const Color(0xFF00F0FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(def.name, style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 16)),
          Text(tr("Nasazeno: $count/8 kusů (mainStat živě: statValue × level × nasazené kusy, od 2 ks)", "Equipped: $count/8 pieces (mainStat live: statValue × level × equipped pieces, from 2 pcs)"), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(),
          tierRow(2, def.twoPieceDesc),
          tierRow(4, def.fourPieceDesc),
          tierRow(6, def.sixPieceDesc),
          tierRow(8, def.eightPieceDesc),
        ],
      ),
    );
  }

  // ===== PŘEDPEKLÍ SET — mainStat × level × 2,5, stejná struktura jako Hardcore/Peklo (2/4/6 ks) =====
  Widget _predpekliSetPanel(BuildContext context, GameState s) {
    final def = s.activePredpekliSetDef;
    if (def == null) {
      return FantasyPanel(
        title: tr('PŘEDPEKLÍ SET', 'NETHERWORLD SET'),
        titleIcon: Icons.diamond_outlined,
        accent: Colors.grey,
        child: Text(
          s.specialization == 0
              ? tr("Nejdřív si zvol specializaci - každá má vlastní Předpeklí set (2/4/6/8 kusů, pekelná fialová).", "First choose your specialization - each has its own Netherworld set (2/4/6/8 pieces, hellish purple).")
              : tr("Pro tuhle kombinaci třídy a specializace zatím žádný Předpeklí set neexistuje.", "No Netherworld set exists yet for this class and specialization combination."),
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    final count = s.equippedPredpekliSetCounts[def.id] ?? 0;
    final tier = s.activePredpekliSetTier;
    Widget tierRow(int threshold, String desc) {
      final active = tier >= threshold;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(active ? Icons.check_circle : Icons.circle_outlined, color: active ? const Color(0xFFB026FF) : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "($threshold) $desc",
                style: TextStyle(color: active ? FantasyColors.parchment : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          ],
        ),
      );
    }

    return FantasyPanel(
      title: tr('PŘEDPEKLÍ SET', 'NETHERWORLD SET'),
      titleIcon: Icons.diamond,
      accent: const Color(0xFFB026FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(def.name, style: const TextStyle(color: Color(0xFFB026FF), fontWeight: FontWeight.bold, fontSize: 16)),
          Text(tr("Nasazeno: $count/8 kusů (mainStat živě: statValue × level × nasazené kusy, od 2 ks)", "Equipped: $count/8 pieces (mainStat live: statValue × level × equipped pieces, from 2 pcs)"), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(),
          tierRow(2, def.twoPieceDesc),
          tierRow(4, def.fourPieceDesc),
          tierRow(6, def.sixPieceDesc),
          tierRow(8, def.eightPieceDesc),
        ],
      ),
    );
  }

  // ===== PEKLO SET — nejvyšší tier, o stupeň víc než Předpeklí (mainStat × level × 4,5) =====
  Widget _pekloSetPanel(BuildContext context, GameState s) {
    final def = s.activePekloSetDef;
    if (def == null) {
      return FantasyPanel(
        title: tr('PEKLO SET', 'HELL SET'),
        titleIcon: Icons.diamond_outlined,
        accent: Colors.grey,
        child: Text(
          s.specialization == 0
              ? tr("Nejdřív si zvol specializaci - každá má vlastní Peklo set (2/4/6/8 kusů, ohnivě rudá).", "First choose your specialization - each has its own Hell set (2/4/6/8 pieces, fiery red).")
              : tr("Pro tuhle kombinaci třídy a specializace zatím žádný Peklo set neexistuje.", "No Hell set exists yet for this class and specialization combination."),
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    final count = s.equippedPekloSetCounts[def.id] ?? 0;
    final tier = s.activePekloSetTier;
    Widget tierRow(int threshold, String desc) {
      final active = tier >= threshold;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(active ? Icons.check_circle : Icons.circle_outlined, color: active ? const Color(0xFFFF3D00) : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "($threshold) $desc",
                style: TextStyle(color: active ? FantasyColors.parchment : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          ],
        ),
      );
    }

    return FantasyPanel(
      title: tr('PEKLO SET', 'HELL SET'),
      titleIcon: Icons.local_fire_department,
      accent: const Color(0xFFFF3D00),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(def.name, style: const TextStyle(color: Color(0xFFFF3D00), fontWeight: FontWeight.bold, fontSize: 16)),
          Text(tr("Nasazeno: $count/8 kusů (mainStat živě: statValue × level × nasazené kusy, od 2 ks)", "Equipped: $count/8 pieces (mainStat live: statValue × level × equipped pieces, from 2 pcs)"), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(),
          tierRow(2, def.twoPieceDesc),
          tierRow(4, def.fourPieceDesc),
          tierRow(6, def.sixPieceDesc),
          tierRow(8, def.eightPieceDesc),
        ],
      ),
    );
  }

  // ===== ALT CATCH-UP BONUS =====
  // ===== GEMY (Prsten Osudu) — výběr aktivního gemu =====
  Widget _gemPanel(BuildContext context, GameState s) {
    final ringMatches = s.inventory.where((i) => i.isArtifact).toList();
    final ring = ringMatches.isNotEmpty ? ringMatches.first : null;
    if (ring == null) {
      return FantasyPanel(
        title: tr('GEMY', 'GEMS'),
        titleIcon: Icons.diamond_outlined,
        accent: Colors.grey,
        child: Text(
          tr("Zatím nemáš Prsten Osudu. Poraz bosse v Lair 100, abys ho získal.", "You don't have the Ring of Fate yet. Defeat the boss in Lair 100 to get it."),
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    final socketed = ring.gemSlots.where((g) => g != null).cast<String>().toList();
    if (socketed.isEmpty) {
      return FantasyPanel(
        title: tr('GEMY', 'GEMS'),
        titleIcon: Icons.diamond_outlined,
        accent: Colors.grey,
        child: Text(
          tr("Prsten Osudu zatím nemá žádné vsazené gemy. Získáš je za Lair 100 kill v Hardcore módu s aktivním Prokletím.", "The Ring of Fate doesn't have any socketed gems yet. You get them from Lair 100 kills in Hardcore mode with an active Curse."),
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    // Seskup podle jména gemu -> počet kusů.
    final Map<String, int> counts = {};
    for (final g in socketed) {
      counts[g] = (counts[g] ?? 0) + 1;
    }
    return FantasyPanel(
      title: tr('GEMY', 'GEMS'),
      titleIcon: Icons.diamond,
      accent: const Color(0xFFB794F6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr("Vsazeno: ${socketed.length}/${ring.gemSlotCount} slotů. Aktivní může být jen jeden typ.", "Socketed: ${socketed.length}/${ring.gemSlotCount} slots. Only one type can be active."), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          for (final entry in counts.entries)
            Card(
              color: s.activeGemType == entry.key ? const Color(0xFF2A1F3D) : const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: s.activeGemType == entry.key ? const Color(0xFFB794F6) : Colors.grey.shade800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text("${entry.key} (×${entry.value})", style: const TextStyle(fontWeight: FontWeight.bold, color: FantasyColors.parchment)),
                subtitle: Text(
                  tr("${s.gemEffectDescriptionFor(entry.key)}\nAktuální síla: ${(entry.value * GameState.gemMagnitudePerCount * 100).round().toString()} %", "${s.gemEffectDescriptionFor(entry.key)}\nCurrent strength: ${(entry.value * GameState.gemMagnitudePerCount * 100).round().toString()}%"),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                isThreeLine: true,
                trailing: s.activeGemType == entry.key
                    ? const Icon(Icons.check_circle, color: Color(0xFFB794F6))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB794F6)),
                        onPressed: () => s.setActiveGem(entry.key),
                        child: Text(tr("Aktivovat", "Activate")),
                      ),
              ),
            ),
          if (s.activeGemType != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => s.setActiveGem(null),
                child: Text(tr("Zrušit aktivní gem", "Clear active gem"), style: const TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _altCatchUpPanel(BuildContext context, GameState s) {
    final bonusPercent = ((s.altCatchUpBonus - 1) * 100).round().toString();
    final milestoneCount = s.paragonCentMilestones.length;
    final nextMilestone = (milestoneCount + 1) * 100;
    return FantasyPanel(
      title: tr('ALT CATCH-UP', 'ALT CATCH-UP'),
      titleIcon: Icons.trending_up,
      accent: const Color(0xFF00E676),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            milestoneCount > 0
                ? tr("Dosaženo $milestoneCount× Paragon setnina. Třídy pozadu za tvou nejsilnější dostávají +$bonusPercent % rank/Paragon.", "Reached $milestoneCount× Paragon hundred-mark. Classes behind your strongest one get +$bonusPercent% rank/Paragon.")
                : tr("Za každých 100 Paragon (na libovolné třídě) získáš +50 % rychlejší rank/Paragon pro ostatní třídy na účtu.", "For every 100 Paragon (on any class) you get +50% faster rank/Paragon for other classes on your account."),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(tr("Další bonus při Paragon $nextMilestone.", "Next bonus at Paragon $nextMilestone."), style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontStyle: FontStyle.italic)),
          if (s.isPlayingAlt) ...[
            const SizedBox(height: 6),
            Text(tr("Právě hraješ alta - tahle třída dostává bonus aktivně.", "You're currently playing an alt - this class is actively receiving the bonus."), style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              tr("Nejvyšší třída na účtu: ${s.highestRankClass.name.toUpperCase()} (rank ${s.classRanks[s.highestRankClass] ?? 0}) - vůči té se porovnává.",
                  "Highest-rank class on this account: ${s.highestRankClass.name.toUpperCase()} (rank ${s.classRanks[s.highestRankClass] ?? 0}) - compared against that."),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

}

// ===== ACHIEVEMENTY — samostatná obrazovka (dřív panel v Profilu), viz spodní navigace =====
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      final defs = GameState.achievementDefs; // spočítat jednou, ne 1x na každý achievement v loopu níž
      final total = AchievementId.values.length;
      final unlocked = state.unlockedAchievements.length;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr("Achievementy — splněno: $unlocked / $total", "Achievements — completed: $unlocked / $total"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
          const SizedBox(height: 10),
          if (state.unlockedAchievements.isNotEmpty) ...[
            Row(
              children: [
                Text(tr("Aktivní titul: ", "Active title: "), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                DropdownButton<AchievementId?>(
                  value: state.activeTitle,
                  dropdownColor: const Color(0xFF1E1E24),
                  hint: Text(tr("Žádný", "None"), style: const TextStyle(color: Colors.grey)),
                  items: [
                    DropdownMenuItem<AchievementId?>(value: null, child: Text(tr("Žádný", "None"), style: const TextStyle(color: Colors.grey))),
                    ...state.unlockedAchievements.map((a) => DropdownMenuItem<AchievementId?>(
                          value: a,
                          child: Text(defs[a]!.title, style: const TextStyle(color: FantasyColors.parchment)),
                        )),
                  ],
                  onChanged: (v) => state.setActiveTitle(v),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          for (final id in AchievementId.values)
            Builder(builder: (context) {
              final def = defs[id]!;
              final done = state.unlockedAchievements.contains(id);
              return Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: done ? const Color(0xFFFFD700) : Colors.grey.shade800, width: done ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(done ? Icons.emoji_events : Icons.lock_outline, color: done ? const Color(0xFFFFD700) : Colors.grey),
                  title: Text(def.name, style: TextStyle(fontWeight: FontWeight.bold, color: done ? FantasyColors.parchment : Colors.grey)),
                  subtitle: Text(def.description, style: TextStyle(fontSize: 11, color: done ? Colors.grey : Colors.grey.shade700)),
                  trailing: done ? Text('„${def.title}“', style: const TextStyle(fontSize: 11, color: Color(0xFFFFD700), fontStyle: FontStyle.italic)) : null,
                ),
              );
            }),
        ],
      );
    });
  }
}

// ===== PROMO KÓDY — UI panel =====
class PromoCodePanel extends StatefulWidget {
  const PromoCodePanel({super.key});
  @override
  State<PromoCodePanel> createState() => _PromoCodePanelState();
}

class _PromoCodePanelState extends State<PromoCodePanel> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    return FantasyPanel(
      title: 'PROMO KÓD',
      titleIcon: Icons.card_giftcard,
      accent: const Color(0xFF00E5A0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: "Zadej kód...",
                    hintStyle: TextStyle(color: Colors.grey),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _redeem(state),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5A0)),
                onPressed: () => _redeem(state),
                child: const Text("Uplatnit"),
              ),
            ],
          ),
          if (state.redeemedPromoCodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("Uplatněné kódy: ${state.redeemedPromoCodes.join(', ')}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  void _redeem(GameState state) {
    state.redeemPromoCode(_controller.text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }
}

// ===== POTULNÝ OBCHODNÍK — sdílené UI pro Věž i Rift =====
class MerchantEncounterView extends StatelessWidget {
  const MerchantEncounterView({super.key});

  Widget _materialRow(BuildContext context, GameState state, String label, int price, int owned, Color color, IconData icon) {
    return Card(
      color: const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(side: BorderSide(color: color, width: 1), borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                const Spacer(),
                Text("Máš: $owned", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Text("$price 🪙 / kus", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: state.gold >= price * 5 ? () => state.buyFromMerchant(5) : null,
                  child: Text("Koupit 5 (${price * 5} 🪙)"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: state.gold >= price * 20 ? () => state.buyFromMerchant(20) : null,
                  child: Text("Koupit 20 (${price * 20} 🪙)"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (context, state, _) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("🧳 Potulný obchodník", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFC9A96E))),
            const Text("Nabízí suroviny na craftění výměnou za zlato. Zůstane, dokud neodejdeš.", style: TextStyle(color: Colors.grey)),
            CheckboxListTile(
              value: state.pauseAutoBattleOnMerchant,
              onChanged: (v) => state.setPauseAutoBattleOnMerchant(v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFFC9A96E),
              title: const Text("Příště pozastavit auto-boj u obchodníka", style: TextStyle(fontSize: 13, color: Color(0xFFF1E6D0))),
              subtitle: const Text("Vypni, pokud chceš, aby auto-boj obchodníka rovnou minul bez zastavení.", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Text("Máš: ${state.gold} 🪙", style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (state.message.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(state.message, textAlign: TextAlign.center)),
            _materialRow(context, state, "Suroviny", GameState.merchantMaterialsPrice, state.materials, FantasyColors.bronze, Icons.handyman),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF33333D)),
              icon: const Icon(Icons.exit_to_app),
              label: const Text("Opustit obchodníka"),
              onPressed: () => state.leaveMerchant(),
            ),
          ],
        ),
      );
    });
  }
}

// ===== ÚVODNÍ INTRODUKCE =====
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  Widget _bullet(String title, String body, {required IconData icon, Color accent = const Color(0xFFFFB100)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFFF1E6D0)),
                children: [
                  TextSpan(text: '$title: ', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    // Cíl týhle obrazovky: hráč, co už hrál jiné ARPG, zjistí za 20 vteřin čtení, čím je TAHLE
    // hra jiná - žádné obecné lore, žádné "tohle je Věž, postupuj patro po patře" (to už zná).
    // Rovnou k věcem, co jsou specifické pro tenhle titul a nedají se odjinud odhadnout.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "VĚŽE OSUDU",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFB100), letterSpacing: 3),
              ),
              const SizedBox(height: 4),
              Text(
                tr('Co je tu jinak - 6 věcí, co potřebuješ vědět:', "What's different here - 6 things you need to know:"),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bullet(
                      tr('Smrt', 'Death'),
                      tr('nenasazený a neuzamčený (🔒) gear se roztaví na Magic Dust. Rank, Paragon a žebříček zůstávají navždy - jen aktuální postup na patře a talenty se resetují.',
                          'unequipped, unlocked (🔒) gear melts into Magic Dust. Rank, Paragon and the ladder stay forever - only your current floor progress and talents reset.'),
                      icon: Icons.dangerous,
                      accent: Colors.redAccent,
                    ),
                    _bullet(
                      tr('Obtížnosti jsou vrstvené', 'Difficulties stack, not branch'),
                      tr('Normal → Hardcore → Předpeklí → Peklo jdou NAD sebe, ne vedle sebe. Smrt tě posune jen o jeden stupeň zpátky, ne rovnou na Normal.',
                          'Normal → Hardcore → Netherworld → Hell stack ON TOP of each other, not side by side. Death only drops you one tier back, not straight to Normal.'),
                      icon: Icons.layers,
                      accent: const Color(0xFFFF6B00),
                    ),
                    _bullet(
                      tr('Rank & Paragon jsou permanentní', 'Rank & Paragon are permanent'),
                      tr('Rostou za krystaly/rank-up per třída a nikdy neklesají. Specializace (mění celý build) se odemyká na level 25 + Paragon 10.',
                          "Grow per class via crystals/rank-ups and never decrease. Specialization (reshapes your whole build) unlocks at level 25 + Paragon 10."),
                      icon: Icons.military_tech,
                      accent: const Color(0xFFFFD700),
                    ),
                    _bullet(
                      tr('Alt postup je rychlejší', 'Alt progress is faster'),
                      tr('Každých 100 Paragon na tvé nejsilnější třídě zrychlí rank/Paragon o +50 % na všech ostatních - vyplatí se zkoušet další povolání.',
                          'Every 100 Paragon on your strongest class speeds up rank/Paragon by +50% on every other class - trying other classes pays off.'),
                      icon: Icons.trending_up,
                      accent: const Color(0xFF00E676),
                    ),
                    _bullet(
                      tr('První společník je povinný', 'Your first companion is mandatory'),
                      tr('Po tvé první smrti si musíš najmout společníka, než budeš pokračovat dál - ten první je zdarma.',
                          "After your first death you must hire a companion before continuing - the first one is free."),
                      icon: Icons.groups,
                      accent: const Color(0xFF9575CD),
                    ),
                    _bullet(
                      tr('Systémy se odemykají postupně', 'Systems unlock gradually'),
                      tr('Tržiště, Kovárna, Banka, Doupě bosse, Aréna, Trhlina Osudu a další se objeví podle tvého levelu - nic z toho není trvale skryté, jen počkej.',
                          "Market, Forge, Bank, Boss Lair, Arena, Rift and more appear based on your level - nothing is permanently hidden, it just takes time."),
                      icon: Icons.explore,
                      accent: const Color(0xFF29B6F6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB100), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                onPressed: () => state.completeIntro(),
                child: const Text("Začít svou pouť", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

