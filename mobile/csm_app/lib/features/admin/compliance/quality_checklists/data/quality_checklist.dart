class QualityChecklist {
  const QualityChecklist({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.constructionSiteName,
    required this.name,
    required this.category,
    this.description,
    required this.isActive,
    required this.items,
  });

  final String id;
  final String companyId;
  final String constructionSiteId;
  final String constructionSiteName;

  final String name;
  final String category;
  final String? description;
  final bool isActive;

  final List<QualityChecklistItem> items;

  factory QualityChecklist.fromJson(Map<String, dynamic> json) {
    return QualityChecklist(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      constructionSiteId:
      json['constructionSiteId']?.toString() ?? '',
      constructionSiteName:
      json['constructionSiteName']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['isActive'] ?? true,
      items: (json['items'] as List? ?? [])
          .map((e) => QualityChecklistItem.fromJson(e))
          .toList(),
    );
  }
}

class QualityChecklistItem {
  const QualityChecklistItem({
    required this.id,
    required this.sequence,
    required this.requirement,
    required this.isMandatory,
  });

  final String id;
  final int sequence;
  final String requirement;
  final bool isMandatory;

  factory QualityChecklistItem.fromJson(Map<String, dynamic> json) {
    return QualityChecklistItem(
      id: json['id']?.toString() ?? '',
      sequence: json['sequence'] ?? 0,
      requirement: json['requirement']?.toString() ?? '',
      isMandatory: json['isMandatory'] ?? true,
    );
  }
}