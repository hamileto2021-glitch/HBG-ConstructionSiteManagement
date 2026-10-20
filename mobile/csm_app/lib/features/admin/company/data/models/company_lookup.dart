class CompanyLookup {
  const CompanyLookup({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory CompanyLookup.fromJson(Map<String, dynamic> json) {
    return CompanyLookup(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
