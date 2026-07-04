import 'package:flutter/widgets.dart';

import 'pixel_sprite.dart';

/// Shared pixel-art palette. Sprites reference these by single characters.
class Px {
  Px._();

  static const outline = Color(0xFF0B1220); // K
  static const steel = Color(0xFF9FB4C7); // S
  static const steelDark = Color(0xFF64748B); // s
  static const white = Color(0xFFE2E8F0); // W
  static const gold = Color(0xFFFFD700); // G
  static const goldDark = Color(0xFFB8860B); // g
  static const skin = Color(0xFFF0C8A0); // F
  static const red = Color(0xFFDC2626); // R
  static const redDark = Color(0xFF7F1D1D); // r
  static const blue = Color(0xFF1A56A0); // B
  static const blueLight = Color(0xFF60A5FA); // L
  static const cyan = Color(0xFF0EA5E9); // C
  static const green = Color(0xFF34D399); // V
  static const greenDark = Color(0xFF059669); // v
  static const purple = Color(0xFFA78BFA); // P
  static const purpleDark = Color(0xFF6D28D9); // p
  static const wood = Color(0xFF92400E); // N
  static const woodDark = Color(0xFF5B2B0A); // n
  static const bone = Color(0xFFE7E5E4); // O
  static const amber = Color(0xFFD97706); // A
}

const Map<String, Color> _basePalette = {
  'K': Px.outline,
  'S': Px.steel,
  's': Px.steelDark,
  'W': Px.white,
  'G': Px.gold,
  'g': Px.goldDark,
  'F': Px.skin,
  'R': Px.red,
  'r': Px.redDark,
  'B': Px.blue,
  'L': Px.blueLight,
  'C': Px.cyan,
  'V': Px.green,
  'v': Px.greenDark,
  'P': Px.purple,
  'p': Px.purpleDark,
  'N': Px.wood,
  'n': Px.woodDark,
  'O': Px.bone,
  'A': Px.amber,
  'a': Color(0xFF92600A), // amber shade
  'c': Color(0xFF0369A1), // cyan shade
};

/// All hand-drawn sprites used by the UI. 16x16 unless noted.
class Sprites {
  Sprites._();

  // -----------------------------------------------------------------
  // Heroes (starter squad: Vanguard / Ember / Lumen / Frostweaver)
  // -----------------------------------------------------------------

  /// Warrior tank: steel knight, gold shield, sword arm.
  static const warrior = PixelSprite(palette: _basePalette, rows: [
    '......KKKK......',
    '.....KRRRRK.....',
    '....KSSSSSSK....',
    '....KSFFFFSK....',
    '....KSFKFKSK....',
    '.....KFFFFK.....',
    '....KKSSSSKK....',
    '..KKKSSSSSSKKK..',
    '.KGGKSSSSSSKWSK.',
    '.KGgKSsSSsSKWSK.',
    '.KGgKSSSSSSKWSK.',
    '.KKKKSSSSSSKKKK.',
    '....KsSKKSsK....',
    '....KsSK.KsK....',
    '...KKSSK.KSSK...',
    '...KKKK..KKKK...',
  ]);

  /// Berserker DPS: horned, red war paint, twin fists of fury.
  static const berserker = PixelSprite(palette: _basePalette, rows: [
    '..KK........KK..',
    '.KGGK......KGGK.',
    '..KGKKKKKKKKGK..',
    '...KRRRRRRRRK...',
    '...KRFFFFFFRK...',
    '...KRFKFFKFRK...',
    '....KFFFFFFK....',
    '...KKRRRRRRKK...',
    '..KFKRRRRRRKFK..',
    '..KFKRrRRrRKFK..',
    '..KKKRRRRRRKKK..',
    '....KRRRRRRK....',
    '....KrRKKRrK....',
    '....KrRK.KrK....',
    '...KKRRK.KRRK...',
    '...KKKK..KKKK...',
  ]);

