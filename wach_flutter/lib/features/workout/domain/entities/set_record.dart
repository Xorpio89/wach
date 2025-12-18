/// Set Record Entity - Domain Layer
/// Represents a single set/rep recording within a session
class SetRecord {
  final String id;
  final String sessionId;
  final int reps;
  final DateTime recordedAt;

  const SetRecord({
    required this.id,
    required this.sessionId,
    required this.reps,
    required this.recordedAt,
  });

  /// Create a copy with updated fields
  SetRecord copyWith({
    String? id,
    String? sessionId,
    int? reps,
    DateTime? recordedAt,
  }) {
    return SetRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      reps: reps ?? this.reps,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SetRecord(id: $id, reps: $reps, recordedAt: $recordedAt)';
  }
}
