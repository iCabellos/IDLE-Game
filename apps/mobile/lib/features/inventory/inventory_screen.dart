import 'package:flutter/material.dart';

import '../../core/inventory/inventory_model.dart';
import '../../core/pixel/item_sprites.dart';
import '../../core/pixel/pixel_art.dart';

const _pixelFont = 'monospace';

TextStyle _retro(double size,
        {Color color = const Color(0xFFF1F5F9), FontWeight w = FontWeight.w700}) =>
    TextStyle(
      fontFamily: _pixelFont,
      fontSize: size,
      color: color,
      fontWeight: w,
      letterSpacing: 1.1,
      height: 1.15,
    );

Map<String, Color> _rarityRecolor(Rarity r) {
  final c = r.color;
  return {'X': c, 'x': Color.lerp(c, Colors.black, 0.45)!};
}

/// Character-bound inventory. Page 1 = the active fighter + its 12-slot gear
/// (tap the hero to swap, tap a slot to re-equip) and the full roster.
/// Swipe right -> the general stash (one item of every rarity).
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _repo = InventoryRepository();
  final _pageCtrl = PageController();
  late Future<InventoryData> _future;

  InventoryData? _data;
  final List<RosterId> _active = [];
  final Map<RosterId, Map<GearSlot, GearItem?>> _equip = {};
  int _selected = 0;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _future = _repo.load().then((d) {
      _data = d;
      _active
        ..clear()
        ..addAll(d.activeTeam);
      for (final entry in d.loadouts.entries) {
        _equip[entry.key] = Map<GearSlot, GearItem?>.from(entry.value.gear);
      }
      return d;
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  RosterId get _focusedId => _active[_selected];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F18),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E1626), Color(0xFF080B12)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<InventoryData>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(
                    child: Text('LOADING GEAR',
                        style: _retro(12, color: const Color(0xFF8FB3D9))));
              }
              return Column(
                children: [
                  _header(),
                  Expanded(
                    child: PageView(
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _page = i),
                      children: [_teamPage(), _stashPage()],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- header ---------------------------------------------------------------

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Text(_page == 0 ? 'EQUIPO' : 'ALIJO GENERAL', style: _retro(18)),
          const SizedBox(width: 10),
          _dot(_page == 0),
          const SizedBox(width: 5),
          _dot(_page == 1),
          const Spacer(),
          Text(_page == 0 ? 'desliza  >' : '<  desliza',
              style: _retro(10, color: const Color(0xFF5E7392))),
        ],
      ),
    );
  }

  Widget _dot(bool active) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0EA5E9) : const Color(0xFF24334C),
          border: Border.all(color: const Color(0xFF0A0F18), width: 1),
        ),
      );

  // --- TEAM PAGE ------------------------------------------------------------

  Widget _teamPage() {
    final loadout = _data!.loadouts[_focusedId]!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      children: [
        _activeSelector(),
        const SizedBox(height: 12),
        _focusedPanel(loadout),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('HEROES DEL JUEGO',
              style: _retro(12, color: const Color(0xFF8FB3D9))),
        ),
        _rosterStrip(),
      ],
    );
  }

  Widget _activeSelector() {
    return Row(
      children: [
        for (var i = 0; i < _active.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: _ActivePortrait(
                id: _active[i],
                name: _data!.loadouts[_active[i]]!.name,
                selected: i == _selected,
              ),
            ),
          ),
      ],
    );
  }

  Widget _focusedPanel(HeroLoadout loadout) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16243F), Color(0xFF0D1524)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF24334C), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portrait + identity (tap portrait to swap the hero).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _openHeroSwap,
                child: Container(
                  width: 96,
                  height: 100,
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A111E),
                    border: Border.all(color: const Color(0xFF34D399), width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: PixelSprite(art: ItemSprites.roster(loadout.id), height: 84),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loadout.name.toUpperCase(), style: _retro(15)),
                    const SizedBox(height: 4),
                    Text('${loadout.role}  -  LV ${loadout.level}',
                        style: _retro(10, color: const Color(0xFF6EE7B7))),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _openHeroSwap,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14213A),
                          border:
                              Border.all(color: const Color(0xFF0EA5E9), width: 1),
                        ),
                        child: Text('TAP  CAMBIAR HEROE',
                            style: _retro(9, color: const Color(0xFF8FD4F2))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 12-slot gear grid (3 columns x 4 rows).
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
            children: [
              for (final slot in GearSlot.values)
                _gearCell(slot, _equip[_focusedId]?[slot]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gearCell(GearSlot slot, GearItem? item) {
    return GestureDetector(
      onTap: () => _openItemSwap(slot),
      child: Column(
        children: [
          Expanded(
            child: item == null
                ? _EmptySlot(slot: slot)
                : _FilledSlot(item: item),
          ),
          const SizedBox(height: 3),
          Text(slot.label.toUpperCase(),
              style: _retro(7, color: const Color(0xFF6C7C93)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _rosterStrip() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in _data!.roster)
          _RosterChip(entry: e, active: _active.contains(e.id)),
      ],
    );
  }

  // --- STASH PAGE -----------------------------------------------------------

  Widget _stashPage() {
    final stash = _data!.stash;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: stash.length,
      itemBuilder: (context, i) => _StashCell(item: stash[i]),
    );
  }

  // --- swap sheets ----------------------------------------------------------

  Future<void> _openHeroSwap() async {
    final bench = _data!.roster
        .where((e) => e.unlocked && !_active.contains(e.id))
        .toList();
    final chosen = await showModalBottomSheet<RosterId>(
      context: context,
      backgroundColor: const Color(0xFF0C1320),
      builder: (_) => _HeroSwapSheet(
        bench: bench,
        loadouts: _data!.loadouts,
        currentName: _data!.loadouts[_focusedId]!.name,
      ),
    );
    if (chosen != null) {
      setState(() {
        _equip.putIfAbsent(
          chosen,
          () => Map<GearSlot, GearItem?>.from(_data!.loadouts[chosen]!.gear),
        );
        _active[_selected] = chosen;
      });
    }
  }

  Future<void> _openItemSwap(GearSlot slot) async {
    final options =
        _data!.stash.where((it) => it.slot == slot).toList();
    final current = _equip[_focusedId]?[slot];
    final result = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: const Color(0xFF0C1320),
      builder: (_) => _ItemSwapSheet(
        slot: slot,
        options: options,
        current: current,
      ),
    );
    if (result == null) return;
    setState(() {
      _equip[_focusedId]![slot] = result is GearItem ? result : null;
    });
  }
}

// --- shared item icon + stars ----------------------------------------------

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({required this.item, required this.height});

  final GearItem item;
  final double height;

  @override
  Widget build(BuildContext context) {
    return PixelSprite(
      art: ItemSprites.shape(item.shape),
      height: height,
      recolor: _rarityRecolor(item.rarity),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.count, required this.color, this.size = 6});

  final int count;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: size,
            height: size,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: i < count ? color : const Color(0xFF26344C),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }
}

