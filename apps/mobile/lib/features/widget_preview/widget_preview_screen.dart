import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/character_status.dart';
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
      appBar: AppBar(title: const Text('Home Screen Widget')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Android Glance widget (apps/widget)',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const _HomeScreenMock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('2x1', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ),
                  _Widget2x1(status: CharacterStatus.winning),
                  SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('4x2', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ),
                  _Widget4x2(status: CharacterStatus.rewardsReady),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            const Text(
              'Tapping the widget opens the app to the Dashboard. The icon, '
              'status color and label update on each idle tick — never raw stats.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple stand-in for an Android home screen wallpaper + grid.
class _HomeScreenMock extends StatelessWidget {
  const _HomeScreenMock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navy, AppColors.bg],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: child,
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
      height: 88,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(status.icon, color: status.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sir Cinder',
                  style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  status.label,
                  style: TextStyle(color: status.color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: status.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RarityColors.superior, width: 1.5),
                ),
                child: const Icon(Icons.shield, color: RarityColors.superior, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sir Cinder',
                      style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Whispering Crypts',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(status.icon, color: status.color, size: 12),
                    const SizedBox(width: 4),
                    Text(status.label, style: TextStyle(color: status.color, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton.icon(
              onPressed: ready ? () {} : null,
              style: FilledButton.styleFrom(
                backgroundColor: ready ? AppColors.success : AppColors.bg,
                disabledBackgroundColor: AppColors.bg,
                padding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.card_giftcard, size: 16, color: ready ? AppColors.text : AppColors.muted),
              label: Text(
                ready ? 'Claim Rewards' : 'Still idle…',
                style: TextStyle(fontSize: 12, color: ready ? AppColors.text : AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
