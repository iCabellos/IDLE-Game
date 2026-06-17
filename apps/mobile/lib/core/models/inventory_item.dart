/// Lightweight client-side model mirroring the backend item shape.
///
/// Populated from the real `/catalog/items` response
/// (see IdleRPG.API.Endpoints.CatalogEndpoints -> CatalogItemDto).
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.rarityTier,
    this.equipped = false,
    this.setName,
  });

  /// Builds an item from a `/catalog/items` JSON object.
  factory InventoryItem.fromCatalogJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slot: json['slot'] as String? ?? '',
      rarity: json['rarity'] as String? ?? '',
      rarityTier: (json['rarityTier'] as num?)?.toInt() ?? 1,
      // Catalog items are definitions, not owned instances.
      equipped: false,
      // Catalog exposes only the set id, not its display name.
      setName: json['setId'] == null ? null : 'Set item',
    );
  }

  final String id;
  final String name;
  final String slot;
  final String rarity;
  final int rarityTier;
  final bool equipped;
  final String? setName;
}