// --- team page widgets -----------------------------------------------------

class _ActivePortrait extends StatelessWidget {
  const _ActivePortrait(
      {required this.id, required this.name, required this.selected});

  final RosterId id;
  final String name;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? const Color(0xFF0EA5E9) : const Color(0xFF243248);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF13233D) : const Color(0xFF0C1320),
        border: Border.all(color: accent, width: selected ? 2 : 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          PixelSprite(art: ItemSprites.roster(id), height: 44),
          const SizedBox(height: 3),
          Text(name.split(' ').first.toUpperCase(),
              style: _retro(8,
                  color: selected
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF7C8CA3)),
              maxLines: 1),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.slot});

  final GearSlot slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A111E),
        border: Border.all(color: const Color(0xFF1A2740), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, c) => Opacity(
            opacity: 0.14,
            child: PixelSprite(
              art: ItemSprites.shape(slot.defaultShape),
              height: c.maxHeight * 0.66,
              desaturate: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilledSlot extends StatelessWidget {
  const _FilledSlot({required this.item});

  final GearItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.rarity.color;
    return Container(
      padding: const EdgeInsets.only(top: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF101B2C),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: item.rarity.isElite ? 0.65 : 0.4),
              blurRadius: item.rarity.isElite ? 11 : 7),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) =>
                    _ItemIcon(item: item, height: c.maxHeight * 0.84),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _Stars(count: item.rarity.stars, color: color, size: 4),
          ),
        ],
      ),
    );
  }
}

class _RosterChip extends StatelessWidget {
  const _RosterChip({required this.entry, required this.active});

