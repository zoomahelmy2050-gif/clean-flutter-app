class TotpCategory {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final int order;

  TotpCategory({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.order = 0,
  });

  factory TotpCategory.fromJson(Map<String, dynamic> json) {
    return TotpCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'order': order,
    };
  }

  TotpCategory copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    int? order,
  }) {
    return TotpCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
    );
  }
}
