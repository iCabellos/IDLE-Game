import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/character_status.dart';
import '../../core/pixel/pixel_sprite.dart';
import '../../core/pixel/pixel_widgets.dart';
import '../../core/pixel/sprites.dart';
import '../../core/theme/app_theme.dart';

/// Visual preview of the Android home-screen widget (F8), implemented
/// natively with Jetpack Glance in `apps/widget`. This screen mirrors the
/// two supported sizes (2x1 and 4x2) so the layout can be reviewed without
/// an Android emulator.
class WidgetPreviewScreen extends StatelessWidget {
  const WidgetPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PixelBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    PixelArt(Sprites.crystal, size: 34),
                    SizedBox(width: 10),
                    PixelText('HOME CHARM', size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                const PixelText(
                  'ANDROID GLANCE WIDGET (APPS/WIDGET)',
                  size: 9,
                  color: AppColors.muted,
                ),
                const SizedBox(height: 16),
                const PixelPanel(
                  fill: Color(0xFF14243A),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixelText('2X1', size: 9, color: AppColors.muted),
                      SizedBox(height: 8),
                      _Widget2x1(status: CharacterStatus.winning),
                      SizedBox(height: 20),
                      PixelText('4X2', size: 9, color: AppColors.muted),
                      SizedBox(height: 8),
                      _Widget4x2(status: CharacterStatus.rewardsReady),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),
                const PixelText(
                  'TAPPING THE WIDGET OPENS THE APP TO THE GUILD HALL. THE '
                  'SPRITE, STATUS COLOR AND LABEL UPDATE ON EACH IDLE TICK — '
                  'NEVER RAW STATS.',
                  size: 9,
                  color: AppColors.muted,
                  shadow: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact "status at a glance" widget.
class _Widget2x1 extends StatelessWidget {
  const _Widget2x1({required this.status});

  final CharacterStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: status.color, width: 2),
        boxShadow: const [BoxShadow(offset: Offset(3, 3), color: Color(0xFF0B1220))],
      ),
      child: Row(
        children: [
          PixelArt(status.sprite, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PixelText('VANGUARD', size: 10, maxLines: 1),
                PixelText(status.label.toUpperCase(), size: 9, color: status.color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Larger widget with zone, status and a claim action.
class _Widget4x2 extends StatelessWidget {
  const _Widget4x2({required this.status});

  final CharacterStatus status;

  @override
  Widget build(BuildContext context) {
    final ready = status == CharacterStatus.rewardsReady;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: status.color, width: 2),
        boxShadow: const [BoxShadow(offset: Offset(3, 3), color: Color(0xFF0B1220))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PixelArt(Sprites.warrior, size: 36),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelText('VANGUARD', size: 11),
                    PixelText('EMBERFALL OUTSKIRTS',
                        size: 8, color: AppColors.muted),
                  ],
                ),
              ),
              PixelBadge(label: status.label, color: status.color),
            ],
          ),
          const SizedBox(height: 12),
          PixelButton(
            label: ready ? 'Claim rewards' : 'Still idle…',
            height: 34,
            color: AppColors.success,
            onPressed: ready ? () {} : null,
            icon: const PixelArt(Sprites.chest, size: 18),
          ),
        ],
      ),
    );
  }
}
