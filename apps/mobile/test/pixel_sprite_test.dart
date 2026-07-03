import 'package:flutter_test/flutter_test.dart';
import 'package:idle_rpg/core/pixel/pixel_sprite.dart';
import 'package:idle_rpg/core/pixel/sprites.dart';

/// Every sprite in the library, so shape/palette rules run over all art.
const allSprites = <String, PixelSprite>{
  'warrior': Sprites.warrior,
  'berserker': Sprites.berserker,
  'cleric': Sprites.cleric,
  'mage': Sprites.mage,
  'slime': Sprites.slime,
  'skeleton': Sprites.skeleton,
  'boss': Sprites.boss,
  'helmet': Sprites.helmet,
  'chestplate': Sprites.chestplate,
  'greaves': Sprites.greaves,
  'boots': Sprites.boots,
  'gauntlets': Sprites.gauntlets,
  'sword': Sprites.sword,
  'shield': Sprites.shield,
  'warhammer': Sprites.warhammer,
  'ring': Sprites.ring,
  'amulet': Sprites.amulet,
  'relic': Sprites.relic,
  'loot': Sprites.loot,
  'banner': Sprites.banner,
  'skull': Sprites.skull,
  'hourglass': Sprites.hourglass,
  'chest': Sprites.chest,
  'brokenLink': Sprites.brokenLink,
  'castle': Sprites.castle,
  'satchel': Sprites.satchel,
  'crystal': Sprites.crystal,
  'emblem': Sprites.emblem,
};

void main() {
  group('sprite shapes', () {
    test('every sprite is a uniform non-empty grid', () {
      for (final entry in allSprites.entries) {
        final sprite = entry.value;
        expect(sprite.rows, isNotEmpty, reason: '${entry.key} has no rows');
        for (final (i, row) in sprite.rows.indexed) {
          expect(
            row.length,
            sprite.width,
            reason: '${entry.key} row $i is ${row.length} wide, '
                'expected ${sprite.width}',
          );
        }
      }
    });

    test('every opaque pixel resolves to a palette color', () {
      for (final entry in allSprites.entries) {
        final sprite = entry.value;
        for (final row in sprite.rows) {
          for (final ch in row.split('')) {
            if (ch == '.' || ch == ' ') continue;
            expect(
              sprite.palette.containsKey(ch),
              isTrue,
              reason: '${entry.key} uses unmapped palette char "$ch"',
            );
          }
        }
      }
    });
  });

  group('slot art', () {
    test('all backend equipment slots have bespoke sprites', () {
      const slots = [
        'Head', 'Chest', 'Legs', 'Feet', 'Hands',
        'MainHand', 'OffHand', 'TwoHand', 'Ring', 'Amulet', 'Relic1', 'Relic2',
      ];
      for (final slot in slots) {
        expect(SpriteLibrary.forSlot(slot), isNotNull);
      }
      // Unknown slots fall back to generic loot.
      expect(SpriteLibrary.forSlot('???'), Sprites.loot);
    });
  });
}
