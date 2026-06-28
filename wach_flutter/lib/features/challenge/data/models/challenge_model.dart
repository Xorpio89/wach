import '../../domain/entities/challenge.dart';

/// Challenge Model - Data Layer
/// Handles serialization to/from the sembast database.
///
/// Items are stored as a nested list of maps inside the challenge record.
class ChallengeModel extends Challenge {
  const ChallengeModel({
    required super.id,
    required super.name,
    super.periodDays,
    required super.createdAt,
    super.items,
  });

  /// Create from database map.
  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    final rawItems = (map['items'] as List?) ?? const [];
    return ChallengeModel(
      id: map['id'] as String,
      name: map['name'] as String,
      periodDays: map['period_days'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      items: rawItems
          .map((e) => _itemFromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'period_days': periodDays,
      'created_at': createdAt.millisecondsSinceEpoch,
      'items': items.map(_itemToMap).toList(),
    };
  }

  static ChallengeItem _itemFromMap(Map<String, dynamic> map) {
    return ChallengeItem(
      id: map['id'] as String,
      name: map['name'] as String,
      targetReps: map['target_reps'] as int,
      blockSize: (map['block_size'] as int?) ?? 10,
      doneReps: (map['done_reps'] as int?) ?? 0,
    );
  }

  static Map<String, dynamic> _itemToMap(ChallengeItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'target_reps': item.targetReps,
      'block_size': item.blockSize,
      'done_reps': item.doneReps,
    };
  }

  /// Create model from entity.
  factory ChallengeModel.fromEntity(Challenge challenge) {
    return ChallengeModel(
      id: challenge.id,
      name: challenge.name,
      periodDays: challenge.periodDays,
      createdAt: challenge.createdAt,
      items: challenge.items,
    );
  }

  /// Convert to domain entity.
  Challenge toEntity() {
    return Challenge(
      id: id,
      name: name,
      periodDays: periodDays,
      createdAt: createdAt,
      items: items,
    );
  }
}
