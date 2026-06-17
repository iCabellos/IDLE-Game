import 'package:flutter/material.dart';

import '../game/game.dart';
import 'pixel_art.dart';

/// All sprites are hand-drawn here as character maps — nothing is loaded from
/// disk or the network. Heroes are drawn facing RIGHT (party stands on the
/// left); enemies are drawn facing LEFT (they stand on the right).

const _o = Color(0xFF0E1622); // universal dark outline

// --------------------------------------------------------------------------
// HEROES
// --------------------------------------------------------------------------

const _knight = PixelArt(
  rows: [
    '.....oooo.....',
    '....osssso....',
    '....osmmso....',
    '...oshhhhso...',
    '...oskkkkso...',
    '...oskekkso...',
    '...oskkkkso...',
    '..ooobbbboo...',
    '.obbbbbbbbbo.w',
    '.obdbbbbdbbo.w',
    '.obbbbbbbbbogw',
    '.oobbbbbbboo g',
    '...obb.bbo...g',
    '...od...do....',
    '...oo...oo....',
  ],
  palette: {
    'o': _o,
    's': Color(0xFFB9C4D4),
    'm': Color(0xFF5B6B7E),
    'h': Color(0xFFE7ECF3),
    'k': Color(0xFFE8B98A),
    'e': Color(0xFF11202E),
    'b': Color(0xFF3D6FB4),
    'd': Color(0xFF274C82),
    'w': Color(0xFFD7DEE8),
    'g': Color(0xFFE3B341),
  },
);

const _mage = PixelArt(
  rows: [
    '......oo......',
    '.....oppo.....',
    '....opppo.....',
    '...opPppo.....',
    '..opppppo.....',
    '...okkkko.s...',
    '...okekko.s...',
    '..orrrrro.y...',
    '..orrrrro.s...',
    '.orrrrrrro....',
    '.orPrrrPro....',
    '.orrrrrrro....',
    '..orr.rro.....',
    '..oo...oo.....',
  ],
  palette: {
    'o': _o,
    'p': Color(0xFF7C5CC4),
    'P': Color(0xFF4F3A86),
    'k': Color(0xFFE8B98A),
    'e': Color(0xFF11202E),
    'r': Color(0xFF5847A8),
    's': Color(0xFF8A5A2B),
    'y': Color(0xFF3FE0E0),
  },
);

const _ranger = PixelArt(
  rows: [
    '.....ooo......',
    '....onnno.....',
    '...onnnno..t..',
    '...onkkno.Bt..',
    '...okekno.B.t.',
    '...okkkno.B..t',
    '..ovvvvvoB...t',
    '..ovvvvvoB..t.',
    '.ovvvvvvoBt...',
    '.ovNvvNvoB....',
    '.ovvvvvvoB....',
    '..ov.vvo......',
    '..oo..oo......',
  ],
  palette: {
    'o': _o,
    'n': Color(0xFF3E8E5A),
    'N': Color(0xFF276B45),
    'k': Color(0xFFE8B98A),
    'e': Color(0xFF11202E),
    'v': Color(0xFF6B4A2A),
    'B': Color(0xFFB07A3C),
    't': Color(0xFFE7ECF3),
  },
);

// --------------------------------------------------------------------------
// ENEMIES (face left)
// --------------------------------------------------------------------------

const _slime = PixelArt(
  rows: [
    '....oooo....',
    '..ooggggoo..',
    '.oghggggGo..',
    'oggggggggGo.',
    'ogWggWgggGo.',
    'ogeggegggGo.',
    'oggggggggGo.',
    'oGgggggggGo.',
    '.oGGgggGGo..',
    '..oooooooo..',
  ],
  palette: {
    'o': Color(0xFF0E3B24),
    'g': Color(0xFF49C06B),
    'G': Color(0xFF2E8E4C),
    'h': Color(0xFF9BE7AD),
    'W': Color(0xFFFFFFFF),
    'e': Color(0xFF0E1622),
  },
);

const _bat = PixelArt(
  rows: [
    'oo........oo',
    'opo......opo',
    'oppo....oppo',
    'opppooooooppo',
    'oppppppppppPo',
    '.oppeppeppPo.',
    '..oppppppPo..',
    '...oP..Po....',
  ],
  palette: {
    'o': Color(0xFF1E1430),
    'p': Color(0xFF8458C6),
    'P': Color(0xFF5A3C8E),
    'e': Color(0xFFE05656),
  },
);

const _goblin = PixelArt(
  rows: [
    '..o.......o..',
    '.ono.....ono.',
    '.onno...onno.',
    '..onnnnnnno..',
    '.onnnnnnnnno.',
    '.oneennneeno.',
    '.onnnnnnnnno.',
    '.onmtmtmtmno.',
    '.oonnnnnnoo..',
    '..onnnnnno...',
    '..onllllno...',
    '..on.nn.no...',
    '..oo...oo....',
  ],
  palette: {
    'o': Color(0xFF143018),
    'n': Color(0xFF6FB04A),
    'e': Color(0xFFE0C040),
    'm': Color(0xFF5A1414),
    't': Color(0xFFE7ECEC),
    'l': Color(0xFF8A5A2B),
  },
);