  /// Cleric healer: white and gold robes, blessing staff.
  static const cleric = PixelSprite(palette: _basePalette, rows: [
    '.......KKKK...KG',
    '......KWWWWK..KN',
    '......KWFFWK..KN',
    '.....KWFKFKW..KN',
    '......KFFFFK..KN',
    '.....KKWWWWKK.KN',
    '....KWWWWWWWWKKN',
    '....KWWGGGGWWKKN',
    '....KWWWGGWWWKKN',
    '....KWWWGGWWWKKN',
    '....KWWWWWWWWKKN',
    '....KWWWWWWWWK..',
    '....KWWWWWWWWK..',
    '....KWgWWWWgWK..',
    '...KKWWWKKWWWKK.',
    '...KKKKK..KKKKK.',
  ]);

  /// Mage DPS: blue hat and robe, frost magic between the hands.
  static const mage = PixelSprite(palette: _basePalette, rows: [
    '.......KK.......',
    '......KBBK......',
    '.....KBBBBK.....',
    '....KBBBBBBK....',
    '..KKBBBBBBBBKK..',
    '.KBBBBBBBBBBBBK.',
    '..KKKFFFFFFKKK..',
    '....KFKFFKFK....',
    '.....KFFFFK.....',
    '....KKBBBBKK....',
    '..KLKBBBBBBKLK..',
    '..KLKBBLLBBKLK..',
    '..KKKBBLLBBKKK..',
    '....KBBBBBBK....',
    '...KKBBBBBBKK...',
    '...KKKKKKKKKK...',
  ]);

  // -----------------------------------------------------------------
  // Hero idle frames (B poses): a one-pixel crouch, hand-authored so the
  // party breathes in discrete retro steps instead of smooth tweens.
  // -----------------------------------------------------------------

  static const warriorB = PixelSprite(palette: _basePalette, rows: [
    '................',
    '......KKKK......',
    '.....KRRRRK.....',
    '....KSSSSSSK....',
    '....KSFFFFSK....',
    '....KSFKFKSK....',
    '....KKSSSSKK....',
    '..KKKSSSSSSKKK..',
    '.KGGKSSSSSSKWSK.',
    '.KGgKSsSSsSKWSK.',
    '.KGgKSSSSSSKWSK.',
    '.KKKKSSSSSSKKKK.',
    '....KsSKKSsK....',
    '....KsSK.KsK....',
    '...KKSSK.KSSK...',
    '...KKKK..KKKK...',
  ]);

  static const berserkerB = PixelSprite(palette: _basePalette, rows: [
    '................',
    '..KK........KK..',
    '.KGGK......KGGK.',
    '..KGKKKKKKKKGK..',
    '...KRRRRRRRRK...',
    '...KRFFFFFFRK...',
    '...KRFKFFKFRK...',
    '...KKRRRRRRKK...',
    '..KFKRRRRRRKFK..',
    '..KFKRrRRrRKFK..',
    '..KKKRRRRRRKKK..',
    '....KRRRRRRK....',
    '....KrRKKRrK....',
    '....KrRK.KrK....',
    '...KKRRK.KRRK...',
    '...KKKK..KKKK...',
  ]);

  static const clericB = PixelSprite(palette: _basePalette, rows: [
    '................',
    '.......KKKK...KG',
    '......KWWWWK..KN',
    '......KWFFWK..KN',
    '.....KWFKFKW..KN',
    '.....KKWWWWKK.KN',
    '....KWWWWWWWWKKN',
    '....KWWGGGGWWKKN',
    '....KWWWGGWWWKKN',
    '....KWWWGGWWWKKN',
    '....KWWWWWWWWKKN',
    '....KWWWWWWWWK..',
    '....KWWWWWWWWK..',
    '....KWgWWWWgWK..',
    '...KKWWWKKWWWKK.',
    '...KKKKK..KKKKK.',
  ]);

  static const mageB = PixelSprite(palette: _basePalette, rows: [
    '................',
    '.......KK.......',
    '......KBBK......',
    '.....KBBBBK.....',
    '....KBBBBBBK....',
    '..KKBBBBBBBBKK..',
    '.KBBBBBBBBBBBBK.',
    '..KKKFFFFFFKKK..',
    '....KFKFFKFK....',
    '....KKBBBBKK....',
    '..KLKBBBBBBKLK..',
    '..KLKBBLLBBKLK..',
    '..KKKBBLLBBKKK..',
    '....KBBBBBBK....',
    '...KKBBBBBBKK...',
    '...KKKKKKKKKK...',
  ]);

