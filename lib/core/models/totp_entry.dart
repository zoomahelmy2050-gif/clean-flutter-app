class TotpEntry {
  final String id;
  final String name;
  final String issuer;
  final String secret;
  final String? category;
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final Map<String, dynamic>? metadata;

  TotpEntry({
    required this.id,
    required this.name,
    required this.issuer,
    required this.secret,
    this.category,
    this.icon,
    this.color,
    required this.createdAt,
    this.lastUsedAt,
    this.metadata,
  });

  factory TotpEntry.fromJson(Map<String, dynamic> json) {
    return TotpEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      issuer: json['issuer'] as String,
      secret: json['secret'] as String,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null 
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuer': issuer,
      'secret': secret,
      'category': category,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  TotpEntry copyWith({
    String? id,
    String? name,
    String? issuer,
    String? secret,
    String? category,
    String? icon,
    String? color,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TotpEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      secret: secret ?? this.secret,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
