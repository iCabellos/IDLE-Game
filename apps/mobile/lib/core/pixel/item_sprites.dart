import 'package:flutter/material.dart';

import '../game/game.dart';
import '../inventory/inventory_model.dart';
import 'pixel_art.dart';
import 'sprites.dart';

/// Hand-drawn, higher-resolution item icons with built-in "story" detail, plus
/// the extra roster heroes. Nothing is loaded from disk or the network.
///
/// The characters 'X' (bright) and 'x' (dark) are RARITY ACCENTS — gems, runes
/// and glows that the renderer recolours per item rarity, so an item's tier
/// reads instantly from its own artwork (not just the frame).

/// Shared item palette. 'X'/'x' are placeholders, recoloured at render time.
const Map<String, Color> _pal = {
  'o': Color(0xFF0B0F16), // outline
  'K': Color(0xFF3C4654), // darkest steel
  'd': Color(0xFF6B7787), // steel
  'm': Color(0xFF8B97A6), // steel mid
  'M': Color(0xFFC2CCD8), // steel light
  'H': Color(0xFFEAF0F7), // highlight
  'g': Color(0xFFE3B341), // gold
  'G': Color(0xFF9C6F1E), // gold dark
  'l': Color(0xFF6B4A2A), // wood / leather
  'L': Color(0xFF4A3018), // wood dark
  'b': Color(0xFFDCE3EC), // blade
  'r': Color(0xFF8A3B2B), // red leather
  's': Color(0xFF8A5A2B), // shaft
  't': Color(0xFFE7ECF3), // string / cloth
  'X': Color(0xFF67E8F9), // rarity bright (recoloured)
  'x': Color(0xFF2A8C9C), // rarity dark   (recoloured)
};

const _helm = PixelArt(rows: [
  '......XX......',
  '.....XxxX.....',
  '.....Xxx......',
  '....oMMMMo....',
  '...oMHHHHMo...',
  '..oMMddddMMo..',
  '..oMd....dMo..',
  '..oMd.oo.dMo..',
  '..oMMddddMMo..',
  '..oMHHHHHHMo..',
  '...oMMMMMMo...',
  '...oMd..dMo...',
  '....oo..oo....',
], palette: _pal);

const _chest = PixelArt(rows: [
  '.oo......oo.',
  'oMMo....oMMo',
  'oMHMooooMHMo',
  '.oMMMMMMMMo.',
  '.oMHHHHHHMo.',
  '.oMd.XX.dMo.',
  '.oMd.xx.dMo.',
  '.oMMddddMMo.',
  '.oMHMMMMHMo.',
  '.oMMd..dMMo.',
  '..oMMMMMMo..',
  '...oo..oo...',
], palette: _pal);

const _greaves = PixelArt(rows: [
  '.oMMo..oMMo.',
  '.oMHo..oMHo.',
  '.oMMo..oMMo.',
  '.oMdo..odMo.',
  '.oMMo..oMMo.',
  '.oMHoXXoMHo.',
  '.oMMoxxoMMo.',
  '.oMMo..oMMo.',
  '.oMdo..odMo.',
  '.ooMo..oMoo.',
  '..oo....oo..',
], palette: _pal);

const _boots = PixelArt(rows: [
  '.oMMo..oMMo.',
  '.oMHo..oMHo.',
  '.oMdo..odMo.',
  '.oMMo..oMMo.',
  '.oMMooooMMo.',
  '.oMHHHHHHMo.',
  'oMMddXXddMMo',
  'oMHHHxHHHHMo',
  'oooooooooooo',
], palette: _pal);

const _gloves = PixelArt(rows: [
  'oMo......oMo',
  'oMMo....oMMo',
  'oMHMo..oMHMo',
  'oMMMMooMMMMo',
  'oMHHMMMMHHMo',
  '.oMdXXXXdMo.',
  '.oMMxxxxMMo.',
  '.oMMMMMMMMo.',
  '..oMMMMMMo..',
  '...oMMMMo...',
  '....oooo....',
], palette: _pal);

const _ring = PixelArt(rows: [
  '....oXXo....',
  '...oXxxXo...',
  '...oXxxXo...',
  '..ogGGGGgo..',
  '.og......go.',
  'og........go',
  'og........go',
  'og........go',
  '.og......go.',
  '..ogGGGGgo..',
  '...oooooo...',
], palette: _pal);

const _amulet = PixelArt(rows: [
  '.o.o....o.o.',
  '.oGo....oGo.',
  '..oGo..oGo..',
  '...oGooGo...',
  '....oGGo....',
  '...ogXXgo...',
  '..ogXxxXgo..',
  '..ogXxxXgo..',
  '...ogXXgo...',
  '....oggo....',
  '.....oo.....',
], palette: _pal);

const _sword = PixelArt(rows: [
  '......HH......',
  '.....HbbH.....',
  '.....HbbH.....',
  '.....HbbH.....',
  '.....HbbH.....',
  '.....HbbH.....',
  '.....mbbm.....',
  '....gXXXXg....',
  '..gG.gXXg.Gg..',
  '......lL......',
  '......lL......',
  '......lL......',
  '.....gXGg.....',
  '......gg......',
], palette: _pal);