  // -----------------------------------------------------------------
  // Enemies
  // -----------------------------------------------------------------

  /// Grunt: a grumpy dungeon slime.
  static const slime = PixelSprite(palette: _basePalette, rows: [
    '................',
    '................',
    '................',
    '......KKKK......',
    '....KKVVVVKK....',
    '...KVVVVVVVVK...',
    '..KVVWVVVVWVVK..',
    '..KVVKVVVVKVVK..',
    '.KVVVVVVVVVVVVK.',
    '.KVvVVVVVVVVvVK.',
    '.KVvVKKKKKKVvVK.',
    '.KVVVVVVVVVVVVK.',
    '.KvVVVVVVVVVVvK.',
    '..KvvVVVVVVvvK..',
    '...KKvvvvvvKK...',
    '.....KKKKKK.....',
  ]);

  /// Elite: a restless skeleton warrior.
  static const skeleton = PixelSprite(palette: _basePalette, rows: [
    '.....KKKKKK.....',
    '....KOOOOOOK....',
    '....KOOOOOOK....',
    '....KOKOOKOK....',
    '....KOOOOOOK....',
    '.....KOKKOK.....',
    '....KKKOOKKK....',
    '..KKOOKOOKOOKK..',
    '.KOKKOKOOKOKKOK.',
    '.KOK.KOOOOK.KOK.',
    '.KKK.KOKKOK.KKK.',
    '.....KOOOOK.....',
    '.....KOKKOK.....',
    '.....KOKKOK.....',
    '....KKOKKOKK....',
    '....KKK..KKK....',
  ]);

  /// Zone boss: horned overlord with burning eyes.
  static const boss = PixelSprite(palette: _basePalette, rows: [
    '.KK..........KK.',
    'KrrK........KrrK',
    'KrrrKKKKKKKKrrrK',
    '.KrrrRRRRRRrrrK.',
    '..KRRRRRRRRRRK..',
    '..KRGKRRRRKGRK..',
    '..KRRRRRRRRRRK..',
    '...KRRKKKKRRK...',
    '..KKRRRRRRRRKK..',
    '.KrKRRRRRRRRKrK.',
    '.KrKRrRRRRrRKrK.',
    '.KKKRRRRRRRRKKK.',
    '....KRRRRRRK....',
    '....KrRKKRrK....',
    '...KKRRK.KRRK...',
    '...KKKK..KKKK...',
  ]);

  /// Slime squash frame: flatter and wider, mid-bounce.
  static const slimeB = PixelSprite(palette: _basePalette, rows: [
    '................',
    '................',
    '................',
    '................',
    '................',
    '......KKKK......',
    '....KKVVVVKK....',
    '...KVVVVVVVVK...',
    '..KVWVVVVVVWVK..',
    '..KVKVVVVVVKVK..',
    '.KVVVVVVVVVVVVK.',
    'KVVvVKKKKKKVvVVK',
    'KVVVVVVVVVVVVVVK',
    'KvVVVVVVVVVVVVvK',
    '.KvvVVVVVVVVvvK.',
    '..KKKKKKKKKKKK..',
  ]);

  /// Boss menace frame: eyes flare white.
  static const bossB = PixelSprite(palette: _basePalette, rows: [
    '.KK..........KK.',
    'KrrK........KrrK',
    'KrrrKKKKKKKKrrrK',
    '.KrrrRRRRRRrrrK.',
    '..KRRRRRRRRRRK..',
    '..KRWKRRRRKWRK..',
    '..KRRRRRRRRRRK..',
    '...KRRKKKKRRK...',
    '..KKRRRRRRRRKK..',
    '.KrKRRRRRRRRKrK.',
    '.KrKRrRRRRrRKrK.',
    '.KKKRRRRRRRRKKK.',
    '....KRRRRRRK....',
    '....KrRKKRrK....',
    '...KKRRK.KRRK...',
    '...KKKK..KKKK...',
  ]);

