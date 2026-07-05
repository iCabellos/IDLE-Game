import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/pixel/pixel_sprite.dart';
import '../../core/pixel/pixel_widgets.dart';
import '../../core/pixel/sprites.dart';
import '../../core/theme/app_theme.dart';

/// World map: zone progression backed by `/combat/zones` (mock preview).
/// Cleared zones show their victory banner, the current zone its wave
/// progress, and future zones stay padlocked.
class ZoneMapScreen extends StatelessWidget {
  const ZoneMapScreen({super.key});

  static const _zones = [
    (zone: 1, name: 'EMBERFALL OUTSKIRTS', status: 'cleared'),
    (zone: 2, name: 'FROSTBITE HOLLOW', status: 'cleared'),
    (zone: 3, name: 'STORMWRACK COAST', status: 'current'),
    (zone: 4, name: 'VIPERMARSH', status: 'locked'),
    (zone: 5, name: 'ASHEN BASTION', status: 'locked'),
    (zone: 6, name: 'GLACIER THROAT', status: 'locked'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PixelBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    PixelArt(Sprites.compass, size: 34),
                    SizedBox(width: 10),
                    PixelText('WORLD MAP', size: 18),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _zones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final zone = _zones[index];
                    return _ZoneCard(
                      zone: zone.zone,
                      name: zone.name,
                      status: zone.status,
                    )
                        .animate()
                        .fadeIn(delay: (60 * index).ms, duration: 300.ms)
                        .slideY(begin: 0.06, end: 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone, required this.name, required this.status});

  final int zone;
  final String name;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (sprite, color, badge) = switch (status) {
      'cleared' => (Sprites.banner, AppColors.success, 'CLEARED'),
      'current' => (Sprites.slime, AppColors.accent, 'FIGHTING'),
      _ => (Sprites.padlock, AppColors.muted, 'LOCKED'),
    };
    final locked = status == 'locked';

    return PixelPanel(
      border: color,
      fill: locked ? const Color(0xFF15202F) : AppColors.surface,
      child: Row(
        children: [
          PixelArt(sprite, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText('ZONE $zone', size: 8, color: AppColors.muted),
                const SizedBox(height: 2),
                PixelText(
                  name,
                  size: 11,
                  color: locked ? AppColors.muted : AppColors.text,
                  maxLines: 1,
                ),
                if (status == 'current') ...[
                  const SizedBox(height: 8),
                  const PixelProgressBar(
                    filled: 7,
                    total: 10,
                    color: AppColors.accent,
                    height: 10,
                  ),
                  const SizedBox(height: 4),
                  const PixelText('WAVE 7/10 — BOSS AT 10',
                      size: 8, color: AppColors.muted, shadow: false),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PixelBadge(label: badge, color: color),
        ],
      ),
    );
  }
}
