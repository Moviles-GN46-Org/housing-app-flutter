enum OfflineActionType { submitReview, toggleFavorite, sendMessage }

class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  final int attempts;

  const OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.queuedAt,
    this.attempts = 0,
  });

  OfflineAction copyWith({int? attempts}) => OfflineAction(
        id: id,
        type: type,
        payload: payload,
        queuedAt: queuedAt,
        attempts: attempts ?? this.attempts,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'queuedAt': queuedAt.toIso8601String(),
        'attempts': attempts,
      };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
        id: json['id'] as String,
        type: OfflineActionType.values.firstWhere(
          (e) => e.name == json['type'],
        ),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        queuedAt: DateTime.parse(json['queuedAt'] as String),
        attempts: json['attempts'] as int? ?? 0,
      );
}