  // -----------------------------------------------------------------
  // Attack slash: a three-frame diagonal arc in steel and white. Drawn
  // over the enemy for ~200ms during the battle-diorama strike.
  // -----------------------------------------------------------------

  static const slash1 = PixelSprite(palette: _basePalette, rows: [
    '............WW..',
    '...........WWS..',
    '..........WWS...',
    '.........WWS....',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
  ]);

  static const slash2 = PixelSprite(palette: _basePalette, rows: [
    '............WW..',
    '...........WWS..',
    '..........WWS...',
    '.........WWS....',
    '........WWS.....',
    '.......WWS......',
    '......WWS.......',
    '.....WWS........',
    '....WWS.........',
    '...WWS..........',
    '..WWS...........',
    '..WW............',
    '................',
    '................',
    '................',
    '................',
  ]);

  static const slash3 = PixelSprite(palette: _basePalette, rows: [
    '................',
    '................',
    '..........S.....',
    '................',
    '.......W........',
    '................',
    '................',
    '....S...........',
    '................',
    '..W.............',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
  ]);

  /// Idle frame pairs, ready to feed AnimatedPixelArt.
  static const warriorFrames = [warrior, warriorB];
  static const berserkerFrames = [berserker, berserkerB];
  static const clericFrames = [cleric, clericB];
  static const mageFrames = [mage, mageB];
  static const slimeFrames = [slime, slimeB];
  static const bossFrames = [boss, bossB];
  static const slashFrames = [slash1, slash2, slash3];

  // -----------------------------------------------------------------
  // Items by equipment slot
  // -----------------------------------------------------------------

  static const helmet = PixelSprite(palette: _basePalette, rows: [
    '................',
    '................',
    '.......KKK......',
    '.....KKRRRKK....',
    '....KSSKRKSSK...',
    '...KSSSSSSSSSK..',
    '...KSSSSSSSSSK..',
    '..KSSSSSSSSSSSK.',
    '..KSKKKKKKKKKSK.',
    '..KSK.KSSK..KSK.',
    '..KSK.KSSK..KSK.',
    '..KSSKSSSSKSSSK.',
    '...KSSSKKSSSSK..',
    '....KKKS.KKKK...',
    '................',
    '................',
  ]);

  static const chestplate = PixelSprite(palette: _basePalette, rows: [
    '................',
    '................',
    '..KKK......KKK..',
    '.KSSSKKKKKKSSSK.',
    '.KSSSSSSSSSSSSK.',
    '.KSKSSSSSSSSKSK.',
    '.KSKSsSSSSsSKSK.',
    '.KKKSSSSSSSSKKK.',
    '...KSSGKKGSSK...',
    '...KSSKGGKSSK...',
    '...KSSSKKSSSK...',
    '...KsSSSSSSsK...',
    '...KsSSSSSSsK...',
    '....KKKKKKKK....',
    '................',
    '................',
  ]);

  static const greaves = PixelSprite(palette: _basePalette, rows: [
    '................',
    '................',
    '...KKKKKKKKKK...',
    '...KSSSSSSSSK...',
    '...KSSSKKSSSK...',
    '...KSSK..KSSK...',
    '...KSSK..KSSK...',
    '...KsSK..KSsK...',
    '...KsSK..KSsK...',
    '...KsSK..KSsK...',
    '...KSSK..KSSK...',
    '..KKSSK..KSSKK..',
    '..KSSSK..KSSSK..',
    '..KKKKK..KKKKK..',
    '................',
    '................',
  ]);

  static const boots = PixelSprite(palette: _basePalette, rows: [
    '................',
    '................',
    '................',
    '................',
    '....KKK..KKK....',
    '....KNNK.KNNK...',
    '....KNnK.KNnK...',
    '....KNNK.KNNK...',
    '....KNnK.KNnK...',
    '....KNNK.KNNK...',
    '...KKNNK.KNNKK..',
    '..KNNNNKKNNNNNK.',
    '..KNnnNKKNnnnNK.',
    '..KKKKKK.KKKKKK.',
    '................',
    '................',
  ]);

