import 'package:flutter_test/flutter_test.dart';
import 'package:idle_rpg/core/pixel/pixel_sprite.dart';
import 'package:idle_rpg/core/pixel/sprites.dart';

/// Every sprite in the library, so shape/palette rules run over all art.
const allSprites = <String, PixelSprite>{
  'warrior': Sprites.warrior,
  'warriorB': Sprites.warriorB,
  'berserker': Sprites.berserker,
  'berserkerB': Sprites.berserkerB,
  'cleric': Sprites.cleric,
  'clericB': Sprites.clericB,
  'mage': Sprites.mage,
  'mageB': Sprites.mageB,
  'slime': Sprites.slime,
  'slimeB': Sprites.slimeB,
  'skeleton': Sprites.skeleton,
  'boss': Sprites.boss,
  'bossB': Sprites.bossB,
  'slash1': Sprites.slash1,
  'slash2': Sprites.slash2,
  'slash3': Sprites.slash3,
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
  'fireIcon': Sprites.fireIcon,
  'iceIcon': Sprites.iceIcon,
  'boltIcon': Sprites.boltIcon,
  'poisonIcon': Sprites.poisonIcon,
  'physicalIcon': Sprites.physicalIcon,
  'padlock': Sprites.padlock,
  'compass': Sprites.compass,
  'turnCursor': Sprites.turnCursor,
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

  group('animation frames', () {
    test('every frame set shares one grid size', () {
      const sets = [
        Sprites.warriorFrames, Sprites.berserkerFrames, Sprites.clericFrames,
        Sprites.mageFrames, Sprites.slimeFrames, Sprites.bossFrames,
        Sprites.slashFrames,
      ];
      for (final frames in sets) {
        expect(frames.length, greaterThanOrEqualTo(2));
        for (final frame in frames) {
          expect(frame.width, frames.first.width);
          expect(frame.height, frames.first.height);
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