const _skeleton = PixelArt(
  rows: [
    '...ooooo...',
    '..obbbbbo..',
    '..obBBBbo..',
    '..obeebeo..',
    '..obbbbbo..',
    '..oobbboo..',
    '....obo....',
    '..obbbbbo..',
    '.obBbBbBbo.',
    '.obbBbBbbo.',
    '.obbbbbbbo.',
    '..ob.b.bo..',
    '..ob...bo..',
    '..oo...oo..',
  ],
  palette: {
    'o': Color(0xFF20262B),
    'b': Color(0xFFE7ECEC),
    'B': Color(0xFFA9B2B2),
    'e': Color(0xFF11161A),
  },
);

const _orc = PixelArt(
  rows: [
    '...oo....oo...',
    '..onno..onno..',
    '..onnnnnnnno..',
    '.onnnnnnnnnno.',
    '.oneennneenno',
    '.onnnnnnnnnno',
    '.ontnnnnnntno',
    '.onnmmmmmmnno',
    '..oAnnnnnnAo.',
    '..oAAnnnnAAo.',
    '..oAnnnnnnAo.',
    '..onn.nn.nno.',
    '..oo......oo.',
  ],
  palette: {
    'o': Color(0xFF12260F),
    'n': Color(0xFF5E8C3A),
    'e': Color(0xFFE05656),
    't': Color(0xFFE7ECEC),
    'm': Color(0xFF2E4A1C),
    'A': Color(0xFF6B4A2A),
  },
);

const _demon = PixelArt(
  rows: [
    '..h..........h..',
    '..hh........hh..',
    '..hro......orh..',
    '.orrroooooorrro.',
    'orrrrrrrrrrrrrro',
    'orrReerrrreeRrro',
    'orrrrrrrrrrrrrro',
    'worrtrrmmrrtrrow',
    'wworrrmmmmrrroww',
    'wwoRrrrrrrrrRoww',
    '.woRRrrrrrrRRow.',
    '..oRrr.rr.rrRo..',
    '..orr..rr..rro..',
    '..oo........oo..',
  ],
  palette: {
    'o': Color(0xFF2A0E0E),
    'r': Color(0xFFC23B3B),
    'R': Color(0xFF7E2222),
    'e': Color(0xFFF2D24B),
    'h': Color(0xFFE7DCC0),
    't': Color(0xFFFFFFFF),
    'm': Color(0xFF3A0F0F),
    'w': Color(0xFF5A1E1E),
  },
);

// --------------------------------------------------------------------------
// SLOT SYMBOLS (small 9x9 icons for the 3x3 engine)
// --------------------------------------------------------------------------

const _symSword = PixelArt(
  rows: [
    '......ooo',
    '.....osso',
    '....osso.',
    '...osso..',
    '..osso.o.',
    '.osso.oo.',
    'gsso.ooo.',
    'ggo.ooo..',
    'oo.......',
  ],
  palette: {
    'o': Color(0xFF0E1622),
    's': Color(0xFFD7DEE8),
    'g': Color(0xFFE3B341),
  },
);

const _symFire = PixelArt(
  rows: [
    '....o....',
    '...ofo...',
    '..offfo..',
    '..offFo..',
    '.offFFfo.',
    '.offFyfo.',
    '.offyyfo.',
    '..offfo..',
    '...ooo...',
  ],
  palette: {
    'o': Color(0xFF3A1402),
    'f': Color(0xFFFB923C),
    'F': Color(0xFFFFD24B),
    'y': Color(0xFFFFF1B0),
  },
);

const _symBolt = PixelArt(
  rows: [
    '...ooo...',
    '..obbo...',
    '.obbo....',
    '.obboooo.',
    'obbbbbbo.',
    '.oooobbo.',
    '....obbo.',
    '...obbo..',
    '...ooo...',
  ],
  palette: {
    'o': Color(0xFF3A3208),
    'b': Color(0xFFFACC15),
  },
);

const _symShield = PixelArt(
  rows: [
    '.ooooooo.',
    'osssssso',
    'osgggggso',
    'osgsssgso',
    'osgsgsgso',
    '.osgsgso.',
    '..osgso..',
    '...oso...',
    '....o....',
  ],
  palette: {
    'o': Color(0xFF0C3322),
    's': Color(0xFF34D399),
    'g': Color(0xFF0E7C57),
  },
);

const _symStar = PixelArt(
  rows: [
    '....o....',
    '....p....',
    '...ppp...',
    'oppPPPppo',
    '.opPPPpo.',
    '..pPPPp..',
    '..pp.pp..',
    '.pp...pp.',
    'oo.....oo',
  ],
  palette: {
    'o': Color(0xFF2E1A57),
    'p': Color(0xFFA78BFA),
    'P': Color(0xFFE9DDFF),
  },
);

/// Public sprite registry.
class Sprites {
  Sprites._();

  static PixelArt hero(HeroClass k) => switch (k) {
        HeroClass.knight => _knight,
        HeroClass.mage => _mage,
        HeroClass.ranger => _ranger,
      };

  static PixelArt enemy(EnemyKind k) => switch (k) {
        EnemyKind.slime => _slime,
        EnemyKind.bat => _bat,
        EnemyKind.goblin => _goblin,
        EnemyKind.skeleton => _skeleton,
        EnemyKind.orc => _orc,
        EnemyKind.demon => _demon,
      };

  static PixelArt slotIcon(SlotSymbol s) => switch (s) {
        SlotSymbol.sword => _symSword,
        SlotSymbol.fire => _symFire,
        SlotSymbol.bolt => _symBolt,
        SlotSymbol.shield => _symShield,
        SlotSymbol.star => _symStar,
      };
}