  static const gauntlets = PixelSprite(palette: _basePalette, rows: [
    '................',
    '................',
    '...KK.......KK..',
    '..KSSK.....KSSK.',
    '..KSsSK...KSsSK.',
    '..KSSSK...KSSSK.',
    '.KKSSSKK.KKSSSK.',
    'KSKSSSSK.KSSSSKK',
    'KSSSSSSK.KSSSSSK',
    'KsSSSSSK.KSSSSsK',
    'KsSSSSSK.KSSSSsK',
    '.KSSSSK...KSSSK.',
    '..KKKK.....KKKK.',
    '................',
    '................',
    '................',
  ]);

  static const sword = PixelSprite(palette: _basePalette, rows: [
    '............KK..',
    '...........KWSK.',
    '..........KWSSK.',
    '.........KWSSK..',
    '........KWSSK...',
    '.......KWSSK....',
    '......KWSSK.....',
    '.....KWSSK......',
    '..KK.KSSK.......',
    '..KGKSSK........',
    '...KGSK.........',
    '...KGGK.........',
    '..KNKKGK........',
    '.KNNK.KGK.......',
    '.KnNK..KK.......',
    '..KK............',
  ]);

  static const shield = PixelSprite(palette: _basePalette, rows: [
    '................',
    '..KKKKKKKKKKKK..',
    '.KGGGGGGGGGGGGK.',
    '.KGBBBBBBBBBBGK.',
    '.KGBBBKKKKBBBGK.',
    '.KGBBKGGGGKBBGK.',
    '.KGBBKGGGGKBBGK.',
    '.KGBBBKKKKBBBGK.',
    '.KGBBBBBBBBBBGK.',
    '..KGBBBBBBBBGK..',
    '..KGBBBBBBBBGK..',
    '...KGBBBBBBGK...',
    '....KGBBBBGK....',
    '.....KGBBGK.....',
    '......KGGK......',
    '.......KK.......',
  ]);

  static const warhammer = PixelSprite(palette: _basePalette, rows: [
    '....KKKKKKKK....',
    '...KSSSSSSSSK...',
    '...KSsSSSSsSK...',
    '...KSSSSSSSSK...',
    '...KSSSSSSSSK...',
    '...KSsSSSSsSK...',
    '...KSSSSSSSSK...',
    '....KKKNNKKK....',
    '.......KNK......',
    '.......KNK......',
    '.......KNK......',
    '.......KNK......',
    '.......KNK......',
    '......KGNGK.....',
    '......KGGGK.....',
    '.......KKK......',
  ]);

  static const ring = PixelSprite(palette: _basePalette, rows: [
    '................',
    '................',
    '......KKKK......',
    '.....KPPPPK.....',
    '.....KPppPK.....',
    '......KPPK......',
    '.....KKGGKK.....',
    '....KGGKKGGK....',
    '...KGGK..KGGK...',
    '...KGgK..KgGK...',
    '...KGgK..KgGK...',
    '...KGGK..KGGK...',
    '....KGGKKGGK....',
    '.....KKGGKK.....',
    '................',
    '................',
  ]);

  static const amulet = PixelSprite(palette: _basePalette, rows: [
    '................',
    '....KKK..KKK....',
    '...KG..KK..GK...',
    '...KG......GK...',
    '..KG........GK..',
    '..KG........GK..',
    '..KG........GK..',
    '...KG......GK...',
    '....KGK..KGK....',
    '.....KKGGKK.....',
    '......KCCK......',
    '.....KCCCCK.....',
    '.....KCcCCK.....',
    '......KCCK......',
    '.......KK.......',
    '................',
  ]);

  static const relic = PixelSprite(palette: _basePalette, rows: [
    '.......KK.......',
    '......KAAK......',
    '......KAAK......',
    '.....KAARAK.....',
    '.....KARRAK.....',
    '....KAARRAAK....',
    '....KARRRRAK....',
    '...KAARGGRAAK...',
    '...KARRGGRRAK...',
    '..KAARGGGGRAAK..',
    '..KARRGGGGRRAK..',
    '..KARGGWWGGRAK..',
    '...KAGGWWGGAK...',
    '....KKAGGAKK....',
    '......KKKK......',
    '................',
  ]);

