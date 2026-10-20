class MaterialLookup {
  const MaterialLookup({
    required this.value,
    required this.name,
  });

  final String value;
  final String name;

  factory MaterialLookup.fromJson(Map<String, dynamic> json) {
    return MaterialLookup(
      value: json['value'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'name': name,
    };
  }
}