const _shield = PixelArt(rows: [
  'oMMMMMMMMMMo',
  'oMHHHHHHHHMo',
  'oMMddddddMMo',
  'oMd.oXXo.dMo',
  'oMd.oXxo.dMo',
  'oMMd.xx.dMMo',
  '.oMMddddMMo.',
  '.oMHHHHHHMo.',
  '..oMMddMMo..',
  '...oMMMMo...',
  '....oMMo....',
  '.....oo.....',
], palette: _pal);

const _bow = PixelArt(rows: [
  '...oGGo.....',
  '..oGllGo...t',
  '.oGl..lo..t.',
  'oGl....o.t..',
  'oGl....X.t..',
  'oGl....o.t..',
  'oGl...lo.t..',
  '.oGl..lo..t.',
  '..oGllGo...t',
  '...oGGo.....',
], palette: _pal);

const _staff = PixelArt(rows: [
  '....oXo....',
  '...oXxXo...',
  '..oXxxxXo..',
  '..oXxXxXo..',
  '..oXxxxXo..',
  '...oXxXo...',
  '....oso....',
  '....olo....',
  '....olo....',
  '....olo....',
  '....olo....',
  '....olo....',
  '....oLo....',
  '....ooo....',
], palette: _pal);

const _relic = PixelArt(rows: [
  '.....oo.....',
  '...oXXXXo...',
  '..oXxxxxXo..',
  '.oXx.XX.xXo.',
  'oXx..XX..xXo',
  'oXx..XX..xXo',
  '.oXx.XX.xXo.',
  '..oXxxxxXo..',
  '...oXXXXo...',
  '....o..o....',
  '..o......o..',
  '.o........o.',
], palette: _pal);

class ItemSprites {
  ItemSprites._();

  static PixelArt shape(ItemShape s) => switch (s) {
        ItemShape.helm => _helm,
        ItemShape.chest => _chest,
        ItemShape.greaves => _greaves,
        ItemShape.boots => _boots,
        ItemShape.gloves => _gloves,
        ItemShape.ring => _ring,
        ItemShape.amulet => _amulet,
        ItemShape.sword => _sword,
        ItemShape.shield => _shield,
        ItemShape.bow => _bow,
        ItemShape.staff => _staff,
        ItemShape.relic => _relic,
      };

  static PixelArt roster(RosterId id) => switch (id) {
        RosterId.knight => Sprites.hero(HeroClass.knight),
        RosterId.mage => Sprites.hero(HeroClass.mage),
        RosterId.ranger => Sprites.hero(HeroClass.ranger),
        RosterId.cleric => _cleric,
        RosterId.rogue => _rogue,
        RosterId.berserker => _berserker,
        RosterId.warden => _berserker,
        RosterId.summoner => _cleric,
      };
}

// --- extra roster heroes (face right) --------------------------------------

const _cleric = PixelArt(rows: [
  '.....oo.....',
  '....owwo....',
  '...owwwwo...',
  '...owggwo...',
  '...okkkko.y.',
  '...okekko.l.',
  '..owwwwwo.l.',
  '..owwwwwo.l.',
  '.owwwwwwwo..',
  '.owWWWWwwo..',
  '.owwwwwwwo..',
  '..oww.wwo...',
  '..oo...oo...',
], palette: {
  'o': Color(0xFF0E1622),
  'w': Color(0xFFE7ECF3),
  'W': Color(0xFFC2CBD6),
  'k': Color(0xFFE8B98A),
  'e': Color(0xFF11202E),
  'g': Color(0xFFE3B341),
  'y': Color(0xFF6EE7B7),
  'l': Color(0xFF8A5A2B),
});

const _rogue = PixelArt(rows: [
  '....ooo.....',
  '...odddo....',
  '..oddddddo..',
  '..odkkkkdo..',
  '..ode..edo..',
  '..odkkkkdo..',
  '.oDddddddDob',
  '.oDddddddDob',
  '.oDddddddDo.',
  '..oDddddDo..',
  '..oDd.dDo...',
  '..oo...oo...',
], palette: {
  'o': Color(0xFF0E1622),
  'd': Color(0xFF2B3340),
  'D': Color(0xFF161B22),
  'k': Color(0xFFE8B98A),
  'e': Color(0xFF67E8F9),
  'b': Color(0xFFD7DEE8),
});

const _berserker = PixelArt(rows: [
  '....rrr.....',
  '...orrro....',
  '..okkkkko...',
  '..okekkko.AA',
  '..okkkkko.Aa',
  '.okkkkkkkoHa',
  '.oKkkkkkkoH.',
  '.okkkkkkkoH.',
  '.oKkkkkkko..',
  '..okkkkko...',
  '..ob.b.bo...',
  '..oo...oo...',
], palette: {
  'o': Color(0xFF0E1622),
  'k': Color(0xFFE8B98A),
  'K': Color(0xFFC98E63),
  'r': Color(0xFFC23B3B),
  'e': Color(0xFF11202E),
  'A': Color(0xFFC0C7D1),
  'a': Color(0xFF8A95A6),
  'H': Color(0xFF8A5A2B),
  'b': Color(0xFF5E3C1C),
});