  /// Fallback for slots without bespoke art.
  static const loot = PixelSprite(palette: _basePalette, rows: [
    '................',
    '...KKKKKKKKKK...',
    '..KNNNNNNNNNNK..',
    '.KNnNNNNNNNNnNK.',
    '.KNNNNNNNNNNNNK.',
    '.KKKKKKKKKKKKKK.',
    '.KNNNNKGGKNNNNK.',
    '.KNNNNKGgKNNNNK.',
    '.KNNNNKKKKNNNNK.',
    '.KNnNNNNNNNNnNK.',
    '.KNNNNNNNNNNNNK.',
    '.KNnNNNNNNNNnNK.',
    '..KNNNNNNNNNNK..',
    '...KKKKKKKKKK...',
    '................',
    '................',
  ]);

  // -----------------------------------------------------------------
  // Status + UI icons
  // -----------------------------------------------------------------

  /// Winning: raised victory banner.
  static const banner = PixelSprite(palette: _basePalette, rows: [
    '.KKKKKKKKKKKKKK.',
    '.KVVVVVVVVVVVVK.',
    '.KVvVVVVVVVVvVK.',
    '.KVVVKKKKKKVVVK.',
    '.KVVKGGGGGGKVVK.',
    '.KVVVKGGGGKVVVK.',
    '.KVvVVKGGKVVvVK.',
    '.KVVVVKGGKVVVVK.',
    '.KVVVVVKKVVVVVK.',
    '.KVVVVVVVVVVVVK.',
    '.KVVVKVVVVKVVVK.',
    '.KVVK.KVVK.KVVK.',
    '.KVK...KK...KVK.',
    '.KK..........KK.',
    '.K............K.',
    '................',
  ]);

  /// Danger: a warning skull.
  static const skull = PixelSprite(palette: _basePalette, rows: [
    '................',
    '....KKKKKKKK....',
    '...KOOOOOOOOK...',
    '..KOOOOOOOOOOK..',
    '..KOOOOOOOOOOK..',
    '..KOKKOOOOKKOK..',
    '..KOKKOOOOKKOK..',
    '..KOOOOKKOOOOK..',
    '..KOOOOKKOOOOK..',
    '...KOOOOOOOOK...',
    '...KOKOKKOKOK...',
    '....KOKOOKOK....',
    '....KKOKKOKK....',
    '.....KKKKKK.....',
    '................',
    '................',
  ]);

  /// Stuck: an hourglass running low.
  static const hourglass = PixelSprite(palette: _basePalette, rows: [
    '................',
    '..KKKKKKKKKKKK..',
    '..KNNNNNNNNNNK..',
    '...KKAAAAAAKK...',
    '....KAAAAAAK....',
    '....KAaAAaAK....',
    '.....KAAAAK.....',
    '......KAAK......',
    '......K..K......',
    '.....K....K.....',
    '....K..AA..K....',
    '....K.AAAA.K....',
    '...KKAAAAAAKK...',
    '..KNNNNNNNNNNK..',
    '..KKKKKKKKKKKK..',
    '................',
  ]);

  /// Rewards ready: an overflowing treasure chest.
  static const chest = PixelSprite(palette: _basePalette, rows: [
    '.....G.....G....',
    '..G..KKKKK...G..',
    '...KKNNNNNKK....',
    '..KNNNNNNNNNK...',
    '.KNnNNNNNNNnNK..',
    '.KNNNNNNNNNNNK..',
    '.KKKKKKKKKKKKK..',
    '.KGGGGGGGGGGGK..',
    '.KNNNNKGKNNNNK..',
    '.KNnNNKgKNNnNK..',
    '.KNNNNKKKNNNNK..',
    '.KNnNNNNNNNnNK..',
    '.KNNNNNNNNNNNK..',
    '.KKKKKKKKKKKKK..',
    '................',
    '................',
  ]);

