class EventLogEntry {
  final int id;
  final String eventType;
  final String entityType;
  final int entityId;
  final Map<String, dynamic> changes;
  final String? previousHash;
  final String currentHash;
  final DateTime timestamp;

  EventLogEntry({
    required this.id,
    required this.eventType,
    required this.entityType,
    required this.entityId,
    required this.changes,
    this.previousHash,
    required this.currentHash,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventType': eventType,
      'entityType': entityType,
      'entityId': entityId,
      'changes': _encodeChanges(changes),
      'previousHash': previousHash,
      'currentHash': currentHash,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory EventLogEntry.fromMap(Map<String, dynamic> map) {
    return EventLogEntry(
      id: map['id'] as int,
      eventType: map['eventType'] as String,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as int,
      changes: _decodeChanges(map['changes'] as String),
      previousHash: map['previousHash'] as String?,
      currentHash: map['currentHash'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  static String _encodeChanges(Map<String, dynamic> changes) {
    final entries = changes.entries.map((e) => '${e.key}:${e.value}').join('|');
    return entries;
  }

  static Map<String, dynamic> _decodeChanges(String encoded) {
    if (encoded.isEmpty) return {};
    final entries = encoded.split('|');
    final map = <String, dynamic>{};
    for (final entry in entries) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  EventLogEntry copyWith({
    int? id,
    String? eventType,
    String? entityType,
    int? entityId,
    Map<String, dynamic>? changes,
    String? previousHash,
    String? currentHash,
    DateTime? timestamp,
  }) {
    return EventLogEntry(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      changes: changes ?? this.changes,
      previousHash: previousHash ?? this.previousHash,
      currentHash: currentHash ?? this.currentHash,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

