import 'enums.dart';

class Topic {
  const Topic({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    this.icon = '',
    this.origin = TopicOrigin.personal,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final TopicOrigin origin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Topic copyWith({
    String? name,
    String? description,
    String? category,
    String? icon,
    TopicOrigin? origin,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Topic(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      origin: origin ?? this.origin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'icon': icon,
    'origin': origin.dbValue,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory Topic.fromMap(Map<String, Object?> map) => Topic(
    id: map['id']! as String,
    name: map['name']! as String,
    description: (map['description'] ?? '') as String,
    category: (map['category'] ?? '') as String,
    icon: (map['icon'] ?? '') as String,
    origin: TopicOrigin.fromDb(map['origin'] as String?),
    isActive: ((map['is_active'] ?? 1) as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (map['created_at']! as num).toInt(),
      isUtc: true,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      (map['updated_at']! as num).toInt(),
      isUtc: true,
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is Topic && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}
