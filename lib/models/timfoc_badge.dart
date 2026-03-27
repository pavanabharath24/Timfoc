import 'package:hive/hive.dart';

part 'timfoc_badge.g.dart';

@HiveType(typeId: 2)
class TimfocBadge extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String iconAsset;

  @HiveField(4)
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  TimfocBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    this.unlockedAt,
  });

  TimfocBadge copyWith({
    String? id,
    String? name,
    String? description,
    String? iconAsset,
    DateTime? unlockedAt,
  }) {
    return TimfocBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
