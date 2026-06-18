import 'package:flutter/material.dart';

import '../../core/game/combat_service.dart';
import '../../core/game/server_game.dart';
import '../../core/inventory/inventory_model.dart' show ItemShape, Rarity, RarityX;
import '../../core/pixel/item_sprites.dart';
import '../../core/pixel/pixel_art.dart';

const _pixelFont = 'monospace';

TextStyle _retro(double size, {Color color = const Color(0xFFF1F5F9), FontWeight w = FontWeight.w700}) =>
    TextStyle(fontFamily: _pixelFont, fontSize: size, color: color, fontWeight: w, letterSpacing: 1.0, height: 1.15);

ItemShape _shape(String s) => switch (s) {
      'sword' => ItemShape.sword,
      'shield' => ItemShape.shield,
      'staff' => ItemShape.staff,
      'bow' => ItemShape.bow,
      'amulet' => ItemShape.amulet,
      'earring' => ItemShape.ring,
      'ring' => ItemShape.ring,
      'relic' => ItemShape.relic,
      _ => ItemShape.sword,
    };

Color _rarityColor(int tier) => Rarity.values[(tier - 1).clamp(0, Rarity.values.length - 1)].color;

/// Detail view under the combat panel: the full breakdown of the current roll
/// (each item's primary + every sub-stat) — where there's room to read it.
class BattleDetailScreen extends StatelessWidget {
  const BattleDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080B12),
      child: ValueListenableBuilder<ServerSnapshot?>(
        valueListenable: CombatService.instance.snapshot,
        builder: (context, snap, _) {
          if (snap == null) {
            return Center(child: Text('…', style: _retro(14, color: const Color(0xFF5E7392))));
          }
          final reel = snap.reel;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(reel.damage != null ? '${reel.damage!.heroName.toUpperCase()} — ROLL' : 'CURRENT ROLL',
                        style: _retro(13)),
                    if (reel.combo != 'MIXED')
                      Text('${reel.combo}  x${reel.multiplier.toStringAsFixed(0)}',
                          style: _retro(12, color: _rarityColor(reel.maxRarityTier), w: FontWeight.w900)),
                  ],
                ),
              ),
              Expanded(
                child: reel.items.isEmpty
                    ? Center(child: Text('SPINNING…', style: _retro(12, color: const Color(0xFF5E7392))))
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final it in reel.items)
                              Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _DetailCard(item: it))),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.item});

  final ServerReelItem item;

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(item.rarityTier);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111B2C),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: color.withValues(alpha: item.rarityTier >= 11 ? 0.6 : 0.35), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                PixelSprite(
                  art: ItemSprites.shape(_shape(item.shape)),
                  height: 30,
                  recolor: {'X': color, 'x': Color.lerp(color, Colors.black, 0.45)!},
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.rarity.toUpperCase(), style: _retro(8, color: color, w: FontWeight.w900), maxLines: 1),
                      Text('LV ${item.level}', style: _retro(7, color: const Color(0xFF6EE7B7))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(item.primary.toUpperCase(),
                style: _retro(9, color: const Color(0xFFF1F5F9), w: FontWeight.w900), maxLines: 2),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              physics: const BouncingScrollPhysics(),
              itemCount: item.passives.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 1.5),
                child: Text(item.passives[i], style: _retro(7.5, color: const Color(0xFF9FB3CC)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