  /// Steam desynced: a broken chain link.
  static const brokenLink = PixelSprite(palette: _basePalette, rows: [
    '................',
    '..KKKK..........',
    '.KSSSSK.........',
    '.KSKKSSK........',
    '.KSK.KSSK.......',
    '.KSK..KSK.......',
    '.KSSK.KSK.......',
    '..KSSKSK...KK...',
    '...KKKK...KSSK..',
    '.......KK.KSSK..',
    '......KSSKKSK...',
    '......KSK.KSK...',
    '.....KSSK.KSSK..',
    '.....KSSKKKSSK..',
    '......KSSSSSK...',
    '.......KKKKK....',
  ]);

  // -----------------------------------------------------------------
  // Navigation + branding
  // -----------------------------------------------------------------

  /// Home tab: the guild-hall castle.
  static const castle = PixelSprite(palette: _basePalette, rows: [
    '................',
    '.KK..KK..KK..KK.',
    '.KSKKSSKKSSKKSK.',
    '.KSSSSSSSSSSSSK.',
    '.KSsSSSsSSSsSSK.',
    '.KSSSSSSSSSSSSK.',
    '.KSSKKSSSSKKSSK.',
    '.KSSKKSSSSKKSSK.',
    '.KSSSSSSSSSSSSK.',
    '.KSsSSKKKKSSsSK.',
    '.KSSSKNNNNKSSSK.',
    '.KSSSKNnNNKSSSK.',
    '.KSSSKNNNNKSSSK.',
    '.KKKKKKKKKKKKKK.',
    '................',
    '................',
  ]);

  /// Inventory tab: adventurer's satchel.
  static const satchel = PixelSprite(palette: _basePalette, rows: [
    '................',
    '.....KKKKKK.....',
    '....KNK..KNK....',
    '...KNK....KNK...',
    '..KKKKKKKKKKKK..',
    '..KNNNNNNNNNNK..',
    '..KNnNNNNNNnNK..',
    '..KNNNNNNNNNNK..',
    '..KKKKKKKKKKKK..',
    '..KNNKGGGGKNNK..',
    '..KNNNKGGKNNNK..',
    '..KNnNNKKNNnNK..',
    '..KNNNNNNNNNNK..',
    '..KKKKKKKKKKKK..',
    '................',
    '................',
  ]);

  /// Widget tab: a magic crystal.
  static const crystal = PixelSprite(palette: _basePalette, rows: [
    '................',
    '.......KK.......',
    '......KCCK......',
    '.....KCCCCK.....',
    '....KCCWCCCK....',
    '...KCCWCCCCCK...',
    '...KCWCCCCCCK...',
    '...KCCCCCCCCK...',
    '...KCCCCCCcCK...',
    '....KCCCCcCK....',
    '.....KCCCCK.....',
    '......KCCK......',
    '.......KK.......',
    '................',
    '................',
    '................',
  ]);

  /// Title emblem: crossed sword over a crowned shield.
  static const emblem = PixelSprite(palette: _basePalette, rows: [
    '.......KK.......',
    '..KK..KWSK..KK..',
    '.KGGK.KWSK.KGGK.',
    '.KGgGKKWSKKGgGK.',
    '..KGGGKSSKGGGK..',
    '...KKKKKKKKKK...',
    '..KGBBBBBBBBGK..',
    '..KGBBLBBLBBGK..',
    '..KGBBBBBBBBGK..',
    '..KGBLBKKBLBGK..',
    '..KGBBBKKBBBGK..',
    '...KGBBBBBBGK...',
    '....KGBBBBGK....',
    '.....KGBBGK.....',
    '......KGGK......',
    '.......KK.......',
  ]);
}

/// Resolves sprites for domain concepts.
class SpriteLibrary {
  SpriteLibrary._();

  static PixelSprite forSlot(String slot) => switch (slot) {
        'Head' => Sprites.helmet,
        'Chest' => Sprites.chestplate,
        'Legs' => Sprites.greaves,
        'Feet' => Sprites.boots,
        'Hands' => Sprites.gauntlets,
        'MainHand' => Sprites.sword,
        'OffHand' => Sprites.shield,
        'TwoHand' => Sprites.warhammer,
        'Ring' => Sprites.ring,
        'Amulet' => Sprites.amulet,
        'Relic1' || 'Relic2' => Sprites.relic,
        _ => Sprites.loot,
      };
}
