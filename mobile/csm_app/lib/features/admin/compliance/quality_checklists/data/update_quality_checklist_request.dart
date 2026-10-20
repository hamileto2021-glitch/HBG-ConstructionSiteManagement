class UpdateQualityChecklistRequest {
  const UpdateQualityChecklistRequest({
    required this.constructionSiteId,
    required this.name,
    required this.category,
    this.description,
    required this.isActive,
    required this.items,
  });

  final String constructionSiteId;
  final String name;
  final String category;
  final String? description;
  final bool isActive;
  final List<UpdateQualityChecklistItem> items;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'name': name,
      'category': category,
      'description': description,
      'isActive': isActive,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class UpdateQualityChecklistItem {
  const UpdateQualityChecklistItem({
    this.id,
    required this.sequence,
    required this.requirement,
    required this.isMandatory,
  });

  final String? id;
  final int sequence;
  final String requirement;
  final bool isMandatory;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequence': sequence,
      'requirement': requirement,
      'isMandatory': isMandatory,
    };
  }
}