  final RosterEntry entry;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final unlocked = entry.unlocked;
    final accent = active
        ? const Color(0xFF0EA5E9)
        : unlocked
            ? const Color(0xFF34D399)
            : const Color(0xFF2A3852);
    return Container(
      width: 102,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF111B2C) : const Color(0xFF0C1320),
        border: Border.all(color: accent, width: unlocked ? 2 : 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          PixelSprite(
              art: ItemSprites.roster(entry.id), height: 52, desaturate: !unlocked),
          const SizedBox(height: 4),
          Text(unlocked ? entry.name.toUpperCase() : '???',
              style: _retro(8,
                  color:
                      unlocked ? const Color(0xFFF1F5F9) : const Color(0xFF5E7392)),
              maxLines: 1),
          const SizedBox(height: 2),
          Text(active ? 'EN EQUIPO' : (unlocked ? entry.role : 'LOCKED'),
              style: _retro(7,
                  color: active
                      ? const Color(0xFF8FD4F2)
                      : unlocked
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF475569))),
        ],
      ),
    );
  }
}

class _StashCell extends StatelessWidget {
  const _StashCell({required this.item});

  final GearItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.rarity.color;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111B2C),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: item.rarity.isElite ? 0.7 : 0.4),
              blurRadius: item.rarity.isElite ? 12 : 7),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) =>
                    _ItemIcon(item: item, height: c.maxHeight * 0.74),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _Stars(count: item.rarity.stars, color: color, size: 5),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16)),
            child: Column(
              children: [
                Text(item.rarity.label.toUpperCase(),
                    style: _retro(8, color: color), maxLines: 1),
                const SizedBox(height: 1),
                Text(item.name,
                    style: _retro(7, color: const Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- bottom sheets ---------------------------------------------------------

class _HeroSwapSheet extends StatelessWidget {
  const _HeroSwapSheet({
    required this.bench,
    required this.loadouts,
    required this.currentName,
  });

  final List<RosterEntry> bench;
  final Map<RosterId, HeroLoadout> loadouts;
  final String currentName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CAMBIAR HEROE', style: _retro(13, color: const Color(0xFF0EA5E9))),
          const SizedBox(height: 2),
          Text('Reemplazar a ${currentName.toUpperCase()}',
              style: _retro(9, color: const Color(0xFF6C7C93))),
          const SizedBox(height: 14),
          if (bench.isEmpty)
            Text('No hay heroes en el banquillo.',
                style: _retro(10, color: const Color(0xFF6C7C93)))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in bench)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, e.id),
                    child: Container(
                      width: 110,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111B2C),
                        border: Border.all(color: const Color(0xFF34D399), width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          PixelSprite(art: ItemSprites.roster(e.id), height: 56),
                          const SizedBox(height: 4),
                          Text(e.name.toUpperCase(), style: _retro(8), maxLines: 1),
                          const SizedBox(height: 2),
                          Text(e.role,
                              style: _retro(7, color: const Color(0xFF6EE7B7))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ItemSwapSheet extends StatelessWidget {
  const _ItemSwapSheet(
      {required this.slot, required this.options, required this.current});

  final GearSlot slot;
  final List<GearItem> options;
  final GearItem? current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('EQUIPAR  -  ${slot.label.toUpperCase()}',
                  style: _retro(13, color: const Color(0xFF0EA5E9))),
              const Spacer(),
              if (current != null)
                GestureDetector(
                  onTap: () => Navigator.pop(context, 'remove'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEF6B6B), width: 1),
                    ),
                    child: Text('QUITAR',
                        style: _retro(9, color: const Color(0xFFEF6B6B))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (options.isEmpty)
            Text('No tienes piezas para esta ranura.',
                style: _retro(10, color: const Color(0xFF6C7C93)))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.74,
                children: [
                  for (final it in options)
                    GestureDetector(
                      onTap: () => Navigator.pop(context, it),
                      child: _OptionCard(item: it, equipped: it == current),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.item, required this.equipped});

  final GearItem item;
  final bool equipped;

  @override
  Widget build(BuildContext context) {
    final color = item.rarity.color;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101B2C),
        border: Border.all(color: color, width: equipped ? 3 : 2),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 7)],
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) =>
                    _ItemIcon(item: item, height: c.maxHeight * 0.78),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: _Stars(count: item.rarity.stars, color: color, size: 4),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            color: color.withValues(alpha: 0.16),
            child: Text(equipped ? 'EQUIPADO' : item.rarity.label.toUpperCase(),
                style: _retro(7, color: color),
                textAlign: TextAlign.center,
                maxLines: 1),
          ),
        ],
      ),
    );
  }
}
