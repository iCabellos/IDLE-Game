import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/character_status.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/character_status_card.dart';

/// Home screen: character status + idle session summary.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CharacterStatus _status = CharacterStatus.winning;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Cycle status (demo)',
            onPressed: () => setState(() {
              final next = CharacterStatus.values
                  .elementAt((_status.index + 1) % CharacterStatus.values.length);
              _status = next;
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroHeader(status: _status).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            CharacterStatusCard(status: _status, zoneName: 'Whispering Crypts'),
            const SizedBox(height: 16),
            _IdleSessionCard(status: _status),
            const SizedBox(height: 16),
            const _SetBonusCard(),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.status});

  final CharacterStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RarityColors.superior, width: 2),
          ),
          child: const Icon(Icons.shield, color: RarityColors.superior, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sir Cinder',
                style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'Warrior · Tank',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(status.icon, color: status.color, size: 14),
              const SizedBox(width: 6),
              Text(status.label, style: TextStyle(color: status.color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdleSessionCard extends StatelessWidget {
  const _IdleSessionCard({required this.status});

  final CharacterStatus status;

  @override
  Widget build(BuildContext context) {
    final ready = status == CharacterStatus.rewardsReady;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Idle Session',
              style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const _SessionRow(label: 'Time away', value: '6h 42m'),
            const _SessionRow(label: 'Enemies defeated', value: 'Dozens'),
            const _SessionRow(label: 'Loot found', value: '3 items'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: ready ? () {} : null,
                style: FilledButton.styleFrom(
                  backgroundColor: ready ? AppColors.success : AppColors.surface,
                  disabledBackgroundColor: AppColors.surface,
                ),
                icon: Icon(Icons.card_giftcard, color: ready ? AppColors.text : AppColors.muted),
                label: Text(
                  ready ? 'Claim Rewards' : 'No rewards yet',
                  style: TextStyle(color: ready ? AppColors.text : AppColors.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SetBonusCard extends StatelessWidget {
  const _SetBonusCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: RarityColors.superior.withValues(alpha: 0.6)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: RarityColors.superior),
                SizedBox(width: 8),
                Text(
                  'Ironclad Set — 4/4',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '2-piece: Defense boost\n4-piece: Unbreakable — immune to one-shot defeats',